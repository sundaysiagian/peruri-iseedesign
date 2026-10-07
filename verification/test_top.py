import csv,json
from pathlib import Path
import cocotb
from cocotb.triggers import FallingEdge,Timer,with_timeout,RisingEdge
async def tick(dut):await FallingEdge(dut.clk)
async def reset(dut):
    for name in ['rst_n','estop','protective_stop','start','cfg_write','cfg_lock','map_begin','map_write','map_commit']:getattr(dut,name).value=0
    dut.ready.value=1;dut.cfg_data.value=0x00143d0f;dut.map_sequence.value=1
    await tick(dut);await tick(dut);dut.rst_n.value=1;await tick(dut)
async def pulse(dut,name):
    await tick(dut);getattr(dut,name).value=1
    await tick(dut);getattr(dut,name).value=0
    await tick(dut)
async def setup(dut,scene):
    await pulse(dut,'cfg_write');await pulse(dut,'cfg_lock');await pulse(dut,'map_begin')
    data=[int(x,16) for x in (Path(__file__).parent/'vectors'/f'map_{scene}.hex').read_text().split()]
    for i,byte in enumerate(data):
        await tick(dut);dut.map_write.value=1;dut.map_address.value=i;dut.map_byte.value=byte
    await tick(dut);dut.map_write.value=0
    await pulse(dut,'map_commit')
@cocotb.test()
async def six_scene_oracle_and_determinism(dut):
    rows=list(csv.DictReader((Path(__file__).resolve().parents[1]/'evidence/prior_audit/scene_latency.csv').read_text().splitlines()))
    measured=[]
    for row in rows:
        await reset(dut);await setup(dut,int(row['scene']));await pulse(dut,'start')
        await with_timeout(RisingEdge(dut.done),250,'us');await Timer(1,units='ns')
        assert int(dut.motor_enable.value)==int(row['motor_enable'])
        assert int(dut.selected_index.value)==int(row['index'])
        assert int(dut.selected_score.value)==int(row['score'])
        assert int(dut.latency_cycles.value)==7938
        measured.append({'scene':int(row['scene']),'cycles':int(dut.latency_cycles.value),'permit':int(dut.motor_enable.value)})
        if int(row['motor_enable']):
            dut.estop.value=1;await Timer(1,units='ns')
            assert int(dut.motor_enable.value)==0 and int(dut.v_command.value)==0 and dut.omega_command.value.signed_integer==0
    Path('scene_cocotb_results.json').write_text(json.dumps({'status':'PASS','scenes':measured,'scope':'Six supplied scenes, audit deadline/freshness parameters, not all possible maps'},indent=2))
@cocotb.test()
async def upload_fault_injection(dut):
    results=[]
    for name in ['truncated','nonsequential','replay','write_after_lock','unknown_map']:
        await reset(dut)
        if name=='unknown_map':await pulse(dut,'start')
        elif name=='write_after_lock':
            await pulse(dut,'cfg_write');await pulse(dut,'cfg_lock');await pulse(dut,'cfg_write')
        elif name=='replay':dut.map_sequence.value=0;await pulse(dut,'map_begin')
        else:
            await pulse(dut,'map_begin')
            if name=='nonsequential':
                dut.map_address.value=1;dut.map_byte.value=0;await pulse(dut,'map_write')
            else:await pulse(dut,'map_commit')
        await Timer(1,units='ns')
        assert int(dut.motor_enable.value)==0
        assert int(dut.v_command.value)==0 and dut.omega_command.value.signed_integer==0
        if name in ['truncated','nonsequential','replay']:assert int(dut.core.maps.fault.value)==1
        if name=='write_after_lock':assert int(dut.core.cfg.fault.value)==1
        results.append({'fault':name,'permit':0,'status':'PASS'})
    Path('upload_fault_cocotb_results.json').write_text(json.dumps(results,indent=2))
