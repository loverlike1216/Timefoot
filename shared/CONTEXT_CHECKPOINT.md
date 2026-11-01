# PRE-PCB WIP checkpoint

{
  "checkpoint_id": "TF-CP-PREPCB-WIP",
  "project_id": "TIMEFOOT",
  "repository": "https://github.com/loverlike1216/Timefoot.git",
  "workspace": "E:/Codex_project/Timefoot",
  "branch": "codex/v1-rtl-core",
  "base_commit": "31005c49b65349fb0aa26f27d728b70f6d83d3fd",
  "head_commit": "31005c49b65349fb0aa26f27d728b70f6d83d3fd",
  "active_version": "v1",
  "version_status": "ACTIVE",
  "current_stage": "INTERFACE_TIMING_CLOSURE_AND_PRE_PCB_READINESS",
  "checkpoint_reason": "Substantial new stage RTL and actual XPM probe completed; preserve recovery state",
  "status": "IN_PROGRESS",
  "completed": [
    "User instruction/problem hash/identity reconciled",
    "Late/early XPM synthesis experiment and early route/bus-skew completed",
    "Narrow link/RX/TX and management/control/physical-node RTL authored",
    "Initial4/8bit and25MHz units passed before latest credit IOB adjustment",
    "Manager64bitwrap/lateACK/fault test PASS"
  ],
  "latest_validation": [
    "link05 running",
    "sdr02 running",
    "adapter03 running",
    "p0_order_early routed and p0_order_late comparison"
  ],
  "blockers": [
    "Full new profile and system validation incomplete",
    "EBAZ original DATA schematic/connector mapping missing; conditional pin candidates only"
  ],
  "do_not_change": [
    "historical preproject files",
    "v1 identity/scope",
    "no Merge/v2/PCB/hardware/purchase/deploy"
  ],
  "invariants": [
    "reference-synchronous qualified marker required",
    "no old-session execution after recovery",
    "explicit CRC/session/sequence/flow control"
  ],
  "resume_from": "Read new guide and execution contract; inspect actual running/logged tests, finish all pre-PCB deliverables; no source changes during final frozen validation",
  "evidence_refs": [
    "v1/verification/EVIDENCE_INDEX.md",
    "v1/verification/evidence/DELIVERY_AUDIT.json",
    "v1/reports/SIMULATION_REPORT.md",
    "v1/reports/IMPLEMENTATION_REPORT.md",
    "v1/verification/evidence/clean_checkout/result.json"
  ],
  "open_ai_problems": [
    "P-20261101-001"
  ],
  "created_at": "2026-11-01T06:53:51.683896+00:00",
  "pull_request": "https://github.com/loverlike1216/Timefoot/pull/1"
}
