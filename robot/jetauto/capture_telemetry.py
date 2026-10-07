"""Receive only, verify CRC and retain exact SYS frames. Sends no motor commands."""
from pathlib import Path
from datetime import datetime
from collections import Counter
import sys,time,json,struct
r=Path(__file__).resolve().parent;sys.path.insert(0,str(r/'vendor'))
import serial
import sdk_original as sdk
s=serial.Serial(None,1000000,timeout=0.05,write_timeout=0.2)
s.rts=False;s.dtr=False;s.port='COM9';raw=bytearray()
try:
 s.open();end=time.monotonic()+4
 while time.monotonic()<end:raw.extend(s.read(max(1,s.in_waiting)))
finally:s.close()
i=0;frames=[];bad=0
while i+5<=len(raw):
 if raw[i:i+2]!=b'\xaa\x55':i+=1;continue
 n=raw[i+3];end=i+5+n
 if end>len(raw):break
 packet=raw[i:end]
 if sdk.checksum_crc8(packet[2:-1])!=packet[-1]:bad+=1;i+=1;continue
 frames.append(packet);i=end
system=[{'hex':f.hex(' ').upper(),'payload_hex':f[4:-1].hex(' ').upper(),'battery_raw':struct.unpack('<H',f[5:7])[0] if f[3]==3 and f[4]==4 else None} for f in frames if f[2]==0]
stamp=datetime.now().strftime('%Y%m%d_%H%M%S')
(r/'logs'/f'{stamp}_rx.raw').write_bytes(raw)
result={'port':'COM9','baud':1000000,'bytes_received':len(raw),'valid_frames':len(frames),'invalid_crc_candidates':bad,'function_counts':dict(Counter(f[2] for f in frames)),'system_frames':system,'commands_sent':0}
(r/'logs'/f'{stamp}_rx.json').write_text(json.dumps(result,indent=2))
print(json.dumps(result,indent=2))
