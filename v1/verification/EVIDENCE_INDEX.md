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
|Clean remote checkout|evidence/clean_checkout/result.json|5units+4node seed1PASS,18RTL and all corresponding CSV hashesMATCH; same toolchain|
|GitHub PR snapshot|evidence/github_pr_snapshot.json|Draft#1 OPEN, no merge, observed head/CI snapshot|

## Preserved attempts

All impl01–04,pin01,unit01–05,sys01–09,final_*,signoff_* attempts remain under evidence or their preflight launcher logs. Some completed passes have been superseded by a later source revision. `sys04` is explicitly invalidated because the old runner missed mixed-case XPM Error messages. See docs/FAILURE_ANALYSIS.md for every relevant repair and evidence limitation. Old uncommitted attempts are diagnostic history, not a claim of exact current-source reproducibility.

Each completed implementation has timing/CDC/DRC/clock interactions/utilization/route/methodology/constraint coverage/effectiveXDC and reset inventory. Raw simulation compile/elab/launcher/xsim logs and CSV are retained. Large VCD/DCP files remain local and ignored by Git; their hashes/size are in DELIVERY_AUDIT.json and they can be regenerated with the pinned toolchain. No failed log or historical output is overwritten. `preflight/preproject_inventory.json` captures the pre-startup780sealed/3723total-file audit; final audit compares the entire historical tree again.

## Current INTERFACE_TIMING_CLOSURE_AND_PRE_PCB_READINESS (source45aa523)

| Evidence | Path | Scope |
|---|---|---|
| Stage aggregate/history/replay/STA | evidence/prepcb_analysis/stage_audit.json | Frozen source checks;4full routed profiles;3723history HashMATCH |
| Full4/8bit two-Part implementations | evidence/prepcb_impl4_03/ ; evidence/prepcb_impl8_03/ | All IO, clocks, constraints/CDC/DRC/bus-skew/datasheet/route |
| SDR1–4nodes×3Seeds +golden | evidence/prepcb_system03/ |12cases,2640Python-checked packets; each hop actual new adapters |
| Old framework regression | evidence/prepcb_legacy03/ |12cases,2640independent packets |
| Fixed-seed3CSV repeat | evidence/prepcb_repeat03/ |4nodes configs HashMATCH |
| 8bit4node | evidence/prepcb_8bit03/ |240independent packets |
| Original units / extensions / serial physical node | evidence/prepcb_unit03/ ; prepcb_link03/ ; prepcb_physical03/ |5+6+1PASS, physical64packets; linkCSV caveat in VALIDATION doc |
| Random initial clock phases | evidence/prepcb_phases/ |6actualRTL stress cases; derived TB archived |
| XPM read-order experiment | evidence/p0_order_early/ ; p0_order_late/ | Same old RTL, clocks before/after synthesis; early routed skew |
| Actual VCD link/application measurements | evidence/prepcb_analysis/link_measurements.json | Physical64packet latency and serializer cadence |
| Long-term conditional model | evidence/prepcb_analysis/clock_budget.json |16×5000edge enumeration, negative slip, labelled analytical horizon |
| Candidate pins | evidence/prepcb_analysis/pin_candidates.json |72rows, package+board-source boundaries |
| Remote clean replay | evidence/prepcb_clean/result.json |45aa523,25RTL byte hashes,5units+4node240packets/3CSVHashMATCH |
| Single-file independent review | ../docs/pre_pcb_readiness/GPT_CHAT_FINAL_REVIEW.md | Reviewer decisions PENDING, hardware freeze HOLD |

All earlier adapter/link/sdr/prepcb attempts remain diagnostic evidence. prepcb_system Seed17 exposed actual short heartbeat reset pulse, fixed ca8d4ad. system02 encountered resource-pressure XSIM access violation; superseded implementation processes were stopped and logs retained. Final03 run sources start/endmatch. No new hardware/CAD artifacts. Large DCP/VCD local hash inventory is evidence/prepcb_analysis/artifact_manifest.json; ignored binaries are not claimed present on GitHub.
