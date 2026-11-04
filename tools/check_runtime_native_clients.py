"""Run the two printed Windows client scripts against their isolated QA fixtures."""
from pathlib import Path
import argparse,datetime,hashlib,json,os,re,subprocess

ROOT=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser()
parser.add_argument('--docker',required=True)
parser.add_argument('--mysql-bin',required=True)
parser.add_argument('--pg-bin',required=True)
args=parser.parse_args()
WORK=ROOT/'work/runtime/native-clients';WORK.mkdir(exist_ok=True)
env=os.environ.copy()
env['PSModulePath']=os.pathsep.join([str(Path(env['USERPROFILE'])/'Documents/WindowsPowerShell/Modules'),str(Path(env['PROGRAMFILES'])/'WindowsPowerShell/Modules'),str(Path(env['SYSTEMROOT'])/'System32/WindowsPowerShell/v1.0/Modules')])
def command(cmd,stdin=None,fail=False,custom_env=None):
    result=subprocess.run(list(map(str,cmd)),input=stdin,capture_output=True,env=custom_env or env,timeout=90)
    output=(result.stdout+result.stderr).decode('utf-8',errors='replace').strip()
    if fail:assert result.returncode!=0,output
    else:assert result.returncode==0,output
    return result.returncode,output
def blocks(text,lang):return re.findall(r'```'+lang+r'\n(.*?)\n```',text,re.S)
areas=(ROOT/'docs/subject_areas.md').read_text(encoding='utf-8')
records=[]
for n,route,engine,port in [('22','mysql-windows','mysql',13407),('23','pg-windows','pg16',15516)]:
    fixture=ROOT/f'work/runtime/containers/20261104b/{engine}'
    password=json.loads((fixture/'secrets.json').read_text(encoding='utf-8'))['admin']
    folder=WORK/f'pm07_v{n}';folder.mkdir(exist_ok=True);(folder/'auth').mkdir(exist_ok=True)
    database=f'pm07_v{n}';restored=database+'_native_restore'
    route_text=(ROOT/f'docs/routes/{route}.md').read_text(encoding='utf-8')
    body=re.search(r'^## Вариант '+n+r' · [^\n]+\n(.*?)(?=^## Вариант |\Z)',areas,re.M|re.S)[1]
    tables=re.search(r'Предметные таблицы: `([^`]+)`, `([^`]+)`, `([^`]+)`',body).groups()
    scaffold=next(b for b in blocks(route_text,'powershell') if 'Set-StrictMode' in b)
    function=blocks(body,'powershell')[0]
    scaffold=scaffold.replace("function Invoke-Task {\n    throw 'Замените эту функцию целиком функцией своей карточки'\n}",function)
    assert 'Замените эту функцию' not in scaffold
    if n=='22':
        client=Path(args.mysql_bin)/'mysql.exe';dump=Path(args.mysql_bin)/'mysqldump.exe'
        (folder/'auth/client.cnf').write_text(f'[client]\nuser=admin\npassword={password}\nhost=127.0.0.1\nport={port}\n',encoding='utf-8')
        config=f"$Database = '{database}'\n$Client = '{client}'\n$Dump = '{dump}'\n$Auth = Join-Path $Work 'auth\\client.cnf'\n"
        def query(sql,db=database):return command([client,f'--defaults-file={folder/"auth/client.cnf"}','--batch','--raw','--skip-column-names',f'--database={db}',f'--execute={sql}'])[1]
        identity=query('SELECT CURRENT_USER(),DATABASE();')
    else:
        client=Path(args.pg_bin)/'psql.exe';dump=Path(args.pg_bin)/'pg_dump.exe';restore=Path(args.pg_bin)/'pg_restore.exe'
        (folder/'auth/pgpass.conf').write_text(f'127.0.0.1:{port}:*:admin:{password}\n',encoding='utf-8')
        config=f"$Database = '{database}'\n$DbHost = '127.0.0.1'\n$DbPort = '{port}'\n$Client = '{client}'\n$Dump = '{dump}'\n$env:PGPASSFILE = Join-Path $Work 'auth\\pgpass.conf'\n"
        pg_env=env.copy();pg_env['PGPASSFILE']=str(folder/'auth/pgpass.conf')
        def query(sql,db=database):return command([client,'-X','-w','-h','127.0.0.1','-p',port,'-U','admin','-d',db,'-v','ON_ERROR_STOP=1','-A','-t','-c',sql],custom_env=pg_env)[1]
        identity=query('SELECT current_user,current_database();')
    (folder/'config.ps1').write_text(config,encoding='utf-8-sig')
    (folder/'run.ps1').write_text(scaffold,encoding='utf-8-sig')
    rc,output=command(['powershell.exe','-NoProfile','-File',folder/'run.ps1'])
    (folder/'run-console.txt').write_text(output,encoding='utf-8')
    archive=max((folder/'backups').glob('*.'+('sql' if n=='22' else 'dump')),key=lambda p:p.stat().st_mtime)
    assert archive.stat().st_size>100
    container=f'pm07-qa-20261104b-{engine}'
    if n=='22':
        command([args.docker,'exec','-i',container,'mysql','--defaults-file=/tmp/pm07-auth/root.cnf'],stdin=f"CREATE DATABASE {restored}; GRANT ALL PRIVILEGES ON {restored}.* TO 'admin'@'%';".encode())
        command([client,f'--defaults-file={folder/"auth/client.cnf"}',f'--database={restored}'],stdin=archive.read_bytes())
    else:
        command([args.docker,'exec',container,'psql','-U','postgres','-d','postgres','-v','ON_ERROR_STOP=1','-c',f'CREATE DATABASE {restored} OWNER admin TEMPLATE template0;'])
        command([restore,'--list',archive])
        command([restore,'-w','-h','127.0.0.1','-p',port,'-U','admin','-d',restored,'--no-owner','--no-privileges','--exit-on-error',archive],custom_env=pg_env)
        saved=(archive.parent/(archive.name+'.sha256.txt')).read_text(encoding='utf-8-sig').strip()
        assert saved.lower()==hashlib.sha256(archive.read_bytes()).hexdigest()
        changed=folder/'changed-copy.dump';changed.write_bytes(archive.read_bytes()+b'changed-copy')
        assert saved.lower()!=hashlib.sha256(changed.read_bytes()).hexdigest()
    for table in tables:
        quoted=f'`{table}`' if n=='22' else f'"{table}"'
        assert query(f'SELECT COUNT(*),SUM(id),SUM(amount) FROM {quoted};',restored).replace('\t','|')=='4|10|100.00'
    (folder/'config-test.ps1').write_text(config.replace(f"$Database = '{database}'","$Database = 'pm07_missing_test'"),encoding='utf-8-sig')
    (folder/'run-test.ps1').write_text(scaffold.replace("'config.ps1'","'config-test.ps1'"),encoding='utf-8-sig')
    failure,error=command(['powershell.exe','-NoProfile','-File',folder/'run-test.ps1'],fail=True)
    logs=(folder/'logs/run.log').read_text(encoding='utf-8-sig')
    assert '[INFO] END result=OK' in logs and '[ERROR]' in logs
    records.append({'variant':n,'identity':identity,'client_version':command([client,'--version'])[1],'manual_exit':rc,'negative_exit':failure,'restored_database':restored,'tables_checked':list(tables),'archive_sha256':hashlib.sha256(archive.read_bytes()).hexdigest()})
    print('PASS actual Windows PowerShell/client, archive, separate restore, negative run:',n,flush=True)
(WORK/'result.json').write_text(json.dumps({'timestamp':datetime.datetime.now().isoformat(),'events':records,'windows_server_os_certified':False,'scheduler_tested':False},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
