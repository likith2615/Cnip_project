# ======================================================================
# Autonomous Vehicle V2V Communication Simulator
# Scenario 4: Dynamic Vehicular Topology & Route Failover (DV / LS)
# Evaluates dynamic route convergence upon link failure and recovery
# ======================================================================

set ns [new Simulator]

# Enable Dynamic Routing (Distance Vector / Link State)
$ns rtproto DV

$ns color 1 Red       ;# Primary Safety Alert Flow
$ns color 2 Green     ;# Alternative Rerouted Path Packets

exec mkdir -p results/traces

set tf [open results/traces/v2v_routing_dynamics.tr w]
$ns trace-all $tf

set nf [open results/traces/v2v_routing_dynamics.nam w]
$ns namtrace-all $nf

# ======================================================================
# 7 VEHICLE NODES FORMING A MESH WITH REDUNDANT DETOUR PATHS
# ======================================================================
# Path 1 (Shortest): V0 -> V1 -> V3 -> V6
# Path 2 (Alternative): V0 -> V2 -> V4 -> V5 -> V6

for {set i 0} {$i < 7} {incr i} {
    set v($i) [$ns node]
}

$v(0) label "V0-SourceLeader"
$v(1) label "V1-MeshRelay1"
$v(2) label "V2-MeshRelay2"
$v(3) label "V3-MeshRelay3"
$v(4) label "V4-MeshRelay4"
$v(5) label "V5-MeshRelay5"
$v(6) label "V6-DestinationTail"

$v(0) color "Red"
$v(6) color "Blue"

# ======================================================================
# NETWORK TOPOLOGY WITH DIVERGENT PATHS
# ======================================================================
# Primary short path
$ns duplex-link $v(0) $v(1) 10Mb 5ms DropTail
$ns duplex-link $v(1) $v(3) 10Mb 5ms DropTail
$ns duplex-link $v(3) $v(6) 10Mb 5ms DropTail

# Backup longer path
$ns duplex-link $v(0) $v(2) 10Mb 5ms DropTail
$ns duplex-link $v(2) $v(4) 10Mb 5ms DropTail
$ns duplex-link $v(4) $v(5) 10Mb 5ms DropTail
$ns duplex-link $v(5) $v(6) 10Mb 5ms DropTail

# Cross-mesh connecting link
$ns duplex-link $v(1) $v(4) 10Mb 10ms DropTail
$ns duplex-link $v(2) $v(3) 10Mb 10ms DropTail

# ======================================================================
# CONTINUOUS SAFETY TRAFFIC STREAM: V0 -> V6
# ======================================================================
set udp0 [new Agent/UDP]
$udp0 set fid_ 1
$ns attach-agent $v(0) $udp0

set null6 [new Agent/Null]
$ns attach-agent $v(6) $null6
$ns connect $udp0 $null6

set cbr0 [new Application/Traffic/CBR]
$cbr0 set packetSize_ 512
$cbr0 set interval_ 0.02
$cbr0 attach-agent $udp0

# ======================================================================
# DYNAMIC LINK FAILURE AND RECOVERY SCHEDULE
# ======================================================================
# Start transmission at t = 0.5s (uses primary path V0->V1->V3->V6)
$ns at 0.5 "$cbr0 start"

# AT t = 1.5s: Primary link V1-V3 FAILS (e.g. truck obstacle/out of line-of-sight)
$ns rtmodel-at 1.5 down $v(1) $v(3)

# AT t = 3.0s: Primary link V1-V3 RECOVERS (vehicle moves back into range)
$ns rtmodel-at 3.0 up $v(1) $v(3)

# Stop traffic at t = 4.5s
$ns at 4.5 "$cbr0 stop"

proc finish {} {
    global ns tf nf
    $ns flush-trace
    close $tf
    close $nf
    puts "V2V Dynamic Routing Simulation completed."
    puts "Trace file generated: results/traces/v2v_routing_dynamics.tr"
    exit 0
}

$ns at 5.0 "finish"
$ns run
