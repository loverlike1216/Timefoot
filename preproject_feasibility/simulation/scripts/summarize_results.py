from pathlib import Path
import json,re,hashlib
ROOT=Path(__file__).resolve().parents[2]
def text(p):return (ROOT/p).read_text(encoding='utf-8',errors='replace')
def timing(s):
    pos=s.index('WNS(ns)');lines=s[pos:].splitlines()
    for line in lines[2:]:
        cols=line.split()
        if len(cols)>=12 and re.fullmatch(r'-?\d+\.\d+',cols[0]):
            return dict(wns=float(cols[0]),tns=float(cols[1]),setup_fail=int(cols[2]),whs=float(cols[4]),ths=float(cols[5]),hold_fail=int(cols[6]))
    raise ValueError('No timing summary')
def cell(s,name):
    m=re.search(r'\|\s*'+re.escape(name)+r'\s*\|\s*(\d+)',s)
    return int(m[1]) if m else 0
summary={'date':'2026-11-01','timezone':'Asia/Shanghai','formal_version':'NOT_STARTED','status':'CONSULTATION_ONLY'}
summary['reproducibility']=json.loads(text('evidence/simulation_logs/reproducibility.json'))
assert summary['reproducibility']['total_simulator_executions']==38
summary['devices']=[]
for part in ['xc7z010clg400-1','xc7z020clg400-2']:
    u=text(f'evidence/resource_reports/{part}_routed.rpt');c=text(f'evidence/timing_reports/{part}/cdc_routed.rpt')
    summary['devices'].append({'part':part,'target_basis':'requested_candidate' if '010' in part else 'manual_candidate_not_physical_identification',
      'ooc_timing':timing(text(f'evidence/timing_reports/{part}/timing_summary_routed.rpt')),
      'pin_probe_timing':timing(text(f'evidence/timing_reports/{part}_pin_probe/timing.rpt')),
      'resources':{k:cell(u,k) for k in ['Slice LUTs','Slice Registers','Block RAM Tile','MMCME2_ADV','PLLE2_ADV','BUFGCTRL']},
      'critical_cdc':sum(map(int,re.findall(r'^CDC-\d+\s+Critical\s+(\d+)',c,re.M))),
      'cdc_status':'REVISE','board_sta_status':'NOT_VERIFIED','pin_probe_sta_status':'FAIL'})
summary['pipeline']=[]
for r in json.loads(text('evidence/simulation_logs/finalE/results.json')):
    if r['testbench']=='tb_pipeline':
        log=text(f'evidence/simulation_logs/finalE/{r["case"]}/xsim.log')
        m=re.search(r'frames=(\d+) stalls=(\d+) full_samples=(\d+) duration_ns=([\d.]+)',log)
        frames,stalls,fullsamples=map(int,m.group(1,2,3));duration=float(m[4])
        summary['pipeline'].append({'case':r['case'],'seed':r['seed'],'source_gap':r['source_gap'],'frames_before_fault':frames,
          'source_stalls':stalls,'full_samples':fullsamples,'duration_ns':duration,
          'virtual_frames_per_second':frames/duration*1e9,'scope':'128-bit abstract ready/valid links, not physical bandwidth'})
code={str(p.relative_to(ROOT)).replace('\\','/'):hashlib.sha256(p.read_bytes()).hexdigest()
      for p in sorted((ROOT/'simulation').rglob('*')) if p.is_file() and p.suffix in ['.sv','.v','.tcl','.py']}
