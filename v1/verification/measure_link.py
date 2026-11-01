"""Measure real XSIM wave edges/counters, without estimating missing latency."""
from pathlib import Path
import json,statistics
ROOT=Path(__file__).resolve().parents[2];E=ROOT/'v1/verification/evidence'

def parse(path,wanted):
    scopes=[];ids={};changes={k:[] for k in wanted};last={};time=0
    with path.open() as stream:
      for line in stream:
        s=line.strip()
        if s.startswith('$scope'):scopes.append(s.split()[2])
        elif s.startswith('$upscope'):scopes.pop()
        elif s.startswith('$var'):
            p=s.split();name='.'.join(scopes+[p[4]])
            if name in wanted:ids[p[3]]=name
        elif s.startswith('#'):time=int(s[1:])
        elif s and s[0] in '01bxz':
            if s[0]=='b':v,code=s[1:].split()
            else:v,code=s[0],s[1:]
            if code not in ids or not set(v)<=set('01'):continue
            name=ids[code];value=int(v,2)
            if last.get(name)!=value:changes[name].append((time,value));last[name]=value
    assert all(changes.values()),wanted
    return changes

def main():
    result={}
    for top in ['tb_link','tb_link8','tb_link25']:
        prefix=top+'.t.'
        d=parse(E/f'prepcb_link03/{top}_s1/wave.vcd',[prefix+x for x in ['ts','link','fclock']])
        starts=[t for t,v in d[prefix+'ts'] if v][-24:]
        intervals=[(b-a)/1000 for a,b in zip(starts,starts[1:])]
        falling=[t for t,v in d[prefix+'link'] if not v and t>0]
        forwarded=[t for t,v in d[prefix+'fclock'] if v]
        # UNISIM ODDR includes 100ps clock-to-Q in this functional model.
        assert set(t+100 for t in falling[-100:])<=set(forwarded)
        half=20 if top=='tb_link25' else 10
        result[top]=dict(post_flush_frames=len(starts),frame_interval_min_ns=min(intervals),
            frame_interval_max_ns=max(intervals),drain_frames_per_second=1e9/statistics.mean(intervals),
            forwarded_rising_after_link_falling_ns=0.1,observed_launch_to_capture_ns=half+0.1)
    p='tb_physical_node.'
    d=parse(E/'prepcb_physical03/tb_physical_node_s1/wave.vcd',[p+'got',p+'dut.samples'])
    delivered={v:t for t,v in d[p+'got'] if 0<v<=64}
    captured={}
    for t,v in d[p+'dut.samples']:
        if 0<v<=64 and v not in captured:captured[v]=t
    assert len(delivered)==len(captured)==64
    lat=[(delivered[i]-captured[i])/1000 for i in range(1,65)]
    assert min(lat)>=0
    result['physical_node']=dict(packets=64,min_capture_to_sink_ns=min(lat),max_capture_to_sink_ns=max(lat),
        first_to_last_delivery_frames_per_second=63e12/(delivered[64]-delivered[1]),
        first_to_last_capture_frames_per_second=63e12/(captured[64]-captured[1]),
        measurement='Actual VCD sample_count/got edges; serial-managed150MHz physical node; no deliberate output block')
    (E/'prepcb_analysis/link_measurements.json').write_text(json.dumps(result,indent=2))
    print(json.dumps(result,indent=2))
if __name__=='__main__':main()
