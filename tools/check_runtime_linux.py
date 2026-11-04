"""Run the printed inputs, permissions and Bash recipes on private official DB containers.

Container names and records identify this run. No existing container is reused,
stopped or removed. Actual engine/OS versions and omitted checks are recorded.
"""
from pathlib import Path
import argparse, datetime, hashlib, json, os, re, secrets, subprocess, time

ROOT=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser()
parser.add_argument('--docker',required=True)
parser.add_argument('--engine',choices=['mysql','maria','pg15','pg16'],required=True)
parser.add_argument('--run-id',default='20261104a')
parser.add_argument('--reuse-empty',action='store_true',help='Reuse only this labeled run\'s engine before it has any variant databases')
args=parser.parse_args()
assert re.fullmatch(r'\d{8}[a-z]',args.run_id)
engine=args.engine; pg=engine.startswith('pg')
WORK=ROOT/'work/runtime/containers'/args.run_id/engine
WORK.mkdir(parents=True,exist_ok=True)
name=f'pm07-qa-{args.run_id}-{engine}'
image={'mysql':'mysql:8.0','maria':'mariadb:10.11','pg15':'postgres:15-bookworm','pg16':'postgres:16-bookworm'}[engine]
port={'mysql':13307,'maria':13308,'pg15':15415,'pg16':15416}[engine]
port+=(ord(args.run_id[-1])-ord('a'))*100
passwords=json.loads((WORK/'secrets.json').read_text(encoding='utf-8')) if args.reuse_empty else {r:'Pm07!'+secrets.token_hex(16)+'aQ9' for r in ['root','admin','app_user','readonly']}
(WORK/'secrets.json').write_text(json.dumps(passwords),encoding='utf-8')
events=[]; gaps=[]

def call(command,stdin=None,allowed=False,timeout=120):
    result=subprocess.run(command,input=stdin.encode('utf-8') if isinstance(stdin,str) else stdin,capture_output=True,timeout=timeout)
    output=(result.stdout+result.stderr).decode('utf-8',errors='replace').strip()
    for password in passwords.values(): output=output.replace(password,'[redacted]')
    if not allowed: assert result.returncode==0,output
    return result.returncode,output,result.stdout
def docker(*command,**kw): return call([args.docker,*map(str,command)],**kw)
def shell(script,allowed=False): return docker('exec','-i',name,'bash','-s',stdin=script,allowed=allowed)
existing=docker('ps','-a','--filter',f'name=^/{name}$','--format','{{.Names}}')[1]
if existing:
    assert args.reuse_empty,'Use a fresh run-id; existing QA container is preserved'
    info=json.loads(docker('inspect',name)[1])[0]
    assert info['Config']['Labels'].get('purpose')=='pm07-method-qa'
    assert any(m['Destination']=='/qa' and Path(m['Source']).resolve()==WORK.resolve() for m in info['Mounts'])
environment=('POSTGRES_PASSWORD' if pg else 'MARIADB_ROOT_PASSWORD' if engine=='maria' else 'MYSQL_ROOT_PASSWORD')+'='+passwords['root']+'\n'
(WORK/'server.env').write_text(environment,encoding='utf-8')
if not existing:docker('run','-d','--name',name,'--label','purpose=pm07-method-qa','-p',f'127.0.0.1:{port}:'+('5432' if pg else '3306'),'--env-file',WORK/'server.env','--mount',f'type=bind,source={WORK},target=/qa',image)
for attempt in range(90):
    if pg:
        rc,_,_=docker('exec',name,'pg_isready','-U','postgres',allowed=True)
    else:
        client='mariadb-admin' if engine=='maria' else 'mysqladmin'
        rc,_,_=docker('exec',name,client,'ping','--silent',allowed=True)
    if rc==0:break
    time.sleep(1)
else:raise RuntimeError('Private engine did not become ready')

if not pg:
    (WORK/'root.cnf').write_text('[client]\nuser=root\npassword='+passwords['root']+'\n',encoding='utf-8')
    shell('mkdir -p /tmp/pm07-auth; cp /qa/root.cnf /tmp/pm07-auth/root.cnf; chmod 600 /tmp/pm07-auth/root.cnf\n')
