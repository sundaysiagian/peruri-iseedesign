# Pencapaian yang dapat dipajang

Halaman ini merangkum hasil yang bisa dibawa ke presentasi, review desain, dan diskusi arsitektur. Setiap pencapaian disertai bukti yang dapat dibuka.

## Empat evaluator dengan jadwal yang jelas

**512 kandidat dan 10.240 evaluasi pose** selesai dalam **7.938 siklus**, setara **158,76 µs pada 50 MHz**, pada enam scene yang diuji. Pembagian kerja terlihat pada RTL, jadwal per kandidat, dan counter top.

Bukti: [scene latency](../evidence/audit/scene_latency.csv), [arsitektur](ARCHITECTURE.md), dan [GTKWave DWA](../evidence/waveforms/05_dwa_result.png).

## Keputusan gerak melewati gerbang

Pada top planner, permit, v, dan omega berasal dari gerbang pemeriksaan. Sembilan skenario fault menghasilkan izin nol. Gerbang sendiri mempunyai 13.078 kasus regresi dengan 12/12 bin hasil fungsional.

Bukti: [gate RTL](../rtl/igor_safety_security_gate.v), [fault table](../evidence/audit/fault_status.csv), dan [functional coverage](../verification/gate_functional_coverage.json).

## Neural core diperiksa sampai output integer

Jaringan **24 → 64 → 64 → 4** memberi **400 output yang cocok tepat** untuk 100 input vector terhadap model integer independen. Semua inferensi yang diuji memakai 18.192 siklus.

Bukti: [model Python](../reference_model/neural_reference.py), [hasil](../verification/neural_cocotb_results.json), dan [GTKWave neural](../evidence/waveforms/06_neural_result.png).

## Dua implementasi FPGA yang dapat dibuka

DE10-Nano dan DE10-Lite mempunyai project, pin assignment, report, dan SOF masing-masing. Target lab dan onsite dipisahkan agar pemilihan board tidak ambigu.

Bukti: [Nano](../fpga_de10_nano/quartus/igor.qpf), [Lite](../fpga_de10_lite/quartus/igor_max10.qpf), dan [tabel resource](PERFORMANCE.md).

## Jalur menuju chip dibuat konkret

Gerbang aktual dibungkus sebagai `tt_um_wlmoi_igor_gate`. Metadata, datasheet, source list, pinout, dan workflow tersedia. Netlist generik dengan 684 logic/register cells lulus test wrapper yang sama.

Bukti: [wrapper](../src/project.v), [metadata](../info.yaml), [generic synthesis](../evidence/asic_generic_synthesis_noabc.log), dan [jalur TinyTapeout](TINYTAPEOUT.md).

## Bukti visual dan dokumentasi modul

Screenshot Quartus, screenshot GTKWave, trace, saved view, dan laporan asli saling melengkapi. Satu file `.io` berisi 28 halaman diagram level 0, level 1, bit flow, dan breakdown modul.

Bukti: [indeks evidence](EVIDENCE.md) dan [diagram `.io`](flowcharts/IGOR_RTL_Flowchart.io).

## UART motor diuji melalui dua implementasi

Paket motor yang berasal dari RTL didecode dan diperiksa kembali menggunakan SDK. Testbench memeriksa empat speed, empat ID, arah, float32, dan CRC. Script laptop memberi tes individual, pair, diagonal, serta staged startup.

Bukti: [captured packets](../robot/jetauto/FPGA_UART_TTL_MULTISPEED/tb/rtl_captured_packets.hex) dan [panduan JetAuto](JETAUTO.md).

## Ringkasan untuk presentasi

> Kami membangun planner FPGA dengan keputusan yang bisa diperiksa. Empat evaluator menyelesaikan workload yang diuji dalam 158,76 mikrodetik, neural core cocok tepat dengan model integer, dan dua target FPGA memiliki bukti implementasi. Gerbang yang diuji juga menyediakan prototipe chip yang konkret dalam harness TinyTapeout.

Gunakan [catatan hasil](RESULTS_AND_SCOPE.md) untuk mempertahankan konteks setiap angka ketika presentasi membahas integrasi, board, daya, atau ASIC.
