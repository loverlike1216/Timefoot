# Observable tool flow

Read user attachment, local guides/reports/RTL/CDC/STA; read GitHub repository metadata;
git ls-remote/init/fetch/branch; PowerShell7 and Vivado version; immutable historical inventory.
Local AMD XPM source signatures were inspected read-only; proprietary vendor source is not copied.
Official UG953 macro pages checked for reset/busy/CDC semantics; installed2025.2 implementation
is the actual runtime source. Logs/commands/results continue under v1/verification/evidence.

Canonical observable sequence: source commits1a4a1ad,3ebc759,9754725,46f88bc; fresh-tag
run_sim.py suites(unit/system/repeat), run_impl.py(node/pin), synth_framework.tcl(twoParts),
check_system.py closure_system, check_clocks.py, audit_delivery.py, write_reports.py.
Observed current outputs:5unitPASS,12systemPASS,2640Python packetsPASS,4trace replaysMATCH,
4VCDclock/eventPASS,3723historical filesMATCH,4routed profiles,2framework synths.
Current stage gateREVISE because full-node I/O STA fails, with actual raw reports retained.
Failure history and corrections are in v1/docs/FAILURE_ANALYSIS.md. No manual CDC waiver,
wide false path, disabled assertion or hidden correct answer was introduced. Fake-implementation
search found only the explicitly labeled TB physical-channel model and a disabled-slot comment.
No physical CAD/JTAG/board action. Git/PR/clean checkout evidence is appended when observed.
