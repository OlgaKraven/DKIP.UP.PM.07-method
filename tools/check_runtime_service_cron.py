"""Check the printed service recipe and a real cron trigger in private Ubuntu 22.04."""
from pathlib import Path
import argparse,datetime,json,re,secrets,subprocess,time

ROOT=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser()
parser.add_argument('--docker',required=True)
parser.add_argument('--collect',action='store_true')
args=parser.parse_args()
WORK=ROOT/'work/runtime/service-cron';WORK.mkdir(parents=True,exist_ok=True)
NAME='pm07-qa-service-cron-20261104'
def docker(*cmd,stdin=None,fail=False):
    p=subprocess.run([args.docker,*map(str,cmd)],input=stdin.encode() if isinstance(stdin,str) else stdin,capture_output=True,timeout=90)
    output=(p.stdout+p.stderr).decode('utf-8',errors='replace').strip()
    if not fail:assert p.returncode==0,output
    return p.returncode,output
def shell(script,fail=False):return docker('exec','-i',NAME,'bash','-s',stdin=script,fail=fail)
def query(sql):return docker('exec','-i',NAME,'mariadb','-uroot','--batch','--raw','--skip-column-names',stdin=sql)[1]
def log():return shell('cat /root/pm07/logs/run.log\n')[1]
def collect():
    record=json.loads((WORK/'registered.json').read_text(encoding='utf-8'))
    logs=log();syslog=shell('cat /var/log/syslog\n')[1]
    assert logs.count('[INFO] END result=OK')>record['success_before_cron'],'Scheduled run is not yet confirmed'
    assert re.search(r'CMD \((?:\[\d+\] )?/bin/bash "\$HOME/pm07/run\.sh"',syslog),'Own cron CMD record is missing'
    assert re.search(r'END \((?:\[\d+\] )?/bin/bash "\$HOME/pm07/run\.sh"',syslog),'Own cron END record is missing'
    assert '[INFO] service started' in logs
    assert query('SELECT COUNT(*) FROM pm07_v06.products;')=='4'
    record.update(collected_at=datetime.datetime.now().astimezone().isoformat(),script_log=logs,scheduler_log=syslog,server_check=query('SELECT VERSION();'),source_rows=query('SELECT COUNT(*),SUM(id),SUM(amount) FROM pm07_v06.products;'),cron_trigger_confirmed=True)
    (WORK/'result.json').write_text(json.dumps(record,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    docker('cp',NAME+':/root/pm07/logs/run.log',WORK/'run.log')
    docker('cp',NAME+':/var/log/syslog',WORK/'scheduler.log')
    print('PASS real cron trigger, source script, previously stopped MariaDB service, live SQL and new log',flush=True)
    return
if args.collect:collect();raise SystemExit

assert docker('ps','-a','--filter',f'name=^/{NAME}$','--format','{{.Names}}')[1]=='','Existing QA container preserved'
docker('run','-d','--name',NAME,'--label','purpose=pm07-method-qa','--mount',f'type=bind,source={WORK},target=/qa','pm07-qa-service-cron:20261104')
for attempt in range(90):
    rc,_=docker('exec',NAME,'mariadb-admin','-uroot','ping','--silent',fail=True)
    if rc==0:break
    time.sleep(1)
else:raise RuntimeError('Private MariaDB did not start')
route=(ROOT/'docs/routes/maria-linux.md').read_text(encoding='utf-8')
areas=(ROOT/'docs/subject_areas.md').read_text(encoding='utf-8')
def blocks(text,lang):return re.findall(r'```'+lang+r'\n(.*?)\n```',text,re.S)
setup=next(b for b in blocks(route,'sql') if "CREATE USER 'admin'" in b).replace('pm07_demo_restore','pm07_v06_restore').replace('pm07_demo','pm07_v06')
pw={role:'Pm07!'+secrets.token_hex(16)+'aQ9' for role in ['admin','app_user','readonly']}
for key,role in [('ADMIN_PASSWORD','admin'),('APP_PASSWORD','app_user'),('READ_PASSWORD','readonly')]:setup=setup.replace(key,pw[role])
query(setup)
query('USE pm07_v06;\n'+(ROOT/'docs/downloads/variant-06.sql').read_text(encoding='utf-8'))
body=re.search(r'^## Вариант 06 · [^\n]+\n(.*?)(?=^## Вариант )',areas,re.M|re.S)[1]
function=blocks(body,'bash')[0]
scaffold=next(b for b in blocks(route,'bash') if '#!/usr/bin/env bash' in b)
scaffold=scaffold.replace('run_task() {\n    log INFO "Замените эту функцию целиком функцией своей карточки"\n    return 2\n}',function)
assert 'Замените эту функцию' not in scaffold
config='DB="pm07_v06"\nCLIENT="mariadb"\nDUMP="mariadb-dump"\nAUTH="$WORK/auth/client.cnf"\nAS_OF="2026-11-04"\nDB_SERVICE="mariadb"\n'
(WORK/'run.sh').write_text(scaffold,encoding='utf-8',newline='\n')
(WORK/'config.env').write_text(config,encoding='utf-8',newline='\n')
(WORK/'client.cnf').write_text('[client]\nuser=admin\npassword='+pw['admin']+'\nhost=127.0.0.1\nport=3306\n',encoding='utf-8')
shell('mkdir -p /root/pm07/auth; cp /qa/run.sh /qa/config.env /root/pm07/; cp /qa/client.cnf /root/pm07/auth/client.cnf; chmod 600 /root/pm07/auth/client.cnf\nbash /root/pm07/run.sh\n')
assert '[INFO] service already active' in log()
shell('/usr/sbin/service mariadb stop\nbash /root/pm07/run.sh\n')
assert '[INFO] service started' in log()
assert query('SELECT COUNT(*) FROM pm07_v06.products;')=='4'
(WORK/'config-test.env').write_text(config.replace('DB_SERVICE="mariadb"','DB_SERVICE="pm07_no_such_service"'),encoding='utf-8',newline='\n')
(WORK/'run-test.sh').write_text(scaffold.replace('config.env','config-test.env'),encoding='utf-8',newline='\n')
shell('cp /qa/run-test.sh /qa/config-test.env /root/pm07/\n')
failure,error=shell('bash /root/pm07/run-test.sh\n',fail=True)
assert failure!=0 and '[ERROR]' in log()
before=log().count('[INFO] END result=OK')
assert shell('crontab -l\n',fail=True)[0]!=0,'Existing root crontab preserved'
cron='SHELL=/bin/bash\n*/2 * * * * /bin/bash "$HOME/pm07/run.sh" >> "$HOME/pm07/logs/cron.log" 2>&1\n'
(WORK/'crontab').write_text(cron,encoding='utf-8',newline='\n')
shell('/usr/sbin/service mariadb stop\ncrontab /qa/crontab\ncrontab -l\n')
record={'registered_at':datetime.datetime.now().astimezone().isoformat(),'container':NAME,'os':shell('cat /etc/os-release\n')[1],'recipe_variant':'06','manual_already_running':True,'manual_start_stopped':True,'negative_exit':failure,'success_before_cron':before,'crontab':cron,'service_stopped_before_trigger':True,'implementation':'actual Ubuntu init script through /usr/sbin/service; cron daemon is PID 1'}
(WORK/'registered.json').write_text(json.dumps(record,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('PASS service running/stopped and negative case. Real cron registered; collect after next even minute.',flush=True)
