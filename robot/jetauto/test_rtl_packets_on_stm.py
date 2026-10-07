"""Send motor frames decoded from Verilog simulation, not freshly built Python packets."""
from pathlib import Path
from datetime import datetime
import sys,json,time,struct,argparse
r=Path(__file__).resolve().parent;sys.path.insert(0,str(r/'vendor'))
import serial,serial.tools.list_ports
import sdk_original as sdk
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--run',action='store_true');p.add_argument('--wheels-raised',action='store_true');p.add_argument('--supply-on',action='store_true')
a=p.parse_args()
if a.run and not(a.wheels_raised and a.supply_on):p.error('Raised wheels and supply ON required')
frames={}
for line in (r/'FPGA_UART_TTL_MULTISPEED/tb/rtl_captured_packets.hex').read_text().splitlines():
 fields=line.split();command,level=map(int,fields[:2]);f=bytes(int(x,16) for x in fields[2:])
 assert f[:2]==b'\xaa\x55' and len(f)==f[3]+5 and sdk.checksum_crc8(f[2:-1])==f[-1]
 if command!=1:
  assert f[2:6]==bytes([3,22,1,4])
  for i in range(4):
   ident,value=struct.unpack('<Bf',f[6+5*i:11+5*i]);assert ident==i
   target=0 if command==0 else [0.25,0.5,1.,1.5][level]*(1 if (i<2)^(command==3) else -1)
   assert value==target
 frames[command,level]=f
assert len(frames)==10
print('PASS: RTL-captured frames independently verified with SDK CRC and float decoder',flush=True)
if not a.run:raise SystemExit(0)
port=next((x for x in serial.tools.list_ports.comports() if x.device.upper()=='COM9'),None)
if not port or (port.vid,port.pid,port.serial_number)!=(0x1a86,0x55d4,'5917012181'):raise SystemExit('Expected COM9 bridge not present. No command sent.')
s=serial.Serial(None,1000000,timeout=0.03,write_timeout=0.2);s.port=port.device;s.rts=False;s.dtr=False
events=[];raw=bytearray();began=time.monotonic()
def tx(f,label):
 count=s.write(f);s.flush();assert count==len(f)
 e={'elapsed_s':round(time.monotonic()-began,4),'label':label,'hex':f.hex(' ').upper(),'bytes':count,'queue_after_flush':s.out_waiting};events.append(e)
def stop():
 for _ in range(3):tx(frames[0,0],'STOP');time.sleep(0.03)
try:
 s.open();print('IDENTIFIED',port.device,port.hwid,flush=True)
 stop();tx(frames[1,0],'BUZZER');time.sleep(0.5)
 segments=[(2,i) for i in range(4)]+[(3,3)]
 for command,level in segments:
  rpm=[15,30,60,90][level];label=f'{"FORWARD" if command==2 else "BACKWARD"}_{rpm}RPM'
  f=frames[command,level];print(label,'1 second |',f.hex(' ').upper(),flush=True)
  end=time.monotonic()+1;next_tx=time.monotonic()
  try:
   while time.monotonic()<end:
    if time.monotonic()>=next_tx:tx(f,label);next_tx=time.monotonic()+0.05
    raw.extend(s.read(max(1,s.in_waiting)))
  finally:stop()
  time.sleep(0.7)
finally:
 try:
  if s.is_open:stop()
 finally:s.close()
 stamp=datetime.now().strftime('%Y%m%d_%H%M%S')
 result={'source':'Verilog testbench serial capture','port':port.device,'hwid':port.hwid,'baud':1000000,'events':events,'physical_result':'awaiting observation of every wheel','max_rpm':90}
 (r/'logs'/f'{stamp}_rtl_four_speed.json').write_text(json.dumps(result,indent=2))
 (r/'logs'/f'{stamp}_rtl_four_speed_rx.raw').write_bytes(raw)
 print('Final STOP sent, saved',stamp+'_rtl_four_speed.json',flush=True)
