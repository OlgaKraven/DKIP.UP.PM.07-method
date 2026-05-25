# Этап 2. Пользователи, роли и разграничение доступа

## Зачем нужны разные пользователи

Если приложение и администратор подключаются под одной учётной записью с правами «всё разрешено», любая ошибка в SQL-запросе становится катастрофой: можно случайно удалить таблицу, изменить пароль администратора или прочитать чужие данные.

Правильный подход — **принцип минимальных привилегий**: каждой задаче — свой логин и набор прав, которых хватает ровно для этой задачи и ни одного больше.

## Учебная модель ролей

В учебной практике используются три обязательные учётные записи:

| Учётная запись | Назначение | Что разрешено |
|----------------|------------|---------------|
| `admin` | Администратор БД | Все права: создание пользователей, изменение схемы, бэкап, восстановление |
| `app_user` | Приложение | CRUD по таблицам предметной области; нет права создавать таблицы и пользователей |
| `readonly` | Только чтение | `SELECT` по всем таблицам предметной области |

Имена и набор прав одинаковы для всех вариантов; меняется только СУБД, в которой они заводятся.

## Что такое привилегия

Привилегия — это разрешение на одно конкретное действие над одним конкретным объектом. Привилегии делятся на:

| Уровень | Примеры | Где задаётся |
|---------|---------|--------------|
| Сервер | `CREATE USER`, `RELOAD`, `SHUTDOWN` | глобально |
| База данных | `CREATE`, `DROP`, `BACKUP DATABASE` | на конкретную БД |
| Таблица | `SELECT`, `INSERT`, `UPDATE`, `DELETE` | на конкретную таблицу |
| Столбец | `SELECT(column)`, `UPDATE(column)` | на отдельный столбец |
| Процедура | `EXECUTE` | на конкретную процедуру |

Принцип: давать привилегию на **минимально возможный объект**.

## Учётная запись: что хранится

| Поле | Назначение |
|------|------------|
| Имя пользователя | Логин, по которому идентифицируется |
| Хост, с которого разрешён вход | В MySQL/MariaDB обязателен: `'app_user'@'localhost'` или `'app_user'@'192.168.%'` |
| Хеш пароля | Никогда не открытый текст |
| Список привилегий | Хранится в служебных таблицах |
| Статус | Активна / заблокирована / истекла |

В Linux-СУБД пара «логин + хост» считается **одной учётной записью**: `app_user@localhost` и `app_user@192.168.%` — это **разные** записи с возможно разными правами.

## Создание пользователей: MySQL и MariaDB

```sql
-- Администратор уже есть (root). Под root:
CREATE USER 'admin'@'localhost'    IDENTIFIED BY 'Strong!Pwd1';
CREATE USER 'app_user'@'%'         IDENTIFIED BY 'AppPwd2024';
CREATE USER 'readonly'@'%'         IDENTIFIED BY 'ReadPwd2024';

-- Полные права администратору
GRANT ALL PRIVILEGES ON library.* TO 'admin'@'localhost' WITH GRANT OPTION;

-- CRUD для приложения
GRANT SELECT, INSERT, UPDATE, DELETE
    ON library.* TO 'app_user'@'%';

-- Только чтение
GRANT SELECT ON library.* TO 'readonly'@'%';

FLUSH PRIVILEGES;
SHOW GRANTS FOR 'app_user'@'%';
```

## Создание пользователей: PostgreSQL

В PostgreSQL «пользователь» и «роль» — синонимы. Роль с правом входа (`LOGIN`) — это и есть пользователь.

```sql
CREATE ROLE admin     LOGIN PASSWORD 'Strong!Pwd1' SUPERUSER;
CREATE ROLE app_user  LOGIN PASSWORD 'AppPwd2024';
CREATE ROLE readonly  LOGIN PASSWORD 'ReadPwd2024';

CREATE DATABASE library OWNER admin;

\connect library

-- CRUD приложению на схеме public
GRANT USAGE ON SCHEMA public TO app_user, readonly;

GRANT SELECT, INSERT, UPDATE, DELETE
   ON ALL TABLES IN SCHEMA public TO app_user;

GRANT SELECT
   ON ALL TABLES IN SCHEMA public TO readonly;

-- Для новых таблиц, созданных позже
ALTER DEFAULT PRIVILEGES IN SCHEMA public
   GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_user;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
   GRANT SELECT ON TABLES TO readonly;
```

Дополнительно редактируется `pg_hba.conf` для подключения по паролю:

```text
# TYPE  DATABASE  USER       ADDRESS         METHOD
host    library   app_user   0.0.0.0/0       scram-sha-256
host    library   readonly   0.0.0.0/0       scram-sha-256
```

После правки — `sudo systemctl reload postgresql`.

## Создание пользователей: MS SQL Server

