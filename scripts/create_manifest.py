"""Hash release files using Git's encoding-independent text classification."""
from pathlib import Path
import hashlib, json, subprocess

root = Path(__file__).resolve().parents[1]
target = root / 'evidence' / 'RELEASE_MANIFEST.json'
entries = subprocess.check_output([
    'git', 'ls-files', '--cached', '--others', '--exclude-standard',
    '--eol', '-z',
], cwd=root).decode('utf-8').split('\0')
paths = {}
for entry in filter(None, entries):
    metadata, name = entry.split('\t', 1)
    worktree_eol = metadata.split()[1]
    attributes = metadata.split('attr/', 1)[1].split()
    # Git detects binary content independently of its character encoding.
    # Explicit text/-text attributes take precedence over automatic detection.
    is_text = '-text' not in attributes and (
        'text' in attributes or worktree_eol != 'w/-text'
    )
    paths[name] = is_text
manifest = {}
text_files = []
for name in sorted(paths):
    path = root / name
    if path == target or not path.is_file():
        continue
    data = path.read_bytes()
    if paths[name]:
        data = data.replace(b'\r\n', b'\n')
        text_files.append(name)
    manifest[name] = hashlib.sha256(data).hexdigest()
target.write_text(json.dumps({'algorithm':'SHA256', 'text_normalization':'CRLF to LF for text files classified by Git, independent of character encoding', 'text_files':text_files, 'files':manifest}, indent=2) + '\n', encoding='utf-8')
print(f'Hashed {len(manifest)} release files')
