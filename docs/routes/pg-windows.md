# PostgreSQL 16 · Windows

## Прежде чем копировать команды

### Работайте только в этом маршруте

ОС и СУБД должны совпадать с карточкой варианта. Здесь все команды ОС выполняются в: **Windows PowerShell на учебной Windows-машине**. SQL выполняется отдельно в клиенте **psql.exe**. Адрес клиента на хосте и адрес внутри VM могут различаться: перепишите оба из паспорта учебной среды. Настройка сервера и канал доступа уже подготовлены; установка из другого маршрута не выполняется.

### Заполните подстановки

| В образце | В своём варианте |
| --- | --- |
| pm07_demo | pm07_vNN — имя исходной базы |
| pm07_demo_restore | pm07_vNN_restore — отдельная проверочная база |
| devices, locations, checks | Три имени таблиц из своей карточки |
| input.sql | Скачанный SQL своего варианта, сохранённый под этим рабочим именем |
| ADMIN_PASSWORD, APP_PASSWORD, READ_PASSWORD | Собственные учебные пароли, подставляемые до выполнения SQL |

В SQL сохраняйте обозначение имени таблицы: двойные кавычки вокруг имени для PostgreSQL. Заменяется имя внутри них. Это важно, например, для исходной таблицы groups.

Во всех блоках SQL сначала замените длинное имя pm07_demo_restore, затем pm07_demo. Сохраняйте каждый изменённый блок в текстовом редакторе до запуска. Пароль в SQL-строке заключён в одинарные кавычки; внутреннюю одинарную кавычку удваивают. При подготовке профиля клиента учитывайте его собственное экранирование. Пароли не помещаются в снимки отчёта.

## 1. Подключение и исходные данные

### Подготовьте рабочую папку

```powershell
New-Item -ItemType Directory -Force C:\Practice07 | Out-Null
Set-Location C:\Practice07
```

Сохраните сюда SQL своей карточки как input.sql. Работа начинается с готовой схемы, а не с повторной разработки таблиц. Разбор использует pm07_demo; ваша сдаваемая база с самого начала называется по своему номеру.

### Сначала задайте путь клиента

В PowerShell задайте $Client перед его первым использованием:

```powershell
$Client = 'C:\Program Files\PostgreSQL\16\bin\psql.exe'
$Dump = 'C:\Program Files\PostgreSQL\16\bin\pg_dump.exe'
$Restore = 'C:\Program Files\PostgreSQL\16\bin\pg_restore.exe'
Test-Path -LiteralPath $Client
```

Ожидается True; если пути паспорта отличаются, сначала подставьте их. Команда входа начального администратора: & $Client -h 127.0.0.1 -p 5432 -U postgres -d postgres.

### Войдите начальным администратором

Откройте psql из выданного каталога клиента. Подключитесь к базе postgres от начальной роли postgres; если роль называется иначе, используйте паспорт. Пример параметров: host 127.0.0.1, port 5432. После запроса введите пароль интерактивно. В клиенте выполните следующий SQL после подстановок:

```sql
SELECT version(), current_user, current_database();
CREATE ROLE admin LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE PASSWORD 'ADMIN_PASSWORD';
CREATE ROLE app_user LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE PASSWORD 'APP_PASSWORD';
CREATE ROLE readonly LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE PASSWORD 'READ_PASSWORD';
CREATE DATABASE pm07_demo OWNER admin TEMPLATE template0 ENCODING 'UTF8';
CREATE DATABASE pm07_demo_restore OWNER admin TEMPLATE template0 ENCODING 'UTF8';
```

### Загрузите выданный SQL от admin

Завершите текущее соединение командой \q. Подключитесь admin к своей исходной базе. Пример команды в терминале ОС:

```powershell
& $Client -h 127.0.0.1 -p 5432 -U admin -d pm07_demo -v ON_ERROR_STOP=1
```

Перед этой командой задайте $Client полным путём к psql.exe из паспорта, например C:\Program Files\PostgreSQL\16\bin\psql.exe. Переменная с примерным несуществующим путём не заменяет установленную утилиту.

В приглашении psql выполните `\i` и полный путь к input.sql. На Windows используйте путь C:/Practice07/input.sql; на Linux — путь, показанный pwd, с /input.sql в конце. Затем выполните:

