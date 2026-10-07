# Hasil dan cakupan bukti

Status ini membatasi klaim sesuai jenis bukti. Halaman utama menampilkan pencapaian, sedangkan tabel ini memberi konteks untuk reviewer dan pengembang berikutnya.

| Area | Bukti yang tersedia | Acceptance berikutnya |
|---|---|---|
| RTL planner | Scene, counter, fault scenario, serta assertion/invariant yang dijalankan | Tambahkan scene baru dan pengujian batas |
| Neural | 400 output cocok tepat pada 100 vektor | Integrasikan ke ranking dan ulangi regresi |
| FPGA Nano dan Lite | Map, fit, assembler, timing, serta SOF | Program board dan rekam readback UART |
| Output gate | Pada `igor_top`, tiga command output didorong instance gate | Pertahankan invariant pada bridge motor |
| Daya | Estimate Quartus 506,69 mW, vectorless Low confidence | Tambahkan activity trace dan ukur daya board |
| ASIC | Wrapper, metadata, generic synthesis, serta tes netlist generik | Jalankan PDK flow, tile fit, DRC, LVS, STA, dan gate-level test |
| JetAuto | UART protocol, paket RTL, buzzer, dan observasi setiap roda bekerja individual | Rekam acceptance terbaru semua roda bersamaan |
| Tanpa laptop | GPIO UART RTL dan template HPS USB tersedia | Identifikasi UART STM atau boot HPS dan integrasikan transport |
| End-to-end | Model transport dan target integrasi | Ukur sensor, gate, controller, dan gerak aktual |
| Video demo | Rundown dan daftar shot tersedia | Tambahkan rekaman aktual dan metadata run |

Pada pengujian JetAuto sebelumnya, seluruh roda bekerja individual. Rear-left mengalami delay pada rear pair dan tidak bergerak pada group run sebelum troubleshooting terbaru. Rerun terbaru selesai mengirim STOP, tetapi hasil fisik setelah perbaikan belum dicatat. Exit code host tidak menjadi motor acknowledgement.

Prototipe TinyTapeout memuat gerbang, bukan seluruh DWA, neural core, SRAM costmap, atau USB controller. Generic synthesis bukan hasil GDS dan bukan estimasi area PDK. Coverage yang disertakan adalah bin outcome fungsional. Verilator dan formal proof tidak digunakan.

Klaim deterministik dibatasi pada jadwal evaluasi lengkap dan enam scene yang direkam. Jumlah waktu kernel DWA dan neural adalah proyeksi arithmetic karena kedua jalur belum digabung. Keunggulan terhadap CPU memerlukan benchmark identik.

## Rekaman acceptance yang diperlukan

Untuk FPGA, simpan device, hash image, hasil programming JTAG, output UART, dan dokumentasi board. Untuk robot, simpan per-ID, pair, diagonal, all-wheel, arah, setpoint RPM, STOP, dan kondisi supply. Untuk ASIC, simpan commit, versi flow/PDK, reports, dan artifact signoff.

Dokumentasi dapat diperbarui setelah bukti tersebut tersedia. Riwayat hasil tidak diganti hanya karena sebuah command selesai tanpa error.
