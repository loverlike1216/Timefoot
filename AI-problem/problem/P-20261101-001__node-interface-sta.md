---
problem_id: P-20261101-001
project_id: TIMEFOOT
active_version: v1
current_stage: RTL_CORE_AND_SYSTEM_FRAMEWORK
status: OPEN
created_at: 2026-11-01
created_by: Codex
chat_source_name: USER_PROVIDED_V1_INSTRUCTION
decision_status: NO_EXTERNAL_CHATGPT_DECISION_AVAILABLE
---
# Complete-node interface STA gate

## Decision needed

Independently review the digital adapter timing contract and recommend how to close complete-node input/output STA while preserving B architecture,50/100/150/50MHz defaults, all ports and the2ns regression output budget. No existing acceptance threshold is relaxed. This problem is a review handoff, not approval to change scope or implement hardware.

## Goal and current implementation

Formal TIMEFOOT v1 source baseline46f88bc, branch codex/v1-rtl-core. Coherent config FIFO, staged qualified future epoch, exact reference-domain queued events, real packet/CRC/processing chain and session recovery are implemented. Current closure_system/repeat/node reports and GPT_CHAT_STAGE_REVIEW.md carry the final observed results. Historical780 sealed and3723 total file hashes are audited separately.

## Evidence

- `v1/verification/evidence/closure_node/xc7z010clg400-1/timing.rpt`: complete OOC WNS-1.255ns,WHS-0.862ns.
- Same directory internal_setup/internal_hold: +0.218/+0.050ns. Internal register paths are separately reported; no I/O endpoints are deleted from timing.rpt.
- Routed CDC has no Critical;36 XPM FIFO data warnings and the external-reset CDC-26 row are explained in CDC_RDC_REVIEW.md. DRC no longer has REQP-1839; remaining OOC RTSTAT-10 and PL-only ZPS7-1 warnings are preserved.
- `final_pin/<part>/timing.rpt`: full routed3-port regression meets the SAME2ns budget with all ports preserved. It is not the208-bit streaming node interface.
- Z020 complete current metrics are in DELIVERY_AUDIT.json and IMPLEMENTATION_REPORT.md; do not substitute earlier impl04/final_node numbers.

## What was tried and learned

Iterative CRC removed a large combinational CRC path. A single registered reset owner and vendor-scoped crossings removed critical CDC. Synchronous RAM-enable guards removed async RAM-control DRC. Four local synchronous reset branches recovered the small negative internal setup path caused by the reset-fix placement. Complete-node OOC interface failures remain. The latest critical output/input paths must be read directly from critical_paths/timing reports; earlier ones included TX valid/data/diagnostic outputs and input hold.

The OOC top has logical packet/control ports without a selected physical PHY/receiver or HD.PARTPIN_LOCS. Vivado Route35-198 explicitly warns that partial routing of boundary ports is unavailable. The present2ns max/min assumptions are a candidate budget, not a measured receiver/board contract. An automatically derived MMCM clock is used and there are no blanket async clock groups or manually waived paths. Positive internal STA therefore does not prove the external interface; negative complete-node STA cannot be called PASS.

## Candidate options

1. Define a concrete digital source-synchronous adapter with forwarded TX clock, registered elastic boundary and specified RX min/max timing; reimplement and validate it on both Parts before physical design. This is the recommended engineering direction for review, not a ChatGPT Decision.
2. Keep the logical208-bit ready/valid port for core composition and provide separate receiver-specific adapter profiles. Preserve the currently failing profile as FAIL; any acceptance-scope change still requires the user's approval.
3. Lower work frequency or loosen timing budgets merely to obtain PASS: rejected as a gate workaround. A measured architectural throughput tradeoff would require a new justified decision, and cannot erase this evidence.

## Questions for independent ChatGPT review

1. Are reset/session/marker invariants and current CDC/RDC evidence adequate within the documented digital scope?
2. Which explicit adapter clock/ready/data contract should be implemented next so complete-node setup/hold checks become meaningful and close without broad exceptions?
3. Is any additional hardware-independent test needed before proceeding with that interface work?
4. Confirm REVISE while the current required complete-node STA profile fails; do not infer board acceptance from pin regression or OOC results.

## Approval boundary and source

The user has authorized routine reversible RTL/XDC implementation, tests and PR updates. Merge, v2, scope changes, PCB/hardware work, procurement and deployment remain prohibited. Current tools cannot read/write a separate ChatGPT chat; this package is persisted for real user/ChatGPT review through the authorized repository. No Decision file is fabricated. The adjacent SHA256 file binds this exact problem content for a later real response.
