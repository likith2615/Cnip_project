# ======================================================================
# Autonomous Vehicle V2V Communication Simulator
# Gnuplot Publication Graph Generation Script: plot_all_graphs.gp
# Generates all 12 required academic graphs directly from CSVs (Zero Python)
# ======================================================================

set datafile separator ","
set terminal pngcairo size 800,500 enhanced font "Arial,11"
set grid

# ----------------------------------------------------------------------
# Graph 1: Vehicle Count vs Packet Delivery Ratio
# ----------------------------------------------------------------------
set output "results/graphs/vehicle_count_vs_pdr.png"
set title "Vehicle Count vs Packet Delivery Ratio (PDR %)" font "Arial-Bold,13"
set xlabel "Vehicle Count" font "Arial-Bold,11"
set ylabel "Packet Delivery Ratio (%)" font "Arial-Bold,11"
set yrange [0:105]
plot "results/csv/congestion_scaling_results.csv" using 1:5 with linespoints lw 2 pt 7 ps 1.5 lc rgb "#1f77b4" title "PDR (%)"

# ----------------------------------------------------------------------
# Graph 2: Vehicle Count vs Packet Loss Ratio
# ----------------------------------------------------------------------
set output "results/graphs/vehicle_count_vs_loss.png"
set title "Vehicle Count vs Packet Loss Ratio (%)" font "Arial-Bold,13"
set xlabel "Vehicle Count" font "Arial-Bold,11"
set ylabel "Packet Loss Ratio (%)" font "Arial-Bold,11"
set yrange [0:100]
plot "results/csv/congestion_scaling_results.csv" using 1:6 with linespoints lw 2 pt 5 ps 1.5 lc rgb "#d62728" title "Packet Loss (%)"

# ----------------------------------------------------------------------
# Graph 3: Vehicle Count vs Average Delay
# ----------------------------------------------------------------------
set output "results/graphs/vehicle_count_vs_delay.png"
set title "Vehicle Count vs Average End-to-End Latency (ms)" font "Arial-Bold,13"
set xlabel "Vehicle Count" font "Arial-Bold,11"
set ylabel "Average Latency (ms)" font "Arial-Bold,11"
set yrange [0:*]
plot "results/csv/congestion_scaling_results.csv" using 1:8 with linespoints lw 2 pt 9 ps 1.5 lc rgb "#2ca02c" title "Average Latency (ms)"

# ----------------------------------------------------------------------
# Graph 4: Vehicle Count vs Throughput
# ----------------------------------------------------------------------
set output "results/graphs/vehicle_count_vs_throughput.png"
set title "Vehicle Count vs Network Throughput (Kbps)" font "Arial-Bold,13"
set xlabel "Vehicle Count" font "Arial-Bold,11"
set ylabel "Throughput (Kbps)" font "Arial-Bold,11"
set yrange [0:*]
plot "results/csv/congestion_scaling_results.csv" using 1:7 with linespoints lw 2 pt 11 ps 1.5 lc rgb "#9467bd" title "Throughput (Kbps)"

# ----------------------------------------------------------------------
# Graph 5: Packet Loss Rate vs Retransmissions (Go-Back-N)
# ----------------------------------------------------------------------
set output "results/graphs/loss_rate_vs_retransmissions.png"
set title "Channel Loss Rate vs Go-Back-N Retransmissions" font "Arial-Bold,13"
set xlabel "Channel Packet Loss Rate" font "Arial-Bold,11"
set ylabel "Retransmission Count" font "Arial-Bold,11"
set yrange [0:*]
plot "results/csv/gobackn_results.csv" using 1:5 with linespoints lw 2 pt 7 ps 1.5 lc rgb "#ff7f0e" title "Retransmissions"

# ----------------------------------------------------------------------
# Graph 6: Packet Loss Rate vs Delivery Ratio (Go-Back-N)
# ----------------------------------------------------------------------
set output "results/graphs/loss_rate_vs_pdr.png"
set title "Channel Loss Rate vs Go-Back-N Delivery Ratio (%)" font "Arial-Bold,13"
set xlabel "Channel Packet Loss Rate" font "Arial-Bold,11"
set ylabel "Delivery Ratio (%)" font "Arial-Bold,11"
set yrange [0:105]
plot "results/csv/gobackn_results.csv" using 1:6 with linespoints lw 2 pt 5 ps 1.5 lc rgb "#1f77b4" title "Delivery Ratio (%)"

