# ======================================================================
# Autonomous Vehicle V2V Communication Simulator
# AWK Script: End-to-End Delay and Jitter Analysis
# Usage: awk -f analysis/end_to_end_delay.awk results/traces/v2v_baseline.tr
# ======================================================================

BEGIN {
    total_delay = 0.0;
    count = 0;
    min_delay = 1e9;
    max_delay = 0.0;
    total_jitter = 0.0;
    prev_delay = -1.0;
}

{
    event = $1;
    time = $2;
    pkt_id = $12;

    # Record first departure time of packet
    if (event == "+" && start_time[pkt_id] == 0) {
        start_time[pkt_id] = time;
    }

    # Record delivery arrival time
    if (event == "r") {
        end_time[pkt_id] = time;
    }
}

END {
    for (id in end_time) {
        if (start_time[id] > 0) {
            delay = (end_time[id] - start_time[id]) * 1000.0; # convert to milliseconds (ms)
            if (delay >= 0) {
                total_delay += delay;
                count++;

                if (delay < min_delay) min_delay = delay;
                if (delay > max_delay) max_delay = delay;

                # Jitter calculation (|delay_i - delay_{i-1}|)
                if (prev_delay >= 0) {
                    diff = delay - prev_delay;
                    if (diff < 0) diff = -diff;
                    total_jitter += diff;
                }
                prev_delay = delay;
            }
        }
    }

    avg_delay = (count > 0) ? (total_delay / count) : 0.0;
    avg_jitter = (count > 1) ? (total_jitter / (count - 1)) : 0.0;
    if (min_delay == 1e9) min_delay = 0.0;

    print "=======================================================";
    print "        V2V END-TO-END DELAY & JITTER SUMMARY          ";
    print "=======================================================";
    printf " Successfully Traced Packets: %d\n", count;
    printf " Average End-to-End Delay:     %.3f ms\n", avg_delay;
    printf " Minimum Latency:             %.3f ms\n", min_delay;
    printf " Maximum Latency:             %.3f ms\n", max_delay;
    printf " Average Jitter (Variation):  %.3f ms\n", avg_jitter;
    print "=======================================================";

    printf "METRIC_TRACED_PKTS:%d\n", count;
    printf "METRIC_AVG_DELAY_MS:%.3f\n", avg_delay;
    printf "METRIC_MIN_DELAY_MS:%.3f\n", min_delay;
    printf "METRIC_MAX_DELAY_MS:%.3f\n", max_delay;
    printf "METRIC_AVG_JITTER_MS:%.3f\n", avg_jitter;
}
