SET search_path = pizza_runner;

-- cleaning dirty columns first and creating temporary tables

DROP TABLE IF EXISTS CUSTOMER_ORDERS_CLEAN;
CREATE TEMP TABLE CUSTOMER_ORDERS_CLEAN AS
SELECT
	ROW_NUMBER() OVER() as _id,
	order_id,
	customer_id,
	pizza_id,
	(CASE WHEN exclusions ~ '^[0-9]' THEN exclusions ELSE null END) as exclusions,
	(CASE WHEN extras ~ '^[0-9]' THEN extras ELSE null END) as extras,
	order_time
FROM customer_orders;

DROP TABLE IF EXISTS RUNNER_ORDERS_CLEAN;
CREATE TEMP TABLE RUNNER_ORDERS_CLEAN AS
SELECT
	order_id,
	runner_id,
	CASE WHEN pickup_time ~ '^\d{4}-\d{2}-\d{2}' THEN pickup_time::TIMESTAMP ELSE null END as pickup_time,	
	CASE WHEN distance ~ '^[0-9]' THEN substring(distance from '\d*\.*\d*')::DECIMAL ELSE null END as distance,
	CASE WHEN duration ~ '^[0-9]' THEN substring(duration from '\d*\.*\d*')::DECIMAL ELSE null END as duration,
	CASE WHEN cancellation ~ '\w+' AND NOT cancellation ~ 'null' THEN cancellation ELSE null END as cancellation
FROM runner_orders;

DROP TABLE IF EXISTS PIZZA_RECIPES_CLEAN;
CREATE TEMP TABLE PIZZA_RECIPES_CLEAN AS
SELECT
	pizza_id,
	UNNEST(STRING_TO_ARRAY(toppings, ', '))::NUMERIC as topping_id
FROM pizza_recipes;

-- a-PizzaMetrics
-- 01 - How many pizzas were ordered?

SELECT
	COUNT(*) as pizzas_ordered
FROM CUSTOMER_ORDERS_CLEAN;

-- 02 - How many unique customer orders were made?

SELECT
	COUNT(DISTINCT order_id) as unique_orders
FROM RUNNER_ORDERS_CLEAN;

-- 03 - How many successful orders were delivered by each runner?

SELECT
	runner_id,
	COUNT(*) as times_delivered
FROM RUNNER_ORDERS_CLEAN 
WHERE cancellation IS null
GROUP BY runner_id;


-- 04 - How many of each type of pizza was delivered?

SELECT
	n.pizza_name,
	COUNT(*) as times_delivered
FROM CUSTOMER_ORDERS_CLEAN c
INNER JOIN RUNNER_ORDERS_CLEAN r
	ON c.order_id = r.order_id
	AND r.cancellation IS null
INNER JOIN pizza_names n USING (pizza_id)
GROUP BY c.pizza_id, n.pizza_name;

-- 05 - How many Vegetarian and Meatlovers were ordered by each customer?

SELECT
	c.customer_id,
	n.pizza_name,
	COUNT(*) as times_ordered
FROM CUSTOMER_ORDERS_CLEAN c
INNER JOIN pizza_names n
	ON c.pizza_id = n.pizza_id
GROUP BY c.customer_id, n.pizza_name
ORDER BY c.customer_id;

-- 06 - What was the maximum number of pizzas delivered in a single order?

WITH cte AS (
	SELECT
		c.order_id,
		COUNT(*) as delivered
	FROM CUSTOMER_ORDERS_CLEAN c
	INNER JOIN RUNNER_ORDERS_CLEAN r
		ON c.order_id = r.order_id
		AND r.duration IS NOT null
	GROUP BY c.order_id
)

SELECT
	MAX(delivered) as max_delivered
FROM cte;

-- 07 - For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

WITH cte AS (
	SELECT
		order_id,
		customer_id,
		CONCAT(exclusions, '--', extras) as concatenated
	FROM CUSTOMER_ORDERS_CLEAN
)

