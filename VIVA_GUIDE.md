# Academic Viva Voce Preparation Guide
## Autonomous Vehicle V2V Communication Simulator

This guide contains the most frequently asked questions during Computer Networks academic project evaluations and viva examinations, paired with precise, high-scoring technical answers.

---

### Section 1: Project Overview & Motivation

#### Q1: What is the core problem your project addresses?
**Answer**:
Autonomous vehicles operating in platoons or urban corridors need to exchange safety-critical messages (such as Emergency Collision Warnings and Sudden-Braking Alerts) within strict latency bounds ($< 50\text{ ms}$) and with high reliability. When multiple vehicles transmit simultaneously, wireless contention and queue overflows cause packet loss and delay spikes. Our project models this environment in NS-2 and implements key Computer Networks mechanisms: Dijkstra/DV routing for dynamic path selection, CRC for error detection, Sliding Window/Go-Back-N ARQ for flow/error recovery, and TCP Reno for congestion management.

#### Q2: Why did you use NS-2 instead of writing a pure Python network simulator?
**Answer**:
NS-2 is a industry-standard, validated discrete-event network simulation engine with exact packet-level timing, realistic MAC/PHY layer queues (DropTail/RED), and accurate trace generation. Pure Python scripts often abstract away physical transmission queues and packet scheduling. In our project, NS-2 runs the actual network simulation and generates standard 12-column `.tr` trace files, while AWK and Python are used for analytical post-processing and metric calculation.

---

### Section 2: Routing Protocols (Dijkstra vs. Distance Vector)

#### Q3: How does Dijkstra's algorithm work in your V2V Link-State routing module?
**Answer**:
Dijkstra's algorithm is a centralized / global Shortest Path First (SPF) algorithm:
1. Every vehicle floods Link State Advertisements (LSAs) so each node builds a complete topology graph $G=(V, E)$.
2. The source initializes distances to all nodes as $\infty$, and $0$ for itself.
3. It iteratively picks the unvisited node $u$ with minimum tentative distance, marks it visited, and **relaxes** all adjacent edges $(u, v)$:
   $$\text{If } \text{dist}[u] + \text{weight}(u, v) < \text{dist}[v], \quad \text{update } \text{dist}[v] = \text{dist}[u] + \text{weight}(u, v)$$
4. It builds a Shortest Path Tree (SPT) and constructs the node's forwarding table.

#### Q4: What is the Bellman-Ford equation in Distance Vector routing?
**Answer**:
Distance Vector is a distributed algorithm where each vehicle maintains a vector of estimated costs to all destinations and periodically exchanges it with direct neighbors. The core update equation is:
$$D_x(y) = \min_v \{ c(x, v) + D_v(y) \}$$
where $c(x, v)$ is the cost of the link from $x$ to neighbor $v$, and $D_v(y)$ is $v$'s advertised distance to destination $y$.

#### Q5: What is the "Count-to-Infinity" problem in Distance Vector, and how did you resolve it?
**Answer**:
When a link between two vehicles breaks, adjacent nodes may use outdated routing info from each other, creating a two-node routing loop where metric values incrementally count up to infinity (or a designated threshold like 16 or 999).
We resolved this by implementing **Poison Reverse** (and Split Horizon):
If vehicle $A$ routes to destination $Y$ through neighbor $B$, $A$ advertises to $B$ that its distance to $Y$ is $\infty$ ($D_A(Y) = \infty$). This prevents $B$ from ever mistakenly routing back through $A$ to reach $Y$.

---

### Section 3: Error Detection & CRC (Cyclic Redundancy Check)

#### Q6: Explain the mathematical principle behind CRC-16 and CRC-32.
**Answer**:
CRC treats data as coefficients of a binary polynomial $D(x)$ and uses a predefined generator polynomial $G(x)$ of degree $r$:
1. At sender: The data bitstream is appended with $r$ zeros: $D(x) \cdot x^r$.
2. Modulo-2 binary polynomial division (using XOR without carries/borrows) is performed:
   $$\frac{D(x) \cdot x^r}{G(x)} = Q(x) + \frac{R(x)}{G(x)}$$
