# Stage research and tool selection record

Project TIMEFOOT/v1, Stage INTERFACE_TIMING_CLOSURE_AND_PRE_PCB_READINESS,2026-11-01. Actual user next-stage instruction authorizes bounded autonomous digital implementation and conditional hardware input research. No CAD/hardware/procurement authority.

Keywords: Zynq7000, XPM Gray pointer constraints, XDC read order, source synchronous SDR, ODDR/IOB, full-frame credit, coherent snapshot, reset-domain crossing, Session/Epoch wrap, EBAZ4205 DATA connector, AX7020 bank/pins, clock/SYNC fanout and receiver phase spread.

Observed resources: realWindows/pwsh7.6.5, Python3.10.11, actualVivado/XSIM2025.2 installed with both target Parts and valid implementation license;16GBRAM. User originalAXPDF/manual andEBAZMD, preserved prior RTL/reports, formalrepo/root/branch. OriginaluserEBAZMD lacksDATAoriginalschematic; community originalPDF/XDC fetched and inspected, actualfourboardrevision remainsunconfirmed.

Tools actually used: pwsh/git/gh, installedVivado/XSIM/UNISIM/XPM, Pythonstdlib golden/hash/VCD/analysis, PDF skill and read-onlyPyMuPDF with-B into project-local outputs, primary-source web research. GitHubConnector PRwrite previously403; existingauthenticatedgh fallback sufficient. No secondRTLsimulator, dedicatedRDCsignoff or connectedhardware available; these are not claimed.

Primary references: AMDUG903 nonproject/readorder/outputdelays, UG949 async, XPM_CDC_GRAY and installed2025.2 vendorTcl/HDL; TI LMK00304/SN65LVDS105/SN65LVDT2/LMK1C1104/TPS62162 manufacturerdatasheets; AbraconASE officialseries andHiroseDF11catalog. URLs/versions/hash/accesslimitations in XPM_CDC_CONSTRAINT_AUDIT and pre_pcb_readiness COMPONENT_SELECTION_AND_BOM, hardware_source_audit.json. CommunityEBAZ originaldesign is conditionalboardreference, not a confirmation of currentphysicalrevision.

Chosen route: retain208bitframe andexistingbusiness/clockarchitecture,4/8bitregisteredSDR+invertedODDRclock, wholeframecredit with reservedRXslot, coherenthandshake status, fullphysicaltop/serialCSR. Place primaryclocks before synthesis so vendor constraints use actualperiods. Validate rootcause with same-source early/late controlledexperiment; no blanket exceptions. Select4bit50 asfirsthardwarecandidate because sourceCRC limitsapplicationrate and extra8bitGPIO/SIcost brings little currentbusinessbenefit.

Rejected/compared: wide208bitphysicalbus notconnector-practical and oldprofile fails; per-beat halfcycle-ready prototype realSTAfailed, replacearchitecturewithcapacityreservation ratherthanlowerfrequency; standaloneGray fast telemetrycounter violates sampling assumptions, replace fullhandshake; LMK00304 lacksfourindependentoutputOE,1104globalOE/singleended notsufficientforlongstar.105fourindependentEN+DCsync is candidate but itsreceiver/pathphase uncertainty doesnotautomaticallymeetSYNCinputwindow.

Licensing/sourcehandling: no copied AMDproprietaryHDL/Tcl embeddedinto repository; vendorinstallation read-only. Third-partydatasheetPDF/extracts onlyprojectwork, sourceURLs/hashfacts inreports. Originalpreprojectbytes protected. No payment/installations/systemconfiguration/visibilitychanges.

Acceptance: bothPart fullnode setup/hold/pulse nonnegative, criticalCDC0, scopedvendorconstraints/busskew/coverage examined, realadapterin1–4nodechain with independentnumeric/CRC checks andfaultrecoveries, fixedseedreplay/cleancheckout, conditionalpin/BOM/phaseinputs, nofalsehardwareclaims. Actualoutcome/remainingconditions in finalreview package. Researchstoppedwhen sufficientfor thisstage; P-002 records the actualhardwarefreeze decisionstillneeded.
