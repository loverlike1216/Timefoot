from pathlib import Path
import hashlib,json,re
ROOT=Path(__file__).resolve().parents[2]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
a=json.loads((ROOT/'evidence/simulation_logs/finalE/results.json').read_text())
b=json.loads((ROOT/'evidence/simulation_logs/finalF/results.json').read_text())
assert len(a)==len(b)==19
comparisons=[];checked_frames=0;pipeline=[]
for x,y in zip(a,b):
    assert x['case']==y['case'] and x['status']==y['status']=='PASS'
    assert x['trace_sha256']==y['trace_sha256']
    logs=[]
    for tag in ['finalE','finalF']:
        log=(ROOT/'evidence/simulation_logs'/tag/x['case']/'xsim.log').read_text(errors='replace')
        assert 'TEST_PASS' in log and 'Fatal:' not in log and 'ERROR:' not in log
        norm='\n'.join(line for line in log.splitlines() if line.startswith(('PASS ','FAULT ','TEST_PASS ','PRIMITIVE_LOCK ')))
        logs.append(hashlib.sha256(norm.encode()).hexdigest())
    assert logs[0]==logs[1]
    comparisons.append({'case':x['case'],'trace_sha256':x['trace_sha256'],'normalized_log_sha256':logs[0],'match':True})
    if x['testbench']=='tb_pipeline':
        data=(ROOT/'evidence/simulation_logs/finalE'/x['case']/'pipeline_trace.csv').read_text().splitlines()
        counts={};aborted=[];last_timestamp={}
        for line in data[1:]:
            if line.startswith('ABORTED,'):aborted.append(int(line.split(',')[1]));continue
            s,index,time,frame=line.split(',');n=int(frame,16)
            ident=n>>96;ts=(n>>32)&((1<<64)-1);payload=n&0xffffffff
            # Independent integer model uses scalar fields decoded from emitted packet.
            result=(((ident*17+3)*3+7)^0x5a5aa5a5)+(ts&0xffffffff)
            assert payload==result&0xffffffff
            if s in last_timestamp:assert ts>last_timestamp[s]
            last_timestamp[s]=ts
            k=int(s);counts[k]=counts.get(k,0)+1
            assert int(index)==counts[k]-1 and ident==int(index)
            checked_frames+=1
        assert counts[0]>=320 and counts[1]==80 and len(aborted)==1
        assert counts[0]+aborted[0]==330
        pipeline.append({'case':x['case'],'delivered_by_session':counts,'reported_aborted':aborted[0]})
manifest=json.loads((ROOT/'evidence/environment/source_manifest.json').read_text(encoding='utf-8'))
for row in manifest:assert sha(Path(row['path']))==row['sha256']
summary={'status':'PASS','same_seed_repeat_runs':2,'cases_per_run':19,'total_simulator_executions':38,
         'independently_decoded_pipeline_frames_one_run':checked_frames,'pipeline':pipeline,'comparisons':comparisons,
         'source_attachments_unchanged':True,'raw_tool_log_byte_identity_claimed':False,
         'definition':'same-seed event/pipeline CSV bytes and normalized PASS/FAULT/lock lines match; host/date lines excluded'}
(ROOT/'evidence/simulation_logs/reproducibility.json').write_text(json.dumps(summary,indent=2),encoding='utf-8')
print(json.dumps({k:v for k,v in summary.items() if k!='comparisons'},indent=2))
