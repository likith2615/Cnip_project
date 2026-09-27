# ======================================================================
# Autonomous Vehicle V2V Communication Simulator - Phase 1
# Global Configuration File: config.tcl
# ======================================================================

global opt msg

# Network & Topology Configuration
set opt(num_vehicles)      10          ;# Default 10 vehicles (supports 20, 50, 100, 200)
set opt(simtime)           5.0         ;# Simulation duration in seconds
set opt(bw)                10Mb        ;# Inter-vehicle link bandwidth (IEEE 802.11p DSRC standard)
set opt(delay)             5ms         ;# Propagation latency between adjacent vehicles
set opt(qlimit)            50          ;# Link queue capacity (packets)
set opt(qtype)             DropTail    ;# Queue management discipline

# Error & Loss Model Configuration
set opt(loss_rate)         0.05        ;# 5% wireless channel packet loss probability (configurable)

# Output Files
set opt(trace_file)        "basic_v2v.tr"
set opt(nam_file)          "basic_v2v.nam"

# ======================================================================
# V2V Safety & Telemetry Message Types Specifications
# ======================================================================
# 1. COLLISION_WARNING (ECW): High-priority emergency broadcast
set msg(COLLISION_WARNING,fid)      1
set msg(COLLISION_WARNING,size)     128    ;# Payload size in bytes
set msg(COLLISION_WARNING,interval) 0.02   ;# 50 Hz transmission frequency
set msg(COLLISION_WARNING,color)    "Red"

# 2. SUDDEN_BRAKING (CAM): Event-triggered deceleration alert
set msg(SUDDEN_BRAKING,fid)         2
set msg(SUDDEN_BRAKING,size)        256    ;# Payload size in bytes
set msg(SUDDEN_BRAKING,interval)    0.04   ;# 25 Hz transmission frequency
set msg(SUDDEN_BRAKING,color)       "Orange"

# 3. TRAFFIC_INFO (BSM): Periodic vehicle telemetry & road conditions
set msg(TRAFFIC_INFO,fid)           3
set msg(TRAFFIC_INFO,size)          512    ;# Payload size in bytes
set msg(TRAFFIC_INFO,interval)      0.08   ;# 12.5 Hz transmission frequency
set msg(TRAFFIC_INFO,color)         "Blue"
