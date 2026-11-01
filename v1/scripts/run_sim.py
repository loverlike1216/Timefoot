from pathlib import Path
import os,subprocess,argparse,json,hashlib,re
from provenance import capture
ROOT=Path(__file__).resolve().parents[2]
BIN=Path(os.environ.get('TIMEFOOT_VIVADO_BIN','D:/Vivado/2025.2/2025.2/Vivado/bin'))
def command(args,cwd,path):
    args=[x.as_posix() if isinstance(x,Path) else str(x) for x in args]
    p=subprocess.run(args,cwd=cwd,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
    path.write_bytes(p.stdout)
    if p.returncode:raise RuntimeError(f'{path}: exit{p.returncode}\n{p.stdout[-2500:].decode(errors="replace")}')
    return p.stdout.decode(errors='replace')
def main():
    ap=argparse.ArgumentParser();ap.add_argument('--tag',required=True);ap.add_argument('--suite',default='unit');a=ap.parse_args()
    assert re.fullmatch('[A-Za-z0-9_-]+',a.tag)
    work=ROOT/'v1/work'/a.tag;out=ROOT/'v1/verification/evidence'/a.tag
    work.mkdir(exist_ok=False);out.mkdir(exist_ok=False)
    capture(out/'source_manifest.json')
    os.environ['TMP']=str(ROOT/'v1/work/tmp');os.environ['TEMP']=os.environ['TMP']
    sources=sorted((ROOT/'v1/rtl').rglob('*.sv'))+sorted((ROOT/'v1/tb').glob('*.sv'))
    sources+=[BIN.parent/'data/verilog/src/glbl.v']
    command([BIN/'xvlog.bat','--sv',*sources],work,out/'compile.log')
    if a.suite=='unit':cases=[('tb_scheduler',1),('tb_fifo',1),('tb_stream',1),('tb_control',1),('tb_sync_window',1)]
    elif a.suite=='system':cases=[(f'tb_system_{n}',s) for n in range(1,5) for s in [1,17,2026]]
    elif a.suite=='repeat':cases=[(f'tb_system_{n}',1) for n in range(1,5)]
    else:cases=[(a.suite,1)]
    results=[];elab=set()
    for tb,seed in cases:
        if tb not in elab:
            command([BIN/'xelab.bat',tb,'glbl','-L','unisims_ver','-L','xpm','--snapshot',tb,'--debug','typical','--mt','2'],work,out/(tb+'_elab.log'));elab.add(tb)
        case=out/f'{tb}_s{seed}';case.mkdir()
        scope=f'/{tb}/t/*' if tb.startswith('tb_system_') else f'/{tb}/*'
        tcl=case/'run.tcl';tcl.write_text(f'open_vcd {{{(case/"wave.vcd").as_posix()}}}\nlog_vcd {scope}\nrun all\nclose_vcd\nquit\n')
        txt=command([BIN/'xsim.bat',tb,'-tclbatch',tcl,'-testplusarg',f'SEED{seed}','-log',case/'xsim.log'],work,case/'launcher.log')
        assert 'TEST_PASS' in txt and not re.search(r'(?im)^(fatal|error):',txt), f'Case failed: {case}'
        hashes={}
        for p in work.glob('*.csv'):
            if p.name.startswith(tb.split('_')[1]):
                data=p.read_bytes();(case/p.name).write_bytes(data);hashes[p.name]=hashlib.sha256(data).hexdigest()
        results.append({'case':case.name,'status':'PASS','seed':seed,'trace_sha256':hashes})
        print('PASS',case.name,flush=True)
    (out/'results.json').write_text(json.dumps(results,indent=2))
    print('TOTAL_PASS',len(results))
if __name__=='__main__':main()
