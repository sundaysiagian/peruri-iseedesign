import sys,json
from pathlib import Path
import cocotb
from cocotb.triggers import FallingEdge,Timer,with_timeout,RisingEdge
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'reference_model'))
from neural_reference import infer,read_mem
async def tick(dut):
    await FallingEdge(dut.clk)
@cocotb.test()
async def neural_export_and_latency(dut):
    values=read_mem('test_inputs.mem')
    dut.rst_n.value=0
    await tick(dut);await tick(dut)
    dut.rst_n.value=1
    cycles=[]
    for n in range(100):
        inputs=values[n*24:n*24+24]
        expected,expected_fault=infer(inputs)
        for i,v in enumerate(inputs):
            await tick(dut);dut.load_input.value=1;dut.input_index.value=i;dut.input_value.value=v&65535
        await tick(dut);dut.load_input.value=0;dut.start.value=1
        await tick(dut);dut.start.value=0
        await with_timeout(RisingEdge(dut.done),500,'us')
        await Timer(1,units='ns')
        assert int(dut.fault.value)==expected_fault
        cycles.append(int(dut.latency_cycles.value))
        for i,v in enumerate(expected):
            dut.output_index.value=i
            await Timer(1,units='ns')
            assert dut.output_value.value.signed_integer==v,(n,i,v,dut.output_value.value)
    assert set(cycles)=={18192},set(cycles)
    Path('neural_cocotb_results.json').write_text(json.dumps({'vectors':100,'outputs_checked':400,'cycles':sorted(set(cycles)),'oracle':'Independent Python integer matrix MAC, floor Q8.8, ReLU, clipping','status':'PASS'},indent=2))
@cocotb.test()
async def neural_incomplete_input_rejected(dut):
    dut.rst_n.value=0;dut.start.value=0;dut.load_input.value=0
    await tick(dut);await tick(dut);dut.rst_n.value=1
    await tick(dut);dut.start.value=1
    await tick(dut);dut.start.value=0
    await Timer(1,units='ns')
    assert int(dut.fault.value)==1 and int(dut.busy.value)==0
