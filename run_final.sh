#!/bin/bash
# ======================================================================
# Autonomous Vehicle V2V Communication Simulator
# Final CLI Simulation Runner: run_final.sh
# Usage: ./run_final.sh [--vehicles 10|25|50|100|200] [--routing dijkstra|distance_vector] [--loss 0.05] [--window 4]
# ======================================================================

set -e

# Pass all CLI arguments directly to v2v_main.tcl
ns v2v_main.tcl "$@"

# Automatically parse generated trace if v2v_final.tr exists
if [ -f "v2v_final.tr" ]; then
    echo ""
    echo "========================================================================"
    echo "                      AUTOMATED TRACE ANALYSIS                          "
    echo "========================================================================"
    awk -f analysis/packet_delivery_ratio.awk v2v_final.tr
    awk -f analysis/throughput.awk v2v_final.tr
    awk -f analysis/end_to_end_delay.awk v2v_final.tr
fi
