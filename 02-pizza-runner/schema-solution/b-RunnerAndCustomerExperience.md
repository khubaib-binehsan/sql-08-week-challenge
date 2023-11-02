# **Runner and Customer Experience**

```sql
-- PostgreSQL 15

SET search_path = pizza_runner;

-- Use (if any) temp table created in "a-PizzaMetrics" file.
```

**Question 01.**

> How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

<details>
<summary>Hide/Reveal Solution</summary>

```sql
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
```

</details>

| **week_num** | **signed_up** |
| -----------: | ------------: |
|            1 |             2 |
|            2 |             1 |
|            3 |             1 |

<br>

**Question 02.**

> What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

<details>
<summary>Hide/Reveal Solution</summary>

```sql
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
```

</details>

| **runner_id** | **time_taken** |
| ------------: | -------------: |
|             3 |          10.47 |
|             2 |          20.01 |
|             1 |          14.33 |

<br>

**Question 03.**

> Is there any relationship between the number of pizzas and how long the order takes to prepare?

<details>
<summary>Hide/Reveal Solution</summary>

```sql
SELECT
	COUNT(pizza_id) as pizza_count,
	AVG(r.pickup_time::timestamp - c.order_time::timestamp) as time_taken
FROM CUSTOMER_ORDERS_CLEAN c
INNER JOIN RUNNER_ORDERS_CLEAN r
	ON c.order_id = r.order_id
	AND r.cancellation IS null
GROUP BY c.order_id
ORDER BY pizza_count;
```

</details>

| **pizza_count** | **time_taken** |
| --------------: | -------------- |
|               1 | 0:10:32        |
|               1 | 0:10:02        |
|               1 | 0:10:28        |
|               1 | 0:10:16        |
|               1 | 0:20:29        |
|               2 | 0:21:14        |
|               2 | 0:15:31        |
|               3 | 0:29:17        |

<br>

**Question 04.**

> What was the average distance travelled for each customer?

<details>
<summary>Hide/Reveal Solution</summary>

```sql
SELECT
	c.customer_id,
	ROUND(AVG(r.distance), 1) as distance
FROM CUSTOMER_ORDERS_CLEAN c
INNER JOIN RUNNER_ORDERS_CLEAN r
	ON c.order_id = r.order_id
	AND r.cancellation IS null
GROUP BY c.customer_id
ORDER by c.customer_id;
```

</details>

| **customer_id** | **distance** |
| --------------: | -----------: |
|             101 |           20 |
|             102 |         16.7 |
|             103 |         23.4 |
|             104 |           10 |
|             105 |           25 |

<br>

**Question 05.**

> What was the difference between the longest and shortest delivery times for all orders?

<details>
<summary>Hide/Reveal Solution</summary>

```sql
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
```

</details>

| **\_range** |
| ----------: |
|          30 |

<br>

**Question 06.**

> What was the average speed for each runner for each delivery and do you notice any trend for these values?

<details>
<summary>Hide/Reveal Solution</summary>

```sql
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
```

</details>

| **runner_id** | **order_id** | **pizza_count** | **\_hour** | **speed** |
| ------------: | -----------: | --------------: | ---------: | --------: |
|             1 |            1 |               1 |         18 |      37.5 |
|             1 |            3 |               2 |          0 |      40.2 |
|             1 |            2 |               1 |         19 |      44.4 |
|             1 |           10 |               2 |         18 |        60 |
|             2 |            4 |               3 |         13 |      35.1 |
|             2 |            7 |               1 |         21 |        60 |
|             2 |            8 |               1 |          0 |      93.6 |
|             3 |            5 |               1 |         21 |        40 |

<br>

**Question 07.**

> What is the successful delivery percentage for each runner?

<details>
<summary>Hide/Reveal Solution</summary>

```sql
SELECT
	runner_id,
	100*SUM(CASE WHEN cancellation IS null THEN 1 ELSE 0 END)/COUNT(*) as successful_percent
FROM RUNNER_ORDERS_CLEAN
GROUP BY runner_id
ORDER BY runner_id;
```

</details>

| **runner_id** | **successful_percent** |
| ------------: | ---------------------: |
|             1 |                    100 |
|             2 |                     75 |
|             3 |                     50 |

<br>

---

[Previous](a-PizzaMetrics.md) | [Next](c-IngredientOptimisation.md)

[Home](../README.md)
