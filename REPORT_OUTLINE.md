# Final Project Report Outline & Academic Template
## Autonomous Vehicle V2V Communication Simulator

This outline serves as a complete structural template for the academic Computer Networks Project Report submission.

---

### Title Page
- **Project Title**: Autonomous Vehicle V2V Communication Simulator
- **Course**: Computer Networks Laboratory (CSE)
- **Author / Student Name**: [Student Name & Roll No]
- **Supervisor / Guide**: [Faculty Name & Department]
- **Institution**: [University / College Name]
- **Academic Year**: 2026

---

### Table of Contents
1. **Abstract**
2. **Chapter 1: Introduction**
   - 1.1 Background & Motivation
   - 1.2 Problem Statement & Challenges
   - 1.3 Project Objectives
3. **Chapter 2: Literature Review & Theoretical Foundations**
   - 2.1 Vehicular Ad-Hoc Networks (VANETs) & DSRC / C-V2X
   - 2.2 Routing Protocols in Vehicular Topologies (Dijkstra vs. Distance Vector)
   - 2.3 Error Detection & Channel Coding (CRC-16 / CRC-32)
   - 2.4 Flow Control & ARQ Reliability (Sliding Window & Go-Back-N)
   - 2.5 Transport Layer Congestion Control (TCP Reno Dynamics)
4. **Chapter 3: System Architecture & Design**
   - 3.1 Overall System Architecture
   - 3.2 Protocol Stack Design
   - 3.3 Network Topologies & Vehicular Scenarios
   - 3.4 State Machines & Algorithm Flowcharts
5. **Chapter 4: Implementation Details**
   - 4.1 NS-2 Simulation Engine & Tcl/OTcl Scripts
   - 4.2 Dijkstra Link-State Routing Implementation (`dijkstra.py`)
   - 4.3 Distance Vector & Poison Reverse Implementation (`distance_vector.py`)
   - 4.4 CRC Polynomial Division & Noise Injector (`crc.py`)
   - 4.5 Go-Back-N ARQ Protocol State Machine (`go_back_n.py`)
   - 4.6 Trace Parsing & Analytical Pipeline (`analysis/*.awk`, `parse_traces.py`)
6. **Chapter 5: Experimental Results & Comparative Analysis**
   - 5.1 Scenario 1: Highway Platoon Baseline Safety Simulation
   - 5.2 Scenario 2: Emergency Collision Warning (ECW) Dissemination
   - 5.3 Scenario 3: Intersection Congestion & Buffer Bottleneck Analysis
   - 5.4 Scenario 4: Dynamic Link Failure & Re-routing Convergence
   - 5.5 Scenario 5: Parametric Wireless Packet Loss Study (0% to 20%)
   - 5.6 Scenario 6: TCP Congestion Window ($cwnd$) Dynamics
   - 5.7 Dijkstra vs Distance Vector Routing Comparison Matrix
   - 5.8 CRC Error Detection Performance Benchmarks
   - 5.9 Go-Back-N ARQ Efficiency vs. Loss Rate Study
7. **Chapter 6: Conclusion & Future Scope**
   - 6.1 Summary of Contributions
   - 6.2 Limitations & Real-world Challenges
   - 6.3 Future Enhancements (5G C-V2X, SUMO Mobility Integration, AI-based Routing)
8. **References**
9. **Appendix: Source Code & Trace Data Snippets**

---

### Abstract Template
> Connected and Autonomous Vehicles (CAVs) rely heavily on Vehicle-to-Vehicle (V2V) communication to exchange time-critical safety messages such as Emergency Collision Warnings (ECW) and Sudden-Braking Alerts. In this project, an academic-grade V2V Communication Simulator is designed and implemented using **Network Simulator 2 (NS-2)** as the core discrete-event simulation engine. The system models realistic vehicular topologies, including highway platoons, urban intersections, and dynamic wireless link dropouts. To address fundamental computer networking challenges, this work implements and evaluates: (1) **Dijkstra Link-State** versus **Distance Vector (Bellman-Ford)** routing with Poison Reverse, (2) **CRC-16 and CRC-32** error detection under simulated wireless channel noise, (3) **Sliding Window Flow Control and Go-Back-N ARQ** over lossy links, and (4) **TCP Reno Congestion Window Dynamics** ($cwnd$ and $ssthresh$) during multi-vehicle traffic saturation. Experimental results demonstrate that Emergency Collision Warnings achieve an average dissemination latency of **15.81 ms**, well within the 50 ms safety threshold, while heavy intersection load results in a 60.29% packet loss and a $2.1\times$ latency inflation. The complete simulation pipeline, automated AWK parsers, CSV metric datasets, and visualization plots are integrated into an automated, one-command execution framework.
