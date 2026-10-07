# Panduan demo live dan video

## Tujuan

Tampilkan alur kerja hardware yang mudah diikuti: input, proses RTL, hasil numerik, safety decision, dan bukti implementasi. Durasi yang disarankan **3–5 menit**. Rundown ini adalah panduan produksi, bukan catatan demo board yang telah dilakukan.

## Rundown empat menit

| Waktu | Tampilan | Narasi dan bukti |
|---|---|---|
| 00:00–00:25 | Board, nama tim, diagram | IGOR mengubah costmap menjadi keputusan lokal yang dapat diperiksa |
| 00:25–01:05 | Diagram empat tile | 512 kandidat, 20 pose tiap kandidat, 4 evaluator, gate output |
| 01:05–01:40 | Quartus dan SOF | Top entity, device, resource, timing, serta image target |
| 01:40–02:20 | GTKWave DWA | Tunjukkan start, busy, done, permit, dan 7.938 siklus |
| 02:20–02:55 | Neural dan model | 24 → 64 → 64 → 4, 100 vektor, 400 output cocok |
| 02:55–03:30 | Fault tests | Empty dapat memberi permit, blocked/unknown dan emergency menolak sesuai kasus |
| 03:30–04:00 | Repository dan hasil | Source, tests, project, SOF, dan technical report dapat diambil dari repo |

Jika board tersedia, masukkan programming JTAG dan UART readback pada segmen 01:05–02:20. Jika menggunakan simulasi, beri label **RTL simulation** pada shot. Beri label **board measurement** hanya untuk rekaman board sebenarnya.

## Persiapan demo live

1. Pilih board, project, dan SOF yang sesuai.
2. Jalankan pemeriksaan repository dan catat hash image.
3. Program lewat JTAG mengikuti [FPGA_PROGRAMMING.md](FPGA_PROGRAMMING.md).
4. Hubungkan adapter TTL 3,3 V ke UART planner, bukan port motor.
5. Jalankan status, ROM readback, neural check, dan satu DWA scene.
6. Reset sebelum mengganti scene. Rekam empty, blocked, dan unknown beserta output terminal.
7. Simpan log yang menghubungkan board, image, command, dan hasil.

## Shot yang wajib terlihat

- Nama top module dan device pada Quartus.
- Screenshot atau report resource yang terbaca.
- Timing counter DWA dan hasil neural di GTKWave.
- Output permit serta fault pada kasus penolakan.
- Board dan kabel apabila demonstrasi fisik dilakukan.
- STOP dan roda bebas berputar jika segmen motor ditambahkan.

Demo motor memakai jalur [JetAuto](JETAUTO.md), yang berbeda dari UART planner. Labelkan segmen tersebut sebagai transport/controller test sampai command IGOR terintegrasi.

## Menambahkan video ke repository

Simpan tautan video aktual bersama tanggal, commit, board, SOF SHA256, dan cakupan yang ditunjukkan. Gunakan GitHub Release atau platform video untuk rekaman besar. Thumbnail dapat ditempatkan pada `docs/assets/`. Jangan menambahkan tautan atau hasil yang belum ada.
