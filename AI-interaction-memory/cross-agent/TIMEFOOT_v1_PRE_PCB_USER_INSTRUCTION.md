# TIMEFOOT v1 — Codex 下一阶段完整执行指令

## 0. 任务授权与执行模式

```text
PROJECT_ID: TIMEFOOT
PROJECT_STATUS: PROJECT_ACTIVE
ACTIVE_VERSION: v1
STAGE: INTERFACE_TIMING_CLOSURE_AND_PRE_PCB_READINESS
MODE: AUTONOMOUS_IMPLEMENT_RUN_VERIFY

REPOSITORY:
https://github.com/loverlike1216/Timefoot.git

PROJECT_ROOT:
E:\Codex_project\Timefoot

VERSION_ROOT:
E:\Codex_project\Timefoot\v1

CURRENT_BRANCH:
codex/v1-rtl-core

LAST_OBSERVED_HEAD:
31005c49b65349fb0aa26f27d728b70f6d83d3fd

PROBLEM_ID:
P-20261101-001
```

**用户已明确授权本轮在 v1 内继续开发，目标是完成 PCB 设计开始前所需的全部可执行数字工程和硬件接口设计输入。**

不创建 v2，不切换正式 Repository。

本轮允许你自主完成普通、可逆的工程决策、资料调查、缺陷修复、RTL 实现、候选接口定义、工具环境搭建、测试、仿真、综合、布局布线、时序收敛、报告整理以及正常 Commit/Push/PR 更新。

**遇到普通技术问题，不需要逐次询问用户。**

应先独立分析实际失败证据，再查询 AMD 官方文档、器件数据手册、GitHub、论文或其他可靠工程案例，选择合理方案，修改、测试并形成验证闭环。

如果一种方案失败，应保留日志并进行根因分析。允许比较和切换经过证明更合理的可逆实现方案。

连续 2–3 轮修复无实质进展时，应建立或更新 Problem、记录已尝试方案和证据，停止无效循环，继续推进其他独立任务。

**不要为了获得 PASS 而降低验收要求。**

无法自主解决的问题在最终运行结束时集中列出，包含原因、证据、影响及解决建议。

只有涉及用户保留审批的重大操作，才允许中断相关工作等待授权。其他互不依赖的工作应继续完成。

---

## 1. 本阶段最终目标

将 Timefoot v1 推进到：

`PCB_PRE_DESIGN_READY`

这一状态的定义是：

1. 核心 RTL 功能完整。
2. 完整节点数字时序接口已定义。
3. 节点接口 RTL 已实现并经过验证。
4. 严重 CDC/RDC 问题已解决。
5. 目标 FPGA 综合和实现通过。
6. 在具备明确假设和有效约束的数字接口 Profile 下，Setup/Hold Timing Closure 通过。
7. 多节点时间同步、预约执行和任务协作得到完整仿真验证。
8. 板间数据传输协议和数字适配层完整。
9. 时钟与同步硬件的接口、电气要求、候选引脚和器件选择依据清楚。
10. 已形成后续原理图与 PCB 工程所需的设计输入包。

最终仍不要求、也不允许声称已经完成真实 PCB 或板间物理精度验证。

本轮应尽量把所有不依赖真实 PCB 的技术问题一次性解决，减少下一阶段硬件设计的返工风险。

---

## 2. 开始前必须核对真实 Repository

首先读取并检查：

- Git Status、Branch、HEAD、Remote。
- README、AGENTS.md、guide.md。
- shared/PROJECT_STATE、VERSION_STATE、CONTEXT_CHECKPOINT、CURRENT_PLAN、DECISIONS、ACCEPTANCE、BLOCKERS。
- v1 当前源码、XDC、Testbench、Scripts。
- 最近的 RTL 源码 Commit 与对应报告。
- Vivado 实现结果、Clock Interaction、STA、CDC/RDC、DRC。
- 预研目录中的硬件调查与技术路线证据。
- Draft PR #1 及其最新状态。

重点核对：

