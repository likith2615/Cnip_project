# ======================================================================
# Autonomous Vehicle V2V Communication Simulator - Phase 2
# Integrated V2V Dijkstra Routing Simulation: v2v_dijkstra_sim.tcl
# ======================================================================

source dijkstra.tcl

# Initialize Simulator
set ns [new Simulator]

# Open Trace and NAM files
set tf [open "dijkstra_v2v.tr" w]
$ns trace-all $tf

set nf [open "dijkstra_v2v.nam" w]
$ns namtrace-all $nf

# Open CSV for routing results
set csv_file [open "routing_results.csv" w]
puts $csv_file "TIME,SOURCE,DESTINATION,ALGORITHM,PATH,NEXT_HOP,COST,STATUS"

# ======================================================================
# 10 VEHICLE NODES (V0 to V9)
# ======================================================================
for {set i 0} {$i < 10} {incr i} {
    set v($i) [$ns node]
    $v($i) label "V$i"
}

# ======================================================================
# BUILD VEHICULAR TOPOLOGY & DIJKSTRA ROUTING GRAPH
# ======================================================================
# We create a vehicular mesh with multiple alternative routes
# In-line platoon links + cross-lane bypass links
set g [new DijkstraGraph]

proc add_link_and_route {u_idx v_idx bw delay_ms cost} {
    global ns v g
    $ns duplex-link $v($u_idx) $v($v_idx) $bw ${delay_ms}ms DropTail
    $ns queue-limit $v($u_idx) $v($v_idx) 50
    $ns queue-limit $v($v_idx) $v($u_idx) 50
    $g add_edge "V$u_idx" "V$v_idx" $cost
}

# Add Primary and Alternative Vehicular Links
add_link_and_route 0 1 10Mb 5.0 5.0
add_link_and_route 1 2 10Mb 5.0 5.0
add_link_and_route 2 3 10Mb 5.0 5.0
add_link_and_route 3 4 10Mb 5.0 5.0
add_link_and_route 4 5 10Mb 5.0 5.0
add_link_and_route 5 6 10Mb 5.0 5.0
add_link_and_route 6 7 10Mb 5.0 5.0
add_link_and_route 7 8 10Mb 5.0 5.0
add_link_and_route 8 9 10Mb 5.0 5.0

# Add High-Speed Cross-Mesh Highway Bypass Links (Low metric / direct range)
add_link_and_route 1 5 10Mb 8.0 8.0   ;# Bypass V1 -> V5
add_link_and_route 2 5 10Mb 6.0 6.0   ;# Low cost shortcut V2 -> V5
add_link_and_route 5 8 10Mb 7.0 7.0   ;# Shortcut V5 -> V8
add_link_and_route 3 7 10Mb 12.0 12.0 ;# Cross link V3 -> V7
add_link_and_route 0 3 10Mb 9.0 9.0   ;# Shortcut V0 -> V3

puts "========================================================================"
puts "       V2V DIJKSTRA ROUTING SIMULATION & ROUTE SELECTION                "
puts "========================================================================"

# ======================================================================
# ROUTE SELECTION & EVENT LOGGING PROCEDURE
# ======================================================================
proc trigger_v2v_safety_route {time src_name dst_name msg_type size_bytes} {
    global ns v g csv_file
    
    # 1. Execute Dijkstra Shortest Path Search
    set res_list [$g compute_shortest_path $src_name $dst_name]
    array set rinfo $res_list
    set path_str [format_path_string $rinfo(path)]
    
    # 2. Log in standard required format
    puts ""
    puts "TIME=[format "%.2f" $time]"
    puts "SOURCE=$src_name"
    puts "DESTINATION=$dst_name"
    puts "ALGORITHM=DIJKSTRA"
    puts "PATH=$path_str"
    puts "COST=$rinfo(cost)"
    
    # 3. Record in CSV
    puts $csv_file "[format "%.2f" $time],$src_name,$dst_name,DIJKSTRA,$path_str,$rinfo(next_hop),$rinfo(cost),$rinfo(status)"
    
    # 4. Provision and Schedule Real NS-2 Traffic Flow over the computed path
    set src_idx [string range $src_name 1 end]
    set dst_idx [string range $dst_name 1 end]
    
    set udp [new Agent/UDP]
    $udp set fid_ 1
    $ns attach-agent $v($src_idx) $udp
    
    set null [new Agent/Null]
    $ns attach-agent $v($dst_idx) $null
    $ns connect $udp $null
    
    set cbr [new Application/Traffic/CBR]
    $cbr set packetSize_ $size_bytes
    $cbr set interval_ 0.02
    $cbr attach-agent $udp
    
    $ns at $time "$cbr start"
    $ns at [expr $time + 1.5] "$cbr stop"
}

# ======================================================================
# SIMULATION TIMELINE & ROUTE DISPATCH SCHEDULE
# ======================================================================

# Event 1 (t = 0.50s): Collision Warning from V0 to V9
$ns at 0.50 "trigger_v2v_safety_route 0.50 V0 V9 COLLISION_WARNING 128"

# Event 2 (t = 1.20s): Sudden Braking Alert from V1 to V8 (Matches exact required example)
$ns at 1.20 "trigger_v2v_safety_route 1.20 V1 V8 SUDDEN_BRAKING 256"

# Event 3 (t = 2.00s): Road Hazard Telemetry from V2 to V7
$ns at 2.00 "trigger_v2v_safety_route 2.00 V2 V7 TRAFFIC_INFO 512"

# Event 4 (t = 3.00s): Dynamic Link Failure (V2-V5 fails) & Re-routing
$ns at 2.80 "puts \"\n\\\[LINK-EVENT\\\] At t=2.80s, link V2-V5 undergoes wireless blockage (Link Down).\"; $g remove_edge V2 V5"
$ns at 3.00 "trigger_v2v_safety_route 3.00 V1 V8 SUDDEN_BRAKING 256"

# ======================================================================
# FINISH PROCEDURE
# ======================================================================
proc finish {} {
    global ns tf nf csv_file
    $ns flush-trace
    close $tf
    close $nf
    close $csv_file
    puts ""
    puts "========================================================================"
    puts " \[SUCCESS\] V2V Dijkstra Routing Simulation Completed."
    puts " Trace file:     dijkstra_v2v.tr"
    puts " Routing CSV:    routing_results.csv"
    puts "========================================================================"
    exit 0
}

$ns at 5.0 "finish"

# Start simulation
$ns run
