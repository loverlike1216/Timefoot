---
project_id: TIMEFOOT
project_root: E:/Codex_project/Timefoot
active_version: v1
current_stage: INTERFACE_TIMING_CLOSURE_AND_PRE_PCB_READINESS
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

2026-11-01 validation checkpoint:正式RTL已提交。五项单元测试通过；sys09旧源码12配置、2640帧独立Python核验通过；更严格配置检查及RAM EN复位锥修复后的signoff运行仍在执行。所有旧失败保留，sys04因漏检XPM混合大小写Error被明确废止为验收证据。管脚三输出同2ns预算正STA；完整节点内部STA正，OOC接口仍负STA，需REVISE/独立Review。最后有效结论以v1/reports、verification/evidence和最新shared状态为准。新增关键边界：read-domain fifo_full是容量告警，实际写侧full只在本域控制流控；REQP-1839必须审查，CDC Critical=0不能替代RDC/DRC。

2026-11-01 review checkpoint（取代上段“仍在执行”的临时状态）：当前RTL46f88bc，closure_system12/12、closure_repeat4/4HashMATCH、signoff_unit5/5、独立2640包及VCD时钟/事件测量均通过；3723历史文件全部Hash匹配。closure_node内部setup/hold两Part正，CriticalCDC0，RAM EN异步复位DRC0；完整节点OOC I/O STA仍负，Stage结论REVISE。正式恢复入口shared/CONTEXT_CHECKPOINT与v1/docs/GPT_CHAT_STAGE_REVIEW.md；P-20261101-001等待真实独立Review。当前版本仍v1ACTIVE。普通受授权的RTL细节已自主实施，不将此Problem伪造成ChatGPT Decision或已批准的Scope变更。

交付补充：Draft PR#1已OPEN，未Merge；远端独立checkout03eeddc重跑5units+4node seed1PASS，18RTL及对应CSV Hash匹配。首轮独立checkout发现work/tmp未自动创建，已修复运行脚本，失败日志保留。此修复不改变RTL；证据见clean_checkout/result.json和shared/HANDOFF.md。GitHub Connector创建PR返回403，改用既有已登录gh完成，不改变认证或仓库安全策略。

2026-11-01新Stage用户明确授权（保留v1）：完整指令见AI-interaction-memory/cross-agent/TIMEFOOT_v1_PRE_PCB_USER_INSTRUCTION.md。
P-20261101-001原Hash已核对，Decision来源是实际用户提供指令，不冒称已读取外部ChatGPT会话。
目标数字适配器STA闭合及14项PCB前输入资料；允许候选电气/引脚/BOM研究，不进行CAD/PCB/采购/实物操作。
P0已实际对照证明1000ns来自XPM在综合时无时钟的fallback；提前read_xdc后自动获得6.667/10/20ns并完成routed bus-skew。
新tf_link_tx/rx采用4/8bit SDR+SOF+整帧credit（不是逐拍ready）；转发时钟ODDR180度中心采样。
接收端预留一整帧，SOF后credit拉低，已交给核心后再拉高；发送端XPM同步credit并观察low→high才重启。
异步安全mask先进入同步input_slot再到FIFO写使能。统计使用coherent handshake快照，不关闭XPM检查。
物理node新增48bit串行管理、工作/RX状态原子快照、事件/错误计数读取；正在验证，不能从文件存在推断PASS。
当前实现/仿真原型日志见pre_pcb_preflight，最终签核必须对冻结Commit重跑。实时状态以最新Checkpoint/真实日志为准。
