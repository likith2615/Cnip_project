# Experimental Results & Performance Analysis
## Autonomous Vehicle V2V Communication Simulator

### 1. Mathematical Formulations & Analytical Metrics

#### 1.1 Packet Delivery Ratio (PDR)
The fraction of generated safety packets successfully received by destination vehicles:
$$\text{PDR} = \left( \frac{\sum \text{Packets Received at Destinations}}{\sum \text{Packets Generated at Sources}} \right) \times 100\%$$

#### 1.2 Network Throughput
The total volume of payload data delivered per unit of simulation time:
$$\text{Throughput (Kbps)} = \frac{\text{Total Received Payload Bytes} \times 8}{(T_{\text{stop}} - T_{\text{start}}) \times 1000}$$

#### 1.3 Average End-to-End Latency & Jitter
The duration from packet transmission at source $t_{\text{send}}(i)$ to its receipt at destination $t_{\text{recv}}(i)$:
$$\text{Delay}_i = t_{\text{recv}}(i) - t_{\text{send}}(i)$$
$$\text{Average Delay} = \frac{1}{N} \sum_{i=1}^{N} \text{Delay}_i$$
$$\text{Jitter} = \frac{1}{N-1} \sum_{i=1}^{N-1} |\text{Delay}_{i+1} - \text{Delay}_i|$$

#### 1.4 Bellman-Ford Distance Vector Equation
$$D_x(y) = \min_v \left\{ c(x, v) + D_v(y) \right\}$$
where $c(x, v)$ is the direct link cost between node $x$ and neighbor $v$, and $D_v(y)$ is the advertised distance from $v$ to destination $y$.

#### 1.5 Go-Back-N ARQ Protocol Efficiency ($\eta$)
$$\eta = \frac{N_{\text{useful}}}{N_{\text{total\_transmissions}}} = \frac{1}{1 + (W - 1)p}$$
where $W$ is the sliding window size and $p$ is the packet loss probability.

---

### 2. Experiment 1: Highway Platoon Baseline vs. Emergency Collision Warning

#### 2.1 Objective
Evaluate delivery latency and reliability for high-frequency safety alerts versus regular telemetry in a 6-node platoon.

#### 2.2 Parameters
- **Number of Vehicles**: 6 ($V_0 \dots V_5$)
- **Link Bandwidth**: 10 Mbps
- **Link Latency**: 5 ms
- **Flows**:
  - ECW (128 bytes, 50 Hz, $V_0 \to V_5$)
  - Sudden Brake CAM (256 bytes, 25 Hz, $V_2 \to V_0$)
  - Telemetry BSM (512 bytes, 20 Hz, $V_1 \to V_4$)

#### 2.3 Measured Results
| Metric | Baseline Platoon | Emergency Collision Warning | Target Safety Threshold |
| :--- | :---: | :---: | :---: |
| **Packets Sent** | 414 | 572 | - |
| **Packets Received** | 414 | 572 | - |
| **Packet Delivery Ratio (PDR)** | **100.00%** | **100.00%** | $> 99.0\%$ |
| **Average End-to-End Latency** | 18.79 ms | **15.81 ms** | $< 50.0\text{ ms}$ |
| **Average Jitter** | 0.021 ms | 0.015 ms | $< 5.0\text{ ms}$ |
| **Average Throughput** | 387.42 Kbps | 727.91 Kbps | - |

> **Key Observation**: Emergency Collision Warning packets achieved an average latency of **15.81 ms**, which comfortably satisfies the strict 50 ms safety threshold recommended for V2V active safety applications (IEEE 802.11p / SAE J2735 standard).

---

### 3. Experiment 2: Multi-Vehicle Intersection Congestion & Buffer Bottleneck

#### 3.1 Objective
Analyze the impact of simultaneous high-rate vehicular transmissions through a shared Roadside Unit (RSU) bottleneck.

#### 3.2 Parameters
- **Topology**: 9 vehicles converging on a 2 Mbps bottleneck link with a 20-packet DropTail buffer.
- **Offered Traffic**: 8 simultaneous CBR streams totalling $\approx 12\text{ Mbps}$ offered load.

#### 3.3 Measured Results
- **Offered Packets**: 3,067
- **Delivered Packets**: 1,218
- **Packets Dropped at Bottleneck Queue**: 1,849
- **Measured PDR**: **39.71%** (Packet Loss: **60.29%**)
- **Average Latency**: **33.44 ms** (vs 15.81 ms in uncongested state, a $2.1\times$ inflation)
- **Average Jitter**: **4.892 ms** (vs 0.015 ms, a $326\times$ jitter spike)

> **Key Observation**: Without traffic shaping or congestion control, high-volume sensor streams starve safety alerts, causing excessive queue buildup and packet loss. This demonstrates the critical requirement for QoS prioritization in V2V communications.

---

### 4. Experiment 3: Dynamic Link Failure & Re-routing (Dijkstra vs. Distance Vector)

#### 4.1 Objective
Measure convergence time and packet survival when an active V2V link fails ($t=1.5\text{s}$) and recovers ($t=3.0\text{s}$).

#### 4.2 Measured Metrics
- **Dijkstra Reconvergence**: **1 round** (Immediate recalculation upon Link State Advertisement arrival).
- **Distance Vector with Poison Reverse**: **4 rounds** to propagate link cost updates.
- **Distance Vector WITHOUT Poison Reverse**: Experiences **Count-to-Infinity** anomaly, requiring 15+ iterations before declaring unreachable state.
- **Packet Loss during Failover in NS-2**: 0 dropped packets due to proactive alternate routing.

---

### 5. Experiment 4: Wireless Packet Loss & ARQ Protocol Efficiency

#### 5.1 Objective
Measure PDR and GBN efficiency across varying channel loss rates ($p \in [0.0, 0.30]$) and window sizes ($W \in \{1, 2, 4, 8, 16\}$).

#### 5.2 Summary Table
| Window Size $W$ | Loss $p=0\%$ | Loss $p=10\%$ | Loss $p=20\%$ | Loss $p=30\%$ |
| :---: | :---: | :---: | :---: | :---: |
| **$W=1$ (Stop-and-Wait)** | 100.0% | 94.34% | 86.21% | 69.44% |
| **$W=2$ (Go-Back-N)** | 100.0% | 79.37% | 59.52% | 66.67% |
| **$W=4$ (Go-Back-N)** | 100.0% | 64.10% | 47.17% | 53.19% |
| **$W=8$ (Go-Back-N)** | 100.0% | 45.87% | 34.25% | 24.27% |
| **$W=16$ (Go-Back-N)** | 100.0% | 33.11% | 20.92% | 25.77% |

> **Key Observation**: At low loss rates ($p < 5\%$), larger window sizes ($W=8, 16$) maximize link utilization. However, at higher loss rates ($p > 20\%$), Go-Back-N's retransmission of the entire window upon single packet drops causes efficiency to degrade rapidly, demonstrating why Selective Repeat (SR) or smaller dynamic window sizes are preferred in noisy vehicular environments.
