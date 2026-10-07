# Run all JetAuto tests and isolate the rear-left problem

## Latest verified physical result

All four wheels worked individually in both directions during the longer COM9 run. Rear-left was delayed when the rear pair ran and did not move when all four ran together, according to the user. The four-speed run earlier moved all four at its first 15 RPM stage and only three at later stages. Therefore the current result is a **partial pass**. Simultaneous operation at all four requested speeds is not established.

The diagonal and staggered-start experiment was sent on the same identified COM9 bridge and ended with STOP. Its physical observation must be recorded before claiming a fix. The recorded commands are in `logs/diagonal_staged_console.log` and the timestamped diagonal JSON file.

## Double-click launcher

Copy the entire `JETAUTO_DRIVER_BRINGUP` folder, including `vendor`, `sdk_original.py`, the Python scripts and the FPGA folders. Python 3 is required. Pyserial is already included, so ROS and pip installation are not needed for these laptop tests.

1. Close other programs using COM9.
2. Double-click **RUN_ALL_MOTOR_TESTS.bat**.
3. Choose **V** for packet/file checks and available Verilog simulations without motor commands, or **M** for the complete motor suite.
4. For M, lift all four wheels so they can rotate freely and turn motor power ON. Type **RUN** when ready. Full motion testing takes roughly three minutes and includes commands up to 90 RPM.
5. Watch the `NOW` labels and UART bytes. Every stage has a time limit. STOP separates stages, except the deliberate continuous startup/ramp stages, which finish with STOP.
6. Inspect the console log and summary JSON created under `logs`. A zero exit code means the script completed, not that all wheels moved. Record the physical result separately.

COM9 must match CH9102, VID 1A86, PID 55D4 and USB serial 5917012181. The scripts refuse an absent or mismatched device and do not scan other ports to send motor commands. If Windows renumbers the known bridge, its port setting must be updated explicitly.

Ctrl+C interrupts the current Python test and invokes its STOP cleanup. Cable loss, a forced process kill or power failure can prevent STOP delivery. This laptop launcher is not an independent hardware emergency stop.

For only the diagonal experiment, double-click **RUN_DIAGONAL_TESTS.bat**. For only staged startup, double-click **RUN_STAGED_START_TEST.bat**. Both ask for RUN before motion. All BAT files use the same runner and identity check.

After the user's further troubleshooting, the new combined launcher is **RUN_NEW_DIAGONAL_STAGED_TEST.bat**. It runs both diagonals in both directions, then staggered startup forward and backward. Commands remain 60 RPM for diagonal pairs, with staged startup at 15 then 30 then 60 RPM. Double-click it and type RUN. It takes about 50 seconds plus offline checks.

## Tests included

| Test | Commanded speed | Duration and coverage |
|---|---:|---|
| Offline SDK/CRC check | No motion | SDK float encoding, packet construction and CRC |
| Verilog packet test | No physical motion | Ten frames, 256 bytes, all motor IDs, four speeds and both directions |
| Verilog controller test | No physical motion | Selection, latching, refresh, time limit and STOP |
| Source and SOF check | No motion | Match source files and SOF to recorded SHA256 hashes |
| Earlier forward/backward run | 60 RPM | Two seconds in each direction |
| RTL packet replay | 15, 30, 60, 90 RPM | One second per forward level, then one second reverse at 90 RPM |
| Short individual test | 60 RPM | Each ID two seconds, then all four two seconds |
| Long individual/pair/group test | 60 RPM | Each ID both directions three seconds, front/rear pairs four seconds, all four each direction six seconds |
| Diagonal test | 60 RPM | Each diagonal pair four seconds in each direction |
| Staggered startup | 15 to 30 to 60 RPM | Add wheels one at a time, hold 15 and 30 RPM, then all four at 60 RPM for six seconds |
| One-ID packet comparison | 60 RPM | Four short packets per refresh instead of one four-ID packet, six seconds per direction |

If Icarus is not installed on the receiving laptop, live Verilog reruns are marked SKIPPED. The packet and image checks still run. Included logs show the simulations performed on this laptop. A missing simulator is never reported as a simulation pass.

## Motor IDs and diagonal pairs

Positions follow the forward-arrow motor diagram in the supplied `mecanum.py`. Confirm against actual wiring and the individual-ID stages.

