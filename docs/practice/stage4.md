# Этап 4. Скрипт автоматизации и расписание

## Задание

Написать скрипт автоматизации **той задачи, которая указана в варианте** (см. [список вариантов](../subject_areas.md), последняя колонка). Скрипт читает параметры из переменных, пишет журнал в отдельный файл и корректно реагирует на ошибки. Поставить скрипт на расписание — `cron` (Linux) или Планировщик заданий (Windows). Убедиться, что **минимум один автоматический запуск прошёл успешно** и оставил запись в журнале.

## Ход работы

В отдельной папке `/usr/local/bin` (Linux) или `C:\Scripts` (Windows) создаётся файл скрипта. В скрипте — заголовок, переменные, проверки, основной блок, журналирование. Учётные данные СУБД выносятся в `~/.my.cnf` / `~/.pgpass` / Windows Credential Manager. Расписание ставится на ближайшее время для проверки, затем переключается на «боевое» значение (например, ежедневно в 03:00).

## Шаги

### 1. Хранение учётных данных вне скрипта

**MySQL / MariaDB** — файл `~/.my.cnf`:

```ini
[client]
user=admin
password=Strong!Pwd1
host=127.0.0.1
```

```bash
chmod 600 ~/.my.cnf
mysql                       # подключение без `-u` и `-p`
```

**PostgreSQL** — файл `~/.pgpass`:

```text
127.0.0.1:5432:library:admin:Strong!Pwd1
```

```bash
chmod 600 ~/.pgpass
psql -h 127.0.0.1 -U admin -d library   # без запроса пароля
```

**MS SQL Server** — `Get-Credential` с сохранением в зашифрованный XML:

```powershell
Get-Credential | Export-Clixml -Path "C:\Scripts\db.cred.xml"
```

```powershell
$cred = Import-Clixml "C:\Scripts\db.cred.xml"
Invoke-Sqlcmd -ServerInstance ".\SQLEXPRESS" -Credential $cred -Query "SELECT 1"
```

### 2. Скрипт для Linux (Bash)

Создайте `/usr/local/bin/backup.sh`. Пример для **варианта 1** (`mysqldump` с ротацией 7 дней) — для своего варианта подставьте свою команду.

```bash
sudo tee /usr/local/bin/backup.sh > /dev/null <<'EOF'
#!/usr/bin/env bash
# backup.sh — ежедневный логический бэкап БД + ротация
set -euo pipefail

DB_HOST="${DB_HOST:-127.0.0.1}"
DB_NAME="${DB_NAME:-library}"
BACKUP_DIR="${BACKUP_DIR:-/var/backups/db}"
KEEP_DAYS="${KEEP_DAYS:-7}"

mkdir -p "${BACKUP_DIR}"
ts="$(date +'%Y-%m-%d_%H-%M-%S')"
file="${BACKUP_DIR}/${DB_NAME}_${ts}.sql.gz"
log="${BACKUP_DIR}/backup.log"

log() { echo "$(date +'%Y-%m-%d %H:%M:%S') [$1] $2" >> "${log}"; }

log INFO "Старт бэкапа базы ${DB_NAME}"
start=$(date +%s)

if mysqldump --defaults-file=/root/.my.cnf -h "${DB_HOST}" "${DB_NAME}" 2>>"${log}" | gzip > "${file}"; then
    size=$(stat -c%s "${file}")
    sha256=$(sha256sum "${file}" | awk '{print $1}')
    echo "${sha256}  ${file}" > "${file}.sha256"
    log INFO "OK ${file} size=${size} sha=${sha256:0:12}..."
else
    log ERROR "Сбой mysqldump"
    exit 1
fi

removed=$(find "${BACKUP_DIR}" -name "${DB_NAME}_*.sql.gz" -mtime +"${KEEP_DAYS}" -print -delete | wc -l)
log INFO "Удалено старых бэкапов: ${removed}"

elapsed=$(( $(date +%s) - start ))
log INFO "Завершено за ${elapsed} c"
EOF

sudo chmod 750 /usr/local/bin/backup.sh
sudo chown root:root /usr/local/bin/backup.sh
```

