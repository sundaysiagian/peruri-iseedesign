# DE10-Nano UART RX reference and STM cross-check

Referensi receiver dari proyek `de10_nano_uart_buzzer` yang diberikan pengguna pada 7 Oktober 2026. Seluruh empat sumber Verilog, QPF, QSF, SDC, testbench, dan capture HEX yang dibutuhkan disertakan agar proyek dapat dibuka dari folder ini.

## Format yang cocok dengan transport STM

| Parameter | Receiver referensi | Transmitter motor repository |
|---|---|---|
| Clock | 50 MHz | 50 MHz |
| UART | 1.000.000 baud, 8N1, LSB first | Sama |
| Header | `AA 55` | Sama |
| Struktur | `AA 55 TYPE LEN PAYLOAD CRC` | Sama |
| Length | Jumlah byte payload, maksimum 32 | 22 byte untuk empat motor |
| CRC | CRC8 reflected `8C`, initial 0, atas TYPE + LEN + PAYLOAD | Sama |
| Fungsi | Memvalidasi paket yang masuk ke FPGA | Mengirim command ke STM |

Receiver tidak memasukkan header atau byte CRC ke perhitungan CRC. `com9_packet_rx` memperbarui payload keluaran hanya setelah CRC cocok. Timeout antar-byte adalah 100.000 clock atau 2 ms pada 50 MHz. Payload byte pertama berada pada bit `[7:0]`.

Kesamaan framing tidak berarti semua TYPE memiliki semantik yang sama. `GPIO_TYPE=10` hex adalah konvensi aplikasi demo ini, bukan command GPIO STM yang sudah diidentifikasi. Default receiver membunyikan buzzer lokal untuk setiap paket valid, dibatasi cooldown satu detik. Buzzer lokal ini berbeda dari command buzzer STM function `02`.

Untuk motor, cross-check [serializer four-speed](../FPGA_UART_TTL_MULTISPEED/rtl/stm_packet_tx_multispeed.v), [hasil paket RTL](../FPGA_UART_TTL_MULTISPEED/tb/rtl_captured_packets.hex), dan [panduan JetAuto](../../../docs/JETAUTO.md). Motor memakai function `03`, subcommand `01`, empat wire ID `0..3`, dan float32 little-endian dalam RPS. Paket empat motor berukuran 27 byte termasuk header dan CRC.

## Modul dan Quartus

Top module: **`de10_nano_uart_buzzer`**. Buka [de10_nano_uart_buzzer.qpf](de10_nano_uart_buzzer.qpf). Target QSF adalah **Cyclone V 5CSEBA6U23I7**.

Alur RTL: `UART_RX` → `uart_rx_8n1` → byte 8 bit → `com9_packet_rx` → TYPE 8 bit, LEN 8 bit, payload 256 bit, valid/error → `uart_gpio_buzzer_demo` → GPIO 8 bit, buzzer, indikator.

| Port referensi | Pin FPGA | Header / peran |
|---|---|---|
| FPGA_CLK1_50 | V11 | Clock 50 MHz |
| KEY0_N | AH17 | Reset aktif rendah |
| UART_RX | V12 | JP1 pin 1, masukan UART |
| BUZZER_CTRL | E8 | JP1 pin 2, kontrol driver buzzer |
| GPIO_MASK_OUT[0..7] | W12, D11, D8, AH13, AF7, AH14, AF4, AH3 | JP1 pin 3..10 |

Pada bitstream **motor**, E8 dipakai sebagai **UART TX**. Pada bitstream **referensi ini**, E8 dipakai sebagai **BUZZER_CTRL**. Sesuaikan wiring dengan proyek yang diprogram. Ground bersama dapat memakai JP1 pin 12 atau 30. GPIO memakai logika 3,3 V, dan buzzer memerlukan driver yang sesuai.

Untuk jalur FPGA → STM, gunakan proyek motor TX, hubungkan TX FPGA ke RX STM yang telah diidentifikasi, lalu ground bersama. Referensi RX ini berguna untuk memeriksa arah STM TX → FPGA RX. Jika akses STM hanya melalui USB CH9102, gunakan [HPS USB host](../../hps_usb). Port GPIO bukan USB host, dan nama COM9 hanya berlaku di Windows.

## Simulasi tanpa menggerakkan robot

Jalankan dari folder ini dengan Icarus Verilog di PATH:

```powershell
iverilog -g2012 -s tb_uart_gpio_buzzer -o uart_reference_sim.out uart_rx_8n1.v com9_packet_rx.v uart_gpio_buzzer_demo.v tb_uart_gpio_buzzer.v
vvp uart_reference_sim.out
```

Testbench memutar ulang capture HEX melalui waveform UART, memeriksa paket valid, CRC salah, stop bit salah, panjang berlebih, timeout, toleransi baud, commit GPIO, dan cooldown buzzer. [Hasil verifikasi 7 Oktober 2026](simulation_result.txt): PASS untuk 314 paket capture dan 5 paket buatan. Top module juga berhasil dikompilasi dengan Icarus. Ini pengujian simulasi receiver, bukan bukti pemrograman board atau motor fisik. File `.sof` receiver tidak disertakan karena belum dibangun dalam integrasi referensi ini. Bitstream motor yang sudah ada tetap berada pada proyek motor tersendiri.
