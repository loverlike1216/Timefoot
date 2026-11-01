# 验证证据与复现

PROJECT_ID TIMEFOOT / v1 / INTERFACE_TIMING_CLOSURE_AND_PRE_PCB_READINESS。
Repository `https://github.com/loverlike1216/Timefoot.git`，branch `codex/v1-rtl-core`。
验证源码Commit **45aa523ddb4151157672df1ee3c5bb483be3edb0**；source_tree SHA256 **e2b9d1ffaa8c73ed3eb7970b3ae1bb8c18e04a54833cd712cdafa20f420098c0**。之后文档/验证分析脚本提交不冒充重新实现的RTL。

## 实际环境

Windows、PowerShell7.6.5、Python3.10.11（核心runner只用stdlib）、Vivado/XSIM2025.2 Build6299465、实际目标器件支持及有效综合/实现license。默认工具路径`D:/Vivado/2025.2/2025.2/Vivado/bin`，可用TIMEFOOT_VIVADO_BIN明确设置。运行目录、TMP、TEMP、所有日志/波形/临时工程均在PROJECT_ROOT/v1/work或verification/evidence。外部安装的Vivado只读使用，未改变系统启动设置。

## 冻结输入最终矩阵

| tag | 真正执行内容 | 结果 |
|---|---|---|
| prepcb_unit03 | 原5项scheduler/FIFO/stream/control/SYNC窗口 | 5/5 PASS |
| prepcb_link03 | 4bit50、8bit50、4bit25、manager wrap/late ACK、非法SOF/flush末beat、任意多位快照 | 6/6 PASS |
| prepcb_physical03 | 真实物理top、串行命令/状态、预约PAD事件、64业务帧、访问中故障、旧Session拒绝 | 1/1 PASS |
| prepcb_legacy03 | 原1–4节点×Seeds1/17/2026 | 12/12 PASS；独立2640帧 |
| prepcb_system03 | 新适配器真实串入每段（含末端）的1–4节点×同3Seeds | 12/12 PASS；独立2640帧 |
| prepcb_repeat03 | 新适配器1–4节点Seed1再次运行 | 4/4，输出/源/事件三类CSV Hash逐一MATCH |
| prepcb_8bit03 | 4节点8bit SDR50，Seed1 | PASS；独立240帧 |
| prepcb_phases | 随机种子20261101选6个初始clock相位，3×4bit+3×8bit真实链路满/反压/flush | 6/6 PASS；派生TB全文和Hash留存 |
| prepcb_impl4_03 / prepcb_impl8_03 | 两Part各full synth/opt/place/phys_opt/route/STA/CDC/DRC/bus_skew | 四实现全部PASS，条件见时序规范 |
| prepcb_analysis | 历史Hash、start/end source、独立CRC/数值、VCD时钟、链路测量、长期条件模型 | stage_audit / clock_budget / link_measurements JSON |

原始负例还包括CRC、Session、Sequence、Length、满空、迟到/取消/旧事件，参考停止/MMCM重锁、local reset/late join、资格丢失、mask重新映射。系统Seed控制反压，初始随机phase另由独立phase sweep覆盖。模型线缆延迟明确、固定，不包含模拟SI/亚稳态概率。

## 复现命令

在已核对的PROJECT_ROOT用pwsh运行，每次必须使用**未存在的新tag**。不覆盖本交付tag。

```powershell
Set-Location -LiteralPath 'E:/Codex_project/Timefoot'
$env:TIMEFOOT_VIVADO_BIN = 'D:/Vivado/2025.2/2025.2/Vivado/bin'
python -B v1/scripts/run_sim.py --tag replay_new_unit --suite unit
python -B v1/scripts/run_sim.py --tag replay_new_link --suite link
python -B v1/scripts/run_sim.py --tag replay_new_physical --suite tb_physical_node
python -B v1/scripts/run_sim.py --tag replay_new_system --suite prepcb
python -B v1/reference_model/check_system.py replay_new_system --prefix sdr --expected-cases 12
python -B v1/scripts/run_sim.py --tag replay_new_repeat --suite prepcb_repeat
python -B v1/scripts/run_sim.py --tag replay_new_legacy --suite system
python -B v1/reference_model/check_system.py replay_new_legacy
python -B v1/scripts/run_sim.py --tag replay_new_8 --suite tb_sdr_system_4x8
python -B v1/reference_model/check_system.py replay_new_8 --prefix sdr --expected-cases 1
python -B v1/scripts/run_adapter.py --tag replay_new_impl4 --lanes 4
python -B v1/scripts/run_adapter.py --tag replay_new_impl8 --lanes 8
```

每条外部命令需检查LASTEXITCODE。建议一个Vivado实现进程，仿真适量串行：本机16GB，多个旧/新实现同时运行曾发生资源压力和XSIM EXCEPTION_ACCESS_VIOLATION，证据保留。不是通过重试忽略RTL assertion：Seed17心跳断言先修复RTL再重跑最终矩阵。已中止的prepcb_impl4/02、XSim崩溃的system02、源改变的早期测试不列为最终签核。

`python -B v1/verification/audit_prepcb.py`对本交付固定标签进行只读聚合/核查，不生成RTL。`clock_budget_model.py`、`build_pin_candidates.py`、`measure_link.py`输出项目内派生分析。VCD/DCP保留本机且有artifact manifest；GitHub保存源码、CSV、日志、rpt和Hash，忽略体积大的VCD/DCP，可依命令重建，不能声称远端具有被忽略二进制。

## Trace使用限制

系统三类CSV都在各case目录，有独立Python逐包检查和重跑Hash。link runner的文件名匹配会漏拷贝tb_link8/tb_link25的`link.csv`，且可能在不产CSV的negative case目录留上一case的同名CSV。**那些CSV不是该case的证据**，不用于任何结论；其结果取独立xsim.log断言、各自VCD和phase sweep逐case保存的CSV。这个产物导航限制不改变真实模拟结果，保留原目录避免篡改原始运行。其它测试也不靠“某个CSV存在”判断PASS。

## 独立复核范围

Python字节表CRC与RTL逐bit CRC不同实现；Python独立计算业务数值和原始采集时间戳，VCD独立测UNISIM输出频率/预约边沿；远端干净检出复现另留结果。仍是同版本XSIM，不能冒充第二RTL模拟器。ChatGPT独立Quality Gate未收到；GPT_CHAT_FINAL_REVIEW是送审材料，不是伪造审查意见。

## Completed remote replay

AuthenticatedGitHub cleanclone45aa523 underPROJECT_ROOT/v1/work/prepcb_clean reran5units and4nodeSDRSeed1,240Python-checkedpackets;25RTL byte hashes and3CSVbytehashes match. Raw copiedlogs/manifests/results: evidence/prepcb_clean/; machine summary result.json. No second simulator claim.
