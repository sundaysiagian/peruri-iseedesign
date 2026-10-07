# Knowledge dan takeover proyek

## Keputusan awal

Repository ini adalah paket source dan bukti yang dipilih untuk proyek IGOR. Mulai dari tujuan Anda pada tabel berikut, kemudian jalankan pemeriksaan file sebelum memilih programming image.

| Pekerjaan | Entry point |
|---|---|
| Mengulang simulasi | [Quickstart](QUICKSTART.md) |
| Menemukan setiap module | [RTL_MODULES.md](RTL_MODULES.md) |
| Melanjutkan architecture | [ARCHITECTURE.md](ARCHITECTURE.md) |
| Memprogram board | [FPGA_PROGRAMMING.md](FPGA_PROGRAMMING.md) |
| Meninjau sembilan fault | [VERIFICATION.md](VERIFICATION.md) |
| Menjawab latency/resource/power | [PERFORMANCE.md](PERFORMANCE.md) |
| Membuat demo | [DEMO_GUIDE.md](DEMO_GUIDE.md) |
| Menguji STM | [JETAUTO.md](JETAUTO.md) |
| Melanjutkan ASIC | [TINYTAPEOUT.md](TINYTAPEOUT.md) |
| Melihat status integrasi | [RESULTS_AND_SCOPE.md](RESULTS_AND_SCOPE.md) |

## File yang menentukan hasil

- `rtl/` adalah common accelerator source untuk simulasi.
- `fpga_de10_nano/rtl/` dan `fpga_de10_lite/rtl/` menjaga project board tetap portable.
- `assets/` menyediakan bobot dan expected neural data.
- `verification/` memuat model-driven tests dan output JSON.
- `evidence/build_evidence.json` mengidentifikasi keempat SOF dengan SHA256.
- `evidence/RELEASE_MANIFEST.json` mengidentifikasi file publik pada snapshot release.
- `docs/flowcharts/IGOR_RTL_Flowchart.io` merupakan sumber diagram yang dapat diedit.
- `robot/jetauto/FPGA_UART_TTL_MULTISPEED/` adalah target motor empat speed tersendiri.

## Invariant yang harus dipertahankan

1. Output command planner tetap melalui gerbang pada `igor_top`.
2. Peta tidak dipakai sampai frame lengkap, sequence dan commit diterima.
3. Konfigurasi dibatasi oleh lock.
4. Timeout, emergency, dan invalid input harus meniadakan izin.
5. Model neural integer tetap menjadi pembanding saat arithmetic diubah.
6. Port dan protocol planner tidak ditukar dengan UART STM.
7. Setiap perubahan RTL membutuhkan sinkronisasi copy board dan test ulang.

## Urutan pekerjaan berikutnya

Rekam programming dan readback pada board lab, kemudian ulangi pada board onsite. Untuk motor, simpan observasi terbaru per-ID dan all-wheel setelah troubleshooting. Setelah transport dipastikan, implementasikan bridge command IGOR yang mempertahankan sequence dan expiry. Ukur latency keseluruhan setelah jalur tersebut ada. Flow ASIC dilanjutkan melalui workflow fisik tersendiri.

## Praktik perubahan

Gunakan branch untuk perubahan. Jalankan validator, cocotb, dan test serializer ketika relevan. Untuk perubahan RTL FPGA, rebuild target yang terpengaruh, update provenance dan hash, lalu review timing. Jangan mengganti measured result dengan projection. Report historis tetap dapat membantu diagnosis, sedangkan klaim release mengacu pada file yang tercantum pada snapshot ini.

## Identitas commit

```bash
git config user.name "wlmoi"
git config user.email "16523109@std.stei.itb.ac.id"
```

Konfigurasi tersebut berlaku pada repository ini. Akun yang melakukan push tetap harus mempunyai akses tulis ke `sundaysiagian/peruri-iseedesign`. Identitas commit tidak memberikan izin GitHub.
