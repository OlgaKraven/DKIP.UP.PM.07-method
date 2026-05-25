# Этап 1. Установка СУБД и проверка работы сервера

## Задание

Развернуть виртуальную машину, установить указанную в варианте СУБД, убедиться, что служба работает, подключиться к серверу из консольного и графического клиента, зафиксировать ключевые настройки.

## Ход работы

Создайте виртуальную машину с параметрами не ниже минимальных (2 ядра, 2 ГБ RAM, 20 ГБ диск). На гостевой ОС обновите пакеты, установите СУБД из своего варианта, проверьте статус службы, подключитесь к серверу. Подключение должно работать **как с самой VM** (CLI), **так и с хоста** (GUI). После проверки соберите артефакты этапа.

## Шаги

### 1. Виртуальная машина

В VirtualBox или VMware:

1. Скачайте ISO выбранной ОС (Ubuntu Server 22.04, Debian 12, Windows Server 2019/2022).
2. Создайте VM: 2 CPU, 2 ГБ RAM (для MS SQL — 3 ГБ), 20 ГБ HDD динамический.
3. В разделе **Network** включите проброс порта:
   - Linux/MySQL: Host `13306` → Guest `3306`;
   - Linux/PostgreSQL: Host `15432` → Guest `5432`;
   - Linux/MariaDB: Host `13306` → Guest `3306`;
   - Windows/MS SQL: Host `11433` → Guest `1433`.
4. Установите ОС, обновите пакеты.

Для Linux:

```bash
sudo apt update && sudo apt upgrade -y
sudo reboot
```

### 2. Установка СУБД

**Вариант с MySQL 8 на Ubuntu/Debian**:

```bash
sudo apt update
sudo apt install -y mysql-server
sudo systemctl enable --now mysql
sudo systemctl status mysql
sudo mysql_secure_installation
```

При запуске `mysql_secure_installation` отвечайте: пароль `root` поставить, тестовую БД и анонимных пользователей удалить, удалённый вход `root` запретить.

**Вариант с MariaDB на Ubuntu/Debian**:

```bash
sudo apt install -y mariadb-server
sudo systemctl enable --now mariadb
sudo systemctl status mariadb
sudo mysql_secure_installation
```

**Вариант с PostgreSQL 16 на Ubuntu/Debian**:

```bash
sudo apt install -y postgresql postgresql-contrib
sudo systemctl enable --now postgresql
sudo systemctl status postgresql
sudo -u postgres psql -c "SELECT version();"
```

**Вариант с MS SQL Server 2022 Express на Windows Server**:

1. Скачайте `SQL2022-SSEI-Expr.exe` и `SSMS-Setup-ENU.exe`.
2. Запустите установщик SQL Server, выберите **Basic**.
3. В **SQL Server Configuration Manager** включите TCP/IP, перезапустите службу `SQL Server (SQLEXPRESS)`.
4. Установите SSMS.
5. PowerShell-проверка:

