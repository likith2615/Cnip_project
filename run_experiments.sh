#!/bin/bash
# ======================================================================
# Autonomous Vehicle V2V Communication Simulator
# Complete 12-Experiment Automated Test Suite: run_experiments.sh
# ======================================================================

set -e

mkdir -p results/traces results/csv results/graphs results/logs

echo "========================================================================"
echo "    STARTING COMPLETE 12-EXPERIMENT V2V SIMULATION SUITE (NS-2 ONLY)   "
echo "========================================================================"

# Master Experiments Summary CSV
EXP_CSV="results/csv/experiments_master_summary.csv"
echo "EXP_ID,DESCRIPTION,VEHICLES,ROUTING,LOSS_RATE,WINDOW,SENT,RECVD,DROPPED,PDR_PCT,LOSS_PCT,THROUGHPUT_KBPS,AVG_DELAY_MS,JITTER_MS" > $EXP_CSV

# ----------------------------------------------------------------------
# EXPERIMENT 1: 10 vehicles, Dijkstra, normal load, 0% loss
# ----------------------------------------------------------------------
echo " [Exp 01/12] 10 vehicles | Dijkstra | 0% Loss..."
ns v2v_main.tcl --vehicles 10 --routing dijkstra --loss 0.00 --trace results/traces/exp1.tr --nam results/traces/exp1.nam > results/logs/exp1.log
METRICS=$(awk -f analysis/metrics_collector.awk results/traces/exp1.tr)
echo "EXP1,10_Vehicles_Dijkstra_0pct_Loss,10,DIJKSTRA,0.00,4,$METRICS" >> $EXP_CSV

# ----------------------------------------------------------------------
# EXPERIMENT 2: 10 vehicles, Distance Vector, normal load, 0% loss
# ----------------------------------------------------------------------
echo " [Exp 02/12] 10 vehicles | Distance Vector | 0% Loss..."
ns v2v_main.tcl --vehicles 10 --routing distance_vector --loss 0.00 --trace results/traces/exp2.tr --nam results/traces/exp2.nam > results/logs/exp2.log
METRICS=$(awk -f analysis/metrics_collector.awk results/traces/exp2.tr)
echo "EXP2,10_Vehicles_DV_0pct_Loss,10,DISTANCE_VECTOR,0.00,4,$METRICS" >> $EXP_CSV

# ----------------------------------------------------------------------
# EXPERIMENT 3: 50 vehicles, Dijkstra, medium load
# ----------------------------------------------------------------------
echo " [Exp 03/12] 50 vehicles | Dijkstra | Medium Load..."
ns v2v_main.tcl --vehicles 50 --routing dijkstra --loss 0.02 --trace results/traces/exp3.tr --nam results/traces/exp3.nam > results/logs/exp3.log
METRICS=$(awk -f analysis/metrics_collector.awk results/traces/exp3.tr)
echo "EXP3,50_Vehicles_Dijkstra_Medium_Load,50,DIJKSTRA,0.02,4,$METRICS" >> $EXP_CSV

# ----------------------------------------------------------------------
# EXPERIMENT 4: 50 vehicles, Distance Vector, medium load
# ----------------------------------------------------------------------
echo " [Exp 04/12] 50 vehicles | Distance Vector | Medium Load..."
ns v2v_main.tcl --vehicles 50 --routing distance_vector --loss 0.02 --trace results/traces/exp4.tr --nam results/traces/exp4.nam > results/logs/exp4.log
METRICS=$(awk -f analysis/metrics_collector.awk results/traces/exp4.tr)
echo "EXP4,50_Vehicles_DV_Medium_Load,50,DISTANCE_VECTOR,0.02,4,$METRICS" >> $EXP_CSV

# ----------------------------------------------------------------------
# EXPERIMENT 5: 100 vehicles, High Traffic (0% Loss)
# ----------------------------------------------------------------------
echo " [Exp 05/12] 100 vehicles | Dijkstra | High Traffic..."
ns v2v_main.tcl --vehicles 100 --routing dijkstra --loss 0.00 --trace results/traces/exp5.tr --nam results/traces/exp5.nam > results/logs/exp5.log
METRICS=$(awk -f analysis/metrics_collector.awk results/traces/exp5.tr)
echo "EXP5,100_Vehicles_High_Traffic,100,DIJKSTRA,0.00,4,$METRICS" >> $EXP_CSV

