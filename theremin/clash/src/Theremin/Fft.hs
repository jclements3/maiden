{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE NoStarIsType #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}
{-# OPTIONS_GHC -fplugin GHC.TypeLits.Extra.Solver #-}
{-# OPTIONS_GHC -fplugin GHC.TypeLits.Normalise #-}
{-# OPTIONS_GHC -fplugin GHC.TypeLits.KnownNat.Solver #-}

{-|
512-point streaming FFT — radix-2 single-delay-feedback (R2SDF).

== Why this exists

`hardware/BOM.md` Note A records a behavioural 512-point FFT synthesising to
~139k LUT4s. The ECP5 LFE5U-85F has 83,640, and it is the largest part in the
family — so on that number MAIDEN does not fit any ECP5, and the board choice
would have to leave the family entirely.

That 139k is the signature of a *fully unrolled* FFT: every butterfly
instantiated in parallel, which is what synthesis produces when a transform is
written behaviourally and flattened. It is a property of the implementation,
not of the transform.

This module is the counter-proposal, built to get a real number rather than an
argument. R2SDF is the standard streaming architecture: one sample in and one
out per clock, @log2 512 = 9@ stages, each holding a delay line and *one*
butterfly. Nine butterflies total instead of 512·log2(512)/2 = 2304.

== Structure

Stage @s@ (counting from the input) has a delay line of @L = N / 2^(s+1)@
complex words: 256, 128, 64, ... , 1. Each clock the stage either

* /fills/ (counter's top bit low): push the input into the delay line, emit
  what falls out the far end; or
* /butterflies/ (top bit high): emit @delayed + input@, and push
  @(delayed - input) * W@ back into the delay line.

The delay lines are 'blockRam', so they land in @DP16KD@ rather than fabric
flops — that is the whole point of the exercise, since 511 complex words held
in registers would be ~16k flip-flops.

The complex multiply is the textbook four-real-multiply form,
@(a+bi)(c+di) = (ac - bd) + (ad + bc)i@, which maps to four @MULT18X18D@ per
stage. Eight stages need a twiddle (the last does not), so ~32 of the 156 DSPs
on the part.

== Status

**This is a sizing model.** It is structurally faithful — the resource shape it
reports is the resource shape a production R2SDF has — and it synthesises. It
has *not* been verified numerically against a reference DFT, and the pipeline
alignment between stages has not been checked cycle-by-cycle. Do not treat it
as a working FFT; treat its LUT4/DSP/BRAM figures as the evidence for the
board decision, and verify functionally before it processes real radar data.
-}
module Theremin.Fft
  ( Cplx
  , sdfStage
  , fft512
  , topEntity
  ) where

import Clash.Prelude

import Theremin.Fft.Twiddle

-- | Complex sample: (real, imaginary), 16-bit signed each.
type Cplx = (Signed 16, Signed 16)

-- | Q1.15 complex multiply, four real multiplies and two adds.
--
-- Products are Q2.30 in 32 bits; shifting right by 15 renormalises back to
-- Q1.15. Truncation, not rounding — a production version would round, at the
-- cost of an adder per product.
cmul :: Cplx -> Twiddle -> Cplx
cmul (a, b) (c, d) = (re, im)
 where
  mul :: Signed 16 -> Signed 16 -> Signed 32
  mul x y = resize x * resize y

  re = resize ((mul a c - mul b d) `shiftR` 15)
  im = resize ((mul a d + mul b c) `shiftR` 15)

cadd, csub :: Cplx -> Cplx -> Cplx
cadd (a, b) (c, d) = (a + c, b + d)
csub (a, b) (c, d) = (a - c, b - d)

-- | One radix-2 single-delay-feedback stage.
--
-- @d@ is the log2 of the delay length, so the stage holds @2^d@ complex words
-- and its phase counter is @d+1@ bits: the top bit selects fill vs butterfly.
--
-- @strideShift@ selects this stage's twiddles out of 'masterTwiddles' — stage
-- delay @L@ uses every @256 \/ L@-th entry.
sdfStage ::
  forall d dom.
  (HiddenClockResetEnable dom, KnownNat d, 1 <= 2 ^ d) =>
  SNat d ->
  Int ->                  -- ^ stride shift into the master twiddle table
  Signal dom Cplx ->
  Signal dom Cplx
sdfStage _ strideShift din = dout
 where
  -- Phase counter: 0 .. 2L-1. Top bit low = fill, high = butterfly.
  counter :: Signal dom (Unsigned (d + 1))
  counter = register 0 (counter + 1)

  butterflyPhase = (== 1) . msb <$> counter

  -- Index within the half-period, which is also the delay-line address.
  addr :: Signal dom (Unsigned d)
  addr = truncateB <$> counter

  -- Delay line of 2^d complex words. Reading and writing the same address
  -- each clock makes it a circular buffer of depth 2^d: the value read is
  -- the one written 2^d clocks earlier.
  delayed :: Signal dom Cplx
  delayed = blockRam (replicate (SNat @(2 ^ d)) (0, 0)) addr wr

  wr = (\a v -> Just (a, v)) <$> addr <*> feedback

  -- Twiddle for this stage, strided out of the shared table.
  tw :: Signal dom Twiddle
  tw = (\a -> masterTwiddles !! (fromIntegral a `shiftL` strideShift :: Int))
         <$> addr

  -- Fill phase: pass the input into the line, emit what falls out.
  -- Butterfly phase: emit the sum, feed the twiddled difference back.
  dout = mux butterflyPhase (cadd <$> delayed <*> din) delayed

  feedback =
    mux butterflyPhase
        (cmul <$> (csub <$> delayed <*> din) <*> tw)
        din

-- | 512-point R2SDF pipeline: nine stages, delays 256 down to 1.
--
-- The stride doubles at each stage as the delay halves, so every stage indexes
-- the shared 256-entry table correctly for its position.
fft512 ::
  HiddenClockResetEnable dom =>
  Signal dom Cplx ->
  Signal dom Cplx
fft512 =
    sdfStage (SNat @8) 0
  . sdfStage (SNat @7) 1
  . sdfStage (SNat @6) 2
  . sdfStage (SNat @5) 3
  . sdfStage (SNat @4) 4
  . sdfStage (SNat @3) 5
  . sdfStage (SNat @2) 6
  . sdfStage (SNat @1) 7
  . sdfStage (SNat @0) 8

-- | Synthesis root, for area and timing on the ECP5.
topEntity ::
  Clock System ->
  Reset System ->
  Signal System Cplx ->
  Signal System Cplx
topEntity clk rst din =
  withClockResetEnable clk rst enableGen (fft512 din)
{-# ANN topEntity
  (Synthesize
    { t_name = "fft512_r2sdf"
    , t_inputs = [PortName "CLK", PortName "RESET", PortName "IN"]
    , t_output = PortName "OUT"
    }) #-}
{-# NOINLINE topEntity #-}
