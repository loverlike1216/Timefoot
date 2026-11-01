# 预设计候选BOM与选型依据

2026-11-01检索。仅候选，不冻结、不采购、不制作CAD。库存页面会变化；ACTIVE是生命周期，不等于现货。原始PDF获取URL/Hash见`v1/verification/evidence/pre_pcb_preflight/datasheet_sources.json`，PDF保存在项目内work作本机参考，不把厂商全文复制入仓库。

## 推荐候选与替代

| 功能 / 数量 | 厂家与候选订货号 | 电气与选择理由 | 封装 / 采购观察 | 替代与风险 |
|---|---|---|---|---|
| 公共XO ×1 | Abracon ASE-50.000MHZ-L-C-T | 50MHz、3.3V CMOS，L=-40..85C，C=±50ppm；给两颗LVTTL fanout输入，需核算总负载 | 4pad3.2×2.5mm，MSL1；分销有listing，未锁库存/价格 | 同系列更紧ppm选项须核对温区组合；上电稳定时间、aging及实际jitter仍需确认 |
| CLOCK fanout ×1、SYNC fanout ×1 | TI SN65LVDS105PWR | LVTTL输入、四路独立EN、LVDS输出；3.3V，适合保持SYNC DC状态 | TSSOP16 PW，常规SMT；TI页面ACTIVE但当次显示Out of stock | SOIC16 SN65LVDS105D/DR需再次核库存；SN65LVDS104是差分输入，不能无改动替换 |
| CLOCK/SYNC接收 ×8（四节点各2） | TI SN65LVDT2DBVR | LVDS转单端、内置端接，供电2.4..3.6V，候选3.3V与LVCMOS33匹配 | SOT23-5 DBV，ACTIVE订货列表；实际可供货量未锁定 | SN65LVDS2DBVR+外100ohm，不能双重端接；不同接收器传播差是主要相位预算风险 |
| 3.3V接口电源 ×1 | TI TPS62162DSGR | 固定3.3V/1A、输入3..17V，PG/EN适合受控接口供电；先按5V输入估算 | WSON8 DSG2×2mm，散热焊盘和外电感需正确装配；ACTIVE产品页 | TPS62160DSGR为可调版，需反馈设计；无具体热/PDN/磁性件签核 |
| 信号连接器/线束 | Hirose DF11-20DS-2C作为2mm双排20位线束系列参考 | 电源针留空；信号/回流地逐针接线 | 压接housing，端子另购；厂家目录可查 | 实物EBAZ并未确认是DF11配合件；相同pitch不等于可配合。禁止直接按本型号下单 |
| AX连接器 | 板载2.54mm双排40位J10/J11配对候选 | 以用户原手册pin表为依据 | 配合件高度/键位/朝向UNKNOWN，MPN待实物量测 | 全宽IDC直连会连接5V/3.3V，不能作为通用跨板线束 |
| DATA驱动/接收 | 首版使用FPGA LVCMOS33 IOB，无额外电平转换 | 单点短连接；现有33ohm串阻需纳入路径 | 无新增高速收发器冻结项 | 若SI不满足需外部缓冲并重新预算；不支持5V容忍假设 |
| 保护/测试 | 输入限流/反接/ESD、CLOCK/SYNC/PG/fault/credit测试点 | 分离电源域、防反灌，关键接口可探测 | 具体MPN和值待接口负载/线缆/ESD目标确定，HOLD | 测试点不要形成长stub；本阶段不生成焊盘/制造文件 |

## fanout对照裁决

SN65LVDS105在100ohm/10pF规定条件下：rising传播1.7..3ns，falling1.4..3.5ns；通道间skew最大100ps。两颗芯片分别处理CLOCK/SYNC不享有同芯片匹配保证。选它的主要原因是四路独立使能及DC逻辑分配，而不是宣称其优于专用低抖动时钟器件。来源：[TI SN65LVDS10x Rev.G](https://www.ti.com/lit/ds/symlink/sn65lvds105.pdf)。

LMK00304SQ/NOPB是备选专用时钟fanout：32pin WQFN5×5，3.3V核心，输出电源按配置；四个差分输出分两bank，支持LVDS/LVPECL/HCSL。50MHz外源优先CLKin0/1；OSCin晶体范围10..40MHz，不能接50MHz晶体；外部single-ended OSCin另有模式限制，不能混同。它额外一个LVCMOS参考输出不等于四路CMOS。没有四个独立差分OE，采用时必须另解节点独立使能。来源：[TI LMK00304 Rev.G](https://www.ti.com/lit/ds/symlink/lmk00304.pdf)。

LMK1C1104PWR为短距单端对照：四路LVCMOS、全局1G使能，非四路独立使能；不推荐把单端星形直接送长线。来源：[TI LMK1C1104](https://www.ti.com/lit/ds/symlink/lmk1c1104.pdf)。

SN65LVDT2接收传播1.4..3.6ns（规定10pF测试条件），内部端接并非精密外置100ohm；器件差与负载改变必须纳入CLOCK/SYNC预算。来源：[TI SN65LVDT2 Rev.M](https://www.ti.com/lit/ds/symlink/sn65lvdt2.pdf)。

## 原始资料

[Abracon ASE官方系列规格/订货选项](https://www.abracon.com/Oscillators/ASEseries.pdf)，[TI TPS62162数据手册](https://www.ti.com/lit/ds/symlink/tps62162.pdf)，[Hirose DF11官方目录](https://www.hirose.com/product/series/catalogdownload?category=DF11)，[TI SN65LVDS105PW供货页](https://www.ti.com/product/SN65LVDS105/part-details/SN65LVDS105PW)，[TI TPS62162产品页](https://www.ti.com/product/TPS62162)，[ASE分销listing](https://www.digikey.com/en/products/detail/abracon-llc/ASE-50-000MHZ-L-C-T/1236894)。仅供应信息引用分销页，电气判断以上述厂商规格为准。官方ASE PDF可通过浏览工具读取，本机直接下载曾403，不能写成所有PDF都已本地下载。

## 冻结门禁

当前组合的CLOCK/SYNC最坏器差不自动满足数字Profile的0.5..3ns相位范围。必须选择/实测匹配接收路径或补偿相位后才可冻结。未使用通道EN默认关闭，同时节点保持reset/资格低；receiver failsafe不代表输出低。预算至少预留3.3V/1A接口供电容量，但不能把额定1A当实测消耗或热验收。保护/端接/去耦/电感值、接插件MPN与实板对应、电源实际最大负载均仍待下一阶段设计核验。
