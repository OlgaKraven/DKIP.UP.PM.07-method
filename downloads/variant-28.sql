-- Учебные исходные данные варианта 28. Открыть в пустой базе pm07_v28.
CREATE TABLE [items] (
  id int PRIMARY KEY,
  name nvarchar(100) NOT NULL,
  event_at datetime2 NOT NULL,
  amount decimal(10,2) NOT NULL,
  link_id int NOT NULL,
  quantity int NOT NULL,
  expires_on date NOT NULL
);
INSERT INTO [items] (id,name,event_at,amount,link_id,quantity,expires_on) VALUES
(1, N'items 1', '2026-11-04 09:00:00', 10, 1, 1, '2026-11-10'),
(2, N'items 2', '2026-11-03 12:00:00', 20, 2, 2, '2026-11-20'),
(3, N'items 3', '2026-07-01 12:00:00', 30, 3, 3, '2026-11-07'),
(4, N'items 4', '2026-11-05 12:00:00', 40, 4, 4, '2026-12-10');

CREATE TABLE [sizes] (
  id int PRIMARY KEY,
  name nvarchar(100) NOT NULL,
  event_at datetime2 NOT NULL,
  amount decimal(10,2) NOT NULL,
  link_id int NOT NULL,
  quantity int NOT NULL,
  expires_on date NOT NULL
);
INSERT INTO [sizes] (id,name,event_at,amount,link_id,quantity,expires_on) VALUES
(1, N'sizes 1', '2026-11-04 09:00:00', 10, 1, 1, '2026-11-10'),
(2, N'sizes 2', '2026-11-03 12:00:00', 20, 2, 2, '2026-11-20'),
(3, N'sizes 3', '2026-07-01 12:00:00', 30, 3, 3, '2026-11-07'),
(4, N'sizes 4', '2026-11-05 12:00:00', 40, 4, 4, '2026-12-10');

CREATE TABLE [sales] (
  id int PRIMARY KEY,
  name nvarchar(100) NOT NULL,
  event_at datetime2 NOT NULL,
  amount decimal(10,2) NOT NULL,
  link_id int NOT NULL,
  quantity int NOT NULL,
  expires_on date NOT NULL
);
INSERT INTO [sales] (id,name,event_at,amount,link_id,quantity,expires_on) VALUES
(1, N'sales 1', '2026-11-04 09:00:00', 10, 1, 1, '2026-11-10'),
(2, N'sales 2', '2026-11-03 12:00:00', 20, 2, 2, '2026-11-20'),
(3, N'sales 3', '2026-07-01 12:00:00', 30, 3, 3, '2026-11-07'),
(4, N'sales 4', '2026-11-05 12:00:00', 40, 4, 4, '2026-12-10');

CREATE TABLE access_probe (id int PRIMARY KEY, value int NOT NULL);
INSERT INTO access_probe VALUES (1,10);