```sql
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
GRANT USAGE ON SCHEMA public TO app_user, readonly;
GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA public TO app_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly;
GRANT USAGE,SELECT ON ALL SEQUENCES IN SCHEMA public TO app_user;
ALTER DEFAULT PRIVILEGES FOR ROLE admin IN SCHEMA public
  GRANT SELECT,INSERT,UPDATE,DELETE ON TABLES TO app_user;
ALTER DEFAULT PRIVILEGES FOR ROLE admin IN SCHEMA public
  GRANT SELECT ON TABLES TO readonly;
```

Таблицы создаёт admin, поэтому и правила для будущих таблиц заданы для этой роли. CREATEROLE и SUPERUSER ему для операций своей базы не выдаются. Служебный postgresql.service иногда показывает active (exited); работоспособность конкретного кластера проверяется реальным подключением и SELECT version(), а не одной строкой агрегирующей службы.

### Проверьте исходный набор и графический клиент

Подключитесь к исходной базе как admin и выполните для каждой своей предметной таблицы (в примере devices):

```sql
SELECT COUNT(*) AS row_count, SUM(id) AS id_sum, SUM(amount) AS amount_sum FROM "devices";
```

Ожидаются 4, 10, 100. Сохраните три результата с именами таблиц. access_probe содержит id=1 и value=10 и в эти три предметных результата не входит.

На хосте откройте выданный графический клиент. В DBeaver: «База данных» (Database) → «Новое соединение» (New Database Connection) → драйвер своей СУБД → «Далее» (Next); введите адрес и порт проброса **из паспорта хоста**, имя исходной базы, readonly и его пароль → «Тест соединения» (Test Connection) → «Готово» (Finish). Если отключено «Сохранять пароль», введите пароль в появившемся отдельном окне авторизации; поле пароля в основной форме при этом недоступно. Если клиент просит драйвер, используйте выданный заранее настроенный клиент; загрузка неизвестного драйвера не заменяет подготовку среды. Откройте «Редактор SQL» (SQL Editor) → «Open SQL console» (Ctrl+Alt+Enter) и выполните SELECT COUNT(*) для одной своей таблицы. Пошаговый разбор со снимками находится в [общем шаге подключения](../practice/stage1.md). В SSMS аналогично выбираются выданный сервер и SQL Server Authentication с readonly, затем New Query и своя база. Результат должен совпасть с CLI. 127.0.0.1 внутри VM и на хосте означает разные машины; порт из гостевого примера не переносится в хост автоматически.

## 2. Три отдельных подключения и права

### Позитивные опыты

Для каждого опыта создайте новое соединение и проверьте имя текущей роли. Под admin выполните создание и удаление только учебной check_admin. Под app_user измените отдельную строку access_probe и затем верните её в исходное состояние:

```sql
CREATE TABLE check_admin (id int);
DROP TABLE check_admin;
```

```sql
INSERT INTO access_probe(id,value) VALUES(9001,20);
UPDATE access_probe SET value=30 WHERE id=9001;
SELECT * FROM access_probe WHERE id=9001;
DELETE FROM access_probe WHERE id=9001;
```

Первый блок — только admin; второй — только app_user. Затем readonly читает SELECT * FROM access_probe. После опыта остаётся ровно исходная строка id=1, value=10.

### Негативные опыты

Под readonly отдельно проверьте INSERT в access_probe и DELETE строки id=1. Под app_user отдельно проверьте CREATE TABLE forbidden_app(id int). Ожидается отказ в соответствующем праве. Если действие неожиданно выполнено, зафиксируйте результат и исправьте выдачу прав из начального административного подключения; не объявляйте такую проверку успешной.

Под app_user проверьте создание серверной учётной записи командой именно этой СУБД:

```sql
CREATE ROLE forbidden_probe LOGIN;
```

Нужен отказ в полномочиях, а не ошибка пароля, синтаксиса или уже существующего имени. Не проверяйте запрет командой другого движка. Списки системных схем не обязаны выглядеть одинаково; вывод делается по нужной операции.

## 3. Ручная копия и отдельное восстановление

### Сохраните исходные значения

После проверки прав повторите COUNT(*), SUM(id), SUM(amount) по трём таблицам и сохраните вывод как rows-before.txt. Зафиксируйте точное имя исходной базы. Первый опыт не требует повреждения этой базы.

### Создайте архив и восстановите пустую копию

В терминале ОС выполните pg_dump от admin с запросом пароля. Полные пути Windows к pg_dump.exe и pg_restore.exe берутся из того же установленного комплекта, что и psql. В примере показаны аргументы утилит; на Windows перед путём в кавычках ставится оператор &.