# ----------------------------------------------------------------------
# EXPERIMENT 6: 100 vehicles, 5% Packet Loss
# ----------------------------------------------------------------------
echo " [Exp 06/12] 100 vehicles | 5% Packet Loss..."
ns v2v_main.tcl --vehicles 100 --routing dijkstra --loss 0.05 --trace results/traces/exp6.tr --nam results/traces/exp6.nam > results/logs/exp6.log
METRICS=$(awk -f analysis/metrics_collector.awk results/traces/exp6.tr)
echo "EXP6,100_Vehicles_5pct_Loss,100,DIJKSTRA,0.05,4,$METRICS" >> $EXP_CSV

# ----------------------------------------------------------------------
# EXPERIMENT 7: 100 vehicles, 10% Packet Loss
# ----------------------------------------------------------------------
echo " [Exp 07/12] 100 vehicles | 10% Packet Loss..."
ns v2v_main.tcl --vehicles 100 --routing dijkstra --loss 0.10 --trace results/traces/exp7.tr --nam results/traces/exp7.nam > results/logs/exp7.log
METRICS=$(awk -f analysis/metrics_collector.awk results/traces/exp7.tr)
echo "EXP7,100_Vehicles_10pct_Loss,100,DIJKSTRA,0.10,4,$METRICS" >> $EXP_CSV

# ----------------------------------------------------------------------
# EXPERIMENT 8: 100 vehicles, 20% Packet Loss
# ----------------------------------------------------------------------
echo " [Exp 08/12] 100 vehicles | 20% Packet Loss..."
ns v2v_main.tcl --vehicles 100 --routing dijkstra --loss 0.20 --trace results/traces/exp8.tr --nam results/traces/exp8.nam > results/logs/exp8.log
METRICS=$(awk -f analysis/metrics_collector.awk results/traces/exp8.tr)
echo "EXP8,100_Vehicles_20pct_Loss,100,DIJKSTRA,0.20,4,$METRICS" >> $EXP_CSV

# ----------------------------------------------------------------------
# EXPERIMENT 9: Window Size Study (W = 1, 4, 8, 16)
# ----------------------------------------------------------------------
echo " [Exp 09/12] Sliding Window Flow Control Study (W=1, 4, 8, 16)..."
ns sliding_window_test.tcl > results/logs/exp9.log
cp window_results.csv results/csv/

# ----------------------------------------------------------------------
# EXPERIMENT 10: Go-Back-N with Controlled Packet Loss
# ----------------------------------------------------------------------
echo " [Exp 10/12] Go-Back-N ARQ with Controlled Packet Loss..."
ns gobackn_test.tcl > results/logs/exp10.log
cp gobackn_results.csv results/csv/

# ----------------------------------------------------------------------
# EXPERIMENT 11: Multi-Vehicle Congestion Scaling (10, 25, 50, 100, 200 nodes)
# ----------------------------------------------------------------------
echo " [Exp 11/12] Multi-Vehicle Congestion Scaling (10, 25, 50, 100, 200 nodes)..."
CONG_CSV="results/csv/congestion_scaling_results.csv"
echo "VEHICLES,SENT,RECVD,DROPPED,PDR_PCT,LOSS_PCT,THROUGHPUT_KBPS,AVG_DELAY_MS,JITTER_MS" > $CONG_CSV

for n_veh in 10 25 50 100 200; do
    echo "    -> Simulating $n_veh vehicles under high load..."
    ns v2v_congestion_sim.tcl $n_veh > results/logs/cong_${n_veh}v.log
    C_METRICS=$(awk -f analysis/metrics_collector.awk congestion_${n_veh}v.tr)
    echo "$n_veh,$C_METRICS" >> $CONG_CSV
    mv congestion_${n_veh}v.tr results/traces/
    mv congestion_${n_veh}v.nam results/traces/
done

# ----------------------------------------------------------------------
# EXPERIMENT 12: Final Combined V2V Scenario
# ----------------------------------------------------------------------
echo " [Exp 12/12] Final Combined Multi-Hop V2V Scenario..."
ns v2v_main.tcl --vehicles 50 --routing dijkstra --loss 0.05 --trace results/traces/exp12_combined.tr --nam results/traces/exp12_combined.nam > results/logs/exp12.log
METRICS=$(awk -f analysis/metrics_collector.awk results/traces/exp12_combined.tr)
echo "EXP12,Final_Combined_V2V_Scenario,50,DIJKSTRA,0.05,4,$METRICS" >> $EXP_CSV

echo ""
echo "========================================================================"
echo " [SUCCESS] All 12 NS-2 Experiments Executed and Logged to CSV!"
echo " Results File: $EXP_CSV"
echo "========================================================================"
