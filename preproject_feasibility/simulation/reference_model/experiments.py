from pathlib import Path
from fractions import Fraction as F
import math,json,hashlib,csv,random
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'evidence/simulation_logs/reference_model'
OUT.mkdir(exist_ok=True)
result={}
# Independent oscillator edge-count verification, then exact affine acceleration.
drift=[]
for ppm in [10,20,50]:
    fplus=F(50_000_000)*(1+F(ppm,1_000_000))
    fminus=F(50_000_000)*(1-F(ppm,1_000_000))
    duration=F(1,1000)
    nplus=sum(1 for k in range(1,50010) if F(k)/fplus<=duration)
    nminus=sum(1 for k in range(1,50010) if F(k)/fminus<=duration)
    assert nplus==math.floor(duration*fplus) and nminus==math.floor(duration*fminus)
    measured_ns=(nplus-nminus)*20
    exact_ns=float(duration*F(2*ppm,1_000_000)*1_000_000_000)
    assert abs(measured_ns-exact_ns)<=20
    for secs in [1,60,3600,86400]:
        drift.append({'ppm_each':ppm,'duration_s':secs,'independent_pair_error_ns':secs*2*ppm*1000,
                      'common_reference_relative_rate_error_ns':0,
                      'common_reference_absolute_error_vs_ideal_ns':secs*ppm*1000})
result['drift_edge_count_crosscheck']='PASS: 1 ms explicit edge enumeration at +/-10,20,50 ppm; <=20 ns quantization'
result['drift']=drift
# Phase model separates propagation, capture ambiguity, quantization, and calibrated estimate.
phase=[]
for seed in [1,17,2026]:
    rng=random.Random(seed)
    for delay in [0,2,5,10]:
        estimate=round(delay/0.25)*0.25
        samples=[delay-estimate+rng.uniform(-0.05,0.05) for _ in range(1000)]
        phase.append({'seed':seed,'delay_ns':delay,'estimate_ns':estimate,
                      'ideal_calibrated_max_abs_ns':max(map(abs,samples)),
                      'uncalibrated_ns':delay,'scope':'ASSUMED 0.25 ns actuator + assumed +/-50 ps noise, NOT RTL/hardware'})
        assert max(map(abs,samples))<=0.051
result['phase_calibration_model']=phase
# Two-flop synchronizers can add a whole ref period when SYNC and REF arrive independently.
captures=[math.ceil((sync_ns-ref_ns)/20)*20+ref_ns+40 for ref_ns,sync_ns in [(0,9),(10,9),(0,11),(10,11)]]
assert max(captures)-min(captures)==20
result['capture_window_counterexample']={'captures_ns':captures,'spread_ns':max(captures)-min(captures),
 'meaning':'same frequency alone does not establish a shared epoch; whole-cycle ambiguity retained'}
# Open-loop ppm plus message-based affine correction: model only, not PTP implementation.
servo=[]
for seed in [1,17,2026]:
    rng=random.Random(seed)
    for asym in [0,400]:
        errors=[];last_est=0.;last_t=0.;monotonic=-float('inf')
        # calibrated frequency is assumed measured exactly; expose irreducible delay asymmetry.
        for k in range(10001):
            t=k*0.01
            if k%10==0:
                last_est=(rng.uniform(-100,100)+asym/2);last_t=t
            err=last_est+(t-last_t)*0.5*1000 # residual frequency error 0.5 ppm
            logical=t*1e9+err
            assert logical>monotonic;monotonic=logical;errors.append(err)
        assert max(map(abs,errors))<350
        servo.append({'seed':seed,'path_asymmetry_ns':asym,'max_abs_error_ns':max(map(abs,errors)),
                      'assumptions':'10 Hz updates; +/-100 ns timestamp noise; 0.5 ppm residual; affine model, not protocol RTL'})
result['logical_clock_servo_model']=servo
# Numerically verify legal candidate integer-MMCM arithmetic; Vivado UNISIM and implementation are separate checks.
result['mmcm_arithmetic']={'input_mhz':50,'D':1,'M':18,'pfd_mhz':50,'vco_mhz':900,
 'dividers':[18,9,6],'output_mhz':[50,100,150]}
assert [900/d for d in [18,9,6]]==[50,100,150]
result['counter']={'width':64,'unit_ns':20,'wrap_seconds':float(F(2**64,50_000_000)),
 'scheduling_contract':'0 < target-current < 2**63 modulo ticks; events execute on compare edge, timestamp output ticks is target+1'}
result['status']='PASS_WITH_EXPLICIT_MODEL_ASSUMPTIONS'
(OUT/'results.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
with (OUT/'drift.csv').open('w',newline='',encoding='utf-8') as f:
    w=csv.DictWriter(f,fieldnames=list(drift[0]));w.writeheader();w.writerows(drift)
print(json.dumps(result,indent=2))
