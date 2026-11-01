# Acceptance status

| Gate | Observed |
|---|---|
|Formal identity/path/history protection|PASS,3723historical hashes match|
|Core implementation and real data path|IMPLEMENTED/SIMULATED|
|1–4nodes,3seeds,CRC/session/sequence/timestamps|12/12PASS,2640independent packets|
|Unit and negative cases|5/5PASS|
|Fixed-seed reproducibility|4/4CSVHASH_MATCH|
|Target synth/place/route|Two Parts node and pin, commands completed|
|Critical CDC / RAM-reset DRC|0/0, warnings explained and kept|
|Internal setup/hold|PASS both Parts at150MHz work|
|Historical3-port same2ns output regression|PASS both Parts|
|Complete-node OOC I/O STA|FAIL, blockingP-20261101-001|
|Independent ChatGPT review|PENDING|
|Board/electrical/PHY/calibration/24h hardware|NOT_HARDWARE_VERIFIED|

Current Stage recommendationREVISE. The source acceptance contract remains unchanged.