```text
Validated RTL baseline:
46f88bcd553a13a9fda55b2599c6740acf6681d0

Previous delivery baseline:
a1633e1a18df87bcb74fb9464e46e006fa406cb4

Problem:
P-20261101-001

Problem SHA256 reported:
5772714a3368d27d87af9d6a90b287ad963927e7335c5a03f90778e6cb6596ba
```

这些都是历史核对参考，不应覆盖当前真实 HEAD。

如果 Problem 内容或 Hash 已发生变化，必须重新对账，不得直接将旧 Decision 应用于新问题。

预研历史证据保持不变，不删除历史失败文件。

工作区及生成物严格限制在：

`E:\Codex_project\Timefoot`

现有 `preproject_feasibility` 原始记录视为只读历史。

Windows 使用 PowerShell 7（pwsh）。

---

## 3. 已批准的架构决策

### Decision：P-20261101-001

**Decision Status：APPROVED_FOR_IMPLEMENTATION_WITH_VALIDATION**

保持 B 总体架构：

- 独立公共 50 MHz 参考时钟。
- 最多四路 CLOCK 分配。
- 最多四路 SYNC 分配。
- 四路节点独立使能。
- AX7020 作为可选管理设备。
- EBAZ4205 作为主要执行节点。
- 每节点本地 MMCM/PLL 派生业务频率。
- 全局时间基准、预约事件、控制和数据接口独立。

数字接口选择：

**保留现有 208-bit 逻辑帧接口，在 FPGA 节点外部增加明确的 Source-Synchronous TX/RX Adapter。**

内部核心不直接把 208-bit 数据总线、全部诊断信号和复杂握手关系映射到物理排针。

通过独立适配层完成：

- 数据帧打包和拆分。
- 可配置物理数据位宽。
- 转发时钟。
- TX/RX 输入输出寄存。
- 弹性缓冲。
- 流控与跨时钟域处理。
- 控制/状态信号边界。
- 复位和故障中止。

优先探索适合 EBAZ4205 DATA 接口的低位宽 SDR Source-Synchronous 模式，例如 4-bit/8-bit 数据宽度、独立转发时钟和流控信号。

其中 4-bit SDR、50 MHz 可作为首个候选链路 Profile，但并非预先认定它在真实板卡连接器上一定可用。

应按照现有 FPGA 引脚资源、接口电气条件、吞吐需求和 STA 结果选择最终推荐配置。

禁止为追求吞吐而无依据地使用高速串行链路或未经核实的 LVDS 管脚。

如果发现更优的数字接口结构，可独立比较并实施可逆优化，但不能改变已批准的整体同步架构和正式 Scope。

### 被拒绝的解决方式

以下方法不得作为时序通过的捷径：

- 直接删除失败端口。
- 把真实失败路径排除在 STA 外。
- 无依据放宽 Input/Output Delay。
- 使用宽泛 False Path 消除问题。
- 仅通过降频规避原有要求。
- 隐藏 Hold Violation。
- 只检查内部 WNS 而忽略外部路径。
- 以行为模型 PASS 替代可综合 RTL 验证。

历史完整节点负 STA 必须保留为对照基线。新增 Adapter Profile 应明确映射原有接口功能，不能通过更名或削减验收范围假装解决了历史失败。

---

## 4. P0：首先解决时序和 CDC 约束问题

### 4.1 核查 XPM Gray 指针约束

上一轮报告发现 XPM FIFO Gray Pointer 的有效约束出现：

```text
set_max_delay -datapath_only ... 1000.000
set_bus_skew ... 1000.000
```

而工作时钟周期为 6.667ns / 10ns 等。

必须调查：

1. 1000ns 来自哪里。
2. 是厂商 XPM 自动生成还是当前 XDC/脚本导致。
3. 是否存在读取时钟顺序问题。
4. 是否存在时钟关系识别错误。
5. 是否有宏参数配置不合理。
6. 是否覆盖了真正需要受限的 CDC 路径。
7. 是否存在被其他 Timing Exception 覆盖的约束。
8. 实际 Bus Skew 是否合理。
9. 正确约束应该根据哪个 Clock Period 或 CDC 协议确定。

