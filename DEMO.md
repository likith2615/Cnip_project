# Autonomous Vehicle V2V Communication Simulator
# Complete Project Demonstration Guide & System Documentation (DEMO.md)

---

## 📌 1. Project Overview & Problem Statement

Modern autonomous vehicles operate in cooperative platoons where milliseconds determine safety. This project implements a comprehensive **Vehicle-to-Vehicle (V2V) Communication Simulator** using **Network Simulator 2 (NS-2)**, accompanied by **pure Tcl algorithm modules**, **pure AWK trace parsers**, **Gnuplot publication chart generation**, and an **interactive HTML5/Canvas Web Visualizer**.

### The Core Problem
In vehicular networks (VANETs) adhering to IEEE 802.11p DSRC standards:
1. **Emergency Collision Warnings (ECW)** must propagate from lead vehicles to trailing platoon members within strict latency bounds (**< 50 ms**).
2. **Wireless Channel Imperfections**: High-speed Doppler shifts, interference, and obstacles cause bit corruption, packet drops, and dynamic link breaks.
3. **Network Congestion**: Bottlenecks near Roadside Units (RSUs) cause buffer drops unless sender transmission rates adapt dynamically.

---

## 🛠️ 2. Technology Stack & Tools Used ("What We Used")

This project was built strictly using academic and industry-standard networking tools with **zero external Python dependencies in the core simulation engine**:

| Component | Technology | Exact Role in Project |
| :--- | :--- | :--- |
| **Core Network Simulator** | **NS-2 (v2.35)** | Discrete-event network simulation engine; schedules packet events, manages DropTail queues, and generates 12-column `.tr` trace files and `.nam` animations. |
| **Protocol Scripting** | **Pure Tcl / OTcl** | Object-oriented and functional scripting used to build custom protocol engines: Dijkstra, Distance Vector, CRC-16/32, Sliding Window, Go-Back-N, and AIMD. |
| **Trace Analytics** | **GNU AWK (`awk`)** | High-performance text parsing scripts that process hundreds of thousands of lines in `.tr` traces to calculate PDR (%), throughput (Kbps), average latency (ms), and jitter (ms). |
| **Publication Plotting** | **Gnuplot** | Script-driven plotting engine generating all 17 publication-quality PNG charts directly from CSV datasets. |
| **Interactive Visualizer** | **HTML5 Canvas, CSS3, ES6+ JS** | Real-time browser-based dashboard featuring Highway animation, Routing Lab, CRC Lab, ARQ flow control visualizer, and Viva defense mode. |
| **Automation Scripts** | **Bash (`.sh`) & Windows Batch (`.bat`)** | Shell pipelines for one-click test execution, 12-experiment batch runs, graph generation, and visualizer launching. |

---

## 🧠 3. Networking Concepts & Algorithms Implemented

| Layer / Concept | Protocol / Algorithm | Implementation File | Key Technical Highlight |
| :--- | :--- | :--- | :--- |
| **Network Layer** | **Dijkstra Link-State** | `dijkstra.tcl` | Centralized shortest path calculation ($O((V+E)\log V)$); deterministic path finding on mesh topologies. |
| **Network Layer** | **Distance Vector (Bellman-Ford)** | `distance_vector.tcl` | Distributed iterative route exchange; includes **Poison Reverse** to eliminate the Count-to-Infinity problem during link drops. |
| **Data Link Layer** | **CRC-16-CCITT & CRC-32** | `crc.tcl` | Bitwise polynomial modulo-2 division. 100% error detection rate on corrupted frames and burst errors. |
| **Transport Layer** | **Sliding Window Flow Control** | `sliding_window.tcl` | Sender/receiver window buffer management ($W=1, 4, 8, 16$) with cumulative ACKs preventing buffer overflow. |
| **Transport Layer** | **Go-Back-N ARQ Retransmission** | `gobackn.tcl` | Reliable delivery over lossy channels; window timer expiration triggers automatic rewind and retransmission. |
| **Transport Layer** | **AIMD Congestion Control** | `congestion.tcl` | Additive Increase (gradual rate ramp-up) and Multiplicative Decrease (instant halving upon drop detection). |
| **Application Layer** | **DSRC Safety Message Profiles** | `config.tcl` | Prioritized traffic flows: Collision Warning (50 Hz, 128B), Sudden Braking (25 Hz, 256B), Traffic Telemetry (12.5 Hz, 512B). |

---

## 📂 4. Complete File Inventory ("What Each File Does")

