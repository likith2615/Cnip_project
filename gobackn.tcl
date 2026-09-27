# ======================================================================
# Autonomous Vehicle V2V Communication Simulator - Phase 5
# Reusable Tcl Go-Back-N ARQ Protocol Engine: gobackn.tcl
# ======================================================================

Class GoBackNARQEngine

GoBackNARQEngine instproc init {window_size total_pkts {loss_rate 0.10} {timeout_ticks 4}} {
    $self instvar W_ total_pkts_ loss_rate_ timeout_ticks_
    $self instvar send_base_ next_seq_ expected_seq_ timer_ timer_running_
    $self instvar total_sent_ total_recvd_ total_lost_ retrans_count_ logs_
    $self instvar forced_loss_list_ tx_count_

    set W_ $window_size
    set total_pkts_ $total_pkts
    set loss_rate_ $loss_rate
    set timeout_ticks_ $timeout_ticks

    set send_base_ 0
    set next_seq_ 0
    set expected_seq_ 0
    set timer_ 0
    set timer_running_ 0

    set total_sent_ 0
    set total_recvd_ 0
    set total_lost_ 0
    set retrans_count_ 0
    set logs_ {}
    set forced_loss_list_ {}
    array set tx_count_ {}

    for {set i 0} {$i < $total_pkts} {incr i} {
        set tx_count_($i) 0
    }
}

GoBackNARQEngine instproc force_drop {seq_num} {
    $self instvar forced_loss_list_
    lappend forced_loss_list_ $seq_num
}

GoBackNARQEngine instproc log_event {type details} {
    $self instvar logs_
    lappend logs_ [format "%-12s | %s" $type $details]
}

GoBackNARQEngine instproc get_logs {} {
    $self instvar logs_
    return $logs_
}

GoBackNARQEngine instproc print_logs {} {
    $self instvar logs_
    foreach l $logs_ {
        puts "   $l"
    }
}

GoBackNARQEngine instproc run_simulation {{max_ticks 500}} {
    $self instvar W_ total_pkts_ loss_rate_ timeout_ticks_
    $self instvar send_base_ next_seq_ expected_seq_ timer_ timer_running_
    $self instvar total_sent_ total_recvd_ total_lost_ retrans_count_
    $self instvar forced_loss_list_ tx_count_

    set current_tick 0

    while {$send_base_ < $total_pkts_ && $current_tick < $max_ticks} {
        incr current_tick

        # 1. SENDER: Transmit packets within window
        while {$next_seq_ < ($send_base_ + $W_) && $next_seq_ < $total_pkts_} {
            set seq $next_seq_
            incr tx_count_($seq)
            incr total_sent_

            if {$tx_count_($seq) > 1} {
                incr retrans_count_
                $self log_event "RETRANSMIT" "Packet #$seq (Retry #$tx_count_($seq))"
            } else {
                $self log_event "SEND" "Packet #$seq"
            }

            # Start timer if not running
            if {!$timer_running_} {
                set timer_running_ 1
                set timer_ 0
            }

            # Check if packet is lost (either forced or probabilistic)
            set is_lost 0
            set forced_idx [lsearch -exact $forced_loss_list_ $seq]
            if {$forced_idx != -1} {
                set is_lost 1
                set forced_loss_list_ [lreplace $forced_loss_list_ $forced_idx $forced_idx]
            } elseif {[expr {rand() < $loss_rate_}]} {
                set is_lost 1
            }

            if {$is_lost} {
                incr total_lost_
                $self log_event "LOSS" "Packet #$seq dropped by channel"
            } else {
                # Packet successfully reached Receiver
                $self log_event "RECEIVE" "Packet #$seq arrived at receiver"
                
                if {$seq == $expected_seq_} {
                    # In-order packet accepted
                    incr expected_seq_
                    incr total_recvd_
                    set ack_num [expr {$expected_seq_ - 1}]
                    $self log_event "ACK" "Cumulative ACK #$ack_num generated -> Received by sender"
                    
                    # Advance sender base
                    set send_base_ $expected_seq_
                    if {$send_base_ == $next_seq_} {
                        set timer_running_ 0
                        set timer_ 0
                    } else {
                        set timer_ 0
                    }
                } else {
                    # Out of order packet discarded
                    set dup_ack [expr {$expected_seq_ - 1}]
                    $self log_event "ACK" "Out-of-order Frame #$seq discarded! Sending Duplicate ACK #$dup_ack"
                }
            }

            incr next_seq_
        }

        # 2. SENDER TIMER TICK & TIMEOUT HANDLING
        if {$timer_running_} {
            incr timer_
            if {$timer_ >= $timeout_ticks_} {
                $self log_event "TIMEOUT" "Timer expired for base Packet #$send_base_! Go-Back-N triggered (Rewinding next_seq from $next_seq_ to $send_base_)"
                set next_seq_ $send_base_
                set timer_ 0
                set timer_running_ 0
            }
        }
    }

    set delivery_ratio [expr {$total_sent_ > 0 ? (double($total_recvd_) / $total_sent_) * 100.0 : 0.0}]
    set retrans_ratio [expr {$total_sent_ > 0 ? (double($retrans_count_) / $total_sent_) * 100.0 : 0.0}]
    set duration_sec [expr {double($current_tick) * 0.05}] ;# 50ms per tick
    set throughput_kbps [expr {($total_recvd_ * 512 * 8) / ($duration_sec * 1000.0)}]
    set avg_delay_ms [expr {(double($current_tick) / $total_recvd_) * 50.0}]

    return [list \
        sent $total_sent_ \
        received $total_recvd_ \
        lost $total_lost_ \
        retransmissions $retrans_count_ \
        delivery_ratio [format "%.2f" $delivery_ratio] \
        retrans_ratio [format "%.2f" $retrans_ratio] \
        throughput [format "%.2f" $throughput_kbps] \
        delay [format "%.2f" $avg_delay_ms] \
        ticks $current_tick \
    ]
}

proc run_gobackn_benchmark {} {
    set loss_rates {0.00 0.05 0.10 0.20 0.30}
    set fp [open "gobackn_results.csv" w]
    puts $fp "loss_rate,packets_sent,packets_received,packets_lost,retransmissions,delivery_ratio,retransmission_ratio,throughput,delay"

    puts "========================================================================"
    puts "       GO-BACK-N ARQ PARAMETRIC SIMULATION (gobackn_results.csv)        "
    puts "========================================================================"
    puts [format "%-10s | %-6s | %-6s | %-6s | %-9s | %-8s | %-12s" \
        "LOSS_RATE" "SENT" "RECVD" "LOST" "RETRANS" "PDR(%)" "THROUGHPUT(Kbps)"]
    puts "------------------------------------------------------------------------"

    foreach lr $loss_rates {
        set gbn [new GoBackNARQEngine 4 30 $lr 4]
        set res [$gbn run_simulation]
        array set r $res

        puts [format "%-10.2f | %-6d | %-6d | %-6d | %-9d | %-8s | %-12s" \
            $lr $r(sent) $r(received) $r(lost) $r(retransmissions) $r(delivery_ratio) $r(throughput)]

        puts $fp "$lr,$r(sent),$r(received),$r(lost),$r(retransmissions),$r(delivery_ratio),$r(retrans_ratio),$r(throughput),$r(delay)"
    }

    close $fp
    puts "------------------------------------------------------------------------"
    puts " \[OK\] Exported Go-Back-N metrics to gobackn_results.csv"
}
