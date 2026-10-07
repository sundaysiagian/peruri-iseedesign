# MAX10 DE10-Lite build: READY FOR LAB PROGRAMMING

Target: 10M50DAF484C7G. Top: igor_de10_lite_top (rtl/igor_de10_lite_top.v).
Quartus Prime Standard 25.1std.0 Build 1129. Semua tahap build berhasil.

- Analysis & Synthesis: 0 errors, 9 warnings.
- Fitter: 0 errors, 2 warnings.
- Assembler: 0 errors, 0 warnings.
- Timing Analyzer: 0 errors, 0 warnings; setup dan hold fully constrained.
- Clock: 50 MHz; setup slack terburuk +1.140 ns; hold minimum +0.107 ns; Fmax 53.02 MHz.
- Resources: 18,984/49,760 logic elements (38%), 1,051,008/1,677,312 memory bits (63%).
- File: quartus/output_files/igor_max10.sof (3,216,574 bytes).

SHA256: 456949B9C86DA8D747AF7E505193444DC23F33D7E42251B72ABBBA64B08C2CB5

Bukti lengkap: evidence/quartus_*.log, quartus/output_files/*.summary, quartus/reports/ dan MAX10_BUILD_RECEIPT.json.
Simulasi sebelumnya lulus termasuk UART FULL MAP CHECKS=16403 ERRORS=0.
Uji fisik JTAG/UART pada board belum dilakukan; ikuti README.md untuk uji lab.

Peringatan fitter yang tersisa: drive strength UART_TX/LEDR menggunakan default (lokasi dan I/O standard tetap ditetapkan), serta persyaratan interface MAX10 3.3-V. Gunakan USB-UART TTL 3.3 V sesuai README. Peringatan synthesis tercatat di log, termasuk input yang tidak digunakan dan perilaku read-during-write RAM.

UART: 115200 8N1, adapter TX ke JP1 pin 1/V10 (UART_RX), adapter RX ke JP1 pin 2/W10 (UART_TX), GND ke JP1 pin 12 atau 30. Jangan hubungkan VCC adapter.

Paket DE10-Nano tetap terpisah di IGOR_DE10_NANO. SOF ini khusus DE10-Lite/MAX10.
