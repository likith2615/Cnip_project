# ======================================================================
# Autonomous Vehicle V2V Communication Simulator
# Scenario 2: Emergency Collision Warning (ECW) & Sudden Braking Alert
# Multi-Hop Safety Dissemination across Autonomous Platoon
# ======================================================================

set ns [new Simulator]

$ns color 1 Red       ;# Emergency Collision Warning
$ns color 2 Orange    ;# Sudden Braking CAM
$ns color 3 Purple    ;# Multi-hop Forwarding

exec mkdir -p results/traces

set tf [open results/traces/v2v_collision_warning.tr w]
$ns trace-all $tf

set nf [open results/traces/v2v_collision_warning.nam w]
$ns namtrace-all $nf

# ======================================================================
# 7 VEHICLE NODES (Platoon in highway convoy)
# ======================================================================
for {set i 0} {$i < 7} {incr i} {
    set v($i) [$ns node]
}

$v(0) label "V0-PlatoonLeader"
$v(1) label "V1-Follower1"
$v(2) label "V2-Follower2"
$v(3) label "V3-Follower3"
$v(4) label "V4-Follower4"
$v(5) label "V5-Follower5"
$v(6) label "V6-PlatoonTail"

$v(0) color "Red"
$v(1) color "Orange"

# ======================================================================
# WIRELESS V2V INTER-VEHICLE DSRC MESH LINKS
# Distance between vehicles ~30m -> Link latency ~3ms, 10Mbps bandwidth
# ======================================================================
for {set i 0} {$i < 6} {incr i} {
    set next [expr $i + 1]
    $ns duplex-link $v($i) $v($next) 10Mb 3ms DropTail
    $ns queue-limit $v($i) $v($next) 30
    $ns queue-limit $v($next) $v($i) 30
    $ns duplex-link-op $v($i) $v($next) orient right
}

# Cross links for redundant safety message paths
$ns duplex-link $v(0) $v(2) 10Mb 6ms DropTail
$ns duplex-link $v(2) $v(4) 10Mb 6ms DropTail
$ns duplex-link $v(4) $v(6) 10Mb 6ms DropTail

# ======================================================================
# SAFETY TRAFFIC GENERATION
# 1. Lead vehicle V0 sudden hazard detection -> broadcasts ECW to V6
# 2. Vehicle V1 sudden braking alert -> forwards to V4 and V6
# 3. Intermediate nodes relay warning backward through the platoon
# ======================================================================

# ECW Stream: V0 -> V6 (End of Platoon)
set udp_ecw [new Agent/UDP]
$udp_ecw set fid_ 1
$ns attach-agent $v(0) $udp_ecw

set null_ecw [new Agent/Null]
$ns attach-agent $v(6) $null_ecw
$ns connect $udp_ecw $null_ecw

set cbr_ecw [new Application/Traffic/CBR]
$cbr_ecw set packetSize_ 128
$cbr_ecw set interval_ 0.01   ;# 100 packets/sec for ultra-critical safety
$cbr_ecw attach-agent $udp_ecw

# Sudden Braking CAM: V1 -> V5
set udp_brake [new Agent/UDP]
$udp_brake set fid_ 2
$ns attach-agent $v(1) $udp_brake

set null_brake [new Agent/Null]
$ns attach-agent $v(5) $null_brake
$ns connect $udp_brake $null_brake

set cbr_brake [new Application/Traffic/CBR]
$cbr_brake set packetSize_ 256
$cbr_brake set interval_ 0.02
$cbr_brake attach-agent $udp_brake

# Coordinated Platoon Telemetry: V3 -> V6
set udp_telemetry [new Agent/UDP]
$udp_telemetry set fid_ 3
$ns attach-agent $v(3) $udp_telemetry

set null_telemetry [new Agent/Null]
$ns attach-agent $v(6) $null_telemetry
$ns connect $udp_telemetry $null_telemetry

set cbr_telemetry [new Application/Traffic/CBR]
$cbr_telemetry set packetSize_ 512
$cbr_telemetry set interval_ 0.05
$cbr_telemetry attach-agent $udp_telemetry

# ======================================================================
# SIMULATION TIMELINE
# ======================================================================
# Collision event occurs at t = 0.5s
$ns at 0.5 "$cbr_ecw start"
# Sudden braking occurs at t = 0.8s
$ns at 0.8 "$cbr_brake start"
# Platoon telemetry starts at t = 1.0s
$ns at 1.0 "$cbr_telemetry start"

# Stop transmissions
$ns at 4.0 "$cbr_ecw stop"
$ns at 4.0 "$cbr_brake stop"
$ns at 4.0 "$cbr_telemetry stop"

proc finish {} {
    global ns tf nf
    $ns flush-trace
    close $tf
    close $nf
    puts "V2V Collision Warning Simulation completed."
    puts "Trace file generated: results/traces/v2v_collision_warning.tr"
    exit 0
}

$ns at 4.5 "finish"
$ns run
