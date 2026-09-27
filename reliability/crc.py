"""
======================================================================
Autonomous Vehicle V2V Communication Simulator
Module: CRC Error Detection Engine (CRC-16-CCITT & CRC-32-IEEE 802.3)
======================================================================
Implements bitwise modulo-2 polynomial division for V2V safety frames.
Simulates vehicular channel noise (bit flips, burst errors) and validates
the error detection capability of CRC polynomials.
"""

import os
import csv
import json
import random
from typing import Dict, Tuple, List


class CRC:
    """Implements bitwise CRC-16 and CRC-32 calculation and verification."""

    POLYNOMIALS = {
        "CRC-16-CCITT": {
            "poly": 0x1021,
            "width": 16,
            "init": 0xFFFF,
            "poly_binary": "10001000000100001"  # x^16 + x^12 + x^5 + 1
        },
        "CRC-32-IEEE": {
            "poly": 0x04C11DB7,
            "width": 32,
            "init": 0xFFFFFFFF,
            "poly_binary": "100000100110000010001110110110111"
        }
    }

    @staticmethod
    def bytes_to_bits(data_bytes: bytes) -> str:
        """Converts raw bytes to binary bit string."""
        return "".join(f"{b:08b}" for b in data_bytes)

    @staticmethod
    def modulo2_division(dividend_bits: str, divisor_bits: str) -> Tuple[str, str, List[Dict]]:
        """
        Performs step-by-step modulo-2 binary division.
        Returns (quotient_bits, remainder_bits, step_trace).
        """
        div_len = len(divisor_bits)
        cur = list(dividend_bits[:div_len])
        quotient = []
        step_trace = []

        for i in range(div_len, len(dividend_bits) + 1):
            if cur[0] == '1':
                quotient.append('1')
                # XOR with divisor
                xor_res = [str(int(a) ^ int(b)) for a, b in zip(cur, divisor_bits)]
                if len(step_trace) < 5:  # Store first few steps for educational trace
                    step_trace.append({
                        "step": len(step_trace) + 1,
                        "current_bits": "".join(cur),
                        "divisor": divisor_bits,
                        "xor_remainder": "".join(xor_res[1:])
                    })
                cur = xor_res[1:]
            else:
                quotient.append('0')
                # XOR with all zeros
                xor_res = [str(int(a) ^ 0) for a in cur]
                cur = xor_res[1:]

            if i < len(dividend_bits):
                cur.append(dividend_bits[i])

        remainder = "".join(cur)
        return "".join(quotient), remainder, step_trace

    @classmethod
    def compute_crc(cls, data_bytes: bytes, standard: str = "CRC-16-CCITT") -> Tuple[int, str, List[Dict]]:
        """
        Computes CRC Frame Check Sequence (FCS).
        Appends n zero bits to data and calculates remainder.
        """
        spec = cls.POLYNOMIALS[standard]
        width = spec["width"]
        poly_bits = spec["poly_binary"]

        data_bits = cls.bytes_to_bits(data_bytes)
        # Append width zeros
        padded_bits = data_bits + ("0" * width)

        _, remainder_bits, steps = cls.modulo2_division(padded_bits, poly_bits)
        crc_int = int(remainder_bits, 2)
        return crc_int, remainder_bits, steps

    @classmethod
    def verify_frame(cls, received_bits: str, standard: str = "CRC-16-CCITT") -> Tuple[bool, str]:
        """
        Verifies received frame (data_bits + CRC remainder).
        Returns (is_valid, syndrome_remainder).
        If valid, syndrome must be all zeros.
        """
        spec = cls.POLYNOMIALS[standard]
        poly_bits = spec["poly_binary"]

        _, syndrome, _ = cls.modulo2_division(received_bits, poly_bits)
        is_valid = int(syndrome, 2) == 0
        return is_valid, syndrome


class V2VFrame:
    """Models a complete V2V Safety Packet with Header, Telemetry Payload, and CRC."""

    def __init__(self, msg_type: str, sender_id: str, target_id: str, seq_num: int, payload: Dict):
        self.msg_type = msg_type  # e.g., "EMERGENCY_BRAKE_ALERT", "COLLISION_WARNING", "CAM_TELEMETRY"
        self.sender_id = sender_id
        self.target_id = target_id
        self.seq_num = seq_num
        self.payload = payload

    def serialize_data(self) -> bytes:
        """Serializes frame header and payload into bytes."""
        header_str = f"HDR|TYPE:{self.msg_type}|SRC:{self.sender_id}|DST:{self.target_id}|SEQ:{self.seq_num}|"
        payload_str = json.dumps(self.payload, separators=(',', ':'))
        return (header_str + payload_str).encode('utf-8')

    def construct_frame(self, crc_standard: str = "CRC-16-CCITT") -> Dict:
        """Builds transmitted frame with CRC appended."""
        data_bytes = self.serialize_data()
        data_bits = CRC.bytes_to_bits(data_bytes)
        crc_int, crc_bits, steps = CRC.compute_crc(data_bytes, standard=crc_standard)

        transmitted_frame_bits = data_bits + crc_bits
        return {
            "data_bytes": data_bytes,
            "data_bits": data_bits,
            "crc_hex": hex(crc_int),
            "crc_bits": crc_bits,
            "transmitted_bits": transmitted_frame_bits,
            "total_bits": len(transmitted_frame_bits),
            "steps": steps
        }