```powershell
Get-Service -Name "MSSQL`$SQLEXPRESS"
sqlcmd -S .\SQLEXPRESS -E -Q "SELECT @@VERSION;"
```

### 3. Конфигурационный файл

Откройте основной конфиг и проверьте/измените три параметра: порт, адрес прослушивания, кодировка.

**MySQL/MariaDB** (`/etc/mysql/mysql.conf.d/mysqld.cnf` или `/etc/mysql/mariadb.conf.d/50-server.cnf`):

```ini
[mysqld]
port            = 3306
bind-address    = 0.0.0.0
character-set-server = utf8mb4
collation-server     = utf8mb4_unicode_ci
log_error       = /var/log/mysql/error.log
```

**PostgreSQL** (`/etc/postgresql/16/main/postgresql.conf`):

```text
port = 5432
listen_addresses = '*'
```

В `/etc/postgresql/16/main/pg_hba.conf` добавьте:

```text
host    all    all    0.0.0.0/0    scram-sha-256
```

**MS SQL** — параметры в SQL Server Configuration Manager → SQL Server Network Configuration → Protocols for SQLEXPRESS → TCP/IP → IPAll → TCP Port = `1433`.

Перезапустите службу:

```bash
sudo systemctl restart mysql        # или: mariadb / postgresql
```

```powershell
Restart-Service "MSSQL`$SQLEXPRESS"
```

### 4. Подключение из CLI на самой VM

```bash
mysql -u root -p                                   # MySQL/MariaDB
sudo -u postgres psql                              # PostgreSQL (local)
sqlcmd -S .\SQLEXPRESS -E                          # MS SQL
```

В клиенте выполните:

```sql
SELECT VERSION();                  -- MySQL/MariaDB
SHOW DATABASES;
```

```sql
SELECT version();                  -- PostgreSQL
\l
```

```sql
SELECT @@VERSION;                  -- MS SQL
SELECT name FROM sys.databases;
```

### 5. Проверка порта изнутри VM

```bash
sudo ss -tlnp | grep -E '3306|5432'
```

```powershell
Get-NetTCPConnection -LocalPort 1433 | Format-Table -Auto
```

Должна быть строка `LISTEN` на нужном порту.

### 6. Подключение с хоста

С хост-машины проверьте, что порт виден:

```bash
# Linux/macOS хост
nc -vz 127.0.0.1 13306
```

```powershell
# Windows хост
Test-NetConnection -ComputerName 127.0.0.1 -Port 13306
```

Установите на хосте GUI-клиент (DBeaver Community) и создайте подключение:

| Поле | Значение |
|------|----------|
| Host | `127.0.0.1` |
| Port | `13306` / `15432` / `11433` (с учётом проброса) |
| User | `root` / `postgres` / `sa` |
| Password | пароль, заданный при установке |

Подключитесь и сделайте скриншот окна DBeaver со списком баз.

### 7. Создание рабочей базы

В CLI:

```sql
CREATE DATABASE library
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;          -- MySQL/MariaDB
```

```sql
CREATE DATABASE library
    ENCODING 'UTF8'
    LC_COLLATE 'C.UTF-8'
    LC_CTYPE 'C.UTF-8'
    TEMPLATE template0;                  -- PostgreSQL
```

```sql
CREATE DATABASE Library
    COLLATE Cyrillic_General_CI_AS;      -- MS SQL
```

Создайте 2–3 тестовые таблицы своего варианта и наполните их 5–10 строками каждую (структуру и тестовые данные возьмите из учебной практики ПМ.05, если она была).

```sql
USE library;
CREATE TABLE authors (
    id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(200) NOT NULL,
    country  VARCHAR(100)
);
CREATE TABLE books (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    author_id INT NOT NULL,
    year INT,
    FOREIGN KEY (author_id) REFERENCES authors(id)
);
INSERT INTO authors (full_name, country) VALUES
    ('А. С. Пушкин','Россия'),
    ('Н. В. Гоголь','Россия');
INSERT INTO books (title, author_id, year) VALUES
    ('Капитанская дочка',1,1836),
    ('Мёртвые души',2,1842);
```

### 8. Запись в журнал администратора

Создайте файл `journal.md` (или `journal.txt`) и сделайте первые записи по форме:

```text
2026-05-25 09:10 | INSTALL    | <ОС>: установлен <СУБД> <версия>
2026-05-25 09:30 | CONFIGURE  | bind-address=0.0.0.0; port=<port>; кодировка utf8mb4
2026-05-25 09:45 | NETWORK    | проброс <host>:<13306> → <guest>:<3306>; nc -vz OK
2026-05-25 10:00 | DB         | создана БД library; 2 таблицы; вставлено 4 строки
```

## Контрольные проверки этапа

- [ ] Команда `systemctl status` / `Get-Service` показывает `active (running)` / `Running`.
- [ ] `ss -tlnp` / `Get-NetTCPConnection` показывает `LISTEN` на нужном порту.
- [ ] `mysql -h 127.0.0.1`, `psql -h 127.0.0.1`, `sqlcmd -S 127.0.0.1\SQLEXPRESS` — все работают.
- [ ] Хост-машина подключается через DBeaver/SSMS с пробросом порта.
- [ ] Создана рабочая БД с UTF-8.
- [ ] Сделаны 2–3 таблицы и тестовые `INSERT`.
- [ ] В журнале администратора есть 4 первых записи.

## Артефакты этапа

| Артефакт | Где взять |
|----------|-----------|
| Скриншот статуса службы | `systemctl status` / Services.msc |
| Скриншот `ss -tlnp` / `Get-NetTCPConnection` | CLI хоста-сервера |
| Скриншот успешного входа в DBeaver/SSMS с хоста | GUI хоста |
| Файл конфигурации | копия `mysqld.cnf` / `postgresql.conf` / экспорт настроек MS SQL |
| Скрипт `init.sql` | команды создания БД и тестовых таблиц |
| Журнал администратора | `journal.md` с 4 записями этапа |