# ----------------------------------------------------------------------
# Graph 7: Window Size vs Throughput
# ----------------------------------------------------------------------
set output "results/graphs/window_size_vs_throughput.png"
set title "Sliding Window Size (W) vs Effective Throughput (Kbps)" font "Arial-Bold,13"
set xlabel "Window Size (W)" font "Arial-Bold,11"
set ylabel "Throughput (Kbps)" font "Arial-Bold,11"
set yrange [0:*]
plot "results/csv/window_results.csv" using 1:5 with linespoints lw 2 pt 7 ps 1.5 lc rgb "#2ca02c" title "Throughput (Kbps)"

# ----------------------------------------------------------------------
# Graph 8: Window Size vs Average Delay
# ----------------------------------------------------------------------
set output "results/graphs/window_size_vs_delay.png"
set title "Sliding Window Size (W) vs Average Delay (ms)" font "Arial-Bold,13"
set xlabel "Window Size (W)" font "Arial-Bold,11"
set ylabel "Average Delay (ms)" font "Arial-Bold,11"
set yrange [0:*]
plot "results/csv/window_results.csv" using 1:6 with linespoints lw 2 pt 9 ps 1.5 lc rgb "#d62728" title "Average Delay (ms)"

# ----------------------------------------------------------------------
# Graph 9: Dijkstra vs Distance Vector — Delivery Ratio
# ----------------------------------------------------------------------
set output "results/graphs/dijkstra_vs_dv_pdr.png"
set title "Dijkstra vs Distance Vector: Packet Delivery Ratio" font "Arial-Bold,13"
set style data histograms
set style fill solid 0.8 border -1
set boxwidth 0.5
set ylabel "PDR (%)" font "Arial-Bold,11"
set yrange [0:110]
plot "results/csv/routing_pdr_comparison.dat" using 2:xtic(1) lc rgb "#1f77b4" title "PDR (%)"

# ----------------------------------------------------------------------
# Graph 10: Dijkstra vs Distance Vector — Delay
# ----------------------------------------------------------------------
set output "results/graphs/dijkstra_vs_dv_delay.png"
set title "Dijkstra vs Distance Vector: Average Latency (ms)" font "Arial-Bold,13"
set style data histograms
set style fill solid 0.8 border -1
set boxwidth 0.5
set ylabel "Latency (ms)" font "Arial-Bold,11"
set yrange [0:35]
plot "results/csv/routing_delay_comparison.dat" using 2:xtic(1) lc rgb "#ff7f0e" title "Average Latency (ms)"

# ----------------------------------------------------------------------
# Graph 11: Dijkstra vs Distance Vector — Routing Overhead
# ----------------------------------------------------------------------
set output "results/graphs/dijkstra_vs_dv_overhead.png"
set title "Dijkstra vs Distance Vector: Routing Protocol Overhead" font "Arial-Bold,13"
set style data histograms
set style fill solid 0.8 border -1
set boxwidth 0.5
set ylabel "Control Packets / Rounds" font "Arial-Bold,11"
set yrange [0:60]
plot "results/csv/routing_overhead_comparison.dat" using 2:xtic(1) lc rgb "#2ca02c" title "Control Messages"

# ----------------------------------------------------------------------
# Graph 12: Vehicle Count vs Congestion / Queue Drops
# ----------------------------------------------------------------------
set output "results/graphs/vehicle_count_vs_congestion.png"
set title "Vehicle Count vs Bottleneck Queue Packet Drops" font "Arial-Bold,13"
set xlabel "Vehicle Count" font "Arial-Bold,11"
set ylabel "Packets Dropped at Queue" font "Arial-Bold,11"
set yrange [0:*]
plot "results/csv/congestion_scaling_results.csv" using 1:4 with linespoints lw 2 pt 7 ps 1.5 lc rgb "#d62728" title "Queue Drops"
