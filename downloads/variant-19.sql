-- Учебные исходные данные варианта 19. Открыть в пустой базе pm07_v19.
CREATE TABLE [objects] (
  id int PRIMARY KEY,
  name nvarchar(100) NOT NULL,
  event_at datetime2 NOT NULL,
  amount decimal(10,2) NOT NULL,
  link_id int NOT NULL,
  quantity int NOT NULL,
  expires_on date NOT NULL
);
INSERT INTO [objects] (id,name,event_at,amount,link_id,quantity,expires_on) VALUES
(1, N'objects 1', '2026-11-04 09:00:00', 10, 1, 1, '2026-11-10'),
(2, N'objects 2', '2026-11-03 12:00:00', 20, 2, 2, '2026-11-20'),
(3, N'objects 3', '2026-07-01 12:00:00', 30, 3, 3, '2026-11-07'),
(4, N'objects 4', '2026-11-05 12:00:00', 40, 4, 4, '2026-12-10');

CREATE TABLE [agents] (
  id int PRIMARY KEY,
  name nvarchar(100) NOT NULL,
  event_at datetime2 NOT NULL,
  amount decimal(10,2) NOT NULL,
  link_id int NOT NULL,
  quantity int NOT NULL,
  expires_on date NOT NULL
);
INSERT INTO [agents] (id,name,event_at,amount,link_id,quantity,expires_on) VALUES
(1, N'agents 1', '2026-11-04 09:00:00', 10, 1, 1, '2026-11-10'),
(2, N'agents 2', '2026-11-03 12:00:00', 20, 2, 2, '2026-11-20'),
(3, N'agents 3', '2026-07-01 12:00:00', 30, 3, 3, '2026-11-07'),
(4, N'agents 4', '2026-11-05 12:00:00', 40, 4, 4, '2026-12-10');

CREATE TABLE [deals] (
  id int PRIMARY KEY,
  name nvarchar(100) NOT NULL,
  event_at datetime2 NOT NULL,
  amount decimal(10,2) NOT NULL,
  link_id int NOT NULL,
  quantity int NOT NULL,
  expires_on date NOT NULL
);
INSERT INTO [deals] (id,name,event_at,amount,link_id,quantity,expires_on) VALUES
(1, N'deals 1', '2026-11-04 09:00:00', 10, 1, 1, '2026-11-10'),
(2, N'deals 2', '2026-11-03 12:00:00', 20, 2, 2, '2026-11-20'),
(3, N'deals 3', '2026-07-01 12:00:00', 30, 3, 3, '2026-11-07'),
(4, N'deals 4', '2026-11-05 12:00:00', 40, 4, 4, '2026-12-10');

CREATE TABLE access_probe (id int PRIMARY KEY, value int NOT NULL);
INSERT INTO access_probe VALUES (1,10);
