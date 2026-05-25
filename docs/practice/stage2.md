# Этап 2. Создание пользователей и проверка прав

## Задание

В уже работающей СУБД создайте три обязательные учётные записи (`admin`, `app_user`, `readonly`) с разными правами на рабочую базу и проверьте, что **каждая учётная запись делает только то, что разрешено**, и не делает того, что запрещено.

## Ход работы

Подключитесь к СУБД под начальным администратором. Создайте трёх пользователей и выдайте им права. Подключитесь поочерёдно под каждой учётной записью и выполните 3 позитивных и 3 негативных сценария. Зафиксируйте результаты в журнале.

## Шаги

### 1. Подготовительная подсказка

Откройте отдельный текстовый файл и подготовьте таблицу для проверочного журнала. Шапка одинакова для всех СУБД:

```text
№ | Учётка   | Сценарий                                 | Ожидание   | Факт
1 | admin    | CREATE TABLE                             | разрешено  |
2 | admin    | CREATE USER                              | разрешено  |
3 | admin    | DROP TABLE                               | разрешено  |
4 | app_user | INSERT INTO books                        | разрешено  |
5 | app_user | DELETE FROM books WHERE id=1             | разрешено  |
6 | app_user | CREATE TABLE temp_x(id INT)              | отклонено  |
7 | app_user | CREATE USER hacker@'%'                   | отклонено  |
8 | readonly | SELECT * FROM books                      | разрешено  |
9 | readonly | INSERT INTO books ...                    | отклонено  |
10| readonly | DROP TABLE books                         | отклонено  |
```

### 2. Создание пользователей: MySQL / MariaDB

Подключитесь под `root`:

```bash
mysql -u root -p
```

Выполните:

```sql
CREATE USER 'admin'@'localhost'    IDENTIFIED BY 'Strong!Pwd1';
CREATE USER 'app_user'@'%'         IDENTIFIED BY 'AppPwd2024';
CREATE USER 'readonly'@'%'         IDENTIFIED BY 'ReadPwd2024';

GRANT ALL PRIVILEGES ON library.* TO 'admin'@'localhost' WITH GRANT OPTION;
GRANT SELECT, INSERT, UPDATE, DELETE ON library.* TO 'app_user'@'%';
GRANT SELECT ON library.* TO 'readonly'@'%';

FLUSH PRIVILEGES;

SHOW GRANTS FOR 'admin'@'localhost';
SHOW GRANTS FOR 'app_user'@'%';
SHOW GRANTS FOR 'readonly'@'%';
```

Сохраните вывод `SHOW GRANTS` в файл `users.sql` рядом со скриптом создания.

### 3. Создание пользователей: PostgreSQL

Подключитесь под `postgres`:

```bash
sudo -u postgres psql
```

Выполните:

```sql
CREATE ROLE admin     LOGIN PASSWORD 'Strong!Pwd1' SUPERUSER;
CREATE ROLE app_user  LOGIN PASSWORD 'AppPwd2024';
CREATE ROLE readonly  LOGIN PASSWORD 'ReadPwd2024';

ALTER DATABASE library OWNER TO admin;

\connect library

GRANT USAGE ON SCHEMA public TO app_user, readonly;

GRANT SELECT, INSERT, UPDATE, DELETE
   ON ALL TABLES IN SCHEMA public TO app_user;

GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
   GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_user;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
   GRANT SELECT ON TABLES TO readonly;

\du
```

Откорректируйте `pg_hba.conf`, чтобы разрешить вход по паролю с хоста:

```text
host    library    admin       0.0.0.0/0    scram-sha-256
host    library    app_user    0.0.0.0/0    scram-sha-256
host    library    readonly    0.0.0.0/0    scram-sha-256
```

```bash
sudo systemctl reload postgresql
```

### 4. Создание пользователей: MS SQL Server

В SSMS подключитесь под `Windows Authentication` к `.\SQLEXPRESS` и выполните:

```sql
USE master;
CREATE LOGIN admin    WITH PASSWORD = 'Strong!Pwd1', CHECK_POLICY = ON;
CREATE LOGIN app_user WITH PASSWORD = 'AppPwd2024';
CREATE LOGIN readonly WITH PASSWORD = 'ReadPwd2024';

USE Library;
CREATE USER admin    FOR LOGIN admin;
CREATE USER app_user FOR LOGIN app_user;
CREATE USER readonly FOR LOGIN readonly;

EXEC sp_addrolemember 'db_owner',       'admin';
EXEC sp_addrolemember 'db_datareader',  'app_user';
EXEC sp_addrolemember 'db_datawriter',  'app_user';
EXEC sp_addrolemember 'db_datareader',  'readonly';
```

