# 开源项目比较

日期：2026-11-01。只读调研，没有 clone/导入外部 RTL，没有把第三方示例当成本轮测试。

| 项目与实际地址 | 时间/状态 | 许可核查 | 公开平台与证据 | 对现有板的意义 |
|---|---|---|---|---|
| [White Rabbit cores](https://ohwr.org/projects/wr-cores/)，[源仓库](https://gitlab.com/ohwr/project/wr-cores) | 官方项目页列 WRPC5.0 发布2023-12-23；最新源码时间本轮未可靠取到 | LICENSE/COPYING 根路径读取失败；`.ohwr.yaml` 的 BSD-3-Clause 只属于元数据文件，**不能当整套 HDL 许可**；采用前须逐模块核对，UNVERIFIED | 官方 WR 节点/交换机生态；本轮 GitLab top 目录无法可靠读取目标全表，无 EBAZ 已验证证据 | 借鉴校准/时间体系；不是现有板直接可烧写的工程 |
| [Red Pitaya X-Channel](https://redpitaya.readthedocs.io/en/latest/appsFeatures/multichannel/multichannel.html)；[FPGA仓库](https://github.com/RedPitaya/RedPitaya-FPGA) | 文档说明旧 X-Channel 已停用，现有 Click Shield 2.0 路线；RedPitaya主仓库 pushed2026-10-24 | FPGA仓库 LICENSE 为三条款 BSD；具体子模块继续核查 | 文档列 STEMlab125-14/LN/Gen2系列，Zynq7010/7020板型；旧从板需要专门硬件修改。公开三板采集示例；有些精度测量仍待发布 | 证明外部时钟/触发分配的工程成熟性，不证明普通 EBAZ 可直接兼容 |
| [LiteX-WR-NIC](https://github.com/enjoy-digital/litex_wr_nic) | API pushed2026-10-08 | LICENSE 原文两条款 BSD；API只写 Other，已以原文消歧；WR依赖另审 | README列SPEC-A7、CLE215+ XC7A200T、HyVision XC7K70T、Gowin目标；公开 WR/PTM PPS 演示，但绝对精度仍需板/模块校准及仪器独立测量 | 没有本轮平台的直接目标；不可把作者演示迁移成本轮证据 |
| [verilog-ethernet](https://github.com/alexforencich/verilog-ethernet) | pushed2025-02-27；README明确弃用，新开发转taxi | MIT | 有 `ptp_clock`、时间CDC、MAC与cocotb测试，列Arty A7、KC705等多平台；不是现成四板时钟系统 | 可研究时间模块/测试接口；不建议新项目不加评估地绑定停更库 |
| [taxi](https://github.com/fpganinja/taxi) | pushed2026-08-28 | API识别 CERN-OHL-S-2.0；不能沿用旧库MIT假设 | Ethernet/AXI/PCIe SystemVerilog生态；本轮未构建 | 新依赖若采纳需逐文件/商业兼容性复核，不为“免费”自动替换 |
| [OCP Time Card](https://github.com/Time-Appliances-Project/Time-Card) | 原opencomputeproject地址已迁移；API pushed2026-10-27 | README规范部分采用 OWF CLA/OWFa1.0；根 LICENSE 不存在；源码/硬件子目录须分别核查，不能统称Apache/MIT | SOM README列 ALINX AC7100B、AC7200T；主README有Calnex测量与驱动/测试资料。不是facebook/time软件库 | 借鉴失源、holdover、状态与校准；GNSS/OCXO/PCIe超出当前最小范围 |

版本状态字段是 API 的 `pushed_at`，不是发行版发布时间、代码质量认证或CI通过证明。快照保存于 `source_extracts/`。未读取的目标或许可明确标未知；这些项目本轮没有在本机重新构建，公开验证均为作者材料。

许可处理只做工程依赖筛选。后续正式采用时固定 commit、保留著作权/许可证及依赖清单，不能用项目顶层许可证覆盖所有子模块。
