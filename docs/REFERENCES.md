# Referensi dan atribusi

| Sumber | Peran dalam proyek |
|---|---|
| [TinyTapeout CMOS5L Verilog template](https://github.com/TinyTapeout/ttihp-verilog-template/tree/cmos5l) | Harness, metadata, dan workflow chip |
| [Template provenance](../evidence/template_provenance.json) | Rekaman upstream commit yang digunakan |
| [DE10-Lite User Manual](https://faculty-web.msoe.edu/johnsontimoj/Common/FILES/DE10_Lite_User_Manual.pdf) | Device, clock, JTAG, dan pin assignment target lab |
| [DE10-Nano pin assignment](../fpga_de10_nano/quartus/pin_assignment.tcl) | Catatan sumber manual dan assignment yang digunakan oleh project |
| [PERURI Chip Hackathon handbook](https://summit.peruri.co.id/docs/Buku-Panduan-PERURI-Chip-Hackathon.pdf) | Konteks luaran dan topik hackathon |
| [SDK source provenance](../robot/jetauto/source_provenance.json) | Asal paket Python controller dan source yang ditinjau |
| [SDK motor data flow](../robot/jetauto/motor_data_flow_original.md) | Alur mecanum, RPS, ID, serialization, dan controller |
| [Neural reference model](../reference_model/neural_reference.py) | Pembanding integer untuk data neural yang disediakan |

TT07 Iterative MAC, TT07 Mini AIE 2×2, dan TinyTPU dibahas sebagai reference baseline pada [TINYTAPEOUT.md](TINYTAPEOUT.md). Hubungan tersebut berupa inspirasi architecture dan arah perbandingan. Tidak ada klaim penggunaan IP atau benchmark identik.

File [LICENSE](../LICENSE) mempertahankan lisensi Apache 2.0 dari paket template. Source pihak ketiga mempertahankan header dan atribusinya, termasuk pySerial BSD-3-Clause pada folder vendor. SDK JetAuto berasal dari paket yang diberikan untuk proyek, sebagaimana dicatat dalam provenance.
