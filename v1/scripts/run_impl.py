from pathlib import Path
import argparse,os,subprocess,re
from provenance import ROOT,capture
ap=argparse.ArgumentParser();ap.add_argument('--tag',required=True);ap.add_argument('--mode',choices=['node','pin'],default='node');a=ap.parse_args()
assert re.fullmatch('[A-Za-z0-9_-]+',a.tag)
work=ROOT/'v1/work'/a.tag;out=ROOT/'v1/verification/evidence'/a.tag
work.mkdir(parents=True,exist_ok=False);out.mkdir(parents=True,exist_ok=False);capture(out/'source_manifest.json')
os.environ['TMP']=str(ROOT/'v1/work/tmp');os.environ['TEMP']=os.environ['TMP']
Path(os.environ['TMP']).mkdir(exist_ok=True)
bin=Path(os.environ.get('TIMEFOOT_VIVADO_BIN','D:/Vivado/2025.2/2025.2/Vivado/bin'))
args=[bin/'vivado.bat','-mode','batch','-source',ROOT/'v1/scripts/implement.tcl','-log',work/'vivado.log','-journal',work/'vivado.jou','-tclargs',a.tag,a.mode]
with (out/'launcher.log').open('wb') as f:
    p=subprocess.run([x.as_posix() if isinstance(x,Path) else x for x in args],cwd=work,stdout=f,stderr=subprocess.STDOUT)
print('VIVADO_EXIT',p.returncode,'reports',out)
raise SystemExit(p.returncode)
