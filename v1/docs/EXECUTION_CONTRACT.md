# v1 execution contract

Goal: synthesizable multi-node timing/control/data core and reproducible digital evidence.
Identity: TIMEFOOT/v1/RTL_CORE_AND_SYSTEM_FRAMEWORK; branch codex/v1-rtl-core;
base main 1c39215f98494ba152c5cdf77312af485fe1ae01.

Architecture: fixed four slots, runtime mask; identical per-node core; optional generic controller;
50MHz reference with MMCM-derived work clocks; independent monitor; source-synchronous epoch marker.
Control commands and work/ref data cross through explicit coherent bridges. Marker is not an arbitrary async pulse.

Interfaces chosen for verification: 64-bit ticks, 32-bit session/event/sequence identifiers,
parameterized payload width and FIFO depth; packet body session/sequence/timestamp/length/payload
plus CRC32 (MSB-first polynomial04C11DB7, init/final XOR FFFFFFFF).
No physical PHY is invented. The first accepted packet sequence per session is zero.
CRC/session/sequence failures are explicit link errors; recovery flushes both endpoint domains.

Synchronization invariant: marker is launched on reference falling edge and arrives with a
signed source-synchronous skew/setup/hold budget; epoch/config are acknowledged before marker.
All nodes apply the same future epoch and cannot execute until verify/RUN. Negative boundary
cases must fail the channel timing contract or leave synchronization invalid; no digital claim
of arbitrary asynchronous edge alignment. Fine physical calibration remains NOT_HARDWARE_VERIFIED.

Events: multi-entry ordered queue, modulo64 half-range horizon, minimum4-tick lead, explicit
duplicate/session/late/full/cancel errors. Registered reference-domain event output corresponds
to the timestamp visible after that edge. Fault resets assert asynchronously and release per domain.

Pipeline mapping is explicit: 1 node runs three operations; 2 nodes use001/110;
3 use001/010/100; 4 use000/001/010/100. Changes require a fresh session.
Source captures an actual ref-domain timebase timestamp; payload is defined synthetic input.
All intermediate operations, queues, CRC and flow control are real synthesizable RTL.

Validation: unit/negative/system tests; node masks1–4, varied phase/delays, true MMCM models,
fixed seeds/repeated hashes, independent Python packet calculations, fault recovery/old-data isolation,
two-part synthesis/place/route/STA/CDC/DRC/clock interaction/constraint coverage and documented RDC audit.
Historical q[2:0] counter outputs are retained in the pin regression but transferred/registered
to the declared50MHz output domain; same2ns output budget, no deletion or false-path masking.

Rollback: additive v1 files and scoped commits. History/read-only preproject protected.
Done: all stage results reviewed against real reports; unmet gates yield REVISE, not hidden failures.
