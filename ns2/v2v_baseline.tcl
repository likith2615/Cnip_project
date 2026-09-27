# ======================================================================
# Autonomous Vehicle V2V Communication Simulator
# Scenario 1: Baseline Highway Platoon Safety & Telemetry Simulation
# ======================================================================

# Create simulator instance
set ns [new Simulator]

# Define color codes for NAM visualization
$ns color 1 Red       ;# High-Priority Emergency Collision Warnings (ECW)
$ns color 2 Orange    ;# Sudden Braking Alerts (CAM)
$ns color 3 Blue      ;# Periodic Vehicle Telemetry (BSM)
$ns color 4 Green     ;# Platoon Coordination & Traffic Info

# Create output trace directory if not exists
exec mkdir -p results/traces

# Open trace and NAM output files
set tf [open results/traces/v2v_baseline.tr w]
$ns trace-all $tf

set nf [open results/traces/v2v_baseline.nam w]
$ns namtrace-all $nf

# ======================================================================
# CREATE VEHICLE NODES (Platoon of 6 Autonomous Vehicles)
# ======================================================================
# Node 0: Platoon Leader (Lead Vehicle)
# Node 1: Autonomous Passenger Car 1
# Node 2: Autonomous Heavy Truck
# Node 3: Autonomous Passenger Car 2
# Node 4: Autonomous Delivery Van
# Node 5: Autonomous Tail Vehicle (Platoon Follower)

for {set i 0} {$i < 6} {incr i} {
    set v($i) [$ns node]
}

# Label nodes for visual clarity in NAM
$v(0) label "V0-LeadVehicle"
$v(1) label "V1-PassengerCar1"
$v(2) label "V2-HeavyTruck"
$v(3) label "V3-PassengerCar2"
$v(4) label "V4-DeliveryVan"
$v(5) label "V5-TailVehicle"

# Color nodes
$v(0) color "Red"
$v(2) color "Orange"

# ======================================================================
# SETUP V2V WIRELESS/DSRC LINKS & TOPOLOGY
# Bandwidth: 10 Mbps (IEEE 802.11p / DSRC channel)
# Propagation delay: 5ms - 10ms (Line of sight V2V)
# Queue: DropTail with queue limit of 50 packets
# ======================================================================

$ns duplex-link $v(0) $v(1) 10Mb 5ms DropTail
$ns duplex-link $v(1) $v(2) 10Mb 5ms DropTail
$ns duplex-link $v(2) $v(3) 10Mb 5ms DropTail
$ns duplex-link $v(3) $v(4) 10Mb 5ms DropTail
$ns duplex-link $v(4) $v(5) 10Mb 5ms DropTail

# Cross-links (Multi-hop redundancy in vehicular mesh)
$ns duplex-link $v(0) $v(2) 5Mb 10ms DropTail
$ns duplex-link $v(1) $v(3) 5Mb 10ms DropTail
$ns duplex-link $v(3) $v(5) 5Mb 10ms DropTail

# Set queue limits
for {set i 0} {$i < 5} {incr i} {
    set next [expr $i + 1]
    $ns queue-limit $v($i) $v($next) 50
    $ns queue-limit $v($next) $v($i) 50
}

# Position nodes linearly in NAM
$ns duplex-link-op $v(0) $v(1) orient right
$ns duplex-link-op $v(1) $v(2) orient right
$ns duplex-link-op $v(2) $v(3) orient right
$ns duplex-link-op $v(3) $v(4) orient right
$ns duplex-link-op $v(4) $v(5) orient right
$ns duplex-link-op $v(0) $v(2) orient down-right
$ns duplex-link-op $v(1) $v(3) orient down-right
$ns duplex-link-op $v(3) $v(5) orient down-right

# ======================================================================
# TRAFFIC FLOW 1: High Priority Emergency Collision Warning (V0 -> Platoon)
# UDP + CBR (Small packet 128 bytes, high frequency 50Hz = interval 0.02s)
# ======================================================================
set udp0 [new Agent/UDP]
$udp0 set fid_ 1
$ns attach-agent $v(0) $udp0

set null5 [new Agent/Null]
$ns attach-agent $v(5) $null5
$ns connect $udp0 $null5

set cbr_ecw [new Application/Traffic/CBR]
$cbr_ecw set packetSize_ 128
$cbr_ecw set interval_ 0.02
$cbr_ecw set random_ 0
$cbr_ecw attach-agent $udp0

# ======================================================================
# TRAFFIC FLOW 2: Sudden Braking Alert (CAM) from V2 (Heavy Truck) -> V0 & V5
# ======================================================================
set udp2 [new Agent/UDP]
$udp2 set fid_ 2
$ns attach-agent $v(2) $udp2

set null0 [new Agent/Null]
$ns attach-agent $v(0) $null0
$ns connect $udp2 $null0

set cbr_brake [new Application/Traffic/CBR]
$cbr_brake set packetSize_ 256
$cbr_brake set interval_ 0.04
$cbr_brake attach-agent $udp2

# ======================================================================
# TRAFFIC FLOW 3: Periodic Vehicle Telemetry (BSM) from V1 -> V4
# ======================================================================
set udp1 [new Agent/UDP]
$udp1 set fid_ 3
$ns attach-agent $v(1) $udp1

set null4 [new Agent/Null]
$ns attach-agent $v(4) $null4
$ns connect $udp1 $null4

set cbr_telemetry [new Application/Traffic/CBR]
$cbr_telemetry set packetSize_ 512
$cbr_telemetry set interval_ 0.05
$cbr_telemetry attach-agent $udp1

# ======================================================================
# TRAFFIC FLOW 4: Traffic Information & Route Advisory from V3 -> V5
# ======================================================================
set udp3 [new Agent/UDP]
$udp3 set fid_ 4
$ns attach-agent $v(3) $udp3

set null5_2 [new Agent/Null]
$ns attach-agent $v(5) $null5_2
$ns connect $udp3 $null5_2

set cbr_traffic [new Application/Traffic/CBR]
$cbr_traffic set packetSize_ 1024
$cbr_traffic set interval_ 0.08
$cbr_traffic attach-agent $udp3

# ======================================================================
# SIMULATION SCHEDULE & TIMELINE
# ======================================================================
# t = 0.5s: Lead vehicle detects obstruction, starts Emergency Broadcast
$ns at 0.5 "$cbr_ecw start"

# t = 1.0s: Heavy Truck experiences braking, issues Sudden Braking Alert
$ns at 1.0 "$cbr_brake start"

# t = 1.5s: Background Telemetry starts
$ns at 1.5 "$cbr_telemetry start"

# t = 2.0s: Traffic Advisory broadcast starts
$ns at 2.0 "$cbr_traffic start"

# Stop transmissions
$ns at 4.5 "$cbr_ecw stop"
$ns at 4.5 "$cbr_brake stop"
$ns at 4.5 "$cbr_telemetry stop"
$ns at 4.5 "$cbr_traffic stop"

# ======================================================================
# FINISH PROCEDURE
# ======================================================================
proc finish {} {
    global ns tf nf
    $ns flush-trace
    close $tf
    close $nf
    puts "V2V Baseline Simulation completed successfully."
    puts "Trace file generated: results/traces/v2v_baseline.tr"
    exit 0
}

$ns at 5.0 "finish"

# Start simulation
$ns run
