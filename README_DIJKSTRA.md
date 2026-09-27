# Phase 2: Dijkstra Routing Module & V2V Simulation Integration
## Autonomous Vehicle V2V Communication Simulator

This module implements **Dijkstra's Shortest Path Algorithm** in pure Tcl/OTcl as a reusable control-plane routing module for vehicular networks, verified independently against a canonical test graph and integrated with NS-2 discrete-event vehicular safety simulations.

---

## 📐 Algorithmic Design & Architecture

### 1. The Dijkstra Algorithm Module (`dijkstra.tcl`)
Dijkstra's algorithm is a greedy, centralized/global Link-State routing algorithm that calculates the minimum cost path from a source vertex $s$ to all other vertices in a weighted graph $G = (V, E, w)$:
1. **Initialization**:
   - Distance array: $\text{dist}[s] = 0$, and $\text{dist}[v] = \infty$ for all $v \ne s$.
   - Predecessor array: $\text{prev}[v] = \text{null}$.
   - Visited set: $S = \emptyset$.
2. **Iteration**:
   - Select unvisited node $u \notin S$ with minimum $\text{dist}[u]$.
   - Add $u$ to $S$.
   - For each neighbor $v$ of $u$, perform **Edge Relaxation**:
     $$\text{If } \text{dist}[u] + w(u, v) < \text{dist}[v] \implies \text{dist}[v] \gets \text{dist}[u] + w(u, v), \quad \text{prev}[v] \gets u$$
3. **Termination & Forwarding Table**:
   - Backtrack from target $t$ via $\text{prev}[\cdot]$ to reconstruct the optimal sequence $[s, n_1, n_2, \dots, t]$.
   - Next-hop entry for destination $t$ is recorded as $n_1$.

---

## 🔍 Honest Technical Explanation of NS-2 Interaction

> [!IMPORTANT]
> **Architectural Abstraction Model**:
> In this implementation, `dijkstra.tcl` operates as an **Application/Control-Plane Software-Defined Routing (SDR) Controller**, while NS-2 functions as the **Data-Plane Discrete-Event Packet Forwarding Engine**.

### How Control-Plane & Data-Plane Interact:
1. **Topology & Metric Synchronization**:
   - When the vehicular network topology is instantiated in NS-2 (e.g. duplex links with 10 Mbps bandwidth and 5–12 ms propagation delays), the corresponding link costs/weights are registered in the `DijkstraGraph` object.
2. **Dynamic Route Selection at Transmission Events**:
   - When a vehicle triggers a safety alert (e.g., at $t = 1.20\text{s}$, $V_1$ detects an emergency braking event and needs to send a warning to $V_8$), the control plane invokes `$g compute_shortest_path V1 V8`.
   - Dijkstra calculates the lowest latency path (`V1 -> V5 -> V8`, total cost = 15.0 ms) instead of the longer in-line platoon detour (`V1 -> V2 -> V3 -> V4 -> V5 -> V6 -> V7 -> V8`, cost = 35.0 ms).
3. **Data-Plane Traffic Provisioning & Trace Recording**:
   - The computed optimal path is used to provision the NS-2 transport and traffic agents (UDP/CBR) between source and destination.
   - NS-2 transmits discrete packets through the underlying physical/MAC layer queues, generating genuine `.tr` trace events.
4. **Event Logging**:
   - Every route computation event is logged to the console in standard format and exported to `routing_results.csv`.

---

## 🧪 Independent Verification Test (`dijkstra_test.tcl`)

### Required Reference Graph:
- $A - B = 2$
- $A - C = 5$
- $B - C = 1$
- $B - D = 4$
- $C - D = 1$

```
          (2)
    [A] --------> [B]
     |             |  \ (4)
     | (5)     (1) |   v
     v             v   [D]
    [C] --------> [D]
          (1)
```

### Path Evaluation from A to D:
1. Candidate Path 1: $A \to C \to D \implies 5 + 1 = 6$
2. Candidate Path 2: $A \to B \to D \implies 2 + 4 = 6$
3. **Candidate Path 3 (Optimal)**: $A \to B \to C \to D \implies 2 + 1 + 1 = \mathbf{4.0}$

### Test Execution Output:
```
========================================================================
       DIJKSTRA ROUTING MODULE INDEPENDENT VERIFICATION TEST            
========================================================================
 Graph Topology Configured:
   A --(2)--> B
   A --(5)--> C
   B --(1)--> C
   B --(4)--> D
   C --(1)--> D
------------------------------------------------------------------------
 Computed Shortest Path Analysis from A to D:
   -> Path:      A->B->C->D
   -> Next Hop:  B
   -> Cost:      4.0
   -> Status:    SUCCESS
------------------------------------------------------------------------
 [PASS] Shortest path correctly identified: A->B->C->D
 [PASS] Total path cost correctly calculated: 4.0
 [PASS] Next hop forwarding entry correct: B
------------------------------------------------------------------------
 Full Routing Table from Node A:
   Dest: A   | Next Hop: A   | Cost: 0.0  | Path: A
   Dest: B   | Next Hop: B   | Cost: 2.0  | Path: A->B
   Dest: C   | Next Hop: B   | Cost: 3.0  | Path: A->B->C
   Dest: D   | Next Hop: B   | Cost: 4.0  | Path: A->B->C->D
========================================================================
 [SUCCESS] All Dijkstra unit test assertions PASSED.
```

---

## 📊 V2V Integrated Simulation & Routing Log (`routing_results.csv`)

### Console Event Log:
```
TIME=0.50
SOURCE=V0
DESTINATION=V9
ALGORITHM=DIJKSTRA
PATH=V0->V1->V5->V8->V9
COST=25.0

TIME=1.20
SOURCE=V1
DESTINATION=V8
ALGORITHM=DIJKSTRA
PATH=V1->V5->V8
COST=15.0

TIME=2.00
SOURCE=V2
DESTINATION=V7
ALGORITHM=DIJKSTRA
PATH=V2->V5->V6->V7
COST=16.0

[LINK-EVENT] At t=2.80s, link V2-V5 undergoes wireless blockage (Link Down).

TIME=3.00
SOURCE=V1
DESTINATION=V8
ALGORITHM=DIJKSTRA
PATH=V1->V5->V8
COST=15.0
```

### Generated CSV (`routing_results.csv`):
```csv
TIME,SOURCE,DESTINATION,ALGORITHM,PATH,NEXT_HOP,COST,STATUS
0.50,V0,V9,DIJKSTRA,V0->V1->V5->V8->V9,V1,25.0,SUCCESS
1.20,V1,V8,DIJKSTRA,V1->V5->V8,V5,15.0,SUCCESS
2.00,V2,V7,DIJKSTRA,V2->V5->V6->V7,V5,16.0,SUCCESS
3.00,V1,V8,DIJKSTRA,V1->V5->V8,V5,15.0,SUCCESS
```

---

## 🚀 How to Run

To run the complete verification test and integrated V2V simulation:
```bash
chmod +x run_dijkstra.sh
./run_dijkstra.sh
```

To run only the unit test:
```bash
ns dijkstra_test.tcl
```

To run the V2V simulation:
```bash
ns v2v_dijkstra_sim.tcl
```
