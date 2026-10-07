# Latency resource dan power

## Kernel pada 50 MHz

| Komponen | Siklus | Waktu | Cakupan |
|---|---:|---:|---|
| DWA empat tile | 7.938 | 158,76 µs | Enam scene simulasi |
| Neural serial | 18.192 | 363,84 µs | 100 vektor, 400 output |
| Jumlah aritmetis dua kernel | 26.130 | 522,60 µs | Proyeksi penjumlahan, bukan integrasi terukur |

`t = cycles / 50.000.000`. Enam scene memiliki counter yang sama pada jalur evaluasi lengkap. Abort dan timeout adalah jalur terpisah.

DWA memproses 10.240 pose per run. Angka turunan adalah sekitar **64,5 juta evaluasi pose/detik** dan headroom sekitar **126×** terhadap periode 20 ms. Keduanya merupakan rasio kernel, bukan throughput robot yang telah diukur.

## Resource implementasi

| Resource | DE10-Nano IGOR | DE10-Lite IGOR | Nano motor empat speed |
|---|---:|---:|---:|
| Logic | 4.964 ALM | 18.984 LE | 194 ALM |
| Register | 1.554 | 1.539 | 176 |
| Block memory | 1.051.008 bit | 1.051.008 bit | 0 |
| RAM block | 131 M10K | Lihat Fitter MAX 10 | 0 |
| Arithmetic | 10 DSP | 19 elemen multiplier 9 bit | 0 DSP |
| Minimum recorded slack | +0,120 ns | +0,107 ns hold | +0,160 ns |

Lite mempunyai setup slack **+1,140 ns** dan recorded Fmax **53,02 MHz**. Angka ALM, LE, dan multiplier 9 bit adalah satuan arsitektur yang berbeda. Jangan membandingkannya sebagai jumlah gate yang setara.

Sumber: [laporan Quartus](../evidence/quartus/reports), [screenshot Nano](../evidence/quartus/nano_resource.png), [screenshot Lite](../evidence/quartus/lite_resource.png), dan [motor build provenance](../robot/jetauto/FPGA_UART_TTL_MULTISPEED/evidence/build_provenance.json).

## Model biaya UART

Protokol IGOR memakai request 8 byte dan response 8 byte pada 115200 baud 8N1. Satu transaksi nominal membutuhkan `16 × 10 / 115200 ≈ 1,389 ms`. Script DWA mengirim sel map satu per satu. Model untuk 16.392 transaksi sekitar **22,77 detik**, sebelum overhead host, USB, parser, dan retry.

Karena itu, latency kernel 158,76 µs berbeda dari waktu demo keseluruhan. [Model transport](../evidence/quartus/PERHITUNGAN_LATENSI.json) mencatat asumsi dan target integrasi. Sensor-to-motor belum menjadi hasil terukur.

## Power Analyzer

| Komponen estimate | Daya |
|---|---:|
| Core dynamic | 71,96 mW |
| Core static | 414,18 mW |
| IO | 20,55 mW |
| Total thermal estimate | **506,69 mW** |

Sumber: [igor.pow.summary](../evidence/audit/power/igor.pow.summary). Report bersifat **vectorless dengan confidence Low** karena informasi toggle terbatas. Estimate tidak memodelkan aktivitas Linux HPS dan bukan pengukuran daya seluruh board atau robot.

RTL memiliki pembaruan register kondisional. Tidak ada implementasi explicit clock gating yang mematikan clock tile idle. Strategi lanjutan dapat memanfaatkan clock enable dan aktivitas switching yang terukur, kemudian mengulang Power Analyzer.

## Membandingkan platform secara objektif

DE10-Nano memberi jalur FPGA dan HPS ARM untuk integrasi Linux, USB host, serta transport data. DE10-Lite memberi target lab MAX 10 untuk memeriksa RTL dan UART dengan perangkat yang tersedia. Hasil kernel berasal dari RTL yang sama, sementara resource dan batas perangkat berbeda.

Belum ada benchmark CPU ARM untuk workload yang sama. Peningkatan neural melalui DSP paralel adalah arah pengembangan yang memerlukan banking ROM, perubahan scheduler, regresi numerik, dan fitting ulang. Tidak ada angka speedup CPU atau Fmax neural paralel yang dinyatakan sebagai hasil.
