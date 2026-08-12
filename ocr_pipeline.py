import subprocess, os, re, json
from pathlib import Path

PAGES = sorted(Path('/Users/shiqiuxun/Documents/日常/workbench/pdf_pages').glob('*.png'))
results = {}
asset_pattern = re.compile(r'(S?1\d{10})')  # 1XXXXXXXXXX or S1XXXXXXXXXX

for p in PAGES:
    try:
        r = subprocess.run(
            ['tesseract', str(p), 'stdout', '-l', 'chi_sim+eng', '--psm', '6'],
            capture_output=True, text=True, timeout=30
        )
        text = r.stdout
        ids = sorted(set(asset_pattern.findall(text)))
        results[p.name] = {'ids': ids, 'len': len(text)}
    except Exception as e:
        results[p.name] = {'error': str(e)}

with open('/Users/shiqiuxun/Documents/日常/workbench/ocr_results.json', 'w', encoding='utf-8') as f:
    json.dump(results, f, ensure_ascii=False, indent=1)

total = sum(len(r.get('ids', [])) for r in results.values())
print(f'Pages: {len(PAGES)}, total IDs found: {total}')
print('\nSample - p01.png:', results.get('p01.png', {}))
