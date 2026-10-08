"""Independent offline frame checks against SDK, no serial device is opened."""
import json,struct,sys
from pathlib import Path
r=Path(__file__).resolve().parent
sys.path.insert(0,str(r/'vendor'))
import sdk_original as sdk
class Port:
 def __init__(self):self.frames=[]
 def write(self,data):self.frames.append(bytes(data));return len(data)
def crc(data):
 c=0
 for x in data:
  c^=x
  for _ in range(8):c=(c>>1)^0x8c if c&1 else c>>1
 return c
assert all(sdk.crc8_table[i]==crc(bytes([i])) for i in range(256))
b=sdk.Board.__new__(sdk.Board);b.port=Port()
cases=[[0,0,0,0],[0.6,0.6,-0.6,-0.6],[-0.6,-0.6,0.6,0.6]]
for speeds in cases:
 b.set_motor_speed([[i+1,x] for i,x in enumerate(speeds)])
 frame=b.port.frames[-1]
 payload=bytes([1,4])+b''.join(struct.pack('<Bf',i,x) for i,x in enumerate(speeds))
 body=bytes([3,len(payload)])+payload
 assert frame==b'\xaa\x55'+body+bytes([crc(body)])
 assert len(frame)==27
for i in range(1,5):
 b.set_motor_speed([[i,0.6]])
 frame=b.port.frames[-1];assert frame[6]==i-1 and len(frame)==12
result={'status':'PASS','crc_table_entries':256,'motor_frames':7,'serial_opened':False,'frames':[x.hex(' ').upper() for x in b.port.frames]}
(r/'offline_verification.json').write_text(json.dumps(result,indent=2));print(json.dumps(result,indent=2))
