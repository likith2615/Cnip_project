# ======================================================================
# Autonomous Vehicle V2V Communication Simulator
# AWK Trace Parser & Metrics Collector: metrics_collector.awk
# Usage: awk -f analysis/metrics_collector.awk exp_name.tr
# Outputs single line: SENT,RECVD,DROPPED,PDR,LOSS_PCT,THROUGHPUT_KBPS,AVG_DELAY_MS,JITTER_MS
# ======================================================================

BEGIN {
    total_generated = 0;
    total_delivered = 0;
    total_dropped = 0;
    recvd_bytes = 0;
    start_time = 1e9;
    stop_time = 0;
    total_delay = 0.0;
    traced_count = 0;
    prev_delay = -1.0;
    total_jitter = 0.0;
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

    split(src_addr, src_parts, ".");
    src_node = src_parts[1];
    split(dst_addr, dst_parts, ".");
    dst_node = dst_parts[1];

    if (time < start_time) start_time = time;
    if (time > stop_time) stop_time = time;

    # End-to-end source packet origination
    if (event == "+" && from_node == src_node && !generated[pkt_id]) {
        generated[pkt_id] = 1;
        pkt_start[pkt_id] = time;
        total_generated++;
    }

    # End-to-end packet delivery
    if (event == "r" && to_node == dst_node && !delivered[pkt_id]) {
        delivered[pkt_id] = 1;
        total_delivered++;
        recvd_bytes += pkt_size;

        if (pkt_start[pkt_id] > 0) {
            delay = (time - pkt_start[pkt_id]) * 1000.0;
            total_delay += delay;
            traced_count++;

            if (prev_delay >= 0) {
                diff = delay - prev_delay;
                if (diff < 0) diff = -diff;
                total_jitter += diff;
            }
            prev_delay = delay;
        }
    }

    if (event == "d") {
        total_dropped++;
    }
}

END {
    if (total_generated == 0) total_generated = 1;
    duration = stop_time - start_time;
    if (duration <= 0) duration = 1.0;

    pdr = (total_delivered / total_generated) * 100.0;
    if (pdr > 100.0) pdr = 100.0;
    
    loss_pct = ((total_generated - total_delivered) * 100.0) / total_generated;
    if (loss_pct < 0.0) loss_pct = 0.0;

    tp_kbps = (recvd_bytes * 8.0) / (duration * 1000.0);
    avg_delay = (traced_count > 0) ? (total_delay / traced_count) : 0.0;
    avg_jitter = (traced_count > 1) ? (total_jitter / (traced_count - 1)) : 0.0;

    printf "%d,%d,%d,%.2f,%.2f,%.2f,%.3f,%.3f\n", \
        total_generated, total_delivered, total_dropped, pdr, loss_pct, tp_kbps, avg_delay, avg_jitter;
}
