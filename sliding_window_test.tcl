# ======================================================================
# Autonomous Vehicle V2V Communication Simulator - Phase 4
# Sliding Window Independent Verification Test: sliding_window_test.tcl
# ======================================================================

source sliding_window.tcl

puts "========================================================================"
puts "       SLIDING WINDOW FLOW CONTROL INDEPENDENT VERIFICATION TEST        "
puts "========================================================================"

set sw [new SlidingWindowFlowController 4 10]
set test_passed 1

puts " Initial Window (W=4, Total=10):"
array set st0 [$sw get_status]
puts "   SEND_BASE = $st0(base), NEXT = $st0(next), WINDOW_END = $st0(end)"

# 1. Send packets 0, 1, 2, 3 (Fills window)
puts "\n Transmitting 4 Packets..."
set s0 [$sw send_packet]
set s1 [$sw send_packet]
set s2 [$sw send_packet]
set s3 [$sw send_packet]

array set st1 [$sw get_status]
puts "   SEND_BASE = $st1(base), NEXT = $st1(next), IN_FLIGHT = $st1(in_flight)"

# Verify window is now full
if {[$sw can_send] == 1} {
    puts " \[FAIL\] Sender should not be allowed to exceed window size 4!"
    set test_passed 0
} else {
    puts " \[PASS\] Flow control correctly blocked transmission when window is full."
}

# 2. Receive cumulative ACK for packet 1 (Advances base to 2)
puts "\n Receiving Cumulative ACK seq=1..."
$sw receive_ack 1

array set st2 [$sw get_status]
puts "   SEND_BASE = $st2(base), NEXT = $st2(next), WINDOW_END = $st2(end), IN_FLIGHT = $st2(in_flight)"

if {$st2(base) != 2} {
    puts " \[FAIL\] Window base mismatch! Expected 2, Got: $st2(base)"
    set test_passed 0
} else {
    puts " \[PASS\] Window base shifted successfully to 2."
}

# 3. Transmit 2 new packets (4 and 5)
puts "\n Transmitting new frames into opened window slots..."
set s4 [$sw send_packet]
set s5 [$sw send_packet]

array set st3 [$sw get_status]
puts "   SEND_BASE = $st3(base), NEXT = $st3(next), IN_FLIGHT = $st3(in_flight)"

# 4. Trigger Timeout and Rewind
puts "\n Simulating Timeout on Packet 2..."
$sw timeout
array set st4 [$sw get_status]
puts "   After Timeout: SEND_BASE = $st4(base), NEXT = $st4(next) (Rewound to base)"

if {$st4(next) != $st4(base)} {
    puts " \[FAIL\] Next sequence number was not rewound to base on timeout!"
    set test_passed 0
} else {
    puts " \[PASS\] Timeout correctly rewound next_seq to base for retransmission."
}

# 5. Run full parametric benchmark and generate window_results.csv
puts ""
run_window_benchmark

puts "========================================================================"
if {$test_passed} {
    puts " \[SUCCESS\] All Sliding Window flow control unit tests PASSED."
    exit 0
} else {
    puts " \[FAILURE\] Sliding window tests failed."
    exit 1
}
