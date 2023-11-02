# **Pricing and Ratings**

```sql
-- PostgreSQL 15

SET search_path = pizza_runner;

-- Use (if any) temp table created in "a-PizzaMetrics" file.
```

**Question 01.**

> If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
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
```

</details>

| **pizza_name** | **sales** |
| -------------- | --------: |
| Meatlovers     |       108 |
| Vegetarian     |        30 |

<br>

**Question 02.**

> What if there was an additional $1 charge for any pizza extras?
>
> - Add cheese is $1 extra

<details>
<summary>Reveal/Hide Solution</summary>

```sql
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
```

</details>

| **pizza_name** | **sales** |
| -------------- | --------: |
| Meatlovers     |       111 |
| Vegetarian     |        31 |

<br>

**Question 03.**

> The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.

<details><summary>Reveal/Hide Solution</summary>

```sql
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
```

</details>

| **order_id** | **rating** |
| -----------: | ---------: |
|            1 |          5 |
|            2 |          4 |
|            3 |          1 |
|            4 |          5 |
|            5 |          1 |
|            7 |          2 |
|            8 |          4 |
|           10 |          4 |

<br>

**Question 04.**

> Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
>
> - customer_id
>
> - order_id
>
> - runner_id
>
> - rating
>
> - order_time
>
> - pickup_time
>
> - Time between order and pickup
>
> - Delivery duration
>
> - Average speed
>
> - Total number of pizzas

<details>
<summary>Reveal/Hide Solution</summary>

```sql
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
```

</details>

| **customer_id** | **order_id** | **runner_id** | **rating** | **order_time**   | **pickup_time**  | **time_between** | **duration** | **speed_kph** | **pizza_count** |
| --------------: | -----------: | ------------: | ---------: | ---------------- | ---------------- | ---------------- | -----------: | ------------: | --------------: |
|             101 |            1 |             1 |          5 | 01/01/2020 18:05 | 01/01/2020 18:15 | 0:10:32          |           32 |          37.5 |               1 |
|             101 |            2 |             1 |          4 | 01/01/2020 19:00 | 01/01/2020 19:10 | 0:10:02          |           27 |          44.4 |               1 |
|             102 |            3 |             1 |          1 | 02/01/2020 23:51 | 03/01/2020 0:12  | 0:21:14          |           20 |          40.2 |               2 |
|             103 |            4 |             2 |          5 | 04/01/2020 13:23 | 04/01/2020 13:53 | 0:29:17          |           40 |          35.1 |               3 |
|             104 |            5 |             3 |          1 | 08/01/2020 21:00 | 08/01/2020 21:10 | 0:10:28          |           15 |            40 |               1 |
|             105 |            7 |             2 |          2 | 08/01/2020 21:20 | 08/01/2020 21:30 | 0:10:16          |           25 |            60 |               1 |
|             102 |            8 |             2 |          4 | 09/01/2020 23:54 | 10/01/2020 0:15  | 0:20:29          |           15 |          93.6 |               1 |
|             104 |           10 |             1 |          4 | 11/01/2020 18:34 | 11/01/2020 18:50 | 0:15:31          |           10 |            60 |               2 |

<br>

**Question 05.**

> If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
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
```

</details>

| **revenue** | **amount_left** |
| ----------: | --------------: |
|         138 |           73.38 |

<br>

---

[Previous](c-IngredientOptimisation.md) | [Next](e-BonusQuestion.md)

[Home](../README.md)
