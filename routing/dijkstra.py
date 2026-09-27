"""
======================================================================
Autonomous Vehicle V2V Communication Simulator
Module: Dijkstra Link-State Shortest Path Routing Engine
======================================================================
Implements Dijkstra's Shortest Path Algorithm for vehicular mesh networks.
Computes Shortest Path Trees (SPT), intermediate relaxation steps, and
generates full routing tables for all autonomous vehicle nodes.
"""

import heapq
import json
from typing import Dict, List, Tuple, Set, Optional


class VehicularGraph:
    """Represents a V2V vehicular communication network topology."""

    def __init__(self):
        self.nodes: Set[str] = set()
        self.edges: Dict[str, Dict[str, float]] = {}  # u -> {v: weight}
        self.node_positions: Dict[str, Tuple[float, float]] = {}

    def add_vehicle(self, vehicle_id: str, x: float = 0.0, y: float = 0.0):
        self.nodes.add(vehicle_id)
        if vehicle_id not in self.edges:
            self.edges[vehicle_id] = {}
        self.node_positions[vehicle_id] = (x, y)

    def add_v2v_link(self, u: str, v: str, latency_ms: float, bidirectional: bool = True):
        self.add_vehicle(u)
        self.add_vehicle(v)
        self.edges[u][v] = latency_ms
        if bidirectional:
            self.edges[v][u] = latency_ms

    def remove_v2v_link(self, u: str, v: str, bidirectional: bool = True):
        if u in self.edges and v in self.edges[u]:
            del self.edges[u][v]
        if bidirectional and v in self.edges and u in self.edges[v]:
            del self.edges[v][u]

    def get_neighbors(self, u: str) -> Dict[str, float]:
        return self.edges.get(u, {})


class DijkstraRoutingEngine:
    """Executes Dijkstra's Shortest Path algorithm on vehicular topologies."""

    def __init__(self, graph: VehicularGraph):
        self.graph = graph

    def compute_shortest_paths(self, source: str) -> Dict:
        """
        Runs Dijkstra's algorithm from a given source vehicle.
        Returns:
            - distances: Dict[node, min_latency]
            - predecessors: Dict[node, previous_node]
            - step_trace: List of step-by-step relaxation records
            - routing_table: Dict[dest, {next_hop, cost, path}]
        """
        if source not in self.graph.nodes:
            raise ValueError(f"Source vehicle {source} not found in network topology.")

        distances: Dict[str, float] = {node: float('inf') for node in self.graph.nodes}
        predecessors: Dict[str, Optional[str]] = {node: None for node in self.graph.nodes}
        distances[source] = 0.0

        # Priority queue stores tuples of (current_dist, node)
        pq: List[Tuple[float, str]] = [(0.0, source)]
        visited: Set[str] = set()
        step_trace: List[Dict] = []

        step_num = 1
        while pq:
            curr_dist, u = heapq.heappop(pq)

            if u in visited:
                continue
            visited.add(u)

            # Record step snapshot
            step_record = {
                "step": step_num,
                "selected_node": u,
                "current_dist": curr_dist,
                "visited": sorted(list(visited)),
                "relaxed_edges": []
            }

            # Relax neighbors
            for v, weight in self.graph.get_neighbors(u).items():
                if v not in visited:
                    new_dist = curr_dist + weight
                    old_dist = distances[v]
                    if new_dist < old_dist:
                        distances[v] = new_dist
                        predecessors[v] = u
                        heapq.heappush(pq, (new_dist, v))
                        step_record["relaxed_edges"].append({
                            "neighbor": v,
                            "old_dist": old_dist if old_dist != float('inf') else "inf",
                            "new_dist": round(new_dist, 2),
                            "action": "Updated"
                        })
                    else:
                        step_record["relaxed_edges"].append({
                            "neighbor": v,
                            "current_best": round(old_dist, 2),
                            "action": "No change"
                        })

            step_trace.append(step_record)
            step_num += 1

        # Build Forwarding / Routing Table
        routing_table: Dict[str, Dict] = {}
        for dest in sorted(self.graph.nodes):
            if dest == source:
                routing_table[dest] = {"next_hop": "LOCAL", "cost_ms": 0.0, "path": [source]}
                continue

            if distances[dest] == float('inf'):
                routing_table[dest] = {"next_hop": "UNREACHABLE", "cost_ms": float('inf'), "path": []}
                continue

            # Reconstruct path from predecessors
            path = []
            curr = dest
            while curr is not None:
                path.append(curr)
                curr = predecessors[curr]
            path.reverse()

            next_hop = path[1] if len(path) > 1 else dest
            routing_table[dest] = {
                "next_hop": next_hop,
                "cost_ms": round(distances[dest], 2),
                "path": path
            }

        return {
            "source": source,
            "distances": {k: round(v, 2) if v != float('inf') else "inf" for k, v in distances.items()},
            "predecessors": predecessors,
            "step_trace": step_trace,
            "routing_table": routing_table
        }

    def generate_all_routing_tables(self) -> Dict[str, Dict]:
        """Generates routing tables for all vehicles in the network."""
        all_tables = {}
        for node in sorted(self.graph.nodes):
            result = self.compute_shortest_paths(node)
            all_tables[node] = result["routing_table"]
        return all_tables

    def print_routing_table(self, source: str):
        """Displays formatted routing table in terminal."""
        result = self.compute_shortest_paths(source)
        print(f"\n=======================================================")
        print(f"   DIJKSTRA ROUTING TABLE FOR VEHICLE: {source}")
        print(f"=======================================================")
        print(f"{'Destination':<15} | {'Next Hop':<12} | {'Cost (ms)':<10} | {'Shortest Path'}")
        print("-" * 65)
        for dest, entry in sorted(result["routing_table"].items()):
            path_str = " -> ".join(entry["path"]) if entry["path"] else "None"
            cost_str = str(entry["cost_ms"])
            print(f"{dest:<15} | {entry['next_hop']:<12} | {cost_str:<10} | {path_str}")
        print("-" * 65)


