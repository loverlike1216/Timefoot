from pathlib import Path
import hashlib, json, shutil
import fitz

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'research/source_extracts'
sources = [
    Path('E:/Codex_project/ZYNQ/AX7020/AX7020开发板原理图V2.0.pdf'),
    Path('E:/Codex_project/ZYNQ/AX7020/3716080086AX7020开发板用户手册V3.0.pdf'),
    Path('E:/Codex_project/ZYNQ/EBAZ4205/EBAZ4205_硬件说明.md'),
    Path('C:/Users/loverlike/.codex/attachments/b9d7eb4f-4e5c-48c2-b4cb-211b82820bd2/已粘贴的文本.txt'),
]
manifest=[]
for n,p in enumerate(sources):
    row={'path':str(p),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
    if p.suffix=='.pdf':
        doc=fitz.open(p)
        row['pages']=len(doc)
        pages=[]
        for i,page in enumerate(doc):
            txt=page.get_text(sort=True)
            (OUT/f'source{n}_page{i+1:02}.txt').write_text(txt,encoding='utf-8')
            pages.append(f'\n\n===== PDF PAGE {i+1} =====\n'+txt)
        (OUT/f'source{n}_full.txt').write_text(''.join(pages),encoding='utf-8')
        row['extracted_chars']=sum(map(len,pages))
    else:
        shutil.copyfile(p,OUT/('EBAZ4205_硬件说明.md' if n==2 else 'USER_REQUEST.txt'))
    manifest.append(row)
(ROOT/'evidence/environment/source_manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(manifest,ensure_ascii=False,indent=2))