结合 AMD UG903、UG949、UG906、XPM 文档及当前 Vivado 版本核查。

不能单纯把 1000ns 改为一个看起来合理的数字；必须证明约束值、路径端点、约束生效顺序和 CDC 结构之间的一致性。

完成后重新综合、实现及检查。

必须输出：

`v1/docs/XPM_CDC_CONSTRAINT_AUDIT.md`

并保存完整的约束证据。

### 4.2 关闭完整节点 STA

历史失败基线：

| Part | WNS | WHS |
|---|---:|---:|
| XC7Z010 | -1.255ns | -0.862ns |
| XC7Z020 | -0.684ns | -0.931ns |

现有内部路径与历史三路输出回归的通过，不代表完整接口满足要求。

针对 TX、RX、ready、valid、数据输出、诊断状态及复位路径分别分析。

重点研究：

- Source-Synchronous Clock Forwarding。
- ODDR/IOB 寄存器。
- RX Capture Clock。
- 发送与接收寄存时序。
- 弹性 Buffer。
- Registered Ready。
- Hold-Time Budget。
- Clock Skew。
- 不同 I/O 路径的 Min/Max Delay。
- 接口复位/flush 安全性。

必须建立真实数字接口契约，而不是为了得到正 WNS 随意改变测试假设。

约束应明确：

- 时钟来源。
- Launch/Capture Edge。
- External Setup/Hold 假设。
- Clock/Data Skew。
- 最小和最大输入输出延迟。
- 接口频率及传输模式。
- 允许的板级传播延迟预算。
- 适用的候选接收器类型。

实际连接器和 PCB 尚未确定的参数可以列为工程假设，但必须明确其可接受范围、可测量条件和未来需要确认的内容。

---

## 5. P1：完成 FPGA 节点物理接口数字适配层

建议新增或完善：

```text
tf_link_adapter
tf_link_tx
tf_link_rx
tf_link_clock_forward
tf_link_elastic_buffer
tf_link_flow_control
tf_link_status_bridge
tf_link_reset_controller
```

具体模块划分由 Codex 根据工程质量决定，不强制为了目录整齐而增加多余模块。

### 核心要求

**TX：**

- 完整帧序列化/低位宽映射。
- 数据与 Forwarded Clock 具有明确定义的时序关系。
- 数据和 Valid 在寄存边界上稳定。
- 支持接收端 Backpressure。
- 数据不能因 Stall 发生丢失或重复。
- Reset/Flush 不允许产生虚假的有效发送。

**RX：**

- 接收时钟与内部工作时钟分离管理。
- 数据接收后经过必要的缓冲和 CDC。
- 完成帧重组、CRC、序号、Session 检查。
- 非法包不得进入业务处理链路。
- 明确接收缓存容量和最大持续吞吐。

**控制与状态：**

- 将管理寄存器与数据 Link 分离。
- 不允许将高扇出组合状态直接输出为高速物理接口。
- 对多位状态采用快照或握手。
- 关键故障能够被外部控制器读取。
- 保证复位、重同步时状态一致。

### 维持既有数据契约

保持：

- 32-bit Session。
- 32-bit Sequence。
- 64-bit Source Timestamp。
- 16-bit Length。
- 参数化 Payload。
- CRC-32/BZIP2。
- 现有业务算法数值与时间戳语义。

如果引入新链路 Header、校验字段或控制字段，应通过明确协议版本/适配层处理，不得静默破坏现有业务帧格式。

对于物理 Link 层，可根据实际需要增加帧同步、错误检测和流控机制，但必须提供对应的接收端及测试。

不要求本阶段实现复杂网络协议或 White Rabbit。

---

## 6. P1：完善同步时间与任务执行逻辑

本轮继续完善：

### 统一 Epoch