В MS SQL различают **Login** (учётная запись сервера) и **User** (пользователь в конкретной БД). Login создаётся на уровне сервера, потом «отображается» на пользователя в БД.

```sql
-- На уровне сервера
USE master;
CREATE LOGIN admin    WITH PASSWORD = 'Strong!Pwd1';
CREATE LOGIN app_user WITH PASSWORD = 'AppPwd2024';
CREATE LOGIN readonly WITH PASSWORD = 'ReadPwd2024';

-- В рабочей БД
USE Library;
CREATE USER admin    FOR LOGIN admin;
CREATE USER app_user FOR LOGIN app_user;
CREATE USER readonly FOR LOGIN readonly;

EXEC sp_addrolemember 'db_owner',      'admin';
EXEC sp_addrolemember 'db_datareader', 'readonly';
EXEC sp_addrolemember 'db_datareader', 'app_user';
EXEC sp_addrolemember 'db_datawriter', 'app_user';
```

Параметр сервера должен разрешать «Mixed Mode» (SQL Server Authentication), иначе вход по паролю не сработает.

## Проверка прав: позитивные и негативные сценарии

После настройки администратор **обязан** проверить, что права работают именно так, как задумано. Проверки одинаковы для всех СУБД и идут двумя группами:

### Позитивные

| Учётная запись | Что должно получаться |
|----------------|------------------------|
| `admin` | `CREATE TABLE`, `DROP TABLE`, `CREATE USER`, `SELECT`, `INSERT` |
| `app_user` | `SELECT`, `INSERT`, `UPDATE`, `DELETE` по таблицам предметной области |
| `readonly` | `SELECT` |

### Негативные

| Учётная запись | Что должно отклоняться |
|----------------|------------------------|
| `app_user` | `CREATE TABLE`, `CREATE USER`, `DROP TABLE` |
| `app_user` | Доступ к чужой БД (`mysql.user`, `pg_catalog`) |
| `readonly` | `INSERT`, `UPDATE`, `DELETE`, `DROP TABLE` |

Каждый отказ должен возвращать ошибку — это нормально. Если отказа нет, права настроены неверно.

## Пароли и хеши

Сервер хранит пароль в виде **хеша**. Используются разные алгоритмы:

| СУБД | Алгоритм |
|------|----------|
| MySQL 8 | `caching_sha2_password` |
| MariaDB | `ed25519` или `mysql_native_password` |
| PostgreSQL | `scram-sha-256` |
| MS SQL | внутренний |

Поэтому **узнать пароль нельзя**, его можно только сменить:

```sql
ALTER USER 'app_user'@'%' IDENTIFIED BY 'NewAppPwd2024';     -- MySQL
ALTER ROLE app_user PASSWORD 'NewAppPwd2024';                -- PostgreSQL
ALTER LOGIN app_user WITH PASSWORD = 'NewAppPwd2024';        -- MS SQL
```

Правила паролей для учебной практики: минимум 10 символов, обязательно цифра и знак, нельзя совпадение с логином.

## Просмотр текущих прав

| СУБД | Команда |
|------|---------|
| MySQL | `SHOW GRANTS FOR 'app_user'@'%';` |
| PostgreSQL | `\du app_user` и `\z table_name` |
| MS SQL | `EXEC sp_helpuser 'app_user';` |

## Отзыв прав

Принцип: «всё, что предоставили, можем отозвать».

```sql
REVOKE INSERT, UPDATE, DELETE ON library.* FROM 'app_user'@'%';    -- MySQL
REVOKE SELECT ON ALL TABLES IN SCHEMA public FROM readonly;        -- PostgreSQL
ALTER SERVER ROLE sysadmin DROP MEMBER admin;                       -- MS SQL
```

После `REVOKE` проверка делается тем же набором сценариев.

## Что не нужно делать

| Ошибка | Чем грозит |
|--------|-----------|
| Пускать приложение под `root`/`postgres`/`sa` | Любая SQL-инъекция превращается в захват сервера |
| Давать `app_user` право `CREATE USER` | Учётная запись приложения может выписать новую с большими правами |
| Хранить пароли пользователей в коде программы или в README | Утечка репозитория = утечка БД |
| Использовать один пароль для разных серверов | Компрометация одного = компрометация всех |
| Создавать запись `'app_user'@'%'` без необходимости | Разрешено подключение из любой сети |

## Артефакты этапа

К концу этапа собираются:

- SQL-скрипт `users.sql` с командами создания всех трёх учёток и выдачи прав;
- скриншот `SHOW GRANTS` / `\du` / `sp_helpuser` для каждой учётной записи;
- журнал проверок: 3 позитивных и 3 негативных сценария, фактический результат напротив ожидаемого;
- описание решения по уровню `bind-address` / `listen_addresses`: разрешено ли подключение с хоста, и зачем.
