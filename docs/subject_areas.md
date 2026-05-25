# Предметные области

Номер варианта задаёт **четыре параметра**: какую СУБД ставить, на какой ОС, какие тестовые таблицы наполнять и какую рутинную задачу автоматизировать. Предметные области взяты те же, что и в УП.05 (ИС в WinForms/WPF), чтобы можно было использовать готовую структуру таблиц.

Список ролей у всех вариантов одинаковый: `admin`, `app_user`, `readonly`.

| № | СУБД | ОС | Предметная область | Тестовые таблицы | Задача автоматизации |
|---:|------|----|--------------------|--------------------|----------------------|
| 1  | MySQL 8 | Ubuntu Server 22.04 | Библиотека | `books`, `readers`, `book_issues` | Ежедневный логический бэкап `mysqldump` с датой в имени, ротация 7 дней |
| 2  | MySQL 8 | Ubuntu Server 22.04 | Автосервис | `clients`, `cars`, `orders` | Скрипт проверки свободного места на диске и отправка предупреждения в файл-лог |
| 3  | MySQL 8 | Debian 12 | Медицинская клиника | `patients`, `doctors`, `appointments` | Ежедневный отчёт «количество записей в каждой таблице» в файл `daily_stats.txt` |
| 4  | MariaDB 10 | Ubuntu Server 22.04 | Учебный центр | `courses`, `groups`, `students` | Бэкап только структуры (`--no-data`) раз в неделю |
| 5  | MariaDB 10 | Debian 12 | Гостиница | `rooms`, `guests`, `bookings` | Сжатие старых бэкапов `.sql` в `.sql.gz`, удаление файлов > 14 дней |
| 6  | MariaDB 10 | Ubuntu Server 22.04 | Магазин электроники | `products`, `categories`, `sales` | Скрипт перезапуска службы СУБД, если она остановлена |
| 7  | PostgreSQL 16 | Ubuntu Server 22.04 | Салон красоты | `clients`, `masters`, `appointments` | Бэкап через `pg_dump` в формате `custom` с компрессией |
| 8  | PostgreSQL 16 | Debian 12 | Спортивный клуб | `members`, `subscriptions`, `visits` | Запуск `VACUUM ANALYZE` по расписанию с записью времени выполнения в лог |
| 9  | PostgreSQL 16 | Ubuntu Server 22.04 | Туристическое агентство | `tours`, `clients`, `bookings` | Ежечасный SQL-запрос на количество свежих записей в `bookings`, вывод в лог |
| 10 | PostgreSQL 15 | Debian 12 | Склад | `items`, `suppliers`, `stock` | Поиск таблиц без обновлений за месяц, запись их имён в `idle_tables.log` |
| 11 | MySQL 8 | Ubuntu Server 22.04 | Кафе | `dishes`, `orders`, `staff` | Архивация заказов старше 90 дней в отдельную таблицу `orders_archive` |
| 12 | MySQL 8 | Ubuntu Server 22.04 | Кинотеатр | `films`, `sessions`, `tickets` | Очистка таблицы `tickets` от записей старше 30 дней + бэкап перед очисткой |
| 13 | MariaDB 10 | Debian 12 | Аптека | `medicines`, `batches`, `sales` | Ежедневная выгрузка лекарств с истекающим сроком годности в CSV |
| 14 | PostgreSQL 16 | Ubuntu Server 22.04 | Сервис доставки | `orders`, `couriers`, `addresses` | Расчёт `pg_database_size` и запись динамики размера БД в лог |
| 15 | MySQL 8 | Ubuntu Server 22.04 | Прокат оборудования | `equipment`, `contracts`, `returns` | Скрипт `mysqlcheck --check --auto-repair` по расписанию |
| 16 | PostgreSQL 16 | Debian 12 | Ветеринарная клиника | `animals`, `owners`, `visits` | Бэкап только указанных таблиц (`-t animals -t visits`) |
| 17 | MariaDB 10 | Ubuntu Server 22.04 | Ремонт компьютерной техники | `devices`, `requests`, `parts` | Проверка лога ошибок `error.log` на ключевые слова `ERROR`/`CRASH` |
| 18 | MS SQL Server 2022 Express | Windows Server 2019 | Цветочный магазин | `bouquets`, `orders`, `clients` | PowerShell-скрипт `BACKUP DATABASE` с датой в имени |
| 19 | MS SQL Server 2022 Express | Windows Server 2019 | Агентство недвижимости | `objects`, `agents`, `deals` | PowerShell: проверка размера журнала транзакций и его усечение |
| 20 | MS SQL Server 2022 Express | Windows Server 2022 | Парикмахерская | `clients`, `masters`, `services` | PowerShell-скрипт восстановления тестовой копии БД из последнего бэкапа |
| 21 | MS SQL Server 2019 Express | Windows Server 2019 | Музыкальная школа | `students`, `teachers`, `lessons` | PowerShell-скрипт пересчёта статистики (`UPDATE STATISTICS`) |
| 22 | MySQL 8 | Windows Server 2019 | Детский сад | `children`, `groups`, `parents` | PowerShell: вызов `mysqldump.exe` с автообновляющимся именем |
| 23 | PostgreSQL 16 | Windows Server 2019 | Логистическая компания | `routes`, `drivers`, `vehicles` | PowerShell: вызов `pg_dump.exe` + проверка SHA-256 |
| 24 | MariaDB 10 | Ubuntu Server 22.04 | Интернет-провайдер | `subscribers`, `tariffs`, `payments` | Скрипт «сколько подписчиков на каждом тарифе» в CSV-файл |
| 25 | PostgreSQL 16 | Debian 12 | Страховая компания | `clients`, `policies`, `claims` | Бэкап + проверка `pg_restore --list` распакован ли архив корректно |
| 26 | MySQL 8 | Ubuntu Server 22.04 | Ресторан | `menu`, `orders`, `staff` | Скрипт «топ-10 блюд за вчерашний день» в файл `top_dishes.txt` |
| 27 | PostgreSQL 16 | Ubuntu Server 22.04 | Фотоателье | `clients`, `orders`, `services` | Ежедневный отчёт по агрегатам `count(*) GROUP BY service` в лог |
| 28 | MS SQL Server 2022 Express | Windows Server 2019 | Магазин одежды | `items`, `sizes`, `sales` | PowerShell: BACKUP + копирование файла на сетевой ресурс (или в другую папку) |
| 29 | MariaDB 10 | Debian 12 | Служба такси | `clients`, `drivers`, `trips` | Архивация поездок старше 60 дней + обновление статистики таблиц |
| 30 | MySQL 8 | Ubuntu Server 22.04 | Производственное предприятие | `products`, `materials`, `orders` | Бэкап + email-симуляция: запись «отправлено уведомление» в лог при успехе/ошибке |

---

## Обязательная индивидуальная доработка

Помимо четырёх обязательных блоков из таблицы, студент **добавляет к своему скрипту автоматизации одно из расширений**:

1. Логирование начала и конца выполнения с длительностью в миллисекундах.
2. Проверка кода возврата шага бэкапа и аварийный выход при ошибке.
3. Подсчёт SHA-256 итогового файла и сохранение рядом.
4. Удаление файлов старше N дней по списку расширений.
5. Чтение настроек из отдельного `.env`/`config.ini` вместо «зашитых» значений.
6. Различные уровни сообщений в логе: `INFO`, `WARN`, `ERROR`.
7. Проверка свободного места на диске перед запуском бэкапа.

Расширение должно быть описано в отчёте: что добавлено, как проверено, как изменился лог.
