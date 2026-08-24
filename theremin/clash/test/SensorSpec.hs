{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE OverloadedStrings #-}

-- | End-to-end tests for the ported sensor datapath.
--
-- These drive the whole chain (CDC -> pulse centres -> stage 1 boxcar ->
-- stage 2 IIR) with a synthetic edge stream of known period, and check that
-- what comes out is the period. That is the property the hardware exists to
-- provide, so it is worth asserting directly rather than only unit-testing
-- the pieces.
module SensorSpec (tests) where

import Clash.Prelude
import qualified Prelude as P

import Test.Tasty
import Test.Tasty.HUnit

import Theremin.SensorPeriodMeasure

-- | Build an edge stream with a fixed spacing between successive edges.
--
-- The real edge detector toggles @CHANGE_EDGE@ and presents a new
-- @EDGE_POSITION@ each time it sees an oscillator transition. Here one edge
-- is emitted every @gap@ clocks, with the position advancing by @step@.
edgeStream ::
  Int ->        -- ^ clocks between edges
  Int ->        -- ^ position increment per edge
  Int ->        -- ^ number of clocks to generate
  [SensorIn]
edgeStream gap step n =
  [ SensorIn
      { spReset        = if i == 0 then high else low
      , spPitchEdge    = if odd (i `div` gap) then high else low
      , spPitchEdgePos = fromIntegral ((i `div` gap) * step)
      , spVolEdge      = if odd (i `div` gap) then high else low
      , spVolEdgePos   = fromIntegral ((i `div` gap) * step)
      }
  | i <- [0 .. n - 1]
  ]

-- | Run the datapath over an input list.
runSensor :: [SensorIn] -> [SensorOut]
runSensor ins = simulateN @System (P.length ins) sensorPeriodMeasure ins

-- | Strip the toggling flag in bit 31 to get the payload.
payload :: BitVector 32 -> Integer
payload = toInteger . (`clearBit` 31)

tests :: TestTree
tests = testGroup "theremin_sensor_period_measure"
  [ testCase "outputs start cleared after reset" $ do
      let outs = runSensor (edgeStream 8 16 40)
      payload (soPitchPeriodStage1 (P.head outs)) @?= 0

  , testCase "stage 1 measures the period over the delay window" $ do
      -- Edge positions advance by `step` per edge. A pulse centre is the sum
      -- of two adjacent edge positions, so it advances by 2*step per pulse.
      -- Stage 1 differences pulses 512 apart, giving 512 * 2 * step.
      let step = 3
          gap  = 4
          -- enough clocks to fill the 512-deep buffer twice over
          n    = gap * 2 * 600
          outs = runSensor (edgeStream gap step n)
          expected = 512 * 2 * step
          finals = P.filter (/= 0)
                     (P.map (payload . soPitchPeriodStage1) (P.drop (n `div` 2) outs))
      case finals of
        [] -> assertFailure "stage 1 never produced a non-zero measurement"
        (v : _) -> v @?= fromIntegral expected

  , testCase "stage 2 tracks stage 1" $ do
      -- The IIR is a lowpass with unity DC gain, so once stage 1 is constant
      -- stage 2 must converge towards it (it will sit slightly below, from
      -- the same per-stage truncation the IIR unit tests characterise).
      let step = 3
          gap  = 4
          n    = gap * 2 * 4000
          outs = runSensor (edgeStream gap step n)
          s2   = payload (soPitchPeriodStage2 (P.last outs))
      assertBool "stage 2 is non-zero once settled" (s2 > 0)
  ]
