CREATE SCHEMA pizza_runner;
SET search_path = pizza_runner;

DROP TABLE IF EXISTS runners;
CREATE TABLE runners (
  "runner_id" INTEGER,
  "registration_date" DATE
);
INSERT INTO runners
  ("runner_id", "registration_date")
VALUES
  (1, '2021-01-01'),
  (2, '2021-01-03'),
  (3, '2021-01-08'),
  (4, '2021-01-15');


DROP TABLE IF EXISTS customer_orders;
CREATE TABLE customer_orders (
  "order_id" INTEGER,
  "customer_id" INTEGER,
  "pizza_id" INTEGER,
  "exclusions" VARCHAR(4),
  "extras" VARCHAR(4),
  "order_time" TIMESTAMP
);

INSERT INTO customer_orders
  ("order_id", "customer_id", "pizza_id", "exclusions", "extras", "order_time")
VALUES
  ('1', '101', '1', '', '', '2020-01-01 18:05:02'),
  ('2', '101', '1', '', '', '2020-01-01 19:00:52'),
  ('3', '102', '1', '', '', '2020-01-02 23:51:23'),
  ('3', '102', '2', '', NULL, '2020-01-02 23:51:23'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '2', '4', '', '2020-01-04 13:23:46'),
  ('5', '104', '1', 'null', '1', '2020-01-08 21:00:29'),
  ('6', '101', '2', 'null', 'null', '2020-01-08 21:03:13'),
  ('7', '105', '2', 'null', '1', '2020-01-08 21:20:29'),
  ('8', '102', '1', 'null', 'null', '2020-01-09 23:54:33'),
  ('9', '103', '1', '4', '1, 5', '2020-01-10 11:22:59'),
  ('10', '104', '1', 'null', 'null', '2020-01-11 18:34:49'),
  ('10', '104', '1', '2, 6', '1, 4', '2020-01-11 18:34:49');


DROP TABLE IF EXISTS runner_orders;
CREATE TABLE runner_orders (
  "order_id" INTEGER,
  "runner_id" INTEGER,
  "pickup_time" VARCHAR(19),
  "distance" VARCHAR(7),
  "duration" VARCHAR(10),
  "cancellation" VARCHAR(23)
);

INSERT INTO runner_orders
  ("order_id", "runner_id", "pickup_time", "distance", "duration", "cancellation")
VALUES
  ('1', '1', '2020-01-01 18:15:34', '20km', '32 minutes', ''),
  ('2', '1', '2020-01-01 19:10:54', '20km', '27 minutes', ''),
  ('3', '1', '2020-01-03 00:12:37', '13.4km', '20 mins', NULL),
  ('4', '2', '2020-01-04 13:53:03', '23.4', '40', NULL),
  ('5', '3', '2020-01-08 21:10:57', '10', '15', NULL),
  ('6', '3', 'null', 'null', 'null', 'Restaurant Cancellation'),
  ('7', '2', '2020-01-08 21:30:45', '25km', '25mins', 'null'),
  ('8', '2', '2020-01-10 00:15:02', '23.4 km', '15 minute', 'null'),
  ('9', '2', 'null', 'null', 'null', 'Customer Cancellation'),
  ('10', '1', '2020-01-11 18:50:20', '10km', '10minutes', 'null');


DROP TABLE IF EXISTS pizza_names;
CREATE TABLE pizza_names (
  "pizza_id" INTEGER,
  "pizza_name" TEXT
);
INSERT INTO pizza_names
  ("pizza_id", "pizza_name")
VALUES
  (1, 'Meatlovers'),
  (2, 'Vegetarian');


DROP TABLE IF EXISTS pizza_recipes;
CREATE TABLE pizza_recipes (
  "pizza_id" INTEGER,
  "toppings" TEXT
);
INSERT INTO pizza_recipes
  ("pizza_id", "toppings")
VALUES
  (1, '1, 2, 3, 4, 5, 6, 8, 10'),
  (2, '4, 6, 7, 9, 11, 12');


DROP TABLE IF EXISTS pizza_toppings;
CREATE TABLE pizza_toppings (
  "topping_id" INTEGER,
  "topping_name" TEXT
);
INSERT INTO pizza_toppings
  ("topping_id", "topping_name")
