"""Source identity for every new run. Stdlib only; never writes historical evidence."""
from pathlib import Path
import subprocess,hashlib,json,datetime
ROOT=Path(__file__).resolve().parents[2]
def capture(path):
    paths=[]
    for folder in ['rtl','tb','scripts','constraints','interfaces','reference_model']:
        paths.extend(p for p in (ROOT/'v1'/folder).rglob('*') if p.is_file() and '__pycache__' not in p.parts)
    hashes={p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(paths)}
    def git(*args):return subprocess.check_output(['git',*args],cwd=ROOT,text=True).strip()
    result={'project_id':'TIMEFOOT','active_version':'v1','branch':git('branch','--show-current'),
       'commit':git('rev-parse','HEAD'),'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),
       'source_sha256':hashes,'source_tree_sha256':hashlib.sha256(json.dumps(hashes,sort_keys=True).encode()).hexdigest(),
       'git_status':git('status','--porcelain'),'toolchain':'Vivado/XSIM 2025.2 Build 6299465',
       'hardware_validation':'NOT_HARDWARE_VERIFIED'}
    path.write_text(json.dumps(result,indent=2),encoding='utf-8')
    return result
