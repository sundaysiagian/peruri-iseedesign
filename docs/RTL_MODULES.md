# Top module dan breakdown RTL

## Top yang dipilih

| Target | Top module | File |
|---|---|---|
| DE10-Nano | igor_uart_top | [RTL](../fpga_de10_nano/rtl/igor_uart_top.v) |
| DE10-Lite | igor_de10_lite_top | [RTL](../fpga_de10_lite/rtl/igor_de10_lite_top.v) |
| TinyTapeout | tt_um_wlmoi_igor_gate | [Wrapper](../src/project.v) |
| STM single speed | stm_uart_demo_top | [RTL](../robot/jetauto/FPGA_UART_TTL/rtl/stm_uart_demo_top.v) |
| STM four speed | stm_uart_multispeed_top | [RTL](../robot/jetauto/FPGA_UART_TTL_MULTISPEED/rtl/stm_uart_multispeed_top.v) |

## Seluruh modul common accelerator

| Modul | Fungsi |
|---|---|
| [igor_uart_top](../rtl/igor_uart_top.v) | Top DE10-Nano, UART dispatch dan readback neural |
| [igor_uart_protocol](../rtl/igor_uart_protocol.v) | Framing request/response delapan byte dan command dispatch |
| [igor_uart_rx](../rtl/igor_uart_rx.v) | Receiver UART |
| [igor_uart_tx](../rtl/igor_uart_tx.v) | Transmitter UART |
| [igor_top](../rtl/igor_top.v) | Kontrol DWA, hasil, deadline, dan gerbang output |
| [igor_config_registers](../rtl/igor_config_registers.v) | Konfigurasi 32 bit, limit, validity, dan lock |
| [igor_costmap_manager](../rtl/igor_costmap_manager.v) | Sequence, upload order, frame completion, commit, freshness |
| [igor_costmap_bank](../rtl/igor_costmap_bank.v) | Memory synchronous 32768 × 8, dua frame per copy |
| [igor_candidate_generator](../rtl/igor_candidate_generator.v) | Enumerasi velocity dan angular-rate kandidat |
| [igor_rollout_tile](../rtl/igor_rollout_tile.v) | 128 kandidat dan 20 pose pada satu evaluator |
| [igor_kinematic_step](../rtl/igor_kinematic_step.v) | Update posisi serta heading fixed-point |
| [igor_trig_lut](../rtl/igor_trig_lut.v) | Lookup sinus dan cosinus signed |
| [igor_score_accumulator](../rtl/igor_score_accumulator.v) | Akumulasi critic 32 bit |
| [igor_best_candidate_selector](../rtl/igor_best_candidate_selector.v) | Pemilihan empat hasil tile dan tie-break |
| [igor_safety_security_gate](../rtl/igor_safety_security_gate.v) | Pemeriksaan permit dan pembatasan command |
| [igor_status_logger](../rtl/igor_status_logger.v) | Fault 8 bit dan event counter 32 bit |
| [igor_neural_core](../rtl/igor_neural_core.v) | MAC serial signed 16 bit, accumulator 40 bit |
| [igor_neural_rom](../rtl/igor_neural_rom.v) | ROM bobot dan bias, address 13 bit |
| [igor_de10_nano_wrapper](../rtl/igor_de10_nano_wrapper.v) | Wrapper scene alternatif, bukan UART top aktif |

Root `rtl/` digunakan oleh regresi. Kedua project FPGA mempunyai copy source untuk menjaga folder board portable. Lite menggunakan atribut RAM M9K pada costmap/ROM serta wrapper MAX 10 sendiri. Nano menggunakan M10K dan wrapper Cyclone V. Validator memeriksa perbedaan target yang spesifik ini. Perubahan common RTL harus disinkronkan ke copy board, kemudian diverifikasi serta dibuild ulang.

Detail bit flow ada pada [ARCHITECTURE.md](ARCHITECTURE.md). Detail FSM dan setiap modul tersedia dalam [Flowchart 28 halaman](flowcharts/IGOR_RTL_Flowchart.io).
