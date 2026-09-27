# ======================================================================
# Autonomous Vehicle V2V Communication Simulator - Phase 7
# Multi-Vehicle Traffic Congestion Simulation: v2v_congestion_sim.tcl
# ======================================================================

source congestion.tcl

# Read node count argument if provided
set N 25
if {$argc > 0} {
    set N [lindex $argv 0]
}

set ns [new Simulator]

set tf [open "congestion_${N}v.tr" w]
$ns trace-all $tf

set nf [open "congestion_${N}v.nam" w]
$ns namtrace-all $nf

puts "========================================================================"
puts "       V2V MULTI-VEHICLE TRAFFIC CONGESTION SIMULATION ($N VEHICLES)    "
puts "========================================================================"

# Create N vehicles + 1 Central RSU / Hub
for {set i 0} {$i < $N} {incr i} {
    set v($i) [$ns node]
}
set rsu [$ns node]

# Setup bottleneck link between V0 and RSU (2 Mbps, 20ms, queue = 15)
$ns duplex-link $v(0) $rsu 2Mb 20ms DropTail
$ns queue-limit $v(0) $rsu 15
$ns queue-limit $rsu $v(0) 15

# Connect other vehicles in vehicular mesh to V0
for {set i 1} {$i < $N} {incr i} {
    $ns duplex-link $v($i) $v(0) 5Mb 5ms DropTail
    $ns queue-limit $v($i) $v(0) 30
}

# Attach Congestion Monitored Agent on Vehicle 0
set udp0 [new Agent/UDP]
$udp0 set fid_ 1
$ns attach-agent $v(0) $udp0
set null_rsu [new Agent/Null]
$ns attach-agent $rsu $null_rsu
$ns connect $udp0 $null_rsu

set cbr0 [new Application/Traffic/CBR]
$cbr0 set packetSize_ 512
$cbr0 set interval_ 0.015 ;# High rate
$cbr0 attach-agent $udp0

set cc [new CongestionController $cbr0 0.01 0.15]

# Attach background traffic streams to create congestion
for {set i 1} {$i < [expr $N > 10 ? 10 : $N]} {incr i} {
    set udp_bg($i) [new Agent/UDP]
    $udp_bg($i) set fid_ 2
    $ns attach-agent $v($i) $udp_bg($i)
    set sink_bg($i) [new Agent/Null]
    $ns attach-agent $rsu $sink_bg($i)
    $ns connect $udp_bg($i) $sink_bg($i)
    
    set cbr_bg($i) [new Application/Traffic/CBR]
    $cbr_bg($i) set packetSize_ 512
    $cbr_bg($i) set interval_ 0.02
    $cbr_bg($i) attach-agent $udp_bg($i)
}

# Periodic monitoring procedure
proc monitor_step {time_step} {
    global ns cc N
    set now [$ns now]
    # Simulate drop feedback if in congested time window
    if {$now >= 1.5 && $now <= 3.0} {
        $cc record_drop
    }
    $cc evaluate_congestion $now
    
    if {$now < 4.5} {
        $ns at [expr $now + $time_step] "monitor_step $time_step"
    }
}

# Schedule Traffic
$ns at 0.5 "$cbr0 start"
for {set i 1} {$i < [expr $N > 10 ? 10 : $N]} {incr i} {
    $ns at [expr 0.8 + ($i * 0.1)] "$cbr_bg($i) start"
}

$ns at 1.0 "monitor_step 0.2"

$ns at 4.5 "$cbr0 stop"
for {set i 1} {$i < [expr $N > 10 ? 10 : $N]} {incr i} {
    $ns at 4.5 "$cbr_bg($i) stop"
}

proc finish {} {
    global ns tf nf N
    $ns flush-trace
    close $tf
    close $nf
    puts "========================================================================"
    puts " \[SUCCESS\] Congestion simulation ($N vehicles) completed."
    puts " Trace file: congestion_${N}v.tr (Size: [file size "congestion_${N}v.tr"] bytes)"
    puts "========================================================================"
    exit 0
}

$ns at 5.0 "finish"
$ns run
