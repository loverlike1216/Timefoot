# 完整数字接口Profile与STA

## 签核范围

目标`xc7z010clg400-1`、`xc7z020clg400-2`，Vivado2025.2 Build6299465。top=`tf_physical_node_top`，**完整综合/place/phys_opt/route，非OOC**。对应旧tf_node_top的frame、管理/事件/诊断功能均经过真实适配器/CSR保留。旧宽接口负STA保留在closure_node，不能把旧报告替换成新top结果。

输入约束：`adapter_clocks.xdc`在synth_design之前读取；`adapter_interfaces.xdc`在综合后读边界延迟。候选封装引脚在implement_adapter.tcl，以连接器候选为基础；没有CLOCK_DEDICATED_ROUTE FALSE，没有新增blanket false path或clock_groups。完整复现命令见VALIDATION_AND_REPRODUCTION.md。

## 边沿和预算（ns）

| 端口/时钟 | Launch / Capture | min | max | 含义 |
|---|---|---:|---:|---|
| reference / monitor / rx | primary50MHz，period20 | — | — | monitor/RX独立域关系由实际CDC处理 |
| control | primary25MHz，period40 | — | — | 外部自由运行管理时钟 |
| work | MMCM参考派生150MHz默认 | — | — | 四节点业务频率在系统仿真覆盖；单physical profile选150MHz |
| tx_clock | ODDR，relative reference反相 | — | — | TX数据在reference rising launch，接收在forwarded rising capture |
| rx_data/valid/sof input | rx falling launch → rising capture | -2.0 | 3.0 | 发送PAD相对clock偏移[-1,2]+板间相对skew[-1,1] |
| tx_data/valid/sof output | reference rising → tx rising中心采样 | -1.5 | 2.0 | 外部接收setup+走线差2ns，hold/差分保留1.5ns |
| rx_ready output | rx rising → held credit，整周期边界 | -1.5 | 2.0 | 不是half-cycle beat-ready，peer XPM同步 |
| tx_ready input | 仅首级XPM同步；held credit | 1.0 | 5.0 | 传输偏移示例；不承诺逐beat往返，也不据此断言物理线缆绝对长度 |
| CS/MOSI input | control falling → rising | 0.5 | 3.0 | 管理主机必须满足 |
| MISO/ready output | control rising → falling | -1.5 | 2.0 | 半周期20ns预算 |
| marker/qualified input | reference falling → rising | 0.5 | 3.0 | **硬件资格条件**，不是分发器已测保证 |
| arst input | 参考下降沿假定；真实异步复位源 | 0.5 | 3.0 | reset宏本身有scoped异步断言例外，各域同步释放 |
| event/fault output | reference rising，下一外部边界 | -1.5 | 2.0 | 输出寄存；事件实际PAD传播另外计入同步误差 |

负output min表达接收hold要求/允许路径差，不能解释为负物理传播。RX min从原型-1收紧为-2，以容许发送端相对偏移为负，扩大最坏hold检查；50MHz未降频。CRC和Session验证路径不从时序中删除。

工具使用实际speed file、默认system jitter=0.071ns以及MMCM模型；最坏工作路径示例Clock Uncertainty=0.084ns，来自工具jitter/phase error。没有把零uncertainty当板级保证；外部XO/分发/电源jitter和实际PVT还需在未来硬件Profile中输入重签。routed datasheet.rpt记录PAD clock-to-out/接收setup/hold，可核对双方接口；不能跨不相关PVT将一个fast clock delay和另一个slow data delay当作同一时刻的物理skew。

## 有效结果

冻结源Commit：45aa523ddb4151157672df1ee3c5bb483be3edb0。

| Profile | Part | WNS | WHS | WPWS |
|---|---|---:|---:|---:|
| 4bit SDR50 完整节点 | Z010 -1 | +0.468 | +0.009 | +2.833 |
| 4bit SDR50 完整节点 | Z020 -2 | +0.925 | +0.028 | +2.833 |
| 8bit SDR50 完整节点 | Z010 -1 | +0.313 | +0.016 | +2.833 |
| 8bit SDR50 完整节点 | Z020 -2 | +0.752 | +0.036 | +2.833 |

所有机器检查见`prepcb_analysis/stage_audit.json`。报告路径`prepcb_impl4_03/<part>/`与`prepcb_impl8_03/<part>/`；四实现均已完成，无尚在运行的签核进程。

4bit Z010资源：3546 LUT、7961 register、9 BRAM tile、0 DSP；Z020：3545 LUT、7961 register、9 BRAM、0 DSP。不是四节点全部装入一颗FPGA的资源，也不是功耗实测。

## XPM约束与覆盖

根因详见`v1/docs/XPM_CDC_CONSTRAINT_AUDIT.md`。Vivado在综合处理XPM宏时若clock尚未读入，厂商Tcl采用1000/1001ns fallback；之后读clock不会自动重建这些已输出的exception。受控early/late实验使用相同旧RTL，证明是读取顺序而不是随意替换常数。

新Profile Gray路径source clock周期6.667/20/40ns，max_delay=源周期；bus_skew=min(源周期,目的周期)，由厂商宏自动生成。40ns属于25MHz管理FIFO，60ns handshake held-data预算属于另一协议，不能当作Gray1000ns疑点复发。routed bus_skew真实检查、端点、例外覆盖见stage_audit及原rpt。没有手工按数字全局替换。

check_timing无no_clock、unconstrained_internal_endpoints、no_input_delay、partial I/O delay；no_output_delay唯一项是已经定义generated_clock的tx_clock（LOW类别），不伪装成全零。methodology的TIMING-18逐项涉及只在指定边沿launch的I/O、async arst多域、转发clock；必须结合完整min/max约束和routed路径阅读，不能删warning后宣布干净。

CDC Critical=0不等于全报告零warning。CDC-15来自厂商XPM的受enable控制RAM/FIFO数据路径；其它源有3级同步器、reset synchronizer或完整handshake。DRC保留RTSTAT-10（无负载统计输出）和ZPS7-1（PL验证top无PS7）；后者在生成真正Zynq启动系统前必须解决。本阶段没有bitstream/上板交付。未使用独立专有RDC工具，RDC证据为复位结构、XPM仿真、恢复/flush断言、REQP-1839检查和Vivado DRC，不能冒称独立RDC signoff。

## 旧失败与修复关系

closure_node Z010 -1.255/-0.862、Z020 -0.684/-0.931保留。adapter01暴露半周期ready组合路径及异步mask到BRAM EN；adapter02终止mask到同步holding slot、改整帧credit，但旧逐beat的rx_ready半周期契约仍失败；adapter03证明新协议后，最终03标签使用更保守RX hold输入和连接器引脚完成签核。所有这些为原型对照，不把不同源码/中止运行混成最终证据。
