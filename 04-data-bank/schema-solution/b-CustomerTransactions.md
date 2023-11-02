# **Customer Transactions**

```sql
-- PostgreSQL 15

SET search_path = data_bank;
```

**Question 01.**

> What is the unique count and total amount for each transaction type?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
SELECT
	txn_type,
	COUNT(*) as txn_count,
	SUM(txn_amount) as txn_amount
FROM customer_transactions
GROUP BY txn_type;
```

</details>

| **txn_type** | **txn_count** | **txn_amount** |
| ------------ | ------------: | -------------: |
| purchase     |          1617 |         806537 |
| withdrawal   |          1580 |         793003 |
| deposit      |          2671 |        1359168 |

<br>

**Question 02.**

> What is the average total historical deposit counts and amounts for all customers?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
WITH customer_agg AS (
	SELECT
		customer_id,
		COUNT(*) as txn_count,
		AVG(txn_amount) as txn_amount
	FROM customer_transactions
	WHERE txn_type = 'deposit'
	GROUP BY customer_id
)

SELECT
	ROUND(AVG(txn_count), 0) as avg_count,
	ROUND(AVG(txn_amount), 0) as avg_amount
FROM customer_agg;
```

</details>

| **avg_count** | **avg_amount** |
| ------------: | -------------: |
|             5 |            509 |

<br>

**Question 03.**

> For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
WITH aggregated_data AS (
	SELECT
		EXTRACT('month' from txn_date) as month_id,
		TO_CHAR(txn_date, 'Month') as month_name,
		customer_id,
		SUM(CASE WHEN txn_type = 'deposit' THEN 1 ELSE 0 END) as deposit_count,
		SUM(CASE WHEN txn_type = 'purchase' THEN 1 ELSE 0 END) as purchase_count,
		SUM(CASE WHEN txn_type = 'withdrawl' THEN 1 ELSE 0 END) as withdrawl_count
	FROM customer_transactions
	GROUP BY month_id, month_name, customer_id
	ORDER BY month_id, customer_id)

SELECT
	month_name,
	SUM(CASE
        WHEN (deposit_count > 1) AND (purchase_count >= 1 OR withdrawl_count >= 1)
	    THEN 1 ELSE 0 END) as customer_count
FROM aggregated_data
GROUP BY month_id, month_name
ORDER BY month_id;
```

</details>

| **month_name** | **customer_count** |
| -------------- | -----------------: |
| January        |                128 |
| February       |                135 |
| March          |                146 |
| April          |                 55 |

<br>

**Question 04.**

> What is the closing balance for each customer at the end of the month?

Only the first 12 rows are shown here as output.

<details>
<summary>Reveal/Hide Solution</summary>

```sql
DROP TABLE IF EXISTS closing_balance;
CREATE TEMP TABLE closing_balance AS
WITH RECURSIVE aggregated_data AS (
	SELECT
		customer_id,
		(DATE_TRUNC('month', txn_date) + INTERVAL '1 MONTH - 1 DAY')::DATE as month_end,
		SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE -txn_amount END) as activity
	FROM customer_transactions
	GROUP BY month_end, customer_id
	ORDER BY customer_id, month_end),

aggregated_data0 AS ( -- added next_month column
	SELECT
		*,
		LEAD(month_end, 1) OVER(PARTITION BY customer_id) as next_month
	FROM aggregated_data
),

date_population AS ( -- recursive query
	SELECT	-- non-recursive part
		*
	FROM aggregated_data0

	UNION ALL

	SELECT	-- recursive part
		customer_id,
		(DATE_TRUNC('month', month_end + INTERVAL '1 MONTH') + INTERVAL '1 MONTH - 1 DAY')::DATE,
		0 as activity,
		next_month
	FROM date_population
	where month_end < '2020-04-30'
		AND EXTRACT('month' FROM month_end) < COALESCE(EXTRACT('month' FROM next_month) - 1, 12)
)

SELECT
	customer_id,
	month_end,
	SUM(activity) OVER(PARTITION BY customer_id ORDER BY month_end) as closing_balance
FROM date_population
ORDER BY customer_id, month_end;

SELECT * FROM closing_balance LIMIT 12;
```

</details>

| **customer_id** | **month_end** | **closing_balance** |
| --------------: | ------------- | ------------------: |
|               1 | 31/01/2020    |                 312 |
|               1 | 29/02/2020    |                 312 |
|               1 | 31/03/2020    |                -640 |
|               1 | 30/04/2020    |                -640 |
|               2 | 31/01/2020    |                 549 |
|               2 | 29/02/2020    |                 549 |
|               2 | 31/03/2020    |                 610 |
|               2 | 30/04/2020    |                 610 |
|               3 | 31/01/2020    |                 144 |
|               3 | 29/02/2020    |                -821 |

<br>

**Question 05.**

> What is the percentage of customers who increase their closing balance by more than 5%?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
WITH rows_cte AS (
	SELECT
		*,
		ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY month_end) as row_id
	FROM closing_balance
),

lag_values AS (
	SELECT
		*,
		LAG(closing_balance, 1) OVER(PARTITION BY customer_id ORDER BY month_end) as initial_balance
	FROM rows_cte
	WHERE row_id IN (1, 4)),

percent_change_calc AS (
	SELECT
		customer_id,
		ROUND(100*((closing_balance/initial_balance) - 1), 0) as pct_change
	FROM lag_values
	WHERE row_id = 4
),

total_customers AS (
	SELECT COUNT(DISTINCT customer_id) as total FROM customer_transactions
),

pct_customers AS (
	SELECT
		COUNT(*) as total
	FROM percent_change_calc
	WHERE pct_change > 5)

SELECT
	ROUND(100*p.total / t.total, 0) as percentage
FROM pct_customers p, total_customers t;
```

</details>

| **percentage** |
| -------------: |
|             44 |

<br>

---

[Previous](a-CustomerNodesExploration.md) | [Next](c-DataAllocationChallenge.md)

[Home](../README.md)
