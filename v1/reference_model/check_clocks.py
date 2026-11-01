"""Measure real UNISIM output periods and first scheduled output skew from VCD."""
from pathlib import Path
import re,json,statistics
ROOT=Path(__file__).resolve().parents[2]
def one(path,n):
    ids={};t=0;start=None;old=0;edges=[[] for _ in range(n)];events=[None]*n
    with path.open() as f:
        for line in f:
            s=line.strip()
            if s.startswith('$var'):
                p=s.split()
                if p[4] in ['wclk','running','execute']:ids[p[4]]=p[3]
            elif s.startswith('#'):
                t=int(s[1:])
                if start is not None and t>start+5000000:break
            elif ids.get('running') and s=='1'+ids['running'] and start is None:start=t
            elif s.startswith('b'):
                value,code=s[1:].split()
                if not set(value)<={'0','1'}:continue
                x=int(value,2)
                if code==ids.get('wclk'):
                    if start is not None:
                        for i in range(n):
                            if x&(1<<i) and not old&(1<<i):edges[i].append(t)
                    old=x
                elif code==ids.get('execute') and start is not None:
                    for i in range(n):
                        if x&(1<<i) and events[i] is None:events[i]=t
    periods=[]
    for i in range(n):
        diff=[b-a for a,b in zip(edges[i],edges[i][1:])];assert len(diff)>100
        expected=[20000,10000,20000/3,20000][i]
        assert min(diff)>=expected-2 and max(diff)<=expected+2,(i,min(diff),max(diff))
        periods.append({'node':i,'period_min_ps':min(diff),'period_max_ps':max(diff),'edges':len(edges[i])})
    assert all(v is not None for v in events)
    skew=max(events)-min(events);assert skew<=3000
    return {'nodes':n,'periods':periods,'first_event_offsets_ps':[v-min(events) for v in events],'event_skew_ps':skew,'status':'PASS'}
def main():
    results=[one(ROOT/f'v1/verification/evidence/closure_system/tb_system_{n}_s1/wave.vcd',n) for n in range(1,5)]
    (ROOT/'v1/verification/evidence/clock_measurements.json').write_text(json.dumps(results,indent=2))
    print('VCD_CLOCK_AND_EVENT_PASS',len(results))
if __name__=='__main__':main()
