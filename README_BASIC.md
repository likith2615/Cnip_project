# Phase 1: Basic NS-2 V2V Communication Simulation
## Autonomous Vehicle V2V Communication Simulator

This module provides the core, foundational **Network Simulator 2 (NS-2)** implementation of the Vehicle-to-Vehicle (V2V) communication network for autonomous vehicular platoons.

---

## 🚀 Key Features Implemented

1. **Configurable Number of Vehicles**:
   - Default: **10 vehicles** ($V_0 \dots V_9$).
   - Scalable: Dynamically supports **20, 50, 100, and 200 vehicles** via command-line flags.
2. **NS-2 Node Representation**:
   - Each autonomous vehicle is instantiated as an independent discrete-event network node in NS-2 with custom NAM labels and colors.
3. **Realistic Logical V2V Topology**:
   - **Platoon Direct In-Line Links**: $V_i \leftrightarrow V_{i+1}$ (10 Mbps, 5 ms delay, DropTail queue limit = 50).
   - **Multi-Lane Cross-Mesh Links**: $V_i \leftrightarrow V_{i+2}$ (10 Mbps, 8 ms delay) modeling adjacent lane DSRC radio coverage.
4. **V2V Safety & Telemetry Message Types**:
   - **`COLLISION_WARNING` (ECW)**: High-priority emergency collision warning broadcast ($V_0 \to V_{\text{tail}}$, 128 bytes, 50 Hz).
   - **`SUDDEN_BRAKING` (CAM)**: Event-triggered deceleration alert ($V_{\text{brake}} \to V_0$, 256 bytes, 25 Hz).
   - **`TRAFFIC_INFO` (BSM)**: Periodic cooperative awareness telemetry ($V_{\text{mid}} \to V_{\text{tail}}$, 512 bytes, 12.5 Hz).
5. **Metadata Support**:
   - Every message encapsulates: `Source Node`, `Destination Node`, `Message Type`, `Sequence Number`, `Payload Size (Bytes)`, `Timestamp (s)`, and vehicular telemetry (Deceleration, Speed).
6. **Configurable Packet Loss & Channel Error Model**:
   - Integrated NS-2 `ErrorModel` with `RandomVariable/Uniform` to simulate physical wireless channel packet loss ($0\%$ to $30\%$).
7. **Simulation Output Artifacts**:
   - Generates standard NS-2 12-column `.tr` trace files and `.nam` network animator files.

---

## 📂 File Summary

- `config.tcl`: Global configuration file holding all network, topology, queue, message, and error parameters.
- `basic_v2v.tcl`: Core NS-2 Tcl/OTcl simulation script with dynamic node creation, topology mesh setup, and traffic generators.
- `run_basic.sh`: One-click master script that runs the simulation, verifies packet transmission/reception with AWK, and executes scalability tests (20, 50, 100 vehicles).
- `README_BASIC.md`: Detailed documentation and usage instructions for Phase 1.

---

## 🛠️ Usage Instructions

### 1. One-Command Execution (Default 10 Vehicles)
```bash
chmod +x run_basic.sh
./run_basic.sh
```

### 2. Custom Node Scaling & Loss Rate Execution
You can execute `basic_v2v.tcl` directly with custom command-line overrides:

```bash
# Run with 20 vehicles and 10% packet loss
ns basic_v2v.tcl -num_vehicles 20 -loss_rate 0.10

# Run with 50 vehicles and 15% packet loss
ns basic_v2v.tcl -num_vehicles 50 -loss_rate 0.15

# Run with 100 vehicles
ns basic_v2v.tcl -num_vehicles 100 -loss_rate 0.05

# Run with 200 vehicles
ns basic_v2v.tcl -num_vehicles 200 -loss_rate 0.02 -simtime 10.0
```

### 3. Trace File Analysis with AWK
```bash
# Check Packet Delivery Ratio (PDR) and Dropped Packets
awk -f analysis/packet_delivery_ratio.awk basic_v2v.tr

# Check Average & Time-Series Network Throughput
awk -f analysis/throughput.awk basic_v2v.tr

# Check End-to-End Latency & Jitter
awk -f analysis/end_to_end_delay.awk basic_v2v.tr
```

---

## 📊 Sample Execution Output (10 Vehicles)

```
========================================================================
       AUTONOMOUS VEHICLE V2V NETWORK SIMULATION (PHASE 1)              
========================================================================
 Configuration Parameters:
   -> Number of Vehicles:      10
   -> Wireless Link Bandwidth: 10Mb
   -> Propagation Latency:     5ms
   -> Queue Limit / Type:      50 packets (DropTail)
   -> Channel Loss Rate:       5 %
   -> Simulation Duration:     5.0 seconds
   -> Output Trace:            basic_v2v.tr
   -> Output NAM:              basic_v2v.nam
========================================================================
 -> Injected ErrorModel with loss probability: 0.05
[V2V-METADATA] Time: 0.50s | Type: COLLISION_WARNING  | Src: V0 | Dst: V9 | Size: 128B | Decel: 8.5 m/s^2, Hazard: Stationary Obstacle
[V2V-METADATA] Time: 0.80s | Type: SUDDEN_BRAKING     | Src: V3 | Dst: V0 | Size: 256B | Decel: 6.2 m/s^2, Event: Hard Brake Active
[V2V-METADATA] Time: 1.00s | Type: TRAFFIC_INFO       | Src: V5 | Dst: V9 | Size: 512B | Speed: 90 km/h, Density: High, Route: Clear

=======================================================
     V2V PACKET DELIVERY RATIO (PDR) & LOSS SUMMARY    
=======================================================
 End-to-End Packets Generated: 337
 End-to-End Packets Delivered: 295
 End-to-End Packets Lost:      42
 Total Queue Drops Traced:     42
 Packet Delivery Ratio (PDR):  87.54 %
 Packet Loss Ratio:            12.46 %
=======================================================

=======================================================
           V2V THROUGHPUT ANALYSIS SUMMARY             
=======================================================
 Simulation Time:      0.50 to 4.53 s (Duration: 4.03 s)
 Total Data Received:  64000 bytes (295 packets)
 Average Throughput:   127.05 Kbps (0.1270 Mbps)
=======================================================

=======================================================
        V2V END-TO-END DELAY & JITTER SUMMARY          
=======================================================
 Successfully Traced Packets: 295
 Average End-to-End Delay:     27.184 ms
 Minimum Latency:             15.812 ms
 Maximum Latency:             46.215 ms
 Average Jitter (Variation):  0.024 ms
=======================================================
```