В свойствах сервера убедитесь, что включён режим **SQL Server and Windows Authentication mode**, иначе пароли не сработают. После смены режима службу нужно перезапустить.

Проверка прав:

```sql
EXEC sp_helpuser 'app_user';
```

### 5. Проверка позитивных сценариев

Выйдите из клиента и войдите **под `admin`**:

```bash
mysql -u admin -p library                     # MySQL
psql -h 127.0.0.1 -U admin -d library         # PostgreSQL
sqlcmd -S .\SQLEXPRESS -U admin -P "Strong!Pwd1" -d Library      # MS SQL
```

Выполните:

```sql
CREATE TABLE check_admin (id INT);
DROP TABLE check_admin;
```

Войдите **под `app_user`**:

```sql
INSERT INTO books (title, author_id, year) VALUES ('Сорочинская ярмарка', 2, 1832);
UPDATE books SET year = 1832 WHERE title = 'Сорочинская ярмарка';
SELECT * FROM books;
DELETE FROM books WHERE title = 'Сорочинская ярмарка';
```

Войдите **под `readonly`**:

```sql
SELECT * FROM books;
SELECT COUNT(*) FROM books;
```

Все три блока должны выполниться без ошибок.

### 6. Проверка негативных сценариев

**Под `app_user`** должны получиться ошибки:

```sql
CREATE TABLE forbidden_app (id INT);
-- MySQL:  ERROR 1142 (42000): CREATE command denied
-- Postgres: ERROR: permission denied for schema public
-- MS SQL:  Msg 262, Level 14, ...  permission was denied

CREATE USER hacker@'%' IDENTIFIED BY '123';
-- ERROR: access denied
```

**Под `readonly`** должны получиться ошибки:

```sql
INSERT INTO books (title, author_id, year) VALUES ('X', 1, 2024);
-- ERROR: INSERT command denied

DELETE FROM books WHERE id = 1;
-- ERROR: DELETE command denied

DROP TABLE books;
-- ERROR: DROP command denied
```

Каждая ошибка фиксируется в журнале как **«отклонено — ожидаемо»**.

### 7. Дополнительная проверка: чужие БД

Под `app_user` попробуйте выполнить:

```sql
SHOW DATABASES;                 -- MySQL: видны только library и information_schema
\l                              -- PostgreSQL: чужие БД не доступны
SELECT name FROM sys.databases; -- MS SQL: видны только разрешённые
```

В выводе **не должна** появляться служебная БД `mysql`, `pg_catalog`/`pg_authid`, `msdb` для записи.

### 8. Запись в журнал администратора

Добавьте две записи:

```text
2026-05-25 10:30 | USER       | созданы admin (полные), app_user (CRUD), readonly (SELECT)
2026-05-25 10:55 | TEST       | проверочная таблица 10 строк: 7 позитивных + 3 негативных — все ожидаемо
```

## Контрольные проверки этапа

- [ ] Все три учётных записи существуют и могут войти.
- [ ] У `admin` есть полные права; у `app_user` — CRUD; у `readonly` — `SELECT`.
- [ ] Под `admin` создаются и удаляются таблицы.
- [ ] Под `app_user` выполняются `INSERT`/`UPDATE`/`DELETE`.
- [ ] Под `app_user` блокируются `CREATE TABLE` и `CREATE USER`.
- [ ] Под `readonly` блокируются `INSERT`, `UPDATE`, `DELETE`, `DROP`.
- [ ] Под `app_user` и `readonly` не видны служебные БД сервера.
- [ ] Проверочный журнал заполнен на 10 строк, ожидаемые результаты совпадают с фактическими.

## Артефакты этапа

| Артефакт | Где взять |
|----------|-----------|
| Скрипт `users.sql` | Команды создания учётных записей и выдачи прав |
| Скриншот `SHOW GRANTS` / `\du` / `sp_helpuser` | для каждой учётной записи |
| Проверочный журнал (10 строк) | Текстовый файл `permissions_check.txt` |
| Скриншоты позитивных сценариев | вход и успешное выполнение `SELECT/INSERT` |
| Скриншоты негативных сценариев | сообщения об отказе |
| Журнал администратора | две новые строки за этап |
