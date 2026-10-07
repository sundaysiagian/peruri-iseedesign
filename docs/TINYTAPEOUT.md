# Jalur prototipe ASIC

## Top dan struktur

Top chip adalah **`tt_um_wlmoi_igor_gate`** pada [src/project.v](../src/project.v). Wrapper menggunakan [igor_safety_security_gate.v](../src/igor_safety_security_gate.v) yang berasal dari desain FPGA. Metadata, label 24 pin, dan source list berada pada [info.yaml](../info.yaml).

Antarmuka menyediakan `ui_in[7:0]` untuk write/address/read select, `uio_in[7:0]` untuk data write, dan `uo_out[7:0]` untuk readback. `uio_out` dan `uio_oe` nol. Reset aktif rendah. Clock target metadata adalah 50 MHz. Register map dan prosedur update ada pada [datasheet](info.md).

## Hubungan dengan accelerator

Desain chip ini adalah subset gerbang keselamatan. DWA, neural network, memory costmap, dan transport motor berada pada FPGA. Wrapper memungkinkan metodologi RTL, register protocol, dan perilaku penolakan dipindahkan ke harness chip yang konkret.

## Hasil lokal

Wrapper diuji pada 1.010 konfigurasi beserta reset dan ena. Yosys generic synthesis tanpa ABC menghasilkan **684 sel logic/register dan satu scopeinfo**. Netlist yang dihasilkan lulus test wrapper yang sama.

```bash
python -m pip install -r requirements-asic.txt
python scripts/synth_asic.py
python verification/run.py tt_generic
```

Report: [asic_generic_synthesis_noabc.log](../evidence/asic_generic_synthesis_noabc.log), [netlist](../evidence/asic_generic_netlist.v), dan [XML](../evidence/cocotb_tt_generic.xml).

## Flow fisik

Template berasal dari branch **CMOS5L** TinyTapeout ttihp-verilog-template. Upstream commit: `b86a2a781484bcab7ba522dc5de540086695a430`. [Provenance](../evidence/template_provenance.json) menyimpan sumbernya.

Workflow GDS dan docs disediakan sebagai **workflow_dispatch** untuk menjalankan flow fisik secara sengaja. Flow GDS meliputi build, precheck, gate-level test, dan viewer opsional sesuai template. Target `1x1` pada metadata perlu dibuktikan oleh physical fit.

Hasil generic synthesis tidak menjadi area PDK, timing ASIC, GDS, DRC, atau LVS. SKY130 merupakan jalur PDK berbeda dan belum memiliki report mapped area di proyek ini.

## Reference baseline topik 03

| Baseline | Hubungan desain |
|---|---|
| TT07 Iterative MAC | Inspirasi penggunaan ulang arithmetic pada neural core serial |
| TT07 Mini AIE 2×2 | Inspirasi pemisahan kerja ke empat evaluator |
| TinyTPU | Baseline konseptual matrix accelerator untuk arah neural paralel |

Ketiga baseline tidak diinstansiasi sebagai IP pada IGOR. Belum ada benchmark direct pada workload yang sama. Repo mempertahankan perbedaan antara inspirasi, implementasi sendiri, dan hasil yang benar-benar diuji.
