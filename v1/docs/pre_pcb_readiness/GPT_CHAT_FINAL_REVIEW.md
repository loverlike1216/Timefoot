# TIMEFOOT v1 — GPT-chat单文件独立审查包

> 请根据下面真实工程结果进行独立Quality Gate。本文是Codex提交的送审事实、问题和下一阶段建议，**不是ChatGPT已经给出的Review或用户硬件授权**。无需依赖本次长聊天恢复上下文；需要深入复核时按本文GitHub路径读取源码和原始证据。

## 1. 项目身份、授权与范围

```text
PROJECT_ID: TIMEFOOT
ACTIVE_VERSION: v1
STAGE: INTERFACE_TIMING_CLOSURE_AND_PRE_PCB_READINESS
REPOSITORY: https://github.com/loverlike1216/Timefoot.git
PROJECT_ROOT: E:/Codex_project/Timefoot
VERSION_ROOT: E:/Codex_project/Timefoot/v1
BRANCH: codex/v1-rtl-core
VALIDATED_SOURCE_COMMIT: 45aa523ddb4151157672df1ee3c5bb483be3edb0
SOURCE_TREE_SHA256: e2b9d1ffaa8c73ed3eb7970b3ae1bb8c18e04a54833cd712cdafa20f420098c0
PR: https://github.com/loverlike1216/Timefoot/pull/1
PR_STATE: OPEN / DRAFT / NOT_MERGED
REPORTED_READINESS: PCB_PRE_DESIGN_READY_WITH_LIMITATIONS
INDEPENDENT_CHATGPT_QUALITY_GATE: PENDING
HARDWARE_VERIFIED: NO
```

用户明确授权本轮v1内自主实施数字适配器、时序闭合、资料调查与候选硬件接口输入；允许普通Commit/Push/PR，禁止Merge、v2、正式Scope改变、原理图/PCB/制造/采购/实物连接或部署。完整实际指令已保存在`AI-interaction-memory/cross-agent/TIMEFOOT_v1_PRE_PCB_USER_INSTRUCTION.md`，SHA256 d108a8031ea2a7321010fed4a324c2709dcdf0e85a6d389597b656b696b277a7。

没有可读外部ChatGPT完整历史的工具/页面ID，AI-chat-memory保持BLOCKED；不得把本文或用户给出的Decision称为已经抓取的ChatGPT会话。当前消息/工具记录只保存可观察范围，PARTIAL。

## 2. 原问题及本轮实际解决方式

历史已验证RTL为46f88bcd553a13a9fda55b2599c6740acf6681d0，历史交付a1633e1a18df87bcb74fb9464e46e006fa406cb4，本轮启动HEAD31005c49b65349fb0aa26f27d728b70f6d83d3fd。这些不是当前验证源码，不能混用。

P-20261101-001原文件SHA256仍为**5772714a3368d27d87af9d6a90b287ad963927e7335c5a03f90778e6cb6596ba**。旧完整宽节点OOC负STA：Z010 WNS/WHS=-1.255/-0.862ns；Z020=-0.684/-0.931ns。原历史证据保留，没有把原top失败改写成PASS。

用户实际批准保留208bit核心frame，增加窄位宽source-synchronous适配器。本轮新增可综合`tf_link_tx/rx/clock_forward`、完整48bit串行管理/节点CSR、coherent多位状态快照、真实physical node top。旧数据、事件/取消、Session/Epoch、stage/source、同步有效性、错误/计数/队列信息均进入适配器/CSR，没有通过删功能端口回避时序。

初期逐beat ready回路在实际实现中失败，还发现异步安全mask直接进入FIFO写使能的REQP-1839。修复为同步input_slot终止mask，并采用**整帧credit**：RX预留一整帧；credit高授权52个4bit或26个8bit连续beat；SOF后credit低不停止已授权帧；RX交核心后再拉高；TX通过3级XPM先观察低再观察高才重新发送。没有半周期组合往返ready，也没有对失败路径加宽泛false path。

## 3. 架构和协议事实

