> Current-stage update2026-11-01: complete4/8bit physical-node profiles close setup/hold/pulse on both Parts, with expanded functional/golden/replay/clean-checkout evidence. Current verdict PCB_PRE_DESIGN_READY_WITH_LIMITATIONS; hardware freeze and independent Review remain gated. See ../docs/pre_pcb_readiness/PRE_PCB_READINESS_REPORT.md and VALIDATION_AND_REPRODUCTION.md. The body below is the preserved previous-stage report, including its genuine full-wide-node FAIL.

# Implementation and timing report

TIMEFOOT/v1; node RTL commit `46f88bcd553a13a9fda55b2599c6740acf6681d0`; branch codex/v1-rtl-core; Vivado2025.2 Build6299465. Both node Parts completed synth/opt/place/phys_opt/route. Pin regression is a full implementation of the retained3-output test; node is OOC digital-core implementation. Actual AX7020 Part and board electrical conditions are unverified.

| Profile | Part | WNS ns | WHS ns | Internal setup ns | Internal hold ns | Critical CDC |
|---|---|---:|---:|---:|---:|---:|
|closure_node|xc7z010clg400-1|-1.255|-0.862|+0.218|+0.050|0|
|closure_node|xc7z020clg400-2|-0.684|-0.931|+1.056|+0.071|0|
|final_pin|xc7z010clg400-1|+4.675|+0.122|+4.675|+0.122|0|
|final_pin|xc7z020clg400-2|+5.065|+0.121|+5.065|+0.121|0|

**Complete-node STA FAIL.** Internal positive register-to-register setup/hold is a separate result and does not erase external port violations. Pulse width slack is+2.833ns in all four profiles. Constraint coverage reports zero no-clock, unconstrained internal endpoint, missing input/output delay, multi-clock, loop or partial-delay checks. All routable nets are routed, route errors0. No broad manual timing exemption or frequency/delay relaxation was applied.

The original pin WNS-0.673/-0.304ns is closed by synchronizing and reference-registering all q[2:0], retaining the2ns budget. The complete208-bit streaming/control OOC profile is a different interface and remains negative. Route35-198 warns that boundary ports lack HD.PARTPIN_LOCS; no board receiver/PHY timing has been established. See P-20261101-001; current profile stays FAIL pending a concrete source-synchronous adapter contract and valid implementation.

Node CDC:0Critical,9CDC-3,6CDC-9,36CDC-15 warnings in vendor config FIFO data paths,1external-reset CDC-26 row. Pin CDC:3safe CDC-3,0Critical. No waiver is written. Reset inventory and structural/functional RDC review are provided; no dedicated RDC signoff tool was used. REQP-1839 RAM-control warnings are0 after the synchronous guard fix. Remaining node DRC warnings are RTSTAT-10(no routable load on the exported clock in OOC) and ZPS7-1(PL-only design lacks PS7); no complete-board bitstream signoff is claimed. Check the raw DRC/methodology reports, including all OOC warnings.

Resource counts are in each utilization.rpt, not estimates. Z010 node uses2339LUT,4399FF,6BRAM tiles,5BUFG,1MMCM (13.29%LUT,12.50%FF,10%BRAM). Other Parts must use their own report rather than extrapolation. closure_framework separately synthesizes the whole one-node manager/CSR/node assembly on both Parts; the4-node logical top represents4FPGAs, not a four-MMCM single chip.

Raw reports: `verification/evidence/closure_node/<part>/` and `final_pin/<part>/`; effective.xdc, clocks, clock interactions, route, utilization, timing, internal_setup, internal_hold, CDC, DRC, methodology, constraint_coverage and reset_inventory are retained. Local DCP hashes are in DELIVERY_AUDIT.json.