- 明确未来 Epoch 准备和提交的时序。
- 检查默认 1024 Tick 提前量的真实起算点。
- 验证 Prepared、Apply、Marker、Verify 的状态优先级。
- 检查计数器比较逻辑的 Wrap 边界。
- Late-Join 节点不得在纪元未确认时执行同步任务。
- 失锁后重新建立 Session 与 Epoch。

### 物理事件数字边界

- 保证预约输出来自明确的参考时钟域。
- 支持同步状态不可信时禁止输出。
- 保留事件 ID、实际执行时间和错误统计。
- 控制端可以读取同步有效性及故障状态。
- 不用 `marker_qualified=1` 常量替代真实系统中的资格接口。

### 可配置节点

- 支持 1/2/3/4 节点。
- 未用节点不影响其他节点。
- 节点切换后重新建立有效 Session。
- 支持原有任务阶段显式映射。
- 不能默认移除节点后业务会自动迁移。

---

## 7. P1：系统级数据链路与任务闭环

以当前可综合业务链为基础：

```text
同步预约事件
    ↓
FPGA1：采集数据源
    ↓
TX/RX Link Adapter
    ↓
FPGA2：转换
    ↓
TX/RX Link Adapter
    ↓
FPGA3：处理
    ↓
TX/RX Link Adapter
    ↓
FPGA4：输出
```

必须验证整个数据流实际经过新的数字适配器，不允许 Testbench 直接绕开它。

要求：

1. 使用真实 RTL Timebase 生成时间戳。
2. 完整执行数据封装、发送、接收及重组。
3. 包含有效的 FIFO、CRC 和序号验证。
4. 验证有效/反压和缓存容量。
5. 验证业务输出与独立 Python Reference Model 一致。
6. 验证不同频率节点的跨域传输。
7. 验证同步任务的启动、暂停和恢复。
8. 验证多节点连续运行与故障恢复。
9. 测量数字链路吞吐、帧延迟、最大队列占用与饱和行为。
10. 对故障中止帧提供明确统计，不允许静默丢包。

对于不同吞吐配置，应区分原始 Link Bitrate、净载荷吞吐、业务算法吞吐和端到端任务延迟。

如果当前逐 bit CRC 或其他处理阶段成为吞吐瓶颈，应独立判断是否值得优化；不得仅为了增加性能而引入无法验证的大规模复杂架构。

---

## 8. P2：完成硬件接口设计输入

虽然本阶段不制作 PCB，但必须完成后续 PCB 设计需要的数字和电气接口定义。

### 8.1 时钟与 SYNC

保留：

- 公共 50MHz 参考。
- 四路可配置时钟输出。
- 四路 SYNC 输出。
- 独立失锁/状态接口。
- 各节点本地 MMCM 时钟派生。
- AX7020 可选管理。

研究并确认候选：

- 时钟源。
- 四路时钟 Buffer。
- SYNC 分配。
- 节点时钟接收。
- 接口 I/O 电平。
- 终端匹配。
- 时钟输入专用引脚。
- 线缆长度和延迟预算。
- 未使用端口的安全状态。

LMK00304 可以继续作为四路差分参考时钟分发候选，但应核对其 50MHz 输入模式、CLKin/OSCin 差别、供电、电平以及实际通道配置。

不要在没有器件数据手册依据的情况下冻结 BOM。

### 8.2 DATA 接口审查

以实际 EBAZ4205 和 AX7020 文档为基础，确定候选：

- Clock 输入引脚。
- SYNC 输入引脚。
- TX/RX 数据引脚。
- Forwarded Clock。
- Flow-Control。
- Fault/Status。
- GND/回流路径。
- Bank 电压。
- 接收端电平与驱动模式。

由 Codex 自主规划候选引脚。

必须输出明确的引脚分配表，包含：

```text
Board
Connector
Connector Pin
FPGA Package Pin
Bank
I/O Standard
Signal Direction
Signal Function
Shared/Reserved Status
Electrical Risk
Source Evidence
Verification Status
```

若发现引脚资源不足，可自主优化数据宽度、接口数量和逻辑复用，但不允许占用电源引脚或与板载输出驱动直接冲突。