SELECT
	customer_id,
	SUM(CASE WHEN LENGTH(concatenated) >= 3 THEN 1 ELSE 0 END) as with_changes,
	SUM(CASE WHEN LENGTH(concatenated) < 3 THEN 1 ELSE 0 END) as no_changes
FROM cte
GROUP BY customer_id;

-- 08 - How many pizzas were delivered that had both exclusions and extras?

SELECT
	COUNT(*) as pizza_count
FROM CUSTOMER_ORDERS_CLEAN c
INNER JOIN RUNNER_ORDERS_CLEAN r
	ON c.order_id = r.order_id
	AND r.cancellation IS null
WHERE exclusions IS NOT null
	AND extras IS NOT null;

-- 09 - What was the total volume of pizzas ordered for each hour of the day?

WITH cte AS (
	SELECT
		EXTRACT(HOUR FROM order_time) as _hour,
		pizza_id
	FROM CUSTOMER_ORDERS_CLEAN
)

SELECT
	_hour,
	COUNT(*) as pizza_count
FROM cte
GROUP BY _hour
ORDER BY _hour;

-- 10 - What was the volume of orders for each day of the week?

WITH cte AS (
	SELECT
		EXTRACT(DOW FROM order_time) as _id,
		TO_CHAR(order_time, 'Dy') as DOW,
		pizza_id
	FROM CUSTOMER_ORDERS_CLEAN
)

SELECT
	DOW,
	COUNT(*)
FROM cte
GROUP BY _id, DOW
ORDER BY _id;

-- b-RunnerAndCustomerExperience
-- 01 - How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

WITH cte AS (
	SELECT
		runner_id,
		EXTRACT(WEEK FROM registration_date + INTERVAL '3 days') as week_num
	FROM runners
)

SELECT
	week_num,
	COUNT(*) as signed_up
FROM cte
GROUP BY week_num
ORDER BY week_num;

-- 02 - What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

WITH cte AS (
	SELECT
		r.runner_id,
		c.order_id,
		AVG(r.pickup_time::timestamp - c.order_time::timestamp) as time_taken
	FROM CUSTOMER_ORDERS_CLEAN c
	INNER JOIN RUNNER_ORDERS_CLEAN r
		ON c.order_id = r.order_id
		AND r.pickup_time IS NOT null
	GROUP BY r.runner_id, c.order_id
)

SELECT
	runner_id,
	EXTRACT('MINUTES' FROM AVG(time_taken)) + ROUND(EXTRACT('SECOND' FROM AVG(time_taken))/60::NUMERIC, 2) as time_taken
FROM cte
GROUP BY runner_id;

-- 03 - Is there any relationship between the number of pizzas and how long the order takes to prepare?

SELECT
	COUNT(pizza_id) as pizza_count,
	AVG(r.pickup_time::timestamp - c.order_time::timestamp) as time_taken
FROM CUSTOMER_ORDERS_CLEAN c
INNER JOIN RUNNER_ORDERS_CLEAN r
	ON c.order_id = r.order_id
	AND r.cancellation IS null
GROUP BY c.order_id
ORDER BY pizza_count;

-- 04 - What was the average distance travelled for each customer?

SELECT
	c.customer_id,
	ROUND(AVG(r.distance), 1) as distance
FROM CUSTOMER_ORDERS_CLEAN c
INNER JOIN RUNNER_ORDERS_CLEAN r
	ON c.order_id = r.order_id
	AND r.cancellation IS null
GROUP BY c.customer_id
ORDER by c.customer_id;

-- 05 - What was the difference between the longest and shortest delivery times for all orders?

WITH cte AS (
	SELECT
		c.order_id,
		ROUND(AVG(r.duration), 1) as time_taken
	FROM CUSTOMER_ORDERS_CLEAN c
	INNER JOIN RUNNER_ORDERS_CLEAN r
		ON c.order_id = r.order_id
		AND r.cancellation IS null
	GROUP BY c.order_id
)

SELECT
	MAX(time_taken) - MIN(time_taken) as _range
FROM cte;

