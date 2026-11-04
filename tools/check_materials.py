"""Check teaching content and rendered PDF; this does not certify database execution."""
from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urlsplit,unquote
import hashlib,json,logging,re
import pdfplumber
from pypdf import PdfReader

ROOT=Path(__file__).resolve().parents[1]
DOCS=ROOT/'docs'
logging.getLogger('pdfminer').setLevel(logging.ERROR)
ROUTES=['mysql-linux','maria-linux','pg-linux','mssql-windows','mysql-windows','pg-windows']

class Links(HTMLParser):
    def __init__(self):super().__init__();self.ids=[];self.links=[]
    def handle_starttag(self,tag,attrs):
        attrs=dict(attrs)
        if 'id' in attrs:self.ids.append(attrs['id'])
        if 'href' in attrs:self.links.append(attrs['href'])

def normalized(s):
    return re.sub(r'\s+','',s.replace('ﬁ','fi').replace('ﬂ','fl').replace('•','').replace('●',''))

def check():
    for p in DOCS.rglob('*.md'):
        text=p.read_text(encoding='utf-8')
        assert not any(ord(c)<32 and c not in '\n\t' for c in text),p
        assert sum(line.startswith('```') for line in text.splitlines())%2==0,p
        for link in re.findall(r'\]\(([^)]+)\)',text):
            part=urlsplit(link)
            if part.scheme or not part.path:continue
            target=(p.parent/unquote(part.path)).resolve()
            assert target.is_relative_to(DOCS) and target.is_file(),(p,link)
    areas=(DOCS/'subject_areas.md').read_text(encoding='utf-8')
    cards=re.split(r'\n## Вариант ',areas)[1:]
    assert len(cards)==30
    for i,card in enumerate(cards,1):
        assert card.startswith(f'{i:02d} ·')
        sql=(DOCS/f'downloads/variant-{i:02d}.sql').read_text(encoding='utf-8')
        assert f'pm07_v{i:02d}' in card and f'variant-{i:02d}.sql' in card
        assert any('routes/'+key+'.md' in card for key in ROUTES)
        assert 'run_task() {' in card or 'function Invoke-Task {' in card
        assert '### Проверка своего результата' in card
        assert sql.count('PRIMARY KEY')>=4 and 'access_probe' in sql
        assert not re.search(r'\bDROP\s+DATABASE\b',sql,re.I)
    for key in ROUTES:
        p=DOCS/'routes'/f'{key}.md';text=p.read_text(encoding='utf-8')
        code='\n'.join(re.findall(r'```[^\n]*\n(.*?)\n```',text,re.S))
        assert 'DB_HELPERS' not in code
        if key.startswith(('mysql','maria')):assert not re.search(r'\b(pg_dump|pg_restore|CREATE ROLE|CREATE LOGIN)\b',code)
        if key.startswith('pg'):assert not re.search(r'\b(mysqldump|mariadb-dump|CREATE LOGIN)\b',code)
        if key=='mssql-windows':assert not re.search(r'\b(pg_dump|mysqldump|COMPRESSION|SYSTEM)\b',code)
        assert 'pm07_demo_restore' in code
    expected=json.loads((ROOT/'work/pdf-preview/expected-text.json').read_text(encoding='utf-8'))
    report={'cards':30,'routes':6,'sql_inputs':34,'runtime_certified_by_this_check':False,'pdf':{}}
    for kind,name in [('method','assignment.pdf'),('areas','guide.pdf')]:
        html=Links();html.feed((ROOT/f'work/pdf-preview/{kind if kind=="areas" else "method"}.html').read_text(encoding='utf-8'))
        assert len(html.ids)==len(set(html.ids)),('duplicate anchors',kind)
        for link in html.links:
            if link.startswith('#'):assert link[1:] in html.ids,link
        path=DOCS/'downloads'/name;reader=PdfReader(path);fonts=set();over=[];body_text=''
        with pdfplumber.open(path) as pdf:
            for i,p in enumerate(pdf.pages,1):
                assert abs(p.width-595.276)<1 and abs(p.height-841.89)<1
                for picture in p.images:
                    assert picture['x0']>=84 and picture['x1']<=539.6 and picture['top']>=55 and picture['bottom']<=787,(name,i,'image outside page body')
                for c in p.chars:
                    if c['top']>795:
                        assert abs(c['size']-8)<.1,(name,i,'footer',c['size']);continue
                    fonts.add((c['fontname'].split('+')[-1],round(c['size'],1)))
                    if c['text'].strip() and (c['x0']<84 or c['x1']>539.6 or c['top']<55 or c['bottom']>787):over.append((i,c['text'],round(c['x0'],1),round(c['top'],1)))
                # Exclude the left route numbers, which can be ordered between paragraph lines.
                body_text+=p.crop((129,0,p.width,795)).extract_text(x_tolerance=2) or ''
        assert not over,(name,'overflow',over[:15])
        compact=normalized(body_text);missing=[]
        for block in expected[kind]:
            for line in block.splitlines():
                if line.strip() and normalized(line) not in compact:missing.append(line[:100])
        assert not missing,(name,'missing text',missing[:10])
        assert any('Golos' in font and size==10.5 for font,size in fonts),fonts
        assert any(size==8.5 for _,size in fonts),fonts
        uris=[a.get_object().get('/A',{}).get('/URI') for p in reader.pages for a in p.get('/Annots',[])]
        assert any(uri and 'variant-01.sql' in uri for uri in uris) if kind=='areas' else any(uris)
        report['pdf'][name]={'pages':len(reader.pages),'fonts':sorted(fonts),'paragraph_and_code_text':True,'bounds':True,'table_review':'visual','sha256':hashlib.sha256(path.read_bytes()).hexdigest()}
    (ROOT/'work/material-check.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print('PASS: 30 cards, 6 consistent routes, inputs/links, PDF text, type and bounds; runtime remains separate')

if __name__=='__main__':check()
