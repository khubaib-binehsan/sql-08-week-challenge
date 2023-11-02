# **Data Analysis Questions**

```sql
-- PostgreSQL 15

SET search_path = foodie_fi;
```

**Question 01.**

> How many customers has Foodie-Fi ever had?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
SELECT
	COUNT(DISTINCT customer_id) as customers
FROM subscriptions;
```

</details>

| **customers** |
| ------------: |
|          1000 |

<br>

**Question 02.**

> What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value

<details>
<summary>Reveal/Hide Solution</summary>

```sql
SELECT
	DATE_PART('month', start_date) as month_id,
	TO_CHAR(start_date, 'Month') as month_name,
	COUNT(*) as subscriptions
FROM subscriptions
WHERE plan_id = 0
GROUP BY month_id, month_name
ORDER BY month_id;
```

</details>

| **month_id** | **month_name** | **subscriptions** |
| -----------: | -------------- | ----------------: |
|            1 | January        |                88 |
|            2 | February       |                68 |
|            3 | March          |                94 |
|            4 | April          |                81 |
|            5 | May            |                88 |
|            6 | June           |                79 |
|            7 | July           |                89 |
|            8 | August         |                88 |
|            9 | September      |                87 |
|           10 | October        |                79 |

<br>

**Question 03.**

> What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name

<details>
<summary>Reveal/Hide Solution</summary>

```sql
WITH cte AS (
	SELECT
		plan_id,
		COUNT(*) as events
	FROM subscriptions
	WHERE start_date >= '2021-01-01'
	GROUP BY plan_id)

SELECT
	p.plan_name,
	COALESCE(c.events, 0) as events
FROM plans p
LEFT JOIN cte c USING (plan_id);
```

</details>

| **plan_name** | **events** |
| ------------- | ---------: |
| trial         |          0 |
| basic monthly |          8 |
| pro monthly   |         60 |
| pro annual    |         63 |
| churn         |         71 |

<br>

**Question 04.**

> What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
WITH cte AS (
	SELECT
		COUNT(DISTINCT customer_id) as total_count,
		SUM(CASE WHEN plan_id = 4 THEN 1 ELSE 0 END) as churned
	FROM subscriptions)

SELECT
	churned as customer_count,
	ROUND(100*churned/total_count, 1) as percentage
FROM cte;
```

</details>

| **customer_count** | **percentage** |
| -----------------: | -------------: |
|                307 |             30 |

<br>

**Question 05.**

> How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
WITH cte AS (
	SELECT
		customer_id
	FROM subscriptions
	WHERE customer_id IN (SELECT customer_id FROM subscriptions WHERE plan_id = 4)
	GROUP BY customer_id
	HAVING COUNT(*) = 2)

SELECT
	COUNT(customer_id) as customer_count,
	ROUND(100*COUNT(customer_id)/(SELECT COUNT(DISTINCT customer_id) FROM subscriptions), 0) as percentage
FROM cte;
```

</details>

| **customer_count** | **percentage** |
| -----------------: | -------------: |
|                 92 |              9 |

<br>

**Question 06.**

> What is the number and percentage of customer plans after their initial free trial?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
WITH cte_ranked AS (
	SELECT
		*,
		RANK() OVER (PARTITION BY customer_id ORDER BY start_date) as ranked
	FROM subscriptions),

cte_customer_count AS (
	SELECT
		p.plan_name,
		count(*) as customer_count
	FROM cte_ranked c
	INNER JOIN plans p USING (plan_id)
	WHERE ranked < 3
		AND plan_id != 0
	GROUP BY c.plan_id, p.plan_name
	ORDER BY c.plan_id)

SELECT
	plan_name,
	customer_count,
	ROUND(100 * customer_count / (SELECT SUM(customer_count) FROM cte_customer_count), 1) as percentage
FROM cte_customer_count;
```

</details>

| **plan_name** | **customer_count** | **percentage** |
| ------------- | -----------------: | -------------: |
| basic monthly |                546 |           54.6 |
| pro monthly   |                325 |           32.5 |
| pro annual    |                 37 |            3.7 |
| churn         |                 92 |            9.2 |