-- 06 - What was the average speed for each runner for each delivery and do you notice any trend for these values?

SELECT
	r.runner_id,
	c.order_id,
	COUNT(*) as pizza_count,
	ROUND(AVG(EXTRACT('HOUR' FROM r.pickup_time::timestamp)), 0) as _hour,
	ROUND(AVG(r.distance/(r.duration/60)), 1) as speed
FROM CUSTOMER_ORDERS_CLEAN c
INNER JOIN RUNNER_ORDERS_CLEAN r
	ON c.order_id = r.order_id
	AND r.cancellation IS null
GROUP BY r.runner_id, c.order_id
ORDER BY r.runner_id, speed;

-- 07 - What is the successful delivery percentage for each runner?

SELECT
	runner_id,
	100*SUM(CASE WHEN cancellation IS null THEN 1 ELSE 0 END)/COUNT(*) as successful_percent
FROM RUNNER_ORDERS_CLEAN
GROUP BY runner_id
ORDER BY runner_id;

-- c-IngredientOptimisation
-- 01 - What are the standard ingredients for each pizza?

SELECT
	pizza_name,
	ARRAY_TO_STRING(array_agg(topping_name), ',') as toppings
FROM PIZZA_RECIPES_CLEAN
INNER JOIN pizza_names USING (pizza_id)
INNER JOIN pizza_toppings USING (topping_id)
GROUP BY pizza_name;

-- 02 - What was the most commonly added extra?

WITH cte AS (
	SELECT
		UNNEST(STRING_TO_ARRAY(extras, ', '))::NUMERIC as topping_id
	FROM CUSTOMER_ORDERS_CLEAN
	WHERE extras IS NOT null
)

SELECT
	topping_name,
	COUNT(*) as times_added
FROM cte c
INNER JOIN pizza_toppings USING (topping_id)
GROUP BY topping_name
ORDER BY times_added DESC
LIMIT 1;

-- 03 - What was the most common exclusion?

WITH cte AS (
	SELECT
		UNNEST(STRING_TO_ARRAY(exclusions, ', '))::NUMERIC as topping_id
	FROM CUSTOMER_ORDERS_CLEAN
	WHERE exclusions IS NOT null
)

SELECT
	topping_name,
	COUNT(*) as times_excluded
FROM cte c
INNER JOIN pizza_toppings USING (topping_id)
GROUP BY topping_name
ORDER BY times_excluded DESC
LIMIT 1;

-- 04 - Generate an order item for each record in the customers_orders table in the format of one of the following:
-- Meat Lovers
-- Meat Lovers - Exclude Beef
-- Meat Lovers - Extra Bacon
-- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

WITH cleaned_ranked AS (
	SELECT
		ROW_NUMBER() OVER(ORDER BY pizza_id) as _id,
		order_id,
		pizza_id,
		COALESCE(exclusions, '0') as exclusions,
		COALESCE(extras , '0') as extras
	FROM CUSTOMER_ORDERS_CLEAN
),

table_unnested AS (
	SELECT
		_id,
		order_id,
		pizza_id,
		UNNEST(STRING_TO_ARRAY(exclusions, ', '))::NUMERIC as exclusions,
		UNNEST(STRING_TO_ARRAY(extras, ', '))::NUMERIC as extras
	FROM cleaned_ranked
),

aggregated_table AS (
	SELECT
		_id,
		order_id,
		pizza_name,
		ARRAY_TO_STRING(ARRAY_AGG(t.topping_name), ', ') as exclusions,
		ARRAY_TO_STRING(ARRAY_AGG(t2.topping_name), ', ') as extras
	FROM table_unnested un
	LEFT JOIN pizza_toppings t
		ON t.topping_id = un.exclusions
	LEFT JOIN pizza_toppings t2
		ON t2.topping_id = un.extras
	LEFT JOIN pizza_names USING (pizza_id)
	GROUP BY _id, order_id, pizza_name
)

