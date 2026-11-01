"""Independent integer-time edge model; analytical acceleration is labelled.
Run from project root: python -B v1/verification/clock_budget_model.py
Not a replacement for RTL, STA, IBIS, or hardware measurements.
"""
from pathlib import Path
import itertools,json,hashlib
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'v1/verification/evidence/prepcb_analysis'
OUT.mkdir(parents=True,exist_ok=True)
T=20000 # ps, nominal 50 MHz

def enumeration(clock_delay,relative_sync,cycles):
    marker=T//2+clock_delay+relative_sync
    samples=[n for n in range(4) if n*T+clock_delay>=marker]
    apply=samples[0]
    epoch=(1<<64)-2000
    count=epoch
    trace=[]
    for edge in range(apply,apply+cycles):
        if edge==apply:count=epoch
        else:count=(count+1)&((1<<64)-1)
        trace.append(count)
    return apply,trace

cases=[]
for cd,sd in itertools.product([0,1000,5000,12000],[500,1000,2000,3000]):
    apply,trace=enumeration(cd,sd,5000)
    assert apply==1
    for k in [0,1,1999,2000,4999]:assert trace[k]==(((1<<64)-2000+k)&((1<<64)-1))
    cases.append(dict(clock_delay_ps=cd,sync_minus_clock_ps=sd,apply_ordinal=apply,
      setup_to_next_edge_ps=10000-sd,hold_from_previous_edge_ps=10000+sd,
      trace_sha256=hashlib.sha256(json.dumps(trace).encode()).hexdigest()))
assert len({c['trace_sha256'] for c in cases})==1
# Outside the contract, demonstrate the edge slip rather than assuming away it.
late_apply,_=enumeration(1000,11000,10)
assert late_apply==2
long=[]
for seconds in [1,3600,86400,2592000]:
    ticks=seconds*50000000
    final=((1<<64)-2000+ticks)&((1<<64)-1)
    long.append(dict(seconds=seconds,common_ticks=ticks,all_nodes_same_final=final,
      relative_drift_ticks=0,absolute_frequency_error_seconds_at_50ppm=seconds*50e-6,
      method='ANALYTICAL_COMMON_EDGE_COUNT_NOT_LONG_DURATION_RTL'))
result=dict(status='PASS_WITH_ASSUMPTIONS',period_ps=T,enumerated_cases=cases,long_horizon=long,
  negative_case=dict(sync_minus_clock_ps=11000,observed_apply_ordinal=late_apply,status='EDGE_SLIP_DETECTED'),
  hardware_unmatched_budget=dict(fanout_pair_rising_spread_ns=1.3,receiver_pair_spread_ns=2.2,
    cable_relative_reserve_ns=0.5,board_relative_reserve_ns=0.5,jitter_reserve_ns=0.5,
    total_relative_uncertainty_ns=5.0,status='DOES_NOT_GUARANTEE_0p5_TO_3ns_PROFILE_REQUIRES_QUALIFICATION'),
  boundaries=['No metastability probability/temperature/BER simulation','No physical clock accuracy claim',
    'Common oscillator means relative tick drift zero only if all nodes retain every edge',
    'Loss and rejoin are validated by separate RTL tests; after loss no old-session validity'])
(OUT/'clock_budget.json').write_text(json.dumps(result,indent=2))
print('CLOCK_MODEL_PASS cases=16 edges_per_case=5000 negative_edge_slip=DETECTED; long horizons=ANALYTICAL')
