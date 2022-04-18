-- insert into "user" (id, username, password, email) values 
    -- (1, 'user1', '$argon2id$v=19$m=4096,t=3,p=1$PurNCF1Y9tu+ETV/3yHSqA$mrMyoQ7YQbf+s9/30Bfma8VPlykLnC17dN2wG3zl9qc', 'email1'); -- "user1-passwd"

insert into platform (id, name, credential) values 
    (1, 'wodify', true),
    (2, 'sportstracker', true);

insert into action_provider (id, name, password, platform_id, description) values
    (1, 'wodify-login', '$argon2id$v=19$m=4096,t=3,p=1$NZeOJg1K37UlxV5wB7yFhg$C7HNfVK9yLZTJyvJNSOhvYRfUK+nGo1rz0lIck1aO6c', 1, 
        'Wodify Login can reserve spots in classes. The action names correspond to the class types.'), -- "wodify-login-passwd"
    (2, 'wodify-wod', '$argon2id$v=19$m=4096,t=3,p=1$FscunZHcMdL3To4Zxc5z5w$InsqwdstEFdkszaokG1rk0HS0oazMm4zTynD6pjQEgw', 1,  
        'Wodify Wod can fetch the Workout of the Day and save it in your wods. The action names correspond to the class type the wod should be fetched for.'), -- "wodify-wod-passwd"
    (3, 'sportstracker-fetch', '$argon2id$v=19$m=4096,t=3,p=1$mmRowryKPKBhRSvrRZRFmg$VPInpHpMq47ZEymwSojrst+CWVOoHopBlvSIwybchAg', 2,  
        'Sportstracker Fetch can fetch the latests workouts recorded with sportstracker and save them in your cardio sessions.'); -- "sportstracker-fetch-passwd"

insert into action (id, name, action_provider_id, description, create_before, delete_after) values 
    (1, 'CrossFit', 1, 'Reserve a spot in a CrossFit class.', 604800000, 0), 
    (2, 'Weightlifting', 1, 'Reserve a spot in a Weightlifting class.', 604800000, 0), 
    (3, 'Open Fridge', 1, 'Reserve a spot in a Open Fridge class.', 604800000, 0),
    (4, 'CrossFit', 2, 'Fetch and save the CrossFit wod for the current day.', 604800000, 0), 
    (5, 'Weightlifting', 2, 'Fetch and save the Weightlifting wod for the current day.', 604800000, 0), 
    (6, 'Open Fridge', 2, 'Fetch and save the Open Fridge wod for the current day.', 604800000, 0), 
    (7, 'fetch', 3, 'Fetch and save new workouts.', 604800000, 0);