SELECT
	order_id,
	CONCAT(pizza_name,
		   CASE WHEN LENGTH(exclusions) > 1 THEN ' - Exclude ' ELSE '' END,
		   exclusions,
		   CASE WHEN LENGTH(extras) > 1 THEN ' - Extra ' ELSE '' END,
		   extras) as _order
FROM aggregated_table
ORDER BY order_id;

-- 05 - Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table
-- and add a 2x in front of any relevant ingredients
-- For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"

WITH exclusions_table AS (
	SELECT
		_id,
		UNNEST(STRING_TO_ARRAY(exclusions, ', '))::NUMERIC as topping_id
	FROM CUSTOMER_ORDERS_CLEAN
	WHERE exclusions IS NOT NULL
),

extras_table AS (
	SELECT
		_id,
		UNNEST(STRING_TO_ARRAY(extras, ', '))::NUMERIC as topping_id
	FROM CUSTOMER_ORDERS_CLEAN
	WHERE extras IS NOT NULL	
),

recipe_with_extras AS (
	SELECT
		_id,
		c.pizza_id,
		UNNEST(STRING_TO_ARRAY(CONCAT(p.toppings,
			   CASE WHEN c.extras IS NULL THEN '' ELSE ', ' END,
			   c.extras), ', '))::NUMERIC as topping_id
	FROM CUSTOMER_ORDERS_CLEAN c
	INNER JOIN RUNNER_ORDERS_CLEAN r
		ON r.order_id = c.order_id
	INNER JOIN pizza_recipes p USING (pizza_id)
),

recipe_summary AS (
	SELECT
		_id, pizza_id,
		(CASE
			WHEN topping_id IN (SELECT topping_id FROM extras_table e WHERE r._id = e._id)
			THEN CONCAT('2x', t.topping_name)
			ELSE topping_name END) as toppings
	FROM recipe_with_extras r
	INNER JOIN pizza_toppings t USING (topping_id)
	WHERE r.topping_id NOT IN (SELECT topping_id FROM exclusions_table e WHERE r._id = e._id)
),

recipe_cte AS (
	SELECT
		_id,
		pizza_id,
		ARRAY_TO_STRING(ARRAY_AGG(toppings), ', ') as _order
	FROM recipe_summary
	GROUP BY _id, pizza_id
)

SELECT
	c.order_id,
	CONCAT(n.pizza_name,': ', _order) as _order
FROM recipe_cte r
INNER JOIN CUSTOMER_ORDERS_CLEAN c USING (_id)
INNER JOIN pizza_names n 
	ON r.pizza_id = n.pizza_id
ORDER BY order_id;

-- 06 - What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

WITH cte_mergedIngredients AS (
	SELECT
			CONCAT(p.toppings,
				   CASE WHEN c.extras IS NULL THEN '' ELSE ', ' END,
				   c.extras,
				   CASE WHEN c.exclusions IS NULL THEN '' ELSE ', ' END,
				   c.exclusions) as ingredients
	FROM CUSTOMER_ORDERS_CLEAN c
	INNER JOIN RUNNER_ORDERS_CLEAN r
		ON r.order_id = c.order_id
		AND r.cancellation IS NULL
	LEFT JOIN pizza_recipes p
		ON p.pizza_id = c.pizza_id),

cte_unnested AS (
	SELECT
		UNNEST(STRING_TO_ARRAY(ingredients, ', '))::NUMERIC as ingredient
	FROM cte_mergedIngredients
)

SELECT
	t.topping_name as ingredient_name,
	COUNT(*) as times_used
FROM cte_unnested i
LEFT JOIN pizza_toppings t
	ON t.topping_id = i.ingredient
GROUP BY t.topping_name
ORDER BY times_used DESC;

-- d-PricingAndRatings
-- 01 - If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes
-- - how much money has Pizza Runner made so far if there are no delivery fees?

WITH cte AS (
	SELECT
		*,
		CASE
			WHEN pizza_name = 'Meatlovers' THEN 12
			WHEN pizza_name = 'Vegetarian' THEN 10
		END as price
	FROM pizza_names)

