---
project_id: TIMEFOOT
project_root: E:/Codex_project/Timefoot
active_version: v1
current_stage: RTL_CORE_AND_SYSTEM_FRAMEWORK
branch: codex/v1-rtl-core
guide_status: PARTIAL
sources: [AI-interaction-memory/cross-agent/TIMEFOOT_v1_USER_INSTRUCTION.md]
---
# TIMEFOOT conversation guide

2026-11-01: 用户明确批准正式v1，唯一仓库loverlike1216/Timefoot，唯一根目录如上。
本次授权取代“正式开发尚未授权”的历史状态；不修改历史预研文档中的当时状态。
采用B架构：公共50MHz参考、1–4节点可配置，AX7020可选。工作时钟默认50/100/150/50MHz。
允许RTL/接口/候选XDC、仿真、综合实现、STA/CDC/RDC、正常Commit/Push/PR；禁止Merge、v2、PCB/实物/采购/部署。
普通可逆技术选择自主执行。预研780封存文件和3723历史文件已建立只读对账，不能覆盖失败。
关键历史问题：9 Critical CDC/Part，管脚top负WNS，异步SYNC捕获/late join无保证、FIFO复位/协议缺口。
当前状态以shared、当前源码和真实新日志为准，不能从本guide推断验证PASS。
完整ChatGPT外部页面未指定且无可用读取工具；只有用户实际传入的指令作为批准来源。
