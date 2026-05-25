# Этап 3. Резервная копия и восстановление

## Задание

Сделать **полный логический бэкап** рабочей базы данных, проверить целостность файла бэкапа, повредить таблицу (удалить запись или таблицу целиком), восстановить базу из бэкапа, сверить количество строк до и после, зафиксировать всё в журнале.

## Ход работы

Бэкап делается из-под учётной записи `admin`. Файл бэкапа сохраняется в отдельный каталог `~/backups` (или `D:\Backups` на Windows) — **вне** каталога данных СУБД. Для каждого файла бэкапа считается контрольная сумма SHA-256. Затем имитируется «инцидент» (удаление таблицы), и база восстанавливается. Сверка происходит по `COUNT(*)` для каждой таблицы.

## Шаги

### 1. Каталог для бэкапов

```bash
mkdir -p ~/backups
chmod 700 ~/backups
```

```powershell
New-Item -ItemType Directory -Path "D:\Backups" -Force
```

### 2. Бэкап перед инцидентом: MySQL/MariaDB

```bash
TS=$(date +'%Y-%m-%d_%H-%M-%S')
mysqldump -u admin -p \
    --single-transaction \
    --routines --triggers --events \
    library > ~/backups/library_${TS}.sql

ls -lh ~/backups/
head -30 ~/backups/library_${TS}.sql
grep -c "INSERT INTO" ~/backups/library_${TS}.sql
sha256sum ~/backups/library_${TS}.sql | tee ~/backups/library_${TS}.sql.sha256
```

Откройте файл редактором и убедитесь, что внутри есть:

- `CREATE DATABASE` (если использовали `--databases`);
- `CREATE TABLE authors`, `CREATE TABLE books`;
- `INSERT INTO authors`, `INSERT INTO books`.

### 3. Бэкап перед инцидентом: PostgreSQL

```bash
TS=$(date +'%Y-%m-%d_%H-%M-%S')

# Текстовый формат
pg_dump -h 127.0.0.1 -U admin -d library \
    -F p -f ~/backups/library_${TS}.sql

# Custom-архив с компрессией (рекомендуется)
pg_dump -h 127.0.0.1 -U admin -d library \
    -F c -f ~/backups/library_${TS}.dump

pg_restore --list ~/backups/library_${TS}.dump | head -20
sha256sum ~/backups/library_${TS}.dump | tee ~/backups/library_${TS}.dump.sha256
```

### 4. Бэкап перед инцидентом: MS SQL

В SSMS:

```sql
DECLARE @file NVARCHAR(255) =
    'D:\Backups\Library_' + REPLACE(CONVERT(VARCHAR, GETDATE(), 120),':','-') + '.bak';

BACKUP DATABASE Library
TO DISK = @file
WITH FORMAT, INIT, COMPRESSION,
     NAME = N'Library full backup';

RESTORE VERIFYONLY FROM DISK = @file;
```

В PowerShell-аналоге:

```powershell
$ts = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$file = "D:\Backups\Library_$ts.bak"
Invoke-Sqlcmd -ServerInstance ".\SQLEXPRESS" -Query @"
BACKUP DATABASE Library
TO DISK = '$file'
WITH INIT, COMPRESSION;
"@
Get-FileHash $file -Algorithm SHA256 |
    Select-Object Hash, Path |
    Tee-Object -FilePath "$file.sha256.txt"
```

### 5. Подсчёт строк до инцидента

В клиенте СУБД выполните и сохраните вывод:

```sql
SELECT 'authors' AS name, COUNT(*) AS rows FROM authors
UNION ALL
SELECT 'books',   COUNT(*) FROM books;
```

Сохраните результат в файл `rows_before.txt`.

### 6. Имитация инцидента

Под `admin` выполните **одно** из:

```sql
-- Вариант A: удаление одной таблицы
DROP TABLE books;

-- Вариант B: массовое удаление
DELETE FROM books;
```

Подтвердите, что таблица потерялась:

```sql
SELECT * FROM books;                    -- ERROR: table doesn't exist (или 0 rows)
```

Запишите в журнал, что именно сделали и в какое время.

### 7. Восстановление: MySQL/MariaDB

Создайте «карантинную» БД для проверки:

```sql
CREATE DATABASE library_restore CHARACTER SET utf8mb4;
```

