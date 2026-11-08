-- Учебные исходные данные варианта 2. Открыть в пустой базе pm07_v02.
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

CREATE TABLE `cars` (
  id int PRIMARY KEY,
  name varchar(100) NOT NULL,
  event_at datetime NOT NULL,
  amount decimal(10,2) NOT NULL,
  link_id int NOT NULL,
  quantity int NOT NULL,
  expires_on date NOT NULL
);
INSERT INTO `cars` (id,name,event_at,amount,link_id,quantity,expires_on) VALUES
(1, 'cars 1', '2026-11-04 09:00:00', 10, 1, 1, '2026-11-10'),
(2, 'cars 2', '2026-11-03 12:00:00', 20, 2, 2, '2026-11-20'),
(3, 'cars 3', '2026-07-01 12:00:00', 30, 3, 3, '2026-11-07'),
(4, 'cars 4', '2026-11-05 12:00:00', 40, 4, 4, '2026-12-10');

CREATE TABLE `orders` (
  id int PRIMARY KEY,
  name varchar(100) NOT NULL,
  event_at datetime NOT NULL,
  amount decimal(10,2) NOT NULL,
  link_id int NOT NULL,
  quantity int NOT NULL,
  expires_on date NOT NULL
);
INSERT INTO `orders` (id,name,event_at,amount,link_id,quantity,expires_on) VALUES
(1, 'orders 1', '2026-11-04 09:00:00', 10, 1, 1, '2026-11-10'),
(2, 'orders 2', '2026-11-03 12:00:00', 20, 2, 2, '2026-11-20'),
(3, 'orders 3', '2026-07-01 12:00:00', 30, 3, 3, '2026-11-07'),
(4, 'orders 4', '2026-11-05 12:00:00', 40, 4, 4, '2026-12-10');

CREATE TABLE access_probe (id int PRIMARY KEY, value int NOT NULL);
INSERT INTO access_probe VALUES (1,10);
