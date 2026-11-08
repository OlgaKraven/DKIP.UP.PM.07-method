-- Учебные исходные данные варианта 24. Открыть в пустой базе pm07_v24.
CREATE TABLE `subscribers` (
  id int PRIMARY KEY,
  name varchar(100) NOT NULL,
  event_at datetime NOT NULL,
  amount decimal(10,2) NOT NULL,
  link_id int NOT NULL,
  quantity int NOT NULL,
  expires_on date NOT NULL
);
INSERT INTO `subscribers` (id,name,event_at,amount,link_id,quantity,expires_on) VALUES
(1, 'subscribers 1', '2026-11-04 09:00:00', 10, 1, 1, '2026-11-10'),
(2, 'subscribers 2', '2026-11-03 12:00:00', 20, 2, 2, '2026-11-20'),
(3, 'subscribers 3', '2026-07-01 12:00:00', 30, 3, 3, '2026-11-07'),
(4, 'subscribers 4', '2026-11-05 12:00:00', 40, 4, 4, '2026-12-10');

CREATE TABLE `tariffs` (
  id int PRIMARY KEY,
  name varchar(100) NOT NULL,
  event_at datetime NOT NULL,
  amount decimal(10,2) NOT NULL,
  link_id int NOT NULL,
  quantity int NOT NULL,
  expires_on date NOT NULL
);
INSERT INTO `tariffs` (id,name,event_at,amount,link_id,quantity,expires_on) VALUES
(1, 'tariffs 1', '2026-11-04 09:00:00', 10, 1, 1, '2026-11-10'),
(2, 'tariffs 2', '2026-11-03 12:00:00', 20, 2, 2, '2026-11-20'),
(3, 'tariffs 3', '2026-07-01 12:00:00', 30, 3, 3, '2026-11-07'),
(4, 'tariffs 4', '2026-11-05 12:00:00', 40, 4, 4, '2026-12-10');

CREATE TABLE `payments` (
  id int PRIMARY KEY,
  name varchar(100) NOT NULL,
  event_at datetime NOT NULL,
  amount decimal(10,2) NOT NULL,
  link_id int NOT NULL,
  quantity int NOT NULL,
  expires_on date NOT NULL
);
INSERT INTO `payments` (id,name,event_at,amount,link_id,quantity,expires_on) VALUES
(1, 'payments 1', '2026-11-04 09:00:00', 10, 1, 1, '2026-11-10'),
(2, 'payments 2', '2026-11-03 12:00:00', 20, 2, 2, '2026-11-20'),
(3, 'payments 3', '2026-07-01 12:00:00', 30, 3, 3, '2026-11-07'),
(4, 'payments 4', '2026-11-05 12:00:00', 40, 4, 4, '2026-12-10');

CREATE TABLE access_probe (id int PRIMARY KEY, value int NOT NULL);
INSERT INTO access_probe VALUES (1,10);