insert into movement (id, user_id, name, description, movement_dimension, cardio) values
    (1, null, 'Running', null, 'distance', true), -- outdoor
    (2, null, 'Running', null, 'energy', true),
    (3, null, 'Trailrunning', null, 'distance', true),
    (4, null, 'Hiking', null, 'distance', true),
    (5, null, 'Trekking', null, 'distance', true),
    (6, null, 'Ski Touring', null, 'distance', true),
    (7, null, 'Cross-Country Skiing', null, 'distance', true),
    (8, null, 'Alpine Skiing', null, 'distance', true),
    (9, null, 'Mountaineering', null, 'distance', true),
    (10, null, 'Biking', null, 'distance', true),
    (11, null, 'Mountainbiking', null, 'distance', true),
    (12, null, 'Swimming', null, 'distance', true),
    (13, null, 'Open Water Swimming', null, 'distance', true),
    (14, null, 'Row Erg', null, 'distance', false), -- erg
    (15, null, 'Row Erg', null, 'energy', false),
    (16, null, 'Bike Erg', null, 'distance', false),
    (17, null, 'Bike Erg', null, 'energy', false),
    (18, null, 'Ski Erg', null, 'distance', false),
    (19, null, 'Ski Erg', null, 'energy', false),
    (20, null, 'Echo Bike', null, 'distance', false),
    (21, null, 'Echo Bike', null, 'energy', false),
    (22, null, 'Back Squat', null, 'reps', false), -- squat
    (23, null, 'Front Squat', null, 'reps', false),
    (24, null, 'Dumbbell Front Squat', null, 'reps', false),
    (25, null, 'Overhead Squat', null, 'reps', false),
    (26, null, 'Dumbbell Overhead Squat', null, 'reps', false),
    (27, null, 'Bulgarian Split Squat', null, 'reps', false),
    (28, null, 'Lunge', null, 'reps', false), -- lunge
    (29, null, 'Dumbbell Lunge', null, 'reps', false),
    (30, null, 'Dumbbell Walking Lunge', null, 'distance', false),
    (31, null, 'Back Rack Lunge', null, 'reps', false),
    (32, null, 'Back Rack Walking Lunge', null, 'distance', false),
    (33, null, 'Front Rack Lunge', null, 'reps', false),
    (34, null, 'Dumbbell Front Rack Lunge', null, 'reps', false),
    (35, null, 'Front Rack Walking Lunge', null, 'distance', false),
    (36, null, 'Dumbbell Front Rack Walking Lunge', null, 'distance', false),
    (37, null, 'Overhead Lunge', null, 'reps', false),
    (38, null, 'Dumbbell Overhead Lunge', null, 'reps', false),
    (39, null, 'Overhead Walking Lunge', null, 'distance', false),
    (40, null, 'Dumbbell Overhead Walking Lunge', null, 'distance', false),
    (41, null, 'Deadlift', null, 'reps', false), -- deadlift
    (42, null, 'Dumbbell Deadlift', null, 'reps', false),
    (43, null, 'Romanian Deadlift', null, 'reps', false),
    (44, null, 'Sumo Deadlift High Pull', null, 'reps', false),
    (45, null, 'Good Morning', null, 'reps', false),
    (46, null, 'Bent Over Row', null, 'reps', false), -- rows
    (47, null, 'Dumbbell Bent Over Row', null, 'reps', false),
    (48, null, 'Bench Press', null, 'reps', false), -- bench, ohp 
    (49, null, 'Dumbbell Bench Press', null, 'reps', false),
    (50, null, 'Overhead Press', null, 'reps', false),
    (51, null, 'Dumbbell Overhead Press', null, 'reps', false),
    (52, null, 'Push Press', null, 'reps', false), -- jerk
    (53, null, 'Dumbbell Push Press', null, 'reps', false),
    (54, null, 'Push Jerk', null, 'reps', false),
    (55, null, 'Split Jerk', null, 'reps', false),
    (56, null, 'Shoulder To Overhead', null, 'reps', false),
    (57, null, 'Clean', null, 'reps', false), -- clean
    (58, null, 'Dumbbell Clean', null, 'reps', false),
    (59, null, 'Power Clean', null, 'reps', false),
    (60, null, 'Muscle Clean', null, 'reps', false),
    (61, null, 'Squat Clean', null, 'reps', false),
    (62, null, 'Hang Clean', null, 'reps', false),
    (63, null, 'Dumbbell Hang Clean', null, 'reps', false),
    (64, null, 'Hang Power Clean', null, 'reps', false),
    (65, null, 'Hang Squat Clean', null, 'reps', false),
    (66, null, 'Clean Pull', null, 'reps', false),
    (67, null, 'Clean & Jerk', null, 'reps', false), -- clean & jerk
    (68, null, 'Power Clean & Push Jerk', null, 'reps', false),
    (69, null, 'Truster', null, 'reps', false),
    (70, null, 'Ground To Overhead', null, 'reps', false),
    (71, null, 'Snatch', null, 'reps', false), -- snatch
    (72, null, 'Dumbbell Snatch', null, 'reps', false),
    (73, null, 'Power Snatch', null, 'reps', false),
    (74, null, 'Muscle Snatch', null, 'reps', false),
    (75, null, 'Squat Snatch', null, 'reps', false),
    (76, null, 'Hang Snatch', null, 'reps', false),
    (77, null, 'Hang Power Snatch', null, 'reps', false),
    (78, null, 'Hang Squat Snatch', null, 'reps', false),
    (79, null, 'Snatch Balance', null, 'reps', false),
    (80, null, 'Snatch High Pull', null, 'reps', false),
    (81, null, 'Turkish Get-up', null, 'reps', false), -- kettlebell
    (82, null, 'Russian Kettlebell Swing', null, 'reps', false),
    (83, null, 'American Kettlebell Swing', null, 'reps', false),
    (84, null, 'One Arm Kettlebell Swing', null, 'reps', false),
    (85, null, 'Goblet Squat', null, 'reps', false),
    (86, null, 'Kettlebell Snatch', null, 'reps', false),
    (87, null, 'Kettlebell Clean', null, 'reps', false),
    (88, null, 'Kettlebell Jerk', null, 'reps', false),
    (89, null, 'Kettlebell Clean & Jerk', null, 'reps', false),
    (90, null, 'Kettlebell Windmill', null, 'reps', false),
    (91, null, 'Farmers Carry', null, 'reps', false), -- strongman
    (92, null, 'Yoke Carry', null, 'reps', false),
    (93, null, 'Sled Push', null, 'reps', false),
    (94, null, 'Sled Pull', null, 'reps', false),
    (95, null, 'Air Squat', null, 'reps', false), -- bodyweight
    (96, null, 'Pistol', null, 'reps', false),
    (97, null, 'Push Up', null, 'reps', false),
    (98, null, 'Parallette Push Up', null, 'reps', false),
    (99, null, 'Dip', null, 'reps', false),
    (100, null, 'Burpee', null, 'reps', false),
    (101, null, 'Hand Stand Push Up', null, 'reps', false),
    (102, null, 'Strict Hand Stand Push Up', null, 'reps', false),
    (103, null, 'Free Stading Hand Stand Push Up', null, 'reps', false),
    (104, null, 'Deficit Hand Stand Push Up', null, 'reps', false),
    (105, null, 'Strict Deficit Hand Stand Push Up', null, 'reps', false),
    (106, null, 'Hang', null, 'reps', false),
    (107, null, 'Pull Up', null, 'reps', false),
    (108, null, 'Strict Pull Up', null, 'reps', false),
    (109, null, 'Chest To Bar Pull Up', null, 'reps', false),
    (110, null, 'Strict Chest To Bar Pull Up', null, 'reps', false),
    (111, null, 'Bar Muscle Up', null, 'reps', false),
    (112, null, 'Strict Bar Muscle Up', null, 'reps', false),
    (113, null, 'Toes To Bar', null, 'reps', false),
    (114, null, 'Strict Toes To Bar', null, 'reps', false),
    (115, null, 'Toes To Ring', null, 'reps', false), -- rings
    (116, null, 'Strict Toes To Ring', null, 'reps', false),
    (117, null, 'Ring Dip', null, 'reps', false),
    (118, null, 'Ring Row', null, 'reps', false),
    (119, null, 'Ring Muscle Up', null, 'reps', false),
    (120, null, 'Strict Ring Muscle Up', null, 'reps', false),
    (121, null, 'Ring L-Sit', null, 'reps', false),
    (122, null, 'Rope Climb', null, 'reps', false), -- rope
    (123, null, 'Legless Rope Climb', null, 'reps', false),
    (124, null, 'Wall Ball', null, 'reps', false), -- ball
    (125, null, 'Med Ball Clean', null, 'reps', false),
    (126, null, 'Back Extension', null, 'reps', false), -- GHD
    (127, null, 'Hip Extension', null, 'reps', false),
    (128, null, 'GHD Sit Up', null, 'reps', false),
    (129, null, 'Box Step Up', null, 'reps', false), -- jumps
    (130, null, 'Box Jump', null, 'reps', false),
    (131, null, 'Broad Jump', null, 'reps', false),
    (132, null, 'Burpee Broad Jump', null, 'reps', false),
    (133, null, 'Hand Stand', null, 'time', false), -- hand stand
    (134, null, 'Hand Stand Walk', null, 'distance', false),
    (135, null, 'Wall Climb', null, 'reps', false),
    (136, null, 'Plank', null, 'time', false), -- abs
    (137, null, 'Side Plank', null, 'time', false),
    (138, null, 'L-Sit', null, 'time', false),
    (139, null, 'Mountain Climbers', null, 'reps', false),
    (140, null, 'V-Up', null, 'reps', false),
    (141, null, 'Hollow Rock', null, 'reps', false),
    (142, null, 'Hollow Hold', null, 'time', false),
    (143, null, 'Single Under', null, 'reps', false), -- jump rope
    (144, null, 'Double Under', null, 'reps', false),
    (145, null, 'Tripple Under', null, 'reps', false);

