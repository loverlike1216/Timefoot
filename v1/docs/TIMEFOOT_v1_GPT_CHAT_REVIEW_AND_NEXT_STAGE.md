---
document_type: GPT_CHAT_SINGLE_FILE_REVIEW_HANDOFF
project_id: TIMEFOOT
active_version: v1
current_stage: RTL_CORE_AND_SYSTEM_FRAMEWORK
prepared_by: Codex
prepared_at: 2026-11-01
independent_review_status: PENDING
codex_stage_recommendation: REVISE
source_delivery_commit: a1633e1a18df87bcb74fb9464e46e006fa406cb4
validated_rtl_commit: 46f88bcd553a13a9fda55b2599c6740acf6681d0
problem_id: P-20261101-001
---

# TIMEFOOT v1：GPT-chat 审查说明、阻塞问题与下一阶段预期

> **交给 GPT-chat 的使用说明：**请把本文件作为一次独立工程审查的输入。先核对已完成事实、证据范围与失败项，再判断当前阶段质量，并给出保持在 v1 内的下一阶段建议和可交给 Codex 的执行指令。不要把 Codex 的自检结论当成独立审查结论。本文不包含已经发生的 GPT-chat Review 或批准。
>
> **当前事实：**正式 RTL 和数字系统框架已实现；功能仿真、内部寄存器路径 STA、历史三路输出回归已有通过证据；**完整节点 OOC 外部接口 setup/hold 仍失败，当前阶段建议为 REVISE**。下一阶段预期聚焦数字接口与时序闭合，不涉及 PCB、实际接线、采购或部署。

## 1. 本次希望 GPT-chat 回答什么

请优先形成以下四项输出：

1. **独立审查结论：**在现有验收标准下，选择 `ACCEPT / ACCEPT WITH LIMITATIONS / REVISE`，逐项解释证据。若现有完整节点 STA 必须通过而仍失败，不应把该门禁改写为“有条件通过”。
2. **阻塞项判断：**确认 B-TF-001 的性质、范围和优先级；评估下文待审风险是否需要新增为阻塞项。
3. **技术路线决策：**选择能够建立有效时序契约的数字适配器路线，明确 TX/RX 时钟、反压、控制/状态、复位和输出时序的关系。
4. **下一阶段 Codex 指令：**给出目标、范围、允许修改、保护边界、实施顺序、必须执行的测试及完成判据。继续使用 v1；不直接转入实物阶段。

本文已包含开展事实审查和路线比较所需的主要信息。做代码级和根因级结论时，仍应核验第 11 节引用的源码及原始报告。若无法访问证据，标记 `EVIDENCE_ACCESS_BLOCKED` 或“仅基于本文件的条件性意见”，说明哪些结论尚不能作出；不要声称已读过未访问的文件。

## 2. 唯一项目身份、当前状态与授权

