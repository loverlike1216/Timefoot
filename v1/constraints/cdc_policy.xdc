# Only the instantiated XPM macros emit scoped synchronizer/Gray-bus exceptions.
# No blanket set_clock_groups, asynchronous clock groups, manual CDC waiver,
# or top-level set_false_path is permitted. See CDC_RDC_REVIEW.md.
# RELATED_CLOCKS=0 keeps the FIFO valid for independently forwarded clocks.
