"""Independent serial transport, no SDK class or ROS. Fixed 1 RPS, 2 seconds."""
import argparse,sys,time,struct,json
from pathlib import Path
from datetime import datetime
r=Path(__file__).resolve().parent;sys.path.insert(0,str(r/'vendor'))
import serial
import serial.tools.list_ports
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--run',action='store_true');p.add_argument('--wheels-raised',action='store_true');p.add_argument('--supply-on',action='store_true')
a=p.parse_args()
if a.run and not(a.wheels_raised and a.supply_on):p.error('Motion requires lifted wheels and supply confirmation')
def crc(data):
 c=0
 for v in data:
  c^=v
  for _ in range(8):c=(c>>1)^0x8c if c&1 else c>>1
 return c
def frame(func,data):
 body=bytes([func,len(data)])+data
 return b'\xaa\x55'+body+bytes([crc(body)])
def motor(values):return frame(3,bytes([1,4])+b''.join(struct.pack('<Bf',i,v) for i,v in enumerate(values)))
zero=motor([0.,0.,0.,0.]);forward=motor([1.,1.,-1.,-1.]);backward=motor([-1.,-1.,1.,1.])
assert zero.hex()=='aa5503160104000000000001000000000200000000030000000007'
port=next((x for x in serial.tools.list_ports.comports() if x.device.upper()=='COM9'),None)
if port is None:raise SystemExit('COM9 missing, nothing sent')
if (port.vid,port.pid)!=(0x1a86,0x55d4):raise SystemExit('COM9 is not the previously observed CH9102')
if port.serial_number!='5917012181':raise SystemExit('COM9 serial number differs from the tested STM bridge. Nothing sent.')
print('IDENTIFIED:',port.device,port.description,port.hwid,flush=True)
s=serial.Serial(None,1000000,timeout=0.03,write_timeout=0.2)
s.rts=False;s.dtr=False;s.port='COM9';raw=bytearray();events=[];start=time.monotonic()
def tx(packet,label):
 print(f'TX {label}: {packet.hex(" ").upper()} | CRC={packet[-1]:02X} | length={len(packet)}',flush=True)
 if packet[2]==3:
  entries=[struct.unpack('<Bf',packet[i:i+5]) for i in range(6,len(packet)-1,5)]
  print('   Motors:',', '.join(f'ID {i+1} = {v:+.3f} RPS' for i,v in entries),flush=True)
 n=s.write(packet);s.flush()
 if n!=len(packet):raise RuntimeError('Partial write')
 print(f'   WRITE={n}/{len(packet)} bytes, queued_after_flush={s.out_waiting}',flush=True)
 events.append({'elapsed_s':round(time.monotonic()-start,4),'label':label,'bytes':n,'hex':packet.hex(' ').upper(),'queued_after_flush':s.out_waiting})
def stop():
 for _ in range(3):tx(zero,'STOP');time.sleep(0.03)
try:
 s.open()
 print('OPEN COM9: 1000000 baud, 8 data bits, parity N, 1 stop bit, RTS=False, DTR=False',flush=True)
 end=time.monotonic()+1
 while time.monotonic()<end:raw.extend(s.read(max(1,s.in_waiting)))
 if a.run:
  stop()
  tx(frame(2,struct.pack('<HHHH',1900,100,900,1)),'BUZZER')
  time.sleep(0.5)
  for label,packet in [('FORWARD',forward),('BACKWARD',backward)]:
   end=time.monotonic()+2;next_tx=time.monotonic()
   try:
    while time.monotonic()<end:
     if time.monotonic()>=next_tx:tx(packet,label);next_tx=time.monotonic()+0.05
     raw.extend(s.read(max(1,s.in_waiting)))
   finally:stop()
   time.sleep(0.7)
finally:
 try:
  if a.run and s.is_open:stop()
 finally:s.close()
 stamp=datetime.now().strftime('%Y%m%d_%H%M%S')
 (r/'logs'/f'{stamp}_raw_direct_rx.raw').write_bytes(raw)
 result={'transport':'independent pyserial, no SDK Board or ROS','port':'COM9','description':port.description,'hwid':port.hwid,'usb_serial':port.serial_number,'baud':1000000,'rx_bytes':len(raw),'events':events,'physical_result':'requires user observation','motor_ack':'not defined by provided SDK'}
 (r/'logs'/f'{stamp}_raw_direct.json').write_text(json.dumps(result,indent=2))
 print('TX counts:',{k:sum(e['label']==k for e in events) for k in ['STOP','BUZZER','FORWARD','BACKWARD']})
 print('All queued_after_flush:',sorted({e['queued_after_flush'] for e in events}));print('RX bytes:',len(raw));print('Log:',stamp+'_raw_direct.json')
