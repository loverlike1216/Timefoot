# TIMEFOOT

共享50MHz参考时钟的多FPGA时序同步RTL核心与数字系统框架。

正式身份：TIMEFOOT / v1 / INTERFACE_TIMING_CLOSURE_AND_PRE_PCB_READINESS；仓库由用户指定为本仓库，正式根目录 `E:\Codex_project\Timefoot`。当前开发分支 `codex/v1-rtl-core`，主分支未合并。**当前Stage：PCB_PRE_DESIGN_READY_WITH_LIMITATIONS；4/8bit完整功能数字节点在Z010/Z020均正setup/hold/pulse余量，硬件冻结与独立Review仍有门禁。** 不代表实板验收或PCB授权。

- [当前单文件GPT-chat审查包](v1/docs/pre_pcb_readiness/GPT_CHAT_FINAL_REVIEW.md)：集中事实、阻塞条件、下一阶段预期。
- [PCB前准备报告与14项输入](v1/docs/pre_pcb_readiness/PRE_PCB_READINESS_REPORT.md)、[当前机器审计](v1/verification/evidence/prepcb_analysis/stage_audit.json)。
- 以下为上一Stage历史文档入口；旧宽接口负STA保留，当前窄接口Profile不覆盖其原记录。

- [独立Review入口](v1/docs/GPT_CHAT_STAGE_REVIEW.md)：真实RTL Commit、验证矩阵、时序和未闭环问题。
- [仿真报告](v1/reports/SIMULATION_REPORT.md)、[实现与STA报告](v1/reports/IMPLEMENTATION_REPORT.md)、[数据预算](v1/reports/PERFORMANCE_BUDGET.md)。
- [数字接口契约](v1/interfaces/DIGITAL_CONTRACT.md)、[寄存器映射](v1/interfaces/REGISTER_MAP.md)、[架构](v1/docs/ARCHITECTURE.md)。
- [复现命令](v1/docs/REPRODUCE.md)、[证据导航](v1/verification/EVIDENCE_INDEX.md)、[审计JSON](v1/verification/evidence/DELIVERY_AUDIT.json)。
- [当前状态](shared/PROJECT_STATE.json)、[恢复检查点](shared/CONTEXT_CHECKPOINT.md)、[待审问题](AI-problem/problem/P-20261101-001__node-interface-sta.md)。

v1提供1–4节点逻辑装配、MMCM50/100/150/50MHz工作域、未来Epoch同步、预约事件队列、跨域配置/数据FIFO、CRC/序号/会话检查、真实算术流水线、反压、参考丢失/复位后的新会话恢复。AX7020不是同步核心的强制依赖。跨板PHY和参考/SYNC时序是明确的适配器边界；仿真链路不等于真实电缆。`marker_qualified`是时序资格输入，不是物理相位测量器。

`preproject_feasibility/`保持历史只读。正式启动前3723文件已建立Hash清单，交付时再次逐文件对账；历史失败也保留。Git保存其原始文本、源码和报告，工具缓存、波形/DCP及第三方原始文档提取保留在本地并由清单索引。禁止在原预研目录重跑会覆盖输出的旧脚本。

本轮没有PCB/原理图、实物改造、采购、部署、v2或Merge。板卡真实Part、VCCO、引脚所有权、电缆PHY、BER、物理精细校准及24小时实物运行均未验证。候选XDC不能作为接线或制造依据。
