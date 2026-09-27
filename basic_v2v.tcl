# ======================================================================
# Autonomous Vehicle V2V Communication Simulator - Phase 1
# Core Simulation Engine: basic_v2v.tcl
# ======================================================================

# Source baseline configurations
source config.tcl

# Parse command line overrides if provided
# Example: ns basic_v2v.tcl -num_vehicles 20 -loss_rate 0.10 -simtime 6.0
for {set i 0} {$i < $argc} {incr i} {
    set arg [lindex $argv $i]
    if {$arg == "-num_vehicles" && [expr $i + 1] < $argc} {
        set opt(num_vehicles) [lindex $argv [incr i]]
    } elseif {$arg == "-loss_rate" && [expr $i + 1] < $argc} {
        set opt(loss_rate) [lindex $argv [incr i]]
    } elseif {$arg == "-bw" && [expr $i + 1] < $argc} {
        set opt(bw) [lindex $argv [incr i]]
    } elseif {$arg == "-delay" && [expr $i + 1] < $argc} {
        set opt(delay) [lindex $argv [incr i]]
    } elseif {$arg == "-simtime" && [expr $i + 1] < $argc} {
        set opt(simtime) [lindex $argv [incr i]]
    } elseif {$arg == "-qlimit" && [expr $i + 1] < $argc} {
        set opt(qlimit) [lindex $argv [incr i]]
    } elseif {$arg == "-trace_file" && [expr $i + 1] < $argc} {
        set opt(trace_file) [lindex $argv [incr i]]
    }
}

puts "========================================================================"
puts "       AUTONOMOUS VEHICLE V2V NETWORK SIMULATION (PHASE 1)              "
puts "========================================================================"
puts " Configuration Parameters:"
puts "   -> Number of Vehicles:      $opt(num_vehicles)"
puts "   -> Wireless Link Bandwidth: $opt(bw)"
puts "   -> Propagation Latency:     $opt(delay)"
puts "   -> Queue Limit / Type:      $opt(qlimit) packets ($opt(qtype))"
puts "   -> Channel Loss Rate:       [expr $opt(loss_rate) * 100] %"
puts "   -> Simulation Duration:     $opt(simtime) seconds"
puts "   -> Output Trace:            $opt(trace_file)"
puts "   -> Output NAM:              $opt(nam_file)"
puts "========================================================================"

# Initialize NS-2 Simulator
set ns [new Simulator]

# Configure Flow Colors for NAM visualization
$ns color $msg(COLLISION_WARNING,fid) $msg(COLLISION_WARNING,color)
$ns color $msg(SUDDEN_BRAKING,fid)    $msg(SUDDEN_BRAKING,color)
$ns color $msg(TRAFFIC_INFO,fid)       $msg(TRAFFIC_INFO,color)

# Open Output Trace and NAM Files
set tf [open $opt(trace_file) w]
$ns trace-all $tf

set nf [open $opt(nam_file) w]
$ns namtrace-all $nf

# ======================================================================
# CREATE VEHICLE NODES (Scaleable: 10, 20, 50, 100, 200)
# ======================================================================
set N $opt(num_vehicles)

for {set i 0} {$i < $N} {incr i} {
    set v($i) [$ns node]
    # Label key nodes
    if {$i == 0} {
        $v($i) label "V0-PlatoonLeader"
        $v($i) color "Red"
    } elseif {$i == [expr $N - 1]} {
        $v($i) label "V[expr $N-1]-TailVehicle"
        $v($i) color "Blue"
    } elseif {$i == [expr $N / 3]} {
        $v($i) label "V$i-BrakingVehicle"
        $v($i) color "Orange"
    }
}

# ======================================================================
# ESTABLISH LOGICAL V2V TOPOLOGY (Platoon & Multi-Lane Inter-Vehicle Mesh)
# ======================================================================
# 1. Primary In-Line Platoon Links: v(i) <-> v(i+1)
for {set i 0} {$i < [expr $N - 1]} {incr i} {
    set next [expr $i + 1]
    $ns duplex-link $v($i) $v($next) $opt(bw) $opt(delay) $opt(qtype)
    $ns queue-limit $v($i) $v($next) $opt(qlimit)
    $ns queue-limit $v($next) $v($i) $opt(qlimit)
    $ns duplex-link-op $v($i) $v($next) orient right
}

# 2. Multi-Lane Cross Links (Vehicles 2 hops away within direct DSRC radio range)
for {set i 0} {$i < [expr $N - 2]} {incr i 2} {
    set cross [expr $i + 2]
    # Cross link has slightly higher propagation delay (e.g., 8ms)
    $ns duplex-link $v($i) $v($cross) $opt(bw) [expr [string trimright $opt(delay) "ms"] * 1.6]ms $opt(qtype)
    $ns queue-limit $v($i) $v($cross) $opt(qlimit)
    $ns queue-limit $v($cross) $v($i) $opt(qlimit)
    $ns duplex-link-op $v($i) $v($cross) orient down-right
}

# ======================================================================
# CONFIGURE ERROR / PACKET LOSS MODEL (If loss_rate > 0)
# ======================================================================
if {$opt(loss_rate) > 0.0} {
    puts " -> Injected ErrorModel with loss probability: $opt(loss_rate)"
    for {set i 0} {$i < [expr $N - 1]} {incr i 3} {
        set next [expr $i + 1]
        set loss_mod($i) [new ErrorModel]
        $loss_mod($i) unit pkt
        $loss_mod($i) set rate_ $opt(loss_rate)
        $loss_mod($i) ranvar [new RandomVariable/Uniform]
        $loss_mod($i) drop-target [new Agent/Null]
        $ns lossmodel $loss_mod($i) $v($i) $v($next)
    }
}

