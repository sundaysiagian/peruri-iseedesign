# Membuka Quartus dan memprogram FPGA

## Pilih target

| Parameter | DE10-Nano | DE10-Lite |
|---|---|---|
| FPGA | Cyclone V SE `5CSEBA6U23I7` | MAX 10 `10M50DAF484C7G` |
| Top entity | `igor_uart_top` | `igor_de10_lite_top` |
| Project | [igor.qpf](../fpga_de10_nano/quartus/igor.qpf) | [igor_max10.qpf](../fpga_de10_lite/quartus/igor_max10.qpf) |
| Image | [igor.sof](../fpga_de10_nano/quartus/output_files/igor.sof) | [igor_max10.sof](../fpga_de10_lite/quartus/output_files/igor_max10.sof) |
| Clock | 50 MHz, FPGA pin V11 | 50 MHz, FPGA pin P11 |
| Programmer | USB-Blaster II onboard | USB-Blaster onboard |

Gunakan Quartus Standard 25.1 dengan device support sesuai FPGA. Folder board harus tetap utuh karena QSF mengacu ke RTL dan ROM melalui path relatif. `.sof` adalah konfigurasi SRAM sementara yang perlu dimuat lagi setelah power-off.

## Langkah programming

1. Clone repository atau download ZIP dan ekstrak seluruh isi.
2. Buka Quartus, pilih **File → Open Project**, lalu pilih QPF board Anda.
3. Pastikan **Assignments → Device** dan top entity sama dengan tabel.
4. Untuk rebuild, pilih **Processing → Start Compilation**. Review Map, Fitter, Assembler, dan Timing Analyzer. Image yang disertakan sudah memiliki bukti build.
5. Nyalakan board dan sambungkan port **USB-Blaster / JTAG** ke laptop.
6. Buka **Tools → Programmer**. Pada **Hardware Setup**, pilih programmer board. Gunakan mode **JTAG**.
7. Klik **Auto Detect**, lalu pilih device FPGA yang cocok. Pada chain DE10-Nano, konfigurasi image ditujukan ke FPGA Cyclone V.
8. Gunakan **Change File / Add File** untuk memilih `.sof` dari folder board yang sama.
9. Centang **Program/Configure**, klik **Start**, lalu simpan bukti hasil 100% Successful.
10. Tekan **KEY0** untuk reset. Lanjutkan pemeriksaan UART. Programming selesai menjadi bukti konfigurasi, sedangkan output UART membuktikan fungsi.

## UART planner

Gunakan adapter **USB–TTL 3,3 V**, **115200 baud, 8 data bit, no parity, 1 stop bit**, tanpa flow control. USB-Blaster tidak menjadi UART.

| Sambungan | DE10-Nano JP1 | DE10-Lite JP1 |
|---|---|---|
| Adapter TX → FPGA RX | pin 1, FPGA V12 | pin 1, FPGA V10 |
| Adapter RX ← FPGA TX | pin 2, FPGA E8 | pin 2, FPGA W10 |
| Common GND | pin 12 atau 30 | pin 12 atau 30 |

Periksa penanda pin 1 pada board. Tidak perlu menghubungkan VCC adapter. GPIO ini memakai TTL 3,3 V, bukan RS-232, USB D+/D−, atau TTL 5 V.

Set **SW2=0**, **SW3=0**, lepas **KEY1**, lalu tekan-lepas KEY0. LED0 adalah permit, LED2 busy, LED3 done, dan LED7:4 fault. Wrapper Lite menambahkan heartbeat pada LEDR8 dan aktivitas RX pada LEDR9.

## Pemeriksaan host

Jalankan dari root repository. Ganti `COM_FPGA` dengan port adapter UART FPGA yang sebenarnya. COM9 pada eksperimen JetAuto tidak otomatis menjadi port FPGA.

```powershell
py -m pip install -r fpga_de10_nano\host\requirements.txt
py fpga_de10_nano\host\igor_uart.py --port COM_FPGA status
py fpga_de10_nano\host\igor_uart.py --port COM_FPGA rom-check
py fpga_de10_nano\host\igor_uart.py --port COM_FPGA nn-test
py fpga_de10_nano\host\igor_uart.py --port COM_FPGA dwa-demo --map empty
```

Untuk Lite, ganti prefix menjadi `fpga_de10_lite/host`. Monitor grafis tersedia pada [uart_monitor.py](../fpga_de10_lite/host/uart_monitor.py).

Reset KEY0 sebelum setiap `dwa-demo`, kemudian ulangi dengan `--map blocked` dan `--map unknown`. Upload 16.384 cell memakai transaksi satu per byte, sehingga transport berlangsung puluhan detik. Readback neural diharapkan memeriksa 100 vektor dan 400 output. Readback DWA memberikan index, v, omega, fault, dan siklus.

Lease hasil dan freshness map adalah 20 ms. Script demo bersifat satu kali. Penerjemahan ke controller motor dibahas terpisah pada [JetAuto](JETAUTO.md).

## Simpan bukti acceptance

Rekam identitas board, hash SOF, log JTAG, command host, output UART, dan satu foto atau video. Bandingkan output dengan [scene simulasi](../evidence/audit/scene_latency.csv). Cakupan hasil yang tersedia saat publikasi ada pada [RESULTS_AND_SCOPE.md](RESULTS_AND_SCOPE.md).
