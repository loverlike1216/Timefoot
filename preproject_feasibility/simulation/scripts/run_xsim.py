from pathlib import Path
import subprocess, json, hashlib, os, argparse, sys
ROOT=Path(__file__).resolve().parents[2]
BIN=Path(os.environ.get('TIMEFOOT_VIVADO_BIN','D:/Vivado/2025.2/2025.2/Vivado/bin'))
def run(args,cwd,log):
    p=subprocess.run([a.as_posix() if isinstance(a,Path) else str(a) for a in args],cwd=cwd,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
    log.write_bytes(p.stdout)
    if p.returncode: raise RuntimeError(f'{log}: exit {p.returncode}; {p.stdout[-3000:].decode(errors="replace")}')
    return p.stdout.decode(errors='replace')
def main():
    parser=argparse.ArgumentParser();parser.add_argument('--tag',default='run1');a=parser.parse_args()
    if not __import__('re').fullmatch(r'[A-Za-z0-9_-]+',a.tag):raise ValueError('Unsafe run tag')
    work=ROOT/'.work'/('xsim_'+a.tag);work.mkdir(exist_ok=False)
    out=ROOT/'evidence/simulation_logs'/a.tag;out.mkdir(exist_ok=False)
    os.environ['TMP']=str(ROOT/'.work/tmp');os.environ['TEMP']=os.environ['TMP']
    sources=list((ROOT/'simulation/rtl').glob('*.sv'))+list((ROOT/'simulation/tb').glob('*.sv'))
    sources.append(BIN.parent/'data/verilog/src/glbl.v')
    run([BIN/'xvlog.bat','--sv',*sources],work,out/'compile.log')
    results=[]
    cases=[(f'tb_sync_{n}',n,s,None) for n in range(1,5) for s in [1,17,2026]]
    cases += [('tb_pipeline',None,s,g) for s in [1,17,2026] for g in [0,3]]+[('tb_mmcm',None,1,None)]
    elaborated=set()
    for tb,n,seed,gap in cases:
        snap=tb
        if snap not in elaborated:
            args=[BIN/'xelab.bat',tb,'glbl','-L','unisims_ver','--snapshot',snap,'--debug','typical','--mt','2']
            run(args,work,out/(snap+'_elaborate.log'));elaborated.add(snap)
        name=f'{snap}_seed{seed}'+(f'_gap{gap}' if gap is not None else '');case=out/name;case.mkdir()
        tcl=case/'run.tcl'
        vcd=(ROOT/'evidence/waveforms'/f'{a.tag}_{name}.vcd').as_posix()
        scope=f'/{tb}/tb/*' if tb.startswith('tb_sync') else f'/{tb}/*'
        tcl.write_text(f'open_vcd {{{vcd}}}\nlog_vcd {scope}\nrun all\nclose_vcd\nquit\n',encoding='ascii')
        # xsim.dir is discovered in work; traces are copied out after each run.
        args=[BIN/'xsim.bat',snap,'-tclbatch',tcl,'-testplusarg',f'SEED{seed}','-log',case/'xsim.log']
        if gap is not None: args+=['-testplusarg',f'GAP{gap}']
        txt=run(args,work,case/'launcher.log')
        if 'TEST_PASS' not in txt or 'Fatal:' in txt or 'FATAL' in txt: raise RuntimeError(f'No PASS: {name}')
        hashes={}
        for f in ['event_trace.csv','pipeline_trace.csv']:
            src=work/f
            if (f=='event_trace.csv' and tb.startswith('tb_sync')) or (f=='pipeline_trace.csv' and tb=='tb_pipeline'):
                data=src.read_bytes();(case/f).write_bytes(data);hashes[f]=hashlib.sha256(data).hexdigest()
        results.append({'case':name,'testbench':tb,'nodes':n,'seed':seed,'source_gap':gap,'status':'PASS','trace_sha256':hashes,'log':str(case.relative_to(ROOT)/'xsim.log')})
        print('PASS',name,flush=True)
    (out/'results.json').write_text(json.dumps(results,indent=2),encoding='utf-8')
    print(f'TOTAL_PASS {len(results)}')
if __name__=='__main__':main()
