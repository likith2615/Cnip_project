# PROJECT IMPLEMENTATION PLAN
## Autonomous Vehicle V2V Communication Simulator

### 1. Executive Summary & Objectives
This project implements an academic, full-featured **Autonomous Vehicle Vehicle-to-Vehicle (V2V) Communication Simulator** using **NS-2 (Network Simulator 2)** as the core simulation engine, coupled with modular implementations and comparative analytical engines for all core Computer Networks curriculum concepts:
- **Dijkstra Link-State Routing** vs. **Distance Vector (Bellman-Ford) Routing** in dynamic vehicular topologies.
- **CRC Error Detection** (CRC-16-CCITT and CRC-32-IEEE 802.3) with channel noise injection.
- **Sliding Window Flow Control** & **Go-Back-N ARQ** discrete-event protocol engine.
- **TCP Congestion Control** (Tahoe/Reno Slow Start, Congestion Avoidance, Fast Recovery) under multi-vehicle load.
- **NS-2 Multi-Scenario Vehicular Simulations** (Collision warnings, sudden braking alerts, traffic telemetry, link failures, packet loss models).
- **Automated Trace Analytics & Visualization Pipeline** using AWK, Python, Matplotlib, and Gnuplot.

---

### 2. System Architecture & Directory Structure

```
v2v_project/
├── PROJECT_PLAN.md                  # Implementation roadmap and system architecture
├── README.md                        # Project documentation and quick-start guide
├── ARCHITECTURE.md                  # Protocol stack and message flow design
├── EXPERIMENTS.md                   # Experimental results and performance analysis
├── VIVA_GUIDE.md                    # Academic viva preparation questions and answers
├── REPORT_OUTLINE.md                # Academic final report structure
├── run_all.sh                       # One-click master build, simulation, & analysis script
│
├── ns2/                             # Core NS-2 Simulation Scripts (Tcl/OTcl)
│   ├── v2v_baseline.tcl             # Multi-vehicle platoon safety message baseline
│   ├── v2v_collision_warning.tcl    # Emergency Collision Warning (ECW) & Sudden Braking (CAM)
│   ├── v2v_traffic_congestion.tcl   # High-density vehicle traffic & buffer bottleneck
│   ├── v2v_routing_dynamics.tcl     # Dynamic link break & re-routing (LS vs DV)
│   ├── v2v_packet_loss_study.tcl    # Parametric error-rate study (1% to 20% drop rates)
│   └── v2v_tcp_congestion.tcl       # TCP window dynamics (cwnd, ssthresh, RTT)
│
├── routing/                         # Routing Algorithm Implementations & Comparator
│   ├── dijkstra.py                  # Shortest Path First (Link-State) algorithm engine
│   ├── distance_vector.py           # Bellman-Ford Distance Vector engine + Count-to-Infinity
│   └── compare_routing.py           # Convergence, message complexity & route comparator
│
├── reliability/                     # Error Control & Flow Control Modules
│   ├── crc.py                       # Bitwise CRC-16/32 polynomial division & noise injector
│   ├── sliding_window.py            # Sliding Window flow control simulator
│   ├── go_back_n.py                 # Go-Back-N ARQ state machine & packet recovery
│   └── arq_simulation.py            # Throughput/efficiency vs loss rate parametric study
│
├── analysis/                        # Trace Parsing & Metrics Generation
│   ├── throughput.awk               # AWK script: Time-series and average throughput
│   ├── packet_delivery_ratio.awk    # AWK script: PDR (%), Sent, Received, Dropped
│   ├── end_to_end_delay.awk         # AWK script: Latency (ms) and Jitter (ms)
│   ├── parse_traces.py              # Unified trace parser & CSV metrics aggregator
│   └── plot_graphs.py               # Automated publication-quality chart generator
│
├── results/                         # Generated Simulation Data & Plots
│   ├── traces/                      # Generated NS-2 .tr and .nam files
│   ├── csv/                         # Processed metrics CSV files
│   └── graphs/                      # Output PNG figures for reports/viva
│
└── tests/                           # Verification & Validation Test Suite
    └── test_suite.py                # Automated unit tests for all modules
```

---

### 3. Phased Implementation Roadmap

#### Phase 1: Environment Setup & Project Foundation
- Verify NS-2, Tcl, AWK, Python3, Matplotlib, Gnuplot toolchain.
- Establish clean directory hierarchy and backup existing files.
- Author initial `PROJECT_PLAN.md`.

#### Phase 2: NS-2 Vehicular Simulation Scenarios (Tcl/OTcl)
- **Baseline Platoon Communication (`v2v_baseline.tcl`)**: 5-node highway platoon topology.
- **Emergency Safety Alerts (`v2v_collision_warning.tcl`)**: High-priority CBR/UDP collision and emergency brake alerts with strict delay bounds.
- **Congested Multi-Vehicle Network (`v2v_traffic_congestion.tcl`)**: Scaled 8-node intersection scenario with bottleneck links.
- **Dynamic Topology & Link Failures (`v2v_routing_dynamics.tcl`)**: Dynamic link downtime simulating vehicle blockage and rerouting.
- **TCP Congestion Control (`v2v_tcp_congestion.tcl`)**: Tracing cwnd dynamics across time.

#### Phase 3: Routing Algorithms Engine (Dijkstra vs. Distance Vector)
- **`dijkstra.py`**: Implementation of Dijkstra's algorithm for vehicular mesh graph, showing Shortest Path Tree (SPT), predecessor maps, and routing tables.
- **`distance_vector.py`**: Implementation of Bellman-Ford algorithm with asynchronous vector exchanges, Split Horizon, Poison Reverse, and Count-to-Infinity demonstration.
- **`compare_routing.py`**: Execution comparison (convergence steps, communication overhead, routing table size).

#### Phase 4: Reliability, Error Detection & ARQ Flow Control
- **`crc.py`**: Modulo-2 binary polynomial long-division algorithm for CRC-16 (0x1021) and CRC-32 (0xEDB88320/0x04C11DB7), frame formatting, and error burst detection test bench.
- **`sliding_window.py` & `go_back_n.py`**: Discrete-event state machine for Go-Back-N ARQ with sliding window frames, ACK/NACK timers, frame drops, and retransmissions.
- **`arq_simulation.py`**: Parametric simulation across window sizes $W \in \{1, 4, 8, 16\}$ and error rates $p \in [0.0, 0.30]$.

#### Phase 5: Metrics Extraction, AWK Parsers & Graph Generation
- Create dedicated, robust AWK scripts for NS-2 trace format.
- Create `parse_traces.py` to aggregate all simulation data into structured CSVs.
- Create `plot_graphs.py` to produce visual plots (PDR vs. Loss Rate, Throughput vs. Traffic Rate, End-to-End Delay, CWND Progression, ARQ Efficiency).

#### Phase 6: Orchestration, Testing & Full End-to-End Validation
- Build `run_all.sh` for one-command automated execution of the entire project pipeline.
- Implement comprehensive unit and integration tests in `tests/test_suite.py`.
- Run simulations, verify zero runtime errors, validate data integrity.

#### Phase 7: Academic Documentation & Viva Preparation Package
- Complete `README.md`, `ARCHITECTURE.md`, `EXPERIMENTS.md`, `VIVA_GUIDE.md`, and `REPORT_OUTLINE.md`.