<br>

**Question 07.**

> What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
WITH cte_ranked AS (
	SELECT
		*,
		RANK() OVER (PARTITION BY customer_id ORDER BY start_date DESC) as ranked
	FROM subscriptions
	WHERE start_date <= '2020-12-31'),

cte_customer_count AS (
	SELECT
		p.plan_name,
		count(*) as customer_count
	FROM cte_ranked c
	INNER JOIN plans p USING (plan_id)
	WHERE ranked = 1
	GROUP BY c.plan_id, p.plan_name
	ORDER BY c.plan_id)

SELECT
	plan_name,
	customer_count,
	ROUND(100 * customer_count / (SELECT SUM(customer_count) FROM cte_customer_count), 1) as percentage
FROM cte_customer_count;
```

</details>

| **plan_name** | **customer_count** | **percentage** |
| ------------- | -----------------: | -------------: |
| trial         |                 19 |            1.9 |
| basic monthly |                224 |           22.4 |
| pro monthly   |                326 |           32.6 |
| pro annual    |                195 |           19.5 |
| churn         |                236 |           23.6 |

<br>

**Question 08.**

> How many customers have upgraded to an annual plan in 2020?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
SELECT
	COUNT(DISTINCT customer_id)
FROM subscriptions
WHERE plan_id = 3
	AND DATE_PART('year', start_date) = 2020
LIMIT 100;
```

</details>

| **count** |
| --------: |
|       195 |

<br>

**Question 09.**

> How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
WITH cte AS (
	SELECT
		a.customer_id,
		a.start_date as annual_start,
		s.start_date as trial_start,
		a.start_date - s.start_date as days_count
	FROM subscriptions a
	INNER JOIN subscriptions s
		ON s.customer_id = a.customer_id
		AND s.plan_id = 0
	WHERE a.plan_id = 3)

SELECT
	ROUND(AVG(days_count), 0) as avg_days
FROM cte;
```

</details>

| **avg_days** |
| -----------: |
|          105 |

<br>

**Question 10.**

> Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)

<details>
<summary>Reveal/Hide Solution</summary>

```sql
WITH cte AS (
	SELECT
		WIDTH_BUCKET(a.start_date - s.start_date, 0 , 360, 12) as bin
	FROM subscriptions a
	INNER JOIN subscriptions s
		ON s.customer_id = a.customer_id
		AND s.plan_id = 0
	WHERE a.plan_id = 3)

SELECT
	(CASE WHEN bin = 1 THEN 0 ELSE (bin - 1) * 30 + 1 END) || ' - ' || bin*30 || ' days' as breakdown,
	COUNT(*) as customers
FROM cte
GROUP BY bin
ORDER BY bin;
```

</details>

| **breakdown**  | **customers** |
| -------------- | ------------: |
| 0 - 30 days    |            48 |
| 31 - 60 days   |            25 |
| 61 - 90 days   |            33 |
| 91 - 120 days  |            35 |
| 121 - 150 days |            43 |
| 151 - 180 days |            35 |
| 181 - 210 days |            27 |
| 211 - 240 days |             4 |
| 241 - 270 days |             5 |
| 271 - 300 days |             1 |

<br>

**Question 11.**

> How many customers downgraded from a pro monthly to a basic monthly plan in 2020?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
WITH cte_ranked AS (
	SELECT
		customer_id,
		plan_id,
		LAG(plan_id, 1) OVER(PARTITION BY customer_id ORDER BY start_date) as last_subscription
	FROM subscriptions
	WHERE DATE_PART('year', start_date) = 2020)

SELECT
	COUNT(*) as downgraded
FROM cte_ranked
WHERE plan_id = 1
	AND last_subscription - plan_id = 1;
```

</details>

| **downgraded** |
| -------------: |
|              0 |

<br>

[Previous](a-CustomerJourney.md) | [Next](c-ChallengePaymentQuestion.md)

[Home](../README.md)
