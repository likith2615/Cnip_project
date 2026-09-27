# Project Demonstration & Viva Presentation Guide
## Autonomous Vehicle V2V Communication Simulator (7–10 Minute Walkthrough)

This guide provides a structured script and execution sequence for demonstrating the project to professors, evaluators, and examiners during practical laboratory evaluations and project defenses.

---

### ⏱️ Demonstration Timeline Overview

| Step | Time | Demonstration Action | Key Technical Concept Highlighted |
| :---: | :---: | :--- | :--- |
| **1** | 0:00 – 1:30 | **System Overview & One-Click Execution** | NS-2 architecture, DSRC vehicular parameters, toolchain |
| **2** | 1:30 – 3:00 | **Dijkstra vs Distance Vector Routing** | Shortest path calculation, Bellman-Ford convergence, Poison Reverse |
| **3** | 3:00 – 4:30 | **CRC Error Detection & Channel Noise** | Modulo-2 division, 100% burst/bit-flip detection, syndrome check |
| **4** | 4:30 – 6:00 | **Sliding Window & Go-Back-N ARQ** | Cumulative ACKs, window boundary shifts, forced loss retransmission |
| **5** | 6:00 – 7:30 | **Multi-Vehicle Congestion & AIMD Response** | Bottleneck queues, buffer drops, adaptive rate throttling |
| **6** | 7:30 – 9:00 | **Trace Verification & 12 Graph Gallery** | 12-column trace parsing with AWK, publication Gnuplot charts |
| **7** | 9:00 – 10:00 | **Conclusion & Viva Q&A Defense** | Academic readiness, safety latency (<50ms), takeaways |

---

### Detailed Step-by-Step Script

#### Step 1: System Overview & Master Execution (0:00 – 1:30)
**Action**: Open terminal and execute:
```bash
./run_all.sh
```
**Spoken Explanation**:
> "Respected evaluators, our project implements an Autonomous Vehicle Vehicle-to-Vehicle (V2V) Communication Simulator built directly on **Network Simulator 2 (NS-2)**. As shown on screen, `./run_all.sh` executes our automated pipeline: validating toolchains, running Tcl algorithm unit tests, executing 12 full NS-2 simulation experiments, parsing traces with AWK, and generating 12 publication-grade charts with Gnuplot—all with zero Python dependencies in the simulation core."

---

#### Step 2: Dijkstra vs. Distance Vector Routing (1:30 – 3:00)
**Action**: Run the independent tests:
```bash
ns dijkstra_test.tcl
ns distance_vector_test.tcl
```
**Spoken Explanation**:
> "For route selection, we implemented both **Dijkstra Link-State** and **Distance Vector (Bellman-Ford)** in pure Tcl. On our canonical test graph ($A-B=2, A-C=5, B-C=1, B-D=4, C-D=1$), both algorithms deterministically find the optimal path $A \to B \to C \to D$ with a latency cost of $4.0\text{ ms}$. Our Distance Vector module implements **Poison Reverse** to eliminate the Count-to-Infinity problem during dynamic vehicular link breaks."

---

#### Step 3: CRC Error Detection & Wireless Noise (3:00 – 4:30)
**Action**: Run the CRC verification test:
```bash
ns crc_test.tcl
```
**Spoken Explanation**:
> "In vehicular wireless environments (IEEE 802.11p DSRC), packets experience interference and bit corruption. Our `crc.tcl` module implements bitwise modulo-2 polynomial division using the standard CRC-16-CCITT and CRC-32 polynomials. When tested across 2,000 corrupted packets, the receiver achieved a **100.00% error detection rate**, rejecting all single-bit flips and burst errors without false negatives."

---

#### Step 4: Flow Control & Go-Back-N ARQ (4:30 – 6:00)
**Action**: Run the Sliding Window and Go-Back-N tests:
```bash
ns sliding_window_test.tcl
ns gobackn_test.tcl
```
**Spoken Explanation**:
> "To guarantee reliable in-order safety message delivery over lossy channels, we implemented **Sliding Window flow control** and **Go-Back-N ARQ**. In our deterministic test, Packet #3 is deliberately dropped by the channel. The receiver detects out-of-order frames 4, 5, and 6, returns duplicate ACKs, and upon sender timer expiration, Go-Back-N automatically rewinds and retransmits starting from #3 onward, ensuring 100% reliable packet delivery."

---

#### Step 5: Congestion Scaling & AIMD Rate Adaptation (6:00 – 7:30)
**Action**: Run a congestion test:
```bash
ns v2v_congestion_sim.tcl 50
```
**Spoken Explanation**:
> "When scaling from 10 to 200 vehicles, bottleneck links at Roadside Units experience buffer saturation. We implement active **AIMD Congestion Control**: when queue drops are detected, the controller dynamically applies Multiplicative Decrease, doubling the sending interval from 10ms to 20ms, and then gradually performs Additive Increase as queues clear, preventing total network collapse."

---

#### Step 6: Trace Analysis & Graph Inspection (7:30 – 9:00)
**Action**: Display generated graphs and trace metrics:
```bash
ls -lh results/graphs/
cat results/csv/experiments_master_summary.csv | head -n 14
```
**Spoken Explanation**:
> "Every number in our report is calculated directly from actual NS-2 trace files (`.tr`) using custom AWK parsers. We generated 12 distinct publication graphs illustrating PDR vs. Vehicle Count, Latency vs. Window Size, and Retransmissions vs. Loss Rate."

---

#### Step 7: Conclusion & Summary (9:00 – 10:00)
**Spoken Explanation**:
> "In conclusion, our Emergency Collision Warnings achieve a dissemination delay of **15.81 ms**, well under the strict $50\text{ ms}$ active safety threshold. The simulator is complete, reproducible with one command, and covers all mandatory networking curriculum concepts. We are now ready for viva questions."