VALUES
  (1, 'Bacon'),
  (2, 'BBQ Sauce'),
  (3, 'Beef'),
  (4, 'Cheese'),
  (5, 'Chicken'),
  (6, 'Mushrooms'),
  (7, 'Onions'),
  (8, 'Pepperoni'),
  (9, 'Peppers'),
  (10, 'Salami'),
  (11, 'Tomatoes'),
  (12, 'Tomato Sauce');
  
  -- Replace 'null' string and empty string in exclusions with actual NULL
UPDATE pizza_runner.customer_orders
SET exclusions = NULL
WHERE exclusions = '' OR exclusions = 'null' OR exclusions IS NULL;

-- Replace 'null' string and NaN in extras with actual NULL
UPDATE pizza_runner.customer_orders
SET extras = NULL
WHERE extras = '' OR extras = 'null' OR extras IS NULL;

-- Remove duplicates
DELETE FROM pizza_runner.customer_orders
WHERE ctid NOT IN (
  SELECT min(ctid)
  FROM pizza_runner.customer_orders
  GROUP BY order_id, customer_id, pizza_id, exclusions, extras, order_time
);

-- Remove 'km' from distance and convert the column to numeric data type
UPDATE pizza_runner.runner_orders
SET distance = REPLACE(distance, 'km', '')::numeric
WHERE distance IS NOT NULL AND distance != 'null';

-- Remove 'minutes' and 'mins' from duration and convert the column to numeric data type
UPDATE pizza_runner.runner_orders
SET duration = REPLACE(REPLACE(REPLACE(duration, 'minutes', ''), 'mins', ''), 'minute', '')::numeric
WHERE duration IS NOT NULL AND duration != 'null';


-- Replace 'null' string in pickup_time, distance, duration, and cancellation with actual NULL
UPDATE pizza_runner.runner_orders
SET pickup_time = NULL
WHERE pickup_time = 'null' OR pickup_time IS NULL;

UPDATE pizza_runner.runner_orders
SET distance = NULL
WHERE distance::text = 'null' OR distance IS NULL;

UPDATE pizza_runner.runner_orders
SET duration = NULL
WHERE duration::text = 'null' OR duration IS NULL;

UPDATE pizza_runner.runner_orders
SET cancellation = CASE 
    WHEN cancellation = '' OR cancellation = 'null' OR cancellation is null THEN 'no cancellation'
    ELSE cancellation
    END;

--Normalizing the pizza_recipes table

-- Create new_pizza_recipes table
CREATE TABLE new_pizza_recipes (
    pizza_id INT,
    topping_id INT
);

-- Insert data into new_pizza_recipes
INSERT INTO new_pizza_recipes (pizza_id, topping_id)
SELECT 1, unnest(ARRAY[1,2,3,4,5,6,8,10]) 
UNION ALL
SELECT 2, unnest(ARRAY[4,6,7,9,11,12]);



CREATE TABLE runner_ratings (
  "rating_id" SERIAL PRIMARY KEY,
  "order_id" INTEGER NOT NULL,
  "runner_id" INTEGER NOT NULL,
  "customer_id" INTEGER NOT NULL,
  "rating" INTEGER CHECK (rating BETWEEN 1 AND 5),
  "comments" TEXT
);

INSERT INTO runner_ratings ("order_id", "runner_id", "customer_id", "rating", "comments")
VALUES
  (1, 1, 101, 5, 'Great service!'),
  (2, 1, 101, 4, 'On time delivery'),
  (3, 1, 102, 4, NULL),
  (4, 2, 103, 3, 'Food was cold'),
  (5, 3, 104, 5, 'Friendly runner'),
  (7, 2, 105, 4, NULL),
  (8, 2, 102, 3, 'Late delivery'),
  (10, 1, 104, 5, 'Excellent!');



--Inserting a new pizza name into the pizza_names table:
INSERT INTO pizza_runner.pizza_names (pizza_id, pizza_name)
VALUES (3, 'Supreme');

--Inserting the corresponding toppings into the new_pizza_recipes table:

INSERT INTO pizza_runner.new_pizza_recipes (pizza_id, topping_id)
VALUES
(3, 1),
(3, 2),
(3, 3),
(3, 4),
(3, 5),
(3, 6),
(3, 7),
(3, 8),
(3, 9),
(3, 10),
(3, 11),
(3, 12);
