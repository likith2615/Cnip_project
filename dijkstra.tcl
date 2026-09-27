# ======================================================================
# Autonomous Vehicle V2V Communication Simulator - Phase 2
# Reusable Tcl Routing Module: dijkstra.tcl
# ======================================================================
# Implements Dijkstra's Shortest Path Algorithm in pure Tcl.
# Computes shortest paths, total costs, next-hop forwarding tables,
# and Shortest Path Trees (SPT) for vehicular network topologies.
# ======================================================================

Class DijkstraGraph

DijkstraGraph instproc init {} {
    $self instvar nodes_ adj_list_
    set nodes_ {}
    array set adj_list_ {}
}

# Add a vehicle node to the graph
DijkstraGraph instproc add_node {node} {
    $self instvar nodes_ adj_list_
    if {[lsearch -exact $nodes_ $node] == -1} {
        lappend nodes_ $node
        set adj_list_($node) {}
    }
}

# Add a V2V communication link with metric / latency cost
DijkstraGraph instproc add_edge {u v cost {bidirectional 1}} {
    $self instvar adj_list_
    $self add_node $u
    $self add_node $v
    
    # Store edge as pair {neighbor cost}
    set adj_list_($u) [$self update_neighbor_list $adj_list_($u) $v $cost]
    if {$bidirectional} {
        set adj_list_($v) [$self update_neighbor_list $adj_list_($v) $u $cost]
    }
}

# Helper to update or insert neighbor in list
DijkstraGraph instproc update_neighbor_list {nlist neighbor cost} {
    set new_list {}
    set found 0
    foreach item $nlist {
        set n [lindex $item 0]
        set c [lindex $item 1]
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

# Remove an edge (for dynamic link failure simulation)
DijkstraGraph instproc remove_edge {u v {bidirectional 1}} {
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

# Compute shortest path from source to destination
DijkstraGraph instproc compute_shortest_path {source target} {
    $self instvar nodes_ adj_list_

    if {[lsearch -exact $nodes_ $source] == -1} {
        error "Source node $source does not exist in graph."
    }
    if {[lsearch -exact $nodes_ $target] == -1} {
        error "Target node $target does not exist in graph."
    }

    set INF 1e9
    array set dist {}
    array set prev {}
    array set visited {}

    foreach n $nodes_ {
        set dist($n) $INF
        set prev($n) ""
        set visited($n) 0
    }

    set dist($source) 0.0

    # Dijkstra priority loop
    while {1} {
        # Find unvisited node with minimum tentative distance
        set min_dist $INF
        set u ""

        foreach n $nodes_ {
            if {!$visited($n) && $dist($n) < $min_dist} {
                set min_dist $dist($n)
                set u $n
            }
        }

        # If no reachable unvisited node remains, break
        if {$u == "" || $min_dist == $INF} {
            break
        }

        # If target reached and visited, we can terminate early
        if {$u == $target} {
            break
        }

        set visited($u) 1

        # Relax adjacent edges
        if {[info exists adj_list_($u)]} {
            foreach edge $adj_list_($u) {
                set v [lindex $edge 0]
                set cost [lindex $edge 1]
                if {!$visited($v)} {
                    set alt [expr {$dist($u) + $cost}]
                    if {$alt < $dist($v)} {
                        set dist($v) $alt
                        set prev($v) $u
                    }
                }
            }
        }
    }

    # Reconstruct path from target back to source
    if {$dist($target) == $INF} {
        return [list path {} cost $INF next_hop "NONE" status "UNREACHABLE"]
    }

    set path {}
    set curr $target
    while {$curr != ""} {
        lappend path $curr
        set curr $prev($curr)
    }

    # Reverse path
    set rev_path {}
    for {set i [expr [llength $path] - 1]} {$i >= 0} {incr i -1} {
        lappend rev_path [lindex $path $i]
    }

    # Identify Next Hop
    set next_hop $source
    if {[llength $rev_path] > 1} {
        set next_hop [lindex $rev_path 1]
    }

    return [list path $rev_path cost $dist($target) next_hop $next_hop status "SUCCESS"]
}

# Generate complete routing table for a given node
DijkstraGraph instproc generate_routing_table {source} {
    $self instvar nodes_
    set table {}
    foreach dest $nodes_ {
        set res [$self compute_shortest_path $source $dest]
        lappend table [list $dest $res]
    }
    return $table
}

# Helper to format path as V1->V2->V3
proc format_path_string {path_list} {
    return [join $path_list "->"]
}
