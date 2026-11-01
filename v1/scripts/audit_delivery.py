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
    dependency_checks={}
    unit_files=[p for p in ROOT.glob('v1/rtl/*/*.sv') if p.parent.name in ['cdc','scheduler','timebase','control'] or p.name in ['tf_stream_link.sv','tf_crc_engine.sv']]
    unit_files += [ROOT/f'v1/tb/tb_{n}.sv' for n in ['scheduler','fifo','stream','control','sync_window']]
    pin_files=[ROOT/'v1/rtl/top/tf_pin_timing_top.sv',ROOT/'v1/rtl/cdc/tf_bit_sync.sv',*ROOT.glob('v1/constraints/pin_*_candidate.xdc')]
    for tag,files in [('signoff_unit',unit_files),('final_pin',pin_files),('closure_node',list(ROOT.glob('v1/rtl/*/*.sv'))),('closure_framework',list(ROOT.glob('v1/rtl/*/*.sv')))]:
        manifest=json.loads(read(E/tag/'source_manifest.json'));hashes=manifest['source_sha256']
        assert all(hashes[p.relative_to(ROOT).as_posix()]==sha(p) for p in files),tag
        dependency_checks[tag]={'commit':manifest['commit'],'relevant_source_hash_match':True,'files_checked':len(files)}
    replay=[]
    for n in range(1,5):
        a=E/f'closure_system/tb_system_{n}_s1';b=E/f'closure_repeat/tb_system_{n}_s1'
        hashes={p.name:sha(p) for p in a.glob('*.csv')}
        assert hashes and hashes=={p.name:sha(p) for p in b.glob('*.csv')}
        replay.append({'nodes':n,'seed':1,'status':'HASH_MATCH','csv_sha256':hashes})
    builds=[]
    for tag in ['closure_node','final_pin']:
        for part in ['xc7z010clg400-1','xc7z020clg400-2']:
            p=E/tag/part;cdc=read(p/'cdc.rpt')
            critical=sum(int(m[1]) for m in re.finditer(r'^CDC-\d+\s+Critical\s+(\d+)',cdc,re.M))
            rows={m[1]:int(m[3]) for m in re.finditer(r'^(CDC-\d+)\s+(Critical|Warning|Info)\s+(\d+)',cdc,re.M)}
            drc=read(p/'drc.rpt');assert 'REQP-1839' not in drc
            assert re.search(r'# of nets with routing errors\.+\s*:\s*0',read(p/'route.rpt'))
            coverage=re.findall(r'^\d+\. checking (\w+) \((\d+)\)',read(p/'constraint_coverage.rpt'),re.M)
            assert coverage and all(int(n)==0 for name,n in coverage)
            builds.append({'tag':tag,'part':part,**timing(p/'timing.rpt'),
                  'internal_setup_ns':first_slack(p/'internal_setup.rpt'),'internal_hold_ns':first_slack(p/'internal_hold.rpt'),
                  'critical_cdc':critical,'cdc_rule_counts':rows,'constraint_coverage':dict(coverage),
                  'ram_async_control_drc':0,'route_errors':0})
    binaries={p.relative_to(ROOT).as_posix():{'bytes':p.stat().st_size,'sha256':sha(p)}
        for tag in ['closure_node','final_pin','closure_system','signoff_unit','closure_repeat','closure_framework']
        for p in (E/tag).rglob('*') if p.is_file() and p.suffix in ['.vcd','.dcp']}
    result={'project_id':'TIMEFOOT','version':'v1','historical_files':len(expected),'historical_mismatch':mismatch,'historical_added':added,
            'replay':replay,'builds':builds,'local_binary_manifest':binaries,'dependency_checks':dependency_checks,
            'stage_gate':'REVISE' if any(b['WNS_ns']<0 or b['WHS_ns']<0 or b['critical_cdc'] or b['internal_setup_ns']<0 or b['internal_hold_ns']<0 for b in builds) else 'REVIEW_REQUIRED',
            'independent_chatgpt_review':'PENDING','hardware':'NOT_HARDWARE_VERIFIED'}
    (E/'DELIVERY_AUDIT.json').write_text(json.dumps(result,indent=2))
    print('HISTORY_MATCH',len(expected),'REPLAY_MATCH',len(replay),'BUILDS',len(builds),'GATE',result['stage_gate'])
if __name__=='__main__':main()
