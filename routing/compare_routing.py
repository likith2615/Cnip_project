"""
======================================================================
Autonomous Vehicle V2V Communication Simulator
Module: Routing Algorithm Comparison Engine (Dijkstra vs Distance Vector)
======================================================================
Performs deep comparative analysis between:
1. Link-State (Dijkstra) Shortest Path First
2. Distance Vector (Bellman-Ford) Distributed Routing
Evaluates under normal platoon operation and dynamic vehicular link failures.
"""

import os
import csv
import json
import time
from typing import Dict, List
from dijkstra import VehicularGraph, DijkstraRoutingEngine, create_standard_v2v_mesh
from distance_vector import DistanceVectorRoutingEngine


def run_routing_comparison() -> Dict:
    """Executes comparative evaluation and generates tabular metrics."""
    os.makedirs("results/csv", exist_ok=True)
    
    # Setup standard 6-vehicle platoon mesh
    graph = create_standard_v2v_mesh()
    num_nodes = len(graph.nodes)
    num_links = sum(len(neighbors) for neighbors in graph.edges.values()) // 2
    
    # 1. DIJKSTRA LINK-STATE EVALUATION
    dijkstra_engine = DijkstraRoutingEngine(graph)
    t0 = time.perf_counter()
    dijkstra_tables = dijkstra_engine.generate_all_routing_tables()
    dijkstra_time_ms = (time.perf_counter() - t0) * 1000.0
    
    # Dijkstra Link State Flooding message count:
    # Each vehicle generates 1 LSA flooded over E links -> O(N * E) messages
    ls_messages = num_nodes * num_links
    
    # 2. DISTANCE VECTOR EVALUATION (Normal state)
    dv_engine = DistanceVectorRoutingEngine(graph.edges, enable_poison_reverse=True)
    t0 = time.perf_counter()
    dv_result = dv_engine.run_convergence()
    dv_time_ms = (time.perf_counter() - t0) * 1000.0
    
    # DV message count: Each round, every node sends DV to direct neighbors -> 2 * E per round
    dv_messages = dv_result["total_rounds"] * (2 * num_links)
    
    # 3. DYNAMIC LINK FAILURE EVALUATION (V1 - V3 Link Failure)
    print("\n[Simulation Event] Simulating V2V link failure between V1 and V3...")
    
    # Link State after failure
    graph_broken = create_standard_v2v_mesh()
    graph_broken.remove_v2v_link("V1", "V3")
    dijkstra_broken = DijkstraRoutingEngine(graph_broken)
    dijkstra_broken_tables = dijkstra_broken.generate_all_routing_tables()
    
    # Distance Vector after failure (With Poison Reverse)
    dv_engine_fail = DistanceVectorRoutingEngine(graph.edges, enable_poison_reverse=True)
    dv_engine_fail.run_convergence()
    dv_engine_fail.trigger_link_failure("V1", "V3")
    dv_fail_result_pr = dv_engine_fail.run_convergence()
    
    # Distance Vector after failure (Without Poison Reverse -> Count-to-Infinity demonstration)
    dv_engine_no_pr = DistanceVectorRoutingEngine(graph.edges, enable_poison_reverse=False)
    dv_engine_no_pr.run_convergence()
    dv_engine_no_pr.trigger_link_failure("V1", "V3")
    dv_fail_result_no_pr = dv_engine_no_pr.run_convergence(max_iterations=15)
    
    # Validate Path Equivalence
    paths_match = True
    for node in graph.nodes:
        for dest in graph.nodes:
            d_cost = dijkstra_tables[node][dest]["cost_ms"]
            dv_cost = dv_result["routing_tables"][node][dest]["cost_ms"]
            if abs(d_cost - dv_cost) > 0.001:
                paths_match = False

    # Summary table
    comparison_data = [
        {"Metric": "Routing Algorithm Class", "Dijkstra (Link-State)": "Global / Centralized or Flooded", "Distance Vector (Bellman-Ford)": "Decentralized / Iterative"},
        {"Metric": "Topology Knowledge", "Dijkstra (Link-State)": "Complete Global Map (LSA DB)", "Distance Vector (Bellman-Ford)": "Next-hop local neighbors only"},
        {"Metric": "Time Complexity per Node", "Dijkstra (Link-State)": "O(V^2) or O(E + V log V)", "Distance Vector (Bellman-Ford)": "O(V * E) rounds"},
        {"Metric": "Convergence Rounds (Initial)", "Dijkstra (Link-State)": "1 round (after LSA flood)", "Distance Vector (Bellman-Ford)": f"{dv_result['total_rounds']} rounds"},
        {"Metric": "Message Overhead (Initial)", "Dijkstra (Link-State)": f"{ls_messages} LSA packets", "Distance Vector (Bellman-Ford)": f"{dv_messages} DV exchange packets"},
        {"Metric": "Reconvergence after Link Failure (V1-V3)", "Dijkstra (Link-State)": "Immediate (1 LSA flood)", "Distance Vector (Bellman-Ford)": f"{dv_fail_result_pr['total_rounds']} rounds (with Poison Reverse)"},
        {"Metric": "Count-to-Infinity Susceptibility", "Dijkstra (Link-State)": "None (No routing loops)", "Distance Vector (Bellman-Ford)": f"High without PR ({dv_fail_result_no_pr['total_rounds']}+ rounds to detect INF)"},
        {"Metric": "V0 -> V5 Shortest Latency (Normal)", "Dijkstra (Link-State)": f"{dijkstra_tables['V0']['V5']['cost_ms']} ms", "Distance Vector (Bellman-Ford)": f"{dv_result['routing_tables']['V0']['V5']['cost_ms']} ms"},
        {"Metric": "V0 -> V5 Shortest Latency (V1-V3 Down)", "Dijkstra (Link-State)": f"{dijkstra_broken_tables['V0']['V5']['cost_ms']} ms", "Distance Vector (Bellman-Ford)": f"{dv_fail_result_pr['routing_tables']['V0']['V5']['cost_ms']} ms"},
        {"Metric": "Optimal Shortest Path Consistency", "Dijkstra (Link-State)": "100% Identical Cost", "Distance Vector (Bellman-Ford)": "100% Identical Cost" if paths_match else "Divergent"}
    ]
    
    # Save to CSV
    csv_path = "results/csv/routing_comparison.csv"
    with open(csv_path, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=["Metric", "Dijkstra (Link-State)", "Distance Vector (Bellman-Ford)"])
        writer.writeheader()
        writer.writerows(comparison_data)
        
    print(f"\n==========================================================================================")
    print(f"               V2V ROUTING ALGORITHMS COMPARATIVE EVALUATION MATRIX")
    print(f"==========================================================================================")
    print(f"{'Evaluation Metric':<45} | {'Dijkstra (Link-State)':<24} | {'Distance Vector (DV)':<26}")
    print("-" * 100)
    for row in comparison_data:
        print(f"{row['Metric']:<45} | {row['Dijkstra (Link-State)']:<24} | {row['Distance Vector (Bellman-Ford)']:<26}")
    print("-" * 100)
    print(f"\n[OK] Comparative summary successfully exported to {csv_path}")
    
    return {
        "dijkstra": dijkstra_tables,
        "dv": dv_result,
        "comparison_table": comparison_data
    }


if __name__ == "__main__":
    run_routing_comparison()
