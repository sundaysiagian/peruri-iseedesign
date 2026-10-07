"""IGOR UART host. Requires pyserial. No motor connection is implemented."""
import argparse, struct, time
from pathlib import Path

def crc8(data):
    c=0
    for v in data:
        c ^= v
        for _ in range(8):
            c=((c<<1)^0x07)&255 if c&128 else (c<<1)&255
    return c

class Link:
    def __init__(self, port):
        import serial
        self.s=serial.Serial(port,115200,timeout=2,write_timeout=2)
        self.s.reset_input_buffer()
    def command(self,op,value=0):
        b=bytes([0xa5,op])+struct.pack('<I',value)
        self.s.write(b+bytes([crc8(b),0x5a]))
        r=self.s.read(8)
        if len(r)!=8 or r[0]!=0x5a or r[1]!=op or r[7]!=0xa5 or crc8(r[:6])!=r[6]:
            raise RuntimeError(f'Invalid/timeout response: {r.hex()}; reset KEY0 before retry')
        return struct.unpack('<I',r[2:6])[0]
    def close(self): self.s.close()

def status(v):
    return dict(enable=bool(v&1),busy=bool(v&2),done=bool(v&4),protocol_fault=bool(v&8),invalid_command=bool(v&16),fault_code=(v>>8)&255,candidate=(v>>16)&511)

def signed(v,bits): return v-(1<<bits) if v&(1<<(bits-1)) else v

def read_mem(path): return [int(x,16) for line in path.read_text().splitlines() for x in line.split('//')[0].split()]

def main():
    a=argparse.ArgumentParser(description=__doc__)
    a.add_argument('--port',required=True)
    a.add_argument('action',choices=['status','nn-test','dwa-demo','rom-check'])
    a.add_argument('--map',choices=['empty','blocked','unknown'],default='empty')
    args=a.parse_args(); link=Link(args.port)
    assets=Path(__file__).resolve().parents[1]/'assets/neural_24_64_64_4'
    try:
        if args.action=='status': print(status(link.command(7)))
        elif args.action=='rom-check':
            expected=read_mem(assets/'bram_unified_weights.mem')
            for i,x in enumerate(expected):
                actual=link.command(8,i)&65535
                if actual!=x: raise RuntimeError(f'ROM mismatch at {i}: {actual:04x} != {x:04x}')
            print(f'PASS: {len(expected)} ROM words')
        elif args.action=='nn-test':
            ins=read_mem(assets/'test_inputs.mem'); gold=read_mem(assets/'test_outputs.mem')
            for n in range(100):
                for i,x in enumerate(ins[n*24:n*24+24]): link.command(10,i|(x<<8))
                link.command(11)
                deadline=time.monotonic()+2
                while True:
                    r=link.command(12)
                    if r&(1<<18): raise RuntimeError('Neural fault')
                    if r&(1<<16): break
                    if time.monotonic()>deadline: raise RuntimeError('Neural timeout')
                got=[link.command(12,i)&65535 for i in range(4)]
                if got!=gold[n*4:n*4+4]: raise RuntimeError(f'NN mismatch vector {n}: {got}')
            print('PASS: 100 vectors, 400 outputs; cycles=',link.command(13))
        else:
            # Fresh reset required: configuration locks until KEY0; frame sequence starts at 1.
            config=(1<<20)|15|(16<<4)|(15<<10)|(32<<14)
            link.command(4,config); link.command(5)
            link.command(1,1)
            cell={'empty':0,'blocked':254,'unknown':255}[args.map]
            print('Uploading 16384 cells; UART transport takes tens of seconds.')
            for i in range(16384):
                r=link.command(2,i|(cell<<16))
                if r&24: raise RuntimeError(f'Protocol fault at cell {i}')
            link.command(3)
            link.command(6)
            deadline=time.monotonic()+0.015
            while True:
                s=status(link.command(7))
                if s['done']: break
                if time.monotonic()>deadline: raise RuntimeError(f'No timely DWA result: {s}; reset KEY0')
            commands=link.command(14)
            print(s,'v=',commands&31,'omega=',signed((commands>>5)&127,7),'cycles=',link.command(9))
            print('Command lease and map freshness expire after 20 ms. This is a one-shot demo.')
    finally: link.close()

if __name__=='__main__': main()
