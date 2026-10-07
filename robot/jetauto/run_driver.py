"""Run supplied SDK without ROS. Default lists ports, motion requires explicit flags."""
import argparse,json,sys,time
from datetime import datetime
from pathlib import Path
r=Path(__file__).resolve().parent
sys.path.insert(0,str(r/'vendor'))
import serial.tools.list_ports
import sdk_original as sdk
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('action',choices=['ports','observe','buzzer','motion'],nargs='?',default='ports')
p.add_argument('--port',default='COM9')
p.add_argument('--wheels-raised',action='store_true')
p.add_argument('--supply-on',action='store_true')
p.add_argument('--rps',type=float,default=0.6)
p.add_argument('--duration',type=float,default=0.5)
p.add_argument('--single-entry',action='store_true',help='Use supported SDK one-motor packets, 12 bytes')
p.add_argument('--pattern',choices=['sequence','chassis'],default='sequence')
a=p.parse_args()
if a.action=='motion' and not(a.wheels_raised and a.supply_on):p.error('Motion requires --wheels-raised --supply-on')
if not(0<a.rps<=1.0 and 0<a.duration<=2.0):p.error('Limit is 1.0 rps and 2.0 seconds per segment')
if a.single_entry and a.pattern=='chassis':p.error('single-entry requires sequence pattern')
events=[];board=None
def record(kind,**fields):
 e={'elapsed_s':round(time.monotonic()-started,4),'kind':kind,**fields};events.append(e);print(json.dumps(e),flush=True)
def stop():
 for _ in range(3):
  if a.single_entry:
   for i in range(1,5):board.set_motor_speed([[i,0.]])
  board.set_motor_speed([[i,0.] for i in range(1,5)]);board.port.flush();time.sleep(0.03)
 record('stop_sent')
def observe(seconds):
 end=time.monotonic()+seconds
 while time.monotonic()<end:
  raw=board.get_battery()
  if raw is not None:record('battery',raw=raw,volts_if_mV=raw/1000)
  time.sleep(0.02)
started=time.monotonic()
try:
 ports=[{'port':x.device,'description':x.description,'hwid':x.hwid} for x in serial.tools.list_ports.comports()]
 record('ports',ports=ports)
 if a.action!='ports':
  if a.port.upper() not in {x['port'].upper() for x in ports}:raise RuntimeError(f'{a.port} not detected. No commands sent.')
  board=sdk.Board(device=a.port,baudrate=1000000,timeout=0.05)
  board.port.write_timeout=0.2
  original=board.port.write
  def logged_write(data):
   count=original(data)
   if count!=len(data):raise RuntimeError('Partial write')
   record('tx',hex=bytes(data).hex(' ').upper(),bytes=count);return count
  board.port.write=logged_write
  board.enable_reception(True);observe(3)
  if a.action in {'buzzer','motion'}:
   board.set_buzzer(1900,0.1,0.9,1);board.port.flush();record('buzzer_sent');time.sleep(0.5)
  if a.action=='motion':
   stop()
   segments=[(f'motor_{i}',[a.rps if j==i else 0. for j in range(1,5)]) for i in range(1,5)] if a.pattern=='sequence' else []
   if not a.single_entry:segments += [('forward',[a.rps,a.rps,-a.rps,-a.rps]),('backward',[-a.rps,-a.rps,a.rps,a.rps])]
   for label,values in segments:
    record('motion_segment',label=label,rps=values,duration_s=a.duration)
    end=time.monotonic()+a.duration
    try:
     while time.monotonic()<end:
      entries=[[i+1,x] for i,x in enumerate(values) if not a.single_entry or x!=0.]
      board.set_motor_speed(entries)
      board.port.flush();time.sleep(0.05)
    finally:stop()
    time.sleep(0.7)
   observe(1)
except KeyboardInterrupt:record('interrupted');raise SystemExit(130)
except Exception as e:record('error',message=str(e));raise
finally:
 if board is not None:
  try:
   if a.action=='motion':stop()
  finally:board.enable_reception(False);board.port.close()
 (r/'logs').mkdir(exist_ok=True)
 path=r/'logs'/(datetime.now().strftime('%Y%m%d_%H%M%S')+'_'+a.action+'.json')
 path.write_text(json.dumps({'events':events,'physical_result':'requires observation','motor_ack':'SDK has no motor acknowledgement'},indent=2))
 print('Log:',path)
