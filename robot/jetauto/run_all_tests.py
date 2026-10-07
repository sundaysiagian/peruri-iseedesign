"""Run offline checks and, when explicitly selected, the recorded COM9 motor suites."""
from pathlib import Path
from datetime import datetime
import argparse, subprocess, sys, json, hashlib, shutil

root = Path(__file__).resolve().parent
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--run', action='store_true')
parser.add_argument('--wheels-raised', action='store_true')
parser.add_argument('--supply-on', action='store_true')
parser.add_argument('--profile', choices=['all', 'diagonals', 'staged', 'diagonal-staged', 'round-robin'], default='all')
args = parser.parse_args()
if args.run and not (args.wheels_raised and args.supply_on):
    parser.error('Motion requires raised wheels and motor supply ON')
stamp = datetime.now().strftime('%Y%m%d_%H%M%S')
log_path = root / 'logs' / f'{stamp}_all_tests_console.log'
results = []

def run(label, command, show_output=True):
    print('\nTEST:', label, flush=True)
    with log_path.open('a', encoding='utf-8') as log:
        log.write('\nTEST: ' + label + '\n')
        child = subprocess.Popen(command, cwd=root, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                 text=True, encoding='utf-8', errors='replace')
        try:
            for line in child.stdout:
                if show_output:
                    print(line, end='', flush=True)
                log.write(line)
                log.flush()
            code = child.wait()
        except KeyboardInterrupt:
            # The console Ctrl+C is also delivered to the child, whose finally block sends STOP.
            try:
                child.wait(timeout=3)
            except subprocess.TimeoutExpired:
                print('Child still cleaning up. Close the motor supply if communication is lost.', flush=True)
            raise
    results.append({'test': label, 'exit_code': code, 'status': 'PASS' if code == 0 else 'FAIL'})
    if code:
        raise RuntimeError(label + ' failed. No further motion test will be started.')
    if not show_output:
        print('PASS:', label, '| details saved to', log_path.name, flush=True)

try:
    run('Offline SDK CRC and packet checks', [sys.executable, 'verify_driver.py'], False)
    run('RTL-captured four-speed packets', [sys.executable, 'test_rtl_packets_on_stm.py'], False)
    run('Long individual/pair/group packet validation', [sys.executable, 'test_wheel_channels.py', '--long-sequence'], False)
    run('Diagonal, staged and one-ID packet validation', [sys.executable, 'test_diagonal_and_staged.py', '--profile', 'all'], False)
    iverilog = Path('C:/iverilog/bin/iverilog.exe')
    vvp = Path('C:/iverilog/bin/vvp.exe')
    iverilog_path = str(iverilog) if iverilog.exists() else shutil.which('iverilog')
    vvp_path = str(vvp) if vvp.exists() else shutil.which('vvp')
    if iverilog_path and vvp_path:
        run('Both Verilog RTL testbenches', ['powershell.exe', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File',
            str(root / 'FPGA_UART_TTL_MULTISPEED/run_verilog_tests.ps1'), '-Iverilog', iverilog_path, '-Vvp', vvp_path])
    else:
        results.append({'test': 'Both Verilog RTL testbenches', 'status': 'SKIPPED', 'reason': 'Icarus not installed on this laptop'})
        print('SKIPPED live Verilog rerun: Icarus not installed. Previous evidence is included.', flush=True)
    provenance = json.loads((root / 'FPGA_UART_TTL_MULTISPEED/evidence/build_provenance.json').read_text(encoding='utf-8'))
    assert hashlib.sha256((root / provenance['sof_path']).read_bytes()).hexdigest() == provenance['sof_sha256']
    for relative, digest in provenance['source_sha256'].items():
        source_bytes = (root / 'FPGA_UART_TTL_MULTISPEED' / relative).read_bytes()
        if provenance.get('source_sha256_normalization') == 'CRLF to LF':
            source_bytes = source_bytes.replace(b'\r\n', b'\n')
        assert hashlib.sha256(source_bytes).hexdigest() == digest, relative
    results.append({'test': 'Source and SOF hashes', 'status': 'PASS'})
    if args.run:
        flags = ['--run', '--wheels-raised', '--supply-on']
        if args.profile == 'all':
            run('Earlier 60 RPM forward/backward test', [sys.executable, 'raw_serial_test.py'] + flags)
            run('Four-speed RTL packet replay, up to 90 RPM', [sys.executable, 'test_rtl_packets_on_stm.py'] + flags)
            run('Short per-motor test', [sys.executable, 'test_wheel_channels.py'] + flags)
            run('Long each-motor, front/rear pairs and group test', [sys.executable, 'test_wheel_channels.py', '--long-sequence'] + flags)
        run('Diagonal/staged/one-ID diagnostic: ' + args.profile,
            [sys.executable, 'test_diagonal_and_staged.py', '--profile', args.profile] + flags)
        run('Check all recorded host frames and RX CRC', [sys.executable, 'analyze_logs.py'])
    print('\nDONE. Physical wheel observations are required. An exit code of zero is not a motor ACK.', flush=True)
finally:
    (root / 'logs' / f'{stamp}_all_tests_summary.json').write_text(json.dumps({
        'motion_requested': args.run, 'profile': args.profile, 'tests': results,
        'physical_motion_automatically_verified': False,
        'console_log': log_path.name}, indent=2), encoding='utf-8')
