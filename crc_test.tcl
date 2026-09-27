# ======================================================================
# Autonomous Vehicle V2V Communication Simulator - Phase 3
# CRC Independent Verification Test: crc_test.tcl
# ======================================================================

source crc.tcl

puts "========================================================================"
puts "       CRC-16 & CRC-32 ERROR DETECTION INDEPENDENT TEST                 "
puts "========================================================================"

set crc_mod [new CRCModule]

# 1. Test Single Frame Clean vs Corrupted
set payload "V2V|TYPE:EMERGENCY_BRAKE|SRC:V1|DST:V8|SEQ:101|DECEL:7.8"
puts " Testing V2V Safety Payload: '$payload'"

set gen_res [$crc_mod generate_crc $payload "CRC-16"]
array set ginfo $gen_res

puts "   -> Calculated CRC-16 FCS (16 bits): $ginfo(crc_bits)"
puts "   -> Transmitted Frame Length:         [string length $ginfo(transmitted_bits)] bits"

# Verify Clean Frame
set clean_ver [$crc_mod verify_frame $ginfo(transmitted_bits) "CRC-16"]
array set cvinfo $clean_ver
puts "   -> Clean Frame Verification: Syndrome=$cvinfo(syndrome) (Valid: $cvinfo(valid))"

# Verify Corrupted Frame (Single Bit Flip)
set corrupted_bits [$crc_mod inject_noise $ginfo(transmitted_bits) 1]
set corrupt_ver [$crc_mod verify_frame $corrupted_bits "CRC-16"]
array set crvinfo $corrupt_ver
puts "   -> Corrupted Frame Verification: Syndrome=$crvinfo(syndrome) (Valid: $crvinfo(valid))"

# 2. Multi-Payload Statistical Benchmark
puts "------------------------------------------------------------------------"
puts " Running Multi-Payload CRC Detection Benchmark (500 trials per rate)..."
puts "------------------------------------------------------------------------"

set error_rates {0.00 0.05 0.10 0.20}
set test_passed 1

foreach er $error_rates {
    set total 500
    set valid_count 0
    set corrupted_count 0
    set detected_errors 0
    set missed_errors 0

    for {set t 0} {$t < $total} {incr t} {
        set p_data "V2V_ALERT_$t|SPEED:[expr 80 + ($t % 30)]"
        set g_info [$crc_mod generate_crc $p_data "CRC-16"]
        array set g_arr $g_info
        set tx_bits $g_arr(transmitted_bits)

        # Inject error based on error rate
        set is_corrupted [expr {rand() < $er}]
        if {$is_corrupted} {
            set tx_bits [$crc_mod inject_noise $tx_bits [expr {int(rand() * 3) + 1}]]
            incr corrupted_count
        } else {
            incr valid_count
        }

        # Receiver verification
        set v_res [$crc_mod verify_frame $tx_bits "CRC-16"]
        array set v_arr $v_res

        if {$v_arr(valid) && $is_corrupted} {
            incr missed_errors
        } elseif {!$v_arr(valid) && $is_corrupted} {
            incr detected_errors
        }
    }

    set error_pct [expr {$total > 0 ? (double($corrupted_count) / $total) * 100.0 : 0.0}]
    puts [format " Error Rate %-4s: Checked=%d | Valid=%d | Corrupted=%d | Detected=%d | Missed=%d" \
        "$er" $total $valid_count $corrupted_count $detected_errors $missed_errors]

    if {$missed_errors > 0} {
        set test_passed 0
    }
}

puts "------------------------------------------------------------------------"
if {$cvinfo(valid) == 1 && $crvinfo(valid) == 0 && $test_passed} {
    puts " TOTAL_PACKETS_CHECKED = 2000"
    puts " VALID_PACKETS         = Tested"
    puts " CRC_ERRORS            = Detected 100%"
    puts " CORRUPTED_PACKETS     = Filtered"
    puts " CRC_ERROR_RATE        = 0.00% Missed"
    puts "========================================================================"
    puts " \[SUCCESS\] All CRC Error Detection unit test assertions PASSED."
    exit 0
} else {
    puts " \[FAILURE\] CRC verification tests failed."
    exit 1
}
