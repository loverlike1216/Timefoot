# TIMEFOOT — Codex v1 正式开发指令

## 0. 项目身份与授权

你是 TIMEFOOT 项目的工程实施 Agent（Codex）。

用户已经正式批准启动 v1。本次任务是在已有预研成果基础上，完成多 FPGA 时序同步系统的 RTL 核心、通用系统框架及完整数字验证。

```text
PROJECT_ID: TIMEFOOT
PROJECT_NAME: Timefoot
PROJECT_STATUS: PROJECT_ACTIVE
ACTIVE_VERSION: v1
STAGE: RTL_CORE_AND_SYSTEM_FRAMEWORK

REPOSITORY:
https://github.com/loverlike1216/Timefoot.git

PROJECT_ROOT:
E:\Codex_project\Timefoot

VERSION_ROOT:
E:\Codex_project\Timefoot\v1

PREPROJECT_EVIDENCE:
E:\Codex_project\Timefoot\preproject_feasibility

PLATFORM:
Windows / PowerShell 7 / Vivado
```

**本轮已授权：**

- RTL 开发与系统框架搭建
- 自主定义模块接口和候选 XDC 约束
- Testbench、Reference Model 和自动化验证
- Vivado 仿真、综合、布局布线及 STA
- CDC/RDC 分析及缺陷修复
- 合理的工具环境配置
- Git Commit、Push、创建或更新 PR
- 工程文档、状态及证据维护

**本轮未授权：**

- PCB、原理图及正式硬件制造设计
- 器件采购、开发板接线或实物改造
- 新建 v2 或其他正式版本
- 更换 Repository
- Force Push、删除 Git 历史及不可逆重构
- 正式发布与部署
- 未经批准的 Merge

所有工程实施与新生成文件必须限制在 PROJECT_ROOT 内。预研目录保留历史证据，不覆盖原始数据。

---

## 1. 开工前核对真实工程状态

首先核对：

1. GitHub Repository、默认分支、HEAD Commit 和工作区 Git Status。
2. 当前仓库已有文件、目录及项目状态。
3. PROJECT_ROOT 与 VERSION_ROOT 是否正确。
4. 现有 `preproject_feasibility` 目录及历史证据是否完整。
5. 预研 RTL、测试脚本、Vivado 报告与实际源码 Hash。
6. 实际已安装工具及版本。

重点阅读：

- `guide.md`
- `SIMULATION_REPORT.md`
- `decision/GPT_CHAT_DECISION_PACKAGE.md`
- `decision/ARCHITECTURE_COMPARISON.md`
- `decision/RISK_REGISTER.md`
- `decision/BLOCKERS.md`
- `research/BOARD_FACTS_AND_PIN_AUDIT.md`
- `evidence/EVIDENCE_INDEX.md`
- 原始 RTL、Testbench、综合/时序/CDC 报告

以真实代码与工具证据为准，不得仅依据预研报告中的 PASS 声明接受已有实现。

发现缺失、Hash 冲突或报告与代码不一致时，先记录并解决。

完成对账后建立 v1 正式工程，保留预研历史，不直接把整个预研目录复制为最终产品。

---

## 2. 总体技术架构

采用已经批准的 B 路线：

**独立公共参考时钟架构 + 参数化多 FPGA 同步 RTL + AX7020 可选管理。**

目标平台：

- EBAZ4205（XC7Z010）作为主要执行节点。
- AX7020（XC7Z020）作为可选系统管理主控。
- 固定支持最多四路节点。
- 实际配置允许启用 1、2、3、4 个节点。
- 统一参考时钟暂定 50 MHz。
- 每个节点允许通过 MMCM/PLL 派生不同内部工作频率。

典型节点工作频率：

| 节点 | 工作任务 | 示例频率 |
|---|---|---|
| FPGA1 | 采集 | 50 MHz |
| FPGA2 | 转换 | 100 MHz |
| FPGA3 | 处理 | 150 MHz |
| FPGA4 | 输出 | 50 MHz |

