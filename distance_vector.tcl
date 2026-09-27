# ======================================================================
# Autonomous Vehicle V2V Communication Simulator
# Reusable Tcl Routing Module: distance_vector.tcl
# ======================================================================
# Implements pure Tcl Distance Vector (Bellman-Ford) routing algorithm.
# Each node maintains its routing table (DESTINATION, DISTANCE/COST, NEXT_HOP)
# and iteratively exchanges vectors with neighbors until convergence.
# Includes Split Horizon and Poison Reverse to prevent routing loops.
# ======================================================================

Class DistanceVectorGraph

DistanceVectorGraph instproc init {} {
    $self instvar nodes_ adj_list_ rtable_ prev_rtable_
    set nodes_ {}
    array set adj_list_ {}
    array set rtable_ {}
    array set prev_rtable_ {}
}

# Add node to graph
DistanceVectorGraph instproc add_node {node} {
    $self instvar nodes_ adj_list_
    if {[lsearch -exact $nodes_ $node] == -1} {
        lappend nodes_ $node
        set adj_list_($node) {}
    }
}

# Add bidirectional or directed edge with cost
DistanceVectorGraph instproc add_edge {u v cost {bidirectional 1}} {
    $self instvar adj_list_
    $self add_node $u
    $self add_node $v
    
    set adj_list_($u) [$self update_neighbor_list $adj_list_($u) $v $cost]
    if {$bidirectional} {
        set adj_list_($v) [$self update_neighbor_list $adj_list_($v) $u $cost]
    }
}

# Helper to update neighbor list
DistanceVectorGraph instproc update_neighbor_list {nlist neighbor cost} {
    set new_list {}
    set found 0
    foreach item $nlist {
        set n [lindex $item 0]
        if {$n == $neighbor} {
            lappend new_list [list $neighbor $cost]
            set found 1
        } else {
            lappend new_list $item
        }
    }
    if {!$found} {
        lappend new_list [list $neighbor $cost]
    }
    return $new_list
}

# Remove edge (link failure simulation)
DistanceVectorGraph instproc remove_edge {u v {bidirectional 1}} {
    $self instvar adj_list_
    if {[info exists adj_list_($u)]} {
        set new_list {}
        foreach item $adj_list_($u) {
            if {[lindex $item 0] != $v} {
                lappend new_list $item
            }
        }
        set adj_list_($u) $new_list
    }
    if {$bidirectional && [info exists adj_list_($v)]} {
        set new_list {}
        foreach item $adj_list_($v) {
            if {[lindex $item 0] != $u} {
                lappend new_list $item
            }
        }
        set adj_list_($v) $new_list
    }
}

# Initialize local routing tables
DistanceVectorGraph instproc init_routing_tables {} {
    $self instvar nodes_ adj_list_ rtable_
    set INF 1e9

    foreach u $nodes_ {
        foreach dest $nodes_ {
            if {$u == $dest} {
                set rtable_($u,$dest,cost) 0.0
                set rtable_($u,$dest,next_hop) $u
            } else {
                set rtable_($u,$dest,cost) $INF
                set rtable_($u,$dest,next_hop) "NONE"
            }
        }

        # Set direct neighbor links
        if {[info exists adj_list_($u)]} {
            foreach edge $adj_list_($u) {
                set v [lindex $edge 0]
                set cost [lindex $edge 1]
                set rtable_($u,$v,cost) $cost
                set rtable_($u,$v,next_hop) $v
            }
        }
    }
}

