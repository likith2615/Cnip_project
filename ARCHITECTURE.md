# System Architecture & Technical Design
## Autonomous Vehicle V2V Communication Simulator

### 1. High-Level Protocol Stack Design
The Autonomous Vehicle V2V Communication Simulator follows the layered OSI/TCP-IP reference architecture adapted for Vehicular Ad-Hoc Networks (VANETs):

```
+-------------------------------------------------------------------------+
|                        APPLICATION LAYER (V2V APPS)                     |
|  - Emergency Collision Warning (ECW)  - Sudden Braking Alert (CAM)      |
|  - Platoon Telemetry Beacon (BSM)     - High-Definition Map Sync (HDM)  |
+-------------------------------------------------------------------------+
                                    |
                                    v
+-------------------------------------------------------------------------+
|                         TRANSPORT LAYER                                 |
|  - UDP: Real-time Safety Broadcasts (Low Latency, Zero Connection)      |
|  - TCP Reno / Tahoe: Bulk Telemetry & HD Maps (Sliding Window, AIMD)   |
|  - Go-Back-N ARQ Engine: Custom Reliable Flow & Retransmission Control  |
+-------------------------------------------------------------------------+
                                    |
                                    v
+-------------------------------------------------------------------------+
|                         NETWORK / ROUTING LAYER                         |
|  - Dijkstra Link-State Shortest Path First (Complete Topology View)     |
|  - Distance Vector Bellman-Ford Routing (Distributed, Split Horizon)    |
|  - Dynamic Route Failover Engine (Link Drop Detection & Reconvergence)  |
+-------------------------------------------------------------------------+
                                    |
                                    v
+-------------------------------------------------------------------------+
|                       DATA LINK / MAC & PHY LAYER                       |
|  - IEEE 802.11p DSRC / C-V2X Physical Wireless Channel Model            |
|  - DropTail / RED Queue Buffer Management                               |
|  - CRC-16-CCITT & CRC-32 Frame Check Sequence Error Detection           |
+-------------------------------------------------------------------------+
```

---

### 2. Vehicular Network Topologies

#### 2.1 Scenario 1 & 2: Highway Platoon Topology (Linear with Cross-Mesh Links)
A 6-node platoon moving at $100\text{ km/h}$ on a highway corridor. Adjacent vehicles are separated by $30\text{ meters}$ with direct DSRC links ($10\text{ Mbps}$, $5\text{ ms}$ delay) plus redundant multi-hop bypass links:

```
[V0 - Lead Vehicle] <==== 10Mb, 5ms ====> [V1 - Car 1] <==== 10Mb, 5ms ====> [V2 - Truck]
       ||                                      ||                                   ||
       || (5Mb, 10ms)                          || (5Mb, 10ms)                       || (10Mb, 5ms)
       \/                                      \/                                   \/
[V3 - Car 2] <======== 10Mb, 5ms =======> [V4 - Van] <======== 10Mb, 5ms ======> [V5 - Tail]
```

- **Traffic Flow 1 (ECW)**: $V_0 \to V_5$ (High priority collision alert).
- **Traffic Flow 2 (Brake Alert)**: $V_2 \to V_0$ & $V_5$ (Heavy truck sudden braking).
- **Traffic Flow 3 (Telemetry)**: $V_1 \to V_4$ (Cooperative Awareness Message).

#### 2.2 Scenario 3: Urban Congested Intersection Topology
8 competing autonomous vehicles transmitting through an Intersection Hub ($V_8$) to a Roadside Unit ($RSU$) across a bottleneck link ($2\text{ Mbps}$, $20\text{ ms}$, queue limit = 20 packets):

```
  [V0 - Emergency] ----\
  [V1 - Car 1] ---------\
  [V2 - Truck] ----------\
  [V3 - Taxi 1] ----------+---> [V8 - Intersection Hub] ===== 2Mb, 20ms =====> [RSU - Roadside Unit]
  [V4 - Taxi 2] -> [V5] --/     (Buffer Limit = 20)      (Bottleneck Link)
  [V6 - Car 2] ----------/
  [V7 - Video Stream] --/
```

- **Congestion Mechanism**: Aggregate incoming traffic exceeds $12\text{ Mbps}$, filling the 20-packet queue at $V_8$, triggering packet drops ($d$ events) and delay inflation.

#### 2.3 Scenario 4: Dynamic Link Failure & Re-routing Topology
Evaluates route failover when link $V_1 \leftrightarrow V_3$ breaks at $t=1.5\text{s}$ and recovers at $t=3.0\text{s}$:

```
                   Primary Path (Cost = 15ms)
               +---- 5ms ---- [V1] ---- 5ms ---- [V3] ---- 5ms ----+
               |                                                   |
             [V0]                                                [V6]
               |                                                   |
               +---- 5ms ---- [V2] ---- 5ms ---- [V4] ---- 5ms ----+
                   Backup Detour Path (Cost = 20ms)
```

---

### 3. State Machine & Algorithmic Designs

#### 3.1 Go-Back-N ARQ Protocol State Machine
```
                       +-------------------+
                       |    SENDER IDLE    |
                       +-------------------+
                                 |
              [New Safety Packet & Window not full]
                                 |
                                 v
                       +-------------------+
                       |  TRANSMIT FRAME   |
                       |  Start Timer      |
                       +-------------------+
                                 |
            +--------------------+--------------------+
            |                                         |
     [ACK K Received]                         [Timer Expired]
            |                                         |
            v                                         v
+------------------------+               +--------------------------+
| Advance Window Base    |               |  GO BACK TO BASE:        |
| Base = K + 1           |               |  Retransmit all frames   |
| If Base == Next: Stop  |               |  from Base to Next - 1   |
| Else: Restart Timer    |               |  Restart Timer           |
+------------------------+               +--------------------------+
```

#### 3.2 CRC Polynomial Long Division Architecture
```
  Transmitter Side:
    [Data Bits D] + [k Zeros (0000...)] 
                    |
                    v (Modulo-2 XOR Division by Generator G(x))
           [Quotient Q] + [Remainder R (FCS)]
                    |
                    v
    Transmitted Frame: [Data Bits D] + [FCS Remainder R]

  Receiver Side:
    [Received Frame (D + R)]
                    |
                    v (Modulo-2 XOR Division by Generator G(x))
           [Syndrome Remainder S]
                    |
          +---------+---------+
          |                   |
       [S == 0]            [S != 0]
          |                   |
          v                   v
   (Frame Accepted)    (Error Detected: Drop Frame)
```

#### 3.3 TCP Reno Congestion Window State Transition
```
                   +------------------------+
                   |       SLOW START       | <-----------------+
                   | cwnd = 1 MSS           |                   |
                   | cwnd += 1 per ACK      |                   |
                   +------------------------+                   |
                                |                               |
                       [cwnd >= ssthresh]                       |
                                |                               |
                                v                               |
                   +------------------------+                   |
                   |  CONGESTION AVOIDANCE  |                   |
                   | cwnd += 1/cwnd per ACK |                   |
                   +------------------------+                   |
                                |                               |
                    +-----------+-----------+                   |
                    |                       |                   |
            [3 Duplicate ACKs]         [Timeout]                |
                    |                       |                   |
                    v                       +-------------------+
        +-----------------------+           ssthresh = cwnd / 2
        |     FAST RECOVERY     |           cwnd = 1
        | ssthresh = cwnd / 2   |
        | cwnd = ssthresh + 3   |
        +-----------------------+
                    |
              [New ACK Recv]
                    |
                    v
        (Return to Congestion Avoidance)
```