这些频率只是默认验证配置，必须保持参数化。

AX7020 不得成为同步核心的强制依赖。

无 AX7020 时，应有明确的同步控制接口和主节点/控制器替代机制，允许系统完成启动、时间纪元分配、同步恢复与基本任务执行。

系统应严格区分：

- 参考时钟域
- 派生工作时钟域
- 逻辑时间同步
- 物理输出同步
- 数据传输域
- 控制管理域

不得因为不同工作时钟同源，就忽略 CDC、相位和接口时序约束。

---

## 3. 核心 RTL 功能开发

### 3.1 时钟管理

设计 `tf_clock_manager`。

要求：

- 支持 50 MHz 外部参考时钟。
- 通过 FPGA MMCM/PLL 产生参数化工作时钟。
- 检查实际 FPGA 时钟资源限制。
- 实现 PLL/MMCM Lock 状态管理。
- 参考时钟失效时进入安全状态。
- 失锁或重新锁定后不得直接恢复旧时间纪元。
- 支持独立参考监测机制的数字接口。

允许自主选择 AMD XPM、Clocking Wizard 或经验证的时钟原语，但必须保留可复用的外层接口。

### 3.2 全局统一时间基准

设计 `tf_timebase`。

要求：

- 64bit 全局逻辑时间计数器。
- 默认 50 MHz、20ns 粗时间分辨率。
- 所有启用节点使用统一 Epoch。
- 支持未来时间纪元同步。
- 避免不同节点在 SYNC 捕获边界产生整周期错位。
- 支持节点启动、退出、重加入。
- 提供时间有效性和同步状态信号。
- 不允许正常运行时逻辑时间意外回跳。

重点解决预研报告中已发现的 SYNC 整周期误差问题。

### 3.3 确定性事件调度

设计 `tf_event_scheduler`。

统一事件接口至少包含：

```text
event_id
session_id
target_timestamp
event_valid
event_ready
event_execute
event_done
event_error
```

要求：

- 支持未来指定时间执行。
- 支持多事件队列。
- 支持事件取消及故障中止。
- 迟到事件必须有明确处理策略。
- 故障期间不得错误执行旧会话事件。
- 实现可验证的预约时间执行机制。

事件最终物理输出应定义明确的参考域执行边界，不得直接用不同工作域的任意组合逻辑输出冒充同步事件。

### 3.4 同步控制协议

设计 `tf_sync_controller`。

至少包含以下状态：

```text
RESET
WAIT_REFERENCE
CLOCK_LOCK
NODE_DISCOVERY
EPOCH_ALIGN
SYNC_VERIFY
READY
RUNNING
FAULT
RECOVERY
```

要求：

- 统一启动。
- 节点上线与退出管理。
- 节点使能 Mask。
- 会话 ID 与时间纪元管理。
- 同步状态检测。
- 失锁后重新同步。
- 重复复位及恢复。
- 节点数量变化后的状态一致性。

不得简单使用所有节点计数器清零作为完整同步协议。

### 3.5 跨时钟域通信

设计 `tf_cdc_bridge` 和 `tf_async_fifo`。

要求：

- 单 bit 状态采用适当同步结构。
- 多 bit 数据采用握手或异步 FIFO。
- FIFO 指针与复位释放符合 CDC/RDC 设计要求。
- 处理 FIFO 满、空、反压、重置和异常。
- 业务时钟与参考时钟之间不存在未经审查的路径。
- 所有异步时钟关系通过正确约束声明。

必须修复预研中的 9 条 Critical CDC，禁止未经论证直接 Waive。

### 3.6 分布式数据互连框架

设计 `tf_stream_link`。

统一逻辑数据接口至少包含：

```text
session_id
sequence_id
source_timestamp
payload
length
crc
valid
ready
error
```

要求：

