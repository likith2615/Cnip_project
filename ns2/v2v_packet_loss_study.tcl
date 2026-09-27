# ======================================================================
# Autonomous Vehicle V2V Communication Simulator
# Scenario 5: Parametric Packet Loss & Error Rate Study
# Injects wireless bit error/loss models to evaluate PDR and Latency
# Usage: ns ns2/v2v_packet_loss_study.tcl [loss_rate_fraction]
# ======================================================================

set ns [new Simulator]

# Read loss rate argument (default 0.05 = 5%)
if {$argc > 0} {
    set loss_rate [lindex $argv 0]
} else {
    set loss_rate 0.05
}

# Tag for output trace filename
set loss_tag [expr int($loss_rate * 100)]
exec mkdir -p results/traces

set tf [open "results/traces/v2v_loss_${loss_tag}pct.tr" w]
$ns trace-all $tf

# ======================================================================
# 6-VEHICLE HIGHWAY PLATOON
# ======================================================================
for {set i 0} {$i < 6} {incr i} {
    set v($i) [$ns node]
}

# Setup duplex links
for {set i 0} {$i < 5} {incr i} {
    set next [expr $i + 1]
    $ns duplex-link $v($i) $v($next) 10Mb 5ms DropTail
    $ns queue-limit $v($i) $v($next) 50
    $ns queue-limit $v($next) $v($i) 50
}

# ======================================================================
# INJECT ERROR MODEL ON V2V WIRELESS INTERFACES
# ======================================================================
set loss_module [new ErrorModel]
$loss_module unit pkt
$loss_module set rate_ $loss_rate
$loss_module ranvar [new RandomVariable/Uniform]
$loss_module drop-target [new Agent/Null]

# Insert loss module on the inter-vehicle links
$ns lossmodel $loss_module $v(1) $v(2)

set loss_module2 [new ErrorModel]
$loss_module2 unit pkt
$loss_module2 set rate_ $loss_rate
$loss_module2 ranvar [new RandomVariable/Uniform]
$loss_module2 drop-target [new Agent/Null]
$ns lossmodel $loss_module2 $v(3) $v(4)

# ======================================================================
# SAFETY AND TELEMETRY TRAFFIC
# ======================================================================
# Flow 1: Emergency Brake Alert (V0 -> V5)
set udp0 [new Agent/UDP]
$udp0 set fid_ 1
$ns attach-agent $v(0) $udp0
set null5 [new Agent/Null]
$ns attach-agent $v(5) $null5
$ns connect $udp0 $null5

set cbr0 [new Application/Traffic/CBR]
$cbr0 set packetSize_ 512
$cbr0 set interval_ 0.02
$cbr0 attach-agent $udp0

# Flow 2: Traffic Update (V1 -> V4)
set udp1 [new Agent/UDP]
$udp1 set fid_ 2
$ns attach-agent $v(1) $udp1
set null4 [new Agent/Null]
$ns attach-agent $v(4) $null4
$ns connect $udp1 $null4

set cbr1 [new Application/Traffic/CBR]
$cbr1 set packetSize_ 256
$cbr1 set interval_ 0.04
$cbr1 attach-agent $udp1

# Simulation Timeline
$ns at 0.5 "$cbr0 start"
$ns at 0.5 "$cbr1 start"
$ns at 4.5 "$cbr0 stop"
$ns at 4.5 "$cbr1 stop"

proc finish {} {
    global ns tf loss_tag
    $ns flush-trace
    close $tf
    puts "V2V Loss Study (${loss_tag}%) completed."
    puts "Trace file generated: results/traces/v2v_loss_${loss_tag}pct.tr"
    exit 0
}

$ns at 5.0 "finish"
$ns run
