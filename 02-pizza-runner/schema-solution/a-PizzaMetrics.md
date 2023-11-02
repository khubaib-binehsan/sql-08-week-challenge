# **Pizza Metrics**

```sql
-- PostgreSQL 15

SET search_path = pizza_runner;
```

Since the dataset is quite dirty, first we clean the dataset and store the tables as temporary tables so that we don't have to do all the cleaning every time the need arises.

<details>
<summary>Reveal/Hide Code</summary>

```sql
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
```

</details>

**CUSTOMER_ORDERS_CLEAN**

| **\_id** | **order_id** | **customer_id** | **pizza_id** | **exclusions** | **extras** | **order_time**   |
| -------: | -----------: | --------------: | -----------: | -------------- | ---------- | ---------------- |
|        1 |            1 |             101 |            1 |                |            | 01/01/2020 18:05 |
|        2 |            2 |             101 |            1 |                |            | 01/01/2020 19:00 |
|        3 |            3 |             102 |            1 |                |            | 02/01/2020 23:51 |
|        4 |            3 |             102 |            2 |                |            | 02/01/2020 23:51 |
|        5 |            4 |             103 |            1 | 4              |            | 04/01/2020 13:23 |

**RUNNER_ORDERS_CLEAN**

| **order_id** | **runner_id** | **pickup_time**  | **distance** | **duration** | **cancellation** |
| -----------: | ------------: | ---------------- | -----------: | -----------: | ---------------- |
|            1 |             1 | 01/01/2020 18:15 |           20 |           32 |                  |
|            2 |             1 | 01/01/2020 19:10 |           20 |           27 |                  |
|            3 |             1 | 03/01/2020 0:12  |         13.4 |           20 |                  |
|            4 |             2 | 04/01/2020 13:53 |         23.4 |           40 |                  |
|            5 |             3 | 08/01/2020 21:10 |           10 |           15 |                  |

**PIZZA_RECIPES_CLEAN**

| **pizza_id** | **topping_id** |
| -----------: | -------------: |
|            1 |              1 |
|            1 |              2 |
|            1 |              3 |
|            1 |              4 |
|            1 |              5 |

<br>

---

**Question 01.**

> How many pizzas were ordered?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
SELECT
	COUNT(*) as pizzas_ordered
FROM CUSTOMER_ORDERS_CLEAN;
```

</details>

| **pizzas_ordered** |
| -----------------: |
|                 14 |

<br>

**Question 02.**

> How many unique customer orders were made?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
SELECT
	COUNT(DISTINCT order_id) as unique_orders
FROM RUNNER_ORDERS_CLEAN;
```

</details>

| **unique_orders** |
| ----------------: |
|                10 |

<br>

**Question 03.**

> How many successful orders were delivered by each runner?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
SELECT
	runner_id,
	COUNT(*) as times_delivered
FROM RUNNER_ORDERS_CLEAN
WHERE cancellation IS null
GROUP BY runner_id;
```

</details>

| **runner_id** | **times_delivered** |
| ------------: | ------------------: |
|             1 |                   4 |
|             2 |                   3 |
|             3 |                   1 |

<br>

**Question 04.**

> How many of each type of pizza was delivered?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
SELECT
	n.pizza_name,
	COUNT(*) as times_delivered
FROM CUSTOMER_ORDERS_CLEAN c
INNER JOIN RUNNER_ORDERS_CLEAN r
	ON c.order_id = r.order_id
	AND r.cancellation IS null
INNER JOIN pizza_names n USING (pizza_id)
GROUP BY c.pizza_id, n.pizza_name;
```

</details>

| **pizza_name** | **times_delivered** |
| -------------- | ------------------: |
| Meatlovers     |                   9 |
| Vegetarian     |                   3 |

<br>

**Question 05.**

> How many Vegetarian and Meatlovers were ordered by each customer?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
SELECT
	c.customer_id,
	n.pizza_name,
	COUNT(*) as times_ordered
FROM CUSTOMER_ORDERS_CLEAN c
INNER JOIN pizza_names n
	ON c.pizza_id = n.pizza_id
GROUP BY c.customer_id, n.pizza_name
ORDER BY c.customer_id;
```

</details>

| **customer_id** | **pizza_name** | **times_ordered** |
| --------------: | -------------- | ----------------: |
|             101 | Meatlovers     |                 2 |
|             101 | Vegetarian     |                 1 |
|             102 | Meatlovers     |                 2 |
|             102 | Vegetarian     |                 1 |
|             103 | Meatlovers     |                 3 |
|             103 | Vegetarian     |                 1 |
|             104 | Meatlovers     |                 3 |
|             105 | Vegetarian     |                 1 |

<br>

**Question 06.**

> What was the maximum number of pizzas delivered in a single order?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
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
```

</details>

| **max_delivered** |
| ----------------: |
|                 3 |

<br>

**Question 07.**

> For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
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
```

</details>

| **customer_id** | **with_changes** | **no_changes** |
| --------------: | ---------------: | -------------: |
|             101 |                0 |              3 |
|             103 |                4 |              0 |
|             104 |                2 |              1 |
|             105 |                1 |              0 |
|             102 |                0 |              3 |

<br>

**Question 08.**

> How many pizzas were delivered that had both exclusions and extras?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
SELECT
	COUNT(*) as pizza_count
FROM CUSTOMER_ORDERS_CLEAN c
INNER JOIN RUNNER_ORDERS_CLEAN r
	ON c.order_id = r.order_id
	AND r.cancellation IS null
WHERE exclusions IS NOT null
	AND extras IS NOT null;
```

</details>

| **pizza_count** |
| --------------: |
|               1 |

<br>

**Question 09.**

> What was the total volume of pizzas ordered for each hour of the day?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
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
```

</details>

| **\_hour** | **pizza_count** |
| ---------: | --------------: |
|         11 |               1 |
|         13 |               3 |
|         18 |               3 |
|         19 |               1 |
|         21 |               3 |
|         23 |               3 |

<br>

**Question 10**

> What was the volume of orders for each day of the week?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
WITH cte AS (
	SELECT
		EXTRACT(DOW FROM order_time) as _id,
		TO_CHAR(order_time, 'Dy') as DOW,
		pizza_id
	FROM CUSTOMER_ORDERS_CLEAN
)

SELECT
	DOW,
	COUNT(*) as pizza_count
FROM cte
GROUP BY _id, DOW
ORDER BY _id;
```

</details>

| **dow** | **pizza_count** |
| ------- | --------------: |
| Wed     |               5 |
| Thu     |               3 |
| Fri     |               1 |
| Sat     |               5 |

<br>

---

[Next](b-RunnerAndCustomerExperience.md)

[Home](../README.md)