# ======================================================================
# V2V SAFETY MESSAGE FLOW GENERATORS
# ======================================================================

# Target node indices
set lead_node  0
set tail_node  [expr $N - 1]
set brake_node [expr $N / 3]
set mid_node   [expr $N / 2]

# ----------------------------------------------------------------------
# FLOW 1: EMERGENCY COLLISION WARNING (ECW)
# Source: Lead Vehicle (V0) -> Destination: Tail Vehicle (V_last)
# Payload Size: 128 bytes | Frequency: 50 Hz (interval = 0.02s)
# ----------------------------------------------------------------------
set udp_ecw [new Agent/UDP]
$udp_ecw set fid_ $msg(COLLISION_WARNING,fid)
$ns attach-agent $v($lead_node) $udp_ecw

set null_ecw [new Agent/Null]
$ns attach-agent $v($tail_node) $null_ecw
$ns connect $udp_ecw $null_ecw

set cbr_ecw [new Application/Traffic/CBR]
$cbr_ecw set packetSize_ $msg(COLLISION_WARNING,size)
$cbr_ecw set interval_   $msg(COLLISION_WARNING,interval)
$cbr_ecw set random_     0
$cbr_ecw attach-agent $udp_ecw

# ----------------------------------------------------------------------
# FLOW 2: SUDDEN BRAKING ALERT (CAM)
# Source: Intermediate Vehicle (V_brake) -> Destination: Lead (V0) & Tail (V_last)
# Payload Size: 256 bytes | Frequency: 25 Hz (interval = 0.04s)
# ----------------------------------------------------------------------
set udp_brake [new Agent/UDP]
$udp_brake set fid_ $msg(SUDDEN_BRAKING,fid)
$ns attach-agent $v($brake_node) $udp_brake

set null_brake [new Agent/Null]
$ns attach-agent $v($lead_node) $null_brake
$ns connect $udp_brake $null_brake

set cbr_brake [new Application/Traffic/CBR]
$cbr_brake set packetSize_ $msg(SUDDEN_BRAKING,size)
$cbr_brake set interval_   $msg(SUDDEN_BRAKING,interval)
$cbr_brake set random_     0
$cbr_brake attach-agent $udp_brake

# ----------------------------------------------------------------------
# FLOW 3: PERIODIC TRAFFIC INFO & TELEMETRY (BSM)
# Source: Mid Platoon Vehicle (V_mid) -> Destination: Tail Vehicle (V_last)
# Payload Size: 512 bytes | Frequency: 12.5 Hz (interval = 0.08s)
# ----------------------------------------------------------------------
set udp_traffic [new Agent/UDP]
$udp_traffic set fid_ $msg(TRAFFIC_INFO,fid)
$ns attach-agent $v($mid_node) $udp_traffic

set null_traffic [new Agent/Null]
$ns attach-agent $v($tail_node) $null_traffic
$ns connect $udp_traffic $null_traffic

set cbr_traffic [new Application/Traffic/CBR]
$cbr_traffic set packetSize_ $msg(TRAFFIC_INFO,size)
$cbr_traffic set interval_   $msg(TRAFFIC_INFO,interval)
$cbr_traffic set random_     0
$cbr_traffic attach-agent $udp_traffic

# ======================================================================
# METADATA LOGGING PROCEDURES
# ======================================================================
proc log_metadata {time type src dst size info} {
    puts "\[V2V-METADATA\] Time: [format "%.2f" $time]s | Type: [format "%-18s" $type] | Src: V$src | Dst: V$dst | Size: ${size}B | $info"
}

# Schedule metadata event logs
$ns at 0.5 "log_metadata 0.50 COLLISION_WARNING $lead_node $tail_node $msg(COLLISION_WARNING,size) {Decel: 8.5 m/s^2, Hazard: Stationary Obstacle}"
$ns at 0.8 "log_metadata 0.80 SUDDEN_BRAKING $brake_node $lead_node $msg(SUDDEN_BRAKING,size) {Decel: 6.2 m/s^2, Event: Hard Brake Active}"
$ns at 1.0 "log_metadata 1.00 TRAFFIC_INFO $mid_node $tail_node $msg(TRAFFIC_INFO,size) {Speed: 90 km/h, Density: High, Route: Clear}"

# ======================================================================
# SIMULATION TIMELINE SCHEDULE
# ======================================================================
$ns at 0.5 "$cbr_ecw start"
$ns at 0.8 "$cbr_brake start"
$ns at 1.0 "$cbr_traffic start"

# Stop transmissions before finish
$ns at [expr $opt(simtime) - 0.5] "$cbr_ecw stop"
$ns at [expr $opt(simtime) - 0.5] "$cbr_brake stop"
$ns at [expr $opt(simtime) - 0.5] "$cbr_traffic stop"

# ======================================================================
# FINISH PROCEDURE
# ======================================================================
proc finish {} {
    global ns tf nf opt N
    $ns flush-trace
    close $tf
    close $nf
    puts ""
    puts "========================================================================"
    puts " \[SUCCESS\] V2V Simulation Completed Successfully ($N Vehicles)."
    puts " Trace file: $opt(trace_file) (Size: [file size $opt(trace_file)] bytes)"
    puts " NAM file:   $opt(nam_file) (Size: [file size $opt(nam_file)] bytes)"
    puts "========================================================================"
    exit 0
}

$ns at $opt(simtime) "finish"

# Start NS-2 Simulation Execution
$ns run
