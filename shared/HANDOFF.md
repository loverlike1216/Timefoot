# Stage handoff

Goal:TIMEFOOT v1 digital synchronization core and multi-node framework. Repository/root/branch/source identity is in PROJECT_STATE; the final delivery/PR commit is observable through Git and PR metadata, while validated RTL baseline is46f88bcd553a13a9fda55b2599c6740acf6681d0.

Inputs reviewed:full authorized startup instruction, historical board/pin/research/decision materials, actual legacy RTL/TB/reports and780sealed/3723total-file startup audit. Historical source/output bytes were not modified.

Changes:coherent XPM config/packet crossings; single-owner reset plus synchronous RAM guards and local reset branches; qualified future epoch; queued reference events/cancellation; CRC/session/sequence/length validation; explicit1–4node pipeline maps; actual synthetic acquisition/timestamp/processing/flow control; optional generic management; candidate XDC and reproducible scripts.

Verification:5units,12system cases with3seeds,2640Python-checked final packets,4trace-hash replays, VCD clocks50/100/150/50MHz and0/600/1200/1800ps modeled output offsets; two-Part node and pin implementations; whole one-node manager/framework synth; all3723history hashes unchanged. Raw evidence and ignored binary hashes are linked from v1/verification/EVIDENCE_INDEX.md.

Failures:full node OOC WNS/WHS remain negative. Internal setup/hold is+0.218/+0.050ns(Z010),+1.056/+0.071ns(Z020); old3-pin failure closed at same2ns budget. Current gate REVISE. P-20261101-001 is OPEN; no fabricated ChatGPT Decision. Dedicated physical/RDC/board signoff is not claimed.

Resume:read guide.md and shared/CONTEXT_CHECKPOINT.*, then the actual open Problem, review package and full-node critical_paths/timing/clock interaction/constraints. Complete interface timing work within v1 after real review, preserving previous evidence. Guide is semantic history; current code/reports override old comments. No observed model/thread-switch event is invented. The final audit validates files currently on disk; it does not assert a before/after platform model-switch hash comparison.

## Observed Git/PR and clean replay

Evidence delivery9071b564387a8c67d88dadb61007e34502136a74 was pushed and verified remotely. Fresh-checkout orchestration fix03eeddcd0520b110649c226245989eba04a21b77 was pushed next. Draft PR:https://github.com/loverlike1216/Timefoot/pull/1, base main, head codex/v1-rtl-core, OPEN/DRAFT, mergedAt=null; no CI status runs were returned. The GitHub connector returned403 for PR creation; authenticated gh CLI succeeded without changing tokens/security settings.

A separate shallow remote clone below v1/work/clean_checkout at03eeddc reran5units and the complete4node seed1system case. All passed;18RTL file hashes, all unit trace hashes and packet/source/event CSV hashes match the canonical checkout. It uses the same installed Vivado toolchain, not a second simulator. Evidence:verification/evidence/clean_checkout/result.json. The initial missing-parent work-directory failure and corrected rerun logs are preserved. Later bookkeeping commits only add evidence/state/scripts for sealing; validated RTL remains46f88bc.
