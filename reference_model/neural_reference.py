from pathlib import Path
import math,json
ROOT=Path(__file__).resolve().parents[1]
ASSETS=ROOT/'assets/neural_24_64_64_4'
def read_mem(name):
 return [int(v,16)-(65536 if int(v,16)&32768 else 0) for v in (ASSETS/name).read_text().splitlines() if v and not v.startswith('//')]
W=[read_mem(f'bram_w{i}.mem') for i in range(1,4)]
B=[read_mem(f'bram_b{i}.mem') for i in range(1,4)]
def infer(a):
 fault=False
 for layer,(ni,no) in enumerate([(24,64),(64,64),(64,4)]):
  out=[]
  for j in range(no):
   acc=B[layer][j]*256+sum(a[k]*W[layer][j*ni+k] for k in range(ni))
   x=acc//256
   if layer<2:
    fault=fault or x>32767;out.append(max(0,min(32767,x)))
   else:
    out.append(max(-256,min(256,x)))
  a=out
 return a,fault
if __name__=='__main__':
 ins=read_mem('test_inputs.mem');external=read_mem('test_outputs.mem');gold=[];faults=0
 for i in range(100):
  out,f=infer(ins[i*24:i*24+24]);gold.extend(out);faults+=f
 (ROOT/'tb/test_vectors/neural_expected.hex').write_text(''.join(f'{v&65535:04x}\n' for v in gold))
 errors=[abs(a-b) for a,b in zip(gold,external)]
 result=dict(vectors=100,outputs=400,saturating_vectors=faults,external_exact=sum(v==0 for v in errors),external_max_abs_lsb=max(errors),external_mean_abs_lsb=sum(errors)/len(errors),status='PASS' if not any(errors) else 'FAIL',contract='Output-major weights; Q8.8 floor; hidden ReLU; output hard clip [-256,256]. Agreement verified on supplied vectors, not a proof for unseen inputs.')
 (ROOT/'evidence/neural_export_comparison.json').write_text(json.dumps(result,indent=2));print(result)
