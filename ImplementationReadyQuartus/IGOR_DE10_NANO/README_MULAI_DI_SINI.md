# Project Quartus IGOR_DE10_NANO

Board/device: 5CSEBA6U23I7
Top module: igor_uart_top
Source top: rtl/igor_uart_top.v
Project: quartus/igor.qpf
SOF siap diprogram: quartus/output_files/igor.sof
Quartus: Prime Standard 25.1 dengan device support yang sesuai.

## Buka dan compile
1. Extract seluruh ZIP. Pertahankan folder rtl, assets dan quartus sebagai saudara.
2. Klik dua kali BUKA_PROJECT_QUARTUS.bat. Alternatif: Quartus > File > Open Project > quartus/igor.qpf.
3. Periksa Assignments > Device: 5CSEBA6U23I7; top entity: igor_uart_top.
4. File RTL dan SDC sudah terdaftar dalam QSF. Jangan menambahkan testbench ke project synthesis.
5. Jika RTL tidak berubah, SOF yang disertakan dapat digunakan tanpa compile ulang.
6. Jika RTL berubah, Processing > Start Compilation. Pastikan sukses dan tidak ada slack timing negatif sebelum memprogram.

## Program FPGA
1. Hubungkan daya board dan USB-Blaster onboard ke laptop.
2. Tools > Programmer > Hardware Setup > pilih USB-Blaster. Mode JTAG.
3. Auto Detect; cocokkan perangkat dengan target di atas.
4. Pada baris perangkat pilih Change File, gunakan quartus/output_files/igor.sof.
5. Centang Program/Configure lalu Start. Tunggu 100% Successful.
6. SOF dimuat ke SRAM; ulangi programming setelah daya dimatikan.

Project telah lulus kompilasi dan timing pada sumber asal. Hash SOF salinan diperiksa terhadap sumber. Uji fisik board belum dinyatakan selesai.
Paket ini fokus pada project Quartus. Aplikasi UART, testbench, dan skrip pengujian lengkap tetap ada pada paket board utama.
