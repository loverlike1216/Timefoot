# Preserved failure history

All run directories are additive. No failed test, threshold, historical output or assertion was removed to obtain a result.

| Run | Evidence / root cause | Disposition |
|---|---|---|
| impl01, unit01 | `checker` is a reserved SV keyword | Renamed instance `crc_validator` |
| unit02 | TB expected epoch+1 at the load edge | Corrected to the specified exact epoch load edge; wrap/event checks retained |
| impl02 | CDC-10/11/12 from combinational reset fan-in and duplicated FIFO busy synchronizers; raw full crosses to a work-domain diagnostic | One reset owner, registered write-domain reset request, vendor busy stays local, coordinated reset mode, read-domain occupancy diagnostic |
| impl03 | Two remaining CDC-11 from parallel read-flush synchronizers for one reset owner | Coordinated-reset FIFOs derive both flushes from `link_hold`; independent endpoint-reset mode remains exercised in tb_fifo |
| sys01/02 | Alignment assertion kept running during the specified fault detection/propagation interval | Assert equality throughout checked RUN bursts; separate bounded negative checks verify safe invalidation after reference loss |
| sys03 | Forward reference to mmcm_reset became implicit wire | Moved declaration before instantiation |
| sys04 | Driver accepted TEST_PASS despite mixed-case XPM Error messages | **INVALIDATED**, not acceptable validation. Driver now rejects Fatal/Error case-insensitively |
| sys05 | Fault status briefly cleared/reasserted during an unqualified prepare | Sticky status until qualified new preparation; qualification gates prepare |
| sys06 | Raw full can pulse for one source cycle; XPM_SINGLE requires >=2 destination samples | Removed unsafe diagnostic transfer. Top full alarm is now read-domain occupancy >= depth; true write full remains local for flow control |
| sys07 | Before initialization/config, work_error sampled unknown decoder status | Error aggregation enabled only after coherent configuration; sticky until session flush |
| sys08 | Source trace monitor interpreted sample counter reset during fault propagation as a new sample | Record increments only; reset decreases update monitor state. Positive timestamp equality assertion retained |
| impl04 | Internal setup/hold pass, but complete OOC interface setup/hold still fails | Retain failures. No delay relaxation, broad false path or port deletion. Final reports decide current gate |
| final_system | Invalid-mask stimulus was sent before manager reset deasserted, so the write was correctly ignored | TB waits for synchronized manager reset release before register traffic |
| final_node | REQP-1839 found async-reset signals in RAM enable/write cones | Synchronous guards now own RAM enable. signoff_node removed all20 such warnings |
| signoff_node Z010 | Guard fix changed placement; one150MHz synchronous reset distribution path failed setup by0.146ns | Four local synchronous reset branches reduce fanout. closure_node is the authoritative rerun; no frequency or output-budget relaxation |

Startup FIFO reset is held for 63 write clocks to survive GSR/model initialization and ensure one uninterrupted reset episode. Independent flush requests must be held >=8 cycles of the slower endpoint. Data is inhibited until local busy and the 31-cycle release guard clear. A stopped endpoint cannot resume an old session: system recovery asserts the session owner, then requires fresh preparation/epoch/RUN.

The MMCM receives a registered monitor-owned reset on heartbeat timeout; heartbeat return releases that reset, and lock must then requalify. This fixes the vendor-model requirement to reset an MMCM after reference stoppage. Expected Unisim stopped-clock warnings remain in negative-test logs.