- 支持不同频率节点之间的数据流处理。
- 支持 FIFO 缓存和 Backpressure。
- 支持流控、数据序号、帧完整性校验。
- 支持故障后的会话清理。
- 明确是否允许丢帧及其记录规则。
- 对持续吞吐、最大突发和处理延迟建立预算。

本阶段实现可综合的数字协议核心与链路适配接口。

尚未指定物理 PHY 时，必须将物理传输层独立出来，使用清楚标记的仿真链路模型验证，不得将其声称为真实电缆传输已经通过。

### 3.7 系统管理接口

设计 `tf_control_interface`。

要求：

- 模块不强制依赖 AX7020。
- 定义通用寄存器映射。
- 支持节点使能、复位、同步启动、事件提交和状态读取。
- 支持错误码、统计计数器与同步状态输出。
- 优先采用清晰、可扩展的控制接口。
- 可以使用 AXI4-Lite 适配层，但核心逻辑不应绑定某一具体 PS 设计。

---

## 4. 统一模块接口和约束

由 Codex 自主确定 RTL 接口规范、参数、寄存器映射和目录结构。

设计应满足：

1. 固定最大四节点，运行时配置有效节点数量。
2. 每节点使用相同的同步 RTL Core。
3. 节点 ID、工作频率、数据宽度、FIFO 深度均参数化。
4. 同步控制与业务算法分离。
5. 参考时钟、SYNC、控制、数据、状态接口分离。
6. 可以替换 FPGA 板卡适配层，而不修改核心同步协议。
7. 支持独立综合节点 Core 与完整多节点仿真 Top。

XDC 分为：

- 公共时钟约束
- 派生时钟约束
- CDC/异步关系约束
- 节点内部时序约束
- 外部接口时序预算
- 板卡 Pin Mapping 候选约束

用户本轮授权你自主定义接口，不需要反复确认引脚选择。

但所有未经实物验证的 XDC 必须标记为 `CANDIDATE_PIN_MAPPING`，不得声称最终板级安全。

不得将已连接板载晶振输出的引脚与另一个外部时钟源直接并接。

---

## 5. 必须修复的历史缺陷

上一轮预研已发现：

- 两种目标 Part 各有 9 条 Critical CDC。
- Z010 管脚 Top：WNS -0.673ns。
- Z020 管脚 Top：WNS -0.304ns。
- SYNC 捕获可能出现整周期 Epoch 偏差。
- Late Join 尚无完整纪元对齐保证。
- 物理精细校准只有数学模型。
- 数据传输仍使用抽象数字链路。
- 异常恢复与局部 FIFO Reset 协议尚未完善。

本轮必须建立缺陷追踪记录。

优先解决影响数字系统正确性的 CDC、RDC、复位、事件调度和接口时序问题。

对先前负 WNS 路径，分析真实结构和失败原因，重新定义有效的输出时序契约，进行结构性修复和约束验证。

不得简单删除失败端口、放宽输出延迟或增加不合理的 False Path 来获得 PASS。

若外部接收器参数尚未确定，应明确区分内部真实 STA 闭合与基于假设的外部接口预算，保留未关闭的板级时序风险。

---

## 6. 系统级完整功能闭环

构建四节点数字系统示例：

```text
Data Source
    |
    v
FPGA1 -- Acquisition
    |
    v
FPGA2 -- Conversion
    |
    v
FPGA3 -- Processing
    |
    v
FPGA4 -- Output / Feedback
```

这一示例必须：

- 使用实际 RTL 数据处理路径。
- 从统一预约事件开始采集。
- 携带真实 RTL Timebase 时间戳。
- 穿过各节点 FIFO、握手和数据处理模块。
- 最终输出结果与独立 Reference Model 一致。
- 具有反压、故障和恢复测试。
- 记录数据吞吐、队列深度、端到端延迟。

不得使用直接硬编码最终输出、跳过主要数据链路或纯 Testbench 拼接结果的方式制造系统完成假象。

