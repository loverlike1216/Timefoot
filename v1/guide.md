# v1 execution guide

Read ../guide.md and ../shared first. Scope is RTL_CORE_AND_SYSTEM_FRAMEWORK.
Historical evaluation is read-only. New reference-synchronous marker timing is a digital interface
contract, not a claim that arbitrary asynchronous SYNC edges or unmeasured physical cables align.
Membership changes use quiesce/abort, a fresh session, staged future epoch, common marker,
verification and explicit RUN. No old session resumes automatically after clock recovery.
Packet PHY remains an adapter boundary. Testbench channel faults are labeled digital models.
