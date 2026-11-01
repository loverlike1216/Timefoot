# 吞吐、延迟与容量实测

本表来自实际XSIM RTL、VCD和独立Python模型，不是PCB吞吐实测。默认208bit frame只有32bit业务payload；Session/Sequence/Timestamp/Length/CRC占其余176bit。

## 链路理论上限与实测

| Profile | 原始bitrate | 无间隙frame极限 | 无间隙payload极限 | 实测空载下游24帧间隔 | 实测Link payload速率 |
|---|---:|---:|---:|---:|---:|
| 4bit SDR50 | 200Mbit/s | 961538frame/s | 30.769Mbit/s | 1200ns，即833333frame/s | 26.667Mbit/s |
| 8bit SDR50 | 400Mbit/s | 1923077frame/s | 61.538Mbit/s | 680ns，即1470588frame/s | 47.059Mbit/s |
| 4bit SDR25 参数验证 | 100Mbit/s | 480769frame/s | 15.385Mbit/s | 2400ns，即416667frame/s | 13.333Mbit/s |

无间隙极限只计算208bit/26bytes，不含credit低→高确认和接收交付。实测包含完整frame credit协议的8个link周期左右帧间隙，不能用200Mbit/s当payload/应用吞吐。证据`prepcb_analysis/link_measurements.json`及prepcb_link03 VCD；ODDR功能模型的forwarded rising在link falling后100ps，观测launch→capture10.1ns（25MHz为20.1ns），不把UNISIM 100ps当silicon tCO。

## 完整业务与拥塞

串行管理的真实physical node（work150MHz，reference50MHz，4bit50MHz，64帧、无故意output block）：source sample_count至sink got的VCD观测延迟7.2501..10.7901us；首末输出之间280898.88frame/s，业务payload8.9888Mbit/s。首末采集间285403.64frame/s包含开始阶段缓存突发，不能把它当长时稳态上限。源CRC在50MHz参考域逐bit运行176bit并有握手开销，是当前业务吞吐的重要瓶颈；扩大链路位宽不会按比例提高算法吞吐。

| 系统节点数 | Seeds | 故意150us堵塞下capture→最终sink延迟范围 | 恢复排空速率范围 |
|---|---|---:|---:|
| 1 | 1/17/2026 | 88.429..151.469us | 527027..528885frame/s |
| 2 | 1/17/2026 | 63.630..151.990us | 767717..797220frame/s |
| 3 | 1/17/2026 | 63.631..151.991us | 767717..797220frame/s |
| 4 | 1/17/2026 | 88.432..151.472us | 527027..528885frame/s |

上述是40帧/phase的缓存排空速率，部分CRC工作已经在堵塞期间完成，**不等于无限流稳态应用吞吐**。4节点8bit seed1对照240帧、堵塞场景延迟87.392..150.952us，排空约536009..536451frame/s。没有因性能数字不好看而改CRC算法或绕开新适配器。

## 容量与中止

TX一个input_slot+16深度XPM FIFO，RX整帧预留槽+核心16深度FIFO。测试实际触发满/反压，读侧level最大17与FWFT/跨域缓存语义有关，不能当写侧可超容量写入的许可。恒定blocked60us的链路测试成功交付64帧，随后8个已接受/在途帧被flush，24个新帧恢复；典型accepted96、wire_sent88、aborted8，满足计数对账。RX部分帧中止也有独立计数。

无自主重传/包缓存可靠传输层，不保证CRC错误后的单包重发；错误导致会话中止，新Session由上层重新执行任务。持续断线的接收帧由上层监督/超时恢复，不在raw framer内推测长度或继续旧会话。

## 资源对照

两个宽度均已在Z010/Z020完整实现，实际LUT/FF/BRAM和STA见各profile utilization.rpt及PRE_PCB_READINESS_REPORT。4bit节省8根数据GPIO和回流/布线负担，当前逐bit CRC源速率不要求8bit，故推荐4bit50作为首个硬件候选。8bit作为容量扩展对照保留，不声称已在EBAZ线缆上运行。