def query(sql,db=None,role=None,deny=False):
    if pg:
        command=['exec','-i',name]
        if role: command+=['-e',f"PGPASSWORD={passwords[role]}"] # docker exec options precede container below
        # Build explicitly because exec --env is an option before the container.
        command=['exec','-i']+(['-e',f"PGPASSWORD={passwords[role]}"] if role else [])+[name,'psql','-X','-U',role or 'postgres','-d',db or 'postgres','-v','ON_ERROR_STOP=1','-A','-t']
        if role:command+=['-h','127.0.0.1']
    else:
        client='mariadb' if engine=='maria' else 'mysql'
        command=['exec','-i',name,client,f'--defaults-file=/tmp/pm07-auth/{role or "root"}.cnf','--batch','--raw','--skip-column-names']
        if db:command+=['--database='+db]
    rc,output,raw=docker(*command,stdin=sql,allowed=deny)
    if deny: assert rc!=0 and re.search(r'permission denied|Access denied|command denied|ERROR 1(?:142|144|227|044)',output,re.I),output
    return output

# mysqladmin ping also answers during image initialization, before the final
# root password is applied. Wait for an authenticated query, not just a socket.
for attempt in range(90):
    try:
        query('SELECT 1;');break
    except AssertionError:
        time.sleep(1)
else:raise RuntimeError('Private authenticated engine did not become ready')
if args.reuse_empty:
    databases=query("SELECT datname FROM pg_database WHERE datname LIKE 'pm07_v%';" if pg else "SELECT schema_name FROM information_schema.schemata WHERE schema_name LIKE 'pm07_v%';")
    assert not databases.strip(),'Variant databases already exist; they are preserved'

if not pg:
    for role in ['admin','app_user','readonly']:
        (WORK/f'{role}.cnf').write_text(f'[client]\nuser={role}\npassword={passwords[role]}\nhost=127.0.0.1\nport=3306\n',encoding='utf-8')
        shell(f'cp /qa/{role}.cnf /tmp/pm07-auth/{role}.cnf; chmod 600 /tmp/pm07-auth/{role}.cnf\n')

def blocks(text,lang):return re.findall(r'```'+lang+r'\n(.*?)\n```',text,re.S)
areas=(ROOT/'docs/subject_areas.md').read_text(encoding='utf-8')
selected=[]
for m in re.finditer(r'^## Вариант (\d{2}) · ([^\n]+)\n(.*?)(?=^## Вариант |\Z)',areas,re.M|re.S):
    n,title,body=m.groups()
    dbms=re.search(r'СУБД: \*\*([^*]+)\*\*',body)[1]
    match=(engine=='mysql' and dbms=='MySQL 8') or (engine=='maria' and dbms=='MariaDB 10') or (engine=='pg15' and dbms=='PostgreSQL 15') or (engine=='pg16' and dbms=='PostgreSQL 16')
    if match:
        tables=re.search(r'Предметные таблицы: `([^`]+)`, `([^`]+)`, `([^`]+)`',body).groups()
        selected.append((n,title,body,tables))
assert len(selected)=={'mysql':9,'maria':7,'pg15':1,'pg16':8}[engine],(engine,len(selected))
route_name='pg-linux' if pg else 'maria-linux' if engine=='maria' else 'mysql-linux'
route=(ROOT/f'docs/routes/{route_name}.md').read_text(encoding='utf-8')
sql_blocks=blocks(route,'sql')
setup=next(b for b in sql_blocks if ('CREATE ROLE admin' if pg else "CREATE USER 'admin'") in b)
pg_grants=next((b for b in sql_blocks if 'ALTER DEFAULT PRIVILEGES' in b),'')
owner=next(b for b in sql_blocks if 'CREATE TABLE check_admin' in b)
crud=next(b for b in sql_blocks if 'VALUES(9001,20)' in b)
forbidden=next(b for b in sql_blocks if 'forbidden_probe' in b)
scaffold=next(b for b in blocks(route,'bash') if '#!/usr/bin/env bash' in b)

