# Laporan teknis singkat IGOR

**Peruri Chip Hackathon 2026 · ISeeDesignITB · Institut Teknologi Bandung**

## Ringkasan

IGOR adalah prototipe planner lokal FPGA dengan empat tile evaluator, costmap double-bank, pemilihan kandidat terbaik, dan gerbang pada keluaran command. Desain tersedia untuk Cyclone V pada DE10-Nano dan MAX 10 pada DE10-Lite. Proyek memuat neural core integer 24 → 64 → 64 → 4 yang diuji terpisah serta prototipe ASIC gerbang dalam harness TinyTapeout.

Hasil utama adalah 7.938 siklus untuk evaluasi 512 kandidat × 20 pose pada enam scene, 400 output neural yang cocok tepat, delapan passing test case cocotb, sembilan skenario fault yang menolak izin, dan dua target FPGA yang telah melewati implementasi Quartus.

## Latar belakang dan keputusan desain

Kontrol lokal memerlukan keputusan yang dapat diperiksa bersama status inputnya. Kecepatan arithmetic saja tidak menjawab apakah peta lengkap, konfigurasi terkunci, hasil masih fresh, atau emergency aktif. IGOR menggabungkan jadwal evaluasi yang jelas dengan keluaran yang tunduk pada gerbang pemeriksaan.

Desain memakai fixed-point dan ROM agar operasi numerik serta resource bisa ditelusuri. Empat evaluator membagi kandidat secara paralel. Costmap direplikasi untuk menyediakan port baca independen. UART menjadi antarmuka inspeksi yang mudah direproduksi pada lab. Keputusan tersebut menyediakan bukti RTL dan implementation yang dapat ditinjau, sambil memperlihatkan batas bandwidth transport yang perlu ditingkatkan untuk integrasi.

## Spesifikasi

| Parameter | Nilai |
|---|---|
| Clock desain FPGA | 50 MHz |
| Costmap | 128 × 128, 8 bit per cell, sudah diinflasi |
| Banking / replication | 2 frame per tile × 4 tile, 128 KiB |
| Kandidat | 512, dibagi 128 per tile |
| Rollout | 20 pose per kandidat |
| Output planner | permit 1 bit, v 5 bit, omega signed 7 bit |
| Neural | 24 → 64 → 64 → 4, operand signed 16 bit, accumulator 40 bit |
| Host planner | UART 115200 8N1, request/response 8 byte |
| Nano | 5CSEBA6U23I7, top igor_uart_top |
| Lite | 10M50DAF484C7G, top igor_de10_lite_top |
| ASIC subset | tt_um_wlmoi_igor_gate |

## Arsitektur dan verifikasi

Config manager mengunci konfigurasi. Map manager memeriksa sequence, urutan alamat, kelengkapan upload, commit, serta freshness. Empat costmap copy menyediakan baca independen. Tile menjalankan kinematic step, lookup trigonometri, dan critic accumulation. Selector memilih hasil dan gate memeriksa kondisi izin.

Icarus dan cocotb menjalankan gate, neural, top, UART, wrapper RTL, serta wrapper netlist generik. Model integer neural terpisah memberi expected output. Assertions/invariants dan functional outcome coverage melengkapi pemeriksaan. Seluruh metode serta XML tersedia pada [VERIFICATION.md](VERIFICATION.md).

## Hasil implementasi dan analisis

DWA lengkap membutuhkan 158,76 µs pada 50 MHz. Neural serial membutuhkan 363,84 µs. Penjumlahan 522,60 µs hanya proyeksi dua kernel terpisah. Nano menggunakan 4.964 ALM, 1.554 register, 131 M10K, dan 10 DSP. Lite menggunakan 18.984 LE, 1.539 register, dan 1.051.008 memory bit. Timing recorded kedua desain memenuhi clock 50 MHz.

Power Analyzer memberi estimate 506,69 mW dengan vectorless Low confidence. Peta penuh melalui host UART stop-and-wait mempunyai biaya nominal sekitar 22,77 detik. Angka ini menekankan bahwa optimasi interface adalah bagian penting integrasi, meskipun kernel sendiri cepat. [PERFORMANCE.md](PERFORMANCE.md) memuat tabel dan sumber lengkap.

## Jalur pengembangan chip dan demonstrasi

Subset gerbang telah mempunyai metadata chip, register interface, generic synthesis, dan passing netlist test. Flow fisik CMOS5L disediakan secara opt-in. Area PDK dan physical signoff merupakan tahap acceptance berikutnya.

Pengujian JetAuto menyediakan encoder paket UART dalam RTL, empat speed setpoint, testbench serializer/controller, dan launcher laptop. Jalur motor ini terpisah dari command planner hingga bridge permit/sequence/expiry selesai diintegrasikan. [Panduan demo](DEMO_GUIDE.md) memberi rundown dan bukti yang perlu direkam.

## Luaran dan reproduksi

Source, ROM, model, testbench, proyek Quartus, SOF, diagram, report, screenshot, serta manifest disediakan dalam repository. [QUICKSTART.md](QUICKSTART.md) menjelaskan verifikasi dan [FPGA_PROGRAMMING.md](FPGA_PROGRAMMING.md) menjelaskan pemrograman hardware. Cakupan hasil dan acceptance berikutnya tercatat pada [RESULTS_AND_SCOPE.md](RESULTS_AND_SCOPE.md).
