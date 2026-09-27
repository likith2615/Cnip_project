# ======================================================================
# Autonomous Vehicle V2V Communication Simulator
# Distance Vector Routing Independent Test: distance_vector_test.tcl
# ======================================================================

source distance_vector.tcl

puts "========================================================================"
puts "    DISTANCE VECTOR (BELLMAN-FORD) ROUTING INDEPENDENT TEST             "
puts "========================================================================"

# 1. Instantiate Graph
set g [new DistanceVectorGraph]

# Build Reference Graph
# A-B = 2, A-C = 5, B-C = 1, B-D = 4, C-D = 1
$g add_edge "A" "B" 2.0
$g add_edge "A" "C" 5.0
$g add_edge "B" "C" 1.0
$g add_edge "B" "D" 4.0
$g add_edge "C" "D" 1.0

puts " Graph Topology Configured:"
puts "   A --(2)--> B"
puts "   A --(5)--> C"
puts "   B --(1)--> C"
puts "   B --(4)--> D"
puts "   C --(1)--> D"
puts "------------------------------------------------------------------------"

# 2. Run Convergence
puts " Executing Distance Vector Iterative Route Exchanges..."
set conv_res [$g run_convergence 1 30 1.00]
array set cinfo $conv_res

puts " Convergence achieved in $cinfo(iterations) rounds with $cinfo(updates) route table updates."
puts " Sample Route-Table Change Event Logs:"
foreach entry [lrange $cinfo(logs) 0 4] {
    puts "   [join $entry " | "]"
}
puts "------------------------------------------------------------------------"

# 3. Verify Route from A to D
set route_res [$g get_route "A" "D"]
array set rinfo $route_res

set path_str [join $rinfo(path) "->"]
puts " Distance Vector Computed Shortest Route from A to D:"
puts "   -> Path:      $path_str"
puts "   -> Next Hop:  $rinfo(next_hop)"
puts "   -> Cost:      $rinfo(cost)"
puts "   -> Status:    $rinfo(status)"
puts "------------------------------------------------------------------------"

# Assertions
set test_passed 1
if {$path_str != "A->B->C->D"} {
    puts " \[FAIL\] Path mismatch! Expected A->B->C->D, Got: $path_str"
    set test_passed 0
} else {
    puts " \[PASS\] Distance Vector Shortest Path matches: A->B->C->D"
}

if {$rinfo(cost) != 4.0} {
    puts " \[FAIL\] Cost mismatch! Expected 4.0, Got: $rinfo(cost)"
    set test_passed 0
} else {
    puts " \[PASS\] Path cost matches optimal cost: 4.0"
}

if {$rinfo(next_hop) != "B"} {
    puts " \[FAIL\] Next hop mismatch! Expected B, Got: $rinfo(next_hop)"
    set test_passed 0
} else {
    puts " \[PASS\] Next hop matches: B"
}

puts "------------------------------------------------------------------------"
$g print_routing_table "A"

puts "========================================================================"
if {$test_passed} {
    puts " \[SUCCESS\] All Distance Vector unit test assertions PASSED."
    exit 0
} else {
    puts " \[FAILURE\] One or more Distance Vector tests failed."
    exit 1
}