# Run Bellman-Ford Distance Vector convergence rounds
DistanceVectorGraph instproc run_convergence {{enable_poison_reverse 1} {max_iterations 30} {time_stamp 1.00}} {
    $self instvar nodes_ adj_list_ rtable_
    $self init_routing_tables

    set INF 1e9
    set iteration 0
    set total_updates 0
    set update_logs {}

    while {$iteration < $max_iterations} {
        incr iteration
        set changed 0

        # Snapshot current tables for synchronous round exchange
        array set curr_cost {}
        array set curr_next {}
        foreach u $nodes_ {
            foreach dest $nodes_ {
                set curr_cost($u,$dest) $rtable_($u,$dest,cost)
                set curr_next($u,$dest) $rtable_($u,$dest,next_hop)
            }
        }

        # Each node u relaxes distances using advertised vectors from direct neighbors
        foreach u $nodes_ {
            if {![info exists adj_list_($u)]} continue

            foreach dest $nodes_ {
                if {$u == $dest} continue

                set min_cost $curr_cost($u,$dest)
                set best_nh $curr_next($u,$dest)
                set old_cost $curr_cost($u,$dest)

                foreach edge $adj_list_($u) {
                    set v [lindex $edge 0]
                    set link_cost [lindex $edge 1]

                    # Advertised cost from v to dest
                    set adv_cost $curr_cost($v,$dest)

                    # Poison reverse: if v routes to dest through u, advertise INF
                    if {$enable_poison_reverse && $curr_next($v,$dest) == $u && $dest != $u} {
                        set adv_cost $INF
                    }

                    if {$adv_cost < $INF} {
                        set total_via_v [expr {$link_cost + $adv_cost}]
                        if {$total_via_v < $min_cost} {
                            set min_cost $total_via_v
                            set best_nh $v
                        }
                    }
                }

                # If updated, record change and log
                if {$min_cost != $old_cost} {
                    set old_cost_str [expr {$old_cost >= $INF ? "INF" : [format "%.1f" $old_cost]}]
                    set new_cost_str [format "%.1f" $min_cost]
                    
                    set log_entry [list \
                        "TIME=[format "%.2f" $time_stamp]" \
                        "NODE=$u" \
                        "DESTINATION=$dest" \
                        "OLD_COST=$old_cost_str" \
                        "NEW_COST=$new_cost_str" \
                        "NEXT_HOP=$best_nh" \
                    ]
                    lappend update_logs $log_entry

                    set rtable_($u,$dest,cost) $min_cost
                    set rtable_($u,$dest,next_hop) $best_nh
                    set changed 1
                    incr total_updates
                }
            }
        }

        if {!$changed} {
            break
        }
    }

    return [list iterations $iteration updates $total_updates logs $update_logs]
}

# Query shortest path and cost from Distance Vector tables
DistanceVectorGraph instproc get_route {source target} {
    $self instvar nodes_ rtable_
    set INF 1e9

    if {![info exists rtable_($source,$target,cost)]} {
        $self run_convergence
    }

    set cost $rtable_($source,$target,cost)
    if {$cost >= $INF} {
        return [list path {} cost $INF next_hop "NONE" status "UNREACHABLE"]
    }

    # Trace next-hops to build complete path
    set path [list $source]
    set curr $source
    set visited_trace [list $source]

    while {$curr != $target} {
        set nh $rtable_($curr,$target,next_hop)
        if {$nh == "NONE" || [lsearch -exact $visited_trace $nh] != -1} {
            # Loop or broken route
            break
        }
        lappend path $nh
        lappend visited_trace $nh
        set curr $nh
    }

    set next_hop [lindex $path 1]
    return [list path $path cost $cost next_hop $next_hop status "SUCCESS"]
}

# Print full Distance Vector routing table for a given node
DistanceVectorGraph instproc print_routing_table {node} {
    $self instvar nodes_ rtable_
    set INF 1e9
    puts "======================================================="
    puts "     DISTANCE VECTOR ROUTING TABLE FOR NODE: $node     "
    puts "======================================================="
    puts [format "%-15s | %-12s | %-12s" "DESTINATION" "NEXT_HOP" "COST"]
    puts "-------------------------------------------------------"
    foreach dest $nodes_ {
        set cost $rtable_($node,$dest,cost)
        set nh $rtable_($node,$dest,next_hop)
        set cost_str [expr {$cost >= $INF ? "INF" : [format "%.1f" $cost]}]
        puts [format "%-15s | %-12s | %-12s" $dest $nh $cost_str]
    }
    puts "-------------------------------------------------------"
}
