# ======================================================================
# Autonomous Vehicle V2V Communication Simulator - Phase 3
# Reusable Tcl Error Detection Module: crc.tcl
# ======================================================================
# Implements pure Tcl bitwise Modulo-2 polynomial division for CRC-16 & CRC-32.
# Polynomials:
#   CRC-16-CCITT : x^16 + x^12 + x^5 + 1 (Generator: 10001000000100001)
#   CRC-32-IEEE  : x^32 + x^26 + x^23 + ... (Generator: 100000100110000010001110110110111)
# ======================================================================

Class CRCModule

CRCModule instproc init {} {
    $self instvar poly16_ poly32_
    # Generator polynomials in binary representation
    set poly16_ "10001000000100001"
    set poly32_ "100000100110000010001110110110111"
}

# Convert ASCII text string to binary bit string
CRCModule instproc str_to_bits {text} {
    set bit_str ""
    set len [string length $text]
    for {set i 0} {$i < $len} {incr i} {
        scan [string index $text $i] "%c" ascii_code
        # Format as 8-bit binary
        for {set b 7} {$b >= 0} {incr b -1} {
            set bit [expr {($ascii_code >> $b) & 1}]
            append bit_str $bit
        }
    }
    return $bit_str
}

# Perform Modulo-2 binary XOR division
CRCModule instproc modulo2_div {dividend divisor} {
    set div_len [string length $divisor]
    set cur [string range $dividend 0 [expr $div_len - 1]]
    set total_len [string length $dividend]

    for {set i $div_len} {$i <= $total_len} {incr i} {
        set first_bit [string index $cur 0]
        set xor_res ""
        
        if {$first_bit == "1"} {
            for {set j 0} {$j < $div_len} {incr j} {
                set b1 [string index $cur $j]
                set b2 [string index $divisor $j]
                set xor_bit [expr {$b1 ^ $b2}]
                append xor_res $xor_bit
            }
        } else {
            for {set j 0} {$j < $div_len} {incr j} {
                set b1 [string index $cur $j]
                set xor_bit [expr {$b1 ^ 0}]
                append xor_res $xor_bit
            }
        }

        # Shift in next bit
        set cur [string range $xor_res 1 end]
        if {$i < $total_len} {
            append cur [string index $dividend $i]
        }
    }

    return $cur
}

# Generate CRC Frame Check Sequence (FCS)
CRCModule instproc generate_crc {data_str {standard "CRC-16"}} {
    $self instvar poly16_ poly32_
    
    if {$standard == "CRC-32"} {
        set poly $poly32_
        set width 32
    } else {
        set poly $poly16_
        set width 16
    }

    set data_bits [$self str_to_bits $data_str]
    # Append 'width' zeros
    set zeros ""
    for {set i 0} {$i < $width} {incr i} {
        append zeros "0"
    }
    set dividend "${data_bits}${zeros}"

    set remainder [$self modulo2_div $dividend $poly]
    return [list data_bits $data_bits crc_bits $remainder transmitted_bits "${data_bits}${remainder}"]
}

# Verify received bitstream at receiver
CRCModule instproc verify_frame {frame_bits {standard "CRC-16"}} {
    $self instvar poly16_ poly32_
    set poly [expr {$standard == "CRC-32" ? $poly32_ : $poly16_}]

    set remainder [$self modulo2_div $frame_bits $poly]
    
    # Check if remainder is all zeros
    set is_valid 1
    for {set i 0} {$i < [string length $remainder]} {incr i} {
        if {[string index $remainder $i] != "0"} {
            set is_valid 0
            break
        }
    }

    return [list valid $is_valid syndrome $remainder]
}

# Simulate channel noise by inverting bits
CRCModule instproc inject_noise {bit_str {num_flips 1}} {
    set len [string length $bit_str]
    set orig $bit_str
    set attempts 0
    while {$bit_str == $orig && $attempts < 10} {
        incr attempts
        for {set f 0} {$f < $num_flips} {incr f} {
            set idx [expr {int(rand() * $len)}]
            set orig_bit [string index $bit_str $idx]
            set flipped_bit [expr {$orig_bit == "1" ? "0" : "1"}]
            set bit_str [string replace $bit_str $idx $idx $flipped_bit]
        }
    }
    return $bit_str
}
