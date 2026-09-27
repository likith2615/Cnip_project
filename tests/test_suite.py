"""
======================================================================
Autonomous Vehicle V2V Communication Simulator
Module: Automated Verification & Unit Test Suite
======================================================================
Validates the correctness of:
- Dijkstra Link-State & Distance Vector Routing
- CRC-16 & CRC-32 Bitwise Error Detection
- Sliding Window Flow Control & Go-Back-N ARQ
- NS-2 Trace File Generation & CSV Schema
"""

import os
import sys
import unittest

# Add project root to sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from routing.dijkstra import VehicularGraph, DijkstraRoutingEngine, create_standard_v2v_mesh
from routing.distance_vector import DistanceVectorRoutingEngine
from reliability.crc import CRC, V2VFrame, VehicularChannelNoiseSimulator
from reliability.sliding_window import SlidingWindowBuffer
from reliability.go_back_n import GoBackNProtocolSimulator


class TestRoutingEngines(unittest.TestCase):
    """Unit tests for Dijkstra and Distance Vector routing algorithms."""

    def setUp(self):
        self.graph = create_standard_v2v_mesh()

    def test_dijkstra_shortest_paths(self):
        engine = DijkstraRoutingEngine(self.graph)
        res = engine.compute_shortest_paths("V0")
        
        # Verify self distance is 0
        self.assertEqual(res["distances"]["V0"], 0.0)
        # Direct neighbor V1 distance is 5.0ms
        self.assertEqual(res["distances"]["V1"], 5.0)
        # Shortest distance to V5 via chain V0-V1-V2-V3-V4-V5 (25ms) vs V0-V1-V3-V5 (5+8+9=22ms)
        self.assertEqual(res["distances"]["V5"], 22.0)
        self.assertEqual(res["routing_table"]["V5"]["path"], ["V0", "V1", "V3", "V5"])

    def test_distance_vector_convergence(self):
        dv = DistanceVectorRoutingEngine(self.graph.edges, enable_poison_reverse=True)
        res = dv.run_convergence()
        
        self.assertTrue(res["converged"])
        # Both algorithms must compute identical shortest path costs
        dijkstra = DijkstraRoutingEngine(self.graph).compute_shortest_paths("V0")
        for node in self.graph.nodes:
            self.assertAlmostEqual(res["routing_tables"]["V0"][node]["cost_ms"], dijkstra["distances"][node])


class TestCRCErrorDetection(unittest.TestCase):
    """Unit tests for CRC-16 and CRC-32 error detection."""

    def test_clean_frame_syndrome_zero(self):
        test_bytes = b"EMERGENCY_BRAKE_MSG_101|SPEED:80|DECEL:6.5"
        crc_int, crc_bits, _ = CRC.compute_crc(test_bytes, "CRC-16-CCITT")
        
        frame_bits = CRC.bytes_to_bits(test_bytes) + crc_bits
        is_valid, syndrome = CRC.verify_frame(frame_bits, "CRC-16-CCITT")
        self.assertTrue(is_valid)
        self.assertEqual(int(syndrome, 2), 0)

    def test_single_bit_flip_detection(self):
        test_bytes = b"V2V_COLLISION_ALERT_NODE_0"
        _, crc_bits, _ = CRC.compute_crc(test_bytes, "CRC-16-CCITT")
        frame_bits = CRC.bytes_to_bits(test_bytes) + crc_bits

        for _ in range(50):
            corrupted, _ = VehicularChannelNoiseSimulator.inject_single_bit_error(frame_bits)
            is_valid, _ = CRC.verify_frame(corrupted, "CRC-16-CCITT")
            self.assertFalse(is_valid, "CRC-16 must detect all single-bit errors.")

    def test_burst_error_detection(self):
        test_bytes = b"PLATOON_COORDINATION_TELEMETRY"
        _, crc_bits, _ = CRC.compute_crc(test_bytes, "CRC-16-CCITT")
        frame_bits = CRC.bytes_to_bits(test_bytes) + crc_bits

        for _ in range(50):
            corrupted, _, _ = VehicularChannelNoiseSimulator.inject_burst_error(frame_bits, burst_length=8)
            is_valid, _ = CRC.verify_frame(corrupted, "CRC-16-CCITT")
            self.assertFalse(is_valid, "CRC-16 must detect all burst errors <= 16 bits.")


class TestFlowAndARQControl(unittest.TestCase):
    """Unit tests for Sliding Window and Go-Back-N ARQ state machines."""

    def test_sliding_window_boundaries(self):
        sw = SlidingWindowBuffer(window_size=4, total_packets=10)
        self.assertEqual(sw.base, 0)
        self.assertEqual(sw.next_seq_num, 0)
        
        # Send 4 frames (fills window)
        for _ in range(4):
            self.assertIsNotNone(sw.get_next_frame())
        self.assertFalse(sw.can_send())
        
        # Receive ACK for frame 1 (advances base to 2)
        acked = sw.receive_ack(1)
        self.assertEqual(acked, 2)
        self.assertEqual(sw.base, 2)
        self.assertTrue(sw.can_send())

    def test_go_back_n_reliable_delivery(self):
        sim = GoBackNProtocolSimulator(
            window_size=4,
            total_packets=15,
            packet_loss_rate=0.20,
            ack_loss_rate=0.05,
            timeout_ticks=4,
            random_seed=77
        )
        res = sim.run_simulation()
        
        # Must reliably deliver all 15 packets despite 20% loss rate
        self.assertEqual(res["total_packets"], 15)
        self.assertEqual(sim.expected_seq_num, 15)
        self.assertGreaterEqual(res["total_transmissions"], 15)
        self.assertGreater(res["protocol_efficiency"], 0.0)


class TestSimulationDeliverables(unittest.TestCase):
    """Verifies existence and non-empty status of simulation artifacts."""

    def test_trace_files_exist(self):
        expected_traces = [
            "results/traces/v2v_baseline.tr",
            "results/traces/v2v_collision_warning.tr",
            "results/traces/v2v_traffic_congestion.tr",
            "results/traces/v2v_routing_dynamics.tr",
            "results/traces/v2v_tcp_congestion.tr"
        ]
        for tr in expected_traces:
            self.assertTrue(os.path.exists(tr), f"Trace file {tr} missing.")
            self.assertGreater(os.path.getsize(tr), 1000, f"Trace file {tr} is empty.")

    def test_csv_files_exist(self):
        expected_csvs = [
            "results/csv/metrics_summary.csv",
            "results/csv/loss_study_summary.csv",
            "results/csv/routing_comparison.csv",
            "results/csv/crc_validation.csv",
            "results/csv/arq_performance.csv",
            "results/csv/tcp_cwnd_trace.csv"
        ]
        for c in expected_csvs:
            self.assertTrue(os.path.exists(c), f"CSV file {c} missing.")

    def test_graphs_exist(self):
        expected_graphs = [
            "results/graphs/pdr_vs_loss_rate.png",
            "results/graphs/tcp_cwnd_dynamics.png",
            "results/graphs/routing_convergence_comparison.png",
            "results/graphs/arq_efficiency_vs_loss.png",
            "results/graphs/scenario_performance_matrix.png"
        ]
        for g in expected_graphs:
            self.assertTrue(os.path.exists(g), f"Graph file {g} missing.")
            self.assertGreater(os.path.getsize(g), 5000, f"Graph file {g} corrupted or empty.")


if __name__ == "__main__":
    unittest.main(verbosity=2)
