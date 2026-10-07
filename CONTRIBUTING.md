# Contributing

Pertahankan source, hasil numerik, dan bukti implementation sebagai satu perubahan yang dapat ditinjau.

1. Buat branch dari `main`.
2. Ubah source canonical, lalu sinkronkan copy board yang relevan.
3. Jalankan `python scripts/validate_repository.py`.
4. Jalankan `python verification/run.py all` dan `python verification/run.py tt_generic`.
5. Untuk RTL motor, jalankan test serializer dan controller tanpa motion.
6. Untuk perubahan FPGA, rebuild board yang relevan dan perbarui provenance serta image hash.
7. Dokumentasikan trigger, hasil, dan validation dalam commit atau pull request.

Test hardware harus mencatat board, image, port, supply, command, dan observasi. CI tidak mengirim command motor. Dokumen hasil menyatakan cakupan simulasi, estimate, atau pengukuran sesuai bukti yang ada.

Jalankan `python scripts/create_manifest.py` setelah file release disiapkan dengan `git add`. Review manifest sebelum commit. Perubahan source yang baru akan membutuhkan update hasil dan metadata yang relevan, bukan sekadar perubahan checksum.
