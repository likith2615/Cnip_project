# ==========================================
# Autonomous Vehicle V2V Communication
# Basic Safety Message Simulation
# ==========================================

set ns [new Simulator]

# Trace files
set nf [open v2v.nam w]
$ns namtrace-all $nf

set tf [open v2v.tr w]
$ns trace-all $tf


# ==========================================
# CREATE AUTONOMOUS VEHICLES
# ==========================================

set v1 [$ns node]
set v2 [$ns node]
set v3 [$ns node]
set v4 [$ns node]
set v5 [$ns node]


# ==========================================
# V2V COMMUNICATION LINKS
# ==========================================

$ns duplex-link $v1 $v2 10Mb 10ms DropTail
$ns duplex-link $v2 $v3 10Mb 10ms DropTail
$ns duplex-link $v3 $v4 10Mb 10ms DropTail
$ns duplex-link $v4 $v5 10Mb 10ms DropTail
$ns duplex-link $v2 $v4 5Mb 20ms DropTail


# ==========================================
# VEHICLE POSITIONS
# ==========================================

$ns duplex-link-op $v1 $v2 orient right
$ns duplex-link-op $v2 $v3 orient right
$ns duplex-link-op $v3 $v4 orient right
$ns duplex-link-op $v4 $v5 orient right
$ns duplex-link-op $v2 $v4 orient down


# ==========================================
# UDP AGENT - VEHICLE 1
# ==========================================

set udp1 [new Agent/UDP]
$ns attach-agent $v1 $udp1


# RECEIVER - VEHICLE 5

set null5 [new Agent/Null]
$ns attach-agent $v5 $null5

$ns connect $udp1 $null5


# ==========================================
# SAFETY MESSAGE GENERATOR
# ==========================================

set cbr1 [new Application/Traffic/CBR]
$cbr1 set packetSize_ 512
$cbr1 set interval_ 0.05
$cbr1 attach-agent $udp1


# ==========================================
# SECOND V2V COMMUNICATION
# ==========================================

set udp2 [new Agent/UDP]
$ns attach-agent $v3 $udp2

set null2 [new Agent/Null]
$ns attach-agent $v1 $null2

$ns connect $udp2 $null2

set cbr2 [new Application/Traffic/CBR]
$cbr2 set packetSize_ 256
$cbr2 set interval_ 0.1
$cbr2 attach-agent $udp2


# ==========================================
# SIMULATION EVENTS
# ==========================================

# Vehicle 1 sends safety messages to Vehicle 5
$ns at 0.5 "$cbr1 start"

# Vehicle 3 sends traffic information to Vehicle 1
$ns at 1.0 "$cbr2 start"

# Stop transmissions
$ns at 4.0 "$cbr1 stop"
$ns at 4.0 "$cbr2 stop"


# ==========================================
# FINISH
# ==========================================

proc finish {} {
    global ns nf tf

    $ns flush-trace

    close $nf
    close $tf

    exit 0
}

$ns at 5.0 "finish"

$ns run