3. The remainder $R(x)$ is the $r$-bit **Frame Check Sequence (FCS)** appended to the frame.
4. At receiver: The entire received frame $T(x) = D(x) \cdot x^r + R(x)$ is divided by $G(x)$.
5. If remainder (syndrome) $S(x) = 0$, no error is detected; if $S(x) \ne 0$, an error occurred and the frame is rejected.

#### Q7: Why is CRC superior to simple parity or checksums for V2V wireless communication?
**Answer**:
- Simple parity only detects single-bit errors (50% failure on double-bit errors).
- Internet checksums can miss transposed bytes or symmetric bit flips.
- CRC guarantees detection of:
  - 100% of all single-bit errors.
  - 100% of all double-bit errors (provided polynomial contains appropriate terms).
  - 100% of all odd number of bit errors (if $G(x)$ has $(x+1)$ as a factor).
  - 100% of all burst errors of length $\le r$ bits (e.g. up to 16 bits for CRC-16, up to 32 bits for CRC-32).

---

### Section 4: Flow Control & Go-Back-N ARQ

#### Q8: How does Go-Back-N ARQ operate, and what is the sliding window rule?
**Answer**:
Go-Back-N allows the sender to transmit up to $W$ consecutive frames without waiting for an individual ACK:
- The sender window is bounded by $[S_{\text{base}}, S_{\text{base}} + W - 1]$.
- The receiver accepts **only in-order frames** ($R_{\text{expected}}$) and sends cumulative ACKs. If an out-of-order frame arrives, it is discarded and a duplicate ACK for the last in-order frame is returned.
- The sender maintains a single timer for the oldest unacknowledged packet ($S_{\text{base}}$).
- On timeout, the sender rewinds $S_{\text{next}}$ back to $S_{\text{base}}$ and **retransmits all unacknowledged packets in the window** ("Go Back N").

#### Q9: What is the maximum window size in Go-Back-N with $m$-bit sequence numbers?
**Answer**:
The maximum window size is:
$$W_{\max} = 2^m - 1$$
If $W = 2^m$, the receiver cannot distinguish whether an ACK is for the current window or the previous window if all ACKs are lost, creating sequence number ambiguity.

---

### Section 5: TCP Congestion Control Dynamics

#### Q10: Describe the 4 phases of TCP Reno Congestion Control seen in your simulation.
**Answer**:
1. **Slow Start**: Starts with $cwnd = 1\text{ MSS}$. For each ACK received, $cwnd \gets cwnd + 1$ (exponential doubling each RTT: $1, 2, 4, 8 \dots$) until $cwnd \ge ssthresh$.
2. **Congestion Avoidance (AIMD)**: Linear growth phase. For each RTT, $cwnd \gets cwnd + 1$ (Additive Increase) to gently probe available bandwidth.
3. **Multiplicative Decrease**: When packet drop occurs:
   - On 3 Duplicate ACKs (Fast Retransmit): $ssthresh \gets cwnd / 2$, $cwnd \gets ssthresh + 3$ (Fast Recovery).
   - On Timeout: $ssthresh \gets cwnd / 2$, $cwnd \gets 1\text{ MSS}$ (Drop back to Slow Start).
4. **Fast Recovery**: Skips Slow Start upon 3 duplicate ACKs and directly resumes linear Congestion Avoidance.

---

### Section 6: NS-2 Simulation Trace Structure

#### Q11: Explain the 12 fields of an NS-2 trace line.
**Answer**:
In our generated `.tr` files:
```
+ 0.5 0 1 cbr 512 ------- 1 0.0 5.0 0 0
```
1. `event`: `+` (enqueued), `-` (dequeued), `r` (received), `d` (dropped).
2. `time`: Simulation timestamp in seconds.
3. `from_node`: Source node of link.
4. `to_node`: Destination node of link.
5. `pkt_type`: Packet protocol (`cbr`, `tcp`, `ack`, `rtProtoDV`).
6. `pkt_size`: Packet size in bytes (e.g. 512, 1024).
7. `flags`: 7-character flag string (`-------`).
8. `fid`: Flow ID (used for coloring and flow identification).
9. `src_addr`: Source node address and port (`0.0`).
10. `dst_addr`: Destination node address and port (`5.0`).
11. `seq_num`: Protocol sequence number.
12. `pkt_id`: Unique global packet identifier.
