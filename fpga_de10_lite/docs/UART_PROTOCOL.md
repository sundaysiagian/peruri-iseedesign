# UART binary protocol v1

115200 8N1, one outstanding request. Request: A5, opcode, payload little-endian 32-bit, CRC8, 5A. Response: 5A, opcode echoed, data little-endian 32-bit, CRC8, A5. CRC8 polynomial 0x07, init 0, no reflection, no final XOR; covers first 6 bytes. Never send next request before receiving all 8 response bytes. Inter-byte timeout 100 ms. Bad framing/CRC/overrun/timeout causes sticky protocol fault; KEY0 clears it.

| op | Request payload | Response |
|---|---|---|
|1|Increasing map sequence, first 1|status|
|2|address [14:0], cell [23:16]; other bits zero|status|
|3|0; commit after exactly 16384 ascending writes|status|
|4|version 1 [27:20], max_dw [19:14], max_dv [13:10], max_w [9:4], max_v [3:0]|status|
|5|0; lock configuration until reset|status|
|6|0; start DWA|status|
|7|0|status|
|8|ROM address 0..6019|ROM word [15:0]|
|9|0|DWA latency cycles|
|10|NN input index [4:0], signed Q8.8 [23:8], others zero|status|
|11|0; start NN after all 24 inputs loaded|status|
|12|NN output index 0..3|signed result [15:0], done [16], busy [17], fault [18]|
|13|0|NN latency cycles|
|14|0|v [4:0], signed omega [11:5]|

Status: enable bit0, busy1, done2, protocol fault3, invalid command4, fault code[15:8], candidate index[24:16]. Other bits reserved zero. DWA configuration max_v<=15, max_w<=16, max_dv<=15, max_dw<=32. Config locked until reset. Neural busy/done/fault must be read via op12, not generic DWA status. Host should transmit reserved request bits as zero.

Map values 254 lethal and 255 unknown are rejected by candidates. Map age and command lease are 20 ms. The command readout is zero after inhibition/expiry. This serial framing/CRC detects transmission errors; it is not cryptographic authentication.
