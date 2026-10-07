# Top module dan modul penyusun

**Top module untuk board / Quartus: `igor_uart_top`**  
**File: `rtl/igor_uart_top.v`**  
**Buka proyek: `quartus/igor.qpf`**  
**Device: 5CSEBA6U23I7 (DE10-Nano)**

Nama `igor_top` adalah core DWA internal, bukan top-level pin board. `igor_de10_nano_wrapper` adalah alternatif demo lama untuk testbench; proyek final tidak memilihnya sebagai top. Folder ini tidak dibangun untuk device MAX 10 atau board lain. Sebutan Nano/Lite tidak boleh menjadi alasan mengganti device/pin tanpa verifikasi.

```text
igor_uart_top                         [TOP BOARD]
├── serial : igor_uart_protocol      [decode packet, CRC, response snapshot]
│   ├── receiver : igor_uart_rx      [serial → byte, synchronizer]
│   └── transmitter : igor_uart_tx   [byte → serial]
├── core : igor_top                  [CORE DWA + control FSM]
│   ├── cfg : igor_config_registers  [configuration + lock]
│   ├── maps : igor_costmap_manager  [load/commit/sequence/freshness]
│   ├── tiles[0..3]                  [4 parallel generate instances]
│   │   ├── memory : igor_costmap_bank [replicated double-buffer map]
│   │   └── tile : igor_rollout_tile  [128 candidates per tile]
│   │       ├── gen : igor_candidate_generator [v/omega + dynamic window]
│   │       ├── stepper : igor_kinematic_step [pose update]
│   │       │   ├── s : igor_trig_lut [sin fixed-point]
│   │       │   └── c : igor_trig_lut [cos via phase +64]
│   │       └── acc : igor_score_accumulator [cost accumulation]
│   ├── selector : igor_best_candidate_selector [balanced tournament]
│   ├── gate : igor_safety_security_gate [mandatory enable/command gate]
│   └── logger : igor_status_logger  [fault transitions]
├── neural : igor_neural_core        [24→64→64→4 sequential MAC]
│   └── weights : igor_neural_rom    [6020 words + zero padding]
└── inspection_rom : igor_neural_rom [readback UART op8]
```

Clock bukan dibangkitkan RTL: input clock onboard 50 MHz di FPGA pin V11. UART membangkitkan hitungan baud 434 clock/bit. Kandidat gerak dibangkitkan oleh `igor_candidate_generator`. Pose rollout dibangkitkan oleh `igor_kinematic_step`; sinus berasal dari `igor_trig_lut`. Bobot neural bukan hasil acak: ROM diinisialisasi dari `assets/neural_24_64_64_4/bram_unified_weights_padded.mem` yang diturunkan dari berkas ekspor pengguna.

## Port top board

| Port | Arah | Fungsi |
|---|---|---|
|FPGA_CLK1_50|input|50 MHz, V11|
|KEY[0]|input|reset active-low, AH17|
|KEY[1]|input|emergency inhibit active-low, AH16|
|SW[3:0]|input|SW2 not-ready, SW3 protective stop; SW0/1 unused|
|UART_RX|input|V12, GPIO0/JP1 pin1|
|UART_TX|output|E8, GPIO0/JP1 pin2|
|LED[7:0]|output|fault nibble, done, busy, reset released, enable|

## Cara menyalin

Salin **seluruh folder `IGOR_DE10_NANO`**, bukan hanya file `.v`. RTL ROM memerlukan file `.mem`; QSF memakai path relatif ke `../rtl` dan `../assets`. Setelah disalin, buka `quartus/igor.qpf`. Jangan meratakan isi subfolder. `.sof` di `quartus/output_files/igor.sof` bisa dipakai langsung tanpa rebuild pada board/device target yang sama.

Semua sumber hardware aktif berupa Verilog-2001 `.v`. File `.ps1`, `.py`, `.tcl` adalah skrip build/test/host, bukan top module. File di `tb/` adalah testbench, bukan file untuk disintesis. Log dan waveform ada di `simulation/` dan `evidence/`.
