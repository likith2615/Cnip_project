# ======================================================================
# Autonomous Vehicle V2V Communication Simulator
# Scenario 6: TCP Congestion Control Dynamics (Slow Start, AIMD, Fast Recovery)
# Vehicle-to-Vehicle HD Map and Sensor Point Cloud Bulk Transfer
# ======================================================================

set ns [new Simulator]

$ns color 1 Blue      ;# TCP Data Packets
$ns color 2 Red       ;# TCP ACKs

exec mkdir -p results/traces
exec mkdir -p results/csv

set tf [open results/traces/v2v_tcp_congestion.tr w]
$ns trace-all $tf

set nf [open results/traces/v2v_tcp_congestion.nam w]
$ns namtrace-all $nf

# Trace congestion window file
set cwnd_file [open results/csv/tcp_cwnd_trace.csv w]
puts $cwnd_file "Time_sec,CongestionWindow_pkts,Ssthresh_pkts,RTT_sec"

# ======================================================================
# 6-VEHICLE PLATOON TOPOLOGY WITH V2V BOTTLENECK
# ======================================================================
for {set i 0} {$i < 6} {incr i} {
    set v($i) [$ns node]
}

# Vehicles connected in highway mesh
$ns duplex-link $v(0) $v(1) 10Mb 5ms DropTail
$ns duplex-link $v(1) $v(2) 10Mb 5ms DropTail
# Bottleneck between V2 and V3 (limited wireless bandwidth & small buffer)
$ns duplex-link $v(2) $v(3) 3Mb 15ms DropTail
$ns queue-limit $v(2) $v(3) 15
$ns queue-limit $v(3) $v(2) 15

$ns duplex-link $v(3) $v(4) 10Mb 5ms DropTail
$ns duplex-link $v(4) $v(5) 10Mb 5ms DropTail

# ======================================================================
# TCP RENO AGENT (Vehicle 0 transferring HD sensor map to Vehicle 5)
# ======================================================================
set tcp0 [new Agent/TCP/Reno]
$tcp0 set fid_ 1
$tcp0 set window_ 64
$tcp0 set packetSize_ 1000
$ns attach-agent $v(0) $tcp0

set sink5 [new Agent/TCPSink]
$sink5 set fid_ 2
$ns attach-agent $v(5) $sink5
$ns connect $tcp0 $sink5

# Attach FTP Application for continuous transmission
set ftp0 [new Application/FTP]
$ftp0 attach-agent $tcp0

# Add competing background bursty traffic at t=2.0s to trigger congestion collapse & recovery
set udp_burst [new Agent/UDP]
$ns attach-agent $v(2) $udp_burst
set null_burst [new Agent/Null]
$ns attach-agent $v(3) $null_burst
$ns connect $udp_burst $null_burst

set cbr_burst [new Application/Traffic/CBR]
$cbr_burst set packetSize_ 1000
$cbr_burst set interval_ 0.003 ;# Intense burst saturating bottleneck
$cbr_burst attach-agent $udp_burst

# ======================================================================
# CWND TRACING PROCEDURE (Records cwnd every 20ms)
# ======================================================================
proc record_cwnd {} {
    global ns tcp0 cwnd_file
    set time 0.02
    set now [$ns now]
    set cwnd [$tcp0 set cwnd_]
    set ssthresh [$tcp0 set ssthresh_]
    set rtt [$tcp0 set rtt_]
    
    puts $cwnd_file "$now,$cwnd,$ssthresh,$rtt"
    $ns at [expr $now + $time] "record_cwnd"
}

# ======================================================================
# SIMULATION SCHEDULE
# ======================================================================
$ns at 0.1 "record_cwnd"
$ns at 0.5 "$ftp0 start"
$ns at 2.0 "$cbr_burst start"
$ns at 3.0 "$cbr_burst stop"
$ns at 5.0 "$ftp0 stop"

proc finish {} {
    global ns tf nf cwnd_file
    $ns flush-trace
    close $tf
    close $nf
    close $cwnd_file
    puts "V2V TCP Congestion Simulation completed."
    puts "Trace file generated: results/traces/v2v_tcp_congestion.tr"
    puts "CWND log generated: results/csv/tcp_cwnd_trace.csv"
    exit 0
}

$ns at 5.5 "finish"
$ns run
