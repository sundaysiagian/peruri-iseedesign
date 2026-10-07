# Gate fault codes

| Code | Condition |
|---|---|
|0|Gate permits command|
|1|Reset asserted|
|2|Emergency input KEY1|
|3|Protective stop SW3|
|4|Not-ready / sticky control fault / UART invalid command or protocol fault|
|5|Map absent, stale, invalid or fault|
|6|Configuration absent, unlocked, invalid or fault|
|7|Tile arithmetic fault|
|8|Deadline or command lease expired|
|9|Tiles/result incomplete or no valid candidate|
|10|Velocity bound exceeded|
|11|Command delta bound exceeded|

Priority follows this table. A reported code is the first active condition, not a complete fault bitmap. Status can show map/config missing during normal initial setup; only start after map committed and configuration locked. KEY0 clears sticky state. The gate is a functional prototype and does not constitute certified machinery safety.
