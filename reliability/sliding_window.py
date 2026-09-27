"""
======================================================================
Autonomous Vehicle V2V Communication Simulator
Module: Sliding Window Flow Control Protocol Simulator
======================================================================
Implements sliding window flow control mechanics for vehicular telemetry streams.
Visualizes sender window state, transmitted frames, cumulative acknowledgements,
and buffer utilization.
"""

from typing import List, Dict, Optional


class SlidingWindowBuffer:
    """Represents a Sliding Window buffer with window size W."""

    def __init__(self, window_size: int, total_packets: int):
        self.W = window_size
        self.total_packets = total_packets
        self.base = 0         # Oldest unacknowledged frame sequence number (Sb)
        self.next_seq_num = 0 # Next sequence number to send (Sn)
        self.buffer = [f"PKT_{i}" for i in range(total_packets)]
        self.acked = [False] * total_packets

    def can_send(self) -> bool:
        """Returns True if the current window has capacity to transmit."""
        return self.next_seq_num < (self.base + self.W) and self.next_seq_num < self.total_packets

    def get_next_frame(self) -> Optional[int]:
        """Transmits the next frame in the window and advances next_seq_num."""
        if self.can_send():
            seq = self.next_seq_num
            self.next_seq_num += 1
            return seq
        return None

    def receive_ack(self, ack_num: int) -> int:
        """
        Processes a cumulative ACK for sequence number ack_num.
        Advances window base to ack_num + 1.
        Returns the number of new frames acknowledged.
        """
        if ack_num >= self.base and ack_num < self.total_packets:
            newly_acked = ack_num - self.base + 1
            for i in range(self.base, ack_num + 1):
                self.acked[i] = True
            self.base = ack_num + 1
            return newly_acked
        return 0

    def render_ascii_window(self) -> str:
        """Draws ASCII representation of the sliding window buffer."""
        display = []
        for i in range(min(self.total_packets, self.base + self.W + 2)):
            status = " "
            if self.acked[i]:
                status = "[ACK]"
            elif self.base <= i < self.next_seq_num:
                status = "[SENT]"
            elif self.next_seq_num <= i < self.base + self.W:
                status = "[USBL]"  # Usable within window
            else:
                status = "[BLCK]"  # Blocked outside window

            marker = ""
            if i == self.base and i == self.next_seq_num:
                marker = " <- Base/Next"
            elif i == self.base:
                marker = " <- Base"
            elif i == self.next_seq_num:
                marker = " <- Next"

            display.append(f"  Frame #{i:02d}: {status:<6} {marker}")

        header = f"--- [Window: Size={self.W} | Base={self.base} | Next={self.next_seq_num}] ---"
        return "\n".join([header] + display)


if __name__ == "__main__":
    print("=======================================================")
    print("   SLIDING WINDOW FLOW CONTROL SIMULATOR DEMO")
    print("=======================================================")
    sw = SlidingWindowBuffer(window_size=4, total_packets=10)
    
    print("\nInitial State (Window size = 4):")
    print(sw.render_ascii_window())
    
    print("\nTransmitting 3 frames (PKT_0, PKT_1, PKT_2)...")
    sw.get_next_frame()
    sw.get_next_frame()
    sw.get_next_frame()
    print(sw.render_ascii_window())
    
    print("\nReceiving Cumulative ACK for Frame #1 (ACK 1)...")
    sw.receive_ack(1)
    print(sw.render_ascii_window())
    
    print("\nTransmitting remaining available window slots (PKT_3, PKT_4, PKT_5)...")
    while sw.can_send():
        sw.get_next_frame()
    print(sw.render_ascii_window())
