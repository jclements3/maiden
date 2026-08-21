# Station UART record protocol (tagged-record framing)

The shared framing between the station's FPGA firmware and the Ch. 10
recorder (D6 "UART/SPI to recorder"; IF-1 producers). One serial stream
per FPGA, 115 200 baud 8N1; every message is a fixed-length tagged
record. The recorder demultiplexes by type into the IF-1 channels.

Created by maiden35 (Doppler record types); maiden38 extends it with the
timebase record types; maiden40 adds the recorder-side payload layouts
for Ch 4/5/6. One file owns the framing — do not fork it.

## Frame

```
byte 0   SYNC   0xA5
byte 1   TYPE   record type (below)
byte 2   SEQ    per-type modulo-256 sequence counter
bytes 3+ PAYLOAD (fixed length per type)
last     CKSUM  two's-complement of the byte-sum of bytes 0..n-1
                (sum of every frame byte including CKSUM == 0 mod 256)
```

Resync rule: a parser that loses lock scans for 0xA5 and validates the
checksum before trusting a frame; SEQ gaps are logged, never fatal.

## Record types

| TYPE | Name | Rate | Payload | Producer |
|---|---|---|---|---|
| 0x01 | DOPPLER_V | 50 Hz | 9 bytes, below | doppler_core (maiden35) |
| 0x10 | PPS_STATUS | 1 Hz | 4 bytes, below | timebase FPGA (maiden38) |
| 0x11 | TIME_MARK | 1 Hz (per PPS) | 10 bytes, below | timebase FPGA (maiden38) |
| 0x12 | STROBE_STAMP | per video frame | 9 bytes, below | timebase FPGA (maiden38) |
| 0x04 | STATION_STATUS | 1 Hz | reserved — maiden40 | recorder SBC |

### 0x01 DOPPLER_V payload (9 bytes, little-endian)

| off | field | format | notes |
|---|---|---|---|
| 0 | flags | u8 | bit0 = det_valid; other bits 0 |
| 1 | v_cm | i16 | radial velocity, cm/s, signed; sign = spectrum half |
| 3 | bin | u16 | detected FFT bin 0..511 (0 when invalid) |
| 5 | peak | u16 | peak magnitude, `mag >> 2` (u18 top 16 bits) |
| 7 | noise | u16 | CFAR noise estimate, `noise_est >> 2` |

SNR is computed downstream as `20*log10(peak/noise)` — no logs or
divisions in fabric. When `flags.det_valid = 0` the record still ships at
50 Hz (v_cm = 0, bin = 0): "SNR below threshold" is a report, not
silence, so the recorder's Ch 4 stays gap-free and lesson 13's EKF can
skip the update explicitly.

### Timebase record payloads (0x10-0x12, merged from maiden38)

All multi-byte fields little-endian, matching the doppler records.

| Type | Name         | Payload | Fields |
|------|--------------|---------|--------|
| 0x10 | PPS_STATUS   | 4 B     | offset: s20 (counts vs RTC_HZ, sign-extended into 3 B); flags: u8 = {bit0 locked, bit1 holdover (watchdog tripped), bit2 pps_seen_since_reset} |
| 0x11 | TIME_MARK    | 10 B    | pps_rtc: u48 (RTC at last PPS edge); tod_secs: u17 + tod_day: u9 packed into u32 (bits 0-16 seconds-of-day, bits 17-25 day-of-year) |
| 0x12 | STROBE_STAMP | 9 B     | rtc: u48; seq: u16; flags: u8 = {bit0 fifo_overflow (sticky)} |

Producer notes:

- `TIME_MARK` is emitted once per PPS (or once per free-running top of
  second in holdover) and is the recorder's source for the Ch 1 time
  packet: it pairs the absolute second with its RTC value — the option-2
  discipline contract (RTC free-running, mapping published).
- `PPS_STATUS` is emitted at 1 Hz into the Ch 6 status payload (PPS lock
  bit per IF-1) alongside battery/temp/disk from the SBC side.
- `STROBE_STAMP` records drain the strobe_latch FIFO; `seq` counts every
  strobe including dropped ones, so ingest can detect drops even after an
  overflow (the sticky flag says *that* stamps were lost, `seq` gaps say
  *which*).