要求节点数量与业务阶段映射相互独立。

2 节点系统可以让一个节点承担多个阶段，但不能假设禁用任意节点后，四级任务会自动重新映射。

---

## 7. 测试与仿真要求

使用 Vivado/XSIM 作为目标器件主要验证工具。

有条件时增加 Verilator 或其他独立工具链进行交叉检查。

至少验证：

1. 1、2、3、4 节点配置。
2. 50 MHz 公共参考时钟。
3. 50/100/150 MHz 多频率工作。
4. 多节点统一 Epoch。
5. 预约事件执行与跨板输出时间对齐逻辑。
6. SYNC 延迟及捕获边界。
7. 节点晚启动、重新加入、复位。
8. PLL/MMCM Lock 丢失与恢复。
9. 参考时钟失效及独立监测。
10. 数据 FIFO 满/空、Backpressure。
11. 高吞吐、突发和饱和条件。
12. 数据顺序、时间戳、CRC 和会话一致性。
13. 故障中止、恢复及旧数据隔离。
14. 时间计数器边界。
15. 多次重复同步。
16. 固定 Seed 与重复执行结果一致性。

对于长期漂移：

- 使用数学分析和经过验证的加速模型。
- 明确区分公共时钟同源频偏与路径固定偏差。
- 不需要机械运行 24 小时逐周期 RTL 仿真。
- 不得将数学等效模拟称为真实 24 小时硬件测试。

每项测试保存：

- 配置参数
- 输入数据与 Seed
- 自动化运行命令
- PASS/FAIL 判据
- 原始日志
- 关键波形或 Trace
- 输出 Hash
- 对应 RTL Commit

---

## 8. 综合、实现与 Quality Gate

目标 Part：

- EBAZ4205：`xc7z010clg400-1`
- AX7020：`xc7z020clg400-2` 作为手册候选；正式以实际板卡 Part 核实结果为准。

必须完成：

- Synthesis
- Opt / Place / Route
- Static Timing Analysis
- CDC/RDC Review
- DRC
- Clock Interaction Analysis
- Resource Utilization
- Constraint Coverage
- Critical Path Analysis

对关键模块分别执行单元级和系统级验证。

Quality Gate：

- Blocking Bug = 0
- Critical Bug = 0
- 无未解释的关键 CDC/RDC
- 核心功能全部通过
- 有效内部时序约束满足
- 不允许用宽泛约束豁免掩盖失败
- 关键验证可重复执行
- 所有核心处理路径真实存在
- 失败记录和 Known Limitations 完整保留

如果目标板级 I/O 时序尚不具备完整物理条件，不得强行宣称最终 STA 已闭合，应明确标注限制。

无法满足以上门禁时，正常保留已有开发成果并提交 REVISE，不要反复进行低收益优化。

---

## 9. 工程目录与状态维护

正式工程建议结构：

```text
Timefoot/
├── README.md
├── AGENTS.md
├── shared/
│   ├── PROJECT_STATE.md
│   ├── VERSION_STATE.md
│   ├── CONTEXT_CHECKPOINT.md
│   ├── CURRENT_PLAN.md
│   ├── DECISIONS.md
│   ├── ACCEPTANCE.md
│   └── BLOCKERS.md
├── preproject_feasibility/
│   └── [历史预研，只读]
└── v1/
    ├── guide.md
    ├── rtl/
    │   ├── clock/
    │   ├── sync/
    │   ├── timebase/
    │   ├── scheduler/
    │   ├── cdc/
    │   ├── stream/
    │   ├── control/
    │   └── top/
    ├── interfaces/
    ├── constraints/
    ├── tb/
    ├── reference_model/
    ├── scripts/
    ├── verification/
    ├── reports/
    ├── docs/
    └── work/
```

目录可以根据实际工具和工程依赖做小幅优化，但不能改变版本管理、历史证据保留和写入边界。

所有 Vivado 缓存、输出文件、仿真中间文件和 Python 环境应保持在指定工程内部。

