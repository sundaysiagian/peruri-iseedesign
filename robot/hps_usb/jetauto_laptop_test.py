"""Bounded JetAuto wheel test. Default dry run never opens a serial port."""
import argparse
import json
import math
import struct
import time
import sys
from datetime import datetime
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent / 'vendor'))

def crc8(data):
    crc = 0
    for byte in data:
        crc ^= byte
        for _ in range(8):
            crc = (crc >> 1) ^ 0x8C if crc & 1 else crc >> 1
    return crc

def motor_frame(speeds):
    if len(speeds) != 4 or any(not math.isfinite(v) or abs(v) > 0.2 for v in speeds):
        raise ValueError('Require four finite wheel speeds within +/-0.2 rps')
    payload = bytes([1, 4]) + b''.join(struct.pack('<Bf', index, speed) for index, speed in enumerate(speeds))
    body = bytes([3, len(payload)]) + payload
    return b'\xAA\x55' + body + bytes([crc8(body)])

def direction_speeds(direction, rps):
    if direction == 'stop':
        return [0.0] * 4
    sign = 1 if direction == 'forward' else -1
    return [sign * rps, sign * rps, -sign * rps, -sign * rps]

class Decoder:
    def __init__(self):
        self.buffer = bytearray()

    def feed(self, data):
        self.buffer.extend(data)
        frames = []
        while True:
            start = self.buffer.find(b'\xAA\x55')
            if start < 0:
                self.buffer[:] = self.buffer[-1:] if self.buffer[-1:] == b'\xAA' else b''
                break
            del self.buffer[:start]
            if len(self.buffer) < 4:
                break
            size = self.buffer[3] + 5
            if len(self.buffer) < size:
                break
            packet = bytes(self.buffer[:size])
            if crc8(packet[2:-1]) != packet[-1]:
                del self.buffer[0]
                continue
            del self.buffer[:size]
            frames.append(packet)
        return frames