| Position from robot's forward-facing orientation | Host ID | Wire ID | Forward sign |
|---|---:|---:|---|
| Front-left | 1 | 0 | Positive |
| Rear-left | 2 | 1 | Positive |
| Front-right | 3 | 2 | Negative |
| Rear-right | 4 | 3 | Negative |

Front-left plus rear-right uses IDs **1 and 4**, with targets `[+1, 0, 0, -1]` RPS. Front-right plus rear-left uses IDs **3 and 2**, with targets `[0, +1, -1, 0]` RPS. Reverse negates the nonzero values. Every four-ID frame includes zero targets for the unused wheels. These patterns are for a lifted-wheel test and do not command normal straight-line chassis motion.

## Proposed startup method and its limits

The staged experiment begins with rear-left, ID2, at 15 RPM for 0.75 seconds. It then adds rear-right, ID4, followed by front-left, ID1, at 0.75-second intervals. Finally it adds front-right, ID3, holds all four at 15 RPM for two seconds, raises all four to 30 RPM for two seconds, then requests 60 RPM for six seconds. The same sequence is tested backward. Refresh remains approximately every 50 ms.

Starting one wheel at a time may reduce coincident startup current, so it is a useful diagnostic. It cannot correct an inadequate steady-state power supply, a failing motor driver, a connector fault or a firmware interlock. It must be observed to work before being adopted in FPGA logic.

The one-ID comparison sends four SDK-compatible 12-byte frames per refresh, each carrying one motor target, rather than one 27-byte four-motor frame. This tests whether batch handling differs from individual handling in the installed STM firmware. It does not reduce the steady-state electrical demand of four motors. Its physical compatibility is unconfirmed until run and observed.

## How to decide the next fix

| Observation | What it supports | Next check |
|---|---|---|
| Rear-left fails in every two-wheel combination | A problem associated with that motor/driver channel, with load dependence possible | Compare known motor-power input voltage during single and pair operation |
| Both diagonals work, but all-four fails | Failure depends on combined operation | Measure loaded supply voltage and inspect the documented power-distribution connections |
| Staggering fixes startup and all four remain running | Startup demand or command sequencing may matter | Repeat and measure loaded voltage before adopting the sequence |
| Staggering starts rear-left, but it stops when speed/load rises | Startup sequencing is insufficient | Investigate steady-state supply, driver/current limit, connector and firmware behavior |
| Short one-ID frames work where a four-ID frame fails | Installed firmware may handle multi-entry packets differently | Trace the actual function 03/subcommand 01 handler in matching STM firmware |

The SDK battery value previously disagreed with the measured 11 to 12 V input, so it is not a reliable loaded-voltage measurement here. Measure directly across the already identified STM motor-power terminals during the relevant stage and record the lowest reading. A static pre-test voltage alone does not resolve a load-related failure. FPGA UART sends targets, it does not provide 12 V motor power.

## Manual commands

From this folder in PowerShell:

```powershell
py run_all_tests.py
py run_all_tests.py --run --wheels-raised --supply-on
py test_diagonal_and_staged.py --profile diagonals --run --wheels-raised --supply-on
py test_diagonal_and_staged.py --profile staged --run --wheels-raised --supply-on
py test_diagonal_and_staged.py --profile round-robin --run --wheels-raised --supply-on
```

The default `run_all_tests.py` performs non-motion verification. `RUN_ALL_MOTOR_TESTS.bat verify --no-pause` is the corresponding batch command for automated verification. Physical movement is always an observation to be added to the log, because this SDK has no motor encoder API or motor ACK.

## FPGA artifacts

The four-speed top module is `stm_uart_multispeed_top`. The Quartus project is `FPGA_UART_TTL_MULTISPEED/quartus/stm_uart_multispeed.qpf` and its SOF is `quartus/output_files/stm_uart_multispeed.sof`. Read `FOUR_SPEED_RTL_TUTORIAL.md` for controls, pin assignments, simulation and programming.

That SOF currently sends fixed four-wheel packets at the selected speed for six seconds. The laptop staged and diagonal sequences are diagnostics and have not been implemented in that image. The DE10-Nano physical board was unavailable, and the STM TTL control UART has not yet been identified. With USB-only STM access, this GPIO-UART SOF alone cannot replace the laptop USB host.
