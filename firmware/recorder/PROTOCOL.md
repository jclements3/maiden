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
| 0x02 | TIME_STATUS | 1 Hz | reserved — maiden38 | timebase FPGA |
| 0x03 | FRAME_LATCH | per video frame | reserved — maiden38 | timebase FPGA |
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
