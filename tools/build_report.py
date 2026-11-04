"""Adapt a retained copy of the common completion-report master to UP PM.07."""
from copy import deepcopy
from pathlib import Path
import hashlib,json,shutil,zipfile
from docx import Document
from docx.oxml.ns import qn
from docx.shared import Mm
from docx.enum.table import WD_ROW_HEIGHT_RULE
import report_template_components as parts

ROOT=Path(__file__).resolve().parents[1]
MASTER=ROOT/'forms/template/Отчет о выполнении.docx'
SHA='5b91286458395ae589ded859021f287ce50cca1148cc5b29226b6fb1cb5373c4'
assert hashlib.sha256(MASTER.read_bytes()).hexdigest()==SHA
STAGES=[
 {'title':'Подключение и исходные данные','prompt':'Укажите свою область, один выбранный маршрут и параметры без паролей. Проверьте вход из CLI и графического клиента, три предметные таблицы и отдельную access_probe.','screenshots':['Своя база и три предметные таблицы с исходными контрольными значениями','Подключение графического клиента и совпадающий результат запроса']},
 {'title':'Учётные записи и проверка прав','prompt':'Покажите три отдельных входа. Сопоставьте ожидаемые и фактические разрешения. Для отказов укажите операцию, роль и причину; ошибка синтаксиса или пароля не подтверждает запрет.','screenshots':['Положительные действия admin и app_user с подтверждением текущей роли','Отказы readonly на INSERT и DELETE','Отказы app_user на создание таблицы и серверной учётной записи']},
 {'title':'Копия и отдельное восстановление','prompt':'Укажите точный файл и SHA-256, имена исходной и отдельной проверочной баз. Сравните три таблицы по количеству, сумме id, сумме amount и одной строке. Исходная база сохраняется.','screenshots':['Резервная копия, точный путь и результат её создания','Три контрольных результата до восстановления','Отдельная восстановленная база и совпадающие результаты после восстановления']},
 {'title':'Операция своего варианта','prompt':'Опишите подстановку функции в каркас, параметры и ручной запуск. Подтвердите именно индивидуальный результат и предусмотренные в карточке граничные условия. Пароли и закрытые профили в отчёт не вставляются.','screenshots':['Скрипт своей операции и открытые параметры без секретов','Ручной запуск, код завершения, журнал и результат индивидуальной операции']},
 {'title':'Отказ и действительное расписание','prompt':'Используйте отдельную тестовую копию для отказа. Затем подтвердите наступивший триггер: запись расписания, время запуска, код, новый журнал и результат. Ручная кнопка запуска не заменяет ожидание расписания.','screenshots':['Контролируемый отказ копии скрипта, ненулевой код и ERROR','Настроенный триггер и действие для своей учётной записи ОС','Наступивший запуск планировщика с новым результатом и записью журнала']},
 {'title':'Дополнение и передача результата','prompt':'Покажите выбранное дополнение сверх обязательного каркаса. Объясните изменение и проверку. Перечислите передаваемые SQL, скрипт, открытый пример конфига, копию, журнал и описание; проверьте отсутствие паролей.','screenshots':['Исходное состояние перед индивидуальным дополнением','Результат дополнения и его отдельная проверка']}
]

def text(e):return ''.join(t.text or '' for t in e.iter(qn('w:t')))
def label_rows(table,labels,tag):
    original=deepcopy(table.rows[1]._tr)
    while len(table.rows)<len(labels)+1:table._tbl.append(deepcopy(original))
    while len(table.rows)>len(labels)+1:table._tbl.remove(table.rows[-1]._tr)
    for i,label in enumerate(labels,1):
        for j,cell in enumerate(table.rows[i].cells):
            controls=cell._tc.xpath('.//w:sdt')
            for k,c in enumerate(controls):
                c.find('w:sdtPr/w:tag',c.nsmap).set(qn('w:val'),f'{tag}_{i}_{j}_{k}')
                ts=list(c.find(qn('w:sdtContent')).iter(qn('w:t')))
                ts[0].text=label if j==0 else '____________'
                for t in ts[1:]:t.text=''
            if j==0 and not controls:
                ts=cell._tc.xpath('.//w:t');ts[0].text=label
                for t in ts[1:]:t.text=''
    for row in table.rows:
        row.height=Mm(12);row.height_rule=WD_ROW_HEIGHT_RULE.AT_LEAST

