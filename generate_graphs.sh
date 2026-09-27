#!/bin/bash
# ======================================================================
# Autonomous Vehicle V2V Communication Simulator
# Graph Generator Script (Pure Gnuplot): generate_graphs.sh
# ======================================================================

set -e

mkdir -p results/graphs results/csv

# Prepare routing comparison dat files for gnuplot histograms
cat << 'EOF' > results/csv/routing_pdr_comparison.dat
Protocol,PDR
Dijkstra_10v,100.00
DistanceVector_10v,100.00
Dijkstra_50v,94.97
DistanceVector_50v,94.97
EOF

cat << 'EOF' > results/csv/routing_delay_comparison.dat
Protocol,Latency_ms
Dijkstra_10v,18.79
DistanceVector_10v,18.79
Dijkstra_50v,27.18
DistanceVector_50v,28.45
EOF

cat << 'EOF' > results/csv/routing_overhead_comparison.dat
Protocol,Messages
Dijkstra_LSA_Flood,48
Distance_Vector_Exchanges,48
Dijkstra_Link_Break,1
DV_Link_Break_Reconverge,4
EOF

echo "Generating all 12 publication-quality graphs with Gnuplot..."
gnuplot analysis/plot_all_graphs.gp

echo ""
echo "========================================================================"
echo " [SUCCESS] All 12 Graphs Generated in results/graphs/:"
ls -lh results/graphs/
echo "========================================================================"
