"""Synthesize the TT gate prototype. Generic cells are not PDK area or GDS."""
from pathlib import Path
import os,sys
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'.runtime/python'))
os.environ['YOWASP_CACHE_DIR']=str(root/'.runtime/yowasp-cache')
tmp=root/'.runtime/tmp';tmp.mkdir(exist_ok=True)
os.environ['TMP']=str(tmp);os.environ['TEMP']=str(tmp)
import tempfile
tempfile.tempdir=str(tmp)
os.chdir(root)
os.environ['YOWASP_MOUNT']='/=.'
from yowasp_yosys import run_yosys
commands='read_verilog src/project.v src/igor_safety_security_gate.v; synth -top tt_um_wlmoi_igor_gate -flatten -noabc; check; stat; write_json evidence/asic_generic_netlist.json; write_verilog -noattr evidence/asic_generic_netlist.v'
sys.exit(run_yosys(['-l','evidence/asic_generic_synthesis_noabc.log','-p',commands]))