OUT=ROOT/'docs/downloads/Отчет о выполнении.docx'
shutil.copyfile(MASTER,OUT);doc=Document(OUT)
for c in doc.element.xpath('.//w:sdt'):
    tag=c.find('w:sdtPr/w:tag',c.nsmap)
    if tag is not None and tag.get(qn('w:val'))=='practice_name':
        ts=list(c.find(qn('w:sdtContent')).iter(qn('w:t')))
        ts[0].text='Соадминистрирование и автоматизация баз данных и серверов (ПМ.07)'
        for t in ts[1:]:t.text=''
label_rows(doc.tables[0],['Вариант и предметная область','Ссылка на свой SQL-файл','Исходная и проверочная базы','Три предметные таблицы'],'inputs')
label_rows(doc.tables[1],['ОС учебной машины и фактический пользователь','СУБД и клиент командной строки','Графический клиент, адрес и порт хоста','Планировщик и рабочие каталоги'],'environment')
label_rows(doc.tables[2],['pm07_demo / pm07_demo_restore','devices / locations / checks','input.sql','Пути клиента, копий и журналов','Роли и параметры подключения без паролей'],'mapping')
labels=['Исходные данные и два клиента','Три роли и положительные опыты','Конкретные отказы в правах','Копия и отдельное восстановление','Операция своего варианта','Контролируемая ошибка','Действительный запуск по расписанию','Индивидуальное дополнение','Комплект без паролей и рабочая ссылка']
label_rows(doc.tables[-1],labels,'final')
doc.tables[2]._tbl.getprevious().get_or_add_pPr().append(parts.el('pageBreakBefore'))
table=doc.tables[-1];table.autofit=False
for col,w in zip(table.columns,[59,34,35,32]):col.width=Mm(w)
for row in table.rows:
    row.height=Mm(10)
    for cell,w in zip(row.cells,[59,34,35,32]):cell.width=Mm(w)
body=doc.element.body;children=list(body)
start=next(i for i,e in enumerate(children) if text(e)=='Этап выполнения работы')
end=next(i for i,e in enumerate(children) if text(e)=='Итоговая проверка и сдача')
anchor=children[end]
for e in children[start:end]:body.remove(e)
parts.CONTROL_ID=10000;fig=0
for index,stage in enumerate(STAGES,1):
    first=len(list(body))-1
    parts.heading(doc,stage['title'],level=2,new_page=index>1)
    doc.add_paragraph(stage['prompt'])
    for label,tag,lines in [('Исходные данные и ожидаемый результат','initial',2),('Выполненные действия','actions',3),('Фактический результат и проверка','actual',2),('Вывод по этапу и объяснение расхождений','conclusion',2)]:
        parts.response(doc,label,f's{index}_{tag}',lines)
    doc.add_page_break();p=doc.add_paragraph();p.add_run('Подтверждения этапа приведены на рис. ')
    for j,caption in enumerate(stage['screenshots']):
        if j:p.add_run(', ')
        parts.field(p,f'REF pm07_fig_{fig+j+1} \\h',str(fig+j+1))
    p.add_run('. Вставить собственные результаты, сохранив подписи.')
    for j,caption in enumerate(stage['screenshots']):
        if j and j%2==0:doc.add_page_break()
        fig+=1;parts.figure_slot(doc,caption,f'pm07_figure_{fig}',fig,f'pm07_fig_{fig}')
    generated=list(body)[first:-1]
    for e in generated:body.remove(e);anchor.addprevious(e)
for control_id,c in enumerate(doc.element.xpath('.//w:sdt'),30000):c.find('w:sdtPr/w:id',c.nsmap).set(qn('w:val'),str(control_id))
doc.core_properties.title='Отчет о выполнении';doc.core_properties.subject='УП ПМ.07'
doc.core_properties.author=doc.core_properties.last_modified_by=''
doc.core_properties.comments=doc.core_properties.keywords=''
doc.save(OUT)
with zipfile.ZipFile(OUT) as z:edited={n:z.read(n) for n in z.namelist()}
with zipfile.ZipFile(MASTER) as z:original={n:z.read(n) for n in z.namelist()}
allowed={'word/document.xml','docProps/core.xml'}
with zipfile.ZipFile(OUT,'w',zipfile.ZIP_DEFLATED) as z:
    for n,value in original.items():z.writestr(n,edited[n] if n in allowed else value)
with zipfile.ZipFile(OUT) as z:
    for n,value in original.items():
        if n not in allowed:assert z.read(n)==value,n
assert hashlib.sha256(MASTER.read_bytes()).hexdigest()==SHA
(ROOT/'maintenance/report-structure.json').write_text(json.dumps({'master_sha256':SHA,'main_sections':['Исходные условия','Выполнение и проверка','Итоговая проверка и сдача'],'stages':STAGES,'figure_slots':fig},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Copied common master; six stages;',fig,'figure slots:',OUT)
