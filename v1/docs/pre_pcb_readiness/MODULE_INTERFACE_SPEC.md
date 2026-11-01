# 数字管脚与管理寄存器规范

## 物理节点端口

top=`tf_physical_node_top`，LANES=4或8，WORK_DIV=6默认150MHz。ref_in=50MHz，monitor_in=独立50MHz，rx_clock=前级转发50MHz，control_clock=外部自由运行25MHz。四个时钟均进入BUFG；RX并非由本地业务时钟直接采样。

| 方向 | 信号 | 契约 |
|---|---|---|
| in | arst | 全局安全复位；异步断言，各域同步释放 |
| in | sync_marker / marker_qualified | SYNC参考下降沿发出；资格由外部实际监督状态驱动 |
| out | event_out | reference域预约执行脉冲；无额外串行化或业务域延迟 |
| out | fault_out | 参考域寄存故障，失锁复位可异步置安全态；参考停转时继续为故障 |
| out / in | tx_clock,tx_data[LANES-1:0],tx_valid,tx_sof / tx_ready | 转发SDR及返回整帧credit |
| in / out | rx_clock,rx_data,rx_valid,rx_sof / rx_ready | 同协议接收及credit |
| in / out | control_clock,control_cs_n,control_mosi / control_miso,control_ready | 独立串行管理；不是AXI或通用SPI兼容声明 |

旧core208bit帧、事件ID/目标/取消、Session/Epoch、stage/source配置、同步有效性、执行计数、错误/队列/吞吐诊断均通过数据适配器或真实CSR后端保留。没有把旧失败端口删掉来获得STA。

## 串行传输

每次CS低发送48bit，MSB first：`opcode[7:0], address[7:0], data[31:0]`，opcode01写、02读。host在control falling发MOSI，node rising采样；MISO在node rising更新、host falling采样。CS高至少2个control周期，control时钟必须持续运行以完成跨域FIFO。

回复在后续事务移出：`flags[7:0], address[7:0], rdata[31:0]`，flags bit7有效、bit6错误。当前事务移出的回复对应之前命令，不应当按当前地址归属。允许一次命令后轮询回复；TB命令间等待1us，不能把任意无间隙命令洪泛声明为已验证。control_ready和protocol_errors用于识别入口溢出；FIFO满命令不能静默当作成功。未知opcode/地址返回error。

## 节点CSR（字节地址，32bit）

| 地址 | R/W | 内容 |
|---|---|---|
| 00 | RW | stage_mask[2:0]，source_role[3]；RUN时禁止改 |
| 04 | W | bit0 prepare、bit1 abort、bit2 run_set、bit3 run_clear；不要组合冲突命令 |
| 10/14 | RW | staged Epoch低/高32；RUN时禁止改 |
| 18 | RW | staged Session；RUN时禁止改 |
| 20/24 | W | event ID / Session |
| 28/2c | W | event target低/高32 |
| 30 | W | bit0 submit；未ready或未RUN返回总线error，避免阻塞后续abort |
| 34/38 | W | cancel ID / cancel_all bit0 |
| 40 | R | bit0 clock_ready,1 prepared,2 applied,3 time_valid,4 run_request,5 fault,6 marker_qualified,7 event_ready |
| 44 | R | active Session |
| 48/4c | R | timestamp低/高；先读48同时冻结高半 |
| 50 | R | 最近scheduler错误或80=submit未ready；有效prepare清除 |
| 54 | R | executed event ID |
| 58/5c | R | executed time低/高；先读58冻结高半 |
| 60/64/68 | R | executed / event aborted / event rejected累计 |
| 70 | R | 串行协议错误coherent快照 |
| 80 | R | core delivered；同时冻结work128 |
| 84 | R | 冻结的{26zero,core FIFO full,level[4:0]} |
| 88 | R | 冻结的stream error code低4bit |
| 8c | R | 冻结的TX accepted累计 |
| 90/94/98 | R | TX aborted / wire_sent / stats_valid bit0；先读90冻结整个96bit |
| a0/a4/a8/ac | R | RX started / forwarded / aborted / framing_errors；先读a0冻结128bit |

多位跨域状态使用XPM handshake held-data快照，不逐bit同步。寄存器读首字冻结完整快照，后续字不随现场变化。快照有延迟，不能作为本周期full/ready组合反馈。

prepare Session必须相对上次已准备Session前进，模32bit差值在(0,2^31)；失锁不会清此防重放记录。全局arst才清生命周期。RUN要求prepared、applied、time_valid、无fault、marker_qualified。失锁/资格丢失清run_request；重新RUN必须新Session+Epoch握手。故障命令不会自动进入新Epoch。

manager的现有CSR布局仍由`tf_control_interface.sv`管理，不能把本节点串行CSR地址直接当作manager地址。跨板管理设备/驱动必须分别实现二者；本阶段提供真实RTL及TB主机，不提供已上板固件。

## 参考完全停转时的管理边界

串行前端仍可在control_clock运行时缓冲命令，但CSR后端使用reference域；参考完全停转期间不能承诺即时返回新CSR结果。外部控制器应直接读取异步置安全态的fault_out、设置命令超时并停止任务，等待参考恢复后再读取CSR/新Session重同步。physical管理测试覆盖的是访问期间撤销qualification（reference仍运行），不能宣称已经覆盖停钟期间的即时CSR读回。