不能通过 `CLOCK_DEDICATED_ROUTE FALSE` 掩盖不合理时钟接入。

任何缺失的原始板卡原理图必须通过可靠资料查找或标记 `UNVERIFIED`；不能仅凭网上相似矿板照片推断当前四块实物的电气属性。

### 8.3 候选硬件清单

完成预设计级 BOM：

- 时钟源。
- 时钟分配。
- SYNC 分配。
- 时钟接收器。
- 必要信号收发器。
- 连接器及线缆。
- 电源与保护。
- 测试接口和测试点。

每个主要器件需要：

- 型号和厂家。
- 选型理由。
- 核心电气参数。
- 与其他器件的兼容关系。
- 封装及装配要求。
- 是否能够采购。
- 替代器件。
- 已确认及未确认风险。

**只形成预设计输入和候选 BOM，不制作原理图、PCB、Gerber、装配文件或制造订单。**

---

## 9. 必须运行的验证矩阵

### 功能验证

保留并扩展既有测试：

- 5 项单元测试。
- 1–4 节点系统配置。
- 固定 Seed 1/17/2026。
- CRC、Session、Sequence、Timestamp。
- FIFO 满/空、Backpressure。
- 参考丢失和 MMCM 重新锁定。
- 节点重加入和新的 Epoch。
- 独立 Python Golden Model。
- 固定 Seed 重复性与 Trace Hash。

### 新增重点测试

1. TX Valid 在 Stall 时保持稳定。
2. Ready 注册后的 Buffer 容量正确。
3. Reset 与 Valid/Ready 握手同时发生。
4. 在途帧跨 Session 切换正确中止。
5. Forwarded Clock 与发送数据的时序关系。
6. RX 数据重组与 CRC。
7. 多时钟域随机相位测试。
8. SYNC 提前量、捕获窗口和边界条件。
9. 参考时钟失效下状态管理。
10. 连续多个 Session 重同步。
11. 不同链路宽度/频率下的资源与吞吐量。
12. 控制/状态访问期间发生故障。
13. FIFO Gray Pointer 约束和结构核查。
14. 包含新数字 Adapter 的完整多节点业务验证。
15. 对既有失败路径的新旧报告差异核对。

使用真实 RTL，而不是把完整链路替换成预先给出最终结果的 Mock。

如需抽象线缆延迟、接收器采样窗口或模拟故障，必须明确其模型边界。

### 综合与布局布线

目标：

```text
xc7z010clg400-1
xc7z020clg400-2
```

使用实际 Vivado 环境。

至少运行：

- Synthesis
- opt_design
- place_design
- phys_opt_design
- route_design
- report_timing_summary
- report_timing
- report_clock_interaction
- report_cdc
- report_drc
- report_methodology
- report_bus_skew（针对适用 CDC 路径）
- report_utilization
- check_timing

必须检查完整数字接口的：

- Setup
- Hold
- Pulse Width
- Input/Output Delay
- Clock Uncertainty
- Route Errors
- Timing Exceptions
- Unconstrained Paths
- CDC/RDC

如果采用 OOC，应另外构建具有完整时钟、TX/RX 和边界信号的集成时序验证 Top，并解释该 Profile 与原 node Top 的关系。

**不得仅凭 OOC 局部正 Slack 宣称完整节点已通过。**

---

## 10. Quality Gate 与验收条件

### P0 必须满足

- 真实有效的完整数字接口 Profile：WNS ≥ 0。
- WHS ≥ 0。
- Pulse Width 检查通过。
- 无未裁决的 Critical CDC/RDC。
- XPM Gray 1000ns 约束疑点获得证据支持的结论。
- 不出现新的关键内部 STA 失败。
- 无真正的未约束关键路径。
- 失败时不通过调整无依据的时序预算获得 PASS。
- 不出现历史已修复 Critical Bug 回归。

### P1 必须满足

