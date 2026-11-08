-- Учебные исходные данные варианта образец. Открыть в пустой базе pm07_demo.
CREATE TABLE "devices" (
  id int PRIMARY KEY,
  name varchar(100) NOT NULL,
  event_at timestamp NOT NULL,
  amount decimal(10,2) NOT NULL,
  link_id int NOT NULL,
  quantity int NOT NULL,
  expires_on date NOT NULL
);
INSERT INTO "devices" (id,name,event_at,amount,link_id,quantity,expires_on) VALUES
(1, 'devices 1', '2026-11-04 09:00:00', 10, 1, 1, '2026-11-10'),
(2, 'devices 2', '2026-11-03 12:00:00', 20, 2, 2, '2026-11-20'),
(3, 'devices 3', '2026-07-01 12:00:00', 30, 3, 3, '2026-11-07'),
(4, 'devices 4', '2026-11-05 12:00:00', 40, 4, 4, '2026-12-10');

CREATE TABLE "locations" (
  id int PRIMARY KEY,
  name varchar(100) NOT NULL,
  event_at timestamp NOT NULL,
  amount decimal(10,2) NOT NULL,
  link_id int NOT NULL,
  quantity int NOT NULL,
  expires_on date NOT NULL
);
INSERT INTO "locations" (id,name,event_at,amount,link_id,quantity,expires_on) VALUES
(1, 'locations 1', '2026-11-04 09:00:00', 10, 1, 1, '2026-11-10'),
(2, 'locations 2', '2026-11-03 12:00:00', 20, 2, 2, '2026-11-20'),
(3, 'locations 3', '2026-07-01 12:00:00', 30, 3, 3, '2026-11-07'),
(4, 'locations 4', '2026-11-05 12:00:00', 40, 4, 4, '2026-12-10');

CREATE TABLE "checks" (
  id int PRIMARY KEY,
  name varchar(100) NOT NULL,
  event_at timestamp NOT NULL,
  amount decimal(10,2) NOT NULL,
  link_id int NOT NULL,
  quantity int NOT NULL,
  expires_on date NOT NULL
);
INSERT INTO "checks" (id,name,event_at,amount,link_id,quantity,expires_on) VALUES
(1, 'checks 1', '2026-11-04 09:00:00', 10, 1, 1, '2026-11-10'),
(2, 'checks 2', '2026-11-03 12:00:00', 20, 2, 2, '2026-11-20'),
(3, 'checks 3', '2026-07-01 12:00:00', 30, 3, 3, '2026-11-07'),
(4, 'checks 4', '2026-11-05 12:00:00', 40, 4, 4, '2026-12-10');

CREATE TABLE access_probe (id int PRIMARY KEY, value int NOT NULL);
INSERT INTO access_probe VALUES (1,10);
