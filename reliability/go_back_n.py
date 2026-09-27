"""
======================================================================
Autonomous Vehicle V2V Communication Simulator
Module: Go-Back-N (GBN) ARQ Protocol Simulator
======================================================================
Implements an event-driven Go-Back-N ARQ protocol engine for unreliable V2V links.
Simulates:
- Sender sliding window of size W
- Cumulative acknowledgements (ACK K)
- Single timer associated with oldest unACKed packet (base)
- Go-Back-N retransmission upon timeout
- Receiver strict in-order acceptance & duplicate ACK generation
- Realistic lossy vehicular wireless channel
"""

import random
from typing import List, Dict, Tuple, Optional


class GBNPacket:
    """Represents a discrete network packet in Go-Back-N."""

    def __init__(self, seq_num: int, payload: str):
        self.seq_num = seq_num
        self.payload = payload
        self.transmission_count = 0


class GoBackNProtocolSimulator:
    """Simulates sender, receiver, channel, and timers for Go-Back-N ARQ."""

    def __init__(
        self,
        window_size: int = 4,
        total_packets: int = 20,
        packet_loss_rate: float = 0.10,
        ack_loss_rate: float = 0.05,
        timeout_ticks: int = 5,
        random_seed: int = 42
    ):
        self.W = window_size
        self.total_packets = total_packets
        self.packet_loss_rate = packet_loss_rate
        self.ack_loss_rate = ack_loss_rate
        self.timeout_ticks = timeout_ticks

        if random_seed is not None:
            random.seed(random_seed)

        # Sender State
        self.base = 0           # Sb: base of window
        self.next_seq_num = 0   # Sn: next sequence number to transmit
        self.timer = 0          # Timer counter for packet at self.base
        self.timer_running = False
        self.sender_packets = [
            GBNPacket(i, f"V2V_SAFETY_MSG_{i}") for i in range(total_packets)
        ]

        # Receiver State
        self.expected_seq_num = 0  # Rn: next in-order expected packet

        # Performance Metrics
        self.current_tick = 0
        self.total_transmissions = 0
        self.total_retransmissions = 0
        self.dropped_data_packets = 0
        self.dropped_ack_packets = 0
        self.completed_packets = 0
        self.event_log: List[Dict] = []

    def run_simulation(self, max_ticks: int = 500) -> Dict:
        """Executes the discrete-time GBN simulation until all packets are delivered."""
        while self.base < self.total_packets and self.current_tick < max_ticks:
            self.current_tick += 1
            tick_events = []

            # 1. SENDER: Transmit newly available packets in current window
            while self.next_seq_num < (self.base + self.W) and self.next_seq_num < self.total_packets:
                pkt = self.sender_packets[self.next_seq_num]
                pkt.transmission_count += 1
                self.total_transmissions += 1
                if pkt.transmission_count > 1:
                    self.total_retransmissions += 1

                # Start timer if not running
                if not self.timer_running:
                    self.timer_running = True
                    self.timer = 0

                # Simulate Channel transmission for data packet
                is_lost = random.random() < self.packet_loss_rate
                if is_lost:
                    self.dropped_data_packets += 1
                    tick_events.append(f"[SEND-LOST] Packet #{pkt.seq_num} dropped by wireless channel noise")
                else:
                    tick_events.append(f"[SEND-OK] Packet #{pkt.seq_num} transmitted successfully")
                    # RECEIVER processes packet
                    ack_event = self._receiver_process_packet(pkt)
                    if ack_event:
                        tick_events.append(ack_event)

                self.next_seq_num += 1

            # 2. SENDER TIMER MANAGEMENT & TIMEOUT CHECK
            if self.timer_running:
                self.timer += 1
                if self.timer >= self.timeout_ticks:
                    # Timeout occurred! Go Back to base
                    tick_events.append(
                        f"[TIMEOUT] Timer expired for Base Packet #{self.base}! Go-Back-N triggered: Rewinding next_seq_num from {self.next_seq_num} back to {self.base}"
                    )
                    self.next_seq_num = self.base
                    self.timer = 0
                    self.timer_running = False

            self.event_log.append({
                "tick": self.current_tick,
                "base": self.base,
                "next_seq_num": self.next_seq_num,
                "expected": self.expected_seq_num,
                "events": tick_events
            })

        # Calculate final summary
        efficiency = (self.total_packets / self.total_transmissions) if self.total_transmissions > 0 else 0.0
        return {
            "window_size": self.W,
            "total_packets": self.total_packets,
            "packet_loss_rate": self.packet_loss_rate,
            "ack_loss_rate": self.ack_loss_rate,
            "total_ticks": self.current_tick,
            "total_transmissions": self.total_transmissions,
            "total_retransmissions": self.total_retransmissions,
            "dropped_data": self.dropped_data_packets,
            "dropped_acks": self.dropped_ack_packets,
            "protocol_efficiency": round(efficiency * 100.0, 2),
            "event_log": self.event_log
        }

    def _receiver_process_packet(self, pkt: GBNPacket) -> Optional[str]:
        """Receiver state machine: checks in-order sequence and returns ACK message."""
        if pkt.seq_num == self.expected_seq_num:
            # Correct in-order packet received!
            self.expected_seq_num += 1
            ack_num = self.expected_seq_num - 1
            self.completed_packets += 1

            # Simulate ACK transmission through lossy channel
            is_ack_lost = random.random() < self.ack_loss_rate
            if is_ack_lost:
                self.dropped_ack_packets += 1
                return f"[RCV-ACCEPT] Frame #{pkt.seq_num} accepted, but cumulative ACK #{ack_num} was LOST in transit!"
            else:
                # SENDER receives ACK
                self._sender_process_ack(ack_num)
                return f"[RCV-ACCEPT] Frame #{pkt.seq_num} accepted -> Cumulative ACK #{ack_num} received by sender"
        else:
            # Out of order packet discarded
            dup_ack = self.expected_seq_num - 1
            return f"[RCV-DISCARD] Out-of-order Frame #{pkt.seq_num} discarded (Expected #{self.expected_seq_num}) -> Sending duplicate ACK #{dup_ack}"

    def _sender_process_ack(self, ack_num: int):
        """Sender advances window upon receipt of cumulative ACK."""
        if ack_num >= self.base:
            self.base = ack_num + 1
            if self.base == self.next_seq_num:
                # No unacknowledged packets in flight, stop timer
                self.timer_running = False
                self.timer = 0
            else:
                # Still have pending packets, restart timer
                self.timer_running = True
                self.timer = 0


