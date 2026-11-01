# Failure history and root cause analysis

These original failures are retained. No acceptance check was disabled.

1. `environment/probe_vivado.log`: package-pin queries require an open design. Fixed by actual minimum synthesis, which also tested license availability. Attempt 2 exits 0.
2. `simulation_logs/attempt1`: Windows batch command parsing split the unquoted generic `N=1` into two arguments. Replaced by four thin testbench wrappers instantiating the same parameterized testbench. No RTL duplication.
3. `simulation_logs/attempt2`: the same Windows batch parsing split `SEED=1`. Plusarg now uses the unambiguous `SEED1` syntax.
4. `simulation_logs/runA`: XSIM's generated Tcl interpreted backslashes in Windows absolute paths as Tcl escapes. Orchestration now passes forward-slash absolute paths everywhere.
5. `simulation_logs/runB`: `log_vcd` in this installed XSIM does not accept the `-r` option. Explicit testbench scopes replace that unsupported option. This is a waveform setup failure before RTL ran.
6. `simulation_logs/reference_driver_initial_failure.log`: manual expected capture spread was incorrectly 30 ns; exact edge equation gives captures 60,50,60,70 ns, i.e. 20 ns. Corrected the mathematical check, not the simulated hardware acceptance threshold. Full-cycle epoch ambiguity remains a finding.

Tool orchestration RCA: use installed command semantics and literal forward-slash paths; avoid relying on Unix command argument conventions through Windows `.bat` launchers. Further results are valid only when the case log contains `TEST_PASS`, no fatal assertion, and the required trace exists.

7. `reference_driver_second_failure.log`: the monotonicity model initialized previous time to -1 ns, incorrectly rejecting an allowed negative initial offset at t=0. Changed the unobserved previous value to negative infinity; every actual consecutive timestamp is still strictly checked. The model remains illustrative, not a PTP implementation.
8. `simulation_logs/finalC/tb_pipeline_seed1_gap3`: after connecting scheduled acquisition and actual sync-counter timestamps, the slower source did not generate enough backlog during the original 3 us initial sink stop. The full/empty/backpressure coverage assertion failed. The common sink-stop stimulus is strengthened to 6 us for both source rates; no assertion or correctness threshold is weakened. The original run remains archived.
9. Both `timing_reports/*_pin_probe/timing.rpt` retain negative WNS (-0.673 / -0.304 ns) on the candidate counter-to-pin output path against an illustrative external-reference capture constraint. Routing legality is observed, but that small complete pin top does NOT meet all timing constraints. No false path or relaxed delay was added to hide this. Final board output design requires an appropriate registered/forwarded interface and actual receiver timing budget.
