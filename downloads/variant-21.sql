-- Учебные исходные данные варианта 21. Открыть в пустой базе pm07_v21.
CREATE TABLE [students] (
  id int PRIMARY KEY,
  name nvarchar(100) NOT NULL,
  event_at datetime2 NOT NULL,
  amount decimal(10,2) NOT NULL,
  link_id int NOT NULL,
  quantity int NOT NULL,
  expires_on date NOT NULL
);
INSERT INTO [students] (id,name,event_at,amount,link_id,quantity,expires_on) VALUES
(1, N'students 1', '2026-11-04 09:00:00', 10, 1, 1, '2026-11-10'),
(2, N'students 2', '2026-11-03 12:00:00', 20, 2, 2, '2026-11-20'),
(3, N'students 3', '2026-07-01 12:00:00', 30, 3, 3, '2026-11-07'),
(4, N'students 4', '2026-11-05 12:00:00', 40, 4, 4, '2026-12-10');

CREATE TABLE [teachers] (
  id int PRIMARY KEY,
  name nvarchar(100) NOT NULL,
  event_at datetime2 NOT NULL,
  amount decimal(10,2) NOT NULL,
  link_id int NOT NULL,
  quantity int NOT NULL,
  expires_on date NOT NULL
);
INSERT INTO [teachers] (id,name,event_at,amount,link_id,quantity,expires_on) VALUES
(1, N'teachers 1', '2026-11-04 09:00:00', 10, 1, 1, '2026-11-10'),
(2, N'teachers 2', '2026-11-03 12:00:00', 20, 2, 2, '2026-11-20'),
(3, N'teachers 3', '2026-07-01 12:00:00', 30, 3, 3, '2026-11-07'),
(4, N'teachers 4', '2026-11-05 12:00:00', 40, 4, 4, '2026-12-10');

CREATE TABLE [lessons] (
  id int PRIMARY KEY,
  name nvarchar(100) NOT NULL,
  event_at datetime2 NOT NULL,
  amount decimal(10,2) NOT NULL,
  link_id int NOT NULL,
  quantity int NOT NULL,
  expires_on date NOT NULL
);
INSERT INTO [lessons] (id,name,event_at,amount,link_id,quantity,expires_on) VALUES
(1, N'lessons 1', '2026-11-04 09:00:00', 10, 1, 1, '2026-11-10'),
(2, N'lessons 2', '2026-11-03 12:00:00', 20, 2, 2, '2026-11-20'),
(3, N'lessons 3', '2026-07-01 12:00:00', 30, 3, 3, '2026-11-07'),
(4, N'lessons 4', '2026-11-05 12:00:00', 40, 4, 4, '2026-12-10');

CREATE TABLE access_probe (id int PRIMARY KEY, value int NOT NULL);
INSERT INTO access_probe VALUES (1,10);
