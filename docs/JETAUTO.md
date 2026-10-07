# JetAuto UART dan Verilog motor test

## Dua protocol dengan dua fungsi

UART planner IGOR memakai **115200 baud** dan paket delapan byte. Controller STM pada pengujian JetAuto memakai **1.000.000 baud**, header `AA 55`, dan protocol SDK motor. Bitstream motor disediakan sebagai target tersendiri.

Folder: [robot/jetauto](../robot/jetauto). Proyek empat speed: [stm_uart_multispeed.qpf](../robot/jetauto/FPGA_UART_TTL_MULTISPEED/quartus/stm_uart_multispeed.qpf). Top: **`stm_uart_multispeed_top`**. Serializer: **`stm_packet_tx_multispeed`**.

## Protocol motor

| Field | Isi |
|---|---|
| Header | `AA 55` |
| Function | `03` |
| Payload length | `22` byte untuk empat motor |
| Subcommand | `01` |
| Motor count | `04` |
| Setpoint | Empat pasangan ID dan float32 little-endian RPS |
| Wire ID | 0, 1, 2, 3 |
| CRC | CRC8 reflected polynomial `8C`, pada function, length, dan payload |

Frame empat motor berukuran **27 byte**, atau **270 µs** pada 1 Mbps 8N1. STOP membawa seluruh ID dengan speed nol. [Frame hasil decode RTL](../robot/jetauto/FPGA_UART_TTL_MULTISPEED/tb/rtl_captured_packets.hex) diperiksa secara independen menggunakan SDK.

## Empat speed

| Level | Setpoint RPM | RPS | Positive float32 bits |
|---|---:|---:|---|
| 0 | 15 | 0,25 | `3E800000` |
| 1 | 30 | 0,50 | `3F000000` |
| 2 | 60 | 1,00 | `3F800000` |
| 3 | 90 | 1,50 | `3FC00000` |

SW1:0 memilih speed, SW2 arah, dan SW3 arm. KEY1 memulai sesi enam detik saat armed atau buzzer saat disarmed. Pilihan speed dan arah dilatch saat start. Refresh dilakukan tiap 50 ms. Boot, lease selesai, dan arm-clear meminta STOP. KEY0 adalah reset logic, bukan emergency stop mekanis independen.

## Mapping roda

| Posisi menurut diagram forward SDK | Host ID | Forward sign |
|---|---:|---|
| Front-left | 1 | + |
| Rear-left | 2 | + |
| Front-right | 3 | − |
| Rear-right | 4 | − |

Mapping perlu diperiksa terhadap wiring aktual menggunakan tes individual. Diagonal adalah ID **1 + 4** dan **3 + 2**. Pair/diagonal test dilakukan dengan roda terangkat, bukan perintah chassis bergerak lurus.

## Laptop launcher

```powershell
cd robot\jetauto
py run_all_tests.py
```

Perintah tersebut menjalankan pemeriksaan offline tanpa command motor. Pada Windows, **RUN_ALL_MOTOR_TESTS.bat** menyediakan pilihan V untuk verifikasi dan M untuk motion. Motion meminta roda diangkat, power motor ON, serta input `RUN`.

Launcher khusus: **RUN_NEW_DIAGONAL_STAGED_TEST.bat**, **RUN_DIAGONAL_TESTS.bat**, dan **RUN_STAGED_START_TEST.bat**. Profile staged menambah rear-left lebih dahulu, lalu rear-right, front-left, dan front-right sebelum ramp 15 → 30 → 60 RPM. Instruksi lengkap ada pada [BAT_TEST_TUTORIAL.md](../robot/jetauto/BAT_TEST_TUTORIAL.md).

Script mengenali COM9 CH9102 dengan VID `1A86`, PID `55D4`, dan serial perangkat yang direkam. Port yang berbeda harus dikonfigurasi secara eksplisit, bukan dipindai untuk mengirim motor command. Tidak ada automatic motion pada CI.

## Menuju FPGA tanpa laptop

Bitstream motor mengeluarkan GPIO UART TTL **1 Mbps** pada DE10-Nano JP1 pin 2 / E8. RX opsional memakai pin 1 / V12. Common ground menggunakan pin 12 atau 30. Ini memerlukan input UART STM kompatibel 3,3 V yang benar-benar diidentifikasi.

Jika STM hanya dapat diakses melalui USB, gunakan **HPS Linux USB host**. Template transport ada pada [robot/hps_usb](../robot/hps_usb). GPIO UART tidak menjadi USB host dan COM9 adalah nama device Windows.

Command IGOR menuju motor memerlukan bridge yang mempertahankan permit, sequence, expiry, dan STOP ketika command stale. Demo motor tersendiri tidak memakai gerbang IGOR. [Status acceptance](RESULTS_AND_SCOPE.md) membedakan packet verification, observasi roda, dan integrasi FPGA.

## Bukti

Testbench serializer dan controller tersedia bersama log, `.sof`, dan source/image hashes pada [folder four-speed](../robot/jetauto/FPGA_UART_TTL_MULTISPEED). Katalog 37 source Python dan alur SDK terdapat pada [PYTHON_FILE_CATALOG.md](../robot/jetauto/PYTHON_FILE_CATALOG.md) dan [CODE_FLOW_REVIEW.md](../robot/jetauto/CODE_FLOW_REVIEW.md).
