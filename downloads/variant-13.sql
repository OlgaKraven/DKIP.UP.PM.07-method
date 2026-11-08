-- Учебные исходные данные варианта 13. Открыть в пустой базе pm07_v13.
CREATE TABLE `medicines` (
  id int PRIMARY KEY,
  name varchar(100) NOT NULL,
  event_at datetime NOT NULL,
  amount decimal(10,2) NOT NULL,
  link_id int NOT NULL,
  quantity int NOT NULL,
  expires_on date NOT NULL
);
INSERT INTO `medicines` (id,name,event_at,amount,link_id,quantity,expires_on) VALUES
(1, 'medicines 1', '2026-11-04 09:00:00', 10, 1, 1, '2026-11-10'),
(2, 'medicines 2', '2026-11-03 12:00:00', 20, 2, 2, '2026-11-20'),
(3, 'medicines 3', '2026-07-01 12:00:00', 30, 3, 3, '2026-11-07'),
(4, 'medicines 4', '2026-11-05 12:00:00', 40, 4, 4, '2026-12-10');

CREATE TABLE `batches` (
  id int PRIMARY KEY,
  name varchar(100) NOT NULL,
  event_at datetime NOT NULL,
  amount decimal(10,2) NOT NULL,
  link_id int NOT NULL,
  quantity int NOT NULL,
  expires_on date NOT NULL
);
INSERT INTO `batches` (id,name,event_at,amount,link_id,quantity,expires_on) VALUES
(1, 'batches 1', '2026-11-04 09:00:00', 10, 1, 1, '2026-11-10'),
(2, 'batches 2', '2026-11-03 12:00:00', 20, 2, 2, '2026-11-20'),
(3, 'batches 3', '2026-07-01 12:00:00', 30, 3, 3, '2026-11-07'),
(4, 'batches 4', '2026-11-05 12:00:00', 40, 4, 4, '2026-12-10');

CREATE TABLE `sales` (
  id int PRIMARY KEY,
  name varchar(100) NOT NULL,
  event_at datetime NOT NULL,
  amount decimal(10,2) NOT NULL,
  link_id int NOT NULL,
  quantity int NOT NULL,
  expires_on date NOT NULL
);
INSERT INTO `sales` (id,name,event_at,amount,link_id,quantity,expires_on) VALUES
(1, 'sales 1', '2026-11-04 09:00:00', 10, 1, 1, '2026-11-10'),
(2, 'sales 2', '2026-11-03 12:00:00', 20, 2, 2, '2026-11-20'),
(3, 'sales 3', '2026-07-01 12:00:00', 30, 3, 3, '2026-11-07'),
(4, 'sales 4', '2026-11-05 12:00:00', 40, 4, 4, '2026-12-10');

CREATE TABLE access_probe (id int PRIMARY KEY, value int NOT NULL);
INSERT INTO access_probe VALUES (1,10);
