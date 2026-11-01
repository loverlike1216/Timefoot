# TIMEFOOT v1 PCB前准备报告

日期：2026-11-01。Stage：INTERFACE_TIMING_CLOSURE_AND_PRE_PCB_READINESS。

**工程状态：PCB_PRE_DESIGN_READY_WITH_LIMITATIONS。** 数字Profile已闭合；硬件BOM/相位资格冻结HOLD，ChatGPT独立Quality Gate PENDING。这不是用户对原理图、PCB、接线、采购、制造或部署的授权，也不是实板同步精度验收。

## 身份与来源

唯一项目TIMEFOOT，Repository https://github.com/loverlike1216/Timefoot.git，PROJECT_ROOT `E:/Codex_project/Timefoot`，版本v1，branch `codex/v1-rtl-core`。验证源Commit **45aa523ddb4151157672df1ee3c5bb483be3edb0**；PR [#1 OPEN/DRAFT](https://github.com/loverlike1216/Timefoot/pull/1)，未Merge。文档/证据交付Commit以Git当前记录为准，不用文档的自引用Hash伪造HEAD。

原P-20261101-001 SHA256 **5772714a3368d27d87af9d6a90b287ad963927e7335c5a03f90778e6cb6596ba**未变。实际用户下一阶段完整指令批准数字适配路线，Decision保存于AI-problem/decision；没有伪造外部ChatGPT回答。预研3723文件全部Hash保持一致（其中780封存文件）。

## 交付结果

保留208bit核心帧和原算法，新增真实可综合4/8bit SDR TX/RX、ODDR转发时钟、整帧credit、输入保持槽/FIFO、跨会话中止计数、coherent状态桥、48bit串行管理和寄存器后端。修复SYNC manager计数wrap/迟到ACK优先级，以及多Seed发现的reset截短监测心跳问题。新适配器实际进入每段系统数据链路，末端也经过串并重组，没有宽总线旁路。

## 两Part完整数字签核

| 位宽/频率 | Part | WNS ns | WHS ns | WPWS ns | LUT / FF / BRAM tile / DSP |
|---|---|---:|---:|---:|---|
| 4bit50 | xc7z010clg400-1 | +0.468 | +0.009 | +2.833 | 3546 / 7961 / 9 / 0 |
| 4bit50 | xc7z020clg400-2 | +0.925 | +0.028 | +2.833 | 3545 / 7961 / 9 / 0 |
| 8bit50 | xc7z010clg400-1 | +0.313 | +0.016 | +2.833 | 3542 / 7956 / 9 / 0 |
| 8bit50 | xc7z020clg400-2 | +0.752 | +0.036 | +2.833 | 3543 / 7956 / 9 / 0 |

全部为full synth→opt→place→phys_opt→route、真实IO与候选连接器引脚，非OOC。route errors0、CriticalCDC0、REQP-1839不存在；bus skew最大1.274/1.113/1.279/1.180ns，最小skew余量5.568/5.765/5.519/5.734ns。Gray max_delay自动6.667/20/40ns、没有1000ns。1000ns根因由同RTL early/late读clock实验确认，修复为综合前读primary clocks。

保留CDC-15厂商FIFO警告、TIMING-18边沿/异步输入分类、tx_clock作为generated clock的no_output_delay LOW项、DRC RTSTAT-10/ZPS7-1。独立RDC工具未运行，不能据CriticalCDC0宣称所有工具零警告。旧宽节点-1.255/-0.862与-0.684/-0.931仍作为旧Profile失败证据保留。

## 功能、回归和复现

原5units、新6扩展tests、串行物理节点64帧、旧12系统case、新12 SDR系统case、4 Seed1重跑、4节点8bit240帧、6随机初相位链路tests全部通过。新/旧12case分别独立核对2640帧；4个重跑case的源/输出/事件三种CSV全Hash一致。远端干净检出45aa523再跑5units和4节点Seed1，25RTL字节Hash及三类CSV Hash匹配、240帧Python检查通过。所有这些仍是同版本XSIM，不冒称第二模拟器或硬件。

实际VCD工作周期20ns/10ns/6.666–6.667ns/20ns，给定数字传播条件下首事件偏移0/600/1200/1800ps。物理top64包无故意堵塞延迟7.2501..10.7901us、约280899frame/s。多节点150us故意堵塞场景、FIFO满/反压/中止均有独立指标，详见吞吐预算。

## 条件性硬件输入

72行候选信号分配（两板各36，包含8bit增量）、Bank/连接器pin/方向/电压/风险/来源/状态齐全；EBAZ社区原图及XDC交叉核对，仍需逐板修订/电压/驱动验证。主要BOM候选ASE50MHz、SN65LVDS105双fanout、SN65LVDT2接收、TPS62162接口电源，LMK00304与LMK1C1104比较保留。器件/连接器未冻结，无采购/CAD。

当前最重要的硬件条件是CLOCK/SYNC最坏器差±5ns不能从资料直接推出数字Profile的0.5..3ns资格范围。P-20261101-002集中提交该问题，硬件冻结前须匹配/补偿/测量；没有放宽XDC掩盖它。

## 当前门禁

数字Blocking=0；已执行范围内已知Critical RTL Bug=0；独立Review未完成；硬件冻结/接线安全HOLD。最终独立结论由ChatGPT审查后按ACCEPT / ACCEPT WITH LIMITATIONS / REVISE给出，用户本人决定下一阶段授权。

本目录14文件组成预设计输入；只转交单一文件时使用 **GPT_CHAT_FINAL_REVIEW.md**，其中集中给出真实结果、阻塞条件和下一阶段预期。机器证据主入口`v1/verification/evidence/prepcb_analysis/stage_audit.json`。
