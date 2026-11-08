-- Учебные исходные данные варианта 22. Открыть в пустой базе pm07_v22.
CREATE TABLE `children` (
  id int PRIMARY KEY,
  name varchar(100) NOT NULL,
  event_at datetime NOT NULL,
  amount decimal(10,2) NOT NULL,
  link_id int NOT NULL,
  quantity int NOT NULL,
  expires_on date NOT NULL
);
INSERT INTO `children` (id,name,event_at,amount,link_id,quantity,expires_on) VALUES
(1, 'children 1', '2026-11-04 09:00:00', 10, 1, 1, '2026-11-10'),
(2, 'children 2', '2026-11-03 12:00:00', 20, 2, 2, '2026-11-20'),
(3, 'children 3', '2026-07-01 12:00:00', 30, 3, 3, '2026-11-07'),
(4, 'children 4', '2026-11-05 12:00:00', 40, 4, 4, '2026-12-10');

CREATE TABLE `groups` (
  id int PRIMARY KEY,
  name varchar(100) NOT NULL,
  event_at datetime NOT NULL,
  amount decimal(10,2) NOT NULL,
  link_id int NOT NULL,
  quantity int NOT NULL,
  expires_on date NOT NULL
);
INSERT INTO `groups` (id,name,event_at,amount,link_id,quantity,expires_on) VALUES
(1, 'groups 1', '2026-11-04 09:00:00', 10, 1, 1, '2026-11-10'),
(2, 'groups 2', '2026-11-03 12:00:00', 20, 2, 2, '2026-11-20'),
(3, 'groups 3', '2026-07-01 12:00:00', 30, 3, 3, '2026-11-07'),
(4, 'groups 4', '2026-11-05 12:00:00', 40, 4, 4, '2026-12-10');

CREATE TABLE `parents` (
  id int PRIMARY KEY,
  name varchar(100) NOT NULL,
  event_at datetime NOT NULL,
  amount decimal(10,2) NOT NULL,
  link_id int NOT NULL,
  quantity int NOT NULL,
  expires_on date NOT NULL
);
INSERT INTO `parents` (id,name,event_at,amount,link_id,quantity,expires_on) VALUES
(1, 'parents 1', '2026-11-04 09:00:00', 10, 1, 1, '2026-11-10'),
(2, 'parents 2', '2026-11-03 12:00:00', 20, 2, 2, '2026-11-20'),
(3, 'parents 3', '2026-07-01 12:00:00', 30, 3, 3, '2026-11-07'),
(4, 'parents 4', '2026-11-05 12:00:00', 40, 4, 4, '2026-12-10');

CREATE TABLE access_probe (id int PRIMARY KEY, value int NOT NULL);
INSERT INTO access_probe VALUES (1,10);
