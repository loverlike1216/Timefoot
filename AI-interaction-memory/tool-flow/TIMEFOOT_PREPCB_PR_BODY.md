# TIMEFOOT v1 multi-node core and complete SDR node interfaces

Implements the shared50MHz synchronization/timebase/event core and explicit1–4node task framework, plus the approved4/8bit source-synchronous physical-node adapter and coherent serial management. Frames retain Session/Sequence/source timestamp/Length/payload/CRC32. Whole-frame credit reserves RX capacity, removing the failed half-cycle ready loop; synchronous input buffering keeps asynchronous safety masks out of BRAM write enables. Manager wrap/late-Prepared priority and a real reset-shortened heartbeat failure are fixed.

The historical wide-node full-interface STA failure and original preproject evidence are preserved. XPM1000ns constraints were traced to clocks being read after synthesis; a controlled same-RTL experiment proves the order fix. Primary clocks now precede synthesis and routed Gray constraints/bus skew are audited.

Validation source:45aa523ddb4151157672df1ee3c5bb483be3edb0. Delivery evidence:18a6594f4091d52431cf36aa8d93017994b0e37a.

Validation:
- Original5unit tests,6new extensions, serial-managed physical-node64packets,6random-initial-phase stress cases PASS.
- Original12system cases and new actual-SDR12cases (1–4nodes,Seeds1/17/2026) PASS; independently checked2640packets per matrix.
- FourSeed1 replays match source/output/event CSV hashes;4node8bit240packets PASS.
- Actual full synthesis/opt/place/phys_opt/route on Z010/Z020 for4/8bit50MHz: WNS/WHS +0.468/+0.009,+0.925/+0.028,+0.313/+0.016,+0.752/+0.036ns; WPWS+2.833ns. CriticalCDC0,route errors0,Gray6.667/20/40ns,positive bus-skew margins.
- Separate authenticated remote clean checkout reruns5units+4nodeSDR240packets;25RTL byte hashes and3CSV hashes match. Same XSIM toolchain, not a second simulator.
- All3723historical files unchanged.1051delivery files scanned, no credential-pattern matches; no frozen-history/version-scope delta.

Current status: PCB_PRE_DESIGN_READY_WITH_LIMITATIONS. Candidate package/connector pins and manufacturer-based BOM are provided in14pre-design documents. CLOCK/SYNC device/path variation does not automatically guarantee0.5..3ns marker phase; P-20261101-002 records the hardware qualification decision. Actual boards/VCCO/SI/BER, BOM/phase freeze and hardware acceptance remain gated. Dedicated RDC signoff/second RTL simulator were not run; vendorCDC/methodology/PS7 warnings are explicitly classified. GitHub CI checks were not observed. No hardware/CAD/procurement/deployment, v2, or Merge is authorized by this PR.

Independent review entry: v1/docs/pre_pcb_readiness/GPT_CHAT_FINAL_REVIEW.md (single-file facts, blockers and next-stage expectations).
Machine evidence: v1/verification/evidence/prepcb_analysis/stage_audit.json.
Full reproduction: v1/docs/pre_pcb_readiness/VALIDATION_AND_REPRODUCTION.md.
Large VCD/DCP remain local with hashes/rebuild commands; logs/reports/CSV/source manifests are committed. Keep this PR DRAFT; actual independent Quality Gate and any hardware-stage authorization remain pending.
