# 技术调研与选型

访问日期：2026-11-01（Asia/Shanghai）；范围是可复用多 FPGA 同步模块，不是独立时间基准产品。检索已覆盖用户列出的 clock distribution、multi-FPGA synchronization、deterministic trigger、MMCM/PLL/BUFG、CDC/FIFO、source synchronous、PTP、White Rabbit 和校准关键词。足以支撑本轮候选比较后停止检索。

## 采用的概念和官方依据

1. **同源频率不等于物理同相，也不自动成为同一时钟域。** 专用 CC 输入、MMCM 反馈补偿和 BUFG 处理片内时钟；跨板线缆、输入缓冲、PLL 复位/失锁和捕获边界仍要独立约束、校准和测量。优先专用 P 脚，输出转发宜使用 ODDR/专用输出路径。依据：[AMD UG472 v1.14, 2018-07-30](https://www.amd.com/content/dam/xilinx/support/documents/user_guides/ug472_7Series_Clocking.pdf)。
2. **CDC 与约束必须一起设计。** 双触发器用于单比特控制；多比特时间/事件须稳定捆绑握手、Gray 编码或异步 FIFO。异步 FIFO 的 Gray 总线需要最大数据路径/总线偏斜限制，不能仅加 ASYNC_REG。时钟组/false path 只在已证实结构与异步关系上使用。[UG903 bus skew](https://docs.amd.com/r/en-US/ug903-vivado-using-constraints/Constraining-Bus-Skew)，[UG949 CDC](https://docs.amd.com/r/2023.2-English/ug949-vivado-design-methodology/Constraining-Asynchronous-Clock-Groups-and-Clock-Domain-Crossings?contentId=MtXlcXgs6qk59KTNBJaDXw)。
3. **预约时间与数据到达分离。** 提前发送 `{session, event_id, target_time, action}`，接收确认后在本地比较器到点触发；超时/迟到拒绝；物理外部输出由参考时钟域负责。工作域的处理完成延迟可以变化，但结果必须在预约 deadline 前就绪。这是本轮候选设计，不是外部来源声称的性能。
4. **Source-synchronous 数据链路** 同时转发时钟与数据，在接收域捕获后进入 FIFO；上升/下降沿、输入延迟、线缆预算、训练、CRC、序号、会话和反压都要设计。公共参考并不取消数据链路的 CDC。现有逻辑流水线不包含电气 PHY、序列化、CRC 或真实线缆。
5. **PTP 对逻辑时钟有用。** IEEE 1588-2019 对应 PTP v2.1；精度取决于硬件时间戳位置、链路不对称、交换机/PHY、振荡器与伺服。不能把软件收包时间或协议 offset 当作物理输出边沿精度。[IEEE 工作组](https://sagroups.ieee.org/1588/2020/08/27/what-is-the-current-version-of-ptp/)。
6. **White Rabbit 不只是网络协议。** 参考其频率传递、细相位测量和链路校准思路。现有 Z010/Z020 CLG400 不具备可直接复用常见 WR GTP/GTX 工程的高速收发器；外部 PHY/时钟恢复/精密相位测量会增加硬件和移植范围。[AMD DS190 v1.11.1，表2](https://docs.amd.com/v/u/en-US/ds190-Zynq-7000-Overview)，[WR 官方项目](https://ohwr.org/projects/wr-cores/)。不能从具备 RJ45 推断现有板已经支持 WR。

## 候选频率合法性

采用真实 `MMCME2_BASE` + BUFG：FIN=50 MHz、DIVCLK=1、MULT=18、VCO=900 MHz、输出除数18/9/6，对应50/100/150 MHz。不是在 RTL 中用普通计数器组合输出时钟。本轮 UNISIM 实际运行验证输出周期，两个目标的综合/布线及 DRC 检查验证该配置的器件合法性。

器件限制正式来源为 [DS187 v1.21, 2020-12-01](https://docs.amd.com/v/u/en-US/ds187-XC7Z010-XC7Z020-Data-Sheet)。原先猜测的 `amd.com/content/dam/...` 直链不可读取，已改为 AMD 文档门户，不把失败链接当已读取的数据页。频率可实现不代表所有用户逻辑都能在150 MHz闭合，更不代表板间相位确定。

## 工具与验证选择

实际环境：Windows、PowerShell7.6.5、Python3.10.11、Vivado/XSIM2025.2 Build6299465；Synthesis 许可证通过真实最小综合检查。Verilator/Icarus/Yosys 未在 PATH 找到；本轮没有必要安装第二个 RTL 工具。Python 独立整数模型验证数据结果，Fraction 模型验证 ppm 漂移，二次独立运行检查可重复性。PDF 按技能使用隔离 PyMuPDF 读取，未调用 CAD，不生产原理图/PCB。

## 已有技术和候选创新边界

公共参考+SYNC、时间计数器、预约事件、CDC FIFO、延迟校准和 PTP 都是成熟技术。可形成工程特色的是：四固定通道/任意启用数、与管理板解耦、统一时间契约、显式故障隔离和可重放证据。**RESEARCH_NOVELTY_NOT_CONFIRMED**；当前没有文献比较和消融数据支撑论文级新算法或“首创同步系统”。若以竞赛/论文立项，须先定义最近工作、误差预算、成本/资源收益及独立实测。

原始网页与 API 返回快照位于 `source_extracts/web_batch*.txt`、`*_metadata.json` 和 `github_*.txt`；其中搜索结果含不采用的非一手链接，结论只采用本报告引用的原始厂商/项目材料。
