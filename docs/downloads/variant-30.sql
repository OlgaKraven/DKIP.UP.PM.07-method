-- Учебные исходные данные варианта 30. Открыть в пустой базе pm07_v30.
CREATE TABLE `products` (
  id int PRIMARY KEY,
  name varchar(100) NOT NULL,
  event_at datetime NOT NULL,
  amount decimal(10,2) NOT NULL,
  link_id int NOT NULL,
  quantity int NOT NULL,
  expires_on date NOT NULL
);
INSERT INTO `products` (id,name,event_at,amount,link_id,quantity,expires_on) VALUES
(1, 'products 1', '2026-11-04 09:00:00', 10, 1, 1, '2026-11-10'),
(2, 'products 2', '2026-11-03 12:00:00', 20, 2, 2, '2026-11-20'),
(3, 'products 3', '2026-07-01 12:00:00', 30, 3, 3, '2026-11-07'),
(4, 'products 4', '2026-11-05 12:00:00', 40, 4, 4, '2026-12-10');

CREATE TABLE `materials` (
  id int PRIMARY KEY,
  name varchar(100) NOT NULL,
  event_at datetime NOT NULL,
  amount decimal(10,2) NOT NULL,
  link_id int NOT NULL,
  quantity int NOT NULL,
  expires_on date NOT NULL
);
INSERT INTO `materials` (id,name,event_at,amount,link_id,quantity,expires_on) VALUES
(1, 'materials 1', '2026-11-04 09:00:00', 10, 1, 1, '2026-11-10'),
(2, 'materials 2', '2026-11-03 12:00:00', 20, 2, 2, '2026-11-20'),
(3, 'materials 3', '2026-07-01 12:00:00', 30, 3, 3, '2026-11-07'),
(4, 'materials 4', '2026-11-05 12:00:00', 40, 4, 4, '2026-12-10');

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
