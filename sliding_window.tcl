# ======================================================================
# Autonomous Vehicle V2V Communication Simulator - Phase 4
# Reusable Tcl Flow Control Module: sliding_window.tcl
# ======================================================================
# Implements pure Tcl Sliding Window flow control state machine.
# Maintains SEND_BASE, NEXT_SEQUENCE_NUMBER, WINDOW_END,
# and tracks in-flight vs acknowledged frames.
# ======================================================================

Class SlidingWindowFlowController

SlidingWindowFlowController instproc init {w_size total_pkts} {
    $self instvar W_ total_pkts_ send_base_ next_seq_ acked_ sent_ logs_
    set W_ $w_size
    set total_pkts_ $total_pkts
    set send_base_ 0
    set next_seq_ 0
    set logs_ {}
    array set acked_ {}
    array set sent_ {}

    for {set i 0} {$i < $total_pkts} {incr i} {
        set acked_($i) 0
        set sent_($i) 0
    }
}

# Check if sender has available window capacity
SlidingWindowFlowController instproc can_send {} {
    $self instvar W_ total_pkts_ send_base_ next_seq_
    return [expr {$next_seq_ < ($send_base_ + $W_) && $next_seq_ < $total_pkts_}]
}

# Transmit next packet in window
SlidingWindowFlowController instproc send_packet {} {
    $self instvar W_ total_pkts_ send_base_ next_seq_ sent_ logs_
    if {[$self can_send]} {
        set seq $next_seq_
        set sent_($seq) 1
        set log_msg "SEND seq=$seq"
        lappend logs_ $log_msg
        incr next_seq_
        return $seq
    }
    return -1
}

# Process cumulative ACK
SlidingWindowFlowController instproc receive_ack {ack_seq} {
    $self instvar W_ total_pkts_ send_base_ next_seq_ acked_ logs_
    if {$ack_seq >= $send_base_ && $ack_seq < $total_pkts_} {
        lappend logs_ "ACK seq=$ack_seq"
        for {set i $send_base_} {$i <= $ack_seq} {incr i} {
            set acked_($i) 1
        }
        set send_base_ [expr {$ack_seq + 1}]
        lappend logs_ "WINDOW_SHIFT base=$send_base_"
        return 1
    }
    return 0
}

# Trigger timeout on base packet
SlidingWindowFlowController instproc timeout {} {
    $self instvar send_base_ next_seq_ logs_
    lappend logs_ "TIMEOUT seq=$send_base_"
    # Rewind next_seq to send_base
    set next_seq_ $send_base_
}

# Get current window metrics
SlidingWindowFlowController instproc get_status {} {
    $self instvar W_ send_base_ next_seq_ total_pkts_
    set in_flight [expr {$next_seq_ - $send_base_}]
    set win_end [expr {$send_base_ + $W_ - 1}]
    return [list base $send_base_ next $next_seq_ end $win_end in_flight $in_flight]
}

# Run a complete flow control batch simulation and export CSV
proc run_window_benchmark {} {
    set window_sizes {1 4 8 16}
    set total_packets 40
    set rtt_ms 10.0

    set fp [open "window_results.csv" w]
    puts $fp "window_size,packets_sent,packets_acked,packets_in_flight,throughput,average_delay"

    puts "========================================================================"
    puts "       SLIDING WINDOW FLOW CONTROL PARAMETRIC BENCHMARK                 "
    puts "========================================================================"
    puts [format "%-12s | %-12s | %-13s | %-14s | %-12s" "WINDOW_SIZE" "PKTS_SENT" "PKTS_ACKED" "THROUGHPUT(Kbps)" "AVG_DELAY(ms)"]
    puts "------------------------------------------------------------------------"

    foreach w $window_sizes {
        set sw [new SlidingWindowFlowController $w $total_packets]
        set time_ms 0.0
        set sent_count 0
        set acked_count 0

        # Simulate transmission rounds
        while {$acked_count < $total_packets} {
            # Fill available window slots
            while {[$sw can_send]} {
                set seq [$sw send_packet]
                if {$seq != -1} {
                    incr sent_count
                }
            }

            # Advance by 1 RTT and ACK transmitted batch
            set time_ms [expr {$time_ms + $rtt_ms}]
            set cur_status [$sw get_status]
            array set sinfo $cur_status
            
            if {$sinfo(in_flight) > 0} {
                set ack_to [expr {$sinfo(next) - 1}]
                $sw receive_ack $ack_to
                set acked_count [expr {$ack_to + 1}]
            }
        }

        set duration_sec [expr {$time_ms / 1000.0}]
        set throughput_kbps [expr {($acked_count * 512 * 8) / ($duration_sec * 1000.0)}]
        set avg_delay_ms [expr {$rtt_ms * (double($total_packets) / $w)}]

        puts [format "%-12d | %-12d | %-13d | %-16.2f | %-12.2f" \
            $w $sent_count $acked_count $throughput_kbps $avg_delay_ms]

        puts $fp "$w,$sent_count,$acked_count,0,[format "%.2f" $throughput_kbps],[format "%.2f" $avg_delay_ms]"
    }

    close $fp
    puts "------------------------------------------------------------------------"
    puts " \[OK\] Exported window metrics to window_results.csv"
}
