# v1 pre-PCB execution contract

Goal:close a meaningful complete digital interface, verify new source-synchronous transport in1–4node
business operation, and produce the14requested pre-design input documents. Active version remainsv1;
stage INTERFACE_TIMING_CLOSURE_AND_PRE_PCB_READINESS, branch codex/v1-rtl-core, initial HEAD31005c4.

Plan:P0 reproduce late-vs-early-clock XPM constraints with unchanged node RTL; derive macro bounds
from actual clock objects, inspect exceptions and routed bus skew. Then implement narrow SDR physical
digital adapter, registered I/O and forwarded clock with bounded flow control; expose coherent control/
status, fix manager wrap/deadline logic; run actual link unit and multi-node/fault/replay/reference tests.
Implement both Parts with full clock/TX/RX/control/diagnostic endpoints, retain old profiles, and report
all STA/CDC/RDC/DRC/coverage/resource results. Independently research original board/datasheet inputs
and conditional pin/BOM/electrical requirements without CAD or real hardware operations.

Invariants:qualified common-edge epoch, no old-session execution after recovery, unchanged208-bit
core frame atpayload32 and CRC-BZIP2, actual timestamp capture, ready/valid capacity respected,
no fake endpoints or testbench bypass of the adapter. Reset-edge aborted data is accounted explicitly.
All new tool work is under v1/work, all immutable run evidence under v1/verification/evidence;
preproject_feasibility and previous result directories are protected read-only.

Done only with real evidence supporting PCB_PRE_DESIGN_READY(_WITH_LIMITATIONS), elseREVISE/BLOCKED
with concrete unresolved issues. Physical pin/VCCO/propagation/metastability/BER precision remains
NOT_HARDWARE_VERIFIED. No lowering thresholds, blanket false paths or frequency retreat to getPASS.
