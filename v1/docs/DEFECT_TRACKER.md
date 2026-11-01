# Historical defect tracking

| ID | Original evidence | v1 remedy to verify | State |
|---|---|---|---|
| TF-001 | CDC1x2/CDC7x6/CDC10x1 per Part | vendor-qualified crossings, reset release, registered monitor fault | OPEN |
| TF-002 | q0 WNS-0.673/-0.304ns | preserve3 outputs; coherent ref-domain output registers, same2ns delay | OPEN |
| TF-003 | async marker whole-cycle ambiguity | staged future epoch + synchronous falling-edge marker contract + verify | OPEN |
| TF-004 | late join valid without epoch proof | membership quiesce/new session/re-epoch all active nodes | OPEN |
| TF-005 | global flush only | link-local two-domain reset/busy protocol + session isolation tests | OPEN |
| TF-006 | no CRC/sequence/length protocol | actual CRC32/session/sequence validator and bounded FIFO | OPEN |
| TF-007 | illustrative fine calibration | documented adapter/physical calibration boundary | HARDWARE_VALIDATION_REQUIRED |
