-- Учебные исходные данные варианта 23. Открыть в пустой базе pm07_v23.
CREATE TABLE "routes" (
  id int PRIMARY KEY,
  name varchar(100) NOT NULL,
  event_at timestamp NOT NULL,
  amount decimal(10,2) NOT NULL,
  link_id int NOT NULL,
  quantity int NOT NULL,
  expires_on date NOT NULL
);
INSERT INTO "routes" (id,name,event_at,amount,link_id,quantity,expires_on) VALUES
(1, 'routes 1', '2026-11-04 09:00:00', 10, 1, 1, '2026-11-10'),
(2, 'routes 2', '2026-11-03 12:00:00', 20, 2, 2, '2026-11-20'),
(3, 'routes 3', '2026-07-01 12:00:00', 30, 3, 3, '2026-11-07'),
(4, 'routes 4', '2026-11-05 12:00:00', 40, 4, 4, '2026-12-10');

CREATE TABLE "drivers" (
  id int PRIMARY KEY,
  name varchar(100) NOT NULL,
  event_at timestamp NOT NULL,
  amount decimal(10,2) NOT NULL,
  link_id int NOT NULL,
  quantity int NOT NULL,
  expires_on date NOT NULL
);
INSERT INTO "drivers" (id,name,event_at,amount,link_id,quantity,expires_on) VALUES
(1, 'drivers 1', '2026-11-04 09:00:00', 10, 1, 1, '2026-11-10'),
(2, 'drivers 2', '2026-11-03 12:00:00', 20, 2, 2, '2026-11-20'),
(3, 'drivers 3', '2026-07-01 12:00:00', 30, 3, 3, '2026-11-07'),
(4, 'drivers 4', '2026-11-05 12:00:00', 40, 4, 4, '2026-12-10');

CREATE TABLE "vehicles" (
  id int PRIMARY KEY,
  name varchar(100) NOT NULL,
  event_at timestamp NOT NULL,
  amount decimal(10,2) NOT NULL,
  link_id int NOT NULL,
  quantity int NOT NULL,
  expires_on date NOT NULL
);
INSERT INTO "vehicles" (id,name,event_at,amount,link_id,quantity,expires_on) VALUES
(1, 'vehicles 1', '2026-11-04 09:00:00', 10, 1, 1, '2026-11-10'),
(2, 'vehicles 2', '2026-11-03 12:00:00', 20, 2, 2, '2026-11-20'),
(3, 'vehicles 3', '2026-07-01 12:00:00', 30, 3, 3, '2026-11-07'),
(4, 'vehicles 4', '2026-11-05 12:00:00', 40, 4, 4, '2026-12-10');

CREATE TABLE access_probe (id int PRIMARY KEY, value int NOT NULL);
INSERT INTO access_probe VALUES (1,10);
