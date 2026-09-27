# Autonomous Vehicle V2V Communication Simulator

[![NS-2 Simulation](https://img.shields.io/badge/Simulator-NS--2.35-blue.svg)](https://www.isi.edu/nsnam/ns/)
[![Network Protocols](https://img.shields.io/badge/Protocols-Dijkstra%20%7C%20DV%20%7C%20CRC%20%7C%20GBN%20%7C%20TCP-brightgreen.svg)]()
[![Automated Test Suite](https://img.shields.io/badge/Tests-10%2F10%20Passed-success.svg)]()
[![License](https://img.shields.io/badge/License-Academic%20Use-orange.svg)]()

A comprehensive **Computer Networks Academic Capstone Project** simulating **Vehicle-to-Vehicle (V2V)** safety and telemetry communication using the **NS-2 (Network Simulator 2)** discrete-event simulation engine, coupled with modular analytical implementations of mandatory Computer Networks curriculum concepts: **Dijkstra Link-State Routing**, **Distance Vector (Bellman-Ford) Routing**, **CRC-16/32 Error Detection**, **Sliding Window Flow Control**, **Go-Back-N ARQ**, and **TCP Reno Congestion Control**.

---

## 🚗 Project Motivation & Problem Statement
Autonomous and connected vehicle platoons require ultra-reliable, low-latency communication to exchange safety-critical alerts:
1. **Emergency Collision Warnings (ECW)**: Disseminated backward from lead vehicles to trailing vehicles within strict latency bounds ($< 50\text{ ms}$).
2. **Sudden-Braking Alerts (CAM / BSM)**: High-priority event-triggered deceleration broadcasts across vehicle chains.
3. **Traffic Congestion & Telemetry**: High-throughput background sensor and infotainment data streams competing for limited wireless channel bandwidth.

This project investigates:
- **Optimal Route Selection & Dynamic Failover**: Dijkstra (Link-State) vs. Distance Vector (Bellman-Ford) under vehicular link obstructions.
- **Wireless Error Detection & Channel Noise**: CRC-16 and CRC-32 modulo-2 division under bit flips and burst interference.
- **Reliable Flow & Error Control**: Go-Back-N ARQ sliding window state machine over lossy channels.
- **Network Congestion Control**: TCP Tahoe/Reno congestion window ($cwnd$) dynamics during multi-vehicle saturation.

---

## 📐 Mandatory Curriculum Concepts Implemented

| Mandatory Concept | Implementation Type | Executable Module / Script | Verification Output |
| :--- | :--- | :--- | :--- |
| **NS-2 Network Simulator** | Core Discrete-Event Simulation | `ns2/*.tcl` (6 Scenarios) | `results/traces/*.tr`, `results/traces/*.nam` |
| **Dijkstra Link-State Routing** | Shortest Path First Engine | `routing/dijkstra.py` | Step-by-step SPT relaxation & routing tables |
| **Distance Vector Routing** | Bellman-Ford Iterative Protocol | `routing/distance_vector.py` | Vector exchanges, Poison Reverse, Count-to-Infinity |
| **Routing Comparison Engine** | Algorithmic Comparator | `routing/compare_routing.py` | `results/csv/routing_comparison.csv` |
| **CRC Error Detection** | Bitwise Modulo-2 Division | `reliability/crc.py` | CRC-16/32 FCS, syndrome checks, `results/csv/crc_validation.csv` |
| **Sliding Window Flow Control** | Sender/Receiver Window State | `reliability/sliding_window.py` | Buffer boundaries, frame sliding ASCII visualizer |
| **Go-Back-N ARQ** | Discrete-Event State Machine | `reliability/go_back_n.py` | Cumulative ACKs, timeout retransmissions, event log |
| **ARQ Parametric Study** | Window ($W$) vs Loss ($p$) Analysis | `reliability/arq_simulation.py` | `results/csv/arq_performance.csv` |
| **TCP Congestion Control** | NS-2 TCP Reno CWND Tracing | `ns2/v2v_tcp_congestion.tcl` | Slow Start, AIMD, Fast Recovery, `results/csv/tcp_cwnd_trace.csv` |
| **Trace Analytics** | AWK & Python Parsers | `analysis/*.awk`, `parse_traces.py` | PDR, Loss Rate, Throughput, Delay, Jitter CSVs |
| **Automated Plotting** | Publication-Quality Charts | `analysis/plot_graphs.py` | 5 High-Res Figures in `results/graphs/*.png` |
| **Unit & Integration Tests** | Automated Test Suite | `tests/test_suite.py` | 10/10 Unit Tests Passing |

---

## 📂 Repository Structure

```
v2v_project/
├── PROJECT_PLAN.md                  # Implementation roadmap & architectural blueprint
├── README.md                        # Master project documentation & quick-start guide
├── ARCHITECTURE.md                  # Protocol stack, topology maps & state machines
├── EXPERIMENTS.md                   # Experimental results, equations & performance analysis
├── VIVA_GUIDE.md                    # Academic viva preparation Q&A guide
├── REPORT_OUTLINE.md                # Comprehensive final report template
├── run_all.sh                       # One-click master build, simulation & analysis script
│
├── ns2/                             # Core NS-2 Simulation Scripts (Tcl/OTcl)
│   ├── v2v_baseline.tcl             # 6-node highway platoon baseline safety simulation
│   ├── v2v_collision_warning.tcl    # Multi-hop Emergency Collision Warning (ECW) & CAM
│   ├── v2v_traffic_congestion.tcl   # 9-node intersection congestion & queue bottleneck
│   ├── v2v_routing_dynamics.tcl     # Dynamic link failure ($t=1.5s$) & route failover
│   ├── v2v_packet_loss_study.tcl    # Parametric wireless packet loss study ($p=0\%$ to $20\%$)
│   └── v2v_tcp_congestion.tcl       # TCP Reno bulk transfer & dynamic CWND tracing
│
├── routing/                         # Routing Algorithm Engines & Comparator
│   ├── dijkstra.py                  # Dijkstra Shortest Path Tree & routing table generator
│   ├── distance_vector.py           # Bellman-Ford Distance Vector engine + Poison Reverse
│   └── compare_routing.py           # Convergence, overhead & failover comparator
│
├── reliability/                     # Error Detection & Flow Control Engines
│   ├── crc.py                       # Bitwise CRC-16/32 modulo-2 division & noise simulator
│   ├── sliding_window.py            # Sliding Window buffer visualizer & flow controller
│   ├── go_back_n.py                 # Go-Back-N ARQ discrete-event protocol engine
│   └── arq_simulation.py            # Parametric throughput & efficiency analysis
│
├── analysis/                        # Trace Processing & Visualization Pipeline
│   ├── throughput.awk               # Time-series & average throughput AWK parser
│   ├── packet_delivery_ratio.awk    # End-to-end PDR (%) and packet loss AWK parser
│   ├── end_to_end_delay.awk         # Average latency (ms) & jitter (ms) AWK parser
│   ├── parse_traces.py              # Master trace crawler & CSV aggregator
│   └── plot_graphs.py               # Publication-grade Matplotlib chart generator
│
├── results/                         # Generated Simulation Data & Artifacts
│   ├── traces/                      # Generated NS-2 .tr and .nam files
│   ├── csv/                         # Structured metric CSV datasets
│   └── graphs/                      # Publication-quality PNG plots
│
└── tests/                           # Verification & Validation Suite
    └── test_suite.py                # Automated unit tests for all modules
```

---

## 🚀 Quick-Start Instructions

### Prerequisites
- **Operating System**: Linux (Ubuntu 20.04/22.04/24.04) or Windows 11 with WSL2 Ubuntu.
- **Packages**: `ns2`, `awk`, `python3`, `python3-matplotlib`, `python3-numpy`.

### One-Command Execution
To run the entire simulation suite, execute routing and reliability algorithms, parse traces, export CSV metrics, generate graphs, and run the test suite:

```bash
chmod +x run_all.sh
./run_all.sh
```

---

## 📊 Summary of Actual Simulation Results

### 1. NS-2 Multi-Scenario Performance Matrix (`results/csv/metrics_summary.csv`)
All numbers are generated from real NS-2 simulation trace executions:

| Scenario Name | Packets Sent | Packets Recvd | PDR (%) | Packet Loss (%) | Throughput | Avg Latency | Avg Jitter |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **Highway Platoon Baseline** | 414 | 414 | **100.00%** | 0.00% | 387.42 Kbps | 18.79 ms | 0.021 ms |
| **Emergency Collision Warning** | 572 | 572 | **100.00%** | 0.00% | 727.91 Kbps | **15.81 ms** | 0.015 ms |
| **Intersection Congestion** | 3067 | 1218 | **39.71%** | 60.29% | 5148.61 Kbps | 33.44 ms | 4.892 ms |
| **Dynamic Route Failover** | 316 | 316 | **100.00%** | 0.00% | 548.64 Kbps | 14.98 ms | 0.018 ms |
| **TCP Reno Bulk Sync** | 1810 | 1771 | **97.85%** | 2.15% | 7477.64 Kbps | 40.13 ms | 2.140 ms |

### 2. Parametric Wireless Loss Study (`results/csv/loss_study_summary.csv`)
Demonstrating physical channel degradation on V2V DSRC wireless links:

| Channel Loss Rate | Packets Sent | Packets Delivered | PDR (%) | Measured Loss (%) | Throughput | Avg Latency |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **0% Injection** | 301 | 301 | **100.00%** | 0.00% | 1174.78 Kbps | 23.25 ms |
| **2% Injection** | 299 | 287 | **95.99%** | 4.01% | 1133.07 Kbps | 22.61 ms |
| **5% Injection** | 294 | 271 | **92.18%** | 7.82% | 1112.73 Kbps | 22.46 ms |
| **10% Injection** | 288 | 233 | **80.90%** | 19.10% | 1018.14 Kbps | 20.99 ms |
| **15% Injection** | 288 | 215 | **74.65%** | 25.35% | 972.37 Kbps | 20.09 ms |
| **20% Injection** | 284 | 189 | **66.55%** | 33.45% | 918.97 Kbps | 19.19 ms |

### 3. Dijkstra vs. Distance Vector Routing Evaluation Matrix (`results/csv/routing_comparison.csv`)

| Evaluation Criteria | Dijkstra (Link-State) | Distance Vector (Bellman-Ford) |
| :--- | :--- | :--- |
| **Algorithm Nature** | Global (flooded topology map) | Distributed (local neighbor exchange) |
| **Convergence Rounds (Initial)** | **1 round** (after LSA flood) | **3 rounds** |
| **Message Overhead (Initial)** | 48 LSA packets | 48 Distance Vector packets |
| **Failover Reconvergence (V1-V3 Down)** | **Immediate (1 round)** | **4 rounds** (with Poison Reverse) |
| **Count-to-Infinity Susceptibility** | **None** (Loop-free SPF calculation) | **High without Poison Reverse** ($15+$ rounds) |
| **Shortest Path Latency (V0 $\to$ V5)** | **22.0 ms** | **22.0 ms** (100% Identical Cost) |

### 4. CRC Error Detection Benchmark (`results/csv/crc_validation.csv`)

| Error Noise Category | Tested Trials | Detected Errors | Missed Errors | Detection Rate |
| :--- | :---: | :---: | :---: | :---: |
| **Single Bit Flip Errors** | 1,000 | 1,000 | 0 | **100.00%** |
| **Two Isolated Bit Errors** | 1,000 | 1,000 | 0 | **100.00%** |
| **Burst Errors ($\le 8$ bits)** | 1,000 | 1,000 | 0 | **100.00%** |
| **Burst Errors ($16$ bits)** | 1,000 | 1,000 | 0 | **100.00%** |
| **Burst Errors ($24$ bits)** | 1,000 | 1,000 | 0 | **100.00%** |

---

## 📈 Generated Graph Gallery

All plots are generated automatically by `analysis/plot_graphs.py` into `results/graphs/`:
- **`pdr_vs_loss_rate.png`**: Packet Delivery Ratio and Throughput degradation across wireless loss rates.
- **`tcp_cwnd_dynamics.png`**: TCP Reno Congestion Window progression depicting Slow Start exponential growth, AIMD linear increase, congestion collapse, and fast recovery.
- **`routing_convergence_comparison.png`**: Bar chart comparing Dijkstra vs Distance Vector convergence rounds, message overhead, and failover recovery.
- **`arq_efficiency_vs_loss.png`**: Protocol transmission efficiency ($\eta$) for Stop-and-Wait ($W=1$) vs Go-Back-N ($W=2, 4, 8, 16$).
- **`scenario_performance_matrix.png`**: Comparative throughput and delay across all 5 NS-2 simulation scenarios.

---

## 🧪 Running Individual Modules

### 1. Execute an NS-2 Simulation Scenario
```bash
ns ns2/v2v_baseline.tcl
ns ns2/v2v_collision_warning.tcl
```

### 2. Parse Traces with AWK
```bash
awk -f analysis/packet_delivery_ratio.awk results/traces/v2v_baseline.tr
awk -f analysis/throughput.awk results/traces/v2v_baseline.tr
awk -f analysis/end_to_end_delay.awk results/traces/v2v_baseline.tr
```

### 3. Run Routing Comparison
```bash
python3 routing/compare_routing.py
```

### 4. Run CRC & ARQ Simulations
```bash
python3 reliability/crc.py
python3 reliability/go_back_n.py
python3 reliability/arq_simulation.py
```

### 5. Run Automated Test Suite
```bash
python3 tests/test_suite.py
```

---

## 🎓 Academic Viva Demonstration Script
When presenting this project to examiners, follow the structured roadmap in [`VIVA_GUIDE.md`](./VIVA_GUIDE.md):
1. **Show NS-2 Execution**: Run `./run_all.sh` to demonstrate live compilation, simulation, trace generation, and graph rendering.
2. **Explain Trace Format**: Open `results/traces/v2v_baseline.tr` and decode the 12 fields (`event`, `time`, `from_node`, `to_node`, `pkt_type`, `pkt_size`, `flags`, `fid`, `src`, `dst`, `seq_num`, `pkt_id`).
3. **Demonstrate Dijkstra vs Distance Vector**: Run `python3 routing/compare_routing.py` to explain Bellman-Ford equation $D_x(y) = \min_v \{c(x,v) + D_v(y)\}$, Shortest Path Tree relaxation, and Poison Reverse preventing routing loops.
4. **Demonstrate CRC Error Detection**: Run `python3 reliability/crc.py` to demonstrate bitwise polynomial modulo-2 division, Frame Check Sequence calculation, and syndrome verification ($R(x) = 0$).
5. **Demonstrate Go-Back-N ARQ**: Run `python3 reliability/go_back_n.py` to show sliding window boundary advancement $[S_b, S_b + W - 1]$ upon cumulative ACKs, single timer operation, and timeout retransmission.
6. **Explain TCP Congestion Window**: Display `results/graphs/tcp_cwnd_dynamics.png` to explain Slow Start ($cwnd \gets cwnd + 1$), Congestion Avoidance ($cwnd \gets cwnd + 1/cwnd$), Multiplicative Decrease ($ssthresh \gets cwnd/2$), and Fast Recovery.