```powershell
& $Dump -h 127.0.0.1 -p 5432 -U admin -d pm07_demo -Fc -f manual.dump
if ($LASTEXITCODE -ne 0) { throw 'pg_dump failed' }
& $Restore --list manual.dump
& $Restore -h 127.0.0.1 -p 5432 -U admin -d pm07_demo_restore --no-owner --no-privileges --exit-on-error manual.dump
if ($LASTEXITCODE -ne 0) { throw 'pg_restore failed' }
```

Восстановление направлено в уже созданную пустую _restore; --create не используется. Вход в другую базу того же сервера выполняется отдельным подключением. Запись вида INSERT INTO исходная.public.table SELECT FROM другая_база.public.table не является переносом между базами PostgreSQL.

Посчитайте SHA-256 manual.dump: sha256sum manual.dump на Linux или Get-FileHash -LiteralPath .\manual.dump -Algorithm SHA256 на Windows. Сохраните значение. Подключитесь к _restore и выполните три контрольных запроса. Список архива не заменяет это сравнение.

### Проверка другого архива

Для нового или частичного архива используйте ещё одну пустую проверочную базу. Войдите начальной ролью postgres к базе postgres и выполните после замены имени:

```sql
CREATE DATABASE pm07_demo_restore2 OWNER admin TEMPLATE template0 ENCODING 'UTF8';
```

Первую _restore и исходную базу сохраните. Завершите это соединение. В Windows PowerShell восстановите новый архив от admin; его точный путь заменяет manual.dump:

```powershell
& $Restore -h 127.0.0.1 -p 5432 -U admin -d pm07_demo_restore2 --no-owner --no-privileges --exit-on-error manual.dump
if ($LASTEXITCODE -ne 0) { throw 'pg_restore failed' }
```

При повторе начальный администратор выделяет следующее уникальное пустое имя. Имя _restore2 используется только как назначение; непустая база без объяснения не очищается. Для частичной копии сравните только включённые таблицы и подтвердите отсутствие остальных.

### Сверьте три предметные таблицы

Запишите rows-after.txt рядом с rows-before.txt. Сопоставьте имя таблицы, количество строк, сумму id и сумму amount; проверьте также одну конкретную запись по id=1. При различии проверьте выбранный файл и его время, список таблиц, базу назначения и первое сообщение восстановления. Только после совпадения переходите к расписанию.

## 4. Операция своего варианта

### Как сохранить файлы без лишнего расширения

Откройте Блокнот. Для config.ps1 и run.ps1 выберите «Сохранить как» → «Все файлы», точное имя и кодировку UTF-8 с BOM, совместимую с Windows PowerShell 5.1. Проводник → Вид → Расширения имён файлов позволяет проверить, что не получилось run.ps1.txt. Каждый блок заменяет файл целиком; не копируйте в него тройные обратные кавычки из оформления.

Для профиля создайте папку C:\Practice07\auth командой New-Item -ItemType Directory -Force. Откройте в Блокноте точный файл, указанный ниже, сохраните как «Все файлы» и подставьте свои значения. Парольный профиль — обычный закрытый файл, а не часть отчёта.

### Подготовьте параметры и профиль клиента

Создайте config.ps1 в C:\Practice07. Замените NN и пути примерных утилит значениями паспорта. Выполните Test-Path -LiteralPath для каждого пути к exe: ожидается True.

```powershell
$Database = 'pm07_vNN'
$DbHost = '127.0.0.1'
$DbPort = '5432'
$Client = 'C:\Program Files\PostgreSQL\16\bin\psql.exe'
$Dump = 'C:\Program Files\PostgreSQL\16\bin\pg_dump.exe'
$env:PGPASSFILE = Join-Path $Work 'auth\pgpass.conf'
```

В auth/pgpass.conf сохраните host:port:database:admin:свой_пароль. Этот файл принадлежит тому же пользователю Windows, что и задача. Символы : и обратный слеш в значениях экранируются обратным слешем. Права доступа к папке не предоставляются посторонним пользователям. Проверьте подключение psql -w без запроса пароля до создания расписания.

### Сохраните каркас run.ps1

Скопируйте блок целиком. В следующем действии заменяется только Invoke-Task.

