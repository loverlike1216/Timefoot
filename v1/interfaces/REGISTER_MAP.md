# Generic management register port

All operations use manager reference clk. valid/write/address8/wdata32; ready stalls only EVENT_SUBMIT while no all-node event capacity/RUN. Each accepted request returns one rvalid, rdata and bus_error pulse (write acknowledgements also use rvalid). Hold the request stable until ready. Unknown addresses return bus_error. This is a single-beat generic port, not an AXI4-Lite implementation.

| Address | Access | Meaning |
|---|---|---|
|00|RW|Requested node mask; defaults to prefix(1<<NODES)-1|
|04|W|bit0 START/reconfigure new session (also coordinated reset/re-sync command)|
|10/14|RW|Requested epoch low/high; becomes active only on START|
|20|W|Event ID|
|24|W|Event session|
|28/2C|W|Event target low/high|
|30|W|bit0 event-submit|
|34|W|Cancel event ID, generates cancel_valid|
|38|W|bit0 cancel-all|
|40|R|state[3:0], running[4]|
|44|R|Active session|
|48/4C|R|Timestamp low then latched high (read48 captures high atomically)|
|50|R|Node fault bitmap|
|60|RW|12-bit map: slot i stage mask at bits3i+:3|
|64|RW|Source bitmap; current chain supports source0 only|
|80|R|Accepted event-submit writes since manager reset|
|84|R|Cancel-ID writes since manager reset|
|88|R|Controller recovery count|

Use 48 then4C for coherent timestamp reads. Update requested mask/map/epoch before START; current node configuration is held in session registers. `configuration_error` is a separate top output for invalid source/prefix/coverage and is cleared by a subsequent valid START. Stream validator error codes and scheduler error codes are exposed at their module interfaces; the present CSR does not provide per-node link error detail or snapshot all work-domain counters. Those diagnostic adapters remain an extension.
