# Quickstart

## Pilih lingkungan

Simulasi memerlukan **Python 3.11**, **Icarus Verilog**, dan dependency pada [requirements.txt](../requirements.txt). Quartus diperlukan untuk rebuild FPGA. GTKWave digunakan untuk inspeksi waveform.

## Linux atau WSL

```bash
git clone https://github.com/sundaysiagian/peruri-iseedesign.git
cd peruri-iseedesign
sudo apt-get update
sudo apt-get install -y iverilog make gtkwave
python3 -m venv .venv
. .venv/bin/activate
python -m pip install -r requirements.txt
python scripts/validate_repository.py
python verification/run.py all
python verification/run.py tt_generic
```

Suite `all` menghasilkan tujuh test case. `tt_generic` memeriksa netlist generik yang disertakan dan menambah satu test case. Berhasil berarti seluruh XML tidak memiliki `failure` atau `error`.

## Windows PowerShell

Pasang Python 3.11 dan Icarus Verilog. Runner mengenali instalasi Icarus di `C:\iverilog\bin` serta executable pada PATH.

```powershell
git clone https://github.com/sundaysiagian/peruri-iseedesign.git
cd peruri-iseedesign
py -3.11 -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
.\.venv\Scripts\python.exe scripts\validate_repository.py
.\.venv\Scripts\python.exe verification\run.py all
.\.venv\Scripts\python.exe verification\run.py tt_generic
```

Tidak perlu mengubah execution policy untuk menjalankan executable Python langsung.

## Membaca waveform

Trace besar disimpan dengan gzip agar repository tetap ringkas. Ekstraksi dilakukan di lokasi yang digunakan saved view GTKWave.

```bash
python scripts/unpack_waveforms.py
gtkwave evidence/waveforms/vcd/igor_top.vcd evidence/waveforms/05_dwa_result.gtkw
gtkwave evidence/waveforms/igor_neural_first_inference.vcd evidence/waveforms/06_neural_result.gtkw
```

Screenshot yang sudah tersedia dapat langsung dibuka melalui [indeks bukti](EVIDENCE.md).

## Membuka FPGA

1. Clone atau salin repository secara utuh.
2. Buka `fpga_de10_nano/quartus/igor.qpf` untuk **5CSEBA6U23I7** atau `fpga_de10_lite/quartus/igor_max10.qpf` untuk **10M50DAF484C7G**.
3. Pilih programming image dari folder board yang sama.
4. Ikuti [panduan JTAG dan UART](FPGA_PROGRAMMING.md).

## Pemeriksaan robot tanpa command motor

```bash
python robot/jetauto/verify_driver.py
python robot/jetauto/test_rtl_packets_on_stm.py
```

Kedua perintah tersebut memeriksa paket tanpa membuka port serial. Untuk tes gerak, gunakan [panduan JetAuto](JETAUTO.md) dan launcher yang meminta pilihan motion secara eksplisit.
