{-|
Clash port of @delay_diff_filter.sv@ from fpga-theremin.

@
  OUT_DIFF = IN_VALUE - IN_VALUE delayed by DELAY_CYCLES writes
@

The input is a stream of monotonically increasing latched timer values, so the
difference between a sample and one taken @DELAY_CYCLES@ writes ago is the
time spanned by those cycles — that is, the oscillator period, averaged over
the delay window. It is a boxcar averager built from one subtract and a
circular buffer, rather than an accumulator, which is what keeps it cheap.

@ram_initialized@ suppresses the output until the buffer has been filled once,
so the first window never differences against uninitialised memory.

The SV picks distributed RAM or block RAM by comparing the address width
against @BRAM_ADDR_BITS_THRESHOLD@. That choice only changes read latency
(asynchronous vs synchronous read), so it is a term-level flag here; Clash
emits a memory that yosys infers to the same primitives. At the theremin's
parameters (512-deep) both instances take the BRAM path.
-}
module Theremin.DelayDiffFilter
  ( DdfIn (..)
  , DdfOut (..)
  , DdfState (..)
  , initialState
  , ddfStep
  , delayDiffFilter
  ) where

import Clash.Prelude

-- | Input ports.
data DdfIn v = DdfIn
  { diReset :: Bit          -- ^ @RESET@, synchronous active high
  , diValue :: BitVector v  -- ^ @IN_VALUE@
  , diWr    :: Bit          -- ^ @WR@, one cycle per pushed value
  }
  deriving stock (Generic, Show, Eq)
  deriving anyclass (NFDataX)

-- | Output ports.
data DdfOut v = DdfOut
  { doChanged :: Bit          -- ^ @CHANGED@, toggles per new output
  , doDiff    :: BitVector v  -- ^ @OUT_DIFF@
  }
  deriving stock (Generic, Show, Eq)
  deriving anyclass (NFDataX)

-- | Every register plus the delay buffer.
--
-- @n@ is the address width, so the buffer holds @2^n@ entries.
data DdfState n v = DdfState
  { dsRam         :: Vec (2 ^ n) (BitVector v)
  , dsRamRead     :: BitVector v  -- ^ @ram_read_value@ (BRAM path registers it)
  , dsAddr        :: BitVector n  -- ^ @addr_counter@
  , dsInitialized :: Bool         -- ^ @ram_initialized@
  , dsDiff        :: BitVector v  -- ^ @diff_value@
  , dsChanged     :: Bit          -- ^ @output_changed@
  }
  deriving stock (Generic, Show, Eq)
  deriving anyclass (NFDataX)

-- | Power-up value. As in the SV, the buffer contents are not reset — the
-- @ram_initialized@ gate is what makes that safe.
initialState :: (KnownNat n, KnownNat v) => DdfState n v
initialState = DdfState
  { dsRam         = repeat 0
  , dsRamRead     = 0
  , dsAddr        = 0
  , dsInitialized = False
  , dsDiff        = 0
  , dsChanged     = 0
  }

-- | One clock edge.
--
-- The @offset@ argument is @DELAY_COUNTER_OFFSET@, i.e.
-- @2^n - DELAY_CYCLES@, which supports delays that are not a power of two.
-- It is zero for both of the theremin's instances.
ddfStep ::
  forall n v.
  (KnownNat n, KnownNat v) =>
  BitVector n ->  -- ^ @DELAY_COUNTER_OFFSET@
  DdfState n v ->
  DdfIn v ->
  DdfState n v
ddfStep offset s DdfIn{..}
  | diReset == high = (initialState :: DdfState n v) { dsRam = dsRam s }
  | diWr == high = s
      { dsRam         = replace (unpack dsAddrIdx :: Index (2 ^ n)) diValue (dsRam s)
        -- BRAM path: synchronous read, one cycle behind the write.
      , dsRamRead     = dsRam s !! (unpack readAddr :: Index (2 ^ n))
      , dsAddr        = dsAddr s + 1
      , dsInitialized = dsInitialized s || addrOverflow
      , dsDiff        = if dsInitialized s then diValue - dsRamRead s else dsDiff s
      , dsChanged     = if dsInitialized s then complement (dsChanged s) else dsChanged s
      }
  | otherwise = s
 where
  dsAddrIdx = dsAddr s
  -- BRAM read address leads the write pointer by one, plus the offset.
  readAddr = dsAddr s + 1 + offset
  addrOverflow = dsAddr s == maxBound

-- | Synchronous delay-difference filter.
delayDiffFilter ::
  forall n v dom.
  (HiddenClockResetEnable dom, KnownNat n, KnownNat v) =>
  BitVector n ->  -- ^ @DELAY_COUNTER_OFFSET@
  Signal dom (DdfIn v) ->
  Signal dom (DdfOut v)
delayDiffFilter offset =
  moore (ddfStep offset) out (initialState :: DdfState n v)
 where
  out s = DdfOut { doChanged = dsChanged s, doDiff = dsDiff s }
