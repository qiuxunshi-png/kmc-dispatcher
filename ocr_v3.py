import subprocess, re, json
from pathlib import Path

PAGES = sorted(Path('/Users/shiqiuxun/Documents/日常/workbench/pdf_pages').glob('*.png'))
results = {}
pat = re.compile(r'\bS?1\d{10}\b')

for p in PAGES:
    try:
        r = subprocess.run(
            ['tesseract', str(p), 'stdout', '-l', 'chi_sim+eng', '--psm', '4'],
            capture_output=True, text=True, timeout=30
        )
        text = r.stdout
        ids = sorted(set(pat.findall(text)))
        results[p.name] = ids
    except Exception as e:
        results[p.name] = []

with open('/Users/shiqiuxun/Documents/日常/workbench/all_ids.json', 'w', encoding='utf-8') as f:
    json.dump(results, f, ensure_ascii=False, indent=1)

all_ids = set()
for v in results.values():
    all_ids.update(v)
print(f'Total unique IDs: {len(all_ids)}, pages: {len(PAGES)}')
# Count pages with 0 IDs
empty = [k for k,v in results.items() if len(v)==0]
print(f'Empty pages: {len(empty)}, e.g. {empty[:5]}')
# Show total per page
counts = [(k, len(v)) for k,v in results.items()]
counts.sort(key=lambda x: x[1])
print('Pages with fewest IDs:', counts[:5])
print('Pages with most IDs:', sorted(counts, key=lambda x: -x[1])[:5])
