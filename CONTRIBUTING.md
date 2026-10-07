# Contributing

Pertahankan source, hasil numerik, dan bukti implementation sebagai satu perubahan yang dapat ditinjau.

1. Buat branch dari `main`.
2. Ubah source canonical, lalu sinkronkan copy board yang relevan.
3. Untuk perubahan RTL, jalankan `python verification/run.py all` dan `python verification/run.py tt_generic`. Untuk RTL motor, jalankan test serializer dan controller tanpa motion.
4. Untuk perubahan FPGA, rebuild board yang relevan dan perbarui provenance serta image hash.
5. Dokumentasikan trigger, hasil, dan validation dalam commit atau pull request.
6. Setelah semua edit selesai, jalankan `python scripts/create_manifest.py`, lalu `python scripts/validate_repository.py`.
7. Commit file yang berubah **bersama** `evidence/RELEASE_MANIFEST.json`, lalu push.

Test hardware harus mencatat board, image, port, supply, command, dan observasi. CI tidak mengirim command motor. Dokumen hasil menyatakan cakupan simulasi, estimate, atau pengukuran sesuai bukti yang ada.

Manifest mencakup dokumentasi, termasuk README. Setiap edit README juga memerlukan regenerasi manifest. Jika masih mengedit setelah regenerasi, ulangi dua perintah berikut sebelum commit:

```powershell
python scripts/create_manifest.py
python scripts/validate_repository.py
git add .
git commit -m "Update documentation and release manifest"
git push origin main
```

Generator membaca file tracked dan untracked yang tidak diabaikan Git. Review perubahan manifest sebelum commit. CI memeriksa manifest yang di-commit, sehingga tidak memperbaruinya otomatis saat validasi. Pada Windows, `PUSH_READY_REPOSITORY.bat` menjalankan regenerasi dan validasi sebelum commit dan push. Perubahan source yang baru membutuhkan update hasil dan metadata yang relevan, bukan sekadar perubahan checksum.
