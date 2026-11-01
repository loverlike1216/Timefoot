"""Produce the stage handoff from final audited evidence; no success inference from process exit."""
from pathlib import Path
import json,subprocess,datetime
ROOT=Path(__file__).resolve().parents[2];E=ROOT/'v1/verification/evidence'
def load(p):return json.loads(p.read_text(encoding='utf-8'))
def write(p,text):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(text,encoding='utf-8')
def main():
    audit=load(E/'DELIVERY_AUDIT.json');cases=load(E/'closure_system/results.json');cross=load(E/'closure_system/python_crosscheck.json')
    unit=load(E/'signoff_unit/results.json');clocks=load(E/'clock_measurements.json')
    assert len(cases)==12 and len(unit)==5 and len(cross)==12
    packets=sum(r['packets'] for r in cross);commit=load(E/'closure_node/source_manifest.json')['commit'];gate=audit['stage_gate']
    rows=['| Profile | Part | WNS ns | WHS ns | Internal setup ns | Internal hold ns | Critical CDC |',
          '|---|---|---:|---:|---:|---:|---:|']
    for b in audit['builds']:rows.append(f"|{b['tag']}|{b['part']}|{b['WNS_ns']:+.3f}|{b['WHS_ns']:+.3f}|{b['internal_setup_ns']:+.3f}|{b['internal_hold_ns']:+.3f}|{b['critical_cdc']}|")
    table='\n'.join(rows)
    impl=f'''# Implementation and timing report

TIMEFOOT/v1; node RTL commit `{commit}`; branch codex/v1-rtl-core; Vivado2025.2 Build6299465. Both node Parts completed synth/opt/place/phys_opt/route. Pin regression is a full implementation of the retained3-output test; node is OOC digital-core implementation. Actual AX7020 Part and board electrical conditions are unverified.

{table}

**Complete-node STA FAIL.** Internal positive register-to-register setup/hold is a separate result and does not erase external port violations. Pulse width slack is+2.833ns in all four profiles. Constraint coverage reports zero no-clock, unconstrained internal endpoint, missing input/output delay, multi-clock, loop or partial-delay checks. All routable nets are routed, route errors0. No broad manual timing exemption or frequency/delay relaxation was applied.

The original pin WNS-0.673/-0.304ns is closed by synchronizing and reference-registering all q[2:0], retaining the2ns budget. The complete208-bit streaming/control OOC profile is a different interface and remains negative. Route35-198 warns that boundary ports lack HD.PARTPIN_LOCS; no board receiver/PHY timing has been established. See P-20261101-001; current profile stays FAIL pending a concrete source-synchronous adapter contract and valid implementation.

Node CDC:0Critical,9CDC-3,6CDC-9,36CDC-15 warnings in vendor config FIFO data paths,1external-reset CDC-26 row. Pin CDC:3safe CDC-3,0Critical. No waiver is written. Reset inventory and structural/functional RDC review are provided; no dedicated RDC signoff tool was used. REQP-1839 RAM-control warnings are0 after the synchronous guard fix. Remaining node DRC warnings are RTSTAT-10(no routable load on the exported clock in OOC) and ZPS7-1(PL-only design lacks PS7); no complete-board bitstream signoff is claimed. Check the raw DRC/methodology reports, including all OOC warnings.

Resource counts are in each utilization.rpt, not estimates. Z010 node uses2339LUT,4399FF,6BRAM tiles,5BUFG,1MMCM (13.29%LUT,12.50%FF,10%BRAM). Other Parts must use their own report rather than extrapolation. closure_framework separately synthesizes the whole one-node manager/CSR/node assembly on both Parts; the4-node logical top represents4FPGAs, not a four-MMCM single chip.

Raw reports: `verification/evidence/closure_node/<part>/` and `final_pin/<part>/`; effective.xdc, clocks, clock interactions, route, utilization, timing, internal_setup, internal_hold, CDC, DRC, methodology, constraint_coverage and reset_inventory are retained. Local DCP hashes are in DELIVERY_AUDIT.json.
'''
    write(ROOT/'v1/reports/IMPLEMENTATION_REPORT.md',impl)
    sim=f'''# Simulation and validation report

Project TIMEFOOT/v1, Stage RTL_CORE_AND_SYSTEM_FRAMEWORK. Canonical node/system RTL commit `{commit}`. Actual Windows/pwsh7.6.5/Python3.10.11/Vivado-XSIM2025.2 Build6299465. Workspace E:/Codex_project/Timefoot. Outcome **PARTIAL**, stage recommendation **{gate}** because complete-node interface STA is still failing.

- Unit:5/5PASS, `signoff_unit/results.json`: scheduler/timebase wrap and cancellations/session/late/duplicate/full; FIFO independent clocks/full/empty/backpressure/read-only and write reset; CRC/session/sequence/length failures; CSR backpressure/atomic time/error/statistics; SYNC setup-window contract acceptance/rejection.
- System:12/12PASS,1–4nodes×seeds1/17/2026, actual UNISIM MMCM50/100/150/50MHz. {packets} accepted final packets checked in RTL and independently by the Python byte-table CRC/arithmetic reference against separately captured source bodies. Packet timestamps are actual RTL timebase captures; source data is defined synthetic17*q+3.
- Every system case includes initial common epoch, exact scheduled output,150us sink blocking with FIFO saturation(max read-side occupancy17 including FWFT prefetch), reference stoppage/relock/new session, local reset/late rejoin, invalid marker qualification, canceled old-session future work. N>1also injects CRC corruption and performs explicit membership/map changes. Invalid zero-mask configuration is rejected before normal startup.
- Repeated seed1 on each count:4/4CSV SHA256MATCH across packet/source/event traces. Source manifests identify exact files/commits and dirty state. This is defined trace reproducibility, not equality of dated tool logs or DCP binaries.
- VCD independent check measures real UNISIM periods20ns/10ns/(6.666–6.667ns)/20ns and first-event modeled offsets0/600/1200/1800ps. All enabled node target timestamps match exactly. This is a1ps-resolution digital simulation with an explicit qualified timing window, not physical cable/board alignment or metastability proof.
- Long-term common-reference arithmetic:15analytic cases (±100/50/0ppm,1s/1h/24h), classificationACCELERATED_ANALYTIC_MODEL_NOT_HARDWARE. It demonstrates common frequency error and fixed skew assumptions; it is not a24h RTL or hardware stability run. Historical preproject independent short-window edge/model comparisons remain preserved separately.

Build/elaboration/simulation logs, commands, inputs/seeds, case CSV hashes and local VCD hashes are retained. Any mixed-case Error/Fatal fails the current runner. sys04 old apparent PASS is explicitly invalidated; every earlier failure/repair is indexed in docs/FAILURE_ANALYSIS.md. Expected Unisim stopped-reference warnings appear only in negative tests; no XPM usage Error remains in canonical passing cases.

Reproduce using docs/REPRODUCE.md and fresh tags. `python v1/reference_model/check_system.py closure_system`, `python v1/reference_model/check_clocks.py`, `python v1/scripts/audit_delivery.py`. Unit and pin source commits predate the final node-only reset tree change; their actual instantiated module hashes are unchanged and source manifests are preserved. No Verilator/second RTL simulator, dedicated RDC tool, board/PHY/JTAG/electrical/calibration or physical24h result is claimed. Python provides an independent calculation check, not a second RTL simulator.
'''
    write(ROOT/'v1/reports/SIMULATION_REPORT.md',sim)
    fps=[v for c in cross for v in c['phase_drain_fps'].values()]
    perf=f'''# Data budget and observed limits

At payload32 body176, iterative CRC takes176bit cycles plus accept/release, minimum initiation interval178clocks. Ideal source50MHz ceiling=280898.88frames/s and1.124MB/s payload, before stalls. Processing/CRC instances overlap through elastic buffers; stage distribution does not bypass any operation. These are digital parallel-interface rates, not serial cable rates or a promised physical PHY throughput.

Measured40-frame drain windows across canonical cases span{min(fps):.2f}–{max(fps):.2f}frames/s. A faster sink can drain previously buffered frames faster than the50MHz source ceiling; that upper burst-drain rate is not sustainable source goodput. End-to-end latency from source trace capture to accepted final output spans{min(c['min_latency_ns'] for c in cross)}–{max(c['max_latency_ns'] for c in cross)}ns with the intentional150us sink stall included. Input traces are sampled2ns after the creation edge; that convention is retained in latency values. Individual phase/case values are in closure_system/python_crosscheck.json. This is a bounded burst/drain measurement, not unbounded steady-state certification.

FIFO RAM depth16 plus FWFT read-side prefetch reaches observed occupancy17. True write full gates local ready. Backpressure can stall acquisition: the source holds a burst until acceptance, and sample timestamps reflect actual creation under that stall; it does not promise a fixed-rate ADC sampling schedule. Correct traffic is lossless within the ready/valid contract. CRC/sequence/session failure deliberately aborts the session, flushes pending traffic and starts sequence0 under a new session; it is not a retransmission protocol. Source start while busy latches overrun/fault. Default RTL burst64 is parameterized; canonical system stress uses40frames/session.
'''
    write(ROOT/'v1/reports/PERFORMANCE_BUDGET.md',perf)
    review=f'''# GPT Chat stage review package

PROJECT_ID:TIMEFOOT; REPOSITORY:https://github.com/loverlike1216/Timefoot.git; PROJECT_ROOT:E:/Codex_project/Timefoot; BRANCH:codex/v1-rtl-core; COMMIT(RTL):`{commit}`; ACTIVE_VERSION:v1; STAGE:RTL_CORE_AND_SYSTEM_FRAMEWORK. Delivery commit/PR is recorded in shared/HANDOFF.md and PR metadata after push. No Merge authorized or performed.

Architecture implemented: shared-reference B route, optional manager without AX7020/PS dependency,1–4 identical node slots, explicit stage mapping,64-bit future epoch,32-bit sessions, reference-domain ordered event queue, coherent XPM config/data crossing, CRC/session/sequence/length checks, real arithmetic/flow control, independent clock monitor, abort/relock/fresh-session recovery. All modules are listed in ARCHITECTURE.md; port/register contracts are in interfaces. Board/PHY adapters remain explicitly logical/candidate.

Validation matrix:5unit cases,12system configurations,{packets}independently checked packets,4exact-seed replays,4routed Part/profile combinations,2whole-one-node framework syntheses. See reports/SIMULATION_REPORT.md, IMPLEMENTATION_REPORT.md, PERFORMANCE_BUDGET.md and verification/evidence/DELIVERY_AUDIT.json. Actual source manifests, tool logs, CSV and local wave/DCP hashes are navigable from verification/EVIDENCE_INDEX.md.

{table}

Critical CDC:0both Parts; RAM async-control DRC fixed; route errors0, constraint-coverage omissions0. RDC is structural review plus reset inventory/negative simulation with documented limitations. Resource data is actual utilization.rpt; Z010node2339LUT/4399FF/6BRAM/5BUFG/1MMCM. Independent VCD clock/event measurements and Python packet/reference calculations are supplied.

**Open blocker:complete-node OOC I/O setup/hold FAIL.** Current stage self-assessment:{gate}. This is not final project acceptance. Do not substitute positive internal timing or the small3-port pin regression for that failed profile. P-20261101-001 contains code/report context, options, questions, acceptance impact and a SHA256 binding. No external ChatGPT Decision has been received or fabricated. Independent ChatGPT must decide ACCEPT / ACCEPT WITH LIMITATIONS / REVISE using these actual facts; the existing gate requires REVISE while this profile fails.

Known limitations: actual Part/VCCO/pin ownership/PS clocks, physical clock distribution, arbitrary asynchronous SYNC, fine skew calibration/metastability, cable PHY/BER and physical24h operation are NOT_HARDWARE_VERIFIED. marker_qualified is an adapter contract input, not a measured phase detector. Functional tests use32-bit payload/depth16/burst40; parameter space is not blanket certified. No dedicated RDC tool/second RTL simulator. Some low-level statistics/error-detail CSR adapters remain documented extensions.

Next recommended work: independently review the proposed concrete source-synchronous logical interface adapter, close complete-node setup/hold on both Parts, then rerun the unchanged core/regression gates within v1. Hardware design, procurement, v2, scope/acceptance changes, merge and deployment require the user's separate approval. All{audit['historical_files']}historical files match their startup hashes; curated historical text/source/logs are in Git and ignored binaries/original extracts remain preserved locally, indexed by hashes.
'''
    write(ROOT/'v1/docs/GPT_CHAT_STAGE_REVIEW.md',review)
    print('REPORTS_WRITTEN',gate,'packets',packets,'RTL',commit)
if __name__=='__main__':main()
