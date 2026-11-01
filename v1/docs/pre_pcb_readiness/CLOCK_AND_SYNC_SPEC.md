# CLOCK / SYNC / Session契约

## 数字规则

公共参考50MHz、20ns周期；默认工作频率由同一参考派生50/100/150/50MHz。monitor时钟必须独立且持续运行。tf_clock_manager以16个reference周期一次toggle心跳检测存在性，monitor timeout=96周期；还必须等待MMCM locked。停止reference后由monitor产生fault异步断言各域reset，释放只在相应域有时钟时同步完成。

本地reset只清心跳分频count，保留heartbeat相位，避免reset在toggle后1周期到来时制造20ns短脉冲；先前Seed17实际XPM报错证据保留在prepcb_system。没有关闭SIM_ASSERT_CHK。

## Epoch起算与优先级

manager在NODE_DISCOVERY的参考上升沿将`apply_at = old manager_ticks + LEAD_TICKS`，默认1024。不是“从用户写start算1024”，也不是收到最后Prepared才开始倒数。预留量为20.48us，包含节点Prepare握手时间。

EPOCH_ALIGN中，clock_ready失效、timeout、apply_at已过或剩余<=8tick优先于Prepared全部到达；迟到Prepared不能让状态跳到SYNC_VERIFY。Prepared必须在这个8tick安全边界之前已被manager同步观察。参数LEAD>16、TIMEOUT>LEAD且<=65535。

SYNC_VERIFY：当旧ticks==apply_at，marker_request置1，并在随后下降沿输出一个reference周期SYNC。节点在满足输入setup/hold的下一上升沿将staged_epoch写入timestamp，time_valid/applied置1；由此定义Epoch是**节点Apply捕获沿的值**。manager等待marker确实已发且since_apply>8、所有applied后进入READY/RUNNING。不要把apply_at的数字直接当作节点timebase值。

差值使用64bit模运算与半区间符号检查，要求所有有效提前量<2^63。tb_sync_controller从FFFFFFFFFFFFFFC0附近开始，实际跨wrap；marker只发一次，迟到Prepared和故障优先级均有断言。

## 资格与参考面

sync_marker是参考同步输入，不通过任意2FF后声称确定同拍。marker_qualified只可由真实管理器在参考/时钟分配、Session准备和相位窗口满足时拉高。RTL管脚输入没有常置1。异步reset只保证安全，不保证统一Apply边沿；条件不满足必须撤销资格、停止RUN并新Session重同步。

数字STA当前要求SYNC/资格在reference下降沿之后0.5..3ns到达节点PAD。这个范围是有条件的接收接口要求，不是已测的CLOCK/SYNC分发器性能。数据手册保守器差估计可能超出此紧窗口；下一硬件阶段必须选择匹配路径/相位补偿并实测，不能在电气资料缺口时宣称自然满足。

物理事件来自reference scheduler输出；目标时间是tick，不是UTC。各板相同tick值和同一次事件的PAD边沿偏差是两个指标；前者由RTL回归证明，后者仅做条件预算，尚未板间测量。

## 四路时钟/使能候选

候选两颗SN65LVDS105分别分发CLOCK和SYNC，各自四路EN可对应节点mask。两端外置LVDS接收器转3.3V单端，FPGA使用普通已核实CCIO参考输入，不直接假定DATA口支持原生LVDS。EN切换按安全顺序：撤销RUN/资格→中止旧Session→保持节点安全态→改变使能→等待参考/MMCM稳定→新Session Prepare/Apply→验证→RUN。不能把EN当无毛刺动态时钟切换。

LMK00304作为低附加抖动对照：四路差分输出为两组，每组两路；并非四路独立OE。若采用它还需实现独立节点使能机制，不能凭型号“4-output”满足四路独立使能。选型和电气限制见COMPONENT_SELECTION_AND_BOM.md。
