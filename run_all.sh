#!/bin/bash
# ======================================================================
# Autonomous Vehicle V2V Communication Simulator
# Master Build, Simulation, Analysis & Validation Orchestrator
# ======================================================================

set -e

echo "========================================================================"
echo "    AUTONOMOUS VEHICLE V2V COMMUNICATION SIMULATOR (NS-2 ENGINE)        "
echo "========================================================================"
echo " [Step 0/6] Verifying toolchain and workspace environment..."

# Check prerequisites
command -v ns >/dev/null 2>&1 || { echo >&2 "Error: NS-2 ('ns') is not installed or not in PATH. Aborting."; exit 1; }
command -v awk >/dev/null 2>&1 || { echo >&2 "Error: 'awk' is not installed. Aborting."; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo >&2 "Error: 'python3' is not installed. Aborting."; exit 1; }

echo "  -> NS-2 Simulator:   $(which ns)"
echo "  -> AWK Parser:       $(which awk)"
echo "  -> Python Engine:    $(which python3)"
echo ""

# Ensure directory structure exists
mkdir -p results/traces results/csv results/graphs

echo "========================================================================"
echo " [Step 1/6] Running NS-2 Network Simulation Scenarios (Tcl/OTcl)..."
echo "========================================================================"

echo "  (1/6) Simulating Baseline Highway Platoon Safety (v2v_baseline.tcl)..."
ns ns2/v2v_baseline.tcl

echo "  (2/6) Simulating Emergency Collision Warning & CAM (v2v_collision_warning.tcl)..."
ns ns2/v2v_collision_warning.tcl

echo "  (3/6) Simulating High-Load Intersection Congestion (v2v_traffic_congestion.tcl)..."
ns ns2/v2v_traffic_congestion.tcl

echo "  (4/6) Simulating Dynamic Link Failure & Re-routing (v2v_routing_dynamics.tcl)..."
ns ns2/v2v_routing_dynamics.tcl

echo "  (5/6) Simulating Parametric Packet Loss Scenarios (0% to 20%)..."
for loss in 0.00 0.02 0.05 0.10 0.15 0.20; do
    ns ns2/v2v_packet_loss_study.tcl $loss
done

echo "  (6/6) Simulating TCP Reno Bulk Sensor Transfer & CWND Dynamics (v2v_tcp_congestion.tcl)..."
ns ns2/v2v_tcp_congestion.tcl

echo ""
echo "========================================================================"
echo " [Step 2/6] Executing Dijkstra & Distance Vector Routing Engines..."
echo "========================================================================"
python3 routing/compare_routing.py

echo ""
echo "========================================================================"
echo " [Step 3/6] Executing Reliability, CRC & Go-Back-N ARQ Engines..."
echo "========================================================================"
python3 reliability/crc.py
python3 reliability/sliding_window.py
python3 reliability/arq_simulation.py

echo ""
echo "========================================================================"
echo " [Step 4/6] Parsing NS-2 Traces & Generating Master CSV Tables..."
echo "========================================================================"
python3 analysis/parse_traces.py

echo ""
echo "========================================================================"
echo " [Step 5/6] Generating Publication-Quality Simulation Plots..."
echo "========================================================================"
python3 analysis/plot_graphs.py

echo ""
echo "========================================================================"
echo " [Step 6/6] Running Comprehensive Automated Verification Test Suite..."
echo "========================================================================"
python3 tests/test_suite.py

echo ""
echo "========================================================================"
echo "       ALL V2V SIMULATION MODULES EXECUTED AND VALIDATED SUCCESSFULLY!   "
echo "========================================================================"
echo " Deliverables Generated:"
echo "   - NS-2 Trace Files:       results/traces/*.tr, *.nam"
echo "   - Processed CSV Datasets: results/csv/*.csv"
echo "   - High-Res Charts:        results/graphs/*.png"
echo "========================================================================"