def read_frames(port, decoder, seconds):
    deadline = time.monotonic() + seconds
    frames = []
    while time.monotonic() < deadline:
        frames.extend(decoder.feed(port.read(min(4096, max(1, port.in_waiting)))))
    return frames

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--mode', choices=['dry-run', 'probe', 'interactive', 'pulse', 'stop'], default='dry-run')
    parser.add_argument('--port', default='COM9')
    parser.add_argument('--baud', type=int, default=1000000)
    parser.add_argument('--rps', type=float, default=0.1)
    parser.add_argument('--seconds', type=float, default=0.5)
    parser.add_argument('--direction', choices=['forward', 'backward'], default='forward')
    parser.add_argument('--wheels-raised', action='store_true', help='Confirm wheels are lifted for this test')
    args = parser.parse_args()
    if not math.isfinite(args.rps) or not 0 < args.rps <= 0.2:
        parser.error('rps must be >0 and <=0.2')
    if not math.isfinite(args.seconds) or not 0 < args.seconds <= 1.0:
        parser.error('seconds must be >0 and <=1.0')
    if args.mode == 'dry-run':
        for direction in ['stop', 'forward', 'backward']:
            speeds = direction_speeds(direction, args.rps)
            print(f'{direction:8s} rps={speeds} frame={motor_frame(speeds).hex(" ").upper()}')
        print('DRY RUN. No port opened, no bytes transmitted.')
        return
    if args.mode in ['interactive', 'pulse'] and not args.wheels_raised:
        parser.error('Lift wheels first and pass --wheels-raised')
    try:
        import serial
    except ImportError:
        parser.error('Install pyserial first: py -m pip install pyserial')

    logdir = Path(__file__).resolve().parent / 'logs'
    logdir.mkdir(exist_ok=True)
    logpath = logdir / (datetime.now().strftime('%Y%m%d_%H%M%S_%f') + '.jsonl')
    log = logpath.open('w', encoding='utf-8')
    port = serial.Serial(port=None, baudrate=args.baud, bytesize=8, parity='N', stopbits=1,
                         timeout=0.05, write_timeout=0.2, xonxoff=False, rtscts=False, dsrdtr=False)
    port.dtr = False
    port.rts = False
    port.port = args.port
    tx_mode = args.mode in ['interactive', 'pulse', 'stop']

    def record(kind, **fields):
        log.write(json.dumps({'monotonic_s': time.monotonic(), 'kind': kind, **fields}) + '\n')
        log.flush()

    def send(speeds, label):
        frame = motor_frame(speeds)
        sent = port.write(frame)
        if sent != len(frame):
            raise RuntimeError(f'Partial write: {sent}/{len(frame)}')
        record('tx', label=label, rps=speeds, hex=frame.hex(' ').upper())

    def stop():
        errors = []
        for _ in range(3):
            try:
                send([0.0] * 4, 'stop')
            except Exception as exc:
                errors.append(str(exc))
            time.sleep(0.05)
        if errors:
            print('STOP transmission error. Cut motor power if wheels still spin:', errors)
            record('stop_error', errors=errors)
        return not errors

    def pulse(direction):
        speeds = direction_speeds(direction, args.rps)
        print(f'{direction}: {args.rps} rps for {args.seconds} s, then STOP')
        deadline = time.monotonic() + args.seconds
        try:
            while time.monotonic() < deadline:
                send(speeds, direction)
                time.sleep(min(0.05, max(0, deadline - time.monotonic())))
        finally:
            stopped = stop()
        if not stopped:
            raise RuntimeError('Stop write failed. End test and check motor power.')

    try:
        port.open()
        record('open', port=args.port, baud=args.baud, sdk_equivalent='set_motor_speed', wheels_raised=args.wheels_raised)
        if args.mode == 'stop':
            if not stop():
                raise RuntimeError('Stop transmission failed')
            print('Zero speed sent to four motors. Physical stop must be observed.')
            return
        frames = read_frames(port, Decoder(), 1.5)
        for frame in frames:
            record('rx', function=frame[2], length=frame[3], hex=frame.hex(' ').upper())
        print(f'CRC-valid telemetry frames: {len(frames)}')
        for function in sorted(set(frame[2] for frame in frames)):
            matching = [frame for frame in frames if frame[2] == function]
            print(f'Function 0x{function:02X}: {len(matching)} packets')
            sample = matching[-1]
            if function == 7 and sample[3] == 24:
                print('IMU ax ay az gx gy gz:', struct.unpack('<6f', sample[4:-1]))
            if function == 8 and sample[3] == 7:
                print('Gamepad buttons hat lx ly rx ry:', struct.unpack('<HB4b', sample[4:-1]))
        if args.mode == 'probe':
            print('RX only, no command transmitted.')
            return
        if not frames:
            raise RuntimeError('No valid RRC telemetry. Motor test cancelled.')
        if not stop():
            raise RuntimeError('Initial stop transmission failed')
        if args.mode == 'pulse':
            pulse(args.direction)
        else:
            print('Raised-wheel test. F=forward pulse, B=backward pulse, X=stop, Q=quit.')
            print('Each movement ends automatically. Ctrl+C requests STOP. Verify physical direction first.')
            while True:
                command = input('F / B / X / Q > ').strip().lower()
                if command == 'q':
                    break
                if command in ['f', 'b']:
                    pulse('forward' if command == 'f' else 'backward')
                elif command == 'x':
                    if not stop():
                        raise RuntimeError('Stop transmission failed')
                else:
                    print('Unknown command, motors stay stopped.')
    except KeyboardInterrupt:
        print('Interrupted, requesting STOP.')
        record('interrupt')
    except Exception as exc:
        record('error', message=str(exc))
        raise
    finally:
        if port.is_open:
            if tx_mode:
                stop()
            port.close()
        log.close()
        print('Log:', logpath)

if __name__ == '__main__':
    main()
