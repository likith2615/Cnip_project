# Algorithmic Foundations & Protocol Specifications
## Autonomous Vehicle V2V Communication Simulator

This document provides complete technical specifications of all algorithms implemented in pure Tcl/OTcl within the V2V Simulator.

---

### 1. Dijkstra Link-State Shortest Path Routing

- **Implementation File**: [`dijkstra.tcl`](file:///d:/PROJECTS/v2v/dijkstra.tcl)
- **Unit Test File**: [`dijkstra_test.tcl`](file:///d:/PROJECTS/v2v/dijkstra_test.tcl)
- **Purpose**: Computes the minimum-latency, loop-free path from a source vehicle to all reachable vehicular destinations based on global Link-State topology information.
- **Inputs**:
  - Vehicular topology graph $G = (V, E)$
  - Edge weights $w(u, v) \in \mathbb{R}^+$ representing inter-vehicle link propagation delays (ms) and bandwidth costs.
- **Outputs**:
  - Shortest path vertex sequence: $[V_{\text{src}}, n_1, n_2, \dots, V_{\text{dst}}]$
  - Total path latency cost: $\sum w(e)$
  - Forwarding next-hop entry: $n_1$
- **Algorithm Principle**:
  1. Initialize $\text{dist}[s] = 0$, $\text{dist}[v] = \infty$ for all $v \ne s$, $\text{visited} = \emptyset$.
  2. Iteratively extract unvisited node $u$ with minimum tentative distance $\text{dist}[u]$.
  3. For every neighbor $v$ of $u$, perform edge relaxation:
     $$\text{If } \text{dist}[u] + w(u, v) < \text{dist}[v] \implies \text{dist}[v] \gets \text{dist}[u] + w(u, v), \quad \text{prev}[v] \gets u$$
  4. Backtrack from target to source using predecessor pointers $\text{prev}[\cdot]$.
- **Test Case**: Canonical test graph $A-B=2, A-C=5, B-C=1, B-D=4, C-D=1$. Evaluates path from $A$ to $D$. Result: $A \to B \to C \to D$ with cost $4.0$ ms (Next Hop: $B$).

---

### 2. Distance Vector (Bellman-Ford) Routing

- **Implementation File**: [`distance_vector.tcl`](file:///d:/PROJECTS/v2v/distance_vector.tcl)
- **Unit Test File**: [`distance_vector_test.tcl`](file:///d:/PROJECTS/v2v/distance_vector_test.tcl)
- **Purpose**: Decentralized routing protocol where each vehicle maintains a local routing vector and iteratively shares distance estimates with direct single-hop neighbors.
- **Inputs**:
  - Direct local link adjacency costs: $c(x, v)$
  - Advertised distance vectors from neighbors: $D_v(y)$
- **Outputs**:
  - Local routing table per node: `DESTINATION`, `DISTANCE/COST`, `NEXT_HOP`
  - Iteration round convergence count and update logs
- **Algorithm Principle (Bellman-Ford Equation)**:
  $$D_x(y) = \min_v \left\{ c(x, v) + D_v(y) \right\}$$
- **Loop Prevention (Poison Reverse)**:
  If vehicle $x$ routes to destination $y$ via neighbor $v$, $x$ advertises $D_x(y) = \infty$ to $v$. This breaks two-node routing loops and prevents the Count-to-Infinity problem during link dropouts.
- **Test Case**: Tested on reference graph. Converges in 3 iterations with 8 route table updates to optimal path $A \to B \to C \to D$ (Cost 4.0 ms).

---

### 3. Cyclic Redundancy Check (CRC-16 & CRC-32) Error Detection

- **Implementation File**: [`crc.tcl`](file:///d:/PROJECTS/v2v/crc.tcl)
- **Unit Test File**: [`crc_test.tcl`](file:///d:/PROJECTS/v2v/crc_test.tcl)
- **Purpose**: Physical/Data-link layer error detection for safety packets transmitted over noisy vehicular wireless channels (DSRC IEEE 802.11p).
- **Polynomials**:
  - **CRC-16-CCITT**: $G(x) = x^{16} + x^{12} + x^5 + 1$ (Binary: `10001000000100001`, 16-bit remainder)
  - **CRC-32-IEEE**: $G(x) = x^{32} + x^{26} + x^{23} + \dots$ (Binary: `100000100110000010001110110110111`, 32-bit remainder)
- **Inputs**:
  - Raw safety message string (e.g. `V2V|TYPE:EMERGENCY_BRAKE|SRC:V1|DST:V8|SEQ:101|DECEL:7.8`)
- **Outputs**:
  - Transmitted bitstream: $\text{DataBits} \mathbin{\Vert} \text{FCS}$
  - Receiver Verification: Syndrome $S(x)$ and boolean `valid` flag ($S(x) == 0 \implies \text{PASS}$).
- **Algorithm Principle**:
  1. Data bits $D(x)$ are padded with $r$ zeros: $D(x) \cdot x^r$.
  2. Modulo-2 binary long division (using bitwise XOR) by generator $G(x)$ calculates remainder $R(x)$ (Frame Check Sequence).
  3. Receiver divides received bits $(D(x) \cdot x^r + R(x))$ by $G(x)$. Remainder must equal zero for uncorrupted frames.
- **Test Case**: 2,000 multi-payload trials across error rates $p \in [0.0, 0.20]$. Achieved 100.00% detection of all single-bit flips and burst errors.

---

### 4. Sliding Window Flow Control

- **Implementation File**: [`sliding_window.tcl`](file:///d:/PROJECTS/v2v/sliding_window.tcl)
- **Unit Test File**: [`sliding_window_test.tcl`](file:///d:/PROJECTS/v2v/sliding_window_test.tcl)
- **Purpose**: Prevents fast transmitting vehicles from overwhelming slower receiver vehicle buffers by constraining the maximum number of unacknowledged packets in flight.
- **Inputs**:
  - Window size: $W \in \{1, 4, 8, 16\}$
  - Packet stream sequence: $\text{Seq } 0 \dots N-1$
- **Outputs**:
  - State variables: `SEND_BASE`, `NEXT_SEQUENCE_NUMBER`, `WINDOW_END`, `OUTSTANDING_PACKETS`
  - Event logs: `SEND seq=k`, `ACK seq=k`, `WINDOW_SHIFT base=k`, `TIMEOUT seq=k`
  - Benchmark dataset: `window_results.csv`
- **Algorithm Principle**:
  - Sender transmission condition: $\text{NEXT\_SEQ} < \text{SEND\_BASE} + W$.
  - Upon receiving cumulative ACK for seq $K$, shift window: $\text{SEND\_BASE} \gets K + 1$.
- **Test Case**: Verifies window saturation at $W=4$, window shift on ACK 1, and next-seq rewind on timeout.

---

### 5. Go-Back-N (GBN) ARQ Protocol

- **Implementation File**: [`gobackn.tcl`](file:///d:/PROJECTS/v2v/gobackn.tcl)
- **Unit Test File**: [`gobackn_test.tcl`](file:///d:/PROJECTS/v2v/gobackn_test.tcl)
- **Purpose**: Automatic Repeat reQuest (ARQ) reliability engine providing guaranteed in-order delivery over lossy vehicular wireless channels.
- **Inputs**:
  - Window size $W$, total packets $N$, packet loss probability $p$, timeout ticks.
- **Outputs**:
  - Event logs: `SEND`, `RECEIVE`, `LOSS`, `ACK`, `TIMEOUT`, `RETRANSMIT`
  - Metrics dataset: `gobackn_results.csv`
- **Algorithm Principle**:
  1. Sender maintains a single timer for the oldest unacknowledged packet $\text{SEND\_BASE}$.
  2. Receiver accepts strictly in-order packets ($\text{seq} == \text{EXPECTED\_SEQ}$) and returns cumulative ACKs. Out-of-order packets are discarded with duplicate ACKs.
  3. On timeout of base packet, sender rewinds $\text{NEXT\_SEQ} \gets \text{SEND\_BASE}$ and retransmits all packets in the current window.
- **Test Case**: Deterministic test forcing packet #3 to drop. Correctly discards out-of-order packets 4, 5, 6, triggers timeout on packet 3, and retransmits 3, 4, 5, 6 for 100% successful delivery.

---

### 6. Active Congestion Control & Rate Adaptation (AIMD)

- **Implementation File**: [`congestion.tcl`](file:///d:/PROJECTS/v2v/congestion.tcl)
- **Simulation Script**: [`v2v_congestion_sim.tcl`](file:///d:/PROJECTS/v2v/v2v_congestion_sim.tcl)
- **Purpose**: Dynamically adjusts vehicular safety and telemetry transmission intervals to prevent persistent queue overflow and buffer collapse at Roadside Units (RSUs).
- **Algorithm Principle**:
  - **Congestion Detection**: Monitors bottleneck link queue drop counters over periodic observation windows $\Delta t = 0.2\text{s}$.
  - **Multiplicative Decrease (MD)**: Upon detecting packet drops ($\Delta \text{Drops} > 0$), double sending interval (cut transmission rate by 50%):
    $$\text{Interval}_{\text{new}} \gets \min(\text{Interval}_{\text{curr}} \times 2.0, \text{Interval}_{\max})$$
  - **Additive Increase (AI)**: When queue loss is zero, linearly decrease sending interval by small increment $\delta = 0.005\text{s}$ to probe for available bandwidth:
    $$\text{Interval}_{\text{new}} \gets \max(\text{Interval}_{\text{curr}} - 0.005, \text{Interval}_{\min})$$