Тестовый запуск **руками**:

```bash
sudo /usr/local/bin/backup.sh
sudo tail /var/backups/db/backup.log
ls -lh /var/backups/db/
```

### 3. Скрипт для Windows (PowerShell)

Создайте `C:\Scripts\backup.ps1`. Пример для **варианта 18** (`BACKUP DATABASE` в MS SQL Express).

```powershell
@'
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
$start = Get-Date

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
WITH INIT, COMPRESSION, NAME = N'$Database full backup';
"@
    $size = (Get-Item $file).Length
    $hash = (Get-FileHash $file -Algorithm SHA256).Hash
    "$hash  $file" | Set-Content "$file.sha256.txt"
    Write-Log INFO ("OK {0} size={1} sha={2}..." -f $file, $size, $hash.Substring(0,12))
} catch {
    Write-Log ERROR "Сбой BACKUP DATABASE: $($_.Exception.Message)"
    exit 1
}

$removed = Get-ChildItem $BackupDir -Filter "$Database`_*.bak" |
    Where-Object { $_.CreationTime -lt (Get-Date).AddDays(-$KeepDays) }
$removed | Remove-Item -Force
Write-Log INFO "Удалено старых бэкапов: $($removed.Count)"

$elapsed = (New-TimeSpan -Start $start -End (Get-Date)).TotalSeconds
Write-Log INFO ("Завершено за {0:F1} c" -f $elapsed)
'@ | Set-Content -Path C:\Scripts\backup.ps1 -Encoding UTF8
```

Тестовый запуск:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File C:\Scripts\backup.ps1
Get-Content D:\Backups\backup.log -Tail 5
```

### 4. Имитация ошибки

Чтобы убедиться, что скрипт **корректно реагирует на сбой**, временно повредите учётные данные:

```bash
# Linux: смените пароль в ~/.my.cnf на неверный
echo "[client]
user=admin
password=WRONG" | sudo tee /root/.my.cnf

sudo /usr/local/bin/backup.sh && echo "должен был упасть"
sudo tail /var/backups/db/backup.log
```

В логе должна появиться строка `[ERROR] Сбой mysqldump`, а файл бэкапа **не должен** быть создан (или должен быть нулевого размера и удалён). Восстановите правильный пароль.

### 5. Расписание: Linux (cron)

Откройте редактор crontab от того пользователя, под которым будет работать скрипт. Для бэкапа с правами `root` — `sudo crontab -e`.

Поставьте сначала задание на **ближайшие 2 минуты** для проверки:

```cron
*/2 * * * *   /usr/local/bin/backup.sh
```

Через 3 минуты убедитесь, что:

```bash
ls -lh /var/backups/db/
sudo tail /var/log/syslog | grep CRON
sudo tail /var/backups/db/backup.log
```

После успешной проверки замените расписание на «боевое» — каждый день в 03:00:

```cron
0 3 * * *   /usr/local/bin/backup.sh
```

Сохраните вывод `crontab -l` в файл `crontab.txt` для отчёта.

### 6. Расписание: Windows (Планировщик заданий)

```powershell
$action  = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File C:\Scripts\backup.ps1"

# Ближайший тест
$trigger = New-ScheduledTaskTrigger -Once -At ((Get-Date).AddMinutes(2))

$principal = New-ScheduledTaskPrincipal `
    -UserId "NT AUTHORITY\SYSTEM" -RunLevel Highest

Register-ScheduledTask -TaskName "DB Backup Test" `
    -Action $action -Trigger $trigger -Principal $principal `
    -Description "Тест бэкапа БД"
```

Через 3 минуты:

```powershell
Get-ScheduledTaskInfo -TaskName "DB Backup Test"
Get-Content D:\Backups\backup.log -Tail 5
```

Если `LastTaskResult = 0` и в логе строка `OK ...` — расписание работает. Затем поставьте «боевое» задание на 03:00 каждый день:

```powershell
Unregister-ScheduledTask -TaskName "DB Backup Test" -Confirm:$false

$trigger = New-ScheduledTaskTrigger -Daily -At 3:00am
Register-ScheduledTask -TaskName "DB Backup" `
    -Action $action -Trigger $trigger -Principal $principal `
    -Description "Ежедневный бэкап БД"
