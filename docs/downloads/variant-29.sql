-- Учебные исходные данные варианта 29. Открыть в пустой базе pm07_v29.
CREATE TABLE `clients` (
  id int PRIMARY KEY,
  name varchar(100) NOT NULL,
  event_at datetime NOT NULL,
  amount decimal(10,2) NOT NULL,
  link_id int NOT NULL,
  quantity int NOT NULL,
  expires_on date NOT NULL
);
INSERT INTO `clients` (id,name,event_at,amount,link_id,quantity,expires_on) VALUES
(1, 'clients 1', '2026-11-04 09:00:00', 10, 1, 1, '2026-11-10'),
(2, 'clients 2', '2026-11-03 12:00:00', 20, 2, 2, '2026-11-20'),
(3, 'clients 3', '2026-07-01 12:00:00', 30, 3, 3, '2026-11-07'),
(4, 'clients 4', '2026-11-05 12:00:00', 40, 4, 4, '2026-12-10');

CREATE TABLE `drivers` (
  id int PRIMARY KEY,
  name varchar(100) NOT NULL,
  event_at datetime NOT NULL,
  amount decimal(10,2) NOT NULL,
  link_id int NOT NULL,
  quantity int NOT NULL,
  expires_on date NOT NULL
);
INSERT INTO `drivers` (id,name,event_at,amount,link_id,quantity,expires_on) VALUES
(1, 'drivers 1', '2026-11-04 09:00:00', 10, 1, 1, '2026-11-10'),
(2, 'drivers 2', '2026-11-03 12:00:00', 20, 2, 2, '2026-11-20'),
(3, 'drivers 3', '2026-07-01 12:00:00', 30, 3, 3, '2026-11-07'),
(4, 'drivers 4', '2026-11-05 12:00:00', 40, 4, 4, '2026-12-10');

CREATE TABLE `trips` (
  id int PRIMARY KEY,
  name varchar(100) NOT NULL,
  event_at datetime NOT NULL,
  amount decimal(10,2) NOT NULL,
  link_id int NOT NULL,
  quantity int NOT NULL,
  expires_on date NOT NULL
);
INSERT INTO `trips` (id,name,event_at,amount,link_id,quantity,expires_on) VALUES
(1, 'trips 1', '2026-11-04 09:00:00', 10, 1, 1, '2026-11-10'),
(2, 'trips 2', '2026-11-03 12:00:00', 20, 2, 2, '2026-11-20'),
(3, 'trips 3', '2026-07-01 12:00:00', 30, 3, 3, '2026-11-07'),
(4, 'trips 4', '2026-11-05 12:00:00', 40, 4, 4, '2026-12-10');

CREATE TABLE access_probe (id int PRIMARY KEY, value int NOT NULL);
INSERT INTO access_probe VALUES (1,10);
CREATE TABLE `trips_archive` LIKE `trips`;
