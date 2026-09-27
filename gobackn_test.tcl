# ======================================================================
# Autonomous Vehicle V2V Communication Simulator - Phase 5
# Go-Back-N ARQ Independent Verification Test: gobackn_test.tcl
# ======================================================================

source gobackn.tcl

puts "========================================================================"
puts "       GO-BACK-N ARQ INDEPENDENT DETERMINISTIC TEST                     "
puts "========================================================================"

# Test with window size 4, total 10 packets, 0% random loss, but FORCE Packet #3 to drop
set gbn [new GoBackNARQEngine 4 10 0.00 4]
$gbn force_drop 3

puts " Scenario Setup:"
puts "   -> Window Size: W = 4"
puts "   -> Total Packets: 10 (Seq 0..9)"
puts "   -> Forced Loss: Packet #3 will be intentionally dropped by channel"
puts "   -> Expected: Packets 0, 1, 2 delivered -> Pkt 3 lost -> Pkts 4, 5 out-of-order discarded"
puts "                Timer expires -> Go-Back-N retransmits starting from #3 onward"
puts "------------------------------------------------------------------------"

set sim_res [$gbn run_simulation 100]
array set sinfo $sim_res

puts " Execution Event Log:"
$gbn print_logs
puts "------------------------------------------------------------------------"

# Assertions
set test_passed 1

if {$sinfo(received) != 10} {
    puts " \[FAIL\] All 10 packets should be reliably delivered! Got: $sinfo(received)"
    set test_passed 0
} else {
    puts " \[PASS\] All 10 packets reliably delivered despite forced loss."
}

if {$sinfo(lost) != 1} {
    puts " \[FAIL\] Expected exactly 1 packet loss event! Got: $sinfo(lost)"
    set test_passed 0
} else {
    puts " \[PASS\] Forced loss detected exactly as configured."
}

if {$sinfo(retransmissions) < 1} {
    puts " \[FAIL\] Expected retransmissions! Got: $sinfo(retransmissions)"
    set test_passed 0
} else {
    puts " \[PASS\] Go-Back-N retransmissions occurred: $sinfo(retransmissions) frames retransmitted."
}

puts "------------------------------------------------------------------------"
# Run parametric benchmark across loss rates and generate gobackn_results.csv
run_gobackn_benchmark

puts "========================================================================"
if {$test_passed} {
    puts " \[SUCCESS\] All Go-Back-N ARQ unit test assertions PASSED."
    exit 0
} else {
    puts " \[FAILURE\] Go-Back-N tests failed."
    exit 1
}
