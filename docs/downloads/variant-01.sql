-- Учебные исходные данные варианта 1. Открыть в пустой базе pm07_v01.
CREATE TABLE `books` (
  id int PRIMARY KEY,
  name varchar(100) NOT NULL,
  event_at datetime NOT NULL,
  amount decimal(10,2) NOT NULL,
  link_id int NOT NULL,
  quantity int NOT NULL,
  expires_on date NOT NULL
);
INSERT INTO `books` (id,name,event_at,amount,link_id,quantity,expires_on) VALUES
(1, 'books 1', '2026-11-04 09:00:00', 10, 1, 1, '2026-11-10'),
(2, 'books 2', '2026-11-03 12:00:00', 20, 2, 2, '2026-11-20'),
(3, 'books 3', '2026-07-01 12:00:00', 30, 3, 3, '2026-11-07'),
(4, 'books 4', '2026-11-05 12:00:00', 40, 4, 4, '2026-12-10');

CREATE TABLE `readers` (
  id int PRIMARY KEY,
  name varchar(100) NOT NULL,
  event_at datetime NOT NULL,
  amount decimal(10,2) NOT NULL,
  link_id int NOT NULL,
  quantity int NOT NULL,
  expires_on date NOT NULL
);
INSERT INTO `readers` (id,name,event_at,amount,link_id,quantity,expires_on) VALUES
(1, 'readers 1', '2026-11-04 09:00:00', 10, 1, 1, '2026-11-10'),
(2, 'readers 2', '2026-11-03 12:00:00', 20, 2, 2, '2026-11-20'),
(3, 'readers 3', '2026-07-01 12:00:00', 30, 3, 3, '2026-11-07'),
(4, 'readers 4', '2026-11-05 12:00:00', 40, 4, 4, '2026-12-10');

CREATE TABLE `book_issues` (
  id int PRIMARY KEY,
  name varchar(100) NOT NULL,
  event_at datetime NOT NULL,
  amount decimal(10,2) NOT NULL,
  link_id int NOT NULL,
  quantity int NOT NULL,
  expires_on date NOT NULL
);
INSERT INTO `book_issues` (id,name,event_at,amount,link_id,quantity,expires_on) VALUES
(1, 'book_issues 1', '2026-11-04 09:00:00', 10, 1, 1, '2026-11-10'),
(2, 'book_issues 2', '2026-11-03 12:00:00', 20, 2, 2, '2026-11-20'),
(3, 'book_issues 3', '2026-07-01 12:00:00', 30, 3, 3, '2026-11-07'),
(4, 'book_issues 4', '2026-11-05 12:00:00', 40, 4, 4, '2026-12-10');

CREATE TABLE access_probe (id int PRIMARY KEY, value int NOT NULL);
INSERT INTO access_probe VALUES (1,10);
