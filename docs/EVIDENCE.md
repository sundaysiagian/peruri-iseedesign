# Indeks bukti

## Hasil numerik dan metode

| Klaim | Sumber utama |
|---|---|
| 7.938 siklus pada enam scene | [scene_latency.csv](../evidence/audit/scene_latency.csv) dan [scene_cocotb_results.json](../verification/scene_cocotb_results.json) |
| 400 output neural cocok | [neural_cocotb_results.json](../verification/neural_cocotb_results.json) |
| 13.078 kasus, 12 bin fungsional | [gate_functional_coverage.json](../verification/gate_functional_coverage.json) |
| Sembilan fault dengan permit nol | [fault_status.csv](../evidence/audit/fault_status.csv) |
| Delapan test case | [cocotb XML](../evidence) dan [build_evidence.json](../evidence/build_evidence.json) |
| Netlist generic wrapper | [synthesis report](../evidence/asic_generic_synthesis_noabc.log) dan [netlist](../evidence/asic_generic_netlist.v) |
| Power estimate | [igor.pow.summary](../evidence/audit/power/igor.pow.summary) |
| Model transport | [PERHITUNGAN_LATENSI.json](../evidence/quartus/PERHITUNGAN_LATENSI.json) |

## Quartus

- [DE10-Nano resource screenshot](../evidence/quartus/nano_resource.png).
- [DE10-Lite resource screenshot](../evidence/quartus/lite_resource.png).
- [Laporan asli kedua board](../evidence/quartus/reports).
- [Report Nano bersama SOF](../fpga_de10_nano/quartus/output_files).
- [Report Lite bersama SOF](../fpga_de10_lite/quartus/output_files).
- [Report motor empat speed](../robot/jetauto/FPGA_UART_TTL_MULTISPEED/evidence).

## GTKWave

| View | Screenshot | Saved view |
|---|---|---|
| DWA normal | [01_dwa_normal.png](../evidence/waveforms/01_dwa_normal.png) | [01_dwa_normal.gtkw](../evidence/waveforms/01_dwa_normal.gtkw) |
| Emergency / fault | [02_dwa_fault.png](../evidence/waveforms/02_dwa_fault.png) | [02_dwa_fault.gtkw](../evidence/waveforms/02_dwa_fault.gtkw) |
| Neural | [03_neural.png](../evidence/waveforms/03_neural.png) | [03_neural.gtkw](../evidence/waveforms/03_neural.gtkw) |
| UART | [04_uart.png](../evidence/waveforms/04_uart.png) | [04_uart.gtkw](../evidence/waveforms/04_uart.gtkw) |
| DWA result | [05_dwa_result.png](../evidence/waveforms/05_dwa_result.png) | [05_dwa_result.gtkw](../evidence/waveforms/05_dwa_result.gtkw) |
| Neural result | [06_neural_result.png](../evidence/waveforms/06_neural_result.png) | [06_neural_result.gtkw](../evidence/waveforms/06_neural_result.gtkw) |

Compressed VCD berada pada [folder waveforms](../evidence/waveforms). Jalankan `python scripts/unpack_waveforms.py` sebelum membuka trace. Compression mempertahankan trace dan menghindari file VCD besar pada Git.

## Integrity

[build_evidence.json](../evidence/build_evidence.json) mengidentifikasi empat SOF dengan full SHA256. [RELEASE_MANIFEST.json](../evidence/RELEASE_MANIFEST.json) mencatat file pada snapshot publik. Validator memeriksa navigation, sumber QSF, copy RTL board, report test, diagram, dan hash.

Bukti historis mempertahankan tanggal pembuatannya. Regressi baru dapat menghasilkan XML/JSON baru dengan timestamp baru. Commit dan artifact CI menghubungkan perubahan dengan run yang relevan.