def create_standard_v2v_mesh() -> VehicularGraph:
    """Creates standard 6-vehicle platoon highway mesh topology."""
    g = VehicularGraph()
    # Platoon vehicles V0..V5 with inter-vehicle delays (ms)
    g.add_v2v_link("V0", "V1", latency_ms=5.0)
    g.add_v2v_link("V1", "V2", latency_ms=5.0)
    g.add_v2v_link("V2", "V3", latency_ms=5.0)
    g.add_v2v_link("V3", "V4", latency_ms=5.0)
    g.add_v2v_link("V4", "V5", latency_ms=5.0)

    # Redundant / Cross-links (e.g. direct high-range DSRC or bypass links)
    g.add_v2v_link("V0", "V2", latency_ms=12.0)
    g.add_v2v_link("V1", "V3", latency_ms=8.0)
    g.add_v2v_link("V3", "V5", latency_ms=9.0)
    return g


if __name__ == "__main__":
    v_graph = create_standard_v2v_mesh()
    engine = DijkstraRoutingEngine(v_graph)
    
    print("Executing Dijkstra's Algorithm on V2V Highway Platoon Network...")
    res = engine.compute_shortest_paths("V0")
    
    print(f"\nStep-by-Step Shortest Path Tree Relaxation Trace from V0:")
    for step in res["step_trace"]:
        print(f" Step {step['step']}: Visited '{step['selected_node']}' (Dist: {step['current_dist']} ms)")
        for edge in step["relaxed_edges"]:
            if edge["action"] == "Updated":
                print(f"   -> Relax edge to {edge['neighbor']}: {edge['old_dist']} -> {edge['new_dist']} ms (UPDATED)")
            else:
                print(f"   -> Check edge to {edge['neighbor']}: {edge['action']}")
                
    engine.print_routing_table("V0")
    engine.print_routing_table("V2")
