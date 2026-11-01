# Historical defect tracking

| ID | Original evidence | v1 remedy to verify | State |
|---|---|---|---|
| TF-001 | CDC1x2/CDC7x6/CDC10x1 per Part | current node0Critical on both Parts; no manual waiver, warning/RDC audit retained | CLOSED_DIGITAL_SCOPE |
| TF-002 | q0 WNS-0.673/-0.304ns | preserve3 outputs; reference IOB registers, same2ns; final_pin WNS+4.675/+5.065 | CLOSED_REGRESSION_SCOPE |
| TF-003 | async marker whole-cycle ambiguity | staged epoch, qualified synchronous marker, boundary negative tests and exact target ticks | CLOSED_UNDER_EXPLICIT_TIMING_CONTRACT |
| TF-004 | late join valid without epoch proof | global quiesce/new session; ref loss and local reset repeat full data burst | CLOSED_DIGITAL_SCOPE |
| TF-005 | global flush only | independent reader/writer flush tests; common-owner coordinated mode; stale-session isolation | CLOSED_UNDER_HELD_RESET_CONTRACT |
| TF-006 | no CRC/sequence/length protocol | true bit-serial CRC32 plus session/sequence/length checks,4error negatives, full/empty/backpressure | CLOSED_DIGITAL_SCOPE |
| TF-007 | illustrative fine calibration | documented adapter/physical calibration boundary | HARDWARE_VALIDATION_REQUIRED |
| TF-008 | full node2ns OOC interface candidate | both Parts complete-node setup/hold still fail; internal register paths separately pass | OPEN_BLOCKING:P-20261101-001 |
| TF-009 | new REQP-1839 from async reset to RAM EN/WE | synchronous guard; canonical DRC0REQP-1839 on both Parts | CLOSED_DIGITAL_SCOPE |
| TF-010 | reset tree fanout setup-0.146ns after RAM fix | four synchronous local reset branches; canonical internal+0.218/+1.056ns | CLOSED_CURRENT_IMPLEMENTATION |

Closure states do not imply board/hardware acceptance, arbitrary-async SYNC support, untested parameter-space coverage, or full stage acceptance. Raw historical and new failures remain preserved.
