# v1 execution guide

Read ../guide.md and ../shared first. Current scope is INTERFACE_TIMING_CLOSURE_AND_PRE_PCB_READINESS.
Historical evaluation is read-only. New reference-synchronous marker timing is a digital interface
contract, not a claim that arbitrary asynchronous SYNC edges or unmeasured physical cables align.
Membership changes use quiesce/abort, a fresh session, staged future epoch, common marker,
verification and explicit RUN. No old session resumes automatically after clock recovery.
Packet PHY remains an adapter boundary. Testbench channel faults are labeled digital models.

2026-11-01: RTL baseline9754725 includes synchronous RAM-enable guards, explicit map validation,
sticky fault, qualified preparation, monitor MMCM reset and true source timestamp capture.
Canonical current runs:signoff_system/signoff_repeat/signoff_unit/signoff_node; pin regression final_pin.
Prior sys09/impl04/final_* remain historical attempts, not automatically current acceptance.
Do not conflate internal positive STA with complete-node I/O STA, or CDC with RDC.

New authorized stage:PRE_PCB_USER_INSTRUCTION is canonical current request. Decision originalHash5772714a...
approved by user; preserve v1 and all historical evidence. Probe p0_order_late/early proves missing-clock fallback,
actual early routed skew exists. New link uses full-frame credit, continuous registered serial beats once granted,
SOF, ODDR inverse forwarded clock, input slot before RAM. tf_management_serial/node_registers/physical_node_top
are authored and under validation. adapter01/02 are preserved failed/development profiles; adapter03 running.
Manager wrap and deadline-priority unit passed manager01. link03/04 passed; link05 tests revised credit IOB path.
tb_sdr_system is the real adapter-in-business-chain test, not tf_sim_channel bypass. sdr02 running at checkpoint.
Need finish serial/physical control tests, full sdr matrix/width/frequency/fault/clean replay, two-Part full STA,
all14pre_pcb_readiness docs and conditional board/BOM input proof. Source freeze/manifest before final runs.

Review snapshot supersedes that in-progress validation note: RTL46f88bc; canonical
closure_system/closure_repeat/closure_node/closure_framework complete; signoff_unit and
final_pin remain valid for unchanged instantiated dependencies (hashes checked).
Read v1/reports and DELIVERY_AUDIT. StageREVISE solely cannot be promoted while full-node
interface setup/hold fails. All protected history still matches. No physical precision or
external independent ChatGPT review is claimed.

2026-11-01 FINAL pre-PCB checkpoint（取代前段仍在运行的状态）：冻结源码45aa523，4/8bit完整节点Z010/Z020正setup/hold/pulse、CriticalCDC0、route0、Gray6.667/20/40ns；12SDR+12legacy及各2640Golden帧、4三CSVHash重跑、原5units/6extensions/physical64/8bit240/6phase均PASS。远端干净检出25RTL字节Hash+3CSVHash一致。3723历史Hash匹配。14预设计资料齐备，单文件GPT_CHAT_FINAL_REVIEW。
当前PCB_PRE_DESIGN_READY_WITH_LIMITATIONS；硬件CLOCK/SYNC器差不能直接保证0.5..3ns资格窗口，P-002 OPEN；实板版本/VCCO/SI/BER、BOM/相位冻结HOLD，独立ReviewPENDING。保持v1，用户另行决定是否授权CAD/PCB/实物/采购；本包不是该授权。不得把旧宽top失败/旧交付状态当当前窄适配Profile。恢复以shared与原日志为准，guide来源仍PARTIAL。
