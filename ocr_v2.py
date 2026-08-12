import subprocess, os, re, json
from pathlib import Path

PAGES = sorted(Path('/Users/shiqiuxun/Documents/日常/workbench/pdf_pages').glob('*.png'))
results = {}

for p in PAGES:
    page_results = {}
    for psm in ['4', '6']:
        try:
            r = subprocess.run(
                ['tesseract', str(p), 'stdout', '-l', 'chi_sim+eng', '--psm', psm],
                capture_output=True, text=True, timeout=30
            )
            text = r.stdout
            # Multiple patterns
            ids_full = set(re.findall(r'\bS?1\d{10}\b', text))
            # Also find shorter variants like 1O11E0DOOOO9 (OCR error)
            ids_partial = set(re.findall(r'1\d{10}', text))
            page_results[f'psm{psm}'] = {'ids': sorted(ids_full), 'len': len(text), 'lines': len(text.split('\n'))}
        except Exception as e:
            page_results[f'psm{psm}'] = {'error': str(e)}
    results[p.name] = page_results

with open('/Users/shiqiuxun/Documents/日常/workbench/ocr_v2.json', 'w', encoding='utf-8') as f:
    json.dump(results, f, ensure_ascii=False, indent=1)

print(f"Pages: {len(PAGES)}")
print('p01 psm4:', results.get('p01.png', {}).get('psm4', {}).get('ids', [])[:10])
print('p01 psm6:', results.get('p01.png', {}).get('psm6', {}).get('ids', [])[:10])