保持公共50MHz B架构、四路CLOCK/四路SYNC/独立节点使能、AX可选管理、业务频率50/100/150/50MHz。内部frame=Session32+Sequence32+SourceTimestamp64+Length16+Payload32+CRC32，共208bit；CRC-32/BZIP2，原始采集timestamp来自真实RTL timebase，算法仍为转换`p*3+7`、处理`xor5a5aa5a5`、输出加timestamp低32（模32bit），并按显式stage map分配。

TX在link rising发DATA，ODDR转发时钟在link falling上升，RX中心采样；推荐4bit50，8bit50是实测对照。RX原始重组后必须经过core CRC/Session/Sequence/Length检查才进任务。TX入口保持槽+16深度FIFO，RX一整帧预留槽+核心FIFO。accepted、wire_sent、aborted语义分开；wire_sent不是远端CRC验收。flush后128link周期quiesce并等coherent accepted快照，stats_valid后进行ledger对账。暂停时钟期间不承诺快照及时更新。

管理串口是自定义48bit source-sync协议，不是AXI/SPI标准兼容声明。25MHz自由运行clock，host falling发MOSI、node rising采样；MISO rising更新、host falling采样；01写/02读，回复在后续事务，flags有效/错误+地址+数据。节点CSR有配置、Prepare/Abort/Run、预约/取消、同步有效性、实际事件ID/时间、执行/中止/拒绝计数及原子工作/RX/TX状态读回。物理事件直接来自参考域scheduler。

## 4. SYNC、复位和恢复修复

manager在NODE_DISCOVERY参考上升沿以旧ticks加1024生成apply_at；不是从用户start写入算固定20.48us。Prepared必须在剩余>8tick时已被观察，超时/迟到/故障优先于Prepared。marker在apply_at请求、随后参考下降沿发出；节点下一合格上升沿写staged_epoch。marker_sent与64bit半区间差值避免计数wrap误判；实际跨MAX wrap测试通过。

参考丢失/复位/资格丢失/CRC错误导致RUN与时间有效性撤销，旧任务中止，重锁后新Session+Epoch恢复。local reset在心跳toggle后短时间到来曾触发真实XPM_SINGLE采样断言（Seed17）；已修复为保持heartbeat相位、只重启分频计数，最终全矩阵没有该报错。没有关闭SIM_ASSERT_CHK。实际physical top保留外部marker_qualified输入，未置常量1；同Session重Prepare在物理管理测试中被拒绝。

## 5. 完整STA / CDC / RDC证据

Vivado/XSIM2025.2 Build6299465，实际完整综合→opt→place→phys_opt→route，非OOC。最终源码冻结45aa523，start/end源码Hash一致。

| Profile | FPGA | WNS ns | WHS ns | WPWS ns | LUT / FF / BRAM / DSP |
|---|---|---:|---:|---:|---|
| 4bit SDR50 | xc7z010clg400-1 | +0.468 | +0.009 | +2.833 | 3546 / 7961 / 9 / 0 |
| 4bit SDR50 | xc7z020clg400-2 | +0.925 | +0.028 | +2.833 | 3545 / 7961 / 9 / 0 |
| 8bit SDR50 | xc7z010clg400-1 | +0.313 | +0.016 | +2.833 | 3542 / 7956 / 9 / 0 |
| 8bit SDR50 | xc7z020clg400-2 | +0.752 | +0.036 | +2.833 | 3543 / 7956 / 9 / 0 |

四实现route errors0、Critical CDC0、无REQP-1839；bus skew最大依序1.274/1.113/1.279/1.180ns、最小slack5.568/5.765/5.519/5.734ns。原1000ns来自XPM综合时未读clock的厂商fallback，late/early同RTL对照已证明；提前读primary XDC后厂商自动max_delay=源period，bus_skew=min源/目的period。最终Gray值6.667/20/40ns，40ns为25MHz管理FIFO；handshake数据路径60ns属于不同协议，不能混为Gray疑点。

