#!/bin/bash
# ======================================================================
# Autonomous Vehicle V2V Communication Simulator
# Final CLI Simulation Runner: run_final.sh
# Usage: ./run_final.sh [--vehicles 10|25|50|100|200] [--routing dijkstra|distance_vector] [--loss 0.05] [--window 4]
# ======================================================================

set -e

# Pass all CLI arguments directly to v2v_main.tcl
ns v2v_main.tcl "$@"

# Automatically parse generated trace
TRACE_PATH=""
if [ -f "results/traces/v2v_final.tr" ]; then
    TRACE_PATH="results/traces/v2v_final.tr"
elif [ -f "v2v_final.tr" ]; then
    TRACE_PATH="v2v_final.tr"
fi

if [ -n "$TRACE_PATH" ]; then
    echo ""
    echo "========================================================================"
    echo "                      AUTOMATED TRACE ANALYSIS ($TRACE_PATH)            "
    echo "========================================================================"
    awk -f analysis/packet_delivery_ratio.awk "$TRACE_PATH"
    awk -f analysis/throughput.awk "$TRACE_PATH"
    awk -f analysis/end_to_end_delay.awk "$TRACE_PATH"
fi
