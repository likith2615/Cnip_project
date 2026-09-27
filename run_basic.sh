#!/bin/bash
# ======================================================================
# Autonomous Vehicle V2V Communication Simulator - Phase 1
# Master Execution Script: run_basic.sh
# ======================================================================

set -e

echo "========================================================================"
echo "    AUTONOMOUS VEHICLE V2V SIMULATION - PHASE 1 VERIFICATION            "
echo "========================================================================"
echo " [Step 1/3] Checking environment & NS-2 executable..."

command -v ns >/dev/null 2>&1 || { echo >&2 "Error: NS-2 ('ns') is not found. Aborting."; exit 1; }
command -v awk >/dev/null 2>&1 || { echo >&2 "Error: 'awk' is not found. Aborting."; exit 1; }

echo "  -> NS-2: $(which ns)"
echo "  -> AWK:  $(which awk)"
echo ""

# ----------------------------------------------------------------------
# 1. RUN DEFAULT 10-VEHICLE SIMULATION
# ----------------------------------------------------------------------
echo "========================================================================"
echo " [Step 2/3] Running Default Baseline Simulation (10 Vehicles, 5% Loss)..."
echo "========================================================================"
ns basic_v2v.tcl -num_vehicles 10 -loss_rate 0.05 -trace_file basic_v2v.tr

echo ""
echo "========================================================================"
echo " [Step 3/3] Parsing Trace File (basic_v2v.tr) with AWK..."
echo "========================================================================"

# Run AWK Verification
awk -f analysis/packet_delivery_ratio.awk basic_v2v.tr
awk -f analysis/throughput.awk basic_v2v.tr
awk -f analysis/end_to_end_delay.awk basic_v2v.tr

echo ""
echo "========================================================================"
echo " [SCALABILITY TEST] Verifying Multi-Vehicle Scalability (20, 50, 100)... "
echo "========================================================================"

for num_v in 20 50 100; do
    echo " -> Testing with $num_v vehicles (trace: test_${num_v}v.tr)..."
    ns basic_v2v.tcl -num_vehicles $num_v -loss_rate 0.05 -trace_file test_${num_v}v.tr > /dev/null
    awk -f analysis/packet_delivery_ratio.awk test_${num_v}v.tr | grep -E "End-to-End Packets|Delivery Ratio|Loss Ratio"
    rm -f test_${num_v}v.tr test_${num_v}v.nam
done

echo ""
echo "========================================================================"
echo " [SUCCESS] Phase 1 Simulation & Scalability Verified Successfully!"
echo " Primary Deliverables:"
echo "   - Configuration:  config.tcl"
echo "   - Simulation Tcl: basic_v2v.tcl"
echo "   - Trace File:     basic_v2v.tr  ($(wc -c < basic_v2v.tr) bytes)"
echo "   - NAM File:       basic_v2v.nam ($(wc -c < basic_v2v.nam) bytes)"
echo "   - Guide:          README_BASIC.md"
echo "========================================================================"
