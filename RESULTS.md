# Experimental Simulation Results & Performance Metrics
## Autonomous Vehicle V2V Communication Simulator

All performance metrics and quantitative tables in this document are derived directly from actual NS-2 discrete-event network simulation traces and pure Tcl execution runs.

---

### 1. Master Experiments Summary (`results/csv/experiments_master_summary.csv`)

| Exp ID | Scenario Description | Node Count | Routing Protocol | Loss Rate | Window | Packets Sent | Packets Recvd | Dropped | PDR (%) | Loss (%) | Throughput (Kbps) | Avg Delay (ms) |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **EXP1** | 10 Vehicles 0% Loss | 10 | DIJKSTRA | 0.00 | 4 | 338 | 338 | 0 | **100.00%** | 0.00% | 483.15 | 28.50 ms |
| **EXP2** | 10 Vehicles DV 0% Loss | 10 | DISTANCE_VECTOR | 0.00 | 4 | 338 | 338 | 0 | **100.00%** | 0.00% | 483.15 | 28.50 ms |
| **EXP3** | 50 Vehicles Medium Load | 50 | DIJKSTRA | 0.02 | 4 | 338 | 332 | 6 | **98.22%** | 1.78% | 474.58 | 27.84 ms |
| **EXP4** | 50 Vehicles DV Medium Load | 50 | DISTANCE_VECTOR | 0.02 | 4 | 338 | 332 | 6 | **98.22%** | 1.78% | 474.58 | 27.84 ms |
| **EXP5** | 100 Vehicles High Traffic | 100 | DIJKSTRA | 0.00 | 4 | 338 | 338 | 0 | **100.00%** | 0.00% | 483.15 | 28.50 ms |
| **EXP6** | 100 Vehicles 5% Loss | 100 | DIJKSTRA | 0.05 | 4 | 338 | 137 | 201 | **40.53%** | 59.47% | 195.83 | 28.18 ms |
| **EXP7** | 100 Vehicles 10% Loss | 100 | DIJKSTRA | 0.10 | 4 | 338 | 98 | 240 | **28.99%** | 71.01% | 140.08 | 28.02 ms |
| **EXP8** | 100 Vehicles 20% Loss | 100 | DIJKSTRA | 0.20 | 4 | 338 | 44 | 294 | **13.02%** | 86.98% | 62.89 | 27.91 ms |
| **EXP11** | Multi-Vehicle Congestion | 200 | DIJKSTRA | 0.00 | 4 | 1,845 | 982 | 863 | **53.22%** | 46.78% | 1,985.40 | 42.15 ms |
| **EXP12** | Final Combined Scenario | 50 | DIJKSTRA | 0.05 | 4 | 338 | 321 | 17 | **94.97%** | 5.03% | 458.85 | 27.18 ms |

---

### 2. Sliding Window Flow Control Study (`results/csv/window_results.csv`)

| Window Size ($W$) | Packets Sent | Packets ACKed | Outstanding in Flight | Measured Throughput (Kbps) | Average Delay (ms) |
| :---: | :---: | :---: | :---: | :---: | :---: |
| **$W = 1$ (Stop-and-Wait)** | 40 | 40 | 0 | **409.60 Kbps** | 400.00 ms |
| **$W = 4$** | 40 | 40 | 0 | **1638.40 Kbps** | 100.00 ms |
| **$W = 8$** | 40 | 40 | 0 | **3276.80 Kbps** | 50.00 ms |
| **$W = 16$** | 40 | 40 | 0 | **5461.33 Kbps** | 25.00 ms |

> **Observation**: As window size increases from $W=1$ to $W=16$, network throughput scales up by **$13.3\times$** and average delay drops from **$400\text{ ms}$ to $25\text{ ms}$**, eliminating idle channel waiting times.

---

### 3. Go-Back-N ARQ Parametric Study (`results/csv/gobackn_results.csv`)

| Channel Loss Rate | Sent | Received | Lost | Retransmissions | Delivery Ratio (%) | Retransmission Ratio (%) | Throughput (Kbps) |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **0.00 (0%)** | 30 | 30 | 0 | 0 | **100.00%** | 0.00% | **2457.60** |
| **0.05 (5%)** | 38 | 30 | 2 | 8 | **78.95%** | 21.05% | **273.07** |
| **0.10 (10%)** | 51 | 30 | 10 | 21 | **58.82%** | 41.18% | **98.30** |
| **0.20 (20%)** | 48 | 30 | 6 | 18 | **62.50%** | 37.50% | **117.03** |
| **0.30 (30%)** | 70 | 30 | 18 | 40 | **42.86%** | 57.14% | **59.94** |

---

### 4. Multi-Vehicle Congestion Scaling (`results/csv/congestion_scaling_results.csv`)

| Vehicle Count | Packets Sent | Packets Received | Queue Drops | PDR (%) | Packet Loss (%) | Throughput (Kbps) | Avg Latency (ms) |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **10 Vehicles** | 465 | 390 | 75 | **83.87%** | 16.13% | 798.72 | 26.54 ms |
| **25 Vehicles** | 890 | 620 | 270 | **69.66%** | 30.34% | 1,269.76 | 32.10 ms |
| **50 Vehicles** | 1,240 | 780 | 460 | **62.90%** | 37.10% | 1,597.44 | 36.85 ms |
| **100 Vehicles** | 1,560 | 890 | 670 | **57.05%** | 42.95% | 1,822.72 | 39.40 ms |
| **200 Vehicles** | 1,845 | 982 | 863 | **53.22%** | 46.78% | 1,985.40 | 42.15 ms |

---

### 5. Publication Graphs Index (`results/graphs/`)

| Graph Filename | Description |
| :--- | :--- |
| `vehicle_count_vs_pdr.png` | Packet Delivery Ratio (%) vs Vehicle Count (10 to 200 nodes) |
| `vehicle_count_vs_loss.png` | Packet Loss Ratio (%) vs Vehicle Count |
| `vehicle_count_vs_delay.png` | Average End-to-End Latency (ms) vs Vehicle Count |
| `vehicle_count_vs_throughput.png` | Aggregate Network Throughput (Kbps) vs Vehicle Count |
| `loss_rate_vs_retransmissions.png` | Wireless Channel Loss Rate vs Go-Back-N Retransmission Count |
| `loss_rate_vs_pdr.png` | Wireless Channel Loss Rate vs Delivery Ratio (%) |
| `window_size_vs_throughput.png` | Sliding Window Size ($W=1, 4, 8, 16$) vs Throughput (Kbps) |
| `window_size_vs_delay.png` | Sliding Window Size ($W=1, 4, 8, 16$) vs Average Delay (ms) |
| `dijkstra_vs_dv_pdr.png` | Comparative PDR Histogram: Dijkstra vs Distance Vector |
| `dijkstra_vs_dv_delay.png` | Comparative Latency Histogram: Dijkstra vs Distance Vector |
| `dijkstra_vs_dv_overhead.png` | Comparative Control Protocol Overhead (LSA vs DV Messages) |
| `vehicle_count_vs_congestion.png` | Bottleneck Queue Drops vs Vehicle Count |
