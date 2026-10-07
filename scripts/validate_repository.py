"""Validate navigation, FPGA source paths, recorded results, and release integrity."""
from pathlib import Path
from urllib.parse import unquote, urlparse
import hashlib, json, re, sys, xml.etree.ElementTree as ET

root = Path(__file__).resolve().parents[1]
errors = []
def require(condition, message):
    if not condition:
        errors.append(message)

authored = [root / 'README.md', root / 'CONTRIBUTING.md'] + list((root / 'docs').glob('*.md'))
links = 0
for page in authored:
    text = page.read_text(encoding='utf-8')
    targets = re.findall(r'\[[^\]\n]*\]\(([^)\n]+)\)', text)
    targets += re.findall(r'(?:src|href)="([^"]+)"', text)
    for target in targets:
        target = target.strip().strip('<>')
        if urlparse(target).scheme or target.startswith('#'):
            continue
        path = (page.parent / unquote(target.split('#')[0])).resolve()
        require(path.is_relative_to(root), f'Link escapes repository: {page.name}: {target}')
        require(path.exists(), f'Broken local link: {page.name}: {target}')
        links += 1

testcases = 0
for suite in ['gate', 'neural', 'top', 'uart', 'tt', 'tt_generic']:
    tree = ET.parse(root / 'evidence' / f'cocotb_{suite}.xml')
    require(not tree.findall('.//failure') and not tree.findall('.//error'), f'Recorded failure: {suite}')
    testcases += len(tree.findall('.//testcase'))
require(testcases == 8, f'Expected 8 recorded testcases, found {testcases}')

proof = json.loads((root / 'evidence' / 'build_evidence.json').read_text())
for image in proof['sof_images']:
    path = root / image['path']
    require(hashlib.sha256(path.read_bytes()).hexdigest() == image['sha256'], f'SOF hash mismatch: {path}')

for canonical, ready, revision in [
    ('fpga_de10_nano', 'IGOR_DE10_NANO', 'igor'),
    ('fpga_de10_lite', 'MAX10_10M50DAF484C7G', 'igor_max10')]:
    ready_root = root / 'ImplementationReadyQuartus' / ready
    for part in ['rtl', 'assets']:
        for path in (root / canonical / part).rglob('*'):
            if path.is_file():
                other = ready_root / path.relative_to(root / canonical)
                require(other.is_file() and other.read_bytes() == path.read_bytes(), f'Quartus Ready copy differs: {ready}/{path.name}')
    original_sof = root / canonical / 'quartus/output_files' / (revision + '.sof')
    ready_sof = ready_root / 'quartus/output_files' / (revision + '.sof')
    require(ready_sof.is_file() and ready_sof.read_bytes() == original_sof.read_bytes(), f'Quartus Ready image differs: {ready}')

for qsf in [root / 'fpga_de10_nano/quartus/igor.qsf', root / 'fpga_de10_lite/quartus/igor_max10.qsf', root / 'robot/jetauto/FPGA_UART_TTL_MULTISPEED/quartus/stm_uart_multispeed.qsf']:
    for relative in re.findall(r'-name (?:VERILOG_FILE|SDC_FILE)\s+([^\r\n]+)', qsf.read_text()):
        require((qsf.parent / relative.strip().strip('"')).is_file(), f'Missing QSF source: {qsf.name}: {relative}')

for board in ['fpga_de10_nano', 'fpga_de10_lite']:
    for path in (root / 'rtl').glob('*.v'):
        # Lite substitutes its own top wrapper and targets M9K memories.
        if board == 'fpga_de10_lite' and path.name == 'igor_de10_nano_wrapper.v':
            require((root / board / 'rtl/igor_de10_lite_top.v').is_file(), 'Missing DE10-Lite wrapper')
            continue
        other = root / board / 'rtl' / path.name
        require(other.is_file(), f'Missing shared RTL: {board}/{path.name}')
        if other.is_file():
            expected = path.read_text(encoding='utf-8')
            if board == 'fpga_de10_lite' and path.name in {'igor_costmap_bank.v', 'igor_neural_rom.v'}:
                expected = expected.replace('"M10K"', '"M9K"')
            require(other.read_text(encoding='utf-8') == expected, f'Unexpected shared RTL difference: {board}/{path.name}')

diagram = ET.parse(root / 'docs/flowcharts/IGOR_RTL_Flowchart.io')
require(len(diagram.findall('diagram')) == 28, 'Expected 28 flowchart pages')
for svg in (root / 'docs/assets').glob('*.svg'):
    ET.parse(svg)

manifest_path = root / 'evidence/RELEASE_MANIFEST.json'
verified = 0
if manifest_path.is_file():
    release = json.loads(manifest_path.read_text())
    manifest = release['files']
    text_files = set(release.get('text_files', []))
    for relative, digest in manifest.items():
        path = root / relative
        require(path.is_file(), f'Missing release file: {relative}')
        if path.is_file():
            data = path.read_bytes()
            if relative in text_files:
                data = data.replace(b'\r\n', b'\n')
            require(hashlib.sha256(data).hexdigest() == digest, f'Release hash differs: {relative}')
        verified += 1
else:
    print('Release manifest not yet generated')
if errors:
    print('\n'.join(errors), file=sys.stderr)
    raise SystemExit(1)
print(json.dumps({'status':'PASS', 'local_links':links, 'recorded_testcases':testcases, 'sof_images':len(proof['sof_images']), 'quartus_ready_projects':2, 'flowchart_pages':28, 'release_files_verified':verified}, indent=2))
