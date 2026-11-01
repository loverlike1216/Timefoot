---
task_type: PRE_PROJECT_FEASIBILITY
project_status: CONSULTATION_ONLY
formal_version: NOT_STARTED
project_id: NOT_ASSIGNED
formal_repository: NOT_SELECTED
evaluation_root: E:/Codex_project/Timefoot/preproject_feasibility
date: 2026-11-01
guide_status: PARTIAL
source_coverage: current user request and supplied local documents; no inaccessible ChatGPT history
---

# Pre-project conversation guide

本轮仅限预研、隔离代码、仿真、综合、报告。不得初始化正式 v1、Git Repository、push、PCB、采购或实板改动。主项目尚未启动，正式 PROJECT_ID / Repository / Stage / 版本状态均不可伪造。

用户资源设想：1 块 AX7020 和 4 块 EBAZ4205；固定四路同步接口，启用 1–4 路；支持 50/100/150/50 MHz；AX7020 可选管理，不可成为模块强制依赖。

必须区分：同频、同源、同相、同一时钟域、逻辑时间、预约事件输出、链路延迟。物理精度不由行为仿真或 OOC 正裕量证明。N18 原板振荡器不可与新驱动源并接。器件数据库确认球位功能，不证明 DATA 接口针号或实物 Bank 电压。

当前请求 canonical：`research/source_extracts/USER_REQUEST.txt`。源资料 SHA-256 在 `evidence/environment/source_manifest.json`；来源覆盖和限制在 `research/BOARD_FACTS_AND_PIN_AUDIT.md`。实际最新证据入口是 `evidence/EVIDENCE_INDEX.md`、`SIMULATION_REPORT.md` 和决策包。

恢复时先检查这些文件、源代码 Hash 和最新日志；不得从本 guide 推断测试 PASS。正式项目若获批，仍须用户指定亲自创建的仓库和正式路径。当前目录只是候选验证资产，不能自动升格。

工具历史：Vivado 2025.2 可用且实际 Synthesis 许可证测试通过；PowerShell 7.6.5；本地 Python 3.10.11 + 隔离 PyMuPDF 1.26.7。Windows `.bat` 的等号与 Tcl 反斜杠问题已记录在 `evidence/FAILURE_AND_RCA.md`。保留全部失败记录。

没有自动模型切换/压缩钩子的证据，不声明已拦截任何平台内部事件。未获取外部 ChatGPT 对话，也没有向 ChatGPT 发消息。
