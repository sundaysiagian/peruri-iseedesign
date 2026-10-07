# IGOR DE10-Lite · MAX 10 10M50DAF484C7G

Top entity: **igor_de10_lite_top**. Clock desain: **50 MHz**.

| Entry point | File |
|---|---|
| Quartus project | [quartus/igor_max10.qpf](quartus/igor_max10.qpf) |
| Programming image | [quartus/output_files/igor_max10.sof](quartus/output_files/igor_max10.sof) |
| Source | [rtl/](rtl) |
| ROM dan neural vectors | [assets/](assets) |
| Pin assignment | [quartus/pin_assignment.tcl](quartus/pin_assignment.tcl) |
| Host test | [host/igor_uart.py](host/igor_uart.py) |

Copy folder board ini secara utuh untuk menjaga source path dan ROM tetap tersedia. Buka QPF, pilih device/top yang sesuai, lalu gunakan Quartus Programmer untuk memuat SOF melalui JTAG.

Panduan lengkap: [Programming FPGA](../docs/FPGA_PROGRAMMING.md), [Quickstart](../docs/QUICKSTART.md), dan [Resource/timing](../docs/PERFORMANCE.md).

Host UART planner memakai **115200 8N1** dengan TTL 3,3 V. Gunakan port adapter FPGA yang sebenarnya. Reset KEY0 sebelum setiap DWA scene. ROM readback serta 100-vector neural check tersedia pada host script. Transport motor memakai project dan protocol terpisah.

Build evidence dan hash image tercantum pada [build_evidence.json](../evidence/build_evidence.json). Cakupan acceptance ada pada [Hasil dan cakupan](../docs/RESULTS_AND_SCOPE.md).
