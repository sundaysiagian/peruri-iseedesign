# Jalur untuk kondisi saat ini: USB, tanpa GPIO STM

Gunakan processor HPS ARM pada DE10-Nano sebagai USB host. FPGA dan HPS adalah bagian berbeda dalam Cyclone V SoC. Demo ini adalah transport HPS, belum integrasi hasil algoritma RTL melalui Avalon.

```text
DE10-Nano HPS Linux -> USB HOST -> port USB kontrol STM -> firmware STM -> buzzer / driver motor
```

Tiga port hub USB untuk peripheral bukan bukti STM tersambung. Hub boleh berada di antara host dan STM jika wired/powered sesuai dan STM benar-benar menjadi downstream USB device. Jangan menghubungkan host DE10-Nano ke host Jetson. USB-Blaster/JTAG dan USB console UART HPS bukan port USB host untuk STM. Gunakan port USB host HPS sesuai manual Terasic dan adapter/kabel yang benar. Board STM wajib mendapat catu daya sesuai board.

## Tahap 1: Linux dan deteksi STM

1. Siapkan microSD dengan image Linux yang mendukung DE10-Nano dan USB host HPS. Tidak sembarang image Jetson/Raspberry Pi bisa dipakai. Ikuti petunjuk image dan MSEL dari Terasic. Image OS tidak disertakan dalam paket ini.
2. Boot DE10-Nano dengan catu yang sesuai. Terminal SSH atau console dapat dipakai saat setup. Saat operasi mandiri tidak perlu laptop.
3. Sambungkan USB kontrol STM yang sebelumnya muncul sebagai COM9 ke USB host HPS. Jika port pada foto hanya hub peripheral dan belum terhubung STM, pasang dahulu kabel menuju port kontrol STM yang benar.
4. Jalankan `lsusb`, `dmesg | tail -n 40`, dan `ls -l /dev/serial/by-id/`. Catat VID/PID serta tty yang baru muncul saat STM dipasang. Jangan memilih port console HPS sebagai STM.
5. Jika tidak ada tty, periksa kabel data, daya/hub dan driver Linux USB bridge sesuai VID/PID. Buzzer belum dapat dicoba sebelum perangkat serial benar-benar muncul.

## Tahap 2: probe dan buzzer melalui SDK

Salin seluruh isi folder hps_usb ke /opt/stm-usb pada SD/rootfs. Python 3 diperlukan. pyserial disertakan pada vendor dan tidak membutuhkan paket ARM native.

```sh
cd /opt/stm-usb
python3 bringup_usb.py
python3 bringup_usb.py --port /dev/serial/by-id/ID_STM_YANG_BENAR
python3 bringup_usb.py --port /dev/serial/by-id/ID_STM_YANG_BENAR --buzzer
```

Ganti ID_STM_YANG_BENAR dengan nama perangkat yang benar-benar muncul. Tanpa --port skrip hanya mencetak daftar port. Tanpa --buzzer skrip hanya menerima data. Buzzer baru dikirim jika ditemukan setidaknya satu frame RRC dengan CRC valid. Tidak ada command motor pada skrip ini.

Jika izin port ditolak, gunakan akun anggota grup pemilik serial yang sesuai image Linux atau sudo untuk tes setup. Tutup ROS/daemon lain yang sedang menulis ke STM sebelum tes. Jangan jalankan dua controller yang mengirim command motor bersamaan.

## Tahap 3: bunyi sekali saat boot, tanpa PC dan BAT

Setelah probe dan buzzer manual berhasil, salin stm-buzzer.service ke /etc/systemd/system/. Buat /etc/stm-usb.env dengan satu baris berikut dan ganti path aktual:

```text
STM_PORT=/dev/serial/by-id/ID_STM_YANG_BENAR
```

Kemudian:

```sh
sudo systemctl daemon-reload
sudo systemctl enable stm-buzzer.service
sudo systemctl start stm-buzzer.service
sudo journalctl -u stm-buzzer.service --no-pager
```

Service tidak diinstal oleh agen pada board. Ini template yang harus diterapkan setelah path perangkat terbukti. Jika perangkat belum muncul saat startup, service gagal dan dapat dijalankan ulang setelah perangkat tersedia. Tidak ada restart loop atau gerak motor otomatis. Menonaktifkan: `sudo systemctl disable --now stm-buzzer.service`.

## Integrasi kontrol FPGA berikutnya

FPGA mengeluarkan velocity dan permit melalui register Avalon-MM yang dibatasi, HPS membaca sequence number dan masa berlaku lalu mengirim RRC melalui USB. HPS harus membatasi nilai, menolak command kedaluwarsa dan mengirim STOP saat permit hilang. Karena Linux/USB memiliki scheduling latency, jangan mengklaim keseluruhan jalur deterministik. Jika HPS hang/USB putus, harus ada watchdog STM atau inhibit hardware independen untuk berhenti. Fitur tersebut belum dibuktikan di firmware sekarang.

Transport buzzer laptop telah terbukti. Gerak motor laptop belum berhasil pada 0,1/0,2 rps. HPS Linux, USB host DE10-Nano dan service belum diuji pada board fisik. SOF demo TTL pada folder quartus tidak mengimplementasikan USB host dan tidak dapat dipakai untuk jalur ini sendirian.