- 1–4 节点功能正常。
- Epoch 和同步事件逻辑正确。
- 新 Link Adapter 完整进入业务数据路径。
- TX/RX、CRC、Session、Backpressure 正确。
- 故障中止及恢复无旧会话泄漏。
- 关键功能通过至少两种独立验证方式或提供适用的替代验证说明。
- 数据输出和算法结果能够复核。
- 测试可重复执行。

### PCB 前设计输入门禁

- 明确 CLOCK/SYNC/管理/数据接口的电气角色。
- 提供引脚资源与候选 Pin Mapping。
- 提供接收器及 Clock Buffer 的接口预算。
- 提供数据吞吐与时钟偏差预算。
- 提供候选器件清单及依据。
- 明确当前所有无法仅靠数字仿真确认的硬件条件。
- 对每项硬件假设给出未来验证方法。

任何电气未确认项目均不可标记为 `HARDWARE_VERIFIED`。

如果缺少原理图或实物资料而无法完成最终 Pin Mapping，可交付条件性候选，但不得声称板级安全已经签核。

---

## 11. 自主问题处理机制

执行过程中遵循：

**发现问题 → 收集日志 → 定位根因 → 检索可靠资料 → 比较方案 → 实施修复 → 重新测试 → 回归验证 → 记录证据。**

优先搜索：

- AMD 官方技术文档。
- Xilinx 7 Series Clocking/SelectIO。
- UG903/UG906/UG949。
- XPM FIFO / CDC 使用方法。
- TI、Microchip 等器件手册。
- GitHub 真实开源工程。
- 与本项目相关的论文及实测工程案例。

不同资料存在冲突时，以实际芯片型号、器件数据手册、真实工具行为及可复现实验为优先。

普通 Bug 可以自主修复。

如果发生核心架构冲突、正式 Scope 改变、关键验收指标需要调整或者连续修复无进展，建立 Problem，并保留全部证据。

无需就一般模块划分、可逆优化、数字接口候选引脚或工具脚本改动询问用户。

但不得擅自改变：

- B 总体时钟架构。
- v1 正式版本。
- 原有基本功能目标。
- 用户批准的 Repository。
- 严格同步与数据正确性的核心验收标准。

---

## 12. 工程记录和 GitHub

继续在现有 v1 开发分支和 Draft PR 上工作，先核对真实状态。

根据需要更新：

```text
v1/guide.md
shared/PROJECT_STATE.md
shared/VERSION_STATE.md
shared/CONTEXT_CHECKPOINT.md
shared/CURRENT_PLAN.md
shared/DECISIONS.md
shared/ACCEPTANCE.md
shared/BLOCKERS.md
AI-problem/problem/
AI-problem/decision/
```

对于 `P-20261101-001`：

本指令批准的技术方向是使用具有真实时序契约的数字适配器解决接口问题。Codex 应核对 Problem ID、SHA256、适用版本及源码基线，再将该决策与用户授权来源记录到正式 Decision 文件。

如果 Problem 发生实质变化，应进行重新验证，而不是直接沿用旧结论。

持续维护 Guide 和 Checkpoint。上下文切换后先核对真实仓库状态，不得只依赖聊天记忆。

所有结果 Commit、Push 并更新现有 Draft PR。

禁止 Merge、Force Push、删除重要历史、创建 v2 或正式发布。

---

## 13. 最终必须交付的 PCB 前准备包

在以下目录建立交付：

`E:\Codex_project\Timefoot\v1\docs\pre_pcb_readiness`

至少包含：

```text
PRE_PCB_READINESS_REPORT.md
SYSTEM_ARCHITECTURE.md
MODULE_INTERFACE_SPEC.md
CLOCK_AND_SYNC_SPEC.md
LINK_PROTOCOL_SPEC.md
TIMING_CONSTRAINT_SPEC.md
PIN_MAPPING_CANDIDATE.md
HARDWARE_INTERFACE_REQUIREMENTS.md
COMPONENT_SELECTION_AND_BOM.md
THROUGHPUT_LATENCY_BUDGET.md
CLOCK_ERROR_BUDGET.md
VALIDATION_AND_REPRODUCTION.md
OPEN_ISSUES_AND_RISKS.md
GPT_CHAT_FINAL_REVIEW.md
```