insert into eorm (reps, percentage) values
    (1, 1.0),
    (2, 0.97),
    (3, 0.94),
    (4, 0.92),
    (5, 0.89),
    (6, 0.86),
    (7, 0.83),
    (8, 0.81),
    (9, 0.78),
    (10, 0.75),
    (11, 0.73),
    (12, 0.71),
    (13, 0.70),
    (14, 0.68),
    (15, 0.67),
    (16, 0.65),
    (17, 0.64),
    (18, 0.63),
    (19, 0.61),
    (20, 0.60),
    (21, 0.59),
    (22, 0.58),
    (23, 0.57),
    (24, 0.56),
    (25, 0.55),
    (26, 0.54),
    (27, 0.53),
    (28, 0.52),
    (29, 0.51),
    (30, 0.50);

insert into metcon (id, user_id, name, metcon_type, rounds, timecap, description) values
    (1, null, 'Cindy', 'amrap', null, 1200000, null),
    (2, null, 'Murph', 'for_time', 1, null, 'wear a weight vest (20/ 14 pounds)'),
    (3, null, '5k Row', 'for_time', 1, 1800000, null);

insert into metcon_movement (id, metcon_id, movement_id, distance_unit, movement_number, count, male_weight, female_weight) values
    (1, 1, 10, null, 0, 5, null, null),
    (2, 1, 11, null, 1, 10, null, null),
    (3, 1, 12, null, 2, 15, null, null),
    (4, 2, 5, null, 0, 1, 9, 6),
    (5, 2, 10, null, 1, 100, 9, 6),
    (6, 2, 11, null, 2, 200, 9, 6),
    (7, 2, 12, null, 3, 300, 9, 6),
    (8, 2, 5, null, 4, 1, 9, 6),
    (9, 3, 8, 'km', 0, 5, null, null);
