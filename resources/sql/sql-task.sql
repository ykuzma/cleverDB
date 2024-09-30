--Вывести к каждому самолету класс обслуживания и количество мест этого класса

select aircraft_code, model, fare_conditions, count(seat_no) as count_seats
from aircrafts_data
         inner join seats using (aircraft_code)
group by aircraft_code, fare_conditions;

--Найти 3 самых вместительных самолета (модель + кол-во мест)
select model, count(seat_no) as count_seats
from aircrafts_data
         inner join seats using (aircraft_code)
group by aircraft_code
order by count_seats desc limit 3;

--Найти все рейсы, которые задерживались более 2 часов

SELECT flight_id, scheduled_departure, actual_departure
FROM flights
where (status in ('Arrived', 'Departed') and extract(epoch from actual_departure - scheduled_departure) > 2 * 60 * 60)
   or (status like 'Delayed' and extract(epoch from bookings.now() - scheduled_departure) > 2 * 60 * 60);

--Найти последние 10 билетов, купленные в бизнес-классе (fare_conditions = 'Business'),
-- с указанием имени пассажира и контактных данных

select ticket_no, passenger_name, contact_data, fare_conditions
from tickets
         inner join ticket_flights using (ticket_no)
         inner join bookings using (book_ref)
where fare_conditions = 'Business'
order by book_date desc limit 10;


--Найти все рейсы, у которых нет забронированных мест в бизнес-классе (fare_conditions = 'Business')

select flight_id
from flights
where flight_id not in
      (select flight_id
       from flights
                inner join ticket_flights using (flight_id)
       where fare_conditions = 'Business'
       group by flight_id);

--Получить список аэропортов (airport_name) и городов (city), в которых есть рейсы с задержкой по вылету
select airport_name, city
from airports_data
         inner join flights on airports_data.airport_code = departure_airport
where status = 'Delayed'
group by airport_name, city;


--Получить список аэропортов (airport_name) и количество рейсов,
-- вылетающих из каждого аэропорта, отсортированный по убыванию количества рейсов

select airport_name, count(flight_id) as count_flight
from airports_data
         inner join flights on airports_data.airport_code = departure_airport
where status in ('Scheduled', 'On time', 'Delayed')
group by airport_name
order by count_flight desc;

--Найти все рейсы, у которых запланированное время прибытия (scheduled_arrival)
-- было изменено и новое время прибытия (actual_arrival) не совпадает с запланированным

SELECT flight_id, scheduled_arrival, actual_arrival
FROM flights
where status = 'Arrived' and extract(epoch from actual_arrival - scheduled_arrival) != 0;

--Вывести код, модель самолета и места не эконом класса
-- для самолета "Аэробус A321-200" с сортировкой по местам

select aircraft_code, model, seat_no
from aircrafts_data
         inner join seats using (aircraft_code)
where fare_conditions != 'Economy' and model ->> 'ru' = 'Аэробус A321-200'
order by seat_no;

--Вывести города, в которых больше 1 аэропорта (код аэропорта, аэропорт, город)

select airport_code, (airport_name ->> 'ru') as airport,  (city ->> 'ru')as city
from airports_data
where city in (select city from airports_data
                          group by city
                          having count(airport_code) > 1);

--Найти пассажиров, у которых суммарная стоимость бронирований превышает среднюю сумму всех бронирований

select passenger_id, passenger_name, total_amount
from bookings
         inner join tickets using (book_ref)
where total_amount > (select avg(total_amount)
                      from bookings);

--Найти ближайший вылетающий рейс из Екатеринбурга в Москву, на который еще не завершилась регистрация

select flight_id, departure_city, arrival_city, flights.scheduled_departure
from flights
         inner join flights_v using (flight_id)
where arrival_city = 'Москва'
  and departure_city = 'Екатеринбург'
  and flights.status in ('On time', 'Delayed', 'Scheduled')
order by flights.scheduled_departure limit 1;

--Вывести самый дешевый и дорогой билет и стоимость (в одном результирующем ответе)

select max(amount) as max_amount, min(amount) as min_amount
from ticket_flights;

--Написать DDL таблицы Customers, должны быть поля id, firstName, LastName, email, phone.
-- Добавить ограничения на поля (constraints)

create table Customers
(
    id        bigint primary key generated always as identity,
    firstName varchar(100) not null,
    lastName  varchar(100) not null,
    email     varchar(50)  not null,
    phone     varchar(30),

    CONSTRAINT proper_email CHECK (email ~* '^[A-Za-z0-9._+%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$')

);

--    Написать DDL таблицы Orders, должен быть id, customerId, quantity.
--    Должен быть внешний ключ на таблицу customers + constraints


create table Orders
(
    id         bigint primary key generated always as identity,
    customerId bigint references customers (id) on delete cascade,
    quantity   int not null check ( quantity > 0 )
);

--Написать 5 insert в эти таблицы

insert into Customers
(firstName, lastName, email, phone)
VALUES ('Aleksander', 'Petrov', 'petrov@mail.ru', '888888888'),
       ('Sergey', 'Burunov', 'burunduk@gmail.com', null),
       ('Marat', 'Izmailov', 'marra@yandex.ru', '33333333'),
       ('Vladimir', 'Yakovlev', 'bess1980@mail.com', null),
       ('Vasia', 'Rogov', 'niva_green99@mail.ru', '020202');

insert into Orders
(customerId, quantity)
VALUES (2, 5),
       (3, 3),
       (1, 1),
       (2, 6),
       (2, 48);

--Удалить таблицы

drop  table Customers, Orders;

