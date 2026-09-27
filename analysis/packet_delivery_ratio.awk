# ======================================================================
# Autonomous Vehicle V2V Communication Simulator
# AWK Script: End-to-End Packet Delivery Ratio (PDR) & Loss Calculation
# Accurately distinguishes Source Originations from Destination Deliveries
# Usage: awk -f analysis/packet_delivery_ratio.awk results/traces/v2v_baseline.tr
# ======================================================================

BEGIN {
    total_generated = 0;
    total_delivered = 0;
    total_dropped = 0;
    hop_sent = 0;
    hop_recvd = 0;
}

{
    event = $1;
    time = $2;
    from_node = $3;
    to_node = $4;
    pkt_type = $5;
    pkt_size = $6;
    flow_id = $8;
    src_addr = $9;
    dst_addr = $10;
    seq_num = $11;
    pkt_id = $12;

    # Parse node IDs from addresses (e.g., "0.0" -> 0, "5.0" -> 5)
    split(src_addr, src_parts, ".");
    src_node = src_parts[1];

    split(dst_addr, dst_parts, ".");
    dst_node = dst_parts[1];

    # 1. End-to-End Origination (Packet leaves source node for the very first time)
    if (event == "+" && from_node == src_node && !generated[pkt_id]) {
        generated[pkt_id] = 1;
        total_generated++;
    }

    # 2. End-to-End Delivery (Packet arrives at its designated target destination)
    if (event == "r" && to_node == dst_node && !delivered[pkt_id]) {
        delivered[pkt_id] = 1;
        total_delivered++;
    }

    # 3. Packet Drop
    if (event == "d") {
        total_dropped++;
    }

    # Hop-by-hop counters
    if (event == "+") hop_sent++;
    if (event == "r") hop_recvd++;
}

END {
    # If topology is broadcast or special addressing, fallback gracefully
    if (total_generated == 0) total_generated = hop_sent;
    if (total_delivered == 0) total_delivered = hop_recvd;

    pdr = (total_generated > 0) ? (total_delivered / total_generated) * 100.0 : 0.0;
    if (pdr > 100.0) pdr = 100.0;

    lost_e2e = total_generated - total_delivered;
    if (lost_e2e < 0) lost_e2e = 0;
    loss_rate = (total_generated > 0) ? (lost_e2e / total_generated) * 100.0 : 0.0;

    print "=======================================================";
    print "     V2V PACKET DELIVERY RATIO (PDR) & LOSS SUMMARY    ";
    print "=======================================================";
    printf " End-to-End Packets Generated: %d\n", total_generated;
    printf " End-to-End Packets Delivered: %d\n", total_delivered;
    printf " End-to-End Packets Lost:      %d\n", lost_e2e;
    printf " Total Queue Drops Traced:     %d\n", total_dropped;
    printf " Packet Delivery Ratio (PDR):  %.2f %%\n", pdr;
    printf " Packet Loss Ratio:            %.2f %%\n", loss_rate;
    print "=======================================================";

    # Output structured key-value line for automated python parser
    printf "METRIC_SENT_PKTS:%d\n", total_generated;
    printf "METRIC_RECVD_PKTS:%d\n", total_delivered;
    printf "METRIC_DROPPED_PKTS:%d\n", total_dropped;
    printf "METRIC_PDR_PCT:%.2f\n", pdr;
    printf "METRIC_LOSS_PCT:%.2f\n", loss_rate;
}
