"""Identify each physical motor channel at 60 RPM, with bounded pulses and STOP."""
from pathlib import Path
from datetime import datetime
import sys, json, time, struct, argparse

root = Path(__file__).resolve().parent
sys.path.insert(0, str(root / 'vendor'))
import serial
import serial.tools.list_ports
import sdk_original as sdk

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--run', action='store_true')
parser.add_argument('--wheels-raised', action='store_true')
parser.add_argument('--supply-on', action='store_true')
parser.add_argument('--long-sequence', action='store_true', help='Each motor both directions 3 s, axle pairs 4 s, all four both directions 6 s')
args = parser.parse_args()
if args.run and not (args.wheels_raised and args.supply_on):
    parser.error('Raised wheels and motor supply ON required')

def frame(speeds):
    body = bytes([3, 22, 1, 4]) + b''.join(struct.pack('<Bf', i, v) for i, v in enumerate(speeds))
    return b'\xaa\x55' + body + bytes([sdk.checksum_crc8(body)])

stop_frame = frame([0, 0, 0, 0])
patterns = []
for motor in range(4):
    directions = [1, -1] if args.long_sequence else [1]
    for direction in directions:
        speeds = [0, 0, 0, 0]
        speeds[motor] = direction * (1.0 if motor < 2 else -1.0)
        label = f'MOTOR_ID_{motor + 1}_ONLY_{"FORWARD" if direction == 1 else "BACKWARD"}_60RPM'
        patterns.append((label, frame(speeds), 3 if args.long_sequence else 2))
if args.long_sequence:
    # Positions follow the forward-arrow diagram in the supplied mecanum.py.
    patterns += [('FRONT_PAIR_IDS_1_3_60RPM', frame([1, 0, -1, 0]), 4),
                 ('REAR_PAIR_IDS_2_4_60RPM', frame([0, 1, 0, -1]), 4),
                 ('ALL_FOUR_FORWARD_60RPM', frame([1, 1, -1, -1]), 6),
                 ('ALL_FOUR_BACKWARD_60RPM', frame([-1, -1, 1, 1]), 6)]
else:
    patterns.append(('ALL_FOUR_FORWARD_60RPM', frame([1, 1, -1, -1]), 2))
for label, packet, duration in patterns:
    assert len(packet) == 27 and sdk.checksum_crc8(packet[2:-1]) == packet[-1]
    print(label, f'{duration} s', packet.hex(' ').upper(), flush=True)
if not args.run:
    raise SystemExit(0)

port = next((p for p in serial.tools.list_ports.comports() if p.device.upper() == 'COM9'), None)
if not port or (port.vid, port.pid, port.serial_number) != (0x1a86, 0x55d4, '5917012181'):
    raise SystemExit('Expected COM9 bridge not present. No command sent.')
connection = serial.Serial(None, 1000000, timeout=0.02, write_timeout=0.2)
connection.port = port.device
connection.rts = False
connection.dtr = False
events = []
raw = bytearray()
started = time.monotonic()
final_stop = False

def transmit(packet, label):
    count = connection.write(packet)
    connection.flush()
    assert count == len(packet)
    events.append({'elapsed_s': round(time.monotonic() - started, 4), 'label': label,
                   'hex': packet.hex(' ').upper(), 'bytes': count,
                   'queue_after_flush': connection.out_waiting})

def stop():
    for _ in range(3):
        transmit(stop_frame, 'STOP')
        time.sleep(0.03)

try:
    connection.open()
    print('IDENTIFIED', port.device, port.hwid, flush=True)
    stop()
    time.sleep(0.5)
    for label, packet, duration in patterns:
        print('NOW:', label, f'| {duration} seconds, then STOP |', packet.hex(' ').upper(), flush=True)
        end = time.monotonic() + duration
        next_send = time.monotonic()
        try:
            while time.monotonic() < end:
                if time.monotonic() >= next_send:
                    transmit(packet, label)
                    next_send = time.monotonic() + 0.05
                raw.extend(connection.read(max(1, connection.in_waiting)))
        finally:
            stop()
            print('STOP', flush=True)
        time.sleep(0.8)
finally:
    try:
        if connection.is_open:
            stop()
            final_stop = True
    finally:
        connection.close()
    stamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    result = {'source': 'Python diagnostic derived from validated SDK packet format',
              'port': port.device, 'hwid': port.hwid, 'baud': 1000000,
              'events': events, 'final_stop_sent': final_stop,
              'physical_result': 'awaiting per-channel observation', 'max_rpm': 60,
              'sequence': [{'label': label, 'duration_s': duration} for label, packet, duration in patterns]}
    suffix = 'wheel_long_sequence' if args.long_sequence else 'wheel_channels'
    (root / 'logs' / f'{stamp}_{suffix}.json').write_text(json.dumps(result, indent=2), encoding='utf-8')
    (root / 'logs' / f'{stamp}_{suffix}_rx.raw').write_bytes(raw)
    print('Final STOP sent:', final_stop, '| saved', stamp + '_' + suffix + '.json', flush=True)
