# Audit klaim IGOR

Audit_Bukti_RTL_dan_Klaim_IGOR.docx menjawab seluruh pertanyaan fault, metodologi, baseline TT07, determinisme, gerbang, daya, costmap, neural paralel, clock enable, ASIC dan uji fisik.

- DWA audit: 12402 checks dan 556939 sampel invariant, 0 error.
- UART CRC audit: 16405 checks, 0 error. Divider 8 untuk simulasi cepat.
- Power: 506.69 mW vectorless, confidence Low. Aktivitas HPS belum dimodelkan.
- ASIC SKY130 dan pengujian board fisik belum selesai.

Jalankan reproduction/Run-Audit.ps1 untuk mengulang simulasi. Testbench deadline 10000 dan freshness 250000 berbeda dari rilis 1000000. Power dilakukan pada salinan build, tidak mengganti SOF rilis. Masalah JetAuto ada di folder UART_JETAUTO_TERPISAH.
