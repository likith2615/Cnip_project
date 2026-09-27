"""
======================================================================
Autonomous Vehicle V2V Communication Simulator
Module: Distance Vector (Bellman-Ford) Routing Engine
======================================================================
Implements Distance Vector routing for vehicular Ad-Hoc networks.
Demonstrates iterative Bellman-Ford updates:
    D_x(y) = min_v { c(x, v) + D_v(y) }
Features:
- Iterative asynchronous vector exchanges until convergence
- Split Horizon and Poison Reverse options
- Count-to-Infinity anomaly demonstration on link failures
- Routing table exports for comparison with Link-State (Dijkstra)
"""

import copy
from typing import Dict, List, Tuple, Set, Optional


class DistanceVectorRoutingEngine:
    """Simulates Distance Vector routing protocol over vehicular network."""

    def __init__(self, graph_edges: Dict[str, Dict[str, float]], enable_poison_reverse: bool = True):
        self.raw_edges = copy.deepcopy(graph_edges)
        self.nodes = sorted(list(self.raw_edges.keys()))
        self.enable_poison_reverse = enable_poison_reverse
        self.infinity = 999.0  # Academic infinity threshold for Bellman-Ford

        # Distance Table: distance_table[x][y] = current estimated distance from x to y
        self.distance_table: Dict[str, Dict[str, float]] = {}
        # Next Hop Table: next_hop[x][y] = neighbor vehicle used as next hop from x to y
        self.next_hop_table: Dict[str, Dict[str, Optional[str]]] = {}

        self.initialize_tables()

    def initialize_tables(self):
        """Initializes distance tables with direct link costs."""
        for u in self.nodes:
            self.distance_table[u] = {}
            self.next_hop_table[u] = {}
            for v in self.nodes:
                if u == v:
                    self.distance_table[u][v] = 0.0
                    self.next_hop_table[u][v] = "LOCAL"
                elif v in self.raw_edges[u]:
                    self.distance_table[u][v] = self.raw_edges[u][v]
                    self.next_hop_table[u][v] = v
                else:
                    self.distance_table[u][v] = self.infinity
                    self.next_hop_table[u][v] = None

    def get_advertised_vector(self, sender: str, neighbor: str) -> Dict[str, float]:
        """
        Returns the distance vector advertised from sender to neighbor.
        Applies Poison Reverse if enabled: if sender routes to dest via neighbor, advertise infinity.
        """
        vector = {}
        for dest in self.nodes:
            if self.enable_poison_reverse and self.next_hop_table[sender][dest] == neighbor and dest != neighbor:
                vector[dest] = self.infinity
            else:
                vector[dest] = self.distance_table[sender][dest]
        return vector

    def run_convergence(self, max_iterations: int = 50) -> Dict:
        """
        Executes Distance Vector iterative update rounds until convergence.
        Returns execution history, round count, and final tables.
        """
        iteration_log = []
        converged = False
        iteration = 0

        while not converged and iteration < max_iterations:
            iteration += 1
            changed = False
            round_record = {
                "round": iteration,
                "updates": []
            }

            # In each round, each node receives vectors from all its direct neighbors
            new_distance_table = copy.deepcopy(self.distance_table)
            new_next_hop_table = copy.deepcopy(self.next_hop_table)

            for u in self.nodes:
                for dest in self.nodes:
                    if u == dest:
                        continue

                    min_cost = self.infinity
                    best_next_hop = self.next_hop_table[u][dest]

                    # Bellman-Ford relaxation over all direct neighbors v
                    for v, direct_cost in self.raw_edges[u].items():
                        neighbor_vector = self.get_advertised_vector(v, u)
                        cost_via_v = direct_cost + neighbor_vector[dest]
                        if cost_via_v < min_cost:
                            min_cost = cost_via_v
                            best_next_hop = v

                    # Check if updated
                    if round(min_cost, 4) != round(self.distance_table[u][dest], 4):
                        round_record["updates"].append({
                            "node": u,
                            "dest": dest,
                            "old_cost": self.distance_table[u][dest],
                            "new_cost": min_cost,
                            "new_next_hop": best_next_hop
                        })
                        new_distance_table[u][dest] = min_cost
                        new_next_hop_table[u][dest] = best_next_hop
                        changed = True

            self.distance_table = new_distance_table
            self.next_hop_table = new_next_hop_table
            iteration_log.append(round_record)

            if not changed:
                converged = True

        return {
            "converged": converged,
            "total_rounds": iteration,
            "iteration_log": iteration_log,
            "routing_tables": self.get_all_routing_tables()
        }

    def get_all_routing_tables(self) -> Dict[str, Dict]:
        """Returns structured routing tables for all vehicles."""
        tables = {}
        for u in self.nodes:
            tables[u] = {}
            for dest in self.nodes:
                cost = self.distance_table[u][dest]
                next_hop = self.next_hop_table[u][dest]
                tables[u][dest] = {
                    "next_hop": next_hop if cost < self.infinity else "UNREACHABLE",
                    "cost_ms": round(cost, 2) if cost < self.infinity else float('inf')
                }
        return tables

    def trigger_link_failure(self, u: str, v: str):
        """Simulates link failure between u and v."""
        if v in self.raw_edges.get(u, {}):
            del self.raw_edges[u][v]
        if u in self.raw_edges.get(v, {}):
            del self.raw_edges[v][u]
        # Direct distance set to infinity
        self.distance_table[u][v] = self.infinity
        self.distance_table[v][u] = self.infinity

    def print_routing_table(self, vehicle_id: str):
        """Prints formatted distance vector routing table."""
        print(f"\n=======================================================")
        print(f"   DISTANCE VECTOR ROUTING TABLE FOR: {vehicle_id}")
        print(f"=======================================================")
        print(f"{'Destination':<15} | {'Next Hop':<15} | {'Metric/Latency (ms)'}")
        print("-" * 55)
        for dest in self.nodes:
            cost = self.distance_table[vehicle_id][dest]
            nh = self.next_hop_table[vehicle_id][dest]
            cost_str = f"{cost:.2f} ms" if cost < self.infinity else "INF (Unreachable)"
            nh_str = str(nh) if cost < self.infinity else "NONE"
            print(f"{dest:<15} | {nh_str:<15} | {cost_str}")
        print("-" * 55)


if __name__ == "__main__":
    from dijkstra import create_standard_v2v_mesh
    
    mesh = create_standard_v2v_mesh()
    engine_dv = DistanceVectorRoutingEngine(mesh.edges, enable_poison_reverse=True)
    
    print("Running Distance Vector (Bellman-Ford) on V2V Highway Platoon Network...")
    result = engine_dv.run_convergence()
    print(f"Convergence reached in {result['total_rounds']} rounds.")
    
    for round_info in result["iteration_log"]:
        print(f"\nRound {round_info['round']}: {len(round_info['updates'])} vector updates occurred.")
        for upd in round_info["updates"][:4]:
            print(f"  * Node {upd['node']} -> {upd['dest']}: {upd['old_cost']} -> {upd['new_cost']} (via {upd['new_next_hop']})")
            
    engine_dv.print_routing_table("V0")
    engine_dv.print_routing_table("V2")
