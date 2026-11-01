# 多FPGA同步系统：隔离预研包

**预研意见：FEASIBLE_WITH_CONSTRAINTS。正式工程未启动，FORMAL_VERSION=NOT_STARTED。**

建议先阅读 [ChatGPT决策包](decision/GPT_CHAT_DECISION_PACKAGE.md)，再查看 [仿真与验证报告](SIMULATION_REPORT.md) 和 [证据索引](evidence/EVIDENCE_INDEX.md)。本目录为预研工作区，不是正式v1，不是Git仓库。

## 核心结果

- 最终19配置×2次独立编译运行=38/38仿真PASS；同Seed事件/数据Trace和规范化结果Hash一致，Python独立复核2443帧。
- 真实MMCM仿真原语验证50/100/150MHz参数；两目标实际综合和OOC布局布线完成。
- 每节点探索性实现601LUT、1365FF、0BRAM、1MMCM、4BUFG；OOC正裕量只限虚拟接口约束。
- 每Part仍有9条Critical CDC。H16/U14专用输入路径虽已布线，管脚top输出STA分别WNS−0.673/−0.304ns。**保留FAIL，不作系统时序闭合声明。**
- EBAZ完整DATA针表/VCCO/PS时钟、实物型号/修订、物理PHY/校准/仪器及实板长期试验尚未闭环；不放行接线或PCB制造。

## 目录导航

| 位置 | 内容 |
|---|---|
| `research/BOARD_FACTS_AND_PIN_AUDIT.md` | 三附件来源、51页覆盖、器件/时钟/Bank/接口与冲突 |
| `research/TECHNOLOGY_SURVEY.md` | 官方技术依据、时钟/CDC/PTP/WR与创新边界 |
| `research/OPEN_SOURCE_COMPARISON.md` | 项目实际URL、时间、许可、平台和公开证据 |
| `research/HARDWARE_FEASIBILITY.md` | 4clock+4SYNC、接收/终端、BOM预算与实物待验证 |
| `decision/ARCHITECTURE_COMPARISON.md` | A/B/C完整比较与候选建议 |
| `decision/RISK_REGISTER.md`、`decision/BLOCKERS.md` | 15项风险、阻塞与解除要求 |
| `simulation/rtl`、`tb`、`reference_model`、`scripts` | 可审阅验证源码，含真实UNISIM实例 |
| `evidence/simulation_logs/finalE`、`finalF` | 最终有效19例的两轮原始日志/Trace |
| `evidence/timing_reports`、`resource_reports` | 实际OOC、管脚探针、STA/CDC/DRC与DCP |
| `evidence/waveforms` | VCD；不支持的unpacked array另用CSV核对 |
| `evidence/FAILURE_AND_RCA.md` | 保留的工具、模型、覆盖与STA失败 |
| `evidence/RESULT_SUMMARY.json`、`DELIVERY_AUDIT.json` | 机器可读结果与交付核验 |
| `guide.md`、`evidence/PREPROJECT_CHECKPOINT.json` | 本预研恢复入口；不是正式项目状态 |
| `.work` | 隔离venv/缓存、各次工具工程和新鲜重放产物，不是正式源码 |

## 重放

在PowerShell7执行：

```powershell
Set-Location -LiteralPath 'E:\Codex_project\Timefoot\preproject_feasibility'
pwsh -NoProfile -File '.\REPLAY.ps1'
# 如需重新执行两个器件的综合、OOC和管脚路由：
pwsh -NoProfile -File '.\REPLAY.ps1' -IncludeImplementation
```

默认Vivado：`D:\Vivado\2025.2\2025.2\Vivado\bin`；不同安装位置通过 `-VivadoBin` 指定。重放在本目录 `.work/replay_<timestamp>` 建立新副本，保留交付证据，不执行删除、Git或硬件连接。Python模型/测试驱动仅用标准库；PDF重提取才需要 `requirements.txt` 中锁定的PyMuPDF。安装文件、商业许可证和原始附件不会被复制进新的正式工程。

原始命令和退出码分散记录于environment与每个case日志；索引提供具体入口。单纯工具exit0不覆盖负时序或未关闭CDC。`REPLAY.ps1 -IncludeImplementation`可成功生成包含负STA的报告，不能把脚本完成解释为硬件PASS。

完整重放脚本已在新副本实际执行38例并通过Hash对照。换电脑重放时仍需manifest所列原始附件可读，以复核来源Hash；若调整来源位置，应显式记录映射，不能把缺失来源改写成“未变化”。

## 权限与证据边界

本轮只读三份用户附件和公开资料，仅写本隔离目录；没有初始化v1、正式仓库、commit/push、采购、CAD/PCB或板卡改动。没有访问不可见的外部ChatGPT历史，没有代填ChatGPT Decision。正式立项、指标、预算和仓库由用户与ChatGPT决定。
