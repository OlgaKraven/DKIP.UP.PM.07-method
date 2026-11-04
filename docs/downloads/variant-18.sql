-- Учебные исходные данные варианта 18. Открыть в пустой базе pm07_v18.
CREATE TABLE [bouquets] (
  id int PRIMARY KEY,
  name nvarchar(100) NOT NULL,
  event_at datetime2 NOT NULL,
  amount decimal(10,2) NOT NULL,
  link_id int NOT NULL,
  quantity int NOT NULL,
  expires_on date NOT NULL
);
INSERT INTO [bouquets] (id,name,event_at,amount,link_id,quantity,expires_on) VALUES
(1, N'bouquets 1', '2026-11-04 09:00:00', 10, 1, 1, '2026-11-10'),
(2, N'bouquets 2', '2026-11-03 12:00:00', 20, 2, 2, '2026-11-20'),
(3, N'bouquets 3', '2026-07-01 12:00:00', 30, 3, 3, '2026-11-07'),
(4, N'bouquets 4', '2026-11-05 12:00:00', 40, 4, 4, '2026-12-10');

CREATE TABLE [orders] (
  id int PRIMARY KEY,
  name nvarchar(100) NOT NULL,
  event_at datetime2 NOT NULL,
  amount decimal(10,2) NOT NULL,
  link_id int NOT NULL,
  quantity int NOT NULL,
  expires_on date NOT NULL
);
INSERT INTO [orders] (id,name,event_at,amount,link_id,quantity,expires_on) VALUES
(1, N'orders 1', '2026-11-04 09:00:00', 10, 1, 1, '2026-11-10'),
(2, N'orders 2', '2026-11-03 12:00:00', 20, 2, 2, '2026-11-20'),
(3, N'orders 3', '2026-07-01 12:00:00', 30, 3, 3, '2026-11-07'),
(4, N'orders 4', '2026-11-05 12:00:00', 40, 4, 4, '2026-12-10');

CREATE TABLE [clients] (
  id int PRIMARY KEY,
  name nvarchar(100) NOT NULL,
  event_at datetime2 NOT NULL,
  amount decimal(10,2) NOT NULL,
  link_id int NOT NULL,
  quantity int NOT NULL,
  expires_on date NOT NULL
);
INSERT INTO [clients] (id,name,event_at,amount,link_id,quantity,expires_on) VALUES
(1, N'clients 1', '2026-11-04 09:00:00', 10, 1, 1, '2026-11-10'),
(2, N'clients 2', '2026-11-03 12:00:00', 20, 2, 2, '2026-11-20'),
(3, N'clients 3', '2026-07-01 12:00:00', 30, 3, 3, '2026-11-07'),
(4, N'clients 4', '2026-11-05 12:00:00', 40, 4, 4, '2026-12-10');

CREATE TABLE access_probe (id int PRIMARY KEY, value int NOT NULL);
INSERT INTO access_probe VALUES (1,10);
