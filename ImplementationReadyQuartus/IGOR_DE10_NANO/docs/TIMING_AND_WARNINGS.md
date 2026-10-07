# Timing constraints and reviewed warnings

FPGA_CLK1_50 has a 20 ns constraint. Internal register and memory paths remain timed. UART RX and SW2/SW3 use two flip-flops; asynchronous input paths to their first synchronizer register are excluded. KEY0 asserts reset asynchronously with synchronous release. KEY1 is an asynchronous demo inhibit. LED and baud-timed UART TX have no external synchronous receiving clock and their external output paths are excluded. No arbitrary internal multicycle or false path was added to make timing pass.

Accordingly, check_timing lists no_input_delay/no_output_delay and absence of a virtual clock for these intentionally asynchronous/non-clocked interfaces. This is not a synchronous external I/O timing guarantee. report_ucp is the check for unintended unconstrained paths. MTBF is not numerically established; the design is not a certified safety controller.

Reviewed synthesis messages: ROM inferred write-side nets are undriven/default zero because these memories are read-only; read-during-write pass-through logic matches inferred RAM semantics; SW0/SW1 are unused in the active UART top. Fitter warning about drive strength/slew uses Quartus device defaults for LED/UART outputs; location and 3.3-V LVTTL are explicitly assigned. These defaults have not been electrically measured on the board.

The pre_uart_pipeline_fix evidence records failed timing. The release added a response snapshot register separating DWA selection from the UART CRC network. Only the latest reports in quartus/output_files and quartus/reports describe the released SOF. Build script rejects negative slack or timing critical warnings even when Quartus process exit code is zero.

A second change replaced a serial four-candidate selection chain with a balanced two-level tournament. It preserves lowest-score/lowest-index ties and removes the remaining cold-corner violation. Final acceptance uses all four PVT models, not just the single-corner Fmax table.
