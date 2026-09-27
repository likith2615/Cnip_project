# ======================================================================
# Autonomous Vehicle V2V Communication Simulator
# Unified Master Simulation Engine: v2v_main.tcl
# ======================================================================

source dijkstra.tcl
source distance_vector.tcl
source crc.tcl
source sliding_window.tcl
source gobackn.tcl
source congestion.tcl

# Default Configuration Parameters
set opt(vehicles)    10
set opt(routing)     "dijkstra"   ;# "dijkstra" or "distance_vector"
set opt(loss)        0.00
set opt(window)      4
set opt(simtime)     5.0
set opt(bw)          10Mb
set opt(delay)       5ms
set opt(qsize)       50
set opt(trace_file)  "v2v_final.tr"
set opt(nam_file)    "v2v_final.nam"
set opt(csv_file)    "v2v_final_metrics.csv"

# Parse CLI arguments
for {set i 0} {$i < $argc} {incr i} {
    set arg [lindex $argv $i]
    if {($arg == "--vehicles" || $arg == "-v") && [expr $i + 1] < $argc} {
        set opt(vehicles) [lindex $argv [incr i]]
    } elseif {($arg == "--routing" || $arg == "-r") && [expr $i + 1] < $argc} {
        set opt(routing) [string tolower [lindex $argv [incr i]]]
    } elseif {($arg == "--loss" || $arg == "-l") && [expr $i + 1] < $argc} {
        set opt(loss) [lindex $argv [incr i]]
    } elseif {($arg == "--window" || $arg == "-w") && [expr $i + 1] < $argc} {
        set opt(window) [lindex $argv [incr i]]
    } elseif {($arg == "--simtime" || $arg == "-t") && [expr $i + 1] < $argc} {
        set opt(simtime) [lindex $argv [incr i]]
    } elseif {$arg == "--trace" && [expr $i + 1] < $argc} {
        set opt(trace_file) [lindex $argv [incr i]]
    } elseif {$arg == "--nam" && [expr $i + 1] < $argc} {
        set opt(nam_file) [lindex $argv [incr i]]
    }
}

puts "========================================================================"
puts "       AUTONOMOUS VEHICLE V2V UNIFIED SIMULATION ENGINE                 "
puts "========================================================================"
puts " Active Parameters:"
puts "   -> Vehicle Count:     $opt(vehicles) Autonomous Vehicles"
puts "   -> Routing Protocol:  [string toupper $opt(routing)]"
puts "   -> Wireless Loss:     [expr $opt(loss) * 100] %"
puts "   -> Flow Window Size:  W = $opt(window)"
puts "   -> Link Attributes:   $opt(bw) bandwidth, $opt(delay) delay, $opt(qsize) queue"
puts "   -> Simulation Time:   $opt(simtime) seconds"
puts "   -> Output Trace:      $opt(trace_file)"
puts "========================================================================"

set ns [new Simulator]

# Flow Color Definitions
$ns color 1 Red       ;# High-Priority Emergency Collision Warning
$ns color 2 Orange    ;# High-Priority Sudden Braking Alert
$ns color 3 Blue      ;# Normal-Priority Traffic Info Telemetry

# Output trace files
set tf [open $opt(trace_file) w]
$ns trace-all $tf

set nf [open $opt(nam_file) w]
$ns namtrace-all $nf

# ======================================================================
# NODE CREATION & DYNAMIC VEHICULAR TOPOLOGY SETUP
# ======================================================================
set N $opt(vehicles)
for {set i 0} {$i < $N} {incr i} {
    set v($i) [$ns node]
    if {$i == 0} {
        $v($i) label "V0-PlatoonLeader"
        $v($i) color "Red"
    } elseif {$i == [expr $N - 1]} {
        $v($i) label "V[expr $N-1]-Tail"
        $v($i) color "Blue"
    }
}

# Instantiate Graph based on Selected Routing Algorithm
if {$opt(routing) == "distance_vector"} {
    set router [new DistanceVectorGraph]
} else {
    set router [new DijkstraGraph]
}

# Build Physical & Logical Vehicular Mesh Links
set delay_val [string trimright $opt(delay) "ms"]
for {set i 0} {$i < [expr $N - 1]} {incr i} {
    set next [expr $i + 1]
    $ns duplex-link $v($i) $v($next) $opt(bw) $opt(delay) DropTail
    $ns queue-limit $v($i) $v($next) $opt(qsize)
    $ns queue-limit $v($next) $v($i) $opt(qsize)
    $router add_edge "V$i" "V$next" [expr {double($delay_val)}]
}

