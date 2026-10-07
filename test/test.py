import json,random
from pathlib import Path
import cocotb
from cocotb.triggers import Timer

async def cycle(dut):
    dut.clk.value=0;await Timer(10,units='ns')
    dut.clk.value=1;await Timer(10,units='ns')
async def write(dut,address,value):
    dut.ui_in.value=(address<<1)|1;dut.uio_in.value=value&255
    await cycle(dut);dut.ui_in.value=0
async def read(dut,select):
    dut.ui_in.value=select<<5;await Timer(1,units='ns')
    return int(dut.uo_out.value)
def expected(reg,ena=1):
    flags=reg[0];v=reg[2]&31;prev=reg[3]&31
    signed=lambda x: (x&127)-128 if x&64 else x&127
    w=signed(reg[6]);pw=signed(reg[7])
    conditions=[False,bool(flags&2),bool(flags&4),not(flags&1 and ena),not(flags&8),not(flags&16),bool(flags&128),bool(reg[1]&1),not(flags&64) or not(flags&32),v>(reg[4]&31) or abs(w)>(reg[8]&127),abs(v-prev)>(reg[5]&31) or abs(w-pw)>(reg[9]&127)]
    return next((i+1 for i,x in enumerate(conditions) if x),0),v,w
@cocotb.test()
async def wrapper_registers_and_fail_closed(dut):
    dut.clk.value=0;dut.ena.value=1;dut.rst_n.value=0;dut.ui_in.value=0;dut.uio_in.value=0
    await cycle(dut)
    assert await read(dut,0)==0 and await read(dut,3)==1
    dut.rst_n.value=1
    counts={str(i):0 for i in range(12)};counts['1']=1
    rng=random.Random(13223048)
    baseline=[0x79,0,3,3,15,15,0,0,63,127]
    cases=[baseline.copy()]
    for flag in [0,0x7b,0x7d,0x78,0x71,0x69,0xf9,0x39,0x59]:
        reg=baseline.copy();reg[0]=flag;cases.append(reg)
    for _ in range(1000):
        reg=baseline.copy()
        if rng.random()<0.4:reg[0]=rng.randrange(256)
        reg[1]=rng.randrange(2)
        for i in range(2,6):reg[i]=rng.randrange(32)
        for i in range(6,10):reg[i]=rng.randrange(128)
        cases.append(reg)
    for reg in cases:
        # Write disabled flags first so intermediate configuration cannot permit.
        await write(dut,0,0)
        for i in range(1,10):await write(dut,i,reg[i])
        await write(dut,0,reg[0])
        fault,v,w=expected(reg);counts[str(fault)]+=1
        assert await read(dut,3)==fault
        assert await read(dut,0)==(fault==0)
        assert await read(dut,1)==(v if fault==0 else 0)
        assert await read(dut,2)==((w&255) if fault==0 else 0)
        assert int(dut.uio_oe.value)==0 and int(dut.uio_out.value)==0
    for i,value in enumerate(baseline):await write(dut,i,value)
    assert await read(dut,0)==1
    dut.ena.value=0
    assert await read(dut,0)==0 and await read(dut,3)==4
    await write(dut,2,31)
    dut.ena.value=1
    assert await read(dut,1)==3,'ena=0 must block register writes'
    Path('tt_functional_coverage.json').write_text(json.dumps({'cases':len(cases),'fault_bins':counts,'status':'PASS','scope':'TTL register wrapper and actual IGOR gate, no DWA/neural/motor driver'},indent=2))