| 字段 | 已确认内容 |
|---|---|
| PROJECT_ID | `TIMEFOOT` |
| Repository | [loverlike1216/Timefoot](https://github.com/loverlike1216/Timefoot) |
| PROJECT_ROOT | `E:\Codex_project\Timefoot` |
| VERSION_ROOT | `E:\Codex_project\Timefoot\v1` |
| 当前版本 | `v1 / ACTIVE`；没有批准 v2 |
| 当前阶段 | `RTL_CORE_AND_SYSTEM_FRAMEWORK` |
| 开发分支 | `codex/v1-rtl-core` |
| 本文件整理前的交付 HEAD | `a1633e1a18df87bcb74fb9464e46e006fa406cb4` |
| 主要 RTL 验证基线 | `46f88bcd553a13a9fda55b2599c6740acf6681d0` |
| 首轮完整证据交付 | `9071b564387a8c67d88dadb61007e34502136a74` |
| 独立远端 checkout 复现基线 | `03eeddcd0520b110649c226245989eba04a21b77` |
| PR | [Draft PR #1](https://github.com/loverlike1216/Timefoot/pull/1)；本次核对为 OPEN / DRAFT，`mergedAt=null` |
| main | 本次核对仍为 `1c39215f98494ba152c5cdf77312af485fe1ae01` |
| CI | PR 本次查询未返回状态检查运行；不能声明 GitHub CI 通过 |
| 独立 GPT-chat Review | 尚未收到；没有伪造 Decision 文件 |

本文件中的 Commit 是整理时核对的固定快照。本文件自身的文档提交不属于上述已执行 RTL 验证的一部分；之后应以实际 PR head 查看最新交付元数据，不把文档更新误认成重新实现或重新测试。

用户已授权：当前 v1 范围内的 RTL、数字接口、候选 XDC、仿真/综合/实现/STA、CDC/RDC 审查、环境配置、证据整理，以及正常开发分支 Commit、Push、PR 更新。普通可逆技术细节由 Codex 自主闭环。

用户仍保留：版本升级、正式 Scope/验收标准变化、Merge、force push、重要历史删除、PCB/原理图/硬件制造设计、接线改造、采购、发布与部署等权限。GPT-chat 的技术建议不能替代这些用户授权。

## 3. 已实现系统及关键契约

### 3.1 总体架构与模块

采用已批准的 **B 路线：公共 50 MHz 参考 + 参数化多 FPGA 同步 RTL + AX7020 可选管理**。

- 相同节点核心支持 1–4 节点逻辑装配；默认工作频率为 50 / 100 / 150 / 50 MHz。
- 每个执行节点独立使用 MMCM 派生业务时钟；50 MHz 输入、900 MHz VCO，输出分频 18 / 9 / 6 对应 50 / 100 / 150 MHz。
- 通用管理接口不绑定某个 PS 或 AX7020 工程。没有 AX7020 时，仍可通过管理逻辑执行启动、配置、预约和恢复。
- `tf_system_top` 表达多个 FPGA 的逻辑系统；没有把四个 FPGA 的 MMCM 和管脚资源当成一片 Z010 的已实现设计。

| 模块组 | 已实现职责 |
|---|---|
| `tf_clock_manager` | 时钟派生、Lock 状态、独立监测时钟下的参考心跳检测、参考恢复后的 MMCM 复位/重新锁定 |
| `tf_timebase` | 64 位参考域时间、32 位会话、Epoch 预装载、有效性与同步错误 |
| `tf_event_scheduler` | 深度 8 的有序未来事件队列、取消/中止、会话/重复/迟到等检查、参考域执行脉冲 |
| `tf_sync_controller` | RESET 至 RUNNING、FAULT、RECOVERY 的同步状态机与统一会话管理 |
| `tf_cdc_bridge`、`tf_async_fifo`、同步器 | 多位配置/数据一致性传输、单 bit 状态同步、复位释放和流控 |
| `tf_crc_engine`、`tf_stream_tx`、`tf_stream_link` | 实际 CRC 生成/校验、序号/长度/会话检查、接收缓存与反压 |
| `tf_data_source`、`tf_task_pipeline` | 合成输入、真实 RTL 时间戳捕获、可综合运算流水线 |
| `tf_control_interface`、node/system top | 通用寄存器、节点状态/控制和完整逻辑装配 |

### 3.2 时间同步及故障恢复

控制器先分配会话和未来 Epoch，节点接收配置并反馈 prepared；参考时钟下降沿发出 marker，节点在满足契约的同一个后续参考上升沿装载 Epoch，再反馈 applied。控制器验证后才进入 RUN。

**准确的提前量表述：**源码在 NODE_DISCOVERY 中设置 `apply_at = ticks + LEAD_TICKS`，默认 `LEAD_TICKS=1024`，即名义上约 20.48 µs 后发 marker。准备/确认消耗其中一部分时间。不能写成“ACK 完成后还保证至少提前 1024 tick”。未准备完成时，源码还检查接近 `apply_at-8` 的条件；其分支优先级和实际安全余量应纳入审查。

`marker_qualified` 是数字适配器/校准环节必须提供的资格输入，**现有 RTL 不测量物理相位，不自动判断电缆偏斜**。资格低会阻止准备、使时间无效并记录协议错误。

数字边界测试采用至少 1 ns setup 的示例契约，测试 marker 延迟 0.2 / 8.5 / 9.5 / 10.5 ns 的接受或拒绝。系统仿真中参考偏移为 0 / 0.6 / 1.2 / 1.8 ns，marker 路径延迟为 2 / 2.7 / 3.4 / 4.1 ns。这些是模型输入，不是实物测量。

节点数量变化、参考丢失或局部复位采用：中止旧会话 → 清理队列/链路 → 新会话与新 Epoch → 重新准备/验证 → RUN。参考恢复后不直接恢复旧任务。独立监测使用慢速心跳和默认 96 个 monitor tick 的 watchdog；实际故障响应还包含同步器、状态机和复位传播延迟，尚不能由某一次测试推导为已证明的最坏响应上界。

### 3.3 数据链路、处理、吞吐边界

当前测试配置：`PAYLOAD_W=32`、`FIFO_DEPTH=16`、每次系统测试突发 40 帧；源模块默认突发参数为 64。其余数据宽度、深度和分频组合没有获得整个参数空间的统一 PASS。

包格式从高位到低位：

```text
session32 | sequence32 | source_timestamp64 | length16 | payloadW | crc32
W=32 时：body=176 bit，完整逻辑帧=208 bit（26 byte）
```

CRC 为非反射 CRC-32/BZIP2，poly=`04C11DB7`，init/final XOR=`FFFFFFFF`，校验向量 `123456789 -> FC891918`。每个新会话从 sequence 0 开始。CRC、会话、序号或长度错误采用显式报错、中止与新会话恢复，没有实现自动重传协议。

实际 RTL 处理路径：

```text
参考域预约事件
  → 合成源输入及 Timebase 时间戳捕获
  → CRC 编码 / FIFO / 校验
  → 运算流水线 / CRC 重编码
  → 数字链路适配器边界
  → 后续节点 FIFO / 校验 / 运算
  → 输出 valid-ready 接收
```

输入定义为 `p=17*sequence+3`，不是 ADC 实测。三步运算依次为 `p*3+7`、异或 `0x5A5AA5A5`、加源时间戳低 32 位；结果按 payload 位宽取模，源时间戳保持不变。

业务阶段明确映射：1 节点 `111`；2 节点 `001/110`；3 节点 `001/010/100`；4 节点 `000/001/010/100`。当前源为 slot0，有效节点为连续前缀；配置检查要求各运算阶段恰好出现一次且顺序正确。禁用任意中间节点不会自动重新分配算法，必须显式改 map 并开启新会话。

CRC 逐 bit 处理，当前 176-bit body 的理论最小启动间隔为 178 个时钟；50 MHz 源理论上限约 280,898.88 帧/s、1.124 MB/s payload，尚需扣除停顿。观察到的 40 帧缓存排空窗口约 272,994.54–831,450.13 帧/s；较快 sink 排空先前缓存可以超过源的持续速率，不能把上限作为持续采集吞吐承诺。包含主动 150 µs 输出停顿时，已记录端到端延迟为 61,579–157,640 ns，源 trace 在创建沿后 2 ns 采集。

FIFO 的真实写侧 full 在本域控制 ready；node-top 的 `fifo_full` 是读域 occupancy≥16 的诊断告警。FWFT 预取使读侧观察到最大 occupancy 17，不能把它解释成实际 RAM 越界。反压会使源样本创建停顿；当前源不承诺固定采样周期。

## 4. 已执行验证及证据边界

实际环境：Windows、PowerShell 7.6.5、Python 3.10.11 标准库、Vivado/XSIM 2025.2 Build 6299465，两个目标 Part 的综合/实现许可实际可用。

| 项目 | 实际结果 | 不能扩大成的结论 |
|---|---|---|
| 5 项单元测试 | 全部 PASS：调度/时间边界、FIFO、流协议、CSR、SYNC 窗口 | 不等于所有任意参数和所有异常组合已穷尽 |
| 1–4 节点 × 3 Seed | 12/12 PASS，Seed 1/17/2026，真实 UNISIM MMCM | 不等于实板运行、模拟亚稳态或随机 CDC 签核 |
| 独立 Python 逐帧核对 | 2640 个最终输出包通过 CRC/数据/序号/实际源时间戳核对 | 不等于第二 RTL 仿真器 |
| 固定 Seed 重跑 | 每种节点数各 1 组，4/4 源输入/输出/事件 CSV Hash MATCH | 不等于带日期日志或 DCP 二进制跨机器完全一致 |
| 远端独立 checkout | 03eeddc 上 5 单元 + 4 节点 Seed1 全 PASS，18 个 RTL 文件及对应 Trace Hash 匹配 | 使用同一安装的 Vivado，不是第二工具链 |
| VCD 测量 | 周期 20 / 10 / 6.666–6.667 / 20 ns；四节点首次事件偏移 0/600/1200/1800 ps | 1 ps 数字模型中的观察值，不是硬件同步精度 |
| 故障与饱和 | 输出停顿 150 µs、FIFO 满/反压、参考中断/重新锁定、局部复位/重加入、资格失败、旧会话隔离；多节点另有 CRC 故障和显式节点数切换 | 不等于电气热插拔、PHY BER 或所有最坏延迟上界 |
| 长期模型 | 15 项公共频偏/固定偏斜解析计算 | 不等于 24 小时逐周期 RTL 或硬件测试 |
| 历史保护 | 交付审计对 3723 个历史文件 Hash 全匹配；启动时 780 个封存文件也已核对 | 不等于把忽略的缓存/波形/第三方提取全文都上传 GitHub |

原始失败和修复记录全部保留。尤其 `sys04` 的早期“PASS”因旧驱动漏检混合大小写 XPM Error 被废止为验收证据；后续驱动对 Error/Fatal 均拒绝。独立 checkout 发现过 work/tmp 父目录未自动创建，运行脚本已修复，原失败日志保留；该修复未改变 RTL。

本次仅整理审查文件，重新核对了当前 18 个 RTL 文件与 canonical node manifest，Hash 均匹配。没有为文档整理重跑 RTL 仿真或实现，也没有把旧运行标成一次新运行。

## 5. 综合、STA、CDC/RDC 与 DRC 的实际状态

节点实现 profile：参考 50 MHz、工作 150 MHz、RX 100 MHz。两个 Part 均实际执行 synthesis、opt、place、phys_opt、route 和报告生成。另有完整单节点装配（包含 manager/CSR/controller）的两 Part 综合；四节点装配没有被当成一片器件的完成实现。

所有数值为 ns：

| Profile / Part | 完整 profile WNS | 完整 profile WHS | 内部寄存器 setup | 内部寄存器 hold | Critical CDC |
|---|---:|---:|---:|---:|---:|
| node / xc7z010clg400-1 | **−1.255** | **−0.862** | +0.218 | +0.050 | 0 |
| node / xc7z020clg400-2 | **−0.684** | **−0.931** | +1.056 | +0.071 | 0 |
| 三路输出回归 / xc7z010clg400-1 | +4.675 | +0.122 | +4.675 | +0.122 | 0 |
| 三路输出回归 / xc7z020clg400-2 | +5.065 | +0.121 | +5.065 | +0.121 | 0 |

必须区分三件事：

1. **内部寄存器路径通过**，但 Z010 裕量较小，接口修改后必须重新检查，不能沿用旧 PASS。
2. **历史三路输出回归已修复**：保留全部 `q[2:0]`，转入参考域同步并用 IOB 寄存器输出，同样 2 ns 输出预算；历史 WNS 为 −0.673/−0.304 ns。该回归不是完整数据节点管脚 Top。
3. **完整 node OOC profile 仍 FAIL**。工具 exit 0、内部 PASS 或小 Top PASS 均不能代替这个门禁。

每个 node 的 CDC 报告：9 条 CDC-3 Info、6 条 CDC-9 Info、36 条 CDC-15 Warning（XPM 配置 FIFO 数据路径）、1 条 CDC-26 Warning（实际报告端点为外部 arst 到心跳复位同步器）。没有手动 waiver；应核对实际端点与宏约束，不能只按规则名称认定无风险。

**整理本文件时追加确认的约束现象：**Z010 的 `effective.xdc` 中可见若干 XPM Gray 指针路径的 `set_max_delay -datapath_only` 和 `set_bus_skew` 为 `1000.000`；`clock_interaction.rpt` 中 RX→work、work→reference/RX 的部分 Max Delay Datapath Only 要求为 1000 ns。第 7 节要求进一步核验这一值。当前“Critical CDC=0”和正内部 slack 是报告事实，不能自动解释为所有宏时序预算已充分验证。

复位修复包括单一会话 owner、独立/协调 flush 契约、RAM EN/WE 同步守卫以及四个工作域同步复位分支。原 REQP-1839 异步控制 RAM 告警已消除。当前 node DRC 仍保留 RTSTAT-10 和 ZPS7-1 两条 OOC/PL-only 警告；不是“所有 DRC 为零”。RDC 的实际证据是结构审查、逐寄存器复位网清单、负向仿真和 DRC，**没有使用专用 RDC 签核工具**。

route errors 为 0；check_timing 覆盖报告列出的无时钟、无输入/输出延迟、内部未约束、环路等计数为 0。这只能证明这些结构覆盖项被检查，不能证明所有预算物理真实。两个 profile 的 pulse-width slack 均为 +2.833 ns。

两种 Part 的当前 node 资源均为 2339 LUT、4399 FF、6 BRAM tile、5 BUFG、1 MMCM；占比因器件不同而不同。`xc7z020clg400-2` 为手册候选，实际板卡 Part、VCCO 和管脚所有权尚待实物阶段确认。

## 6. 确认的阻塞问题：B-TF-001 / P-20261101-001

### 6.1 决策绑定

```text
Problem ID: P-20261101-001
Status: OPEN
Problem 文件: AI-problem/problem/P-20261101-001__node-interface-sta.md
SHA256: 5772714a3368d27d87af9d6a90b287ad963927e7335c5a03f90778e6cb6596ba
适用版本: v1
独立 Decision: 尚未产生
```

此 Hash 绑定原 Problem 文件，不是本合并文件的 Hash。GPT-chat 回答时应引用上述 ID/Hash/适用 RTL 基线。若核验发现 Problem 已变化，应要求对账，不能把旧回答当成已批准的最新 Decision。

### 6.2 实际失败路径

下列是当前 routed 报告中的直接观察，不是推测：

| Part / 检查 | 路径 | Slack | 关键条件 |
|---|---|---:|---|
| Z010 最差 setup | `core/datapath_reset/u_reset/arststages_ff_reg[2]/C -> tx_valid` | −1.255 ns | wraw 6.667 ns；output delay 2 ns；data path 2.306 ns；clock skew −3.531 ns |
| Z020 最差 setup | `core/work_source_reg/C -> fifo_level[2]` | −0.684 ns | wraw 6.667 ns；output delay 2 ns；data path 1.774 ns；clock skew −3.492 ns |
| Z010 最差 hold | `tx_ready -> core/tx/enc/out_valid_reg/D` | −0.862 ns | input delay 2 ns；clock skew +3.531 ns |
| Z020 最差 hold | `tx_ready -> core/tx/enc/out_valid_reg_rep/D` | −0.931 ns | input delay 2 ns；clock skew +3.403 ns |

还存在参考域控制输入和 `rx_frame` 输入的 hold 失败。故问题不局限于一根 TX valid，也不能只处理 `critical_paths.rpt` 中的输出 setup。

当前源码中相关结构：

```systemverilog
assign tx_valid = raw_tx_valid & ~local_work_flush;
assign fifo_full = (work_source ? sl : el) >= FIFO_DEPTH;
assign fifo_level = work_source ? sl : el;
```

### 6.3 当前约束与不能据此作出的判断

现有候选约束把 TX data/valid、FIFO 诊断输出和 `tx_ready` 关联到真实 MMCM 派生的 work clock，并采用 2 ns input/output delay。输入/输出命令没有分别列出 `-min/-max`，当前报告对 setup/hold 使用的候选值均需审查；它们没有来自已指定的实际接收器/PHY 的预算证明。

OOC 边界没有具体 HD.PARTPIN_LOCS；日志存在 Route 35-198，提示端口没有相应边界路由信息。因此下一阶段必须同时解决：

- 哪些端口属于实际 source-synchronous 数据接口，哪些属于本地状态/管理接口；
- launch/capture 时钟、转发时钟、min/max delay 和外部接收预算如何定义；
- RTL 输出寄存、反压路径、诊断状态快照和复位安全屏蔽应怎样实现；
- 哪种 OOC/层次实现或数字接口验证 Top 能对所选契约形成可审查证据。

**不能把问题直接归因于“工具 OOC 假告警”并忽略。** 目前证据只支持“该 profile 失败，预算及边界需要审查”。完整根因、可满足的接口和最终约束必须由具体设计及新报告证明。

### 6.4 已尝试的有效修复

逐 bit CRC 代替大组合 CRC；单一寄存复位 owner 与 XPM 宏消除 Critical CDC；去掉重复 busy 跨域同步；RAM 控制使用同步 guard 消除 REQP-1839；本地复位分支恢复高扇出复位路径的内部 setup。以上修复均保留对应失败记录，**没有关闭当前外部 I/O STA 阻塞**。

### 6.5 建议 GPT-chat 比较的路线

| 路线 | 内容 | 需要证明的事项 |
|---|---|---|
| A：具体数字 source-synchronous adapter | 为 TX 定义明确转发时钟与寄存/弹性边界，为 RX 定义捕获时钟、有效数据/反压关系；管理状态采用明确接口 | 保持正确传输和复位安全，setup/hold 在有效预算下闭合；物理 PHY 仍独立 |
| B：保留核心逻辑端口并增加显式 adapter profile | 核心不假装已经是板级接口；用受验证的适配器形成可约束的数字顶层；旧 FAIL profile 继续保留 | 说明旧、新顶层关系与覆盖范围；必须交付完整有效接口 STA，不能仅重命名 profile 规避现有门禁 |
| 不作为通过手段的做法 | 降频、放松 delay、删除失败端口、宽泛 false path、忽略 hold、隐藏诊断输出 | 仅为 PASS 的处理不可采用；真实规格变更必须明确论证并得到必要用户批准 |

Codex 初步倾向路线 A，或在路线 B 的结构中实现路线 A 的具体适配器。**这只是待审建议，不是已经收到的 GPT-chat Decision。** 新增 forwarded clock、寄存切片等逻辑可以在已有用户数字接口授权下评估，但不得附带引脚接线或硬件实施。

## 7. 需要审查、尚未确认为新增阻塞的风险

这些条目依据现有源码和覆盖边界提出，没有新增失败实验，不应写成已确认的 Critical Bug：

1. **SYNC 提前量及比较边界：**核对 1024 tick 的实际起算点、prepared 的期限、marker/verify 分支优先级；区分 scheduler/timebase 的已测 64-bit wrap 与 manager `ticks` 绝对比较的边界覆盖，不能声称所有计数器 wrap 已测试。
2. **故障时的 TX 屏蔽：**消除 `tx_valid` 组合路径时，不能让 reset/flush 后的旧包获得新的一次有效握手。应明确屏蔽何时生效、payload 清理何时完成、对已在途传输如何记账。
3. **控制/状态接口闭环：**scheduler 提供 `event_done/event_error/error_code`，node_core 当前有些错误/统计保留在内部；CSR 不完整暴露每节点流错误细节或所有工作域计数器快照。请判断哪些属于软件可用性的必要闭环，哪些可列后续扩展。
4. **资格输入和多位控制的真实边界：**`marker_qualified=1` 不能由常量替代物理条件；控制总线目前依赖 forwarded-reference 契约，下一阶段应说明其 source-synchronous 约束/一致性传输方式。工作域多位配置已有 FIFO，但不等于全部板间控制传输已实现。
5. **范围和覆盖：**32-bit payload、depth16、burst40 是当前系统验证点。若下一阶段宣称支持额外参数，必须新增对应仿真和资源/时序检查；没有必要为了补矩阵而先扩大 Scope。
6. **XPM Gray 指针约束的实际数值：优先核验。**当前导出约束中存在以下形式，且时钟交互报告出现 1000 ns 要求：

   ```tcl
   set_max_delay -datapath_only -from [get_cells src_gray_ff_reg*] -to [get_cells {dest_graysync_ff_reg[0]*}] 1000.000
   set_bus_skew -from [get_cells src_gray_ff_reg*] -to [get_cells {dest_graysync_ff_reg[0]*}] 1000.000
   ```

   请核验宏约束参数、约束生成/时钟读入顺序、当时是否识别真实时钟、实际路径及 bus skew。工作/RX 时钟周期约 6.667/10 ns，1000 ns 与之显著不同。**已确认的是数值存在；其来源和安全性影响尚未完成验证。** 不能直接把约 998 ns 的相关正 slack 当作真实高频设计余量，也不能在未核验实际路径和协议前断言已发生 CDC 数据损坏。请明确它是否构成新增阻塞，以及是否必须先修正约束并重新实现；不能简单因为“来自 XPM”就豁免。

请分别标记：必须在下一阶段修复 / 需要新增验证 / 文档澄清即可 / 可延期，并给出理由。若发现新阻塞，应建立新的真实 Problem 或明确更新流程，不修改已经 Hash 绑定的旧 Problem 来掩盖变化。

## 8. 下一阶段预期：保持 v1 的候选计划

**候选名称：**`INTERFACE_TIMING_CLOSURE_AND_REGRESSION`。这是给 GPT-chat 评估的计划，不表示当前对话已实施该阶段，也不表示 v1 已验收或自动建立 v2。

### 8.1 目标与范围

目标：在保持现有同步/会话/算法行为的前提下，完成一个具有明确数字时序契约的节点边界，使两 Part 的完整有效接口 setup/hold 通过，并保留当前全部失败对照及可重复性证据。

允许范围：逻辑 adapter、节点 top 的可回退调整、寄存/弹性缓冲、必要状态快照/握手、候选 XDC、数字验证 Top、TB、自动化报告、文档和 shared 状态。具体修改集由真实 Review 结果和用户现有授权共同约束。

保持：B 架构、统一参考、1–4 节点与明确阶段映射、默认工作频率、64-bit 时间/32-bit 会话、包格式及算法数值契约、原三路输出及 2 ns 回归预算、旧证据和预研只读边界。接口语义确需变更时，应提供兼容/迁移说明，不能静默改变。

不包含：PCB/原理图、制造、实物接线/改造、采购、板级精细校准、真实 PHY BER/24h 测试、部署、Merge 或 v2。预期“可继续推进硬件验证”不等于现在获得硬件工作授权。

### 8.2 实施顺序与应交付证据

| 步骤 | 预期产物 | 必须回答的问题 |
|---|---|---|
| 1. 基线重核 | 当前分支/HEAD、源码 Hash、旧报告/失败路径清单 | 新工作是否对应正确 v1？是否保留原始失败？ |
| 1a. 宏约束核验 | XPM 指针约束数值、时钟识别/读入顺序及 bus skew 审查；必要时纠正后重跑 | 1000 ns 要求是否符合实际接口与宏条件？是否存在未被有效预算约束的风险？ |
| 2. 接口契约 | 每类端口的域、方向、有效/反压、采样边沿、min/max 预算及推导、复位/在途包策略 | 每个时序数字来自何种假设或目标要求？ |
| 3. 适配器与边界 RTL | 必要寄存/缓冲/时钟和状态路径；与原核心的关系 | 有无组合 ready 环路、跨域多位撕裂或旧会话泄漏？ |
| 4. 有效候选约束 | common/generated clock、I/O、CDC 宏约束、内部时序及候选顶层配置 | 有无把真路径排除或把时钟定义成不真实关系？ |
| 5. 功能及故障验证 | 正常/满速/反压、延迟边界、复位、参考丢失、恢复、旧数据隔离 | 新边界是否改变语义或掩盖故障？ |
| 6. 两 Part 实现 | synth/opt/place/route、完整及内部 STA、CDC/RDC/DRC、覆盖、资源、critical paths | setup、hold、pulse width 和例外是否均可解释？ |
| 7. 复现与审查交接 | 源码 Commit、固定 Seed、Trace Hash、独立 checkout、更新状态和 Review 包 | 别人能否据已推送内容重跑并得到定义内一致结果？ |

### 8.3 建议验收标准，供 GPT-chat 确认

- 两 Part 的**所交付有效完整接口 profile**满足 setup/hold，`WNS≥0`、`WHS≥0`，pulse-width 检查通过；原内部及三输出回归继续通过。
- 完整接口应包含必要 RX/TX、控制、状态和反压路径。允许诊断口采用明确的新快照接口，但不允许删掉观测能力来消除失败。
- Critical CDC=0；无未解释的关键 CDC/RDC。REQP-1839 不复发；对保留的警告逐项说明适用边界，不伪称全部警告为零。
- 第 7 节的 1000 ns 宏约束疑点必须获得实际证据支持的结论；如果预算或生效顺序有误，先修正并重新实现，不能沿用先前正 slack 作签核。
- 无无时钟/内部漏约束/无合理 I/O delay 等覆盖缺口；route errors=0。检查有效 XDC 和时钟交互，不仅看总 WNS。
- 保留当前 5 项单元、12 组系统配置、独立源到输出 reference check 和 4 组固定 Seed 重跑基线。若接口合理增加延迟，可以产生有说明的新黄金 Trace；不得为迁就错误数据或错误预约时刻而改断言。
- 新增与本次变化直接相关的边界测试：valid-held-under-stall、ready 注册后的容量预算、故障/复位恰逢握手、在途包归属、SYNC/配置准备期限，以及 min/max 捕获窗口的数字边界。
- 既定输入算法结果、CRC/序号/会话/源时间戳核对继续通过；无未经定义的静默丢包。恢复后的旧会话事件不得执行。
- 新源码 Commit、实际工具版本、原始日志、波形/Trace、Hash、失败记录与 clean-checkout 复现齐全。单机另一工作目录的重跑仍应明确为同一工具链。
- 不把新数字接口预算、候选管脚或数字边沿偏移宣传为实物板级安全/精度。

Z010 现有内部 setup 裕量只有 +0.218 ns。下一阶段应报告改动后的最差路径和裕量；不能保留新外部 PASS、丢弃新的内部 FAIL。任何额外的“最小正裕量”目标需要给出依据和明确目标，不由本文凭空指定数值。

### 8.4 什么时候仍应停止并交付 REVISE

若无法建立可解释的接口预算、完整有效 profile 仍负时序、发现核心功能/CDC/RDC 失败、需要越出已有授权，或连续根因修复没有新证据，应保留本轮成果并提交实际问题包。不得把已失败的 profile 悄悄从验收表移走，也不应无限调布局种子碰运气。

## 9. 期望 GPT-chat 返回的审查格式

建议按下列结构输出，足以供 Codex 持久化与执行：

```text
Review Target:
  PROJECT_ID=TIMEFOOT, active_version=v1
  source_delivery_commit=a1633e1a18df87bcb74fb9464e46e006fa406cb4
  validated_rtl_commit=46f88bcd553a13a9fda55b2599c6740acf6681d0
  problem_id=P-20261101-001
  problem_hash=5772714a3368d27d87af9d6a90b287ad963927e7335c5a03f90778e6cb6596ba

Evidence Actually Read / Evidence Not Accessible:
Independent Stage Verdict: ACCEPT | ACCEPT WITH LIMITATIONS | REVISE
Confirmed Findings: severity / code-or-report reference / impact
Additional Risks Requiring Verification:
Decision For P-20261101-001: chosen route / rejected routes / reasons
Interface And Timing Contract: clocks / sampling / min-max / flow-control / reset
Next Stage Goal / Scope / Non-Goals:
Allowed Changes / Do Not Change / Invariants:
Required Tests And Implementation Reports:
Done When / Remaining Hardware Boundaries:
User Approval Still Required:
Concrete Codex Execution Instruction:
```

请区分：已由工具确认的事实、对根因的推断、待验证假设和建议。Review 可以提出新风险；没有执行新仿真/实现时，不写成已经运行后的结论。独立 Review 的职责是作出有依据的判断，不是重复 Codex 的 PASS 表格。

Codex 收到真实回答后，需核对 ID、Hash、版本、源码基线及用户授权边界，再保存真实来源的 Decision 并执行。用户明确保留权限的事项，不能因 GPT-chat 建议就自动批准。

## 10. 可重跑命令与运行说明

以下为已存在脚本的用法；本次文档整理未执行这些长运行。使用 PowerShell 7，从正确项目根目录执行。每次使用新的 tag，避免覆盖旧证据：

```powershell
Set-Location -LiteralPath 'E:\Codex_project\Timefoot'
$env:TIMEFOOT_VIVADO_BIN = 'D:/Vivado/2025.2/2025.2/Vivado/bin'
$ReviewRunTag = 'review_' + (Get-Date -Format 'yyyyMMdd_HHmmss')
python v1/scripts/run_sim.py --tag ($ReviewRunTag + '_unit') --suite unit
python v1/scripts/run_sim.py --tag ($ReviewRunTag + '_system') --suite system
python v1/reference_model/check_system.py ($ReviewRunTag + '_system')
python v1/scripts/run_sim.py --tag ($ReviewRunTag + '_repeat') --suite repeat
python v1/scripts/run_impl.py --tag ($ReviewRunTag + '_node') --mode node
python v1/scripts/run_impl.py --tag ($ReviewRunTag + '_pin') --mode pin
```

脚本自动创建本项目内的 work/tmp 和证据目录。`run_impl.py` 返回 0 只证明 Vivado 命令执行完成，仍须解析并审查 STA/CDC/DRC 等报告。当前 clock/audit/seal 脚本有针对 canonical 目录的路径，不能把它们误认为自动支持所有新 tag；新阶段应明确新旧证据映射或改进报告入口。

## 11. 固定快照证据入口

以下链接固定到本文整理前的交付 Commit，避免浮动分支随后变化而混用结果。主要结论已内嵌于本文，链接用于进一步独立核验：

| 证据 | 固定链接 |
|---|---|
| 全部 RTL 及候选 XDC | [v1 源码快照](https://github.com/loverlike1216/Timefoot/tree/a1633e1a18df87bcb74fb9464e46e006fa406cb4/v1) |
| 交付审计、STA 数值及相关源码 Hash 对账 | [DELIVERY_AUDIT.json](https://github.com/loverlike1216/Timefoot/blob/a1633e1a18df87bcb74fb9464e46e006fa406cb4/v1/verification/evidence/DELIVERY_AUDIT.json) |
| Z010 实现原始报告 | [Z010 closure_node](https://github.com/loverlike1216/Timefoot/tree/a1633e1a18df87bcb74fb9464e46e006fa406cb4/v1/verification/evidence/closure_node/xc7z010clg400-1) |
| Z020 实现原始报告 | [Z020 closure_node](https://github.com/loverlike1216/Timefoot/tree/a1633e1a18df87bcb74fb9464e46e006fa406cb4/v1/verification/evidence/closure_node/xc7z020clg400-2) |
| 当前 I/O 候选预算 | [logical_interfaces.xdc](https://github.com/loverlike1216/Timefoot/blob/a1633e1a18df87bcb74fb9464e46e006fa406cb4/v1/constraints/logical_interfaces.xdc) |
| 12 组系统结果及逐帧独立核对 | [closure_system](https://github.com/loverlike1216/Timefoot/tree/a1633e1a18df87bcb74fb9464e46e006fa406cb4/v1/verification/evidence/closure_system) |
| 独立远端 checkout 结果 | [clean_checkout/result.json](https://github.com/loverlike1216/Timefoot/blob/a1633e1a18df87bcb74fb9464e46e006fa406cb4/v1/verification/evidence/clean_checkout/result.json) |
| 独立 VCD 时钟/事件测量 | [clock_measurements.json](https://github.com/loverlike1216/Timefoot/blob/a1633e1a18df87bcb74fb9464e46e006fa406cb4/v1/verification/evidence/clock_measurements.json) |
| 原始 Problem 及批准边界 | [P-20261101-001](https://github.com/loverlike1216/Timefoot/blob/a1633e1a18df87bcb74fb9464e46e006fa406cb4/AI-problem/problem/P-20261101-001__node-interface-sta.md) |
| CDC/RDC 方法与警告解释 | [CDC_RDC_REVIEW.md](https://github.com/loverlike1216/Timefoot/blob/a1633e1a18df87bcb74fb9464e46e006fa406cb4/v1/docs/CDC_RDC_REVIEW.md) |
| 失败、无效 PASS 与修复经过 | [FAILURE_ANALYSIS.md](https://github.com/loverlike1216/Timefoot/blob/a1633e1a18df87bcb74fb9464e46e006fa406cb4/v1/docs/FAILURE_ANALYSIS.md) |
| 人工授权原文 | [v1 正式指令](https://github.com/loverlike1216/Timefoot/blob/a1633e1a18df87bcb74fb9464e46e006fa406cb4/AI-interaction-memory/cross-agent/TIMEFOOT_v1_USER_INSTRUCTION.md) |

全部相对源码/证据路径均相对于 `E:\Codex_project\Timefoot`。较大的 VCD/DCP 保留本地，Hash/大小见清单；GitHub 有源码、紧凑 Trace、报告和索引，不能声称线上包含所有二进制波形。预研目录保持历史只读。

**提交给 GPT-chat 时的最终请求：请依据以上真实边界完成独立 Review，给出当前阶段结论、阻塞项分级，以及留在 v1 内的接口时序闭合决策和下一阶段 Codex 指令。物理硬件验收与用户保留审批继续独立。**
