"""Seal the actually executed remote-checkout replay without copying tool binaries."""
from pathlib import Path
import json,hashlib,shutil,subprocess
ROOT=Path(__file__).resolve().parents[2];E=ROOT/'v1/verification/evidence'
clone=ROOT/'v1/work/clean_checkout';src=clone/'v1/verification/evidence';out=E/'clean_checkout'
assert clone.resolve().is_relative_to(ROOT.resolve())
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def load(p):return json.loads(p.read_text(encoding='utf-8'))
def main():
    u=load(src/'clean_unit2/results.json');s=load(src/'clean_system4/results.json')
    assert len(u)==5 and len(s)==1 and all(r['status']=='PASS' for r in u+s)
    canonical=load(E/'signoff_unit/results.json')
    assert [r['trace_sha256'] for r in u]==[r['trace_sha256'] for r in canonical]
    a=E/'closure_system/tb_system_4_s1';b=src/'clean_system4/tb_system_4_s1'
    hashes={p.name:sha(p) for p in a.glob('*.csv')}
    assert hashes=={p.name:sha(p) for p in b.glob('*.csv')}
    rtl={p.relative_to(ROOT).as_posix():sha(p) for p in ROOT.glob('v1/rtl/*/*.sv')}
    assert all(sha(clone/p)==h for p,h in rtl.items())
    commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=clone,text=True).strip()
    out.mkdir(exist_ok=False)
    for tag in ['clean_unit2','clean_system4']:
        for p in (src/tag).rglob('*'):
            if p.is_file() and p.suffix not in ['.vcd','.wdb']:
                target=out/tag/p.relative_to(src/tag);target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(p,target)
    binaries={p.relative_to(ROOT).as_posix():{'bytes':p.stat().st_size,'sha256':sha(p)} for p in src.rglob('*.vcd')}
    result={'classification':'CLEAN_REMOTE_CHECKOUT_SAME_VIVADO_TOOLCHAIN','repository':'https://github.com/loverlike1216/Timefoot.git',
      'checkout_commit':commit,'unit_pass':len(u),'system_case':'tb_system_4_s1','system_pass':1,
      'rtl_files_hash_match':len(rtl),'packet_source_event_hash_match':hashes,'unit_trace_hash_match':True,
      'binary_manifest':binaries,'status':'PASS'}
    (out/'result.json').write_text(json.dumps(result,indent=2))
    print('CLEAN_REPLAY_PASS',commit,'unit5 system1 RTL18 CSV_MATCH')
if __name__=='__main__':main()
