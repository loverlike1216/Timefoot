---
problem_id: P-20261101-002
project_id: TIMEFOOT
active_version: v1
current_stage: INTERFACE_TIMING_CLOSURE_AND_PRE_PCB_READINESS
status: OPEN
created_at: 2026-11-01
created_by: Codex
type: HARDWARE_FREEZE_CONDITION
---
# CLOCK/SYNC硬件相位资格与BOM冻结

## Decision Needed

独立Review下一硬件阶段如何保证CLOCK/SYNC相对PAD到达范围0.5..3ns：匹配接收器/路径、可验证相位补偿、测量筛选，或在有充分电气依据的未来Profile中重新约束并签核。当前不请求中断数字工作，不请求CAD/采购授权。

## Goal / Current State

公共50MHz B架构保持。完整4/8bit数字接口在Z010/Z020正STA、CriticalCDC0，原问题P-001的数字适配路线已实现验证。原问题正文/Hash不变。参考分发的板间电气相位尚未测量。

## Evidence

v1/docs/pre_pcb_readiness/CLOCK_ERROR_BUDGET.md及COMPONENT_SELECTION_AND_BOM.md；prepcb_analysis/clock_budget.json负例展示11ns导致Apply错一拍。TI SN65LVDS105两颗rising器差按1.7..3ns推得±1.3ns；SN65LVDT2两颗按1.4..3.6ns推得±2.2ns；加线缆/板/抖动保留合计±5ns，不能从数据手册直接保证0.5..3ns接口。

## What Codex Tried / Root Cause

比较LMK00304（两bank不能直接四路独立OE）、SN65LVDS105（独立OE但CLOCK/SYNC两chip）、LMK1C1104（global OE单端）与外置接收器，完成资料和条件预算。问题来自器差与实际物理路径未锁定，不是数字RTL可凭推断消除的bug；没有放宽XDC换取PASS。实际资格输入不常置1。

## Candidate Options

A：同器件matched多通道接收+受控CLOCK/SYNC路径，先按最坏datasheet预算，实测PVT确认。降低接收器差，但需新选型和板级验证。

B：保持候选器件，以可测/可校准的相位补偿将到达范围压入Profile；须新增明确硬件/控制接口要求并验证故障安全态，不能假定现有RTL已提供自动校准。

C：保持硬件仅作实验，qualification低直到人工测量满足；只能有限实验，不能声称跨四块板无条件严格同步。

## Acceptance Impact / Constraints

本轮只能PCB_PRE_DESIGN_READY_WITH_LIMITATIONS；硬件BOM/相位冻结HOLD。数字验证仍有效于其明确Profile。不得改B架构、v1、原验收标准；不得把解析误差模型当实板证明。

## Questions For ChatGPT

1. 是否接受本阶段有限预设计输入及P0数字问题关闭？
2. 下一Stage优先哪种匹配/相位资格方案，要求什么测量与门限？
3. 在用户另行授权原理图/PCB前，哪些器件/相位条件必须先闭合？

## User Approval Boundary

需要用户本人另行授权才能进入原理图/PCB、硬件连接/采购/制造、正式Scope改变或新版本。本文不是授权请求，也没有自动采用某个外部ChatGPT Decision。
