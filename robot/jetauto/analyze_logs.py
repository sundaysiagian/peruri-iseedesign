"""Verify emitted host frames and independent raw receive capture."""
from pathlib import Path
from collections import Counter
import json,struct
r=Path(__file__).resolve().parent
def crc(data):
 c=0
 for x in data:
  c^=x
  for _ in range(8):c=(c>>1)^0x8c if c&1 else c>>1
 return c
tx=[]
for p in (r/'logs').glob('*.json'):
 d=json.loads(p.read_text())
 for e in d.get('events',[]):
  if e.get('kind')=='tx' or 'queued_after_flush' in e or 'queue_after_flush' in e:
   f=bytes.fromhex(e['hex'])
   assert f[:2]==b'\xaa\x55' and len(f)==f[3]+5 and crc(f[2:-1])==f[-1],p.name
   if f[2]==3:
    assert f[4]==1 and f[3]==2+5*f[5]
    speeds=[struct.unpack('<Bf',f[i:i+5]) for i in range(6,len(f)-1,5)]
    assert all(0<=i<4 and abs(v)<=1.5 for i,v in speeds)
   tx.append(f)
rx=[];bad=0
for p in (r/'logs').glob('*.raw'):
 b=p.read_bytes();i=0
 while i+5<=len(b):
  if b[i:i+2]!=b'\xaa\x55':i+=1;continue
  end=i+5+b[i+3]
  if end>len(b):break
  f=b[i:end]
  if crc(f[2:-1])!=f[-1]:bad+=1;i+=1;continue
  rx.append(f);i=end
result={'host_frames_checked':len(tx),'host_frame_validation':'PASS','receive_valid_frames':len(rx),'receive_invalid_crc_candidates':bad,'receive_function_counts':dict(Counter(f[2] for f in rx)),'motor_function_rx_frames':sum(f[2]==3 for f in rx),'interpretation':'Host writes and valid framing verified. Physical outcomes must be read per run, including the partial four-speed result. No motor ACK or encoder feedback is defined in this SDK.'}
(r/'log_analysis.json').write_text(json.dumps(result,indent=2));print(json.dumps(result,indent=2))
