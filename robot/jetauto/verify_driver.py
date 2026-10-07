"""Independent offline frame checks against SDK, no serial device is opened."""
import json,math,struct,sys,types,importlib.util
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
module=types.ModuleType('ros_robot_controller.msg')
module.MotorState=type('MotorState',(),{})
sys.modules['ros_robot_controller']=types.ModuleType('ros_robot_controller')
sys.modules['ros_robot_controller.msg']=module
p=next((r/'original').rglob('mecanum.py'))
spec=importlib.util.spec_from_file_location('mecanum',p);m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
chassis=m.MecanumChassis(wheelbase=0.216,track_width=0.195,wheel_diameter=0.097)
got=chassis.set_velocity(0.1,math.pi/2,0)
expected=[0.1/(math.pi*0.097)]*2+[-0.1/(math.pi*0.097)]*2
assert all(x.id==i+1 and abs(x.rps-v)<1e-10 for i,(x,v) in enumerate(zip(got,expected)))
result={'status':'PASS','crc_table_entries':256,'motor_frames':7,'forward_mecanum_ids':[x.id for x in got],'forward_mecanum_rps':[x.rps for x in got],'serial_opened':False,'frames':[x.hex(' ').upper() for x in b.port.frames]}
(r/'offline_verification.json').write_text(json.dumps(result,indent=2));print(json.dumps(result,indent=2))
