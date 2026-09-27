"""
======================================================================
Autonomous Vehicle V2V Communication Simulator
Module: Master Trace Parser & CSV Metrics Aggregator
======================================================================
Executes AWK analysis scripts on NS-2 trace files (.tr) and compiles
comprehensive performance metric tables for all simulated vehicular scenarios.
"""

import os
import re
import csv
import subprocess
from typing import Dict, List, Optional


def run_awk_script(awk_file: str, trace_file: str) -> Dict[str, float]:
    """Runs an AWK parser on a trace file and extracts structured metrics."""
    if not os.path.exists(trace_file):
        return {}

    cmd = ["awk", "-f", awk_file, trace_file]
    try:
        proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, check=True)
        metrics = {}
        for line in proc.stdout.splitlines():
            if line.startswith("METRIC_"):
                parts = line.split(":")
                key = parts[0].replace("METRIC_", "").strip()
                val = float(parts[1].strip())
                metrics[key] = val
        return metrics
    except Exception as e:
        print(f"[Error] Failed running AWK on {trace_file}: {e}")
        return {}


def analyze_all_traces():
    """Analyzes all generated traces and creates summary CSV tables."""
    os.makedirs("results/csv", exist_ok=True)

    scenarios = [
        {"id": "baseline", "name": "Highway Platoon Baseline", "trace": "results/traces/v2v_baseline.tr"},
        {"id": "collision_warning", "name": "Emergency Collision Warning", "trace": "results/traces/v2v_collision_warning.tr"},
        {"id": "traffic_congestion", "name": "Intersection Traffic Congestion", "trace": "results/traces/v2v_traffic_congestion.tr"},
        {"id": "routing_dynamics", "name": "Dynamic Route Failover (DV/LS)", "trace": "results/traces/v2v_routing_dynamics.tr"},
        {"id": "tcp_congestion", "name": "TCP Reno Bulk Sensor Sync", "trace": "results/traces/v2v_tcp_congestion.tr"},
    ]

    summary_rows = []
    print("\n==========================================================================================")
    print("                      NS-2 V2V SIMULATION TRACE ANALYSIS SUMMARY")
    print("==========================================================================================")
    print(f"{'Scenario Name':<32} | {'Sent':<7} | {'Recvd':<7} | {'PDR (%)':<8} | {'Loss (%)':<8} | {'Throughput':<12} | {'Avg Delay'}")
    print("-" * 105)

    for sc in scenarios:
        tr_file = sc["trace"]
        pdr_metrics = run_awk_script("analysis/packet_delivery_ratio.awk", tr_file)
        tp_metrics = run_awk_script("analysis/throughput.awk", tr_file)
        delay_metrics = run_awk_script("analysis/end_to_end_delay.awk", tr_file)

        sent = int(pdr_metrics.get("SENT_PKTS", 0))
        recvd = int(pdr_metrics.get("RECVD_PKTS", 0))
        pdr = pdr_metrics.get("PDR_PCT", 0.0)
        loss = pdr_metrics.get("LOSS_PCT", 0.0)
        tp_kbps = tp_metrics.get("THROUGHPUT_KBPS", 0.0)
        tp_mbps = tp_metrics.get("THROUGHPUT_MBPS", 0.0)
        delay_ms = delay_metrics.get("AVG_DELAY_MS", 0.0)
        jitter_ms = delay_metrics.get("AVG_JITTER_MS", 0.0)

        summary_rows.append({
            "Scenario_ID": sc["id"],
            "Scenario_Name": sc["name"],
            "Packets_Sent": sent,
            "Packets_Received": recvd,
            "PDR_Pct": f"{pdr:.2f}%",
            "PDR_Fraction": pdr / 100.0 if pdr > 0 else 0.0,
            "Packet_Loss_Pct": f"{loss:.2f}%",
            "Throughput_Kbps": round(tp_kbps, 2),
            "Throughput_Mbps": round(tp_mbps, 4),
            "Avg_Delay_ms": round(delay_ms, 3),
            "Avg_Jitter_ms": round(jitter_ms, 3)
        })

        print(f"{sc['name']:<32} | {sent:<7} | {recvd:<7} | {pdr:>6.2f}% | {loss:>6.2f}% | {tp_kbps:>8.2f} Kbps | {delay_ms:>6.2f} ms")

    print("-" * 105)

    # Write Master Metrics Summary CSV
    master_csv = "results/csv/metrics_summary.csv"
    with open(master_csv, "w", newline="") as f:
        fieldnames = [
            "Scenario_ID", "Scenario_Name", "Packets_Sent", "Packets_Received",
            "PDR_Pct", "PDR_Fraction", "Packet_Loss_Pct", "Throughput_Kbps",
            "Throughput_Mbps", "Avg_Delay_ms", "Avg_Jitter_ms"
        ]
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(summary_rows)

    print(f"[OK] Master metrics exported to {master_csv}")

    # Analyze Parametric Loss Study Traces
    analyze_loss_study()


