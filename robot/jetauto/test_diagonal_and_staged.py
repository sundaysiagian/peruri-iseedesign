"""Compare diagonal pairs, staggered starts, and optional one-ID packet refresh."""
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
parser.add_argument('--profile', choices=['diagonals', 'staged', 'diagonal-staged', 'round-robin', 'all'], default='diagonal-staged')
args = parser.parse_args()
if args.run and not (args.wheels_raised and args.supply_on):
    parser.error('Raised wheels and motor supply ON required')

def frame(values, ids=None):
    ids = list(range(4)) if ids is None else ids
    payload = bytes([1, len(ids)]) + b''.join(struct.pack('<Bf', i, values[i]) for i in ids)
    body = bytes([3, len(payload)]) + payload
    packet = b'\xaa\x55' + body + bytes([sdk.checksum_crc8(body)])
    assert len(packet) == packet[3] + 5
    return packet

zero = frame([0, 0, 0, 0])
plan = []
def stage(label, values, seconds, stop_after=True, one_id=False):
    packets = [frame(values, [i]) for i in range(4)] if one_id else [frame(values)]
    plan.append((label, values.copy(), seconds, stop_after, packets))

if args.profile in ['diagonals', 'diagonal-staged', 'all']:
    for label, pair in [('DIAGONAL_LF_RR_IDS_1_4', [0, 3]), ('DIAGONAL_RF_LR_IDS_3_2', [2, 1])]:
        for direction in [1, -1]:
            values = [0, 0, 0, 0]
            for i in pair:
                values[i] = direction * (1 if i < 2 else -1)
            stage(label + ('_FORWARD' if direction == 1 else '_BACKWARD') + '_60RPM', values, 4)
if args.profile in ['staged', 'diagonal-staged', 'all']:
    for direction in [1, -1]:
        word = 'FORWARD' if direction == 1 else 'BACKWARD'
        values = [0, 0, 0, 0]
        for i in [1, 3, 0, 2]:
            values[i] = direction * (0.25 if i < 2 else -0.25)
            stage(f'STAGGER_{word}_ADD_ID_{i+1}_15RPM', values, 2 if i == 2 else 0.75, False)
        stage(f'STAGGER_{word}_ALL_30RPM', [direction * x for x in [0.5, 0.5, -0.5, -0.5]], 2, False)
        stage(f'STAGGER_{word}_ALL_60RPM', [direction * x for x in [1, 1, -1, -1]], 6)
if args.profile in ['round-robin', 'all']:
    for direction in [1, -1]:
        stage('ONE_ID_PACKETS_ALL_' + ('FORWARD' if direction == 1 else 'BACKWARD') + '_60RPM',
              [direction * x for x in [1, 1, -1, -1]], 6, one_id=True)

if not args.run:
    for label, values, seconds, stop_after, packets in plan:
        print('PLAN:', label, f'| {seconds} s | RPS={values}', flush=True)
        for packet in packets:
            print('UART:', packet.hex(' ').upper(), flush=True)
    print('Validation only. No COM port opened.', flush=True)
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

def tx(packet, label):
    count = connection.write(packet)
    connection.flush()
    assert count == len(packet)
    events.append({'elapsed_s': round(time.monotonic() - started, 4), 'label': label,
                   'hex': packet.hex(' ').upper(), 'bytes': count,
                   'queue_after_flush': connection.out_waiting})

def stop():
    for _ in range(3):
        tx(zero, 'STOP')
        time.sleep(0.03)

try:
    connection.open()
    print('IDENTIFIED', port.device, port.hwid, flush=True)
    stop()
    time.sleep(0.5)
    for label, values, seconds, stop_after, packets in plan:
        print('NOW:', label, f'| {seconds} seconds | RPS={values}', flush=True)
        for packet in packets:
            print('UART:', packet.hex(' ').upper(), flush=True)
        end = time.monotonic() + seconds
        next_send = time.monotonic()
        while time.monotonic() < end:
            if time.monotonic() >= next_send:
                for packet in packets:
                    tx(packet, label)
                next_send = time.monotonic() + 0.05
            raw.extend(connection.read(max(1, connection.in_waiting)))
        if stop_after:
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
    result = {'source': 'SDK-format diagnostic packets, not physical FPGA', 'port': port.device,
              'hwid': port.hwid, 'baud': 1000000, 'events': events,
              'final_stop_sent': final_stop, 'profile': args.profile, 'max_rpm': 60,
              'physical_result': 'awaiting diagonal and staggered-start observations',
              'sequence': [{'label': label, 'rps': values, 'duration_s': seconds, 'stop_after': stop_after}
                           for label, values, seconds, stop_after, packets in plan]}
    (root / 'logs' / f'{stamp}_diagonal_staged.json').write_text(json.dumps(result, indent=2), encoding='utf-8')
    (root / 'logs' / f'{stamp}_diagonal_staged_rx.raw').write_bytes(raw)
    print('Final STOP sent:', final_stop, '| saved', stamp + '_diagonal_staged.json', flush=True)