for index,(n,title,body,tables) in enumerate(selected):
    database=f'pm07_v{n}'; restored=database+'_restore'; folder=WORK/database;folder.mkdir(exist_ok=True)
    for sub in ['out','backups','logs']:(folder/sub).mkdir(exist_ok=True)
    current=setup.replace('pm07_demo_restore',restored).replace('pm07_demo',database)
    for key,role in [('ADMIN_PASSWORD','admin'),('APP_PASSWORD','app_user'),('READ_PASSWORD','readonly')]:current=current.replace(key,passwords[role])
    if index:current=re.sub(r'^CREATE (?:ROLE|USER).*?;\n','',current,flags=re.M)
    query(current)
    seed=(ROOT/f'docs/downloads/variant-{n}.sql').read_text(encoding='utf-8')
    query(seed,database,'admin')
    if pg:query(pg_grants,database,'admin')
    identities={role:query('SELECT current_user,current_database();' if pg else 'SELECT CURRENT_USER(),DATABASE();',database,role) for role in ['admin','app_user','readonly']}
    query(owner,database,'admin');query(crud,database,'app_user');query('SELECT * FROM access_probe;',database,'readonly')
    denies=[]
    for sql,role in [('INSERT INTO access_probe(id,value) VALUES(9002,20);','readonly'),('DELETE FROM access_probe WHERE id=1;','readonly'),('CREATE TABLE forbidden_app(id int);','app_user'),(forbidden,'app_user')]:
        denies.append({'role':role,'observed':query(sql,database,role,deny=True)})
    def rows(db):
        items=[]
        for table in tables:
            quoted=f'"{table}"' if pg else f'`{table}`'
            aggregate=query(f'SELECT COUNT(*),SUM(id),SUM(amount) FROM {quoted};',db,'admin')
            assert aggregate.replace('\t','|')=='4|10|100.00',(db,table,aggregate)
            first=query(f'SELECT id,amount,quantity FROM {quoted} WHERE id=1;',db,'admin')
            assert first.replace('\t','|')=='1|10.00|1',(db,table,first)
            items.append({'table':table,'aggregate':aggregate,'row_1':first})
        assert query('SELECT id,value FROM access_probe;',db,'admin').replace('\t','|')=='1|10'
        return items
    before=rows(database);base=f'/qa/{database}'
    if pg:
        (folder/'pgpass').write_text(f'127.0.0.1:5432:*:admin:{passwords["admin"]}\n',encoding='utf-8')
        shell(f'cp {base}/pgpass /tmp/pm07-auth-{n}; chmod 600 /tmp/pm07-auth-{n}\n')
        backup=f'{base}/backups/manual.dump'
        shell(f'export PGPASSFILE=/tmp/pm07-auth-{n}\npg_dump -w -h 127.0.0.1 -U admin -d {database} -Fc -f {backup}\npg_restore --list {backup} > {base}/out/manual-toc.txt\npg_restore -w -h 127.0.0.1 -U admin -d {restored} --no-owner --no-privileges --exit-on-error {backup}\n')
    else:
        backup=f'{base}/backups/manual.sql';dump='mariadb-dump' if engine=='maria' else 'mysqldump';client='mariadb' if engine=='maria' else 'mysql'
        flags='--no-tablespaces --set-gtid-purged=OFF ' if engine=='mysql' else ''
        shell(f'{dump} --defaults-file=/tmp/pm07-auth/admin.cnf --single-transaction {flags}--result-file={backup} {database}\n{client} --defaults-file=/tmp/pm07-auth/admin.cnf {restored} < {backup}\n')
    after=rows(restored);assert before==after
    entry={'variant':n,'title':title,'identities':identities,'denials':denies,'before':before,'after':after,'backup_sha256':hashlib.sha256((folder/'backups'/Path(backup).name).read_bytes()).hexdigest()}
    bash_functions=blocks(body,'bash')
    if not bash_functions:
        gaps.append({'variant':n,'check':'Printed Windows PowerShell script; Linux fixture certifies SQL data/rights/restore only'})
    elif n=='06':
        gaps.append({'variant':n,'check':'Real start of a dedicated systemd MariaDB service; these database containers do not run systemd'})
    else:
        function=bash_functions[0]
        code=scaffold.replace('run_task() {\n    log INFO "Замените эту функцию целиком функцией своей карточки"\n    return 2\n}',function)
        assert 'Замените эту функцию' not in code
        config=f'DB="{database}"\nDB_HOST="127.0.0.1"\nDB_PORT="5432"\nCLIENT="'+('psql' if pg else client)+'"\nDUMP="'+('pg_dump' if pg else dump)+'"\nAUTH="'+(f'/tmp/pm07-auth-{n}' if pg else '/tmp/pm07-auth/admin.cnf')+'"\nAS_OF="2026-11-04"\nCHECK_TIME="2026-11-04 09:30:00"\nKEEP_DAYS=7\nERROR_LOG="$WORK/error-input.log"\nDB_SERVICE="mariadb"\n'
        (folder/'config.env').write_text(config,encoding='utf-8',newline='\n')
        (folder/'run.sh').write_text(code,encoding='utf-8',newline='\n')
        if n=='01':shell(f'touch {base}/backups/{database}_old.sql {base}/backups/foreign_old.sql; touch -d "10 days ago" {base}/backups/*old.sql\n')
        if n=='05':shell(f'cp {backup} {base}/backups/{database}_fresh.sql; cp {backup} {base}/backups/{database}_old.sql; gzip {base}/backups/{database}_old.sql; touch -d "16 days ago" {base}/backups/{database}_old.sql.gz\n')
        if n=='17':(folder/'error-input.log').write_text('INFO ready\nERROR example for practice\n',encoding='utf-8')
        success,output,_=shell(f'bash {base}/run.sh\n')
        (folder/'run-console.txt').write_text(output,encoding='utf-8')
        if n in ['11','12','29']:
            table={'11':'orders','12':'tickets','29':'trips'}[n]
            assert query(f'SELECT COUNT(*) FROM {table};',database,'admin')=='3'
            if n in ['11','29']:
                assert query(f'SELECT COUNT(*) FROM {table}_archive;',database,'admin')=='1'
                shell(f'bash {base}/run.sh\n');assert query(f'SELECT COUNT(*) FROM {table}_archive;',database,'admin')=='1'
        if n=='01':assert not (folder/f'backups/{database}_old.sql').exists() and (folder/'backups/foreign_old.sql').exists()
        if n=='05':
            assert (folder/f'backups/{database}_fresh.sql.gz').exists() and not (folder/f'backups/{database}_old.sql.gz').exists()
            shell(f'gzip -t {base}/backups/{database}_fresh.sql.gz\n')
        if n=='09':assert 'count=1' in (folder/'out/fresh_bookings.log').read_text()
        if n=='10':assert 'items' in (folder/'out/idle_tables.log').read_text()
        if n=='26':assert '2' in (folder/'out/top_dishes.txt').read_text()
        # Failure changes a copied input/config only. File-only operations have
        # their own missing input, as the teaching card requires.
        test_code=code.replace('config.env','config-test.env')
        test_config=config.replace(f'DB="{database}"','DB="pm07_missing_test"')
        if n=='02':test_code=test_code.replace('df -Pk "$WORK"','df -Pk "$WORK/missing-input"')
        if n=='05':test_code=test_code.replace('find "$WORK/backups"','find "$WORK/missing-backups"')
        if n=='17':test_config=test_config.replace('ERROR_LOG="$WORK/error-input.log"','ERROR_LOG="$WORK/missing.log"')
        (folder/'run-test.sh').write_text(test_code,encoding='utf-8',newline='\n')
        (folder/'config-test.env').write_text(test_config,encoding='utf-8',newline='\n')
        rc,error,_=shell(f'bash {base}/run-test.sh\n',allowed=True)
        assert rc!=0,(n,'Expected failing copied script',error)
        logs=(folder/'logs/run.log').read_text(encoding='utf-8')
        assert '[INFO] END result=OK' in logs and '[ERROR]' in logs,(n,logs)
        entry.update(manual_exit=success,negative_exit=rc)
    events.append(entry)
    print('PASS inputs, independent logins, rights, separate restore'+(', printed Bash and failure' if 'manual_exit' in entry else '; script remains separate')+': '+n,flush=True)
    record={'timestamp':datetime.datetime.now().isoformat(),'container':name,'image':image,'engine_version':query('SELECT version();'),'os':shell('cat /etc/os-release\n')[1],'events':events,'remaining_checks':gaps,'scheduler_tested':False,'other_os_certified':False}
    (WORK/'result.json').write_text(json.dumps(record,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Completed',engine,'; remaining scopes:',len(gaps),flush=True)
