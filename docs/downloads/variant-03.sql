-- Учебные исходные данные варианта 3. Открыть в пустой базе pm07_v03.
CREATE TABLE `patients` (
  id int PRIMARY KEY,
  name varchar(100) NOT NULL,
  event_at datetime NOT NULL,
  amount decimal(10,2) NOT NULL,
  link_id int NOT NULL,
  quantity int NOT NULL,
  expires_on date NOT NULL
);
INSERT INTO `patients` (id,name,event_at,amount,link_id,quantity,expires_on) VALUES
(1, 'patients 1', '2026-11-04 09:00:00', 10, 1, 1, '2026-11-10'),
(2, 'patients 2', '2026-11-03 12:00:00', 20, 2, 2, '2026-11-20'),
(3, 'patients 3', '2026-07-01 12:00:00', 30, 3, 3, '2026-11-07'),
(4, 'patients 4', '2026-11-05 12:00:00', 40, 4, 4, '2026-12-10');

CREATE TABLE `doctors` (
  id int PRIMARY KEY,
  name varchar(100) NOT NULL,
  event_at datetime NOT NULL,
  amount decimal(10,2) NOT NULL,
  link_id int NOT NULL,
  quantity int NOT NULL,
  expires_on date NOT NULL
);
INSERT INTO `doctors` (id,name,event_at,amount,link_id,quantity,expires_on) VALUES
(1, 'doctors 1', '2026-11-04 09:00:00', 10, 1, 1, '2026-11-10'),
(2, 'doctors 2', '2026-11-03 12:00:00', 20, 2, 2, '2026-11-20'),
(3, 'doctors 3', '2026-07-01 12:00:00', 30, 3, 3, '2026-11-07'),
(4, 'doctors 4', '2026-11-05 12:00:00', 40, 4, 4, '2026-12-10');

CREATE TABLE `appointments` (
  id int PRIMARY KEY,
  name varchar(100) NOT NULL,
  event_at datetime NOT NULL,
  amount decimal(10,2) NOT NULL,
  link_id int NOT NULL,
  quantity int NOT NULL,
  expires_on date NOT NULL
);
INSERT INTO `appointments` (id,name,event_at,amount,link_id,quantity,expires_on) VALUES
(1, 'appointments 1', '2026-11-04 09:00:00', 10, 1, 1, '2026-11-10'),
(2, 'appointments 2', '2026-11-03 12:00:00', 20, 2, 2, '2026-11-20'),
(3, 'appointments 3', '2026-07-01 12:00:00', 30, 3, 3, '2026-11-07'),
(4, 'appointments 4', '2026-11-05 12:00:00', 40, 4, 4, '2026-12-10');

CREATE TABLE access_probe (id int PRIMARY KEY, value int NOT NULL);
INSERT INTO access_probe VALUES (1,10);
