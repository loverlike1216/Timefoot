# 风险登记

日期：2026-11-01。严重度是对后续集成影响的评估，不表示本轮发生了实物损坏。

| Risk ID | Severity | Trigger | Impact | Evidence | Mitigation | Validation Required |
|---|---|---|---|---|---|---|
| R01 | CRITICAL | 外部源并接N18/X5或U18/X3 | 输出争用、损坏 | 板卡审查表S0/S2 | 用另一个已确认空闲CC P脚，或正式设计可隔离选择器 | 通断、波形、驱动源清单 |
| R02 | CRITICAL | DATA针序/VCCO/扩展板批次错误 | 5V进IO、反灌、外设争用 | S2无完整DATA表 | 原理图+实物逐针审查，禁整排互插 | 四板物理签核 |
| R03 | HIGH | 多板SYNC落到不同捕获边界/重锁相位变化 | 整周期错位、重复/错时事件 | RTL0/2/5/10ns、数学20ns反例 | 捕获窗口、epoch握手、训练/校准、每次失锁新会话 | 反复上电/复位+仪器测量 |
| R04 | HIGH | 复位/异步监测/组合门控CDC未闭合 | 亚稳、假valid、故障后旧事件 | 最终CDC：2×CDC1、6×CDC7、1×CDC10 | 标准复位释放、寄存后单bit crossing、审阅XPM/握手、精确约束 | CDC/RDC无未裁决严重项+异步相位测试 |
| R05 | HIGH | 把逻辑FIFO当跨板物理接口 | 吞吐/时序/误码完全不匹配 | pipeline是128bit虚拟链路 | 序列化/PHY、源同步、CRC/session/credit、真实I/O延迟 | 链路TB、BER/回环、满载与插拔测试 |
| R06 | HIGH | reference丢失且监测时钟也停止/采样混叠 | 故障不可见、悬挂输出 | 独立100MHz监测模型；真实来源未签核 | 保留独立本地源，验证频率比、分频心跳/看门狗 | 物理断钟/监测源独立性/延迟上界 |
| R07 | HIGH | 长线CMOS/终端错误/地电位超范围 | 反射、多次过零、输入损坏 | TI器件数据手册；33Ω不是电平保护 | 正确LVDS接收、回流/终端、SI设计 | 过冲/眼图/共模/功率及断电输入 |
| R08 | HIGH | OOC正WNS被解释为系统闭合 | 错误项目批准/精度承诺 | 虚拟端口、无PARTPIN_LOCS/HD.CLK_SRC警告 | 只承认局部资源/路径；最终集成重新约束 | 最终board top、IO、CDC和所有角STA |
| R09 | MEDIUM | 晚加入节点用当前ticks直接当epoch | 激活但逻辑时间有固定滞后 | bench明确只检隔离/恢复，不检晚加入精度 | 约定未来epoch采样时刻与完整握手 | late-join相同epoch/事件ID断言 |
| R10 | MEDIUM | FIFO局部复位/丢链后继续旧序号 | 跨会话残留/无声丢帧 | bench全局flush及中止计数 | 明确quiesce/flush/abort/restart，局部复位协议 | 故障时账目闭合+新会话无旧包 |
| R11 | MEDIUM | FPGA1源速率长期超最慢链路/消费速率 | 缓存耗尽、deadline错过 | 背压/满空覆盖与两档输入间隔 | 带宽和最大burst预算，credit，超时拒绝事件 | 饱和/过载/长突发、量化队列延迟 |
| R12 | MEDIUM | 独立XO丢同步后继续无限holdover | ppm累计漂移超阈值 | ±10/20/50ppm exact模型 | 按漂移预算限制holdover，单调slew，报告失锁 | 不对称/温漂/丢包伺服试验 |
| R13 | MEDIUM | AX管理移除但独立板只有XO | 没有SYNC/epoch/会话控制 | 架构B完整性审查 | 标准可替换控制接口及独立控制器 | 完全不接AX的启动/预约/重同步 |
| R14 | MEDIUM | 开源顶层许可或旧库维护状态误读 | 移植/发布受限、停更依赖 | LICENSE及实时API快照 | 固定commit并逐组件审核；本轮不导入 | 依赖/许可清单 |
| R15 | HIGH | 没有合适仪器却要求真实纳秒指标 | 不能区分模型与实际误差 | 仪器/PCB/实板测试全部NOT_CHECKED | 先确定可测指标和仪器 | 四路同时测量、校准基准与误差预算 |

**R04并未因仿真PASS而关闭；R01/R02未因器件管脚路由PASS而关闭。**
