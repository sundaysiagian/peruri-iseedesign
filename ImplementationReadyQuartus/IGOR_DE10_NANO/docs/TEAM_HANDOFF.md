# Handoff pekerjaan

Semua hasil yang tersedia disatukan di folder utama. Arsip BRAM/model dari pengguna dipertahankan utuh di sources/run_20260929_032642-20260930T152952Z-1-001.zip. Model checkpoint/pickle tidak dieksekusi. Bobot hardware diekstrak ke assets/ dan digunakan RTL neural.

RTL/DWA, serial, integrasi neural, testbench, model pembanding, dan skrip build disusun pada pekerjaan ini. Nama kontributor lain tidak tersedia; atribusi tidak direka. Header Verilog mengikuti identitas yang diminta pengguna.

Untuk pengguna RTL: README → quartus/igor.qpf → rtl/igor_uart_top.v. Untuk verifikasi: simulation/run_simulation.ps1 → evidence/. Untuk UART: docs/UART_PROTOCOL.md → host/igor_uart.py. Untuk referensi: sources/. Versi eksplorasi gagal disimpan dengan penanda pre/superseded, bukan dianggap hasil final.

Belum selesai secara fisik: pemrograman board, loopback UART, pengukuran latency/power hardware, integrasi NN ke keputusan DWA, transport costmap real-time, motor/robot/HPS. Proposal DOCX/PDF lengkap dari permintaan awal masih pekerjaan lanjutan; fokus rilis ini RTL dan SOF sesuai prioritas terbaru.