```
v2v/
├── config.tcl                   # Global parameters: bandwidth (10Mb), delay (5ms), queues, DSRC message profiles
├── basic_v2v.tcl                # Baseline NS-2 simulation script creating multi-node vehicular topologies
├── dijkstra.tcl                 # Dijkstra Link-State shortest path routing algorithm implementation
├── dijkstra_test.tcl            # Unit test verifying Dijkstra on canonical reference graph (Cost: 4.0ms)
├── distance_vector.tcl          # Distance Vector (Bellman-Ford) routing with Poison Reverse
├── distance_vector_test.tcl     # Unit test verifying DV convergence, routing tables, and Poison Reverse
├── crc.tcl                      # Bitwise CRC-16 and CRC-32 polynomial error detection module
├── crc_test.tcl                 # Unit test checking 2,000 packets across 0%, 5%, 10%, 20% error rates
├── sliding_window.tcl           # Sliding window flow control logic and parametric benchmark generator
├── sliding_window_test.tcl      # Unit test verifying window shifts, buffer full blocking, and timeout rewinds
├── gobackn.tcl                  # Go-Back-N ARQ protocol state machine and loss recovery engine
├── gobackn_test.tcl             # Unit test verifying forced-loss recovery (deliberately dropping Packet #3)
├── congestion.tcl               # Active AIMD congestion controller class for dynamic rate throttling
├── v2v_congestion_sim.tcl       # Multi-vehicle traffic congestion scaling simulation (10 to 200 nodes)
├── v2v_main.tcl                 # Master unified simulation engine combining all protocols and CLI options
│
├── run_all.sh                   # Master 8-step pipeline: tool checks, unit tests, 12 experiments, trace analysis, graphs
├── run_experiments.sh           # Automated batch execution of all 12 experimental research scenarios
├── run_final.sh                 # Flexible CLI simulation runner with automatic AWK trace parsing
├── generate_graphs.sh           # Gnuplot script compiling all 17 publication-grade PNG graphs
├── run_visualizer.sh            # Linux/WSL launcher for the web visualizer
├── open_visualizer.bat          # Windows 1-click launcher for the web visualizer
│
├── analysis/                    # Pure AWK & Gnuplot analytics toolchain
│   ├── packet_delivery_ratio.awk# Extracts packets sent, received, dropped, and calculates PDR (%)
│   ├── throughput.awk           # Calculates network throughput in Kbps and Mbps from trace timestamps
│   ├── end_to_end_delay.awk     # Calculates average latency (ms), minimum/maximum delay, and jitter (ms)
│   ├── metrics_collector.awk    # Single-line comma-separated metrics extractor for automated CSV builds
│   └── plot_all_graphs.gp       # Master Gnuplot plotting script for all 17 graphs
│
├── visualizer/                  # Interactive Web Visualizer (Zero external dependencies)
│   ├── index.html               # Multi-tab dashboard (Highway Live, Routing, CRC, ARQ, AIMD, Viva)
│   ├── style.css                # Dark-themed glassmorphism UI styling with responsive layout
│   └── app.js                   # High-performance HTML5 Canvas animation and protocol logic
│
├── results/                     # All generated research outputs and benchmark datasets
│   ├── csv/                     # Master CSV summary tables and comparison datasets
│   ├── graphs/                  # 17 Publication-ready high-resolution PNG charts
│   ├── logs/                    # Standard output logs from unit tests and simulation runs
│   └── traces/                  # NS-2 .tr packet traces and .nam visualizer files
│
└── Documentation Suite/
    ├── README.md                # Repository overview, badges, instructions, and results summary
    ├── DEMO.md                  # Complete viva presentation guide & demonstration manual (THIS FILE)
    ├── VIVA.md                  # 50+ Core Computer Networks viva voce questions and answers
    ├── PROJECT_REPORT.md        # Comprehensive 16-chapter academic project report
    ├── ARCHITECTURE.md          # Protocol stack, sequence diagrams, and ASCII architecture
    ├── ALGORITHMS.md            # Detailed algorithm pseudocode, complexity, and equations
    ├── EXPERIMENTS.md           # Deep dive into all 12 experimental test scenarios
    └── RESULTS.md               # Real numerical metrics from actual simulation runs
```

---

## 🚀 5. How to Run Everything ("How to Run")

All NS-2 simulations and trace analysis scripts run in **Linux / WSL (Ubuntu)**. The interactive visualizer runs in **any modern web browser** on both Windows and Linux.

### Prerequisites Check
Ensure the required toolchain is installed in WSL Ubuntu:
```bash
sudo apt-get update
sudo apt-get install -y ns2 gawk gnuplot
```

---

### Method 1: The Master 1-Click Pipeline (Recommended)
Executes all unit tests, all 12 experiments, trace analysis, and graph generation:
```bash
chmod +x run_all.sh
./run_all.sh
```
**Expected Output**:
- Dijkstra test: `PASS`
- Distance Vector test: `PASS`
- CRC test: `PASS`
- Sliding Window test: `PASS`
- Go-Back-N test: `PASS`
- NS-2 simulation: `PASS`
- Trace generation: `PASS`
- Trace analysis: `PASS`
- Graph generation: `PASS`
- Final integration: `PASS`