其中：

### PRE_PCB_READINESS_REPORT.md

说明是否已经达到 PCB 前准备状态，哪些内容完成，哪些需要硬件确认。

### TIMING_CONSTRAINT_SPEC.md

必须明确完整数字接口 Profile、时钟采样关系、Min/Max Delay、XPM 约束核查和实际 STA 结果。

### PIN_MAPPING_CANDIDATE.md

必须列出所有候选外部信号、Bank、FPGA Pin、接口 Pin、信号方向与电压条件。

### COMPONENT_SELECTION_AND_BOM.md

列出可能需要的时钟、SYNC、接收、缓冲、电源及连接模块，不进行采购。

### VALIDATION_AND_REPRODUCTION.md

包含工具版本、命令、测试输入、Seed、Hash、STA/CDC/DRC 结果、原始证据路径。

### OPEN_ISSUES_AND_RISKS.md

仅保留真正未解决的问题和条件性风险，不因暂时无法进行实板测量就虚构验证成功。

---

## 14. 运行结束时集中上报

不要在中途因普通技术疑问反复向我请求选择。

所有可自主处理的普通问题应先搜索资料、实施修复并验证。

最终回复必须采用以下结构：

```text
PROJECT_ID: TIMEFOOT
ACTIVE_VERSION: v1
STAGE: INTERFACE_TIMING_CLOSURE_AND_PRE_PCB_READINESS

BRANCH:
COMMIT:
PR:

1. 实际完成模块
2. 完整系统功能验证
3. Z010 / Z020 综合与STA
4. CDC / RDC / XPM 约束审查
5. 数字链路和接口定义
6. 候选引脚与器件选择
7. 时间同步和长期稳定性模型
8. 可复现性与证据
9. 剩余 Blocking / Critical / Known Limitations
10. PCB前准备状态
11. GPT-chat 独立Review所需文件
```

对于实在不能解决的问题，逐项提供：

```text
Issue ID
Severity
Root Cause / Current Hypothesis
Attempts Made
Evidence
Why Not Resolved
Affected Modules
Impact on Acceptance
Recommended Next Action
Whether User Approval Is Required
```

**最终工程状态只允许按证据报告：**

- `PCB_PRE_DESIGN_READY`
- `PCB_PRE_DESIGN_READY_WITH_LIMITATIONS`
- `REVISE`
- `BLOCKED`

如果数字核心已闭合，但仍缺少真实硬件电气信息，只能报告有限的 PCB 前准备状态，并列明相应条件。

不得把 PCB 前准备就绪解释为已获 PCB 设计、制造或实物连接授权。

---

## 15. 停止条件

当下列条件满足时结束本阶段，不继续进行无收益的优化：

1. 当前完整节点数字接口 STA 问题已解决。
2. 关键 CDC/RDC 及 XPM 约束问题已得到合理关闭。
3. 1–4 节点同步与业务功能完成回归。
4. 新 Source-Synchronous Adapter 已完成综合与仿真验证。
5. 主要数字业务链路形成真实闭环。
6. 硬件设计输入资料足够支撑下一阶段原理图设计决策。
7. 重要 Known Limitations 已明确列出。
8. GitHub、文档与真实证据状态一致。
9. 核心测试可复现。
10. 不存在可以自主解决却尚未处理的 Blocking 问题。

如果遇到暂时不能解决的问题，应保存当前最佳工程状态并集中报告，不得无限重复测试或修改。

本轮不执行任何 PCB、原理图或实物硬件操作。

**立即按照以上授权自主推进 TIMEFOOT v1，目标是把工程完成到 PCB 设计前的最后一个可验证数字阶段。**

完成后将整个结果交给 ChatGPT 进行独立 Quality Gate，由用户决定是否允许进入硬件原理图和 PCB 阶段。