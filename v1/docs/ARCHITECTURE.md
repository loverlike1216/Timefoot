# Implemented architecture

`tf_system_top` is a multi-FPGA **logical assembly**, not a four-MMCM single-Z010 design. It instantiates1–4 identical `tf_node_top`s, a generic CSR and `tf_sync_controller`. AX7020 may host the manager later, but no PS/IP or AX7020 runtime dependency exists. Elaboration fixes available slots and default business mapping; runtime mask selects a valid prefix within those slots with explicit mapping.

```text
Generic register port -> sync controller -> staged epoch/config -> common qualified marker -> RUN
                           ^                        |
                           +--- prepared/applied/fault status ---+

reference-domain scheduled source -> CRC -> async FIFO -> validate
  -> elastic real processing -> CRC -> logical PHY adapter boundary
  -> next node async FIFO -> validate -> processing ... -> output ready/valid
```

Node core separates reference50 timebase/scheduler/source, MMCM-derived business clock, incoming forwarded packet clock and independent monitor. Coherent config/data cross FIFOs; slow status uses XPM. Time is incremented in reference domain, not reconstructed from different business frequencies. Data timestamps survive processing unchanged. A faulty node forces all active nodes to discard the old session and prepare a new future epoch before data resumes.

Module inventory: clock/tf_clock_manager; timebase/tf_timebase; scheduler/tf_event_scheduler; sync/tf_sync_controller; cdc/tf_reset_sync,tf_bit_sync,tf_async_fifo,tf_cdc_bridge; stream/tf_crc_engine,tf_stream_tx,tf_stream_link,tf_task_pipeline,tf_data_source; control/tf_control_interface; top/tf_node_core,tf_node_top,tf_system_top,tf_pin_timing_top.

`tf_sim_channel` exists only under tb. It adds finite storage, seed-dependent stalls, delay and deliberate bit corruption between actual RTL packet ports. It never computes a final result. Source acquisition is synthetic, with real timestamp capture. Independent Python checks consume separately captured source bodies and end packets. This is the simulation boundary for an unspecified physical PHY.

The retained pin regression fixes the historical fast-domain direct output by synchronizing each counter bit and registering all q[2:0] in reference50 with IOB registers. This changes output latency/domain explicitly; it preserves all original ports and the same2ns output requirement. It is a separate structural regression, not a complete TIMEFOOT board pinout or bitstream.
