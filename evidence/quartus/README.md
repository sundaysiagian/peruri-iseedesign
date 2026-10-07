# Bukti Quartus dan latensi IGOR

Paket ini melengkapi Proposal_IGOR_ISeeDesignITB.docx.

## Isi

- nano_resource.png dan lite_resource.png adalah screenshot asli aplikasi Quartus Prime 25.1 yang membuka laporan Fitter dalam text editor bawaan.
- reports berisi salinan laporan asli masing-masing build, termasuk Fitter, assembler, STA, QSF dan SDC.
- PERHITUNGAN_LATENSI.json memuat rumus, asumsi dan angka serialisasi UART.
- MANIFEST.json menghubungkan hash file, SOF dan angka timing lintas corner.
- arsitektur_hps_fpga.png adalah diagram rancangan. HPS dan output motor pada diagram belum diimplementasikan pada SOF rilis.

## Membuka bukti

1. Buka Quartus Prime.
2. Pilih File > Open lalu buka reports/DE10_NANO/igor.fit.summary atau reports/DE10_LITE/igor_max10.fit.summary.
3. Periksa status, device, top module dan penggunaan resource.
4. Buka file sta.summary untuk setup dan hold semua corner.
5. Gunakan file sta.rpt untuk Fmax tiap corner. Nilai minimum Nano adalah 50,37 MHz. File custom fmax.rpt lama hanya mewakili corner 100 derajat C.

## Batas waktu yang dilaporkan

Kernel DWA 0,15876 ms berasal dari simulasi. Model serial demo CLI penuh sekitar 22,77 detik mengasumsikan satu polling dan tidak memasukkan jeda host. Target 5 ms adalah anggaran integrasi sensor hingga penerimaan perintah oleh motor controller. Waktu sampai mesin bergerak belum diukur.

Sisa resource tidak menjadi jaminan timing desain berikutnya. ALM, LE dan slice bukan unit yang dapat dibandingkan satu banding satu. Semua build yang ditambah HPS, DMA, SignalTap atau motor interface harus melalui fitting dan STA ulang.