(ROOT/'evidence/environment/validation_source_hashes.json').write_text(json.dumps(code,indent=2),encoding='utf-8')
(ROOT/'evidence/RESULT_SUMMARY.json').write_text(json.dumps(summary,indent=2),encoding='utf-8')
device_rows='\n'.join(f'| {d["part"]} | {d["resources"]["Slice LUTs"]} | {d["resources"]["Slice Registers"]} | {d["resources"]["Block RAM Tile"]} | 1 / 0 / 4 | {d["ooc_timing"]["wns"]:+.3f} / {d["ooc_timing"]["whs"]:+.3f} | {d["pin_probe_timing"]["wns"]:+.3f} | {d["critical_cdc"]} |' for d in summary['devices'])
pipe_rows='\n'.join(f'| {p["seed"]} | {p["source_gap"]} | 320 | {p["duration_ns"]:.0f} | {p["source_stalls"]} | {p["full_samples"]} | {p["virtual_frames_per_second"]/1e6:.3f} |' for p in summary['pipeline'])
frames=summary['reproducibility']['independently_decoded_pipeline_frames_one_run']
report=f'''# Simulation and Validation Report

Date: 2026-11-01, Asia/Shanghai. Executor: Codex. Project ID: NOT_ASSIGNED; Version: NOT_STARTED; Stage: RESEARCH_AND_SIMULATION. Repository/Branch/Commit: NOT_APPLICABLE (no Git repository or formal project was started).

Workspace: `E:/Codex_project/Timefoot/preproject_feasibility`.

## Outcome and scope

**Overall validation outcome: PARTIAL.** 最终RTL矩阵为19例×2次独立编译/执行=38/38 PASS；数学模型及独立结果交叉核验PASS；两Part实际OOC实现完成且本约束下setup/hold满足；但是管脚试验的输出STA FAIL，CDC为REVISE，电气与实板NOT_CHECKED。这不是系统硬件验收。

## Actual environment

Windows；PowerShell7.6.5；Python3.10.11；Vivado/XSIM2025.2 Build6299465；隔离依赖PyMuPDF1.26.7。实际许可获取/释放见环境probe与build日志。没有Verilator/Icarus/Yosys第二工具链结果。原始附件与任务Hash在 `evidence/environment/source_manifest.json`，当前验证源Hash在 `evidence/environment/validation_source_hashes.json`。沒有伪造Git commit。

## Test matrix and acceptance

| 用户测试 | 本次结果 | 实际判据与限制 | 证据 |
|---|---|---|---|
| Test1，1/2/3/4节点 | PASS（同步逻辑） | 同一参数化核心；未用通道事件=0；使能/晚加入隔离、单节点复位恢复；晚加入时间精度不在本次PASS内 | `evidence/simulation_logs/finalE/tb_sync_1_seed1/` 至4节点，各Seed；finalF重跑 |
| Test2，共同参考/分配延迟 | PARTIAL | 原始路径0/2/5/10ns，初次预约输出边沿分别相差0/2/5/10ns且同一逻辑tick；没有以零延迟证明零偏差。物理校准RTL未实现；仅有明确假设的算法模型 | 同步event_trace.csv；reference_model/results.json |
| Test3，不同频率 | PASS（原语参数和逻辑数据处理） | 输入50、VCO900、分频18/9/6；UNISIM 2us统计100/200/300个边沿，周期容差50MHz±0.01ns、100MHz±0.01ns、150MHz6.65–6.68ns；综合DRC也接受两Part | tb_mmcm_seed1与各pipeline日志 |
| Test4，±10/20/50ppm | PASS（数学/加速模型） | 1ms显式边沿枚举与Fraction公式相差≤20ns，再外推1s/60s/1h/24h；公共源只消除模型中的相对频率斜率，保留偏斜和绝对误差 | reference_model/results.json、drift.csv |
| Test5，四节点任务链 | PASS（抽象数据接口） | 预约事件启动采样，携带真实仿真sync计数器时间戳；算术链、序号、时间戳、FIFO和反压检查；Seed1/17/2026×source_gap0/3；每次正常320帧，故障后80帧 | finalE/finalF各6组pipeline_trace.csv |
| Test6，故障与稳定性 | PARTIAL | 晚启动、reference中断、模拟失锁、SYNC timeout、单节点reset、延迟/停读变化、满空、64bit wrap、重复重同步、丢链session flush恢复均执行；尚无真实24h/温漂、精确late-join、独立局部FIFO复位协议或电气热插拔验证 | 同步/流水线PASS与FAULT行；FAILURE_AND_RCA.md |
| Test7，可重复性 | PASS（定义内） | finalE与finalF 19对case，三个Seed；同Seed的CSV字节Hash与规范化PASS/FAULT/锁定行Hash全部相同。未声称含主机/日期的原始日志逐字节相同 | reproducibility.json、verify_evidence.log |

同步测试本身无随机刺激，三Seed是重复配置；随机Seed真正影响流水线反压与模型噪声，不将其夸大为随机CDC签核。19例是配置总数，每例包含多个断言，不等于仅19条断言。

## Integrated data experiment

输入为定义明确的合成采样payload `17*frame_id+3`，不是ADC硬件数据。Node2计算 `3*x+7`，Node3异或 `0x5a5aa5a5`，Node4加source timestamp低32bit，溢出按无符号32bit取模。128bit包为{{seq32,timestamp64,payload32}}。Reference时钟域预约事件启动第一帧，timestamp来自实际RTL时间计数器；三条独立深度8 FIFO跨50→100→150→50工作域，每阶段有握手/寄存，sink停读及随机限流造成真实满和反压。

行为时钟精度为1ps，pipeline的150MHz模型半周期3.333333ns会舍入到3.333ns（约150.015MHz）；其目的包含CDC容忍验证，不能据此宣称三工作时钟严格相位锁定。准确标称分频另由真实UNISIM检查。同步故障测试中的LOCK输入是故障注入，不是测量真实PLL。

| Seed | 额外输入间隔/cycles | 正常帧 | 时长/ns | 源反压采样 | FIFO满采样 | 抽象吞吐/Mframe/s |
|---|---|---|---|---|---|---|
{pipe_rows}

额外间隔0/3在无背压时分别约40/100ns一帧。表中包含共同的6us停读窗口及后续停读。**这些是128bit虚拟链路吞吐，不是排针/电缆带宽**。尚无serializer、源同步PHY、CRC/retry、实际I/O误码或四个封装的互连模型。Python独立解码一轮共{frames}帧，检查每帧序号、时间戳单调及算术；第二轮trace字节相同。故障中止帧逐case明确记录，已接受=已交付+已中止，禁止称为故障期间零丢帧；新session恢复80帧未出现旧包。

## Timing/resource evidence

| 文档/要求候选Part | LUT | FF | BRAM | MMCM/PLL/BUFG | OOC WNS/WHS ns | 管脚top WNS ns | 严重CDC |
|---|---|---|---|---|---|---|---|
{device_rows}

OOC TNS=THS=0，路由报告无routing error；`check_timing`在这些虚拟约束下的无时钟/缺I/O延迟/未约束内部端点均0。OOC顶层每节点含1个64bit同步核心、1条128bit深8 FIFO、1个异或任务级和1套50/100/150MHz时钟树，不是四板完整系统资源。存储实际映射为1024个FF，**BRAM=0不表示FIFO不占资源**；Z010的1个MMCM占器件2个中的50%。未来更深FIFO应另评估RAM/XPM。

OOC端口延迟是探索性2ns，不是线缆测得值；无HD.PARTPIN_LOCS及monitor端口HD.CLK_SRC警告保留。独立monitor100与reference在STA中有周期性边沿关系，真实独立晶振不能靠这里的正裕量证明CDC正确；后续必须在结构审核后采用针对性的异步约束及Gray skew/延迟约束。本轮没有加宽泛false_path掩盖问题。

管脚top使用H16（Z010）/U14（Z020）专用输入、IBUF→MMCM→BUFG并实际布线，没有CLOCK_DEDICATED_ROUTE FALSE。其150MHz `d_reg[7]`→q[0]（W13）相对50MHz外部捕获边沿且输出delay2ns的路径 **setup FAIL**，两Part的负WNS如上；hold分别+0.167/+0.185ns。证明合法时钟路线，未证明该输出接口满足接收时序。最终应用应定义实际输出寄存/转发时钟及接收预算后重新实现，不删除失败报告。

最终CDC每Part：CDC-1×2、CDC-7×6、CDC-10×1，共9条Critical；另CDC-15×5 Warning、CDC-9×1 Info。对应独立monitor crossing、异步复位/安全门控和组合信号前置同步，不能自动waive。DRC保留ZPS7-1（未实例化PS7）Warning；当前没有bitstream、PS配置或部署。

## Error/phase model limits

独立±50ppm两节点在1秒/1小时/一天的相对偏差为100us/360ms/8.64s。共源模型的相对频率漂移为0，但不消除常量路径偏斜、接收门限温漂、重锁相位、输出抖动或公共XO相对UTC漂移。独立SYNC/REF捕获边界的模型反例得到60/50/60/70ns，表明可出现整20ns的epoch差异。

细校准模型人为假定0.25ns延迟执行器和±50ps噪声，只用于说明“测量+执行器”如何消除已知偏置，没有对应器件/RTL签核。伺服模型假定10Hz更新、±100ns噪声及0.5ppm残余误差；100秒离散模型不是完整PTP/WR，也不证明连续时间无瞬时回跳；连续单调slew尚未实现。

## Reproduction and baseline

原始驱动命令：PowerShell7启动Python `simulation/scripts/run_xsim.py --tag finalE` 与 `--tag finalF`，reference_model/experiments.py，再 verify_evidence.py；各外部命令exit0。Vivado batch分别运行probe_vivado.tcl、build_ooc.tcl、pin_routing.tcl，保留log/jou/launcher，exit0仅表示工具流程成功，不能覆盖负STA。

可安全重放：在本目录执行 `pwsh -NoProfile -File ./REPLAY.ps1`；可加 `-IncludeImplementation`。脚本创建全新 `.work/replay_<timestamp>`，不覆盖交付证据；若安装路径不同传 `-VivadoBin`。依赖锁定见requirements.txt。完整wrapper已在新副本实际复跑额外38例PASS，所有对应Trace/规范化结果Hash与交付基线一致；路径与核验见DELIVERY_AUDIT.json。IncludeImplementation分支的各底层综合/实现命令已独立实际执行，本轮没有在wrapper内重复这部分。

16例早期baseline位于finalA/finalB；finalC保留覆盖失败；本次有效baseline为finalE/finalF的19例。硬件前没有历史实测baseline；不能报告比现有产品更快/更准。

独立交叉检查为Python标量数学及源Hash/重放检查；没有第二RTL工具链、CI、外部ChatGPT最终Review或实板证据。完整交付应由ChatGPT继续审阅，不能由本Agent自证物理系统通过。
'''
(ROOT/'SIMULATION_REPORT.md').write_text(report,encoding='utf-8')
print(json.dumps({'devices':summary['devices'],'crosschecked_frames':frames,'pipeline_cases':len(summary['pipeline'])},indent=2))
