"""Record the SHA256 of staged release files without including this manifest itself."""
from pathlib import Path
import hashlib, json, subprocess

root = Path(__file__).resolve().parents[1]
target = root / 'evidence' / 'RELEASE_MANIFEST.json'
paths = subprocess.check_output(['git', 'ls-files', '-z'], cwd=root).decode('utf-8').split('\0')
manifest = {}
for name in sorted(filter(None, paths)):
    path = root / name
    if path == target:
        continue
    with path.open('rb') as stream:
        manifest[name] = hashlib.file_digest(stream, 'sha256').hexdigest()
target.write_text(json.dumps({'algorithm':'SHA256', 'files':manifest}, indent=2) + '\n', encoding='utf-8')
print(f'Hashed {len(manifest)} staged files')
