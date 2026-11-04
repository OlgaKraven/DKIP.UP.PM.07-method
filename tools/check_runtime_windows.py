"""Execute the printed SQL Server route in a dedicated, disposable LocalDB instance.

No instance is installed or deleted here. Supply an already created PM07_QA_* instance.
The resulting record states the actual version; it does not certify another OS/version.
"""
from pathlib import Path
import argparse, datetime, hashlib, json, os, re, secrets, subprocess

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--sqlcmd', required=True)
parser.add_argument('--server', required=True)
parser.add_argument('--restart-owned', action='store_true', help='Clear only this run\'s QA databases after verifying every physical path')
args = parser.parse_args()
assert re.fullmatch(r'\(localdb\)\\PM07_QA_\d{8}(?:_\d{2})?', args.server), 'Dedicated QA instance required'
WORK = ROOT / 'work/runtime/sqlserver' / args.server.split('\\')[-1]
WORK.mkdir(parents=True, exist_ok=True)
secret_file = WORK / 'secrets.json'
if not secret_file.exists():
    secret_file.write_text(json.dumps({role:'Pm07!'+secrets.token_hex(16)+'aQ9' for role in ['admin','app_user','readonly']}), encoding='utf-8')
passwords = json.loads(secret_file.read_text(encoding='utf-8'))
events = []

def query(sql, db='master', role=None, deny=None):
    command = [args.sqlcmd, '-S',args.server,'-d',db,'-b','-r','1','-W','-s','|','-h','-1','-f','65001','-l','15']
    env = os.environ.copy()
    if role:
        command += ['-U',role]; env['SQLCMDPASSWORD'] = passwords[role]
    else: command += ['-E']
    # A private input file keeps generated passwords out of process arguments/logs.
    sql_file = WORK / 'current-query.sql'
    sql_file.write_text('SET NOCOUNT ON;\n'+sql,encoding='utf-8-sig')
    command += ['-i',str(sql_file)]
    result = subprocess.run(command,env=env,capture_output=True,timeout=90)
    output = (result.stdout+result.stderr).decode('utf-8',errors='replace').strip()
    for password in passwords.values(): output=output.replace(password,'[redacted]')
    if deny is not None:
        assert result.returncode != 0 and re.search(rf'\b{deny}\b', output), (db,role,'Expected permission denial',deny,output)
    else:
        assert result.returncode == 0, (db,role,output)
    return output

def blocks(text,lang): return re.findall(r'```'+lang+r'\n(.*?)\n```',text,re.S)
route=(ROOT/'docs/routes/mssql-windows.md').read_text(encoding='utf-8')
sql_blocks=blocks(route,'sql')
setup=next(b for b in sql_blocks if 'CREATE LOGIN admin' in b)
owner=next(b for b in sql_blocks if 'CREATE TABLE check_admin' in b)
crud=next(b for b in sql_blocks if 'VALUES(9001,20)' in b)
forbidden=next(b for b in sql_blocks if 'CREATE LOGIN forbidden_probe' in b)
version=query("SELECT CAST(SERVERPROPERTY('ProductVersion') AS varchar(40)),CAST(SERVERPROPERTY('Edition') AS varchar(60)),CAST(SERVERPROPERTY('IsIntegratedSecurityOnly') AS int);")
existing=query("SELECT name FROM sys.databases WHERE name LIKE 'pm07[_]v%';")
if existing.strip() and args.restart_owned:
    for db in existing.splitlines():
        assert re.fullmatch(r'pm07_v(?:18|19|20|21|28)(?:_restore)?',db),db
        filenames=query('SELECT physical_name FROM sys.database_files;',db).splitlines()
        assert filenames and all(Path(f).resolve().is_relative_to(WORK.resolve()) for f in filenames),(db,filenames)
    # The password file and successful login establish ownership of these QA roles.
    query('SELECT 1;',existing.splitlines()[0],'admin')
    for db in existing.splitlines():
        query(f'ALTER DATABASE [{db}] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [{db}];')
    query('DROP LOGIN admin; DROP LOGIN app_user; DROP LOGIN readonly;')
    existing=''
