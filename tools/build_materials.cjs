/* Render the existing teaching Markdown into the approved portrait PDF design. */
const fs=require('node:fs');
const path=require('node:path');
const {pathToFileURL}=require('node:url');
const {chromium}=require('playwright');

const ROOT=path.resolve(__dirname,'..');
const DOCS=path.join(ROOT,'docs');
const OUT=path.join(ROOT,'work','pdf-preview');
const RAW='https://raw.githubusercontent.com/OlgaKraven/DKIP.UP.PM.07-method/refs/heads/codex/up07-method-editorial/docs/';
const ROUTES=['mysql-linux','maria-linux','pg-linux','mssql-windows','mysql-windows','pg-windows'];
const methodFiles=['index.md','practice/stage1.md','practice/stage2.md','practice/stage3.md','practice/stage4.md',...ROUTES.map(x=>'routes/'+x+'.md'),...Array.from({length:4},(_,i)=>'theory/stage'+(i+1)+'.md'),'sources.md'];
const esc=s=>s.replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;').replaceAll('"','&quot;');
const identity=file=>'doc-'+file.replaceAll(/[^a-z0-9]/gi,'-');

function updateSubjectIndex(){
 const source=fs.readFileSync(path.join(DOCS,'subject_areas.md'),'utf8');
 const rows=[...source.matchAll(/^## Вариант (\d{2}) · (.+)\r?\n([\s\S]*?)(?=^## |$(?![\s\S]))/gm)].map(m=>{
  const profile=m[3].match(/СУБД: \*\*(.+?)\*\*\. ОС: \*\*(.+?)\*\*/);
  if(!profile)throw new Error('Missing subject profile '+m[1]);
  return `| ${m[1]} | ${m[2]} | ${profile[1]} | ${profile[2]} | docs/downloads/variant-${m[1]}.sql |`;
 });
 if(rows.length!==30)throw new Error('Expected 30 subject cards');
 fs.writeFileSync(path.join(ROOT,'maintenance','subject-index.md'),'# Индекс предметных областей для импорта\n\nПроизводная таблица из docs/subject_areas.md; обновляется сборщиком материалов. Учебное содержание редактируется только в исходных карточках.\n\n| № | Предметная область | СУБД | ОС | SQL |\n| --- | --- | --- | --- | --- |\n'+rows.join('\n')+'\n');
}

function splitCode(token){
 const lines=token.text.split('\n'),parts=[];let start=0;
 while(start<lines.length){
  let end=start,estimated=0,lastBlank=0;
  while(end<lines.length){
   const height=Math.max(1,Math.ceil(lines[end].length/65));
   if(estimated+height>25&&end>start)break;
   estimated+=height;end++;
   if(estimated>=17&&!lines[end-1].trim())lastBlank=end;
  }
  if(end<lines.length&&lastBlank)end=lastBlank;
  parts.push({...token,text:lines.slice(start,end).join('\n')});start=end;
 }
 return parts;
}
function estimate(t){
 if(t.type==='code')return t.text.split('\n').reduce((n,l)=>n+Math.max(1,Math.ceil(l.length/65)),0)*12+20;
 if(t.type==='table')return 35+t.rows.reduce((n,row)=>n+Math.max(...row.map(c=>Math.ceil(c.text.length/(65/row.length))))*16+12,0);
 if(t.type==='list')return 14+t.items.reduce((n,i)=>n+Math.ceil(i.text.length/65)*16+8,0);
 return Math.ceil((t.text||t.raw||'').length/65)*16+12;
}
function fixLinks(html,file,kind){
 return html.replace(/src="([^"]+)"/g,(_,src)=>{
  if(/^(https?:|data:)/.test(src))return `src="${src}"`;
  return `src="${path.posix.normalize(path.posix.join(path.posix.dirname(file),src))}"`;
 }).replace(/href="([^"]+)"/g,(_,href)=>{
  if(/^(https?:|mailto:|#)/.test(href))return `href="${href}"`;
  const parts=href.split('#');const target=path.posix.normalize(path.posix.join(path.posix.dirname(file),parts[0]));
  if(kind==='method'&&methodFiles.includes(target))return `href="#${identity(target)}"`;
  return `href="${RAW+target+(parts[1]?'#'+parts[1]:'')}"`;
 });
}
const plain=html=>html.replace(/<[^>]*>/g,' ').replaceAll('&lt;','<').replaceAll('&gt;','>').replaceAll('&quot;','"').replaceAll('&#39;',"'").replaceAll('&amp;','&');

