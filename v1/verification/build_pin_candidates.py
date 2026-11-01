"""Derived factual connector mapping, conditional on actual board revision.
No CAD/wiring approval. Reads Vivado package pin bank facts from routed report.
"""
from pathlib import Path
import re,json,hashlib
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'v1/verification/evidence/prepcb_analysis';OUT.mkdir(parents=True,exist_ok=True)
common={'tx_clock':'H17','tx_valid':'A20','tx_sof':'B19','tx_ready':'B20',
 'rx_valid':'H20','rx_sof':'J20','rx_ready':'K18','control_cs_n':'M18','control_mosi':'M17',
 'control_miso':'D20','control_ready':'D19','sync_marker':'H18','marker_qualified':'E19',
 'arst':'C20','event_out':'K19','fault_out':'J19'}
tx=['F20','F19','G20','G19','L17','L16','N17','P18']
ax10='W19 W18 R14 P14 Y17 Y16 W15 V15 Y14 W14 P18 N17 U15 U14 P16 P15 U17 T16 V18 V17 T15 T14 V13 U13 W13 V12 U12 T12 T10 T11 A20 B19 B20 C20'.split()
ax11='F17 F16 F20 F19 G20 G19 H18 J18 L20 L19 M20 M19 K18 K17 J19 K19 H20 J20 L17 L16 M18 M17 D20 D19 E19 E18 G18 G17 H17 H16 G15 H15 J14 K14'.split()
ax={p:(conn,i) for conn,pins in [('J10',ax10),('J11',ax11)] for i,p in enumerate(pins,3)}
community=(ROOT/'v1/work/hardware_reference/ebaz_community.xdc').read_text()
eb={pin:(f'DATA{c}',int(pos)) for pin,c,pos in re.findall(r'PACKAGE_PIN\s+(\w+)\s+IOSTANDARD LVCMOS33.*?DATA([123])_(\d+)',community)}
rows=[]
for board,part in [('EBAZ4205','xc7z010clg400-1'),('AX7020','xc7z020clg400-2')]:
    bank={}
    text=(ROOT/'v1/verification/evidence/prepcb_impl4_03'/part/'io.rpt').read_text()
    for line in text.splitlines():
        v=[x.strip() for x in line.split('|')]
        if len(v)>8 and re.fullmatch('[A-Z]+[0-9]+',v[1]) and v[7].isdigit():bank[v[1]]=int(v[7])
    pins=dict(common)
    pins.update(dict(ref_in='H16' if board=='EBAZ4205' else 'U14',monitor_in='N18' if board=='EBAZ4205' else 'U18',
      rx_clock='J18' if board=='EBAZ4205' else 'H16',control_clock='K17' if board=='EBAZ4205' else 'J18'))
    rx=['L20','L19','M20','M19']+(['N20','P20','R18','R19'] if board=='EBAZ4205' else ['W19','W18','R14','P14'])
    pins.update({f'tx_data[{i}]':p for i,p in enumerate(tx)})
    pins.update({f'rx_data[{i}]':p for i,p in enumerate(rx)})
    assert len(set(pins.values()))==len(pins)
    for signal,pin in pins.items():
        if signal=='monitor_in':connector,cp=('X5','stock XO output') if board=='EBAZ4205' else ('board XO','U18 driven net')
        else:
            lookup=eb if board=='EBAZ4205' else ax
            assert pin in lookup,(board,signal,pin)
            connector,cp=lookup[pin]
        direction='OUT' if signal.startswith(('tx_data','tx_clock','tx_valid','tx_sof')) or signal in ['rx_ready','control_miso','control_ready','event_out','fault_out'] else 'IN'
        optional=bool(re.search(r'\[[4-7]\]',signal))
        rows.append(dict(board=board,connector=connector,connector_pin=cp,package_pin=pin,bank=bank[pin],
          io_standard='LVCMOS33',direction=direction,function=signal,profile='8bit extra' if optional else '4bit/8bit',
          shared_reserved='monitor: existing oscillator single driver' if signal=='monitor_in' else 'remove external expansion peripherals; no parallel drivers',
          electrical_risk='voltage/loading/pin1/33ohm path and actual revision unmeasured',
          source='EBAZ community schematic p1 + Development XDC + user hardware MD; conditional' if board=='EBAZ4205' else 'AX original schematic p15 + manual p29-33 + Vivado package report',
          verification='VENDOR_PACKAGE_CONFIRMED; BOARD_CANDIDATE_ONLY'))
(OUT/'pin_candidates.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2),encoding='utf8')
head='''# 候选Pin Mapping（禁止据此直接接线）

生成输入：`v1/verification/build_pin_candidates.py`、完整数字profile的Vivado report_io、用户AX原资料和EBAZ社区原图/XDC。下表是候选设计输入，不是HARDWARE_VERIFIED。EBAZ社区版本与四块实际板卡尚未核对；AX实际修订/跳线/电压也未测。所有行必须在下一阶段逐板核验后才能批准接线。

完整machine表：`v1/verification/evidence/prepcb_analysis/pin_candidates.json`。4bit使用标为4/8的行，8bit增加extra行，二者为替代配置，不是同时占用两套引脚。

| Board | Connector | Connector Pin | FPGA Package Pin | Bank | I/O Standard | Direction | Function | Profile | Shared/Reserved | Electrical Risk | Source | Verification |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
'''
for r in rows:
    head+='| '+' | '.join(str(r[k]) for k in ['board','connector','connector_pin','package_pin','bank','io_standard','direction','function','profile','shared_reserved','electrical_risk','source','verification'])+' |\n'
head+='''
## 电源、地、未使用针

AX J10/J11 pin1/37/38=GND，2=5V，39/40=3.3V；EBAZ社区DATA1/2/3 pin1/3/10/12=GND，2/4=VCC-DATA电源相关网，电压UNKNOWN。电源针在信号线束中NC/绝缘，不和其它板的供电并联。其它未使用GPIO保持输入/安全态，不能根据表中没列出就当GND。高速信号需要回流地，原有排针地分布不足的线束要额外分配接地/连接器，不能宣称全部GPIO同时使用已有足够SI回流。

EBAZ每个DATA有14个GPIO（原图经串阻），4bit全节点需要27个外接信号（另1路stock monitor），分布在3个DATA口；8bit需35个外接信号。每口2×10=20并不是20个GPIO。AX四时钟候选中monitor U18为板载50MHz振荡器网，不允许外部时钟并联；ref U14走J10.16。EBAZ ref H16和RX J18/control K17均为厂商clock-capable输入；monitor N18的X5装配及频率仍须核对。未使用CLOCK_DEDICATED_ROUTE FALSE。

原始来源：用户`E:/Codex_project/ZYNQ/AX7020/AX7020开发板原理图V2.0.pdf`第15页、`3716080086AX7020开发板用户手册V3.0.pdf`第29–33页、`E:/Codex_project/ZYNQ/EBAZ4205/EBAZ4205_硬件说明.md`；[EBAZ社区原图](https://github.com/xjtuecho/EBAZ4205/blob/master/HW/ebaz4205/EBAZ4205-SCH.pdf)与[对应XDC](https://github.com/xjtuecho/EBAZ4205/blob/master/Development/EBAZ4205.xdc)。社区XDC的示例clock period不得继承为本项目50MHz约束；本项目明确20ns。原图/连接器局部已渲染检查，未将网上相似板照片作为实物版本确认。
'''
(ROOT/'v1/docs/pre_pcb_readiness/PIN_MAPPING_CANDIDATE.md').write_text(head,encoding='utf8')
print('PIN_CANDIDATES',len(rows),'unique package pins per profile verified; board conditional')