if __name__ == "__main__":
    print("=======================================================================")
    print("        GO-BACK-N ARQ PROTOCOL SIMULATION (V2V SAFETY LINK)")
    print("=======================================================================")
    sim = GoBackNProtocolSimulator(
        window_size=4,
        total_packets=12,
        packet_loss_rate=0.15,
        ack_loss_rate=0.05,
        timeout_ticks=4,
        random_seed=101
    )
    res = sim.run_simulation()

    print(f"\nExecution Event Log:")
    for entry in res["event_log"]:
        if entry["events"]:
            print(f"Tick {entry['tick']:02d} | Base={entry['base']} Next={entry['next_seq_num']} Expected={entry['expected']}")
            for ev in entry["events"]:
                print(f"   -> {ev}")

    print("\n-----------------------------------------------------------------------")
    print(f"Simulation Summary:")
    print(f" Total Safety Packets Delivered: {res['total_packets']}")
    print(f" Total Transmissions:            {res['total_transmissions']} (Retransmissions: {res['total_retransmissions']})")
    print(f" Channel Losses:                 {res['dropped_data']} data pkts, {res['dropped_acks']} ACKs")
    print(f" Total Simulation Time (Ticks):  {res['total_ticks']}")
    print(f" GBN Protocol Efficiency:        {res['protocol_efficiency']}%")
    print("-----------------------------------------------------------------------")
