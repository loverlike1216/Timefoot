# 剩余问题与条件性风险

当前数字Profile Blocking=0、已知Critical RTL Bug=0（针对已执行矩阵，不代表穷尽证明）。PCB_PRE_DESIGN_READY_WITH_LIMITATIONS；独立ChatGPT Review PENDING。硬件冻结/实板安全并未通过。

| ID / Severity | 根因与已尝试 | 证据 | 影响 / 为什么未关闭 | 下一步 / 用户审批 |
|---|---|---|---|---|
| HW-PHASE-001 / HIGH hardware gate | CLOCK/SYNC独立fanout/receiver器差；比较LMK00304、105、1104并计算保守预算 | P-20261101-002、CLOCK_ERROR_BUDGET、clock_budget.json | 最坏±5ns不能直接保证0.5..3ns资格范围；无实板测量，不能靠RTL猜测关闭 | 匹配接收/路径或可验证相位补偿，实测再资格化；CAD/硬件需要新用户授权 |
| HW-REV-001 / HIGH wiring gate | 用户EBAZ MD缺原DATA原图，已找社区原图+同repo XDC交叉核对；AX有用户原图 | PIN_MAPPING_CANDIDATE、datasheet_sources | 社区与四块实物修订/串阻/扩展模块/VCCO未核；不同板电源不能并联 | 逐板版本/电压/通断/驱动归属核查；接线与实物操作需新授权 |
| HW-SI-001 / HIGH hardware acceptance | 当前只有候选短距CMOS和差分分发预算，未做IBIS/眼图/BER | HARDWARE_INTERFACE_REQUIREMENTS | 无真实线缆/板/探头；数据50MHz可路由不代表线束可运行 | 下一阶段SI/回流/终端/接收共模/供电瞬态测试；当前无实物授权 |
| BOM-001 / MEDIUM freeze gate | 主要IC有厂家依据，105订货页当次Out of stock；连接器配合版本未知 | COMPONENT_SELECTION_AND_BOM | ACTIVE不等于可采购；保护/无源/接插件未冻结 | 选定可供货封装、机械配合与电源/保护参数；采购需新授权 |
| ZYNQ-BOOT-001 / MEDIUM deployment gate | PL验证top未集成PS7，DRC ZPS7-1保留 | 完整实现drc.rpt | 本阶段不生成bitstream/启动软件，不能称可直接上板 | 真正部署前按板启动条件集成PS7/复核配置；部署需新授权 |
| RDC-TOOL-001 / MEDIUM evidence limit | 使用Vivado CDC/DRC、reset结构、XPM仿真、flush/失锁负例；无独立RDC signoff工具 | TIMING_CONSTRAINT_SPEC、原rpt | 工具覆盖有限；不能冒充专用RDC穷尽检查 | 独立Review复核reset tree、异步安全边界；如另行指定工具可补查 |
| PHY-SUPERVISION-001 / MEDIUM protocol limit | raw RX不提供独立partial-frame timeout；两端flush由Session owner协调 | LINK_PROTOCOL_SPEC | 不保证单端硬复位或断线自主恢复；现有fault/CRC/manager监督覆盖限定场景 | 外部管理器实现断线/两端reset监督后再允许新Session；无核心Scope扩展批准 |
| TRACE-NAV-001 / LOW tooling limit | link8/25 CSV文件名匹配及negative case stale CSV不作为证据；未删除原运行物 | VALIDATION_AND_REPRODUCTION | 不影响log/VCD/phase sweep证据；不声称该CSV逐case完整 | 后续小工具改进可选，不重新启动RTL优化循环 |
| CTRL-CLOCK-001 / MEDIUM interface condition | 管理CSR后端在reference域，参考完全停止时命令只能排队；fault_out可异步断言安全态 | MODULE_INTERFACE_SPEC、physical top/reset结构 | 不承诺停钟期间即时CSR响应；测试访问中qualification故障并非停止CSR时钟 | host监控fault_out并设置超时，等参考恢复后读CSR/新Session；如要求停钟可读完整CSR需另行接口决策 |
| REVIEW-001 / QUALITY GATE | 可观察用户指令已存档；无外部ChatGPT历史/Review工具 | GPT_CHAT_FINAL_REVIEW | 独立Review尚未实际收到；Codex不能替ChatGPT签最终ACCEPT | 将单文件交ChatGPT；用户另行决定是否允许硬件Stage |

历史P-20261101-001原问题Hash不变，来源用户明确批准的adapter Decision已执行；旧宽节点STA仍保持FAIL对照，新的完整功能profile通过不是“把旧top改名后删端口”。P-001可由独立Reviewer确认数字关闭，不伪造其最终Decision。早期原型失败、心跳Seed17报错、资源压力引起XSIM崩溃/中止日志全部保留，与最终冻结证据分开使用。

不允许为解决上述硬件条件自动创建v2、改同步验收门槛、Merge、采购或生成CAD/制造文件。
