# Proyek Quartus siap dibuka

Pilih folder berdasarkan board. Setiap folder memiliki RTL, ROM, QPF, QSF, SDC, pin assignment, host UART, SOF, dan report implementasi.

| Board | Project | Top | Device |
|---|---|---|---|
| DE10-Nano | [igor.qpf](IGOR_DE10_NANO/quartus/igor.qpf) | igor_uart_top | 5CSEBA6U23I7 |
| DE10-Lite | [igor_max10.qpf](MAX10_10M50DAF484C7G/quartus/igor_max10.qpf) | igor_de10_lite_top | 10M50DAF484C7G |

Klik **BUKA_PROJECT_QUARTUS.bat** dalam folder pilihan. Folder ini disinkronkan dengan project canonical pada root repository. Image Nano terkini memakai SHA256 prefix **4236365161b23d537121**, sedangkan Lite **456949b9c86da8d747af**.

Lihat [VERIFIKASI_PAKET.json](VERIFIKASI_PAKET.json) untuk hash lengkap dan pemeriksaan seluruh source reference. Instruksi JTAG, UART, reset, serta test ada pada [FPGA_PROGRAMMING.md](../docs/FPGA_PROGRAMMING.md).
