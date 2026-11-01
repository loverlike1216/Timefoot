"""Independent stage aggregation. Does not rewrite historical delivery audit."""
from pathlib import Path
import json,re,hashlib,sys
ROOT=Path(__file__).resolve().parents[2];E=ROOT/'v1/verification/evidence';OUT=E/'prepcb_analysis'
def read(p):return p.read_text(encoding='utf8',errors='replace')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def timing(p):
    rows=read(p).split('WNS(ns)',1)[1].splitlines()
    v=next(s.split() for s in rows if re.match(r'^\s*-?\d+\.\d+\s+-?\d+\.\d+',s))
    return dict(wns_ns=float(v[0]),whs_ns=float(v[4]),wpws_ns=float(v[8]))
def main():
    OUT.mkdir(exist_ok=True)
    suites={}
    for tag,count in [('prepcb_unit03',5),('prepcb_link03',6),('prepcb_physical03',1),('prepcb_legacy03',12),
                      ('prepcb_system03',12),('prepcb_repeat03',4),('prepcb_8bit03',1)]:
        d=E/tag;results=json.loads(read(d/'results.json'));assert len(results)==count
        a=json.loads(read(d/'source_manifest.json'));b=json.loads(read(d/'source_manifest_end.json'))
        assert a['source_sha256']==b['source_sha256']
        assert all(sha(ROOT/p)==h for p,h in a['source_sha256'].items()),tag
        suites[tag]=dict(cases=count,status='PASS',commit=a['commit'],source_tree_sha256=a['source_tree_sha256'])
    replays=[]
    for n in range(1,5):
        a=E/f'prepcb_system03/tb_sdr_system_{n}_s1';b=E/f'prepcb_repeat03/tb_sdr_system_{n}_s1'
        hashes={p.name:sha(p) for p in a.glob('sdr*.csv')};assert len(hashes)==3
        assert hashes=={p.name:sha(p) for p in b.glob('sdr*.csv')}
        replays.append(dict(nodes=n,seed=1,status='HASH_MATCH',trace_sha256=hashes))
    builds=[]
    for tag in ['prepcb_impl4_03','prepcb_impl8_03']:
      manifest=json.loads(read(E/tag/'source_manifest.json'));end=json.loads(read(E/tag/'source_manifest_end.json'))
      assert manifest['source_sha256']==end['source_sha256']
      for part in ['xc7z010clg400-1','xc7z020clg400-2']:
        d=E/tag/part;sta=timing(d/'timing.rpt');assert min(sta.values())>=0
        cdc=read(d/'cdc.rpt');crit=sum(int(n) for n in re.findall(r'^CDC-\d+\s+Critical\s+(\d+)',cdc,re.M));assert crit==0
        assert 'REQP-1839' not in read(d/'drc.rpt')
        assert not re.search(r'^\|[^\n]+\|\s*(Error|Critical Warning)',read(d/'drc.rpt'),re.M)
        coverage=dict(re.findall(r'^\d+\. checking (\w+) \((\d+)\)',read(d/'constraint_coverage.rpt'),re.M))
        assert all(int(v)==0 for k,v in coverage.items() if k!='no_output_delay')
        assert int(coverage['no_output_delay'])==1 and 'tx_clock' in read(d/'constraint_coverage.rpt')
        xdc=read(d/'effective.xdc')
        gray=[line for line in xdc.splitlines() if line.startswith(('set_max_delay','set_bus_skew')) and 'src_gray_ff' in line]
        assert gray and all(0<float(line.rsplit(' ',1)[-1])<=40 for line in gray)
        skew=[list(map(float,m)) for m in re.findall(r'^\s*(?:Slow|Fast)\s+([\d.]+)\s+([\d.]+)\s+([-\d.]+)\s*$',read(d/'bus_skew.rpt'),re.M)]
        assert skew and min(x[2] for x in skew)>=0
        assert re.search(r'# of nets with routing errors\.+\s*:\s*0',read(d/'route.rpt'))
        drc_rules=re.findall(r'^\|\s*([A-Z]+[A-Z0-9]*-\d+)\s*\|\s*(Warning|Error|Critical Warning)\s*\|',read(d/'drc.rpt'),re.M)
        builds.append(dict(tag=tag,part=part,**sta,critical_cdc=crit,coverage=coverage,route_errors=0,
          gray_constraint_lines=len(gray),gray_constraint_values_ns=sorted(set(float(s.rsplit(' ',1)[-1]) for s in gray)),
          bus_skew_max_ns=max(x[1] for x in skew),bus_skew_min_slack_ns=min(x[2] for x in skew),
          drc_rules=drc_rules,commit=manifest['commit']))
    history=json.loads(read(E/'preflight/preproject_inventory.json'))['all_historical_files']
    expected={p['path']:p['sha256'] for p in history}
    current={p.relative_to(ROOT/'preproject_feasibility').as_posix():sha(p) for p in (ROOT/'preproject_feasibility').rglob('*') if p.is_file()}
    assert expected==current,'HISTORICAL_DELTA'
    cross=json.loads(read(E/'prepcb_system03/python_crosscheck.json'))
    legacy=json.loads(read(E/'prepcb_legacy03/python_crosscheck.json'))
    phases=json.loads(read(E/'prepcb_phases/results.json'));assert len(phases['cases'])==6
    assert all(sha(ROOT/p)==h for p,h in phases['rtl_sha256'].items())
    sys.path.insert(0,str(ROOT/'v1/reference_model'))
    from check_clocks import one
    clocks=[one(E/f'prepcb_system03/tb_sdr_system_{n}_s1/wave.vcd',n) for n in range(1,5)]
    result=dict(project_id='TIMEFOOT',version='v1',validated_source_commit=suites['prepcb_system03']['commit'],
       suites=suites,replay=replays,builds=builds,history=dict(files=len(history),mismatch=0,added=0,status='HASH_MATCH'),
       golden=dict(sdr_packets=sum(x['packets'] for x in cross),legacy_packets=sum(x['packets'] for x in legacy)),
       phase_sweep_cases=6,vcd_clock_measurements=clocks,hardware='NOT_HARDWARE_VERIFIED',independent_chatgpt_review='PENDING',
       limitation='Vendor XPM CDC15 warnings, TIMING18 edge/async classification, PS7 warning, board SI/phase qualification remain explicit')
    (OUT/'stage_audit.json').write_text(json.dumps(result,indent=2))
    print('AUDIT_PASS',len(builds),'full implementations; history',len(history),'replays',len(replays),'sdr packets',result['golden']['sdr_packets'])
if __name__=='__main__':main()