---

### Method 2: Running Unit Tests Individually
Run any protocol module unit test directly using NS-2:
```bash
# 1. Dijkstra Link-State routing verification
ns dijkstra_test.tcl

# 2. Distance Vector (Bellman-Ford) routing & Poison Reverse
ns distance_vector_test.tcl

# 3. CRC-16 and CRC-32 error detection across 2,000 packets
ns crc_test.tcl

# 4. Sliding Window flow control buffer & timeout test
ns sliding_window_test.tcl

# 5. Go-Back-N ARQ forced-loss retransmission test
ns gobackn_test.tcl
```

---

### Method 3: Running the 12-Experiment Automated Suite
Executes the full matrix of 12 vehicular scenarios and logs all metrics to `results/csv/experiments_master_summary.csv`:
```bash
chmod +x run_experiments.sh
./run_experiments.sh
```

---

### Method 4: Running Custom Simulation via CLI Runner
Use `run_final.sh` to run simulations with custom parameters and automatically view AWK analytics:
```bash
# Example A: 10 vehicles, Dijkstra routing, 0% loss
./run_final.sh --vehicles 10 --routing dijkstra --loss 0.00

# Example B: 50 vehicles, Distance Vector routing, 5% loss, window size 8
./run_final.sh --vehicles 50 --routing distance_vector --loss 0.05 --window 8

# Example C: 100 vehicles, high congestion, 10% loss
./run_final.sh --vehicles 100 --routing dijkstra --loss 0.10
```

---

### Method 5: Analyzing Traces with AWK
Parse any generated `.tr` trace file directly:
```bash
# Packet Delivery Ratio (PDR) and Loss Ratio
awk -f analysis/packet_delivery_ratio.awk results/traces/v2v_final_demo.tr

# Network Throughput (Kbps & Mbps)
awk -f analysis/throughput.awk results/traces/v2v_final_demo.tr

# Average Latency and Jitter
awk -f analysis/end_to_end_delay.awk results/traces/v2v_final_demo.tr
```

---

### Method 6: Generating Publication Charts
Generate or regenerate all 17 Gnuplot charts:
```bash
chmod +x generate_graphs.sh
./generate_graphs.sh
```
All charts will be saved to `results/graphs/*.png`.

---

### Method 7: Launching the Interactive Web Visualizer
- **On Windows**: Double-click `open_visualizer.bat` or run:
  ```cmd
  open_visualizer.bat
  ```
- **On Linux / WSL Terminal**:
  ```bash
  chmod +x run_visualizer.sh
  ./run_visualizer.sh
  ```
- **Direct Browser**: Open `visualizer/index.html` in Chrome, Edge, or Firefox.

---

## 🎬 6. Live Viva Demonstration Script (Step-by-Step Walkthrough)

Use this structured 7-step sequence when demonstrating the project to evaluators:

### Step 1: System Overview & Master Execution (Time: 0:00 – 1:30)
- **Action**: Open terminal and run:
  ```bash
  ./run_all.sh
  ```
- **Spoken Script**:
  > *"Respected evaluators, our project implements an Autonomous Vehicle V2V Communication Simulator built directly on Network Simulator 2 (NS-2). As shown on screen, `./run_all.sh` executes our automated pipeline: validating toolchains, running Tcl algorithm unit tests, executing 12 full NS-2 simulation experiments, parsing traces with AWK, and generating 17 publication-grade charts with Gnuplot—all with zero Python dependencies in the simulation core."*

---

### Step 2: Routing Protocols Demonstration (Time: 1:30 – 3:00)
- **Action**: Run the independent tests:
  ```bash
  ns dijkstra_test.tcl
  ns distance_vector_test.tcl
  ```
- **Spoken Script**:
  > *"For route selection, we implemented both Dijkstra Link-State and Distance Vector (Bellman-Ford) in pure Tcl. On our canonical reference topology, both algorithms deterministically find the optimal path $A \to B \to C \to D$ with a latency cost of $4.0\text{ ms}$. Furthermore, our Distance Vector module implements Poison Reverse to eliminate the Count-to-Infinity problem during vehicular link breaks."*

---

### Step 3: CRC Error Detection & Wireless Noise (Time: 3:00 – 4:15)
- **Action**: Run the CRC verification test:
  ```bash
  ns crc_test.tcl
  ```
- **Spoken Script**:
  > *"In vehicular wireless environments (IEEE 802.11p DSRC), packets experience interference and bit corruption. Our `crc.tcl` module implements bitwise modulo-2 polynomial division using the standard CRC-16-CCITT and CRC-32 polynomials. Across 2,000 packets tested under varying error rates, our receiver achieved a 100.00% error detection rate, successfully filtering out all single-bit flips and burst errors without false negatives."*

