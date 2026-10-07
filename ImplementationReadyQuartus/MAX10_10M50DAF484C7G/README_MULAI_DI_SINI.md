# Project Quartus MAX10_10M50DAF484C7G

Board/device: 10M50DAF484C7G
Top module: igor_de10_lite_top
Source top: rtl/igor_de10_lite_top.v
Project: quartus/igor_max10.qpf
SOF siap diprogram: quartus/output_files/igor_max10.sof
Quartus: Prime Standard 25.1 dengan device support yang sesuai.

## Buka dan compile
1. Extract seluruh ZIP. Pertahankan folder rtl, assets dan quartus sebagai saudara.
2. Klik dua kali BUKA_PROJECT_QUARTUS.bat. Alternatif: Quartus > File > Open Project > quartus/igor_max10.qpf.
3. Periksa Assignments > Device: 10M50DAF484C7G; top entity: igor_de10_lite_top.
4. File RTL dan SDC sudah terdaftar dalam QSF. Jangan menambahkan testbench ke project synthesis.
5. Jika RTL tidak berubah, SOF yang disertakan dapat digunakan tanpa compile ulang.
6. Jika RTL berubah, Processing > Start Compilation. Pastikan sukses dan tidak ada slack timing negatif sebelum memprogram.

## Program FPGA
1. Hubungkan daya board dan USB-Blaster onboard ke laptop.
2. Tools > Programmer > Hardware Setup > pilih USB-Blaster. Mode JTAG.
3. Auto Detect; cocokkan perangkat dengan target di atas.
4. Pada baris perangkat pilih Change File, gunakan quartus/output_files/igor_max10.sof.
5. Centang Program/Configure lalu Start. Tunggu 100% Successful.
6. SOF dimuat ke SRAM; ulangi programming setelah daya dimatikan.

Project telah lulus kompilasi dan timing pada sumber asal. Hash SOF salinan diperiksa terhadap sumber. Uji fisik board belum dinyatakan selesai.
Paket ini fokus pada project Quartus. Aplikasi UART, testbench, dan skrip pengujian lengkap tetap ada pada paket board utama.
