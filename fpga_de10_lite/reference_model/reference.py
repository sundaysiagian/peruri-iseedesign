"""Independent scalar integer oracle. No RTL execution; no FPGA speed claim."""
import math,time,json,csv,argparse
from pathlib import Path
LUT=[round(16384*math.sin(2*math.pi*i/256)) for i in range(256)]
def map_cell(s,x,y):
 if s==0:return 0
 if s==1:return 254
 if s==2:return 255
 if s==3:return (x*3+y*5)%96
 if s==4:return 254 if x>67 and y!=64 else 0
 if s==5:return 254 if ((x*73+y*137+19)%101)<18 and (x,y)!=(64,64) else 0
 return 0
def candidate(i,s,horizon=20,nv=16,nw=32,previous_v=0,previous_w=0,max_v=15,max_w=16,max_dv=15,max_dw=16):
 vi,wi=divmod(i,nw)
 v=round(15*vi/max(1,nv-1));w=round(31*wi/max(1,nw-1))-16
 x=y=16384;heading=0;cost=0
 valid=v<=max_v and abs(w)<=max_w and abs(v-previous_v)<=max_dv and abs(w-previous_w)<=max_dw
 for _ in range(horizon):
  x+=(v*16*LUT[(heading+64)&255])>>14
  y+=(v*16*LUT[heading])>>14
  heading=(heading+w)&255
  valid=valid and 0<=x<32768 and 0<=y<32768
  c=map_cell(s,(x>>8)&127,(y>>8)&127); cost+=c
  valid=valid and c<254
 goal=abs(x-24576)+abs(y-16384);velocity=(15-v)*256
 score=16*cost+goal+velocity
 return dict(index=i,v=v,w=w,cost=cost,goal=goal,velocity=velocity,score=score,valid=int(valid))
def run(s,horizon=20,nv=16,nw=32):
 candidates=[candidate(i,s,horizon,nv,nw) for i in range(nv*nw)]
 legal=[c for c in candidates if c['valid']]
 best=min(legal,key=lambda c:(c['score'],c['index'])) if legal else dict(index=0,v=0,w=0,cost=0,goal=0,velocity=0,score=0,valid=0)
 return candidates,best
def generate(root):
 out=root/'tb/test_vectors';out.mkdir(exist_ok=True,parents=True)
 expected=[]
 for s in range(6):
  cc,best=run(s);expected.append(best)
  (out/f'map_{s}.hex').write_text(''.join(f'{map_cell(s,x,y):02x}\n' for y in range(128) for x in range(128)))
  # memory word: valid1, score32, cost32, goal32, velocity32
  (out/f'expected_{s}.hex').write_text(''.join(f"{(c['valid']<<128)|(c['score']<<96)|(c['cost']<<64)|(c['goal']<<32)|c['velocity']:033x}\n" for c in cc))
 (out/'best.json').write_text(json.dumps(expected,indent=2))
 return expected
def sweep(root,repeats):
 rows=[]
 for nv,nw in [(8,16),(16,32),(20,20)]:
  for h in [10,20,40]:
   for s in range(6):
    samples=[]
    for _ in range(repeats):
     t=time.perf_counter_ns();cc,b=run(s,h,nv,nw);samples.append((time.perf_counter_ns()-t)/1e6)
    samples.sort()
    rows.append(dict(nv=nv,nw=nw,horizon=h,scenario=s,n=repeats,min_ms=samples[0],mean_ms=sum(samples)/len(samples),p50_ms=samples[int(.5*(len(samples)-1))],p95_ms=samples[int(.95*(len(samples)-1))],p99_ms=samples[int(.99*(len(samples)-1))],max_ms=samples[-1],deadline_miss=sum(v>=20 for v in samples),scope='Python oracle only; not optimized CPU/Nav2 or FPGA end-to-end'))
 with (root/'evidence/cpu_oracle_sweep.csv').open('w',newline='') as f:
  w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--sweep',action='store_true');p.add_argument('--repeats',type=int,default=10);a=p.parse_args()
 root=Path(__file__).resolve().parents[1];generate(root)
 if a.sweep:sweep(root,a.repeats)
