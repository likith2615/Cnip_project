# ======================================================================
# Autonomous Vehicle V2V Communication Simulator
# Scenario 3: Heavy Multi-Vehicle Traffic Congestion & Queue Bottleneck
# Analyzes network performance under high simultaneous vehicular transmission load
# ======================================================================

set ns [new Simulator]

$ns color 1 Red       ;# Safety Alert Flow
$ns color 2 Blue      ;# High-rate Sensor Telemetry (Congestion Cause)
$ns color 3 Green     ;# Vehicle Infotainment / Navigation
$ns color 4 Yellow    ;# V2I / RSU Traffic Aggregation

exec mkdir -p results/traces

set tf [open results/traces/v2v_traffic_congestion.tr w]
$ns trace-all $tf

set nf [open results/traces/v2v_traffic_congestion.nam w]
$ns namtrace-all $nf

# ======================================================================
# 9 VEHICULAR NODES + 1 ROADSIDE UNIT (RSU)
# ======================================================================
for {set i 0} {$i < 9} {incr i} {
    set v($i) [$ns node]
}
set rsu [$ns node]

# Labels
$v(0) label "V0-EmergencyVehicle"
$v(1) label "V1-CommuterCar"
$v(2) label "V2-DeliveryTruck"
$v(3) label "V3-AutonomousTaxi1"
$v(4) label "V4-AutonomousTaxi2"
$v(5) label "V5-BusGateway"
$v(6) label "V6-CommuterCar2"
$v(7) label "V7-ConnectedSUV"
$v(8) label "V8-TrafficHub"
$rsu  label "RSU-RoadsideUnit"

$v(0) color "Red"
$rsu  color "Black"

# ======================================================================
# TOPOLOGY WITH BOTTLENECK LINKS AT INTERSECTION HUB (V8 & RSU)
# ======================================================================
# Normal vehicle access links (5 Mbps, 5ms)
$ns duplex-link $v(0) $v(8) 10Mb 5ms DropTail
$ns duplex-link $v(1) $v(8) 5Mb 5ms DropTail
$ns duplex-link $v(2) $v(8) 5Mb 5ms DropTail
$ns duplex-link $v(3) $v(8) 5Mb 5ms DropTail
$ns duplex-link $v(4) $v(5) 5Mb 5ms DropTail
$ns duplex-link $v(5) $v(8) 5Mb 5ms DropTail
$ns duplex-link $v(6) $v(8) 5Mb 5ms DropTail
$ns duplex-link $v(7) $v(8) 5Mb 5ms DropTail

# BOTTLENECK LINK between TrafficHub (V8) and RSU (2 Mbps, 20ms, queue limit = 20)
$ns duplex-link $v(8) $rsu 2Mb 20ms DropTail
$ns queue-limit $v(8) $rsu 20
$ns queue-limit $rsu $v(8) 20

# Set queue limits on other links
for {set i 0} {$i < 8} {incr i} {
    if {$i != 4 && $i != 5} {
        $ns queue-limit $v($i) $v(8) 30
        $ns queue-limit $v(8) $v($i) 30
    }
}

# Monitor queue at bottleneck link for NAM
$ns duplex-link-op $v(8) $rsu queuePos 0.5

# ======================================================================
# SIMULTANEOUS TRAFFIC STREAMS (Generating Congestion)
# ======================================================================

# Stream 1: High Priority Emergency Vehicle Alert (V0 -> RSU)
set udp0 [new Agent/UDP]
$udp0 set fid_ 1
$ns attach-agent $v(0) $udp0
set null_rsu [new Agent/Null]
$ns attach-agent $rsu $null_rsu
$ns connect $udp0 $null_rsu

set cbr_safety [new Application/Traffic/CBR]
$cbr_safety set packetSize_ 128
$cbr_safety set interval_ 0.02
$cbr_safety attach-agent $udp0

# Streams 2-7: Aggressive High-Rate Telemetry Flooding Bottleneck
for {set i 1} {$i <= 6} {incr i} {
    set udp($i) [new Agent/UDP]
    $udp($i) set fid_ 2
    $ns attach-agent $v($i) $udp($i)
    
    set sink($i) [new Agent/Null]
    $ns attach-agent $rsu $sink($i)
    $ns connect $udp($i) $sink($i)
    
    set cbr_cong($i) [new Application/Traffic/CBR]
    $cbr_cong($i) set packetSize_ 1024
    $cbr_cong($i) set interval_ 0.015 ;# High rate pushing link into congestion
    $cbr_cong($i) attach-agent $udp($i)
}

# Stream 8: Heavy Video/Infotainment from V7 -> RSU
set udp7 [new Agent/UDP]
$udp7 set fid_ 3
$ns attach-agent $v(7) $udp7
set sink7 [new Agent/Null]
$ns attach-agent $rsu $sink7
$ns connect $udp7 $sink7

set cbr_video [new Application/Traffic/CBR]
$cbr_video set packetSize_ 1500
$cbr_video set interval_ 0.01
$cbr_video attach-agent $udp7

# ======================================================================
# TIMELINE: Staggered start creating progressive congestion collapse
# ======================================================================
$ns at 0.5 "$cbr_safety start"
$ns at 1.0 "$cbr_cong(1) start"
$ns at 1.2 "$cbr_cong(2) start"
$ns at 1.4 "$cbr_cong(3) start"
$ns at 1.6 "$cbr_cong(4) start"
$ns at 1.8 "$cbr_cong(5) start"
$ns at 2.0 "$cbr_cong(6) start"
$ns at 2.2 "$cbr_video start"

# Stop
for {set i 1} {$i <= 6} {incr i} {
    $ns at 4.5 "$cbr_cong($i) stop"
}
$ns at 4.5 "$cbr_safety stop"
$ns at 4.5 "$cbr_video stop"

proc finish {} {
    global ns tf nf
    $ns flush-trace
    close $tf
    close $nf
    puts "V2V Traffic Congestion Simulation completed."
    puts "Trace file generated: results/traces/v2v_traffic_congestion.tr"
    exit 0
}

$ns at 5.0 "finish"
$ns run
