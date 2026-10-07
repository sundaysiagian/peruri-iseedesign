import argparse,json,os,sys
from pathlib import Path
root=Path(__file__).resolve().parents[1]
runtime=root/'.runtime/python'
if runtime.exists():sys.path.insert(0,str(runtime))
os.environ['PYTHONPATH']=os.pathsep.join([str(runtime),str(root/'verification'),str(root/'reference_model'),os.environ.get('PYTHONPATH','')])
if os.name=='nt':os.environ['PATH']=os.pathsep.join(['C:/iverilog/bin',str(runtime/'cocotb/libs'),os.environ['PATH']])
from cocotb.runner import get_runner
parser=argparse.ArgumentParser()
parser.add_argument('suite',choices=['gate','neural','top','uart','tt','tt_generic','all'],default='all',nargs='?')
args=parser.parse_args()
for suite in (['gate','neural','top','uart','tt'] if args.suite=='all' else [args.suite]):
    runner=get_runner('icarus')
    if suite=='gate':sources=[root/'rtl/igor_safety_security_gate.v'];top='igor_safety_security_gate';module='test_gate';testdir=root/'verification'
    elif suite=='neural':sources=[root/'rtl/igor_neural_core.v',root/'rtl/igor_neural_rom.v',root/'verification/tb_neural.v'];top='tb_neural';module='test_neural';testdir=root/'verification'
    elif suite=='top':sources=[p for p in (root/'rtl').glob('*.v')]+[root/'verification/tb_top.v'];top='tb_top';module='test_top';testdir=root/'verification'
    elif suite=='uart':sources=[root/'rtl/igor_uart_protocol.v',root/'rtl/igor_uart_rx.v',root/'rtl/igor_uart_tx.v',root/'verification/tb_uart.v'];top='tb_uart';module='test_uart';testdir=root/'verification'
    elif suite=='tt_generic':sources=[root/'evidence/asic_generic_netlist.v',root/'test/tb.v'];top='tb';module='test';testdir=root/'test'
    else:sources=[root/'src/project.v',root/'src/igor_safety_security_gate.v',root/'test/tb.v'];top='tb';module='test';testdir=root/'test'
    build=root/'verification/build'/suite
    runner.build(verilog_sources=sources,hdl_toplevel=top,build_dir=build,build_args=['-g2012'],always=True)
    result=runner.test(hdl_toplevel=top,test_module=module,test_dir=testdir,results_xml=str(root/'evidence'/f'cocotb_{suite}.xml'))
    import xml.etree.ElementTree as ET
    tree=ET.parse(result)
    failures=tree.findall('.//failure')+tree.findall('.//error')
    if failures:raise SystemExit(f'{suite}: {len(failures)} failed tests')
    print('SUITE PASS:',suite)
