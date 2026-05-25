# Этап 4. Автоматизация рутинных операций

## Что значит «автоматизировать»

Ручной бэкап раз в день работает только пока администратор не забыл. Реальная служба требует, чтобы рутинные операции выполнялись:

- **по расписанию** — без участия человека;
- **с журналированием** — каждое выполнение оставляет след;
- **с проверкой результата** — успешно или с ошибкой, какой;
- **с предсказуемым окружением** — те же файлы, тот же путь, та же учётка.

Скрипт автоматизации — это исполняемый файл, в котором собрана последовательность команд, и который запускается **планировщиком**.

## Что подходит для учебной автоматизации

| Операция | Зачем автоматизировать |
|----------|------------------------|
| Резервное копирование | Не зависит от внимания администратора |
| Ротация старых бэкапов | Диск не переполняется |
| Проверка свободного места | Раннее предупреждение |
| Проверка статуса службы | Если служба упала — узнать сразу |
| Сбор статистики | Ежедневный отчёт, тренды |
| Очистка временных таблиц | Производительность |
| Запуск `VACUUM` / `OPTIMIZE` | Поддержка состояния БД |

В учебной практике достаточно **одного** скрипта по варианту.

## Какой язык выбрать

| ОС | Стандарт |
|----|----------|
| Linux (Ubuntu/Debian) | Bash |
| Windows Server | PowerShell |

Для обоих случаев действуют одинаковые требования: читаемость, обработка ошибок, журналирование, конфигурируемость.

## Структура хорошего скрипта

Любой скрипт автоматизации состоит из шести блоков:

1. **Заголовок** — что делает, версия, автор.
2. **Параметры** — все «настраиваемые» значения в переменных вверху файла.
3. **Подготовка окружения** — создание каталогов, проверка прав.
4. **Полезная работа** — основные команды.
5. **Проверка результата** — анализ кодов возврата.
6. **Журналирование** — запись результата.

## Шаблон Bash-скрипта

```bash
#!/usr/bin/env bash
# backup.sh — ежедневный логический бэкап MySQL с ротацией

set -euo pipefail

DB_HOST="${DB_HOST:-127.0.0.1}"
DB_USER="${DB_USER:-admin}"
DB_NAME="${DB_NAME:-library}"
BACKUP_DIR="${BACKUP_DIR:-/var/backups/db}"
KEEP_DAYS="${KEEP_DAYS:-7}"

mkdir -p "${BACKUP_DIR}"

ts="$(date +'%Y-%m-%d_%H-%M-%S')"
file="${BACKUP_DIR}/${DB_NAME}_${ts}.sql.gz"
log="${BACKUP_DIR}/backup.log"

log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') [$1] $2" >> "${log}"
}

log INFO "Старт бэкапа базы ${DB_NAME}"

if mysqldump -h "${DB_HOST}" -u "${DB_USER}" "${DB_NAME}" 2>>"${log}" | gzip > "${file}"; then
    size=$(stat -c%s "${file}")
    log INFO "Бэкап готов: ${file} (${size} байт)"
else
    log ERROR "Бэкап завершился с ошибкой"
    exit 1
fi

# Ротация: удалить файлы старше KEEP_DAYS дней
removed=$(find "${BACKUP_DIR}" -name "${DB_NAME}_*.sql.gz" -mtime +${KEEP_DAYS} -print -delete | wc -l)
log INFO "Удалено старых бэкапов: ${removed}"
log INFO "Завершено"
```

Запуск:

```bash
chmod +x /usr/local/bin/backup.sh
/usr/local/bin/backup.sh
tail /var/backups/db/backup.log
```

### Что важно в шаблоне

| Приём | Зачем |
|-------|-------|
| `#!/usr/bin/env bash` | Использует bash, найденный по `PATH`, а не жёсткий путь |
| `set -euo pipefail` | Останов при ошибке, неинициализированной переменной, неудачной команде в пайпе |
| `${VAR:-default}` | Значение по умолчанию, если переменной нет в окружении |
| Функция `log` | Единый формат и место записи журналом |
| Проверка `if ... ; then ... else exit 1; fi` | Реакция на провал команды |
| `mtime +N` в `find` | Ротация без сторонних утилит |

## Шаблон PowerShell-скрипта

```powershell
# backup.ps1 — ежедневный BACKUP DATABASE с ротацией

param(
    [string]$ServerInstance = ".\SQLEXPRESS",
    [string]$Database       = "Library",
    [string]$BackupDir      = "D:\Backups",
    [int]   $KeepDays       = 7
)

$ErrorActionPreference = "Stop"
$ts   = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$file = Join-Path $BackupDir "$($Database)_$ts.bak"
$log  = Join-Path $BackupDir "backup.log"

function Write-Log {
    param([string]$Level, [string]$Message)
    "{0} [{1}] {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Level, $Message |
        Add-Content -Path $log
}

if (-not (Test-Path $BackupDir)) { New-Item -ItemType Directory -Path $BackupDir | Out-Null }

Write-Log INFO "Старт бэкапа базы $Database"

try {
    Invoke-Sqlcmd -ServerInstance $ServerInstance -Query @"
BACKUP DATABASE [$Database]
TO DISK = '$file'
WITH INIT, COMPRESSION;
"@
    $size = (Get-Item $file).Length
    Write-Log INFO "Бэкап готов: $file ($size байт)"
} catch {
    Write-Log ERROR "Ошибка бэкапа: $($_.Exception.Message)"
    exit 1
}

# Ротация
$removed = Get-ChildItem $BackupDir -Filter "$Database`_*.bak" |
    Where-Object { $_.CreationTime -lt (Get-Date).AddDays(-$KeepDays) }
