# LAB-SETUP.md — lab computer setup for MAIDEN / theremin hardware work

Takes a bare, internet-connected Linux machine to (a) flashing the prebuilt
bring-up bitstreams the day the boards arrive and (b) a full Clash
development loop. Do this BEFORE the boards arrive: step 4 runs unattended
for an hour or more, and it gates the pin-fix contingency in step 5.

Steps are ordered so the long unattended builds start first. The VHDL-side
setup (udev rules, usbipd on WSL, phase1 flow) is documented in the theremin
repo — `fpga/ROADMAP.md` Phase 0 and `CLAUDE.md` — and is referenced, not
repeated, here.

## 0. Ground rules

- The two machines sync **only through git** (`github.com/jclements3/maiden`
  and `github.com/jclements3/theremin`). Uncommitted work on one machine is
  invisible to the other: commit and push whenever you stop.
- The lab machine does all hardware/USB work. The home laptop (WSL2, no
  admin rights on the Windows host) cannot attach USB — never plan a flash
  step there.

## 1. Clone the repos (minutes)

```sh
mkdir -p ~/projects && cd ~/projects
git clone https://github.com/jclements3/maiden.git
git clone https://github.com/jclements3/theremin.git
```

Optional, only for comparing against the original upstream design (213 MB):

```sh
git clone https://github.com/fpga-theremin/theremin.git \
    ~/projects/maiden/theremin/fpga-theremin
```

## 2. FPGA toolchain — pinned OSS CAD Suite (minutes)

Pinned release **2026-08-20** (GHDL 7.0.0-dev, Yosys 0.68, nextpnr 0.11.1),
installed at `~/tools/oss-cad-suite` — the Makefiles assume that path. It
bundles everything the hardware flow needs, including `openFPGALoader` and
`iceprog`.

```sh
mkdir -p ~/tools && cd ~/tools
curl -LO https://github.com/YosysHQ/oss-cad-suite-build/releases/download/2026-08-20/oss-cad-suite-linux-x64-20260820.tgz
tar xzf oss-cad-suite-linux-x64-20260820.tgz
```

Activate **per shell**, never in `.bashrc` (it shadows the system python3):

```sh
source ~/tools/oss-cad-suite/environment
```

**glibc shim (conditional):** if `ldd --version` reports glibc < 2.38
(e.g. Ubuntu 22.04), GHDL elaboration fails at link time on `__isoc23_*`
symbols. Build the shim per the theremin repo's `fpga/ROADMAP.md`
(`gcc -c -O2 -fPIC -o ~/tools/glibc-isoc23-shim.o glibc-isoc23-shim.c`);
the maiden Makefile picks it up automatically when
`~/tools/glibc-isoc23-shim.o` exists, and it is harmless to skip on a
newer distro.

## 3. USB permissions (minutes, needs sudo)

So flashing runs unprivileged (rules file travels in the theremin repo):

```sh
sudo cp ~/projects/theremin/fpga/setup/53-lattice-ftdi.rules /etc/udev/rules.d/
sudo udevadm control --reload
```

If the lab machine turns out to be Windows+WSL2 rather than native Linux,
additionally follow the usbipd-win steps in the theremin repo's
`fpga/ROADMAP.md` Phase 0 and run `fpga/setup/attach-fpga.sh` per plug-in.

## 4. Haskell / Clash toolchain (start early — an hour+ unattended)

The Clash compiler is built from the project's own build plan
(`build-tool-depends`); a globally installed clash will not work. Pins:
GHC **9.6.7**, cabal-install **3.14.2.0**, clash-ghc **1.8.5** (from the
cabal.project freeze).

```sh
curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh
ghcup install ghc 9.6.7 && ghcup set ghc 9.6.7
ghcup install cabal 3.14.2.0 && ghcup set cabal 3.14.2.0

cd ~/projects/maiden/theremin/clash
cabal update
cabal build all        # long: builds clash-ghc and deps from source
cabal test             # behavioural suite; should be all green
```

The Makefile locates the project-built clash binary under
`~/.cabal/store/ghc-9.6.7/clash-ghc-1.8.5-e-clash-*/bin/clash` — nothing
else to configure once `cabal build all` succeeds.

## 5. Arrival day — flash and listen

Follow `theremin/clash/bringup/BRINGUP.md` end to end; it is the runbook.
The three bitstreams it flashes are prebuilt and tracked in git
(`bringup/bin/*.bin`), so this step works even if step 4 is still churning:

```sh
cd ~/projects/maiden/theremin/clash/bringup
source ~/tools/oss-cad-suite/environment
openFPGALoader --detect                      # FTDI device should appear
openFPGALoader -b alchitry_cu bin/blinky.bin # our flow, end to end
```

**Pin-fix contingency:** BRINGUP.md's procedure for wrong `theremin.pcf`
pin guesses re-runs nextpnr on `build/arrival/*.json`. Those netlists are
build outputs and are **not in git** — they regenerate from the Makefile
targets named in BRINGUP.md, which needs step 4 finished. That is the
reason step 4 starts before the boards arrive.

## 6. Verify the development loop

Clash side (this repo):

```sh
cd ~/projects/maiden/theremin/clash
source ~/tools/oss-cad-suite/environment
make test    # Haskell behavioural tests
make sim     # Clash -> VHDL -> GHDL elaboration
make pnr     # ECP5 synthesis + P&R (the numbers that matter)
```

VHDL side (theremin repo): `cd ~/projects/theremin/fpga/phase1` and
`make sim && make bit && make prog` per that repo's CLAUDE.md — never
flash what hasn't been simulated.

## Done when

- [ ] `cabal test` green in `maiden/theremin/clash`
- [ ] `make sim` and `make pnr` complete in `maiden/theremin/clash`
- [ ] `openFPGALoader --detect` sees the board (once hardware arrives)
- [ ] `bin/blinky.bin` flashed and blinking (once hardware arrives)
- [ ] A test commit pushed from the lab machine and pulled at home
