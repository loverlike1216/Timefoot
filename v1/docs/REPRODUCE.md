# Reproduction and evidence scope

Actual environment: Windows, PowerShell7.6.5, Python3.10.11 stdlib, Vivado/XSIM2025.2 Build6299465 with working synthesis/implementation license for xc7z010clg400-1 and xc7z020clg400-2. The second Part remains a manual candidate until an actual AX7020 is identified. No board/JTAG/bitstream/PHY access is used.

Run from the confirmed repository root in pwsh7. Scripts derive that root from their own path; all work, TMP/TEMP, logs, waves and outputs remain under v1. No pip package is needed. Override `TIMEFOOT_VIVADO_BIN` if Vivado is installed elsewhere. Each tag must be NEW; runners refuse an existing work/evidence directory. Never run legacy preproject sealer or replay scripts in place.

```powershell
Set-Location -LiteralPath 'E:\Codex_project\Timefoot'
$PSVersionTable.PSVersion
$env:TIMEFOOT_VIVADO_BIN='D:/Vivado/2025.2/2025.2/Vivado/bin'
python v1/scripts/run_sim.py --tag replay_unit --suite unit
python v1/scripts/run_sim.py --tag replay_system --suite system
python v1/reference_model/check_system.py replay_system
python v1/scripts/run_sim.py --tag replay_repeat --suite repeat
python v1/scripts/run_impl.py --tag replay_node --mode node
python v1/scripts/run_impl.py --tag replay_pin --mode pin
python v1/reference_model/long_term_model.py
```

Every runner creates source_manifest.json with branch/commit, exact source SHA256 and the pre-run dirty state. Raw launcher/tool logs are retained. System suite covers4node counts×3seeds(1,17,2026); repeat suite repeats seed1 for every count. Packet/event/source CSV hashes must match the same case/seed across runs; log timestamps/tool duration are not compared. Waves and DCPs stay local and are indexed by SHA256; source, compact traces, reports and manifests are Git assets. Rebuild large binaries from the pinned source, constraints and tool version. DCP binary equality across machines is not claimed.

`synth_framework.tcl <fresh-tag>` additionally synthesizes the complete one-node framework (including manager/CSR/controller) for both Parts. The four-node logical assembly represents four FPGAs and is not packed onto a single Z010. Primary node implementation uses150MHz work/50MHz reference/100MHz RX. Functional system defaults are50/100/150/50MHz; other dividers, widths and depths need their own STA and tests.

Inspect timing.rpt WHS/WNS, internal_setup/internal_hold, CDC, DRC, route, clocks, methodology, effective.xdc and constraint_coverage. An exit0 from Vivado only means the commands completed; it does **not** mean timing or the stage gate passed. Pin regression retains2ns output delay. Complete-node OOC interface failures remain gate failures even where internal timing is positive.