$removed | Remove-Item -Force
Write-Log INFO "Удалено старых бэкапов: $($removed.Count)"
Write-Log INFO "Завершено"
```

Запуск:

```powershell
.\backup.ps1
Get-Content D:\Backups\backup.log -Tail 5
```

## Учётные данные в скриптах

Пароль **не зашивается в текст скрипта**. Три приемлемых способа:

| Способ | Linux | Windows |
|--------|-------|---------|
| Файл `~/.my.cnf` (MySQL) | `chmod 600 ~/.my.cnf` | — |
| `~/.pgpass` (PostgreSQL) | `chmod 600 ~/.pgpass` | `%APPDATA%\postgresql\pgpass.conf` |
| Переменные окружения | `export DB_PASS=...` в `crontab` | в задаче планировщика |
| Зашифрованный credential | — | `Get-Credential` + `Export-CliXml` |

Пример `~/.my.cnf`:

```ini
[client]
user=admin
password=Strong!Pwd1
```

После этого `mysqldump library` подхватит логин и пароль из файла, а в скрипте останется только команда.

## Расписание: Linux (cron)

`crontab -e` открывает редактор. Каждая строка — задание.

```cron
# мин   час   день   мес   день_нед   команда
0       3     *      *     *          /usr/local/bin/backup.sh
*/15    *     *      *     *          /usr/local/bin/check_disk.sh
0       2     *      *     0          /usr/local/bin/weekly_optimize.sh
```

Проверки:

```bash
crontab -l                       # показать задания
sudo tail -f /var/log/syslog | grep CRON   # увидеть запуск в логах
```

Альтернатива — `systemd timer` (чище, но сложнее в учебной практике).

## Расписание: Windows (Планировщик заданий)

Через PowerShell:

```powershell
$action  = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File C:\Scripts\backup.ps1"

$trigger = New-ScheduledTaskTrigger -Daily -At 3:00am

$principal = New-ScheduledTaskPrincipal `
    -UserId "NT AUTHORITY\SYSTEM" -RunLevel Highest

Register-ScheduledTask -TaskName "DB Backup" `
    -Action $action -Trigger $trigger -Principal $principal `
    -Description "Ежедневный бэкап БД Library"
```

Проверки:

```powershell
Get-ScheduledTask -TaskName "DB Backup"
Get-ScheduledTaskInfo -TaskName "DB Backup"
```

В журнале задачи фиксируется код возврата последнего запуска.

## Журнал автоматизации

В отчёт по практике вкладываются **три** разных журнала:

1. **Журнал самого скрипта** (`backup.log`) — пишется в коде скрипта.
2. **Журнал планировщика** — `/var/log/syslog` (`CRON`) или Event Viewer (Windows).
3. **Журнал администратора** — текстовый файл с одной строкой за действие.

Пример журнала администратора:

```text
2026-05-25 09:10 | INSTALL    | установлен MySQL 8.0.36
2026-05-25 09:30 | CONFIGURE  | bind-address=0.0.0.0; port=3306; UTF-8
2026-05-25 10:15 | USER       | создан admin@localhost (SUPER), app_user@%, readonly@%
2026-05-25 11:20 | BACKUP     | manual mysqldump library, 124 КБ, ok
2026-05-25 12:00 | TEST       | удалена books, восстановлена из backup_2026-05-25_11-20.sql, 248 строк
2026-05-25 14:00 | AUTOMATION | установлен backup.sh, cron 0 3 * * *, KEEP_DAYS=7
2026-05-26 03:00 | RUN        | автозапуск backup.sh: OK, 142 КБ, 21 с
```

## Проверка надёжности

Прежде чем считать скрипт готовым, выполняются четыре проверки:

| Проверка | Как делается |
|----------|--------------|
| Скрипт работает руками | Запустить от того же пользователя, что и в расписании |
| Скрипт работает по расписанию | Поставить ближайшее время; убедиться по логу планировщика |
| Скрипт корректно реагирует на ошибку | Временно сделать пароль неверным — должна быть запись `ERROR`, файл бэкапа не должен появиться |
| Ротация работает | Создать вручную «старые» файлы (`touch -d '-30 days' ...`) и убедиться, что скрипт удалил |

## Типичные ошибки автоматизации

- скрипт работает руками, но не работает в cron: разные переменные окружения, нет `PATH` к `mysqldump` или `psql`;
- бэкап «вроде делается», но файл нулевого размера: команда упала, а `>` всё равно создал пустой файл (поэтому проверяем код возврата и размер);
- пароль в скрипте открытым текстом: показывается во время `ps aux`;
- скрипт не выходит с правильным кодом возврата, и планировщик не видит ошибку;
- журнал пишется только при успехе — об ошибках узнать нельзя.

## Артефакты этапа

К концу этапа в отчёт включаются:

- сам файл скрипта (`backup.sh` или `backup.ps1`);
- образец журнала (`backup.log`) с записями `INFO` и `ERROR`;
- скриншот вывода `crontab -l` / `Get-ScheduledTaskInfo`;
- две строки журнала администратора: установка скрипта и первый автозапуск;
- описание индивидуальной доработки (расширение из списка в [вариантах](../subject_areas.md));
- готовый отчёт по учебной практике с разделами «Цель», «Что сделано», «Что проверено», «Чему научился».