Восстановите дамп в неё:

```bash
mysql -u admin -p library_restore < ~/backups/library_2026-05-25_*.sql
```

Сверьте структуру и количество строк:

```sql
USE library_restore;
SELECT COUNT(*) FROM books;
SELECT COUNT(*) FROM authors;
```

Если совпадает с `rows_before.txt`, перенесите данные обратно в `library`:

```sql
USE library;
CREATE TABLE IF NOT EXISTS books LIKE library_restore.books;
INSERT INTO books SELECT * FROM library_restore.books;
```

Или просто переименуйте таблицы / БД, если допустимо «потерять» текущее состояние.

### 8. Восстановление: PostgreSQL

```bash
psql -h 127.0.0.1 -U admin -d postgres -c "CREATE DATABASE library_restore;"

pg_restore -h 127.0.0.1 -U admin -d library_restore \
    --clean --if-exists ~/backups/library_2026-05-25_*.dump
```

Сверка:

```sql
\connect library_restore
SELECT COUNT(*) FROM books;
SELECT COUNT(*) FROM authors;
```

При совпадении — перенос данных в `library`:

```sql
INSERT INTO library.public.books
SELECT * FROM library_restore.public.books;
```

### 9. Восстановление: MS SQL

```sql
USE master;
ALTER DATABASE Library SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

RESTORE DATABASE Library
FROM DISK = N'D:\Backups\Library_2026-05-25_<точная_метка>.bak'
WITH REPLACE, RECOVERY;

ALTER DATABASE Library SET MULTI_USER;

USE Library;
SELECT COUNT(*) FROM dbo.Books;
```

### 10. Сверка результата

В сводном файле `rows_after.txt` запишите количество строк после восстановления. Сопоставьте с `rows_before.txt`:

```text
Таблица   | До | После | Совпадает
authors   |  2 |    2  |   да
books     |  2 |    2  |   да
```

Если число строк после восстановления **меньше**, чем до инцидента, бэкап оказался устаревшим — нужно увеличить частоту автоматических бэкапов на следующем этапе.

### 11. Проверка SHA-256

```bash
sha256sum -c ~/backups/library_2026-05-25_*.sql.sha256
```

```powershell
$expected = (Get-Content "D:\Backups\Library_$ts.bak.sha256.txt").Split()[0]
$actual   = (Get-FileHash "D:\Backups\Library_$ts.bak").Hash
if ($expected -eq $actual) { "OK" } else { "MISMATCH" }
```

Совпадение хешей подтверждает: файл бэкапа не был повреждён между снятием и восстановлением.

### 12. Записи в журнал

```text
2026-05-25 11:20 | BACKUP     | mysqldump library → backup_2026-05-25_11-20.sql (124 КБ)
2026-05-25 11:22 | CHECKSUM   | SHA-256 = a7f8...c2c4
2026-05-25 11:40 | INCIDENT   | DROP TABLE books — таблица удалена
2026-05-25 11:45 | RESTORE    | в library_restore из backup_2026-05-25_11-20.sql; 248 строк
2026-05-25 11:50 | VERIFY     | rows_before == rows_after — данные совпадают
```

## Контрольные проверки этапа

- [ ] Бэкап-файл существует и размер > 0.
- [ ] Файл `.sha256` создан рядом с бэкапом.
- [ ] В дампе видны `CREATE TABLE` и `INSERT INTO`.
- [ ] После «инцидента» таблица недоступна.
- [ ] Восстановление из бэкапа прошло без ошибок.
- [ ] `COUNT(*)` после восстановления совпадает с `COUNT(*)` до инцидента.
- [ ] SHA-256 файла бэкапа подтверждён повторной проверкой.
- [ ] В журнале администратора 5 новых записей.

## Артефакты этапа

| Артефакт | Где взять |
|----------|-----------|
| Файл бэкапа | `~/backups/library_*.sql` / `*.dump` / `Library_*.bak` |
| Файл SHA-256 | `library_*.sql.sha256` / `Library_*.bak.sha256.txt` |
| `rows_before.txt`, `rows_after.txt` | Вывод `SELECT COUNT(*)` |
| Скриншот «инцидента» и сообщения об ошибке | CLI/GUI |
| Скриншот успешного восстановления | CLI/GUI |
| Журнал администратора | 5 новых строк за этап |
