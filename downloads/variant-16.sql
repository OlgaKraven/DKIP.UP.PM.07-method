-- Учебные исходные данные варианта 16. Открыть в пустой базе pm07_v16.
CREATE TABLE "animals" (
  id int PRIMARY KEY,
  name varchar(100) NOT NULL,
  event_at timestamp NOT NULL,
  amount decimal(10,2) NOT NULL,
  link_id int NOT NULL,
  quantity int NOT NULL,
  expires_on date NOT NULL
);
INSERT INTO "animals" (id,name,event_at,amount,link_id,quantity,expires_on) VALUES
(1, 'animals 1', '2026-11-04 09:00:00', 10, 1, 1, '2026-11-10'),
(2, 'animals 2', '2026-11-03 12:00:00', 20, 2, 2, '2026-11-20'),
(3, 'animals 3', '2026-07-01 12:00:00', 30, 3, 3, '2026-11-07'),
(4, 'animals 4', '2026-11-05 12:00:00', 40, 4, 4, '2026-12-10');

CREATE TABLE "owners" (
  id int PRIMARY KEY,
  name varchar(100) NOT NULL,
  event_at timestamp NOT NULL,
  amount decimal(10,2) NOT NULL,
  link_id int NOT NULL,
  quantity int NOT NULL,
  expires_on date NOT NULL
);
INSERT INTO "owners" (id,name,event_at,amount,link_id,quantity,expires_on) VALUES
(1, 'owners 1', '2026-11-04 09:00:00', 10, 1, 1, '2026-11-10'),
(2, 'owners 2', '2026-11-03 12:00:00', 20, 2, 2, '2026-11-20'),
(3, 'owners 3', '2026-07-01 12:00:00', 30, 3, 3, '2026-11-07'),
(4, 'owners 4', '2026-11-05 12:00:00', 40, 4, 4, '2026-12-10');

CREATE TABLE "visits" (
  id int PRIMARY KEY,
  name varchar(100) NOT NULL,
  event_at timestamp NOT NULL,
  amount decimal(10,2) NOT NULL,
  link_id int NOT NULL,
  quantity int NOT NULL,
  expires_on date NOT NULL
);
INSERT INTO "visits" (id,name,event_at,amount,link_id,quantity,expires_on) VALUES
(1, 'visits 1', '2026-11-04 09:00:00', 10, 1, 1, '2026-11-10'),
(2, 'visits 2', '2026-11-03 12:00:00', 20, 2, 2, '2026-11-20'),
(3, 'visits 3', '2026-07-01 12:00:00', 30, 3, 3, '2026-11-07'),
(4, 'visits 4', '2026-11-05 12:00:00', 40, 4, 4, '2026-12-10');

CREATE TABLE access_probe (id int PRIMARY KEY, value int NOT NULL);
INSERT INTO access_probe VALUES (1,10);
