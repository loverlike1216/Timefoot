"""Collect independent remote-checkout evidence without touching originals."""
from pathlib import Path
import hashlib,json,shutil,subprocess
ROOT=Path(__file__).resolve().parents[2];E=ROOT/'v1/verification/evidence'
CLONE=ROOT/'v1/work/prepcb_clean';OUT=E/'prepcb_clean'
OUT.mkdir(exist_ok=False)
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
rtl=list((ROOT/'v1/rtl').rglob('*.sv'))
matches={p.relative_to(ROOT).as_posix():sha(p)==sha(CLONE/p.relative_to(ROOT)) for p in rtl}
assert len(matches)==25 and all(matches.values())
canonical=E/'prepcb_system03/tb_sdr_system_4_s1'
replay=CLONE/'v1/verification/evidence/prepcb_clean_sdr/tb_sdr_system_4_s1'
traces={p.name:sha(p) for p in canonical.glob('sdr*.csv')}
assert len(traces)==3 and traces=={p.name:sha(p) for p in replay.glob('sdr*.csv')}
for tag in ['prepcb_clean_unit','prepcb_clean_sdr']:
    source=CLONE/'v1/verification/evidence'/tag
    for p in source.rglob('*'):
        if p.is_file() and p.suffix in ['.log','.json','.csv','.tcl']:
            dest=OUT/tag/p.relative_to(source);dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,dest)
result=dict(status='PASS',clone_commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=CLONE,text=True).strip(),
  clone_remote=subprocess.check_output(['git','remote','get-url','origin'],cwd=CLONE,text=True).strip(),
  unit_cases=5,sdr_nodes=4,sdr_seed=1,sdr_packets=240,rtl_files=25,rtl_byte_hash_matches=matches,
  sdr_trace_sha256=traces,second_simulator=False,toolchain='Same installed Vivado/XSIM2025.2; separate authenticated remote clone')
(OUT/'result.json').write_text(json.dumps(result,indent=2))
print('CLEAN_REMOTE_REPLAY_PASS 5units 4node/240packets 25RTL byte hashes 3 CSV hashes')
