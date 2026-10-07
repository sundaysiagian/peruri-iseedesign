"""Expand the gzip-compressed evidence waveforms without modifying source files."""
from pathlib import Path
import gzip, shutil

root = Path(__file__).resolve().parents[1]
for path in sorted((root / 'evidence' / 'waveforms').rglob('*.vcd.gz')):
    output = path.with_suffix('')
    with gzip.open(path, 'rb') as inp, output.open('wb') as out:
        shutil.copyfileobj(inp, out)
    print(output.relative_to(root).as_posix())
