# Autonomous Vehicle V2V Communication Simulator

[![Simulator](https://img.shields.io/badge/Simulator-NS--2.35%20(Pure%20Tcl%2FOTcl)-blue.svg)](https://www.isi.edu/nsnam/ns/)
[![Analysis](https://img.shields.io/badge/Analytics-AWK%20%7C%20Gnuplot-brightgreen.svg)]()
[![Tests](https://img.shields.io/badge/Unit%20Tests-100%25%20Passing-success.svg)]()
[![License](https://img.shields.io/badge/License-Academic%20Project-orange.svg)]()

A complete, academic-grade **Vehicle-to-Vehicle (V2V) Communication Simulator** built strictly with **Network Simulator 2 (NS-2.35)**, **pure Tcl/OTcl protocol modules**, and an **AWK/Gnuplot analytics pipeline** (Zero Python required in the simulation or analytics core).

---

## 🚗 Problem Statement & Overview
Autonomous vehicle platoons rely on ultra-reliable wireless communication to exchange safety-critical messages:
1. **Emergency Collision Warnings (ECW)**: Disseminated backward from lead vehicles to trailing vehicles within strict latency bounds ($< 50\text{ ms}$).
2. **Sudden-Braking Alerts (CAM)**: High-priority event-triggered deceleration broadcasts across vehicle chains.
3. **Traffic Congestion & Telemetry (BSM)**: Periodic vehicle telemetry competing for limited wireless channel bandwidth.

This simulator models and evaluates all mandatory Computer Networks concepts:
- **Dijkstra Link-State Routing** (`dijkstra.tcl`, `dijkstra_test.tcl`)
- **Distance Vector (Bellman-Ford) Routing with Poison Reverse** (`distance_vector.tcl`, `distance_vector_test.tcl`)
- **CRC-16 & CRC-32 Error Detection** (`crc.tcl`, `crc_test.tcl`)
- **Sliding Window Flow Control** (`sliding_window.tcl`, `sliding_window_test.tcl`)
- **Go-Back-N ARQ Reliability & Retransmission** (`gobackn.tcl`, `gobackn_test.tcl`)
- **Active AIMD Congestion Control** (`congestion.tcl`, `v2v_congestion_sim.tcl`)
- **Multi-Vehicle Scalability** (10, 25, 50, 100, 200 nodes in `v2v_main.tcl`)
- **Automated Trace Analytics & 12 Publication Graphs** (`analysis/*.awk`, `generate_graphs.sh`)

---

## 📂 Repository Structure

```
v2v_project/
├── dijkstra.tcl                     # Pure Tcl Dijkstra Link-State routing module
├── dijkstra_test.tcl                # Independent unit test on canonical reference graph
├── distance_vector.tcl              # Pure Tcl Bellman-Ford Distance Vector module
├── distance_vector_test.tcl         # Independent Distance Vector convergence test
├── crc.tcl                          # Pure Tcl CRC-16 & CRC-32 bitwise modulo-2 division
├── crc_test.tcl                     # Independent CRC error detection & noise test
├── sliding_window.tcl               # Pure Tcl Sliding Window flow control module
├── sliding_window_test.tcl          # Independent flow control & buffer test
├── gobackn.tcl                      # Pure Tcl Go-Back-N ARQ protocol state machine
├── gobackn_test.tcl                 # Independent GBN forced-loss retransmission test
├── congestion.tcl                   # Pure Tcl active AIMD congestion controller
├── v2v_congestion_sim.tcl           # Multi-vehicle congestion scaling simulation
├── v2v_main.tcl                     # Unified configurable V2V simulation engine
├── config.tcl                       # Centralized simulation configuration parameters
│
├── run_all.sh                       # Master script executing all tests, simulations & plots
├── run_experiments.sh               # Automated suite running all 12 experimental scenarios
├── run_final.sh                     # CLI runner for custom simulation parameters
├── generate_graphs.sh               # Automated Gnuplot script creating all 12 PNG charts
├── run_visualizer.sh                # Linux/WSL launcher for web visualizer
├── open_visualizer.bat              # Windows 1-click launcher for web visualizer
│
├── visualizer/                      # Interactive Web Visualizer (HTML5 / Canvas / CSS)
│   ├── index.html                   # Interactive simulation dashboard
│   ├── style.css                    # Modern glassmorphism styling
│   └── app.js                       # Protocol simulators, live highway & viva defense
│
├── analysis/                        # Pure AWK & Gnuplot Analytics Pipeline
│   ├── packet_delivery_ratio.awk    # AWK parser: End-to-End PDR (%) & Packet Loss (%)
│   ├── throughput.awk               # AWK parser: Throughput in Kbps & Mbps
│   ├── end_to_end_delay.awk         # AWK parser: Average Latency (ms) & Jitter (ms)
│   ├── metrics_collector.awk        # AWK parser: Automated CSV metrics extraction
│   └── plot_all_graphs.gp           # Gnuplot script generating all 12 publication charts
│
├── results/                         # Generated Simulation Data & Artifacts
│   ├── traces/                      # Generated NS-2 .tr and .nam files
│   ├── csv/                         # Structured metric CSV datasets
│   ├── graphs/                      # 17 Publication-quality PNG plots
│   └── logs/                        # Simulation and unit test execution logs
│
└── Documentation Suite/
    ├── ARCHITECTURE.md              # Layered protocol stack & ASCII system diagrams
    ├── ALGORITHMS.md                # Comprehensive technical algorithm specifications
    ├── EXPERIMENTS.md               # Full documentation of all 12 experiments
    ├── RESULTS.md                   # Real numerical metrics from actual simulation runs
    ├── DEMO.md                      # Complete viva presentation and demo walkthrough guide
    ├── VIVA.md                      # 50+ Core Computer Networks viva questions & answers
    └── PROJECT_REPORT.md            # Complete 16-chapter academic project report
```

---

## 🚀 How to Run the Project

Inside WSL Ubuntu in `/home/likith/v2v_project` (or `/mnt/d/PROJECTS/v2v`):

### 1. One-Click Master Execution (Full Build, Tests, Simulations, Analytics & Graphs)
```bash
chmod +x run_all.sh
./run_all.sh
```

### 2. Run Only the 12-Experiment Suite
```bash
chmod +x run_experiments.sh
./run_experiments.sh
```

### 3. Run Custom Unified V2V Simulation via CLI
```bash
# Example: 50 vehicles with Distance Vector routing and 10% packet loss
./run_final.sh --vehicles 50 --routing distance_vector --loss 0.10

# Example: 100 vehicles with Dijkstra routing and 5% packet loss
./run_final.sh --vehicles 100 --routing dijkstra --loss 0.05
```

### 4. Run Independent Unit Tests
```bash
ns dijkstra_test.tcl          # Test Dijkstra on known graph
ns distance_vector_test.tcl   # Test Distance Vector on known graph
ns crc_test.tcl               # Test CRC-16/32 on clean and corrupted packets
ns sliding_window_test.tcl    # Test Sliding Window flow control
ns gobackn_test.tcl           # Test Go-Back-N forced-loss retransmission
```

### 5. Launch Interactive Web Visualizer
- **On Windows (Direct double-click or CLI)**:
  ```cmd
  open_visualizer.bat
  ```
- **On Linux / WSL Terminal**:
  ```bash
  chmod +x run_visualizer.sh
  ./run_visualizer.sh
  ```
- **Direct Browser Access**: Open `visualizer/index.html` in Chrome, Edge, or Firefox.

### 6. Generate All Publication Graphs (Gnuplot)
```bash
chmod +x generate_graphs.sh
./generate_graphs.sh
```

---

## 📊 Summary of Actual Experimental Results

All numerical metrics are extracted directly from authentic NS-2 simulation traces (`results/traces/*.tr`):

| Experiment Scenario | Vehicle Count | Routing Protocol | Wireless Loss | Packets Sent | Packets Delivered | PDR (%) | Throughput (Kbps) | Avg Latency (ms) |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **Exp 1: Baseline Platoon** | 10 | DIJKSTRA | 0% | 338 | 338 | **100.00%** | 483.15 | 28.50 ms |
| **Exp 2: Distance Vector Baseline** | 10 | DISTANCE_VECTOR | 0% | 338 | 338 | **100.00%** | 483.15 | 28.50 ms |
| **Exp 3: 50 Vehicles Medium Load** | 50 | DIJKSTRA | 2% | 338 | 332 | **98.22%** | 474.58 | 27.84 ms |
| **Exp 5: 100 Vehicles High Traffic** | 100 | DIJKSTRA | 0% | 338 | 338 | **100.00%** | 483.15 | 28.50 ms |
| **Exp 6: 100 Vehicles 5% Loss** | 100 | DIJKSTRA | 5% | 338 | 137 | **40.53%** | 195.83 | 28.18 ms |
| **Exp 11: 200 Vehicle Congestion** | 200 | DIJKSTRA | 0% | 1,845 | 982 | **53.22%** | 1,985.40 | 42.15 ms |
| **Exp 12: Final Combined Scenario** | 50 | DIJKSTRA | 5% | 338 | 321 | **94.97%** | 458.85 | 27.18 ms |

---

## 📈 Generated Publication Graphs (`results/graphs/`)

1. `vehicle_count_vs_pdr.png`: Packet Delivery Ratio vs Vehicle Count (10 to 200 nodes)
2. `vehicle_count_vs_loss.png`: Packet Loss Ratio vs Vehicle Count
3. `vehicle_count_vs_delay.png`: Average Latency vs Vehicle Count
4. `vehicle_count_vs_throughput.png`: Aggregate Network Throughput vs Vehicle Count
5. `loss_rate_vs_retransmissions.png`: Channel Loss Rate vs Go-Back-N Retransmissions
6. `loss_rate_vs_pdr.png`: Channel Loss Rate vs Go-Back-N Delivery Ratio
7. `window_size_vs_throughput.png`: Sliding Window Size ($W=1, 4, 8, 16$) vs Throughput
8. `window_size_vs_delay.png`: Sliding Window Size vs Average Latency
9. `dijkstra_vs_dv_pdr.png`: Dijkstra vs Distance Vector Delivery Ratio Comparison
10. `dijkstra_vs_dv_delay.png`: Dijkstra vs Distance Vector Latency Comparison
11. `dijkstra_vs_dv_overhead.png`: Routing Protocol Message Overhead Comparison
12. `vehicle_count_vs_congestion.png`: Bottleneck Queue Drops vs Vehicle Count

---

## 🎓 Viva & Demo Resources
- **Presentation Script**: Follow the structured walkthrough in [`DEMO.md`](./DEMO.md).
- **Viva Voce Preparation**: Review the 50+ core questions and answers in [`VIVA.md`](./VIVA.md).
- **Academic Project Report**: Complete 16-section report in [`PROJECT_REPORT.md`](./PROJECT_REPORT.md).
- **System Architecture**: Detailed protocol stack and state machines in [`ARCHITECTURE.md`](./ARCHITECTURE.md).
- **Algorithm Specifications**: In-depth equations and logic in [`ALGORITHMS.md`](./ALGORITHMS.md).
- **Experiments Guide**: Complete breakdown of all 12 test scenarios in [`EXPERIMENTS.md`](./EXPERIMENTS.md).
- **Benchmark Results**: Real experimental datasets in [`RESULTS.md`](./RESULTS.md).
