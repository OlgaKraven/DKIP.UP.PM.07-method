-- Учебные исходные данные варианта 15. Открыть в пустой базе pm07_v15.
CREATE TABLE `equipment` (
  id int PRIMARY KEY,
  name varchar(100) NOT NULL,
  event_at datetime NOT NULL,
  amount decimal(10,2) NOT NULL,
  link_id int NOT NULL,
  quantity int NOT NULL,
  expires_on date NOT NULL
);
INSERT INTO `equipment` (id,name,event_at,amount,link_id,quantity,expires_on) VALUES
(1, 'equipment 1', '2026-11-04 09:00:00', 10, 1, 1, '2026-11-10'),
(2, 'equipment 2', '2026-11-03 12:00:00', 20, 2, 2, '2026-11-20'),
(3, 'equipment 3', '2026-07-01 12:00:00', 30, 3, 3, '2026-11-07'),
(4, 'equipment 4', '2026-11-05 12:00:00', 40, 4, 4, '2026-12-10');

CREATE TABLE `contracts` (
  id int PRIMARY KEY,
  name varchar(100) NOT NULL,
  event_at datetime NOT NULL,
  amount decimal(10,2) NOT NULL,
  link_id int NOT NULL,
  quantity int NOT NULL,
  expires_on date NOT NULL
);
INSERT INTO `contracts` (id,name,event_at,amount,link_id,quantity,expires_on) VALUES
(1, 'contracts 1', '2026-11-04 09:00:00', 10, 1, 1, '2026-11-10'),
(2, 'contracts 2', '2026-11-03 12:00:00', 20, 2, 2, '2026-11-20'),
(3, 'contracts 3', '2026-07-01 12:00:00', 30, 3, 3, '2026-11-07'),
(4, 'contracts 4', '2026-11-05 12:00:00', 40, 4, 4, '2026-12-10');

CREATE TABLE `returns` (
  id int PRIMARY KEY,
  name varchar(100) NOT NULL,
  event_at datetime NOT NULL,
  amount decimal(10,2) NOT NULL,
  link_id int NOT NULL,
  quantity int NOT NULL,
  expires_on date NOT NULL
);
INSERT INTO `returns` (id,name,event_at,amount,link_id,quantity,expires_on) VALUES
(1, 'returns 1', '2026-11-04 09:00:00', 10, 1, 1, '2026-11-10'),
(2, 'returns 2', '2026-11-03 12:00:00', 20, 2, 2, '2026-11-20'),
(3, 'returns 3', '2026-07-01 12:00:00', 30, 3, 3, '2026-11-07'),
(4, 'returns 4', '2026-11-05 12:00:00', 40, 4, 4, '2026-12-10');

CREATE TABLE access_probe (id int PRIMARY KEY, value int NOT NULL);
INSERT INTO access_probe VALUES (1,10);
