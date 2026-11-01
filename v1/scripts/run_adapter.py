"""Full physical-node implementation; no OOC and no replacement of old runs."""
from pathlib import Path
import argparse, os, subprocess, re, json
from provenance import capture, ROOT

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('--tag',required=True)
    ap.add_argument('--lanes',type=int,choices=[4,8],default=4)
    a=ap.parse_args()
    assert re.fullmatch('[A-Za-z0-9_-]+',a.tag)
    work=ROOT/'v1/work'/a.tag
    out=ROOT/'v1/verification/evidence'/a.tag
    work.mkdir(parents=True,exist_ok=False)
    out.mkdir(parents=True,exist_ok=False)
    first=capture(out/'source_manifest.json')
    os.environ['TMP']=str(ROOT/'v1/work/tmp');os.environ['TEMP']=os.environ['TMP']
    Path(os.environ['TMP']).mkdir(parents=True,exist_ok=True)
    binary=Path(os.environ.get('TIMEFOOT_VIVADO_BIN','D:/Vivado/2025.2/2025.2/Vivado/bin'))/'vivado.bat'
    args=[str(binary),'-mode','batch','-source',(ROOT/'v1/scripts/implement_adapter.tcl').as_posix(),'-tclargs',a.tag,str(a.lanes)]
    with (out/'launcher.log').open('wb') as log:
        result=subprocess.run(args,cwd=work,stdout=log,stderr=subprocess.STDOUT)
    last=capture(out/'source_manifest_end.json')
    assert first['source_sha256']==last['source_sha256'],'SOURCE_CHANGED_DURING_RUN'
    assert result.returncode==0, f'Vivado exit {result.returncode}; see {out}'
    summary={}
    for part in ['xc7z010clg400-1','xc7z020clg400-2']:
        text=(out/part/'timing.rpt').read_text()
        rows=text.split('WNS(ns)',1)[1].splitlines()
        row=next(x for x in rows if re.match(r'^\s*-?\d+\.\d+\s+-?\d+\.\d+',x)).split()
        summary[part]={'wns_ns':float(row[0]),'whs_ns':float(row[4]),'wpws_ns':float(row[8])}
        assert min(summary[part].values())>=0, f'Negative STA: {part} {summary[part]}'
    (out/'implementation_summary.json').write_text(json.dumps(summary,indent=2))
    print('FULL_NODE_STA_PASS',json.dumps(summary))
if __name__=='__main__':main()
