-- Учебные исходные данные варианта 12. Открыть в пустой базе pm07_v12.
CREATE TABLE `films` (
  id int PRIMARY KEY,
  name varchar(100) NOT NULL,
  event_at datetime NOT NULL,
  amount decimal(10,2) NOT NULL,
  link_id int NOT NULL,
  quantity int NOT NULL,
  expires_on date NOT NULL
);
INSERT INTO `films` (id,name,event_at,amount,link_id,quantity,expires_on) VALUES
(1, 'films 1', '2026-11-04 09:00:00', 10, 1, 1, '2026-11-10'),
(2, 'films 2', '2026-11-03 12:00:00', 20, 2, 2, '2026-11-20'),
(3, 'films 3', '2026-07-01 12:00:00', 30, 3, 3, '2026-11-07'),
(4, 'films 4', '2026-11-05 12:00:00', 40, 4, 4, '2026-12-10');

CREATE TABLE `sessions` (
  id int PRIMARY KEY,
  name varchar(100) NOT NULL,
  event_at datetime NOT NULL,
  amount decimal(10,2) NOT NULL,
  link_id int NOT NULL,
  quantity int NOT NULL,
  expires_on date NOT NULL
);
INSERT INTO `sessions` (id,name,event_at,amount,link_id,quantity,expires_on) VALUES
(1, 'sessions 1', '2026-11-04 09:00:00', 10, 1, 1, '2026-11-10'),
(2, 'sessions 2', '2026-11-03 12:00:00', 20, 2, 2, '2026-11-20'),
(3, 'sessions 3', '2026-07-01 12:00:00', 30, 3, 3, '2026-11-07'),
(4, 'sessions 4', '2026-11-05 12:00:00', 40, 4, 4, '2026-12-10');

CREATE TABLE `tickets` (
  id int PRIMARY KEY,
  name varchar(100) NOT NULL,
  event_at datetime NOT NULL,
  amount decimal(10,2) NOT NULL,
  link_id int NOT NULL,
  quantity int NOT NULL,
  expires_on date NOT NULL
);
INSERT INTO `tickets` (id,name,event_at,amount,link_id,quantity,expires_on) VALUES
(1, 'tickets 1', '2026-11-04 09:00:00', 10, 1, 1, '2026-11-10'),
(2, 'tickets 2', '2026-11-03 12:00:00', 20, 2, 2, '2026-11-20'),
(3, 'tickets 3', '2026-07-01 12:00:00', 30, 3, 3, '2026-11-07'),
(4, 'tickets 4', '2026-11-05 12:00:00', 40, 4, 4, '2026-12-10');

CREATE TABLE access_probe (id int PRIMARY KEY, value int NOT NULL);
INSERT INTO access_probe VALUES (1,10);