SELECT
	cte.pizza_name,
	SUM(price) as sales
FROM CUSTOMER_ORDERS_CLEAN c
INNER JOIN RUNNER_ORDERS_CLEAN r
	ON r.order_id = c.order_id
	AND r.cancellation IS NULL
INNER JOIN cte USING (pizza_id)
GROUP BY cte.pizza_name;

-- 02 - What if there was an additional $1 charge for any pizza extras?
-- Add cheese is $1 extra

WITH cte AS (
	SELECT
		*,
		CASE
			WHEN pizza_name = 'Meatlovers' THEN 12
			WHEN pizza_name = 'Vegetarian' THEN 10
		END as price
	FROM pizza_names)

SELECT
	cte.pizza_name,
	SUM(price + COALESCE(DIV(LENGTH(extras), 3) + 1, 0)) as sales
FROM CUSTOMER_ORDERS_CLEAN c
INNER JOIN RUNNER_ORDERS_CLEAN r
	ON r.order_id = c.order_id
	AND r.cancellation IS NULL
INNER JOIN cte USING (pizza_id)
GROUP BY cte.pizza_name;

-- 03 - The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner,
-- how would you design an additional table for this new dataset
-- - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.

DROP TABLE IF EXISTS runner_ratings;
CREATE TABLE runner_ratings (
	"order_id" INTEGER,
	"rating" NUMERIC
);

INSERT INTO runner_ratings
	("order_id", "rating")
VALUES
	(1, 5),
	(2, 4),
	(3, 1),
	(4, 5),
	(5, 1),
	(7, 2),
	(8, 4),
	(10, 4);

-- 04 - Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
-- customer_id
-- order_id
-- runner_id
-- rating
-- order_time
-- pickup_time
-- Time between order and pickup
-- Delivery duration
-- Average speed
-- Total number of pizzas

WITH aggregations AS (
	SELECT
		customer_id,
		order_id,
		COUNT(*) as pizza_count
	FROM CUSTOMER_ORDERS_CLEAN
	GROUP BY customer_id, order_id
	ORDER BY customer_id, order_id
),

order_times AS (
	SELECT
		order_id,
		MAX(order_time) as order_time
	FROM CUSTOMER_ORDERS_CLEAN
	GROUP BY order_id
)

SELECT
	a.customer_id,
	a.order_id,
	r.runner_id,
	rr.rating,
	o.order_time,
	r.pickup_time,
	(r.pickup_time - o.order_time) as time_between,
	r.duration,
	ROUND(60 * r.distance/r.duration, 1) as speed_kph, -- kilometers per hour
	a.pizza_count
FROM aggregations a
INNER JOIN RUNNER_ORDERS_CLEAN r
	ON r.order_id = a.order_id
	AND r.cancellation IS NULL
INNER JOIN order_times o
	ON o.order_id = a.order_id
INNER JOIN runner_ratings rr 
	ON rr.order_id = a.order_id;

-- 05 - If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras
-- and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?

WITH cte AS (
	SELECT
		*,
		CASE
			WHEN pizza_name = 'Meatlovers' THEN 12
			WHEN pizza_name = 'Vegetarian' THEN 10
		END as price
	FROM pizza_names)

SELECT
	SUM(price) as revenue,
	SUM(price - distance*0.3) as amount_left
FROM CUSTOMER_ORDERS_CLEAN c
INNER JOIN RUNNER_ORDERS_CLEAN r
	ON r.order_id = c.order_id
	AND r.cancellation IS NULL
INNER JOIN cte USING (pizza_id);

-- e-BonusQuestions
-- If Danny wants to expand his range of pizzas - how would this impact the existing data design?
-- Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?

-- We only need to update two tables i.e., pizza_names and pizza_recipes for this change.

-- INSERT INTO pizza_names
-- 	("pizza_id", "pizza_name")
-- VALUES
-- 	(3, 'Supreme Pizza');
	
-- INSERT INTO pizza_recipes
-- 	("pizza_id", "toppings")
-- VALUES
-- 	(3, '1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12');