边界Profile：RX DATA/VALID/SOF相对rx falling输入min=-2、max=3ns（sender PAD偏移[-1,2]+相对布线[-1,1]）；TX数据相对中心转发时钟输出min=-1.5、max=2ns；返回RX credit按整周期min=-1.5/max2，peer XPM同步；管理CS/MOSI falling输入0.5..3、MISO/ready falling输出-1.5..2；marker/qualification要求参考falling之后0.5..3ns；event/fault输出-1.5..2。没有降50MHz、CLOCK_DEDICATED_ROUTE FALSE、blanket false path或删除hold检查。

check_timing no_clock/unconstrained_internal/no_input_delay/partial I/O均0。唯一no_output_delay为作为generated clock的tx_clock，LOW类别，不声称全零。CDC-15 warning为XPM FIFO受enable控制数据路径；TIMING-18涉及指定单launch edge、异步arst多域与转发clock，需要按约束/路径分类阅读；没有手工抹除。DRC仅RTSTAT-10和ZPS7-1 warning，PL验证top不包含PS7，真实Zynq启动集成仍需解决。默认system jitter0.071ns，工作关键路径uncertainty示例0.084ns，不含已测外部clock质量。

未运行独立专有RDC signoff。实际RDC证据是reset同步结构、XPM检查、故障/flush负例、RAM异步EN DRC和Vivado报告。不要把CriticalCDC0解释为独立RDC穷尽通过或模拟亚稳态已验证。

## 6. 真实验证、性能和复现

| 验证 | 真实结果 |
|---|---|
| 原单元测试 | 5/5 PASS |
| 新扩展 | 6/6：4bit50/8bit50/4bit25、manager wrap/lateACK、非法SOF/flush末beat、任意多位跳变快照 |
| serial-managed physical top | 64包、预约PAD事件/读回、管理访问期间故障、旧Session拒绝、新Session恢复 PASS |
| 原系统1–4节点×Seeds1/17/2026 | 12/12，独立Python2640帧 PASS |
| 新SDR适配器完整串入系统同矩阵 | 12/12，独立Python2640帧 PASS |
| 新系统Seed1重复 | 4/4，source/output/event三类CSV Hash全部MATCH |
| 4节点8bit50 | 240帧独立模型 PASS |
| 随机clock初相位 | Seed20261101派生6场景，4/8bit各3，满/反压/flush PASS |
| 远端独立干净checkout45aa523 | 5units+4节点Seed1/240帧 PASS；25RTL字节Hash和三类CSV Hash MATCH |
| 预研保护 | 全3723文件（780封存）Hash MATCH，新增/修改0 |

Python采用独立字节表CRC和算术校验，与RTL逐bit实现不同。VCD实际测业务频率50/100/150/50MHz，指定数字延迟条件下首事件偏移0/600/1200/1800ps。没有第二RTL模拟器或硬件运行证据；干净checkout仍用同一个安装的XSIM。GitHub CI未返回检查项，不能写CI PASS。

Link有效排空：4bit50为833333frame/s、8bit50为1470588frame/s，32bit payload约26.667/47.059Mbit/s；不是200/400Mbit/s原始位速率。完整physical top64包无故意堵塞观测约280899frame/s，capture到sink7.2501..10.7901us。系统另有150us故意堵塞场景，最终延迟最大151.991us，排空约527k..797kframe/s；是缓存排空，不是无限流应用稳态。逐bit源CRC仍是业务瓶颈，未为跑分引入复杂新架构。

主要复现：在PROJECT_ROOT、pwsh7运行`python -B v1/scripts/run_sim.py --tag <全新tag> --suite prepcb`，再`python -B v1/reference_model/check_system.py <tag> --prefix sdr --expected-cases 12`；完整实现`python -B v1/scripts/run_adapter.py --tag <全新tag> --lanes 4`（或8）。全部矩阵/工具版本/退出码边界见VALIDATION_AND_REPRODUCTION。建议一个Vivado实现进程，本机16GB曾因旧/新实现同时运行发生资源压力和XSIM崩溃；失败/中止日志保留，不作为最终PASS。

