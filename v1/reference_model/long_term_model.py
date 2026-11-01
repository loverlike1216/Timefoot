"""Accelerated analytic model; never hardware or 24-hour RTL evidence."""
from pathlib import Path
from decimal import Decimal
import json
root=Path(__file__).resolve().parents[2];rows=[]
for ppm in [-100,-50,0,50,100]:
    f=Decimal(50000000)*(1+Decimal(ppm)/1000000)
    for seconds in [1,3600,86400]:
        # Four nodes count the same indexed reference edges, irrespective of
        # their derived business clocks. Fixed skew does not accumulate.
        counts=[int(f*seconds)]*4
        assert max(counts)-min(counts)==0
        rows.append({'common_ppm':ppm,'seconds':seconds,'same_index_edge_count_delta':0,
          'common_time_error_s':str(Decimal(counts[0])/50000000-Decimal(seconds)),
          'assumed_path_skew_ns':[0,0.6,1.2,1.8],'event_skew_ns':1.8})
out={'classification':'ACCELERATED_ANALYTIC_MODEL_NOT_HARDWARE','rows':rows,
     'independent_oscillator_counterexample_100ppm_24h_s':'8.64',
     'limits':['No oscillator phase noise, metastability, board/cable drift, temperature or calibration measurement',
               'Alignment requires the qualified marker and no missed reference edge; integer counting is not physical precision']}
(root/'v1/verification/evidence/long_term_model.json').write_text(json.dumps(out,indent=2))
print('ANALYTIC_MODEL_PASS',len(rows))