```powershell
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$Work = $PSScriptRoot
. (Join-Path $Work 'config.ps1')
foreach ($dir in 'out','backups','logs') {
    New-Item -ItemType Directory -Force -Path (Join-Path $Work $dir) | Out-Null
}
$Log = Join-Path $Work 'logs\run.log'
$Stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
function Write-Log([string]$Level,[string]$Message) {
    "$(Get-Date -Format o) [$Level] $Message" | Add-Content -LiteralPath $Log -Encoding UTF8
}

function Invoke-Db([string]$Query) {
    & $Client -X -w -h $DbHost -p $DbPort -U admin -d $Database -v ON_ERROR_STOP=1 -A -t -c $Query
    if ($LASTEXITCODE -ne 0) { throw "psql exit=$LASTEXITCODE" }
}
function Backup-Db([string]$File) {
    & $Dump -w -h $DbHost -p $DbPort -U admin -d $Database -Fc -f $File
    if ($LASTEXITCODE -ne 0) { throw "pg_dump exit=$LASTEXITCODE" }
}

function Invoke-Task {
    throw 'Замените эту функцию целиком функцией своей карточки'
}
try {
    Write-Log INFO "START db=$Database"
    Invoke-Task
    Write-Log INFO 'END result=OK'
    exit 0
} catch {
    Write-Log ERROR $_.Exception.Message
    exit 1
}
```
### Ручной запуск и проверка отказа

Сохраните run.ps1 и config.ps1 в C:\Practice07. Замените Invoke-Task целиком функцией своей карточки. Если каркас ещё содержит throw с указанием заменить функцию, операция не выполнена. Сначала используйте ту же учётную запись Windows, от которой затем будет запускаться задача.

```powershell
powershell.exe -NoProfile -File C:\Practice07\run.ps1
$LASTEXITCODE
Get-Content -LiteralPath C:\Practice07\logs\run.log -Tail 8
Get-ChildItem -LiteralPath C:\Practice07\out,C:\Practice07\backups
```

Ожидаются код 0, новая START/END и результат своей операции. Сохраните отдельные run-test.ps1 и config-test.ps1; в копии скрипта измените только имя подключаемого конфига. В тестовом конфиге задайте несуществующую базу, а для файловой операции — несуществующий исходный путь. Ожидаются ERROR и ненулевой код. Рабочий конфиг с паролем не перезаписывается. Если политика учебной машины запрещает локальные скрипты, используйте выданный разрешённый учебный профиль; общий ExecutionPolicy не меняется ради примера.

### Создание однократной задачи

Откройте Пуск → Планировщик заданий → Создать задачу. На вкладке «Общие» оставьте ту же учётную запись Windows, которая прошла ручную проверку. Для учебного опыта выберите выполнение при входе этого пользователя в систему; SYSTEM не подставляется вместо него.

На вкладке «Триггеры» нажмите «Создать», выберите «По расписанию» → «Однократно» и время на несколько минут позже текущего. На вкладке «Действия» выберите «Запуск программы» и заполните поля раздельно:

| Поле | Значение |
| --- | --- |
| Программа | C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe |
| Аргументы | -NoProfile -File C:\Practice07\run.ps1 |
| Рабочая папка | C:\Practice07 |

Сохраните задачу с именем PM07_VNN, заменив NN номером. Запишите назначенное время и дождитесь его. В свойствах задачи посмотрите время последнего запуска и результат; в журнале скрипта должны появиться новые строки, а в out/backups — результат нужной операции. Кнопка «Выполнить» проверяет действие вручную, но не наступление триггера.

### Постоянная периодичность

В существующей задаче замените однократный триггер ежедневным, еженедельным или другим из своей карточки. Сохраните задачу и её XML через «Экспорт». Факт выполнения подтверждается вместе: временем запуска, кодом, новой записью скрипта и результатом. Код 0 при отсутствии ожидаемого файла или отчёта означает, что проверка ещё не завершена.

## Итог выбранного маршрута

В своей карточке найдите функцию операции и её обязательный опыт. Выполните только её, добавьте выбранное индивидуальное дополнение, затем заполните журнал: подключение, права, ручная копия, отдельное восстановление, ручной запуск, контролируемый отказ и действительный запуск планировщика.

Сдаваемая инструкция своего репозитория позволяет повторить запуск с выданными параметрами без пересоздания производственной модели и без чтения другого маршрута. Снимки и результаты отчёта принадлежат своей работе; приведённые ожидаемые значения не заменяют наблюдения.