维护：

- 当前架构
- 模块接口
- 当前 Stage
- 最新 Commit
- 已完成验证
- Failed Cases
- 当前 Blockers
- Decision History
- Next Actions
- 不得更改的约束

在重大 Stage 完成、上下文明显增长、模型/线程切换或暂停前更新 guide.md 和 CONTEXT_CHECKPOINT。

不得在未取得实际工具证据时伪造工程状态。

---

## 10. GitHub 工作方式

以用户指定 Repository 为唯一正式远程仓库。

先核对实际 `main` 状态，再选择合理的开发分支。

正常开发中可以：

- Commit
- Push
- 创建或更新 PR
- 运行已配置的 CI
- 修复普通 Bug
- 更新工程文档和证据

不得擅自：

- Merge PR
- Force Push
- 改写 Git History
- 删除重要历史
- 创建 v2
- 修改正式 Scope
- 发布正式版本

重大架构变更或连续多轮无法解决的问题，应建立 Problem 文件，附真实代码、日志、失败原因、候选方案及验收影响，再向 ChatGPT 提交重大 Decision 请求。

---

## 11. 当前 Stage 的完成条件

本轮任务完成时，应满足：

1. 正式 v1 RTL 目录及完整基础工程建立。
2. 可综合的参数化同步核心完成。
3. 1–4 节点配置通过验证。
4. 不同频率节点能在统一时间基准下协作。
5. 预约事件及统一 Epoch 机制完成。
6. 关键 CDC/RDC 缺陷已关闭或明确报告阻塞。
7. 数字数据处理闭环完整通过。
8. 故障检测和基本恢复机制完成。
9. 目标 FPGA 综合、实现及有效 STA 验证完成。
10. 测试日志、波形、报告、Hash 与复现命令完整。
11. GitHub 工程状态真实同步。
12. 无无意义 Placeholder、虚假 PASS 和未经说明的关键模拟替代。
13. 已准备 ChatGPT 独立 Review 所需材料。

如果某项无法完成，记录真实原因和必要的下一步，不得降低验收标准。

## 12. 最终交付给 ChatGPT

在当前 Stage 结束时，生成：

`v1/docs/GPT_CHAT_STAGE_REVIEW.md`

内容包括：

```text
PROJECT_ID
REPOSITORY
PROJECT_ROOT
BRANCH
COMMIT
ACTIVE_VERSION
STAGE

Architecture Implemented
Modules Completed
Interfaces Defined
Validation Matrix
Simulation Results
Synthesis Results
Timing Results
CDC/RDC Results
Resource Utilization
Reproducibility Evidence
Critical Bugs
Open Blockers
Known Limitations
Hardware Validation Required
Next Recommended Stage
Codex Self-Assessment
```

同时提供：

- 真实源码路径
- GitHub Commit / PR
- 可重跑的构建和测试命令
- 关键报告与证据路径
- 所有未关闭的 Blocking Issue
- 与上一轮预研结果的变化对照

明确区分：

`IMPLEMENTED / TESTED / SIMULATED / SYNTHESIZED / NOT_HARDWARE_VERIFIED`

最终由 ChatGPT 独立作出：

`ACCEPT / ACCEPT WITH LIMITATIONS / REVISE`

不得由 Codex 自行宣布整个 Timefoot 项目最终验收通过。

---

**立即开始 TIMEFOOT v1 当前 Stage 的实施。**

优先完成 Repository 状态对账、预研资产核验和历史 CDC/STA 问题审查，然后继续 RTL 核心开发、通用系统框架搭建和自动化验证。

在已经批准的范围内自主推进普通可逆技术工作，不因可自行解决的小问题中断任务。

本阶段的目标是交付**结构完整、数字功能真实、综合与时序证据可信、能够继续推进真实硬件验证的多 FPGA 同步 RTL 系统基础**，不涉及 PCB 和实际硬件改造。