assert not existing.strip(), 'QA databases already exist: preserve them and use a fresh dedicated QA instance'
assert query("SELECT name FROM sys.server_principals WHERE name IN ('admin','app_user','readonly');").strip()=='', 'QA roles already exist'
areas=(ROOT/'docs/subject_areas.md').read_text(encoding='utf-8')
variants=[]
for match in re.finditer(r'^## Вариант (\d{2}) · ([^\n]+)\n(.*?)(?=^## Вариант |\Z)',areas,re.M|re.S):
    n,title,body=match.groups()
    if '(routes/mssql-windows.md)' not in body: continue
    tables=re.search(r'Предметные таблицы: `([^`]+)`, `([^`]+)`, `([^`]+)`',body).groups()
    variants.append((n,title,body,tables))
assert [v[0] for v in variants]==['18','19','20','21','28'], 'All five SQL Server variants must be selected'

for index,(n,title,body,tables) in enumerate(variants):
    database=f'pm07_v{n}'; restored=database+'_restore'
    folder=WORK/database
    for child in ['backups','restore-data','logs','out']: (folder/child).mkdir(parents=True,exist_ok=True)
    current_setup=setup.replace('pm07_demo_restore',restored).replace('pm07_demo',database)
    # LocalDB defaults to the user's home even for separate instances. Keep all
    # QA database files in this particular run's workspace instead.
    data_dir=folder/'data'; data_dir.mkdir(exist_ok=True)
    for db_name in [database,restored]:
        current_setup=current_setup.replace(f'CREATE DATABASE {db_name};',f"CREATE DATABASE {db_name} ON PRIMARY (NAME=N'{db_name}',FILENAME=N'{data_dir/(db_name+'.mdf')}') LOG ON (NAME=N'{db_name}_log',FILENAME=N'{data_dir/(db_name+'_log.ldf')}');")
    for placeholder,role in [('ADMIN_PASSWORD','admin'),('APP_PASSWORD','app_user'),('READ_PASSWORD','readonly')]:
        current_setup=current_setup.replace(placeholder,passwords[role])
    if index: current_setup=re.sub(r'^CREATE LOGIN.*?;\n','',current_setup,flags=re.M)
    query(current_setup)
    query((ROOT/f'docs/downloads/variant-{n}.sql').read_text(encoding='utf-8'),database,'admin')
    # Three real, independent SQL-authenticated connections, never EXECUTE AS.
    identities={r:query('SELECT SUSER_SNAME(),USER_NAME(),DB_NAME();',database,r) for r in passwords}
    query(owner,database,'admin'); query(crud,database,'app_user')
    query('SELECT * FROM dbo.access_probe;',database,'readonly')
    for sql,role,error in [('INSERT INTO access_probe(id,value) VALUES(9002,20);','readonly',229),('DELETE FROM access_probe WHERE id=1;','readonly',229),('CREATE TABLE forbidden_app(id int);','app_user',262),(forbidden,'app_user',15247)]:
        observed=query(sql,database,role,deny=error)
        events.append({'variant':n,'role':role,'expected_error':error,'observed':observed})
    def rows(db):
        output=[]
        for table in tables:
            count=query(f'SELECT COUNT(*),SUM(id),SUM(amount) FROM dbo.[{table}];',db,'admin')
            assert count=='4|10|100.00',(db,table,count)
            one=query(f'SELECT id,amount,quantity FROM dbo.[{table}] WHERE id=1;',db,'admin')
            assert one=='1|10.00|1',(db,table,one)
            output.append({'table':table,'aggregates':count,'row_1':one})
        assert query('SELECT id,value FROM dbo.access_probe;',db,'admin')=='1|10'
        return output
    before=rows(database)
    (folder/'rows-before.txt').write_text(json.dumps(before,ensure_ascii=False,indent=2),encoding='utf-8')
    backup=folder/'backups'/f'{database}_manual.bak'
    query(f"BACKUP DATABASE [{database}] TO DISK=N'{backup}' WITH INIT,CHECKSUM; RESTORE VERIFYONLY FROM DISK=N'{backup}'; RESTORE FILELISTONLY FROM DISK=N'{backup}';")
    logical=query("SELECT name,type FROM sys.database_files ORDER BY type;",database).splitlines()
    assert len(logical)==2,logical
    data_name,log_name=[line.split('|')[0] for line in logical]
    datafile=folder/'restore-data'/f'{restored}.mdf'; logfile=folder/'restore-data'/f'{restored}_log.ldf'
    query(f"RESTORE DATABASE [{restored}] FROM DISK=N'{backup}' WITH MOVE N'{data_name}' TO N'{datafile}',MOVE N'{log_name}' TO N'{logfile}',REPLACE,RECOVERY;")
    after=rows(restored); assert before==after
    (folder/'rows-after.txt').write_text(json.dumps(after,ensure_ascii=False,indent=2),encoding='utf-8')
    scaffold=next(b for b in blocks(route,'powershell') if 'Set-StrictMode' in b)
    function=blocks(body,'powershell')[0]
    scaffold=scaffold.replace("function Invoke-Task {\n    throw 'Замените эту функцию целиком функцией своей карточки'\n}",function)
    assert 'Замените эту функцию' not in scaffold
    config=f"$Database = '{database}'\n$ServerInstance = '{args.server}'\n$Client = '{args.sqlcmd}'\n$AsOf = '2026-11-04'\n$RestoreDatabase = '{restored}'\n$RestoreDataDir = '{folder/'restore-data'}'\n$LogicalData = '{data_name}'\n$LogicalLog = '{log_name}'\n"
    (folder/'config.ps1').write_text(config,encoding='utf-8-sig')
    (folder/'run.ps1').write_text(scaffold,encoding='utf-8-sig')
    def run_script(file,expected):
        env=os.environ.copy()
        # A Python child otherwise inherits this runner's PowerShell 7 module path.
        # Use Windows PowerShell's native modules without changing user settings.
        env['PSModulePath']=os.pathsep.join([str(Path(env['USERPROFILE'])/'Documents/WindowsPowerShell/Modules'),str(Path(env['PROGRAMFILES'])/'WindowsPowerShell/Modules'),str(Path(env['SYSTEMROOT'])/'System32/WindowsPowerShell/v1.0/Modules')])
        result=subprocess.run(['powershell.exe','-NoProfile','-File',str(file)],env=env,capture_output=True,timeout=90)
        output=(result.stdout+result.stderr).decode('utf-8',errors='replace')
        (folder/(file.stem+'-console.txt')).write_text(output,encoding='utf-8')
        assert (result.returncode==0)==expected,(n,file.name,result.returncode,output)
        return result.returncode
    success=run_script(folder/'run.ps1',True)
    if n in ['18','28']:
        generated=[p for p in (folder/'backups').glob('*.bak') if p!=backup]; assert generated
        query(f"RESTORE VERIFYONLY FROM DISK=N'{generated[-1]}';")
    if n=='20': rows(restored)
    if n=='28':
        copies=list((folder/'copy').glob('*.bak')); assert copies
        assert hashlib.sha256(copies[-1].read_bytes()).digest()==hashlib.sha256((folder/'backups'/copies[-1].name).read_bytes()).digest()
    test_config=config.replace(f"$Database = '{database}'","$Database = 'pm07_missing_test'")
    (folder/'config-test.ps1').write_text(test_config,encoding='utf-8-sig')
    failed_script=scaffold.replace("'config.ps1'","'config-test.ps1'")
    if n=='20': failed_script=failed_script.replace("'backups'","'missing-backups'")
    (folder/'run-test.ps1').write_text(failed_script,encoding='utf-8-sig')
    failure=run_script(folder/'run-test.ps1',False)
    log=(folder/'logs/run.log').read_text(encoding='utf-8-sig')
    assert '[INFO] END result=OK' in log and '[ERROR]' in log
    events.append({'variant':n,'title':title,'identities':identities,'source_rows':before,'restore_rows':after,'backup_sha256':hashlib.sha256(backup.read_bytes()).hexdigest(),'manual_exit':success,'negative_exit':failure})
    print('PASS SQL input, three actual logins, permissions, backup/restore, printed PowerShell, failure:',n,flush=True)
record={'timestamp':datetime.datetime.now().isoformat(),'server':args.server,'actual_version':version,'variants':[v[0] for v in variants],'events':events,'scheduler_tested':False,'gui_tested':False,'other_versions_or_os_certified':False}
(WORK/'result.json').write_text(json.dumps(record,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Actual engine:',version,'; scheduler and assigned-version/OS acceptance remain separate',flush=True)