```

### 7. Индивидуальная доработка варианта

Из списка [обязательных доработок](../subject_areas.md) (раздел «Обязательная индивидуальная доработка» в конце страницы) выберите одну и реализуйте в своём скрипте. Минимум, который должен оказаться в отчёте:

| Доработка | Что должно появиться в скрипте/логе |
|-----------|-------------------------------------|
| Длительность в мс | Поле `elapsed_ms=...` в каждой записи INFO |
| Проверка кода возврата | Явная проверка `$?` / `$LASTEXITCODE`; выход с `exit 1` при сбое |
| SHA-256 | Файл `*.sha256` рядом с каждым бэкапом + строка хеша в логе |
| Удаление по расширениям | Список расширений из переменной + удаление файлов > N дней |
| `.env` / `config.ini` | Все настройки читаются из файла; скрипт не содержит «зашитых» значений |
| Уровни сообщений | `INFO`, `WARN`, `ERROR` — в логе все три уровня хотя бы один раз |
| Проверка свободного места | Запрос `df -h` / `Get-PSDrive`; если меньше порога — `exit 2` |

### 8. Записи в журнал администратора

```text
2026-05-25 14:00 | AUTOMATION | установлен backup.sh; cron 0 3 * * * KEEP_DAYS=7
2026-05-25 14:02 | TEST_RUN   | запуск вручную; backup_2026-05-25_14-02.sql.gz, ok
2026-05-25 14:05 | NEGATIVE   | подменён пароль; в логе ERROR; бэкапа нет — ожидаемо
2026-05-26 03:00 | AUTO_RUN   | автозапуск cron; backup_2026-05-26_03-00.sql.gz, 142 КБ, 21 c
2026-05-26 09:30 | REVIEW     | прочитан backup.log; ошибок нет; ротация удалила 1 файл
```

### 9. Сборка итогового отчёта

В отчёт по практике входят 4 раздела (по этапам) и общая часть:

| Раздел | Что включить |
|--------|--------------|
| Этап 1 | Скриншоты статуса службы, конфиг, тестовое подключение из CLI и GUI |
| Этап 2 | `users.sql`, `SHOW GRANTS`/`\du`/`sp_helpuser`, журнал из 10 проверок |
| Этап 3 | Файл бэкапа (+ SHA-256), `rows_before.txt`, `rows_after.txt`, скриншот восстановления |
| Этап 4 | Сам скрипт, фрагмент `backup.log` (≥ 5 строк, есть `OK` и `ERROR`), `crontab -l` / `Get-ScheduledTaskInfo`, описание индивидуальной доработки |
| Общая | Полный журнал администратора и краткие выводы (что усвоено) |

## Контрольные проверки этапа

- [ ] Скрипт лежит в системном пути, имеет права на исполнение и владельца `root`/администратора.
- [ ] Учётные данные **не записаны** в текст скрипта.
- [ ] При запуске вручную скрипт завершается с кодом `0` и создаёт файл бэкапа.
- [ ] При искусственной ошибке (неверный пароль) в логе появляется `ERROR` и скрипт выходит с ненулевым кодом.
- [ ] Тестовое расписание (раз в 2 минуты) сработало.
- [ ] Боевое расписание установлено и подтверждено выводом `crontab -l` / `Get-ScheduledTaskInfo`.
- [ ] Реализована индивидуальная доработка варианта.
- [ ] Журнал администратора содержит записи всех 4 этапов.

## Артефакты этапа

| Артефакт | Где взять |
|----------|-----------|
| `backup.sh` или `backup.ps1` | Полный текст скрипта |
| `backup.log` | ≥ 10 строк, есть `INFO` и `ERROR` |
| `crontab.txt` или скриншот окна Планировщика | вывод `crontab -l` / `Get-ScheduledTaskInfo` |
| Файл бэкапа автозапуска | новый файл, появившийся после автоматического запуска |
| Описание доработки | абзац в отчёте по практике |
| Готовый отчёт по практике | итоговый документ со всеми этапами |