(async()=>{
 updateSubjectIndex();
 if(process.argv.includes('--index-only')){process.stdout.write('30 subject entries exported\n');return;}
 const {marked}=await import(pathToFileURL(require.resolve('marked')).href);
 fs.mkdirSync(OUT,{recursive:true});
 fs.cpSync(path.join(DOCS,'assets'),path.join(OUT,'assets'),{recursive:true});
 const expected={method:[],areas:[]};
 const sourceTitles={};
 for(const file of methodFiles){sourceTitles[file]=(fs.readFileSync(path.join(DOCS,file),'utf8').match(/^# (.+)$/m)||[])[1];}
 function renderFile(file,kind){
  const input=fs.readFileSync(path.join(DOCS,file),'utf8');
  const tokens=marked.lexer(input);let result='',current=[],title='',chapterOpen=false,step=0,continued=false;
  const documentTitle=(tokens.find(t=>t.type==='heading'&&t.depth===1)||{}).text||file;
  const kicker=file.startsWith('routes/')?'Маршрут / '+documentTitle:'ПМ.07 / Соадминистрирование';
  let first=true;
  function startChapter(heading){
   if(chapterOpen)result+='</ol></article>';
   const compactIntro=kind==='areas'&&first;
   const anchor=first?identity(file):identity(file)+'-'+step;
   result+=`<article class="chapter" id="${anchor}">${compactIntro?'':`<header class="doc-head"><div class="section-id">${esc(kicker)}</div><h2>${esc(heading)}</h2></header>`}<ol class="steps">`;
   chapterOpen=true;first=false;
   return compactIntro;
  }
  function flush(){
   if(!current.length)return;
   if(!chapterOpen)startChapter(documentTitle);
   let batch=[],height=0;
   function emit(){
    if(!batch.length)return;step++;
    const heading=(title?marked.parseInline(title):'')+(continued?' · продолжение':'');
    const raw=marked.parser(batch).replace(/<p>(<img[^>]*alt="([^"]*)"[^>]*>)<\/p>/g,(_,img,caption)=>`<figure>${img}<figcaption>${caption}</figcaption></figure>`);
    // Multi-line table cells are interleaved by PDF text extractors; inspect their layout visually.
    expected[kind].push(plain(marked.parser(batch.filter(t=>t.type!=='table'))));
    result+=`<li class="step"><span class="number">${step}</span><section class="card">${heading?'<h3>'+heading+'</h3>':''}${fixLinks(raw,file,kind)}</section></li>`;
    batch=[];height=0;continued=true;
   }
   for(const token of current){
    for(const t of token.type==='code'?splitCode(token):[token]){
     if(t.type==='paragraph' && /^<p><img\b/.test(marked.parser([t]))){
      emit();
      const figure=marked.parser([t]).replace(/<p>(<img[^>]*alt="([^"]*)"[^>]*>)<\/p>/g,(_,img,caption)=>`<figure>${img}<figcaption>${caption}</figcaption></figure>`);
      result+=`<li class="figure-row">${fixLinks(figure,file,kind)}</li>`;
      continue;
     }
     if(height+estimate(t)>390&&batch.length)emit();
     batch.push(t);height+=estimate(t);
    }
   }
   emit();current=[];continued=false;
  }
  for(const t of tokens){
   if(t.type==='space')continue;
   if(t.type==='heading'&&t.depth===1){flush();continue;}
   if(t.type==='heading'&&t.depth===2){flush();title=startChapter(t.text)?t.text:'';continue;}
   if(t.type==='heading'&&t.depth>=3){flush();title=t.text;continue;}
   current.push(t);
  }
  flush();if(chapterOpen)result+='</ol></article>';
  return result;
 }
 function shell(title,body,kind){
  return `<!doctype html><html lang="ru"><head><meta charset="utf-8"><title>${esc(title)}</title><link rel="stylesheet" href="assets/style.css"></head><body><main class="${kind}"><header class="hero"><div class="section-id">Учебная практика ПМ.07</div><h1>${esc(title)}</h1></header>${body}</main></body></html>`;
 }
 const toc='<section class="file-links"><h2>Выберите свой маршрут</h2><p>Общее задание и проверки выполняются всеми. Из шести маршрутов ниже выполняется только один — по ОС и СУБД своего варианта.</p>'+ROUTES.map(r=>`<p><a href="#${identity('routes/'+r+'.md')}">${esc(sourceTitles['routes/'+r+'.md'])}</a></p>`).join('')+'</section>';
 fs.writeFileSync(path.join(OUT,'method.html'),shell('Задание и методические рекомендации',toc+methodFiles.map(f=>renderFile(f,'method')).join(''),'method'));
 fs.writeFileSync(path.join(OUT,'areas.html'),shell('Список предметных областей',renderFile('subject_areas.md','areas'),'areas'));
 fs.writeFileSync(path.join(OUT,'expected-text.json'),JSON.stringify(expected,null,2));
 const browser=await chromium.launch({headless:true});
 try{
  const page=await browser.newPage();
  for(const [file,output] of [['method.html','assignment.pdf'],['areas.html','guide.pdf']]){
   await page.goto(pathToFileURL(path.join(OUT,file)).href);
   await page.evaluate(()=>document.fonts.ready);
   await page.pdf({path:path.join(DOCS,'downloads',output),printBackground:true,preferCSSPageSize:true,tagged:true,outline:true});
   process.stdout.write(output+' exported\n');
  }
 }finally{await browser.close()}
})().catch(e=>{console.error(e);process.exit(1)});
