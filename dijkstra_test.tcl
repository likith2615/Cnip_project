# ======================================================================
# Autonomous Vehicle V2V Communication Simulator - Phase 2
# Independent Dijkstra Verification Test: dijkstra_test.tcl
# ======================================================================
# Tests the Dijkstra implementation against the exact required reference graph:
#   A-B = 2
#   A-C = 5
#   B-C = 1
#   B-D = 4
#   C-D = 1
# Expected Shortest Path (A -> D): A -> B -> C -> D, Total Cost = 4
# ======================================================================

source dijkstra.tcl

puts "========================================================================"
puts "       DIJKSTRA ROUTING MODULE INDEPENDENT VERIFICATION TEST            "
puts "========================================================================"

# Instantiate Graph
set g [new DijkstraGraph]

# Build Reference Graph
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

# 1. Compute Shortest Path from A to D
set result [$g compute_shortest_path "A" "D"]

array set res $result
set path_str [format_path_string $res(path)]

puts " Computed Shortest Path Analysis from A to D:"
puts "   -> Path:      $path_str"
puts "   -> Next Hop:  $res(next_hop)"
puts "   -> Cost:      $res(cost)"
puts "   -> Status:    $res(status)"
puts "------------------------------------------------------------------------"

# 2. Automated Assertions
set expected_path "A->B->C->D"
set expected_cost 4.0
set expected_next_hop "B"

set test_passed 1

if {$path_str != $expected_path} {
    puts " \[FAIL\] Path mismatch! Expected: $expected_path, Got: $path_str"
    set test_passed 0
} else {
    puts " \[PASS\] Shortest path correctly identified: $path_str"
}

if {$res(cost) != $expected_cost} {
    puts " \[FAIL\] Cost mismatch! Expected: $expected_cost, Got: $res(cost)"
    set test_passed 0
} else {
    puts " \[PASS\] Total path cost correctly calculated: $res(cost)"
}

if {$res(next_hop) != $expected_next_hop} {
    puts " \[FAIL\] Next hop mismatch! Expected: $expected_next_hop, Got: $res(next_hop)"
    set test_passed 0
} else {
    puts " \[PASS\] Next hop forwarding entry correct: $res(next_hop)"
}

puts "------------------------------------------------------------------------"
puts " Full Routing Table from Node A:"
set rtable [$g generate_routing_table "A"]
foreach item $rtable {
    set dest [lindex $item 0]
    set entry [lindex $item 1]
    array set dinfo $entry
    puts [format "   Dest: %-3s | Next Hop: %-3s | Cost: %-4.1f | Path: %s" $dest $dinfo(next_hop) $dinfo(cost) [format_path_string $dinfo(path)]]
}

puts "========================================================================"
if {$test_passed} {
    puts " \[SUCCESS\] All Dijkstra unit test assertions PASSED."
    exit 0
} else {
    puts " \[FAILURE\] One or more Dijkstra unit tests failed."
    exit 1
}
