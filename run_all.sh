#!/bin/bash
# ======================================================================
# Autonomous Vehicle V2V Communication Simulator
# Master Build, Simulation, Analysis & Validation Script: run_all.sh
# NS-2 ONLY Engine (Pure Tcl, AWK, and Gnuplot - Zero Python Dependencies)
# ======================================================================

set -e

echo "========================================================================"
echo "    AUTONOMOUS VEHICLE V2V COMMUNICATION SIMULATOR (NS-2 ENGINE)        "
echo "========================================================================"
echo " [Step 1/8] Verifying toolchain environment (NS-2, AWK, Gnuplot)..."

command -v ns >/dev/null 2>&1 || { echo >&2 "Error: NS-2 ('ns') is not found. Aborting."; exit 1; }
command -v awk >/dev/null 2>&1 || { echo >&2 "Error: 'awk' is not found. Aborting."; exit 1; }
command -v gnuplot >/dev/null 2>&1 || { echo >&2 "Error: 'gnuplot' is not found. Aborting."; exit 1; }

echo "  -> NS-2 Simulator:   $(which ns)"
echo "  -> AWK Trace Parser: $(which awk)"
echo "  -> Gnuplot Engine:   $(which gnuplot)"
echo ""

mkdir -p results/traces results/csv results/graphs results/logs

# ----------------------------------------------------------------------
# 1. RUN UNIT TESTS
# ----------------------------------------------------------------------
echo "========================================================================"
echo " [Step 2/8] Executing Algorithm Unit Tests (Pure Tcl Modules)..."
echo "========================================================================"

echo "  (1/5) Running Dijkstra Routing Test (dijkstra_test.tcl)..."
ns dijkstra_test.tcl > results/logs/dijkstra_test.log && TEST_DIJKSTRA="PASS" || TEST_DIJKSTRA="FAIL"
echo "        -> Result: $TEST_DIJKSTRA"

echo "  (2/5) Running Distance Vector Routing Test (distance_vector_test.tcl)..."
ns distance_vector_test.tcl > results/logs/distance_vector_test.log && TEST_DV="PASS" || TEST_DV="FAIL"
echo "        -> Result: $TEST_DV"

echo "  (3/5) Running CRC-16 & CRC-32 Error Detection Test (crc_test.tcl)..."
ns crc_test.tcl > results/logs/crc_test.log && TEST_CRC="PASS" || TEST_CRC="FAIL"
echo "        -> Result: $TEST_CRC"

echo "  (4/5) Running Sliding Window Flow Control Test (sliding_window_test.tcl)..."
ns sliding_window_test.tcl > results/logs/sliding_window_test.log && TEST_SW="PASS" || TEST_SW="FAIL"
echo "        -> Result: $TEST_SW"

echo "  (5/5) Running Go-Back-N ARQ Retransmission Test (gobackn_test.tcl)..."
ns gobackn_test.tcl > results/logs/gobackn_test.log && TEST_GBN="PASS" || TEST_GBN="FAIL"
echo "        -> Result: $TEST_GBN"

echo ""
# ----------------------------------------------------------------------
# 2. RUN BASIC NS-2 SIMULATION
# ----------------------------------------------------------------------
echo "========================================================================"
echo " [Step 3/8] Executing Baseline NS-2 V2V Simulation (basic_v2v.tcl)..."
echo "========================================================================"
ns basic_v2v.tcl -num_vehicles 10 -loss_rate 0.05 -trace_file results/traces/basic_v2v.tr -nam_file results/traces/basic_v2v.nam > results/logs/basic_v2v.log && TEST_NS2="PASS" || TEST_NS2="FAIL"
echo "        -> Result: $TEST_NS2"

echo ""
# ----------------------------------------------------------------------
# 3. RUN COMPLETE 12-EXPERIMENT SUITE
# ----------------------------------------------------------------------
echo "========================================================================"
echo " [Step 4/8] Executing 12-Experiment Automated Suite (run_experiments.sh)..."
echo "========================================================================"
chmod +x run_experiments.sh
./run_experiments.sh

echo ""
# ----------------------------------------------------------------------
# 4. TRACE & LOG VERIFICATION
# ----------------------------------------------------------------------
echo "========================================================================"
echo " [Step 5/8] Verifying Trace Generation & Non-Empty Artifacts..."
echo "========================================================================"
if [ -s "results/traces/exp1.tr" ] && [ -s "results/traces/exp12_combined.tr" ]; then
    TEST_TRACE_GEN="PASS"
    echo "  -> Found $(ls results/traces/*.tr | wc -l) trace files (Total Size: $(du -sh results/traces | cut -f1))"
else
    TEST_TRACE_GEN="FAIL"
fi
echo "        -> Result: $TEST_TRACE_GEN"

echo ""
# ----------------------------------------------------------------------
# 5. TRACE ANALYSIS WITH AWK
# ----------------------------------------------------------------------
echo "========================================================================"
echo " [Step 6/8] Executing Automated Trace Analysis & Metrics Aggregation..."
echo "========================================================================"
if [ -s "results/csv/experiments_master_summary.csv" ]; then
    TEST_TRACE_ANA="PASS"
    echo " Master Experiments Performance Summary:"
    echo "------------------------------------------------------------------------"
    column -s, -t < results/csv/experiments_master_summary.csv | head -n 14
    echo "------------------------------------------------------------------------"
else
    TEST_TRACE_ANA="FAIL"
fi
echo "        -> Result: $TEST_TRACE_ANA"

echo ""
# ----------------------------------------------------------------------
# 6. GRAPH GENERATION WITH GNUPLOT
# ----------------------------------------------------------------------
echo "========================================================================"
echo " [Step 7/8] Generating All 12 Publication Graphs (Gnuplot)..."
echo "========================================================================"
chmod +x generate_graphs.sh
./generate_graphs.sh > /dev/null 2>&1
if [ $(ls results/graphs/*.png 2>/dev/null | wc -l) -ge 12 ]; then
    TEST_GRAPH="PASS"
    echo "  -> Successfully generated $(ls results/graphs/*.png | wc -l) publication charts in results/graphs/."
else
    TEST_GRAPH="FAIL"
fi
echo "        -> Result: $TEST_GRAPH"

echo ""
# ----------------------------------------------------------------------
# 7. FINAL INTEGRATION TEST
# ----------------------------------------------------------------------
echo "========================================================================"
echo " [Step 8/8] Executing Unified Final Integration Simulation (v2v_main.tcl)..."
echo "========================================================================"
ns v2v_main.tcl --vehicles 25 --routing dijkstra --loss 0.05 --trace results/traces/v2v_final_demo.tr > results/logs/final_demo.log && TEST_FINAL="PASS" || TEST_FINAL="FAIL"
echo "        -> Result: $TEST_FINAL"

echo ""
echo "========================================"
echo "V2V PROJECT EXECUTION SUMMARY"
echo "========================================"
echo "Dijkstra test: $TEST_DIJKSTRA"
echo "Distance Vector test: $TEST_DV"
echo "CRC test: $TEST_CRC"
echo "Sliding Window test: $TEST_SW"
echo "Go-Back-N test: $TEST_GBN"
echo "NS-2 simulation: $TEST_NS2"
echo "Trace generation: $TEST_TRACE_GEN"
echo "Trace analysis: $TEST_TRACE_ANA"
echo "Graph generation: $TEST_GRAPH"
echo "Final integration: $TEST_FINAL"
echo "========================================"