class VehicularChannelNoiseSimulator:
    """Simulates wireless interference and injects noise patterns into V2V frames."""

    @staticmethod
    def inject_single_bit_error(frame_bits: str) -> Tuple[str, int]:
        """Inverts a single random bit."""
        pos = random.randint(0, len(frame_bits) - 1)
        flipped = '0' if frame_bits[pos] == '1' else '1'
        corrupted = frame_bits[:pos] + flipped + frame_bits[pos + 1:]
        return corrupted, pos

    @staticmethod
    def inject_burst_error(frame_bits: str, burst_length: int = 8) -> Tuple[str, int, int]:
        """Inverts a consecutive sequence of bits of given burst length."""
        start_pos = random.randint(0, max(0, len(frame_bits) - burst_length))
        bit_list = list(frame_bits)
        for i in range(start_pos, min(start_pos + burst_length, len(frame_bits))):
            bit_list[i] = '0' if bit_list[i] == '1' else '1'
        return "".join(bit_list), start_pos, burst_length


def run_crc_benchmarks():
    """Runs rigorous statistical benchmark of CRC detection under vehicular channel noise."""
    os.makedirs("results/csv", exist_ok=True)
    random.seed(42)

    # Sample V2V Emergency Brake Safety Packet
    safety_frame = V2VFrame(
        msg_type="EMERGENCY_BRAKE_ALERT",
        sender_id="V0-LeadVehicle",
        target_id="V5-TailVehicle",
        seq_num=101,
        payload={
            "timestamp_ms": 1500.25,
            "vehicle_speed_kmh": 85.4,
            "deceleration_mps2": 7.8,
            "hazard_type": "STATIONARY_OBSTACLE",
            "gps_lat": 12.9716,
            "gps_lon": 77.5946
        }
    )

    frame_info = safety_frame.construct_frame(crc_standard="CRC-16-CCITT")
    orig_bits = frame_info["transmitted_bits"]

    # 1. Verify clean frame
    is_clean_valid, syndrome_clean = CRC.verify_frame(orig_bits, "CRC-16-CCITT")
    assert is_clean_valid, "Clean frame must pass CRC verification with syndrome=0."

    # 2. Monte-Carlo Noise Tests
    test_categories = [
        {"name": "Single Bit Flip Errors", "trials": 1000, "type": "single"},
        {"name": "Two Isolated Bit Errors", "trials": 1000, "type": "double"},
        {"name": "Burst Errors (Length <= 8 bits)", "trials": 1000, "type": "burst_8"},
        {"name": "Burst Errors (Length 16 bits)", "trials": 1000, "type": "burst_16"},
        {"name": "Burst Errors (Length 24 bits)", "trials": 1000, "type": "burst_24"},
    ]

    results = []
    print("\n==========================================================================================")
    print("                     CRC ERROR DETECTION PERFORMANCE BENCHMARK")
    print("==========================================================================================")
    print(f"Original V2V Safety Packet Size: {len(frame_info['data_bytes'])} bytes ({len(orig_bits)} bits)")
    print(f"Calculated CRC-16 FCS: {frame_info['crc_hex']} (Binary: {frame_info['crc_bits']})")
    print(f"Clean Transmission Syndrome: {syndrome_clean} (Frame Accepted: {is_clean_valid})")
    print("-" * 100)
    print(f"{'Error Noise Category':<35} | {'Trials':<8} | {'Detected':<10} | {'Missed':<8} | {'Detection Rate (%)'}")
    print("-" * 100)

    for cat in test_categories:
        detected = 0
        missed = 0
        for _ in range(cat["trials"]):
            if cat["type"] == "single":
                corrupted_bits, _ = VehicularChannelNoiseSimulator.inject_single_bit_error(orig_bits)
            elif cat["type"] == "double":
                c1, _ = VehicularChannelNoiseSimulator.inject_single_bit_error(orig_bits)
                corrupted_bits, _ = VehicularChannelNoiseSimulator.inject_single_bit_error(c1)
            elif cat["type"] == "burst_8":
                corrupted_bits, _, _ = VehicularChannelNoiseSimulator.inject_burst_error(orig_bits, 8)
            elif cat["type"] == "burst_16":
                corrupted_bits, _, _ = VehicularChannelNoiseSimulator.inject_burst_error(orig_bits, 16)
            elif cat["type"] == "burst_24":
                corrupted_bits, _, _ = VehicularChannelNoiseSimulator.inject_burst_error(orig_bits, 24)

            valid, _ = CRC.verify_frame(corrupted_bits, "CRC-16-CCITT")
            if not valid:
                detected += 1
            else:
                missed += 1

        det_rate = (detected / cat["trials"]) * 100.0
        results.append({
            "Error_Category": cat["name"],
            "Trials": cat["trials"],
            "Detected_Errors": detected,
            "Missed_Errors": missed,
            "Detection_Rate_Pct": f"{det_rate:.2f}%"
        })
        print(f"{cat['name']:<35} | {cat['trials']:<8} | {detected:<10} | {missed:<8} | {det_rate:.2f}%")

    print("-" * 100)

    # Save to CSV
    csv_path = "results/csv/crc_validation.csv"
    with open(csv_path, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=["Error_Category", "Trials", "Detected_Errors", "Missed_Errors", "Detection_Rate_Pct"])
        writer.writeheader()
        writer.writerows(results)

    print(f"[OK] CRC benchmark results saved to {csv_path}\n")


if __name__ == "__main__":
    run_crc_benchmarks()
