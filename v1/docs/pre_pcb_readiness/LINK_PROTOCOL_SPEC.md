# TIMEFOOT v1 SDR板间逻辑协议

协议标识：TF-SDR-FRAME-CREDIT-1。两端必须使用相同LANES、FRAME_W和此协议；无自动协商。推荐4bit SDR50MHz；8bit50MHz为对照。25MHz仅用于可参数化单元验证，不代替50MHz验收。

## 帧与传输

默认FRAME_W=208bit（26bytes），字段按MSB先行，不增加/删除内部字段：

| bit | 字段 |
|---|---|
| 207:176 | Session32 |
| 175:144 | Sequence32 |
| 143:80 | Source Timestamp64 |
| 79:64 | Length16，当前业务为4bytes |
| 63:32 | Payload32 |
| 31:0 | CRC32 |

CRC覆盖前176bit；多项式04C11DB7、init FFFFFFFF、非反射、xorout FFFFFFFF，BZIP2校验向量`123456789`=FC891918。参数化核心的BODY_W随payload改变；当前物理top及回归固定208，扩大payload需要同时修改FRAME_W、接收CRC/Length契约并重跑，不能宣称任意payload已签核。

每frame为52个4bit或26个8bit beat。TX在link_clk上升沿寄存DATA/VALID/SOF；ODDR输出的forwarded clock在link_clk下降沿上升，接收端在forwarded rising capture。第一个有效beat SOF=1，其余SOF=0、VALID连续为1；空闲VALID=SOF=0。IOB捕获后下一拍处理重组，不将未校验payload直接交任务。

## FRAME CREDIT

返回的`ready`管脚表示**一整帧的预留容量**，不是逐beat ready。RX只有在没有活动帧、没有待交帧、输入空闲时授予credit。源同步器观察到credit=1后可以连续发送整个frame；RX在SOF捕获时撤销credit，但接收已经授权的所有后续beat。RX完整frame进入下游核心后才重新授予credit。

TX开始一帧后必须先观察credit低，再观察高，才允许开始下一帧。返回credit经过3级XPM_SINGLE，其延迟只增加帧间隙，不形成半周期组合往返路径。接收端预留整帧容量保证已授权帧不因credit传播延迟溢出。这是初期逐beat组合ready原型失败后的结构性修复，失败证据adapter01/02保留。

内部208bit `valid && !ready`时必须保持valid和frame稳定。该断言在tb_link覆盖。管脚层已授权帧期间credit=0不能解释成stall；若接收端需要中止，应通过session abort/flush，两端重新初始化，不得只截断credit来停止当前帧。

## 容量、错误、中止

TX入口1保持槽+16深度异步FIFO；序列化使用FWFT头部，最后beat才pop。入口容量与读域level不完全同时更新；实测max level=17包含XPM读侧缓存，不把它解释为第17个可任意写入的存储位置。以in_ready/full进行域内写入判定。

RX有一个完整208bit重组/待交槽；核心接收FIFO16深度另计。每个frame通过core的CRC、Session、Sequence、Length后才进入任务。失配触发会话fault；不能用物理重组成功代替这些检查。RX没有自动猜测包边界；非法SOF/无SOF有效beat置sticky framing error，要求flush恢复。持续VALID=0的截断帧依赖上层故障/会话超时中止，本层不提供自主线缆断开超时检测。

计数语义：TX accepted=内部frame握手次数；wire_sent=最后beat已经发到PAD的次数，**不是远端CRC验收次数**。TX aborted在flush后停止新写入，等待128个link周期及coherent accepted快照收敛，以`accepted - wire_sent`累计债务对账；读stats_valid=1后使用。RX started=获得授权的SOF；forwarded=重组frame被核心接收；aborted=部分/待交帧被flush或非法帧打断；framing_errors独立累计。重复flush不重复记部分帧。

## 跨板复位契约

一条链路两端必须共同进入flush，并在两端时钟已运行、credit归零、FIFO reset busy释放后进入新Session。不能在只有RX复位时继续向其发送旧帧。全局root reset清统计；session flush保留累计统计。任一端时钟停转时，远端必须撤销RUN/资格并协调全链路恢复；coherent快照及128周期ledger只在相关时钟恢复后保证完成。

线缆延迟模型只是数字延迟；不模拟亚稳态模拟概率、反射、串扰、地电位差或BER。实际板卡仅在TIMING_CONSTRAINT_SPEC及HARDWARE_INTERFACE_REQUIREMENTS的条件满足后才可连接。
