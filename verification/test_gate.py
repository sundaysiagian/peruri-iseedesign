import json,random
from pathlib import Path
import cocotb
from cocotb.triggers import Timer

CONTROL=['rst_n','ready','estop','protective_stop','map_ok','cfg_ok','result_valid','all_done','arithmetic_fault','timeout']
FIELDS=['candidate_v','previous_v','max_v','max_dv','candidate_w','previous_w','max_w','max_dw']
def oracle(x):
    conditions=[not x['rst_n'],x['estop'],x['protective_stop'],not x['ready'],not x['map_ok'],not x['cfg_ok'],x['arithmetic_fault'],x['timeout'],not x['all_done'] or not x['result_valid'],x['candidate_v']>x['max_v'] or abs(x['candidate_w'])>x['max_w'],abs(x['candidate_v']-x['previous_v'])>x['max_dv'] or abs(x['candidate_w']-x['previous_w'])>x['max_dw']]
    return next((i+1 for i,v in enumerate(conditions) if v),0)
@cocotb.test()
async def gate_truth_table_and_boundaries(dut):
    counts={str(i):0 for i in range(12)}
    baseline=dict(zip(CONTROL,[1,1,0,0,1,1,1,1,0,0]))
    baseline.update(candidate_v=3,previous_v=3,max_v=15,max_dv=15,candidate_w=0,previous_w=0,max_w=63,max_dw=127)
    rng=random.Random(16523109)
    cases=[]
    for bits in range(1024):
        x=baseline.copy();x.update({name:(bits>>i)&1 for i,name in enumerate(CONTROL)});cases.append(x)
    for v in [0,15,31]:
        for w in [-64,-63,-1,0,1,63]:
            for prev in [-64,0,63]:
                x=baseline.copy();x.update(candidate_v=v,candidate_w=w,previous_w=prev,max_dv=0,max_dw=0);cases.append(x)
    for _ in range(12000):
        x=baseline.copy()
        if rng.random()<0.4:x.update({name:rng.randrange(2) for name in CONTROL})
        for name in FIELDS:x[name]=rng.randrange(-64,64) if name in ['candidate_w','previous_w'] else rng.randrange(128 if name in ['max_w','max_dw'] else 32)
        cases.append(x)
    for x in cases:
        for name,value in x.items(): getattr(dut,name).value=value & ((1<<len(getattr(dut,name)))-1)
        await Timer(1,units='ns')
        expected=oracle(x);counts[str(expected)]+=1
        assert int(dut.fault_code.value)==expected,x
        assert int(dut.motor_enable.value)==(expected==0),x
        assert int(dut.v_command.value)==(x['candidate_v'] if expected==0 else 0),x
        assert dut.omega_command.value.signed_integer==(x['candidate_w'] if expected==0 else 0),x
    assert all(counts.values()),counts
    Path('gate_functional_coverage.json').write_text(json.dumps({'seed':16523109,'cases':len(cases),'fault_bins':counts,'covered_bins':12,'total_bins':12,'kind':'functional outcome bins, not RTL line/toggle coverage'},indent=2))
