# ======================================================================
# Autonomous Vehicle V2V Communication Simulator
# AWK Script: Average and Time-Series Throughput Calculation
# Usage: awk -f analysis/throughput.awk results/traces/v2v_baseline.tr
# ======================================================================

BEGIN {
    recvdSize = 0;
    startTime = 1e9;
    stopTime = 0;
    totalPkts = 0;
    time_interval = 0.1; # 100ms granularity
}

{
    event = $1;
    time = $2;
    from_node = $3;
    to_node = $4;
    pkt_type = $5;
    pkt_size = $6;
    flow_id = $8;
    seq_num = $11;

    # Record simulation start and stop time
    if (time < startTime) {
        startTime = time;
    }
    if (time > stopTime) {
        stopTime = time;
    }

    # Count received packets at final destination node
    if (event == "r") {
        recvdSize += pkt_size;
        totalPkts++;
        
        # Time-series bucket aggregation
        bucket = int(time / time_interval);
        bucket_bytes[bucket] += pkt_size;
        if (bucket > max_bucket) max_bucket = bucket;
    }
}

END {
    duration = stopTime - startTime;
    if (duration <= 0) duration = 1;

    # Throughput in Kilobits per second (Kbps)
    throughput_kbps = (recvdSize * 8) / (duration * 1000);
    throughput_mbps = throughput_kbps / 1000;

    print "=======================================================";
    print "           V2V THROUGHPUT ANALYSIS SUMMARY             ";
    print "=======================================================";
    printf " Simulation Time:      %.2f to %.2f s (Duration: %.2f s)\n", startTime, stopTime, duration;
    printf " Total Data Received:  %d bytes (%d packets)\n", recvdSize, totalPkts;
    printf " Average Throughput:   %.2f Kbps (%.4f Mbps)\n", throughput_kbps, throughput_mbps;
    print "=======================================================";

    # Output structured key-value line for automated python parser
    printf "METRIC_THROUGHPUT_KBPS:%.2f\n", throughput_kbps;
    printf "METRIC_THROUGHPUT_MBPS:%.4f\n", throughput_mbps;
    printf "METRIC_RECVD_BYTES:%d\n", recvdSize;
    printf "METRIC_DURATION_SEC:%.2f\n", duration;
}
