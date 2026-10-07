"""HPS Linux USB transport bring-up. Default only lists ports, no motor motion."""
import argparse
import sys
from pathlib import Path
import json
import time
root = Path(__file__).resolve().parent
sys.path.insert(0, str(root/'vendor'))
import serial
from serial.tools import list_ports
from ros_robot_controller_sdk_reference import Board
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--port')
parser.add_argument('--buzzer', action='store_true')
parser.add_argument('--listen-seconds', type=float, default=2.0)
args = parser.parse_args()
if not 0 < args.listen_seconds <= 10:
    parser.error('listen-seconds must be >0 and <=10')
ports = [{'device':p.device,'description':p.description,'vid':p.vid,'pid':p.pid,'serial_number':p.serial_number} for p in list_ports.comports()]
print(json.dumps(ports,indent=2))
if not args.port:
    print('No port opened. Specify the verified STM USB serial device with --port.')
    sys.exit(0)
from jetauto_laptop_test import Decoder
port = serial.Serial(None, baudrate=1000000, timeout=0.05, write_timeout=0.2)
port.rts=False
port.dtr=False
port.port=args.port
port.open()
try:
    decoder=Decoder()
    deadline=time.monotonic()+args.listen_seconds
    count=0
    while time.monotonic()<deadline:
        count+=len(decoder.feed(port.read(min(4096,max(1,port.in_waiting)))))
    print('CRC-valid RRC packets:',count)
    if args.buzzer:
        if not count:
            raise RuntimeError('No valid RRC RX. Buzzer cancelled. Verify STM port and firmware.')
        class CheckedPort:
            def write(self,data):
                count=port.write(data)
                if count!=len(data): raise RuntimeError('Partial command write')
                print('SDK TX:',bytes(data).hex(' ').upper())
                return count
        board=Board.__new__(Board)
        board.port=CheckedPort()
        board.set_buzzer(1900,0.1,0.9,1)
        time.sleep(0.2)
        print('Buzzer command sent. Confirm sound physically. No motor command sent.')
finally:
    port.close()
