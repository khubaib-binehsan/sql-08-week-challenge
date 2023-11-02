# **Transaction Analysis**

```sql
-- PostgreSQL 15

SET search_path = balanced_tree;
```

**Question 01.**

> How many unique transactions were there?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
SELECT
	COUNT(DISTINCT txn_id) as total_transactions
FROM sales;
```

</details>

| **total_transactions** |
| ---------------------: |
|                   2500 |

<br>

**Question 02.**

> What is the average unique products purchased in each transaction?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
WITH cte AS (
	SELECT
		txn_id,
		COUNT(DISTINCT prod_id) as product_count
	FROM sales
	GROUP BY txn_id
)

SELECT
	ROUND(AVG(product_count), 0) as avg_unique_products
FROM cte;
```

</details>

| **avg_unique_products** |
| ----------------------: |
|                       6 |

<br>

**Question 03.**

> What are the 25th, 50th and 75th percentile values for the revenue per transaction?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
WITH revenue_per_transaction AS (
	SELECT
		txn_id,
		SUM(qty * price * (100.0 - discount) / 100) as revenue
	FROM sales
	GROUP BY txn_id
)

SELECT
	ROUND(PERCENTILE_DISC(0.25) WITHIN GROUP (ORDER BY revenue), 2) as percentile_25,
	ROUND(PERCENTILE_DISC(0.50) WITHIN GROUP (ORDER BY revenue), 2) as percentile_50,
	ROUND(PERCENTILE_DISC(0.75) WITHIN GROUP (ORDER BY revenue), 2) as percentile_75
FROM revenue_per_transaction;
```

</details>

| **percentile_25** | **percentile_50** | **percentile_75** |
| ----------------: | ----------------: | ----------------: |
|            326.18 |               441 |            572.75 |

<br>

**Question 04.**

> What is the average discount value per transaction?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
WITH cte AS (
	SELECT
		txn_id,
		SUM(qty * price * (1.0 * discount / 100)) as discount
	FROM sales
	GROUP BY txn_id
)

SELECT
	ROUND(AVG(discount), 2) as avg_discount_value
FROM cte;
```

</details>

| **avg_discount_value** |
| ---------------------: |
|                  62.49 |

<br>

**Question 05.**

> What is the percentage split of all transactions for members vs non-members?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
WITH aggregated AS (
	SELECT
		(CASE WHEN member THEN 'member' ELSE 'non-member' END) as _member,
		ROUND(SUM(qty * price * (100.0 - discount) / 100), 2) as revenue
	FROM sales
	GROUP BY _member
)

SELECT
	_member as member,
	revenue,
	ROUND(100 * revenue / (SELECT SUM(revenue) FROM aggregated), 2) as percentage
FROM aggregated;
```

</details>

| **member** | **revenue** | **percentage** |
| ---------- | ----------: | -------------: |
| member     |   683476.13 |          60.31 |
| non-member |   449747.73 |          39.69 |

<br>

**Question 06.**

> What is the average revenue for member transactions and non-member transactions?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
WITH aggregated AS (
	SELECT
		(CASE WHEN member THEN 'member' ELSE 'non-member' END) as _member,
		txn_id,
		ROUND(SUM(qty * price * (100.0 - discount) / 100), 2) as revenue
	FROM sales
	GROUP BY _member, txn_id
)

SELECT
	_member as member,
	ROUND(AVG(revenue), 2) as avg_revenue_per_transaction
FROM aggregated
GROUP BY member;
```

</details>

| **member** | **avg_revenue_per_transaction** |
| ---------- | ------------------------------: |
| member     |                          454.14 |
| non-member |                          452.01 |

<br>

---

[Previous](a-HighLevelSalesAnalysis.md) | [Next](c-ProductAnalysis.md)

[Home](..\README.md)
