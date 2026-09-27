#!/bin/bash
# ======================================================================
# Autonomous Vehicle V2V Communication Simulator - Phase 2
# Execution Script: run_dijkstra.sh
# ======================================================================

set -e

echo "========================================================================"
echo "    PHASE 2: DIJKSTRA ROUTING MODULE VERIFICATION & SIMULATION          "
echo "========================================================================"

echo " [Step 1/3] Running Independent Dijkstra Graph Verification Test..."
ns dijkstra_test.tcl

echo ""
echo "========================================================================"
echo " [Step 2/3] Running Integrated V2V Dijkstra Routing NS-2 Simulation..."
echo "========================================================================"
ns v2v_dijkstra_sim.tcl

echo ""
echo "========================================================================"
echo " [Step 3/3] Inspecting Generated Routing Events Log (routing_results.csv)"
echo "========================================================================"
cat routing_results.csv

echo ""
echo "========================================================================"
echo " [Trace Verification] Parsing dijkstra_v2v.tr with AWK..."
echo "========================================================================"
awk -f analysis/packet_delivery_ratio.awk dijkstra_v2v.tr
awk -f analysis/throughput.awk dijkstra_v2v.tr

echo ""
echo "========================================================================"
echo " [SUCCESS] Phase 2: Dijkstra Routing Module & Simulation Verified!"
echo "========================================================================"
