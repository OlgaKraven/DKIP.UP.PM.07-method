-- Учебные исходные данные варианта 10. Открыть в пустой базе pm07_v10.
CREATE TABLE "items" (
  id int PRIMARY KEY,
  name varchar(100) NOT NULL,
  event_at timestamp NOT NULL,
  amount decimal(10,2) NOT NULL,
  link_id int NOT NULL,
  quantity int NOT NULL,
  expires_on date NOT NULL
);
INSERT INTO "items" (id,name,event_at,amount,link_id,quantity,expires_on) VALUES
(1, 'items 1', '2026-11-04 09:00:00', 10, 1, 1, '2026-11-10'),
(2, 'items 2', '2026-11-03 12:00:00', 20, 2, 2, '2026-11-20'),
(3, 'items 3', '2026-07-01 12:00:00', 30, 3, 3, '2026-11-07'),
(4, 'items 4', '2026-11-05 12:00:00', 40, 4, 4, '2026-12-10');

CREATE TABLE "suppliers" (
  id int PRIMARY KEY,
  name varchar(100) NOT NULL,
  event_at timestamp NOT NULL,
  amount decimal(10,2) NOT NULL,
  link_id int NOT NULL,
  quantity int NOT NULL,
  expires_on date NOT NULL
);
INSERT INTO "suppliers" (id,name,event_at,amount,link_id,quantity,expires_on) VALUES
(1, 'suppliers 1', '2026-11-04 09:00:00', 10, 1, 1, '2026-11-10'),
(2, 'suppliers 2', '2026-11-03 12:00:00', 20, 2, 2, '2026-11-20'),
(3, 'suppliers 3', '2026-07-01 12:00:00', 30, 3, 3, '2026-11-07'),
(4, 'suppliers 4', '2026-11-05 12:00:00', 40, 4, 4, '2026-12-10');

CREATE TABLE "stock" (
  id int PRIMARY KEY,
  name varchar(100) NOT NULL,
  event_at timestamp NOT NULL,
  amount decimal(10,2) NOT NULL,
  link_id int NOT NULL,
  quantity int NOT NULL,
  expires_on date NOT NULL
);
INSERT INTO "stock" (id,name,event_at,amount,link_id,quantity,expires_on) VALUES
(1, 'stock 1', '2026-11-04 09:00:00', 10, 1, 1, '2026-11-10'),
(2, 'stock 2', '2026-11-03 12:00:00', 20, 2, 2, '2026-11-20'),
(3, 'stock 3', '2026-07-01 12:00:00', 30, 3, 3, '2026-11-07'),
(4, 'stock 4', '2026-11-05 12:00:00', 40, 4, 4, '2026-12-10');

CREATE TABLE access_probe (id int PRIMARY KEY, value int NOT NULL);
INSERT INTO access_probe VALUES (1,10);
CREATE TABLE practice_change_log (table_name varchar(80) PRIMARY KEY,last_change timestamp NOT NULL);
INSERT INTO practice_change_log VALUES ('items', '2026-09-01 12:00:00');
INSERT INTO practice_change_log VALUES ('suppliers', '2026-11-03 12:00:00');
INSERT INTO practice_change_log VALUES ('stock', '2026-11-03 12:00:00');
