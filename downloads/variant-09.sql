-- Учебные исходные данные варианта 9. Открыть в пустой базе pm07_v09.
CREATE TABLE "tours" (
  id int PRIMARY KEY,
  name varchar(100) NOT NULL,
  event_at timestamp NOT NULL,
  amount decimal(10,2) NOT NULL,
  link_id int NOT NULL,
  quantity int NOT NULL,
  expires_on date NOT NULL
);
INSERT INTO "tours" (id,name,event_at,amount,link_id,quantity,expires_on) VALUES
(1, 'tours 1', '2026-11-04 09:00:00', 10, 1, 1, '2026-11-10'),
(2, 'tours 2', '2026-11-03 12:00:00', 20, 2, 2, '2026-11-20'),
(3, 'tours 3', '2026-07-01 12:00:00', 30, 3, 3, '2026-11-07'),
(4, 'tours 4', '2026-11-05 12:00:00', 40, 4, 4, '2026-12-10');

CREATE TABLE "clients" (
  id int PRIMARY KEY,
  name varchar(100) NOT NULL,
  event_at timestamp NOT NULL,
  amount decimal(10,2) NOT NULL,
  link_id int NOT NULL,
  quantity int NOT NULL,
  expires_on date NOT NULL
);
INSERT INTO "clients" (id,name,event_at,amount,link_id,quantity,expires_on) VALUES
(1, 'clients 1', '2026-11-04 09:00:00', 10, 1, 1, '2026-11-10'),
(2, 'clients 2', '2026-11-03 12:00:00', 20, 2, 2, '2026-11-20'),
(3, 'clients 3', '2026-07-01 12:00:00', 30, 3, 3, '2026-11-07'),
(4, 'clients 4', '2026-11-05 12:00:00', 40, 4, 4, '2026-12-10');

CREATE TABLE "bookings" (
  id int PRIMARY KEY,
  name varchar(100) NOT NULL,
  event_at timestamp NOT NULL,
  amount decimal(10,2) NOT NULL,
  link_id int NOT NULL,
  quantity int NOT NULL,
  expires_on date NOT NULL
);
INSERT INTO "bookings" (id,name,event_at,amount,link_id,quantity,expires_on) VALUES
(1, 'bookings 1', '2026-11-04 09:00:00', 10, 1, 1, '2026-11-10'),
(2, 'bookings 2', '2026-11-03 12:00:00', 20, 2, 2, '2026-11-20'),
(3, 'bookings 3', '2026-07-01 12:00:00', 30, 3, 3, '2026-11-07'),
(4, 'bookings 4', '2026-11-05 12:00:00', 40, 4, 4, '2026-12-10');

CREATE TABLE access_probe (id int PRIMARY KEY, value int NOT NULL);
INSERT INTO access_probe VALUES (1,10);
