# 证据索引

日期：2026-11-01。以最终选定 `finalE` / `finalF` 为有效仿真基线，早期结果和失败全部保留。

| ID | 路径 | 支持的结论/限制 |
|---|---|---|
| ENV01 | `environment/source_manifest.json` | 三附件+用户任务的绝对来源、大小、SHA-256，PDF16+35页 |
| ENV02 | `environment/pip_install.log`、`vivado_probe.txt` | 隔离依赖和真实工具版本；无全局包安装 |
| ENV03 | `environment/probe_vivado_attempt2.log`、`pins_*.tsv` | 两Part实际最小综合及专用时钟球位数据库；不能证明PCB连通 |
| SIM01 | `simulation_logs/finalE/results.json`、`finalF/results.json` | 19例×2轮PASS的完整配置、Seed、Hash和log路径 |
| SIM02 | `simulation_logs/finalE/tb_sync_4_seed1/` | 四节点延迟、时间、事件/失锁/丢钟/复位/回绕等逻辑断言 |
| SIM03 | `simulation_logs/finalE/tb_pipeline_seed*_gap*/` | 预约启动→采样时间戳→CDC→算术→输出、两档速率/背压及故障session |
| SIM04 | `simulation_logs/finalE/tb_mmcm_seed1/` | 厂商UNISIM参数/周期/reset-relock模型，不是实物PLL |
| SIM05 | `simulation_logs/reference_model/results.json`、`drift.csv` | ppm exact模型、短时边沿交叉核对、假设校准与伺服；模型假设明确 |
| SIM06 | `simulation_logs/reproducibility.json`、`verify_evidence.log` | 19对Trace/规范化行Hash、2443帧Python独立解码、原附件Hash复核 |
| WAVE | `waveforms/finalE_*.vcd`、`finalF_*.vcd` | 实际波形，unpacked数据另以CSV保存；不是电气模拟波形 |
| SYN01 | `resource_reports/xc7z010clg400-1_routed.rpt`、`xc7z020clg400-2_routed.rpt` | 每节点候选601LUT/1365FF等；非完整业务系统 |
| STA01 | `timing_reports/<part>/timing_summary_routed.rpt` | OOC虚拟接口下setup/hold正裕量，TNS/THS0；board STA仍NOT_VERIFIED |
| CDC01 | `timing_reports/<part>/cdc_routed.rpt` | 每Part9条Critical、5条Warning、1条Info，状态REVISE |
| STA02 | `timing_reports/<part>/clock_interaction_routed.rpt`、`check_timing.rpt`、`drc_routed.rpt`、`route_status.rpt` | 时钟交互/约束/DRC/路由；保留独立monitor和OOC端口边界 |
| PIN01 | `timing_reports/xc7z010clg400-1_pin_probe/`、`xc7z020clg400-2_pin_probe/` | H16/U14专用输入实际布线；输出WNS负值，**STA FAIL** |
| DCP | `timing_reports/<part>/eval_node_routed.dcp`、`<part>_pin_probe/pin_route.dcp` | 可打开检查的实际实现，无bitstream |
| BUILD | `environment/build_ooc_final.log/jou`、`pin_routing.log/jou`及launcher | 命令与exit结果；工具成功完成不等于所有报告PASS |
| BASE | `simulation_logs/finalA`、`finalB`、`timing_reports/baseline_before_fault_gate` | 早期16例/安全门控前基线，不能替代最终结果 |
| FAIL | `FAILURE_AND_RCA.md`及`simulation_logs/attempt*`、`runA/B/C`、`finalC`、环境初次失败 | 保留原因、原始错误与修正；未削弱断言 |
| REPLAY | `environment/replay_wrapper.log` | 整体交付脚本在新目录的真实重放结果，详见DELIVERY_AUDIT.json |
| SEAL | `ARTIFACT_MANIFEST.json`、`DELIVERY_AUDIT.json` | 最终交付文件Hash、所需文件、原附件不变、结构/敏感字段扫描 |

`<part>`是上述两个候选器件目录，索引表中的通配符是导航形式，不是声称每个通配符字符串都是实际文件。精确文件清单及Hash由ARTIFACT_MANIFEST.json给出。

全部网页/公开项目快照及附件提取在 `../research/source_extracts/`。没有实板、示波器、SI、BER、温漂、功耗、制造或生产证据。
