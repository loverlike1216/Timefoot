# Evidence index

## Current canonical evidence

| Evidence | Path | Scope |
|---|---|---|
|Source/branch/Commit identity|Each canonical folder/source_manifest.json|Actual snapshot and per-fileSHA256, dirty state retained|
|5unit tests|evidence/signoff_unit/results.json|Instantiated dependency hashes checked against current source|
|1–4nodes×3seeds|evidence/closure_system/results.json|Current node reset-tree revision|
|Independent source/frame CRC and arithmetic|evidence/closure_system/python_crosscheck.json|Real captured source timestamp/payload to final packets|
|Repeated seed1,1–4nodes|evidence/closure_repeat/results.json|Packet/source/event CSV byte hashes compared|
|Clock and event measurement|evidence/clock_measurements.json|Real UNISIM VCD,1psresolution; no physical precision claim|
|Two-Part150MHz node implementation|evidence/closure_node/|Internal and full-interface STA kept separately; full profile FAIL|
|Retained3-output same2ns pin regression|evidence/final_pin/|Both Parts routed, candidate mapping only|
|Whole one-node assembly synth|evidence/closure_framework/|Manager/CSR/controller and node, two Parts|
|Analytic long-term model|evidence/long_term_model.json|15arithmetic cases; not24h hardware/RTL|
|Full replay/history/STA/binary audit|evidence/DELIVERY_AUDIT.json|3723historical hashes,4CSV replays, local DCP/VCD hashes|
|Credential pattern scan|evidence/secret_scan.json|No plaintext matches emitted|

## Preserved attempts

All impl01–04,pin01,unit01–05,sys01–09,final_*,signoff_* attempts remain under evidence or their preflight launcher logs. Some completed passes have been superseded by a later source revision. `sys04` is explicitly invalidated because the old runner missed mixed-case XPM Error messages. See docs/FAILURE_ANALYSIS.md for every relevant repair and evidence limitation. Old uncommitted attempts are diagnostic history, not a claim of exact current-source reproducibility.

Each completed implementation has timing/CDC/DRC/clock interactions/utilization/route/methodology/constraint coverage/effectiveXDC and reset inventory. Raw simulation compile/elab/launcher/xsim logs and CSV are retained. Large VCD/DCP files remain local and ignored by Git; their hashes/size are in DELIVERY_AUDIT.json and they can be regenerated with the pinned toolchain. No failed log or historical output is overwritten. `preflight/preproject_inventory.json` captures the pre-startup780sealed/3723total-file audit; final audit compares the entire historical tree again.
