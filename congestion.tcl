# ======================================================================
# Autonomous Vehicle V2V Communication Simulator - Phase 7
# Congestion Control & Rate Adaptation Module: congestion.tcl
# ======================================================================
# Implements pure Tcl active congestion control and rate adaptation.
# Monitors queue occupancy and packet drops on bottleneck links.
# Applies Additive Increase Multiplicative Decrease (AIMD) on CBR sending interval.
# ======================================================================

Class CongestionController

CongestionController instproc init {cbr_agent {min_interval 0.01} {max_interval 0.20}} {
    $self instvar cbr_ min_interval_ max_interval_ curr_interval_
    $self instvar drop_count_ last_drop_count_ state_ logs_
    
    set cbr_ $cbr_agent
    set min_interval_ $min_interval   ;# High rate (low interval)
    set max_interval_ $max_interval   ;# Throttled rate (high interval)
    set curr_interval_ $min_interval
    set drop_count_ 0
    set last_drop_count_ 0
    set state_ "NORMAL"
    set logs_ {}
}

# Record a queue drop detection event
CongestionController instproc record_drop {} {
    $self instvar drop_count_
    incr drop_count_
}

# Periodic congestion monitoring & AIMD adaptation step
CongestionController instproc evaluate_congestion {time_now} {
    $self instvar cbr_ min_interval_ max_interval_ curr_interval_
    $self instvar drop_count_ last_drop_count_ state_ logs_

    set new_drops [expr {$drop_count_ - $last_drop_count_}]
    set last_drop_count_ $drop_count_

    if {$new_drops > 0} {
        # CONGESTION DETECTED! Multiplicative Decrease (Increase interval by 2x)
        set old_int $curr_interval_
        set curr_interval_ [expr {$curr_interval_ * 2.0}]
        if {$curr_interval_ > $max_interval_} {
            set curr_interval_ $max_interval_
        }
        set state_ "THROTTLED"
        set rate_kbps [expr {(512 * 8) / ($curr_interval_ * 1000.0)}]
        set log_msg [format "TIME=%.2fs | CONGESTION_DETECTED (Drops=%d) -> Multiplicative Decrease: Interval %.3fs -> %.3fs (Rate: %.1f Kbps)" \
            $time_now $new_drops $old_int $curr_interval_ $rate_kbps]
        lappend logs_ $log_msg
        puts "   \[CONGESTION-RESPONSE\] $log_msg"
        
        # Apply to NS-2 agent
        $cbr_ set interval_ $curr_interval_
    } else {
        # CHANNEL CLEAR: Additive Increase (Decrease interval by small step)
        if {$curr_interval_ > $min_interval_} {
            set old_int $curr_interval_
            set curr_interval_ [expr {$curr_interval_ - 0.005}]
            if {$curr_interval_ < $min_interval_} {
                set curr_interval_ $min_interval_
            }
            set state_ "RECOVERING"
            set rate_kbps [expr {(512 * 8) / ($curr_interval_ * 1000.0)}]
            set log_msg [format "TIME=%.2fs | QUEUE_NORMAL -> Additive Recovery: Interval %.3fs -> %.3fs (Rate: %.1f Kbps)" \
                $time_now $old_int $curr_interval_ $rate_kbps]
            lappend logs_ $log_msg
            $cbr_ set interval_ $curr_interval_
        }
    }
}
