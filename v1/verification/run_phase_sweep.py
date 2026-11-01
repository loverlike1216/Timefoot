"""Replay the real link stress TB at independently selected clock phases.
Derived TB is archived verbatim with its hash, not a substitute link model.
"""
from pathlib import Path
import sys,subprocess,json,hashlib,random,os
ROOT=Path(__file__).resolve().parents[2]
BIN=Path(os.environ.get('TIMEFOOT_VIVADO_BIN','D:/Vivado/2025.2/2025.2/Vivado/bin'))
out=ROOT/'v1/verification/evidence/prepcb_phases'
work=ROOT/'v1/work/prepcb_phases'
out.mkdir(parents=True,exist_ok=False);work.mkdir(parents=True,exist_ok=False)
os.environ['TMP']=str(ROOT/'v1/work/tmp');os.environ['TEMP']=os.environ['TMP']
original=(ROOT/'v1/tb/tb_link.sv').read_text()
base=original.split('module tb_link;')[0]
base=base.replace('tb_link_base #(parameter integer LANES=4,HALF_PERIOD=10)',
 'tb_phase_base #(parameter integer LANES=4,HALF_PERIOD=10,PHASE_PS=0)')
assert 'always #(HALF_PERIOD)link=~link;' in base
base=base.replace('always #(HALF_PERIOD)link=~link;',
 'initial begin #(PHASE_PS*0.001);forever #(HALF_PERIOD)link=~link;end')
rng=random.Random(20261101);cases=[]
for i in range(6):
    phase=rng.randrange(1,20000);lanes=4 if i<3 else 8
    base+=f'\nmodule tb_phase_{i};tb_phase_base #(.LANES({lanes}),.PHASE_PS({phase})) t();endmodule\n'
    cases.append(dict(top=f'tb_phase_{i}',phase_ps=phase,lanes=lanes))
bench=out/'phase_sweep.sv';bench.write_text(base)
def run(args,log):
    p=subprocess.run([str(x) for x in args],cwd=work,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
    log.write_bytes(p.stdout)
    assert p.returncode==0,log
    return p.stdout.decode(errors='replace')
run([BIN/'xvlog.bat','--sv',*sorted((ROOT/'v1/rtl').rglob('*.sv')),bench,BIN.parent/'data/verilog/src/glbl.v'],out/'compile.log')
for c in cases:
    name=c['top'];run([BIN/'xelab.bat',name,'glbl','-L','unisims_ver','-L','xpm','--snapshot',name,'--mt','2'],out/(name+'_elab.log'))
    text=run([BIN/'xsim.bat',name,'-runall','-log',out/(name+'_xsim.log')],out/(name+'_launcher.log'))
    assert 'TEST_PASS' in text and '\nError:' not in text and '\nFatal:' not in text,name
    c['status']='PASS';c['trace_sha256']=hashlib.sha256((work/'link.csv').read_bytes()).hexdigest()
    (out/(name+'.csv')).write_bytes((work/'link.csv').read_bytes())
    print('PHASE_PASS',c,flush=True)
(out/'results.json').write_text(json.dumps(dict(seed=20261101,cases=cases,
    testbench_sha256=hashlib.sha256(bench.read_bytes()).hexdigest(),
    rtl_sha256={p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted((ROOT/'v1/rtl').rglob('*.sv'))}),indent=2))
