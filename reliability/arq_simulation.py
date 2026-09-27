"""
======================================================================
Autonomous Vehicle V2V Communication Simulator
Module: ARQ Performance & Flow Control Parametric Study
======================================================================
Evaluates Go-Back-N ARQ efficiency across different window sizes and
varying vehicular wireless packet error rates.
Exports: results/csv/arq_performance.csv
"""

import os
import csv
from typing import List, Dict
from go_back_n import GoBackNProtocolSimulator


def run_parametric_arq_study():
    """Runs Go-Back-N simulation across window sizes and channel loss rates."""
    os.makedirs("results/csv", exist_ok=True)

    window_sizes = [1, 2, 4, 8, 16]  # W=1 corresponds to Stop-and-Wait ARQ
    loss_rates = [0.0, 0.05, 0.10, 0.15, 0.20, 0.25, 0.30]
    total_packets = 50

    results: List[Dict] = []

    print("\n==========================================================================================")
    print("                 GO-BACK-N ARQ PARAMETRIC PERFORMANCE EVALUATION")
    print("==========================================================================================")
    print(f"{'Window Size (W)':<16} | {'Loss Rate (%)':<14} | {'Total Tx':<10} | {'Retransmissions':<16} | {'Efficiency (%)'}")
    print("-" * 90)

    for w in window_sizes:
        for p in loss_rates:
            sim = GoBackNProtocolSimulator(
                window_size=w,
                total_packets=total_packets,
                packet_loss_rate=p,
                ack_loss_rate=0.02,
                timeout_ticks=5,
                random_seed=42 + int(p * 100) + w
            )
            data = sim.run_simulation(max_ticks=2000)

            record = {
                "Window_Size": w,
                "Loss_Rate_Pct": f"{int(p * 100)}%",
                "Loss_Rate_Fraction": p,
                "Total_Packets": total_packets,
                "Total_Transmissions": data["total_transmissions"],
                "Retransmissions": data["total_retransmissions"],
                "Data_Dropped": data["dropped_data"],
                "ACK_Dropped": data["dropped_acks"],
                "Total_Ticks": data["total_ticks"],
                "Efficiency_Pct": data["protocol_efficiency"]
            }
            results.append(record)

            if p in [0.0, 0.10, 0.20, 0.30]:
                w_desc = f"W={w} (Stop-and-Wait)" if w == 1 else f"W={w} (GBN)"
                print(f"{w_desc:<16} | {int(p*100):>3}%          | {data['total_transmissions']:<10} | {data['total_retransmissions']:<16} | {data['protocol_efficiency']}%")

    print("-" * 90)

    # Save CSV
    csv_path = "results/csv/arq_performance.csv"
    with open(csv_path, "w", newline="") as f:
        fieldnames = [
            "Window_Size", "Loss_Rate_Pct", "Loss_Rate_Fraction",
            "Total_Packets", "Total_Transmissions", "Retransmissions",
            "Data_Dropped", "ACK_Dropped", "Total_Ticks", "Efficiency_Pct"
        ]
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(results)

    print(f"[OK] ARQ Parametric results exported to {csv_path}\n")
    return results


if __name__ == "__main__":
    run_parametric_arq_study()