link8/25的CSV拷贝命名限制、negative目录可能留上一case的同名CSV已标注不作证据；使用各自xsim.log/VCD和phase sweep逐case CSV，不以文件存在认证。最终系统三CSV均完整独立校验。

## 7. 硬件候选事实与限制

已形成两板共72行完整候选外部信号表（含8bit增量）：连接器/pin、FPGA ball、Bank、方向、I/O、电气风险、来源、状态齐全。AX来自用户原图V2.0/手册V3.0；EBAZ来自用户硬件MD及社区同repo原图+XDC，**不是用户四块实物修订确认**。EBAZ4bit需要27根外接信号，分散在DATA1/2/3，每口14GPIO，另一路stock X5 monitor。必须逐板确认Bank电压、扩展外设并联驱动、pin1和33ohm路径；不用照片推断电源。

AX J10/J11电源针2=5V、39/40=3.3V，GND1/37/38；EBAZ社区DATA的2/4为电源相关网、1/3/10/12为GND。信号线束电源针NC/绝缘，不能把其它板电源直接并联。monitor AX U18是板载XO网，不能并接外部驱动。具体表与来源见PIN_MAPPING_CANDIDATE。

候选BOM：Abracon ASE-50.000MHZ-L-C-T50MHz3.3V；两颗SN65LVDS105PWR分别分CLOCK/SYNC、各四路独立EN；四节点各两颗SN65LVDT2DBVR接收；TPS62162DSGR接口3.3V/1A候选。LMK00304作为低抖动对照，但差分输出两bank、不是四路独立OE；其OSCin晶体10..40MHz不能当50MHz晶体接口，外源优先CLKin。LMK1C1104为global OE单端对照。105当次TI页面ACTIVE但Out of stock；连接器配合件、保护/无源/热设计尚未冻结。所有器件选择均有厂商资料，未采购/CAD。

## 8. 真正未解决的问题（集中上报）

**HW-PHASE-001 / HIGH，P-20261101-002 OPEN。** 原因：独立CLOCK/SYNC fanout和receiver器差。已查TI真实资料、比较三种fanout、完成16×5000edge模型和保守预算；rising fanout差±1.3ns、receiver差±2.2ns，再加线缆/板/抖动预留合计±5ns，不能直接保证当前数字Profile SYNC输入0.5..3ns。没有物理路径/器件匹配信息，不能从RTL消除。影响：硬件相位资格及BOM冻结HOLD；数字Profile结果有效于它的输入假设。建议匹配多通道接收/路径或可验证相位补偿，实测满足才拉高qualification。需要用户另行授权才能进入CAD/实物验证；此处没有自动修改Scope或放宽XDC。

**HW-REV/SI-001 / HIGH硬件门禁。** 原因：四块实际EBAZ修订、电压/驱动/电源针与线缆SI未知。已用社区原图/XDC、AX原资料和厂商封装交叉核对条件候选；无法替代逐板通断/电压、接收共模、眼图/BER和断电反灌测试。影响：禁止据表直接连接或制造；下一阶段测量/复核后冻结pin和线束。用户硬件操作授权仍未获得。

其它明确限制：PL-only验证top缺PS7启动集成；无独立RDC工具；无自动单包重传/单端复位恢复，raw framer截断帧依赖上层timeout/flush；部分BOM供应/机械配合未锁定；外部jitter/温度/24h硬件未验。完整逐项Issue表见OPEN_ISSUES_AND_RISKS。已执行数字范围内Blocking=0、已知Critical RTL Bug=0，不把硬件门禁写成已通过。

## 9. 长期时间模型能证明什么

整数ps独立模型枚举16个有效clock/SYNC条件，每例5000edge、含64bit wrap，全部trace一致；负例11ns真实触发Apply晚1周期。1秒/1小时/24h/30d是解析公共边沿计数，不是长时RTL或实板运行；共同源且无漏边沿时相对tick drift0，±50ppm绝对频差24h可达±4.32秒。真实PAD偏差、温漂、噪声、亚稳态概率仍未测。

