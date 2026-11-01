"""Independent byte-table CRC and arithmetic reference, matched to captured RTL inputs."""
from pathlib import Path
import json,csv,struct,hashlib,argparse
ROOT=Path(__file__).resolve().parents[2]
def crc32_bzip2(data):
    table=[]
    for i in range(256):
        c=i<<24
        for _ in range(8):c=((c<<1)^0x04c11db7 if c&0x80000000 else c<<1)&0xffffffff
        table.append(c)
    c=0xffffffff
    for b in data:c=((c<<8)&0xffffffff)^table[(c>>24)^b]
    return c^0xffffffff
assert crc32_bzip2(b'123456789')==0xfc891918
def check(tag):
    base=ROOT/'v1/verification/evidence'/tag
    results=[]
    for case in sorted(base.glob('tb_system_*_s*')):
        inputs={}
        for phase,t,body in csv.reader((case/'system_source.csv').open()):
            raw=bytes.fromhex(body.zfill(44));s,q,ts,length=struct.unpack('>IIQH',raw[:18]);p=int.from_bytes(raw[18:],'big')
            assert p==(q*17+3)&0xffffffff and length==4
            assert (s,q) not in inputs
            inputs[s,q]=(ts,p,int(t))
        perphase={};latencies=[];times={};packets=0
        for phase,t,s,q,frame in csv.reader((case/'system.csv').open()):
            raw=bytes.fromhex(frame.zfill(52));session,seq,stamp,length=struct.unpack('>IIQH',raw[:18])
            assert session==int(s) and seq==int(q) and length==4
            assert int.from_bytes(raw[-4:],'big')==crc32_bzip2(raw[:-4])
            it,p,created=inputs[session,seq];assert it==stamp
            expected=((((p*3+7)&0xffffffff)^0x5a5aa5a5)+(stamp&0xffffffff))&0xffffffff
            assert int.from_bytes(raw[18:22],'big')==expected
            phase=int(phase);assert seq==perphase.get(phase,0);perphase[phase]=seq+1
            latency=int(t)-created;assert latency>=0;latencies.append(latency);times.setdefault(phase,[]).append(int(t));packets+=1
        assert packets>0 and all(n==40 for n in perphase.values())
        result={'case':case.name,'status':'PASS','packets':packets,'phases':perphase,
                'min_latency_ns':min(latencies),'max_latency_ns':max(latencies),
                'phase_drain_fps':{p:round(39e9/(v[-1]-v[0]),2) for p,v in times.items()},
                'trace_sha256':hashlib.sha256((case/'system.csv').read_bytes()).hexdigest()}
        results.append(result)
    assert len(results)==12, f'Expected 12 system cases, found {len(results)}'
    (base/'python_crosscheck.json').write_text(json.dumps(results,indent=2))
    print('PYTHON_CROSSCHECK_PASS',len(results),'packets',sum(r['packets'] for r in results))
    return results
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('tag');check(p.parse_args().tag)
