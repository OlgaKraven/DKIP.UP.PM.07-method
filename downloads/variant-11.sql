-- Учебные исходные данные варианта 11. Открыть в пустой базе pm07_v11.
CREATE TABLE `dishes` (
  id int PRIMARY KEY,
  name varchar(100) NOT NULL,
  event_at datetime NOT NULL,
  amount decimal(10,2) NOT NULL,
  link_id int NOT NULL,
  quantity int NOT NULL,
  expires_on date NOT NULL
);
INSERT INTO `dishes` (id,name,event_at,amount,link_id,quantity,expires_on) VALUES
(1, 'dishes 1', '2026-11-04 09:00:00', 10, 1, 1, '2026-11-10'),
(2, 'dishes 2', '2026-11-03 12:00:00', 20, 2, 2, '2026-11-20'),
(3, 'dishes 3', '2026-07-01 12:00:00', 30, 3, 3, '2026-11-07'),
(4, 'dishes 4', '2026-11-05 12:00:00', 40, 4, 4, '2026-12-10');

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

CREATE TABLE `staff` (
  id int PRIMARY KEY,
  name varchar(100) NOT NULL,
  event_at datetime NOT NULL,
  amount decimal(10,2) NOT NULL,
  link_id int NOT NULL,
  quantity int NOT NULL,
  expires_on date NOT NULL
);
INSERT INTO `staff` (id,name,event_at,amount,link_id,quantity,expires_on) VALUES
(1, 'staff 1', '2026-11-04 09:00:00', 10, 1, 1, '2026-11-10'),
(2, 'staff 2', '2026-11-03 12:00:00', 20, 2, 2, '2026-11-20'),
(3, 'staff 3', '2026-07-01 12:00:00', 30, 3, 3, '2026-11-07'),
(4, 'staff 4', '2026-11-05 12:00:00', 40, 4, 4, '2026-12-10');

CREATE TABLE access_probe (id int PRIMARY KEY, value int NOT NULL);
INSERT INTO access_probe VALUES (1,10);
CREATE TABLE `orders_archive` LIKE `orders`;
