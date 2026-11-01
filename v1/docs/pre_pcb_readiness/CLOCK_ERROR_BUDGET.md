# 时间同步与长期误差预算

## 三个不同结论

1. RTL中在统一Session/Apply之后，各节点timebase同tick，预约事件执行时间等于target；通过真实RTL、多节点业务和独立trace检查。
2. 同一公共源的节点不产生独立XO频率差累积的相对tick漂移，前提是没有漏边沿、相位跨采样窗或失锁；该结论有短期逐边沿模型和长时解析外推。
3. 板间PAD边沿偏差、与UTC的绝对偏差、温漂/抖动/电源干扰尚未实测，不属于上述RTL PASS。

## 独立模型

运行`python -B v1/verification/clock_budget_model.py`，输出`prepcb_analysis/clock_budget.json`。整数ps模型枚举4个clock绝对延迟×4个SYNC相对延迟=16条件，每个逐边沿模拟5000tick，含64bit计数wrap；全部trace Hash相同。再以mod64闭式公式独立检查枚举中的第0/1/1999/2000/4999个点。负例SYNC相对延迟11ns真实产生1周期Apply slip，模型没有把失败窗口抹去。

1s/1h/24h/30d为**ANALYTICAL_COMMON_EDGE_COUNT**，不是模拟数万亿个RTL周期，也不是24h实物运行。每个节点接收相同边沿数时相对tick drift=0；公共XO±50ppm造成24h相对理想秒±4.32s、30d±129.6s。aging等额外项另计；±50ppm为候选订货选项，不能当实板已测频率。模型不含亚稳态概率、温度噪声或BER。

## CLOCK / SYNC相对预算

| 项目 | 预设计保守预算 | 来源/性质 |
|---|---:|---|
| CLOCK与SYNC分别通过两颗fanout的rising器差 | ±1.3ns | SN65LVDS105 rising1.7..3ns范围推导；非实测 |
| 两颗接收器差 | ±2.2ns | SN65LVDT2范围1.4..3.6ns推导 |
| 相对线缆传播差 | ±0.5ns | 待匹配/测量的设计保留 |
| 相对板内传播差 | ±0.5ns | 待布局/测量的设计保留 |
| 抖动/额外保留 | ±0.5ns | 候选保留，不是datasheet保证 |
| 合计保守相对不确定度 | ±5.0ns | 不能直接满足当前SYNC输入0.5..3ns范围 |

参考周期20ns，SYNC在下降沿发出，理想上有10ns采样半窗；实际FPGA输入setup/hold、BUF路径和资格信号路径由STA进一步限制。不能将“±5ns小于10ns”直接称为满足此Profile。下一阶段必须匹配接收路径/选更紧matched receiver或提供可验证相位补偿，把**实际到达PAD范围**压入0.5..3ns，并测PVT余量。否则qualification必须为0，禁止RUN。此问题是硬件冻结前条件，当前有限预设计交付显式保留。

## 事件误差分解

节点间实际event PAD偏差包括CLOCK分发channel skew、接收器器差、线缆/板路径差、FPGA clock insertion和clock-to-output差。仿真TB中的0/0.6/1.2/1.8ns参考偏移及marker延迟是指定数字输入，不是实际copper模型；其<=3ns事件偏差只证明该数字场景。真实边沿偏差必须使用同一仪器参考面测量，并保留触发/探头/校准记录。

参考丢失后time_valid和RUN清除，长期累计有效时间在新Session重新定义。不得跨故障间隙把旧Session和新Epoch拼成“连续绝对时间”。
