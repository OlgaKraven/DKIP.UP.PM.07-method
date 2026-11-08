-- Учебные исходные данные варианта 6. Открыть в пустой базе pm07_v06.
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

CREATE TABLE `categories` (
  id int PRIMARY KEY,
  name varchar(100) NOT NULL,
  event_at datetime NOT NULL,
  amount decimal(10,2) NOT NULL,
  link_id int NOT NULL,
  quantity int NOT NULL,
  expires_on date NOT NULL
);
INSERT INTO `categories` (id,name,event_at,amount,link_id,quantity,expires_on) VALUES
(1, 'categories 1', '2026-11-04 09:00:00', 10, 1, 1, '2026-11-10'),
(2, 'categories 2', '2026-11-03 12:00:00', 20, 2, 2, '2026-11-20'),
(3, 'categories 3', '2026-07-01 12:00:00', 30, 3, 3, '2026-11-07'),
(4, 'categories 4', '2026-11-05 12:00:00', 40, 4, 4, '2026-12-10');

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
