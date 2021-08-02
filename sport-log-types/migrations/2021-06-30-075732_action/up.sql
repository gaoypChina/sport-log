create type weekday as enum('monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday');

create table action_provider (
    id serial primary key,
    name varchar(80) not null unique check (length(name) >= 2),
    password char(96) not null,
    platform_id integer not null references platform on delete cascade
);
insert into action_provider (name, password, platform_id) values
    ('wodify-login', '$argon2id$v=19$m=4096,t=3,p=1$NZeOJg1K37UlxV5wB7yFhg$C7HNfVK9yLZTJyvJNSOhvYRfUK+nGo1rz0lIck1aO6c', 1), -- "wodify-login-passwd"
    ('wodify-wod', '$argon2id$v=19$m=4096,t=3,p=1$FscunZHcMdL3To4Zxc5z5w$InsqwdstEFdkszaokG1rk0HS0oazMm4zTynD6pjQEgw', 1), -- "wodify-wod-passwd"
    ('sportstracker-fetch', '$argon2id$v=19$m=4096,t=3,p=1$mmRowryKPKBhRSvrRZRFmg$VPInpHpMq47ZEymwSojrst+CWVOoHopBlvSIwybchAg', 2); -- "sportstracker-fetch-passwd"

create table action (
    id serial primary key,
    name varchar(80) not null check (length(name) >= 2),
    action_provider_id integer not null references action_provider on delete cascade,
    unique (action_provider_id, name)
);
insert into action (name, action_provider_id) values 
    ('Crossfit', 1), 
    ('Weightlifting', 1), 
    ('Open Fridge', 1),
    ('fetch', 2),
    ('fetch', 3);

create table action_rule (
    id serial primary key,
    user_id integer not null references "user" on delete cascade,
    action_id integer not null references action on delete cascade,
    weekday weekday not null, 
    time time not null,
    enabled boolean not null,
    unique (user_id, action_id, weekday, time, enabled)
);
insert into action_rule (user_id, action_id, weekday, time, enabled) values 
    (1, 1, 'monday', '09:00:00', true), 
    (1, 3, 'tuesday', '19:00:00', true),
    (1, 4, 'monday', '00:00:00', true),
    (1, 4, 'tuesday', '00:00:00', true),
    (1, 4, 'wednesday', '00:00:00', true),
    (1, 4, 'thursday', '00:00:00', true),
    (1, 4, 'friday', '00:00:00', true),
    (1, 4, 'saturday', '00:00:00', true),
    (1, 4, 'sunday', '00:00:00', true);

create table action_event (
    id serial primary key,
    user_id integer not null references "user" on delete cascade,
    action_id integer not null references action on delete cascade,
    datetime timestamp not null,
    enabled boolean not null,
    unique (user_id, action_id, datetime, enabled)
);
insert into action_event (user_id, action_id, datetime, enabled) values 
    (1, 1, '2021-07-01 09:00:00', true), 
    (1, 1, '2021-07-02 09:00:00', true), 
    (1, 1, '2021-07-03 09:00:00', true), 
    (1, 3, '2021-07-04 19:00:00', false), 
    (2, 1, '2021-07-01 09:00:00', true), 
    (2, 2, '2021-07-02 09:00:00', true), 
    (2, 1, '2021-07-03 09:00:00', true), 
    (2, 2, '2021-07-04 19:00:00', false),
    (1, 4, '2021-08-29 00:00:00', true), 
    (1, 4, '2021-08-30 00:00:00', true), 
    (1, 5, '2021-07-01 09:00:00', true), 
    (1, 5, '2021-07-01 10:00:00', true), 
    (1, 5, '2021-07-01 11:00:00', true),
    (3, 5, '2021-07-01 09:00:00', true), 
    (3, 5, '2021-07-01 10:00:00', true), 
    (3, 5, '2021-07-01 11:00:00', true); 
