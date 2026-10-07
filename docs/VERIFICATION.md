# Metodologi verifikasi

## Strategi

Verifikasi lokal memakai **Icarus Verilog**, **cocotb**, pemeriksaan assertion/invariant HDL, dan model integer Python yang berdiri terpisah dari RTL. Kasus neural membandingkan hasil numerik. Kasus top memeriksa scene dan penolakan fault. Kasus UART memeriksa protocol dan upload. Wrapper TinyTapeout juga diperiksa setelah sintesis generik.

| Suite | Test case | Laporan |
|---|---:|---|
| gate | 1 | [cocotb_gate.xml](../evidence/cocotb_gate.xml) |
| neural | 2 | [cocotb_neural.xml](../evidence/cocotb_neural.xml) |
| top | 2 | [cocotb_top.xml](../evidence/cocotb_top.xml) |
| uart | 1 | [cocotb_uart.xml](../evidence/cocotb_uart.xml) |
| tt | 1 | [cocotb_tt.xml](../evidence/cocotb_tt.xml) |
| tt_generic | 1 | [cocotb_tt_generic.xml](../evidence/cocotb_tt_generic.xml) |
| Total | **8** | Enam laporan tanpa failure/error |

`python verification/run.py all` menjalankan lima suite berisi tujuh test case. `python verification/run.py tt_generic` menambahkan kasus kedelapan. Workflow repository menjalankan keduanya.

## Coverage fungsional

[gate_functional_coverage.json](../verification/gate_functional_coverage.json) merekam **13.078 kasus** dan **12 dari 12 bin hasil fungsional**. Ini mengukur outcome pemeriksaan gerbang. Angka tersebut tidak mewakili line coverage, toggle coverage, atau bukti formal.

## Referensi numerik neural

Jaringan **24 → 64 → 64 → 4** memakai operand signed 16 bit dan accumulator 40 bit. Seratus vektor menghasilkan 400 output yang cocok tepat dengan model integer Python. Seluruh inferensi yang diuji mempunyai latency 18.192 siklus.

Sumber: [neural_reference.py](../reference_model/neural_reference.py), [hasil cocotb](../verification/neural_cocotb_results.json), dan [RTL core](../rtl/igor_neural_core.v).

## Fault injection

| Ancaman / kondisi | Hasil skenario simulasi | Izin |
|---|---|---:|
| Replay sequence | PASS | 0 |
| Upload terpotong | PASS | 0 |
| Alamat tidak berurutan | PASS | 0 |
| CRC salah | PASS | 0 |
| Write setelah lock | PASS | 0 |
| Peta unknown | PASS | 0 |
| Semua kandidat terblokir | PASS | 0 |
| Timeout | PASS | 0 |
| Emergency | PASS | 0 |

Sumber: [fault_status.csv](../evidence/audit/fault_status.csv), [top_audit.log](../evidence/audit/top_audit.log), dan [uart_audit.log](../evidence/audit/uart_audit.log). Sebagian pengujian memperpendek parameter deadline/freshness agar fault bisa diinjeksikan cepat. CRC mendeteksi korupsi transmisi dan tidak mengautentikasi pengirim.

## Pemeriksaan motor Verilog

Testbench serializer memeriksa **10 frame, 256 byte**, empat motor ID, empat speed level, arah, float32, dan CRC. Testbench controller memeriksa boot STOP, buzzer saat disarmed, latch pilihan, refresh, timeout STOP, serta STOP ketika arm dilepas.

Dokumentasi dan perintah ada pada [JetAuto](JETAUTO.md). Status tiap jenis bukti dibatasi pada [RESULTS_AND_SCOPE.md](RESULTS_AND_SCOPE.md). Verilator dan formal verification tidak tercantum sebagai metode yang telah dijalankan.
