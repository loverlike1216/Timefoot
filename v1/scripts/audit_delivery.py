"""Read-only historical audit, replay comparison and report extraction."""
from pathlib import Path
import json,hashlib,re,subprocess
ROOT=Path(__file__).resolve().parents[2];E=ROOT/'v1/verification/evidence'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p):return p.read_text(encoding='utf-8',errors='replace')
def first_slack(p):
    m=re.search(r'Slack \((?:MET|VIOLATED)\)\s*:\s*([-\d.]+)ns',read(p));assert m,p
    return float(m[1])
def timing(p):
    lines=read(p).splitlines()
    index=next(i for i,s in enumerate(lines) if s.strip().startswith('WNS(ns)'))
    values=next(s.split() for s in lines[index+1:index+8] if re.match(r'\s*-?\d+\.\d+\s',s))
    return {'WNS_ns':float(values[0]),'WHS_ns':float(values[4]),'WPWS_ns':float(values[8])}
def main():
    old=json.loads(read(E/'preflight/preproject_inventory.json'))
    expected={p['path']:p['sha256'] for p in old['all_historical_files']}
    current={p.relative_to(ROOT/'preproject_feasibility').as_posix():sha(p) for p in (ROOT/'preproject_feasibility').rglob('*') if p.is_file()}
    mismatch=[p for p,h in expected.items() if current.get(p)!=h];added=sorted(set(current)-set(expected))
    assert not mismatch and not added,(mismatch,added)
    replay=[]
    for n in range(1,5):
        a=E/f'final_system2/tb_system_{n}_s1';b=E/f'final_repeat/tb_system_{n}_s1'
        hashes={p.name:sha(p) for p in a.glob('*.csv')}
        assert hashes and hashes=={p.name:sha(p) for p in b.glob('*.csv')}
        replay.append({'nodes':n,'seed':1,'status':'HASH_MATCH','csv_sha256':hashes})
    builds=[]
    for tag in ['final_node','final_pin']:
        for part in ['xc7z010clg400-1','xc7z020clg400-2']:
            p=E/tag/part;cdc=read(p/'cdc.rpt')
            critical=sum(int(m[1]) for m in re.finditer(r'^CDC-\d+\s+Critical\s+(\d+)',cdc,re.M))
            rows={m[1]:int(m[3]) for m in re.finditer(r'^(CDC-\d+)\s+(Critical|Warning|Info)\s+(\d+)',cdc,re.M)}
            coverage=re.findall(r'^\d+\. checking (\w+) \((\d+)\)',read(p/'constraint_coverage.rpt'),re.M)
            assert coverage and all(int(n)==0 for name,n in coverage)
            builds.append({'tag':tag,'part':part,**timing(p/'timing.rpt'),
                  'internal_setup_ns':first_slack(p/'internal_setup.rpt'),'internal_hold_ns':first_slack(p/'internal_hold.rpt'),
                  'critical_cdc':critical,'cdc_rule_counts':rows,'constraint_coverage':dict(coverage)})
    binaries={p.relative_to(ROOT).as_posix():{'bytes':p.stat().st_size,'sha256':sha(p)}
        for tag in ['final_node','final_pin','final_system2','final_unit','final_repeat','final_framework']
        for p in (E/tag).rglob('*') if p.is_file() and p.suffix in ['.vcd','.dcp']}
    result={'project_id':'TIMEFOOT','version':'v1','historical_files':len(expected),'historical_mismatch':mismatch,'historical_added':added,
            'replay':replay,'builds':builds,'local_binary_manifest':binaries,
            'stage_gate':'REVISE' if any(b['WNS_ns']<0 or b['WHS_ns']<0 or b['critical_cdc'] for b in builds) else 'REVIEW_REQUIRED',
            'independent_chatgpt_review':'PENDING','hardware':'NOT_HARDWARE_VERIFIED'}
    (E/'DELIVERY_AUDIT.json').write_text(json.dumps(result,indent=2))
    print('HISTORY_MATCH',len(expected),'REPLAY_MATCH',len(replay),'BUILDS',len(builds),'GATE',result['stage_gate'])
if __name__=='__main__':main()