def analyze_loss_study():
    """Analyzes parametric error-rate simulation trace files."""
    loss_percentages = [0, 2, 5, 10, 15, 20]
    loss_rows = []

    print("\n==========================================================================================")
    print("              PARAMETRIC V2V WIRELESS PACKET LOSS STUDY (NS-2 TRACES)")
    print("==========================================================================================")
    print(f"{'Channel Loss Rate':<20} | {'Sent':<7} | {'Recvd':<7} | {'PDR (%)':<8} | {'Measured Loss':<14} | {'Throughput':<12} | {'Avg Delay'}")
    print("-" * 105)

    for pct in loss_percentages:
        tr_file = f"results/traces/v2v_loss_{pct}pct.tr"
        # Run simulation if not present
        if not os.path.exists(tr_file):
            rate_frac = pct / 100.0
            subprocess.run(["ns", "ns2/v2v_packet_loss_study.tcl", str(rate_frac)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

        pdr_m = run_awk_script("analysis/packet_delivery_ratio.awk", tr_file)
        tp_m = run_awk_script("analysis/throughput.awk", tr_file)
        del_m = run_awk_script("analysis/end_to_end_delay.awk", tr_file)

        sent = int(pdr_m.get("SENT_PKTS", 0))
        recvd = int(pdr_m.get("RECVD_PKTS", 0))
        pdr = pdr_m.get("PDR_PCT", 0.0)
        loss = pdr_m.get("LOSS_PCT", 0.0)
        tp_kbps = tp_m.get("THROUGHPUT_KBPS", 0.0)
        delay_ms = del_m.get("AVG_DELAY_MS", 0.0)

        loss_rows.append({
            "Configured_Loss_Pct": f"{pct}%",
            "Loss_Rate_Fraction": pct / 100.0,
            "Sent_Packets": sent,
            "Received_Packets": recvd,
            "PDR_Pct": round(pdr, 2),
            "Measured_Loss_Pct": round(loss, 2),
            "Throughput_Kbps": round(tp_kbps, 2),
            "Avg_Delay_ms": round(delay_ms, 3)
        })
        print(f"{pct:>2}% Injection          | {sent:<7} | {recvd:<7} | {pdr:>6.2f}% | {loss:>6.2f}%       | {tp_kbps:>8.2f} Kbps | {delay_ms:>6.2f} ms")

    print("-" * 105)

    loss_csv = "results/csv/loss_study_summary.csv"
    with open(loss_csv, "w", newline="") as f:
        fieldnames = [
            "Configured_Loss_Pct", "Loss_Rate_Fraction", "Sent_Packets",
            "Received_Packets", "PDR_Pct", "Measured_Loss_Pct",
            "Throughput_Kbps", "Avg_Delay_ms"
        ]
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(loss_rows)

    print(f"[OK] Loss study summary exported to {loss_csv}\n")


if __name__ == "__main__":
    analyze_all_traces()
