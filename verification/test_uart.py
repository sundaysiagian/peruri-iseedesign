import json
from pathlib import Path
import cocotb
from cocotb.triggers import Timer,FallingEdge,with_timeout
def crc8(data):
    c=0
    for b in data:
        c^=b
        for _ in range(8):c=((c<<1)^0x07)&255 if c&128 else (c<<1)&255
    return c
async def reset(dut):
    dut.rx.value=1;dut.rst_n.value=0;await Timer(100,units='ns')
    dut.rst_n.value=1;await Timer(100,units='ns')
async def byte(dut,value):
    dut.rx.value=0;await Timer(160,units='ns')
    for i in range(8):dut.rx.value=(value>>i)&1;await Timer(160,units='ns')
    dut.rx.value=1;await Timer(320,units='ns')
async def receive(dut):
    result=[]
    for _ in range(8):
        await with_timeout(FallingEdge(dut.tx),100,'us')
        await Timer(240,units='ns')
        value=0
        for i in range(8):
            value|=int(dut.tx.value)<<i
            await Timer(160,units='ns')
        assert int(dut.tx.value)==1
        result.append(value)
    return bytes(result)
@cocotb.test()
async def uart_crc_response_and_fault_latch(dut):
    await reset(dut)
    body=bytes([0xa5,9,0x78,0x56,0x34,0x12])
    frame=body+bytes([crc8(body),0x5a])
    receiver=cocotb.start_soon(receive(dut))
    for value in frame:await byte(dut,value)
    response=await receiver
    assert int(dut.accepted.value)==1 and int(dut.payload.value)==0x12345678
    assert response[:6]==bytes([0x5a,9,0x78,0x56,0x34,0x12])
    assert response[6]==crc8(response[:6]) and response[7]==0xa5
    await Timer(2000,units='ns')
    corrupted=bytearray(frame);corrupted[6]^=1
    for value in corrupted:await byte(dut,value)
    await Timer(500,units='ns')
    assert int(dut.protocol_fault.value)==1 and int(dut.accepted.value)==1
    for value in frame:await byte(dut,value)
    await Timer(500,units='ns')
    assert int(dut.accepted.value)==1,'Fault remains latched until reset'
    await reset(dut)
    receiver=cocotb.start_soon(receive(dut))
    for value in frame:await byte(dut,value)
    await receiver
    assert int(dut.accepted.value)==1 and int(dut.protocol_fault.value)==0
    Path('uart_cocotb_results.json').write_text(json.dumps({'status':'PASS','valid_response_crc':True,'bad_crc_rejected':True,'fault_latched':True,'reset_recovers':True,'divider':8,'scope':'IGOR A5/5A protocol, not STM RRC'},indent=2))