## 10. 请GPT-chat作出的独立判断

1. 新完整功能physical top及整帧credit是否合理关闭P-001数字接口问题？请重点核对功能保留、RX最坏min/max、credit语义和XPM例外有效性。
2. 对XPM CDC-15、TIMING-18、generated-clock no_output_delay和RDC证据范围的分类是否充分，是否有遗漏的关键异步/复位路径？
3. 是否接受本阶段 **PCB_PRE_DESIGN_READY_WITH_LIMITATIONS**，同时保持HW-PHASE/HW-REV/SI冻结HOLD？不要把有限数字准备等同实物安全。
4. 下一阶段优先采用哪种匹配接收/相位资格方案，以及必须通过什么量化测量后才允许冻结BOM/管脚？
5. 请最终给出ACCEPT / ACCEPT WITH LIMITATIONS / REVISE及必要修改项。若修改，请区分数字Blocking、硬件Stage前置条件和可选低收益工具改进。

## 11. 下一阶段预期与权限边界

保持v1，不自动开v2。先完成本包独立Review和P-002决策；用户再决定是否授权原理图/PCB与实物测量。若授权，先逐板核对版本/电压/连接器/驱动，解决CLOCK/SYNC相位预算和资格检测，再冻结BOM/电源/接收/线束。先做有参考面的CLOCK/SYNC/事件与DATA SI/BER/故障安全测量计划，后续才能形成原理图/PCB设计输入的正式冻结版。

预期验收：所有板的实际相位落入有效数字Profile、inactive node安全、失锁/断线/插拔不执行旧任务；50MHz窄链路实测无误码且达到需求吞吐；Session恢复和24h稳定性有真实仪器/运行日志。若实测不满足，回到有依据的接口/器件决策并重跑STA与回归，不能直接降低验收。

在新的硬件授权前，Codex只接收Review、执行Scope内数字修订/资料补证和正常Git同步；不生成原理图/PCB/Gerber/制造订单，不Merge、不采购、不部署。

## 12. 原始证据定位

在上述Repository的`codex/v1-rtl-core`分支读取（main未合并）：

- `v1/verification/evidence/prepcb_analysis/stage_audit.json`：四实现、7suite、3723历史Hash、重跑Hash、真实VCD周期/事件。
- `v1/verification/evidence/prepcb_impl4_03/`、`prepcb_impl8_03/`：每Part timing/setup/hold/datasheet/CDC/DRC/bus_skew/route/clock_interaction/exceptions/coverage/effective XDC/utilization。
- `v1/verification/evidence/prepcb_system03/`、`prepcb_repeat03/`、`prepcb_8bit03/`、`prepcb_physical03/`：真实日志/CSV/source start-end manifests。
- `v1/verification/evidence/prepcb_clean/result.json`：远端干净检出复现及源/trace Hash。
- `v1/verification/evidence/prepcb_analysis/clock_budget.json`、`link_measurements.json`、`pin_candidates.json`：模型/实际VCD性能/完整候选引脚。
- `v1/docs/XPM_CDC_CONSTRAINT_AUDIT.md`与`p0_order_early/late`：1000ns根因实验。
- `AI-problem/decision/P-20261101-001__source-synchronous-adapter.md`：真实用户批准来源。
- `AI-problem/problem/P-20261101-002__clock-sync-hardware-qualification.md`：硬件相位决策包，SHA256 **6745c3b75b1ee595d275d1a1a2be2fddd646eb84f0842a78f25587d661eda74d**。
- `v1/docs/pre_pcb_readiness/`：14项详细设计输入；`shared/CONTEXT_CHECKPOINT.*`为下次恢复入口。

大型VCD/DCP保留本地并由artifact manifest索引，GitHub只保存可重建的源码/日志/rpt/CSV/Hash；不能假定远端包含被gitignore的波形。所有历史失败和预研原记录保留。以上是送审事实，不替代Reviewer实际检查源码、约束和原始报告。
