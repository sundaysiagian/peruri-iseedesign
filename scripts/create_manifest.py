"""Hash release files with portable LF normalization for UTF-8 text."""
from pathlib import Path
import hashlib, json, subprocess

root = Path(__file__).resolve().parents[1]
target = root / 'evidence' / 'RELEASE_MANIFEST.json'
paths = subprocess.check_output(['git', 'ls-files', '--cached', '--others', '--exclude-standard', '-z'], cwd=root).decode('utf-8').split('\0')
manifest = {}
text_files = []
for name in sorted(set(filter(None, paths))):
    path = root / name
    if path == target:
        continue
    data = path.read_bytes()
    try:
        data.decode('utf-8')
        if b'\0' not in data:
            data = data.replace(b'\r\n', b'\n')
            text_files.append(name)
    except UnicodeDecodeError:
        pass
    manifest[name] = hashlib.sha256(data).hexdigest()
target.write_text(json.dumps({'algorithm':'SHA256', 'text_normalization':'CRLF to LF for the listed UTF-8 text files', 'text_files':text_files, 'files':manifest}, indent=2) + '\n', encoding='utf-8')
print(f'Hashed {len(manifest)} release files')