# Cross-Lane Bypass Links (Simulating multi-hop vehicular DSRC range)
for {set i 0} {$i < [expr $N - 2]} {incr i 2} {
    set cross [expr $i + 2]
    set cross_delay [expr {$delay_val * 1.5}]
    $ns duplex-link $v($i) $v($cross) $opt(bw) ${cross_delay}ms DropTail
    $ns queue-limit $v($i) $v($cross) $opt(qsize)
    $ns queue-limit $v($cross) $v($i) $opt(qsize)
    $router add_edge "V$i" "V$cross" $cross_delay
}

# Inject ErrorModel if loss rate > 0
if {$opt(loss) > 0.0} {
    for {set i 0} {$i < [expr $N - 1]} {incr i 3} {
        set next [expr $i + 1]
        set err_mod [new ErrorModel]
        $err_mod unit pkt
        $err_mod set rate_ $opt(loss)
        $err_mod ranvar [new RandomVariable/Uniform]
        $err_mod drop-target [new Agent/Null]
        $ns lossmodel $err_mod $v($i) $v($next)
    }
}

# ======================================================================
# SAFETY MESSAGE TRANSMISSION & ROUTING DISPATCH
# ======================================================================
proc route_and_transmit {time src_id dst_id msg_type size_bytes interval priority} {
    global ns v router opt
    set src_name "V$src_id"
    set dst_name "V$dst_id"

    # Compute route using active algorithm
    if {$opt(routing) == "distance_vector"} {
        set res [$router get_route $src_name $dst_name]
    } else {
        set res [$router compute_shortest_path $src_name $dst_name]
    }
    array set rinfo $res
    set path_str [join $rinfo(path) "->"]

    # Log route selection event
    puts ""
    puts "TIME=[format "%.2f" $time]"
    puts "SOURCE=$src_name"
    puts "DESTINATION=$dst_name"
    puts "ALGORITHM=[string toupper $opt(routing)]"
    puts "PATH=$path_str"
    puts "COST=$rinfo(cost)"
    puts "PRIORITY=$priority"

    # Provision NS-2 Transport & CBR Flow
    set fid [expr {$priority == "HIGH" ? ($msg_type == "COLLISION_WARNING" ? 1 : 2) : 3}]
    set udp [new Agent/UDP]
    $udp set fid_ $fid
    $ns attach-agent $v($src_id) $udp

    set null [new Agent/Null]
    $ns attach-agent $v($dst_id) $null
    $ns connect $udp $null

    set cbr [new Application/Traffic/CBR]
    $cbr set packetSize_ $size_bytes
    $cbr set interval_ $interval
    $cbr set random_ 0
    $cbr attach-agent $udp

    $ns at $time "$cbr start"
    $ns at [expr $opt(simtime) - 0.5] "$cbr stop"
}

# Schedule Safety Traffic
set lead_id 0
set tail_id [expr $N - 1]
set mid_id  [expr $N / 2]

# 1. COLLISION_WARNING (ECW): High Priority, 128B, 50Hz
$ns at 0.50 "route_and_transmit 0.50 $lead_id $tail_id COLLISION_WARNING 128 0.02 HIGH"

# 2. SUDDEN_BRAKING (CAM): High Priority, 256B, 25Hz
$ns at 0.80 "route_and_transmit 0.80 $mid_id $lead_id SUDDEN_BRAKING 256 0.04 HIGH"

# 3. TRAFFIC_INFO (BSM): Normal Priority, 512B, 12.5Hz
$ns at 1.00 "route_and_transmit 1.00 $mid_id $tail_id TRAFFIC_INFO 512 0.08 NORMAL"

proc finish {} {
    global ns tf nf opt N
    $ns flush-trace
    close $tf
    close $nf
    puts ""
    puts "========================================================================"
    puts " \[SUCCESS\] Simulation complete ($N vehicles, $opt(routing) routing)."
    puts " Trace file: $opt(trace_file) (Size: [file size $opt(trace_file)] bytes)"
    puts "========================================================================"
    exit 0
}

$ns at $opt(simtime) "finish"
$ns run
