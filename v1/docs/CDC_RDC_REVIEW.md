# CDC and reset-domain review

This is Vivado structural CDC plus a documented reset-domain audit and executed negative RTL tests. No dedicated commercial RDC signoff tool, analog metastability test or board measurement was run. Do not label it a complete physical RDC certification.

| Crossing | Implementation / invariant | Evidence |
|---|---|---|
|Reference heartbeat and lock -> independent monitor|XPM_SINGLE3stages; heartbeat slow enough for >=2 monitor samples|clock-manager fault/relock system tests; CDC-3|
|Registered monitor fault -> ref/work reset|One registered owner; XPM_ASYNC_RST3, async assertion, local synchronous release|CDC-9 and per-register reset_inventory.tsv|
|Reference session owner -> work/RX flush|link_hold register, reset synchronizer, synchronous local gating|No combinational multi-clock reset fan-in; ref loss/local reset tests|
|Config36 ref -> work|XPM async FIFO; only coherent valid/ready consumption|CDC-15×36 are the vendor FIFO distributed-memory data bus and read enable, not independent bit synchronization|
|Packets ref/RX -> work|XPM Gray pointers and scoped macro constraints, validated CRC/session/sequence|FIFO full/empty/read-only flush tests and long output stalls|
|Work config-loaded/error -> ref|Single-bit stable status; fault sticky until qualified fresh prepare|XPM S-1 checker enabled; all mixed-case Error/Fatal messages fail the runner|
|Node status -> manager|XPM_SINGLE with sticky fault and long-lived prepared/applied|System fault/session and membership tests|
|Historical fast counter bits -> ref output|XPM_SINGLE then reference IOB registers|Pin CDC3safe crossings and routed same2ns STA|

FIFO independent flush mode handles a held read-side request through ONE crossing before registered write reset distribution. Coordinated mode intentionally removes duplicated requests only when the common owner is proven by `tf_node_core` wiring. Vendor busy flags stay local; the macro manages its own internal reset crossings. The startup63-clock hold and31-clock local guard prevent early transfers. No independent flush pulse narrower than the documented contract is promised.

RDC inventory records clock and CLR/PRE nets for every routed sequential cell. Review sources are monitor fault, link_hold and locally synchronized resets; logic with synchronous reset is timed normally. The reset tree must not gain a combinational OR between unrelated clock-domain resets. Input `arst` is an external reset contract (held through initialization); its source is not asserted to be a synchronous data path. The remaining CDC-26 report row identifies `arst -> clocks/hr/.../PRE` despite its generic LUTRAM description; inspect the actual row and XPM_ASYNC_RST structure, not just that rule title. No waiver is created. The 36 FIFO data warning paths are governed by XPM pointer/empty/read-enable logic and were exercised with stalled and reset traffic.

The initial full DRC also found REQP-1839: directly including async-assert reset levels in wr_online/rd_online allowed reset to reach RAM EN/WE combinationally. The corrected wrapper uses synchronous guard state for acceptance. A reset-edge transfer, if any, is discarded by pointer reset/session invalidation. Four synchronous work reset branches fan out to receive/source validators, task pipeline and TX encoder; payload reset may lag by one work edge, while the owner masks TX immediately. No additional asynchronous reset is introduced to payload flops or RAM control. Both DRC and STA must be rerun after this structural change.

OOC external port timing is not a substitute for CDC. No broad asynchronous clock group or top-level false path is used. Internal true asynchronous paths are confined to vendor-scoped macros; read-domain occupancy replaces a raw write-full diagnostic crossing. Full reports, exceptions and clock interactions remain in each implementation evidence folder.

Primary sources checked2026-11-01: [AMD UG953 XPM_FIFO_ASYNC](https://docs.amd.com/r/2023.2-English/ug953-vivado-7series-libraries/XPM_FIFO_ASYNC), [UG9532024.2 libraries guide](https://download.amd.com/docnav/documents/UG953_2024.2_English.pdf). Installed2025.2 XPM HDL and generated constraints were inspected read-only to verify actual tool behavior. No AMD proprietary HDL was copied into the repository.