---

### Step 4: Flow Control & Go-Back-N ARQ (Time: 4:15 – 5:30)
- **Action**: Run the flow control and ARQ tests:
  ```bash
  ns sliding_window_test.tcl
  ns gobackn_test.tcl
  ```
- **Spoken Script**:
  > *"To guarantee reliable in-order safety message delivery over lossy channels, we implemented Sliding Window flow control and Go-Back-N ARQ. In our deterministic test, Packet #3 is intentionally dropped by the channel. The receiver detects out-of-order frames, returns duplicate ACKs, and upon sender timer expiration, Go-Back-N automatically rewinds and retransmits starting from frame #3 onward, achieving 100% reliable packet delivery."*

---

### Step 5: Congestion Scaling & AIMD Rate Adaptation (Time: 5:30 – 6:45)
- **Action**: Run a congestion test:
  ```bash
  ns v2v_congestion_sim.tcl 50
  ```
- **Spoken Script**:
  > *"When scaling from 10 to 200 vehicles, bottleneck links near Roadside Units experience buffer saturation. We implemented active AIMD Congestion Control: when queue drops occur, the controller dynamically applies Multiplicative Decrease, cutting transmission rates in half, and then gradually performs Additive Increase as queues clear, preventing catastrophic network collapse."*

---

### Step 6: Interactive Web Visualizer Demonstration (Time: 6:45 – 8:15)
- **Action**: Launch the visualizer by double-clicking `open_visualizer.bat` or opening `visualizer/index.html`.
- **Show Evaluators**:
  1. **Highway V2V Live tab**: Click *"Collision Warning"* and observe the red high-priority broadcast propagating from the lead vehicle down the platoon.
  2. **Routing Lab tab**: Switch between Dijkstra and Distance Vector, trigger a link break, and watch the dynamic re-routing in real time.
  3. **CRC Error Lab tab**: Corrupt a single bit in the binary payload and watch the CRC syndrome calculation reject the packet.
  4. **Flow Control & ARQ tab**: Slide the window size and trigger packet drops to observe Go-Back-N retransmission visually.
- **Spoken Script**:
  > *"To provide visual intuition for evaluators, we developed a standalone, modern Web Visualizer. Evaluators can interactively trigger collision alerts, simulate channel noise, and observe packet-level state machine transitions in real time."*

---

### Step 7: Trace Analytics & Conclusion (Time: 8:15 – 9:30)
- **Action**: Display the master summary table and charts:
  ```bash
  cat results/csv/experiments_master_summary.csv | head -n 14
  ls -lh results/graphs/
  ```
- **Spoken Script**:
  > *"Every metric in our report is parsed directly from authentic NS-2 `.tr` trace files using our custom AWK scripts. In our final combined scenario, Emergency Collision Warnings achieve a dissemination delay of 15.81 ms, well beneath the strict 50 ms active safety threshold. The simulator is complete, reproducible with a single command, and satisfies all networking curriculum requirements. We are now ready for viva questions."*

---

## 🎯 7. Quick Viva Voce Cheat Sheet

| Evaluator Question | Recommended Core Answer |
| :--- | :--- |
| **Why not use Python for the simulator?** | The core requirement was strict adherence to standard networking curricula utilizing NS-2 (C++ / OTcl engine) and Unix analytical tools (AWK, Gnuplot) for pure, deterministic discrete-event simulation. |
| **What is the critical latency for V2V safety?** | Active safety messages (ECW) require dissemination latency **strictly below 50 ms**. Our simulator achieves **15.81 ms** under normal conditions and **29.23 ms** under baseline load. |
| **How does Poison Reverse prevent Count-to-Infinity?** | If node $A$ routes to $D$ via neighbor $B$, $A$ advertises its distance to $D$ as $\infty$ to $B$. This prevents $B$ from ever attempting to route back through $A$, breaking the two-node routing loop. |
| **What is the CRC generator polynomial used?** | CRC-16-CCITT: $x^{16} + x^{12} + x^5 + 1$ (0x1021) and standard CRC-32 (0xEDB88320). |
| **What is the difference between Go-Back-N and Selective Repeat?** | Go-Back-N discards all out-of-order packets and retransmits the entire window starting from the lost packet ($N$). Selective Repeat buffers out-of-order packets and retransmits only the missing packet. |
| **What are the 12 columns of an NS-2 trace file?** | 1: Event type (`+`, `-`, `r`, `d`), 2: Time (s), 3: Source node, 4: Destination node, 5: Packet name, 6: Packet size (B), 7: Flags, 8: Flow ID (fid), 9: Source address, 10: Destination address, 11: Sequence number, 12: Unique packet ID. |

---

*End of Demonstration Guide.*
