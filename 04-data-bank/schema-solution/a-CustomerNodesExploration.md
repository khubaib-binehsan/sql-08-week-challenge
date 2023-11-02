# **Customer Nodes Exploration**

```sql
-- PostgreSQL 15

SET search_path = data_bank;
```

**Question 01.**

> How many unique nodes are there on the Data Bank system?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
SELECT
	COUNT(DISTINCT node_id) as node_count
FROM customer_nodes;
```

</details>

| **node_count** |
| -------------: |
|              5 |

<br>

**Question 02.**

> What is the number of nodes per region?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
SELECT
	region_name,
	COUNT(DISTINCT node_id) as node_count
FROM customer_nodes
INNER JOIN regions USING (region_id)
GROUP BY region_name;
```

</details>

| **region_name** | **node_count** |
| --------------- | -------------: |
| Africa          |              5 |
| America         |              5 |
| Asia            |              5 |
| Australia       |              5 |
| Europe          |              5 |

<br>

**Question 03.**

> How many customers are allocated to each region?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
SELECT
	region_name,
	COUNT(DISTINCT customer_id) as customer_count
FROM customer_nodes
INNER JOIN regions USING (region_id)
GROUP BY region_name;
```

</details>

| **region_name** | **customer_count** |
| --------------- | -----------------: |
| Africa          |                102 |
| America         |                105 |
| Asia            |                 95 |
| Australia       |                110 |
| Europe          |                 88 |

<br>

**Question 04.**

> How many days on average are customers reallocated to a different node?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
WITH cte AS (
SELECT
	customer_id,
	node_id,
	end_date - start_date as difference
FROM customer_nodes
WHERE end_date != '9999-12-31')

SELECT
	ROUND(AVG(difference), 0) as avg_days_to_relocate
FROM cte;
```

</details>

| **avg_days_to_relocate** |
| -----------------------: |
|                       15 |

<br>

**Question 05.**

> What is the median, 80th and 95th percentile for this same reallocation days metric for each region?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
WITH cte AS (
	SELECT
		region_id,
		customer_id,
		node_id,
		end_date - start_date as difference
	FROM customer_nodes
	WHERE end_date != '9999-12-31')

SELECT
	region_name,
	PERCENTILE_DISC(0.50) WITHIN GROUP (ORDER BY difference) as median,
	PERCENTILE_DISC(0.80) WITHIN GROUP (ORDER BY difference) as percentile_80,
	PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY difference) as percentile_95
FROM cte
INNER JOIN regions USING (region_id)
GROUP BY region_name;
```

</details>

| **region_name** | **median** | **percentile_80** | **percentile_95** |
| --------------- | ---------: | ----------------: | ----------------: |
| Africa          |         15 |                24 |                28 |
| America         |         15 |                23 |                28 |
| Asia            |         15 |                23 |                28 |
| Australia       |         15 |                23 |                28 |
| Europe          |         15 |                24 |                28 |

<br>

---

[Next](b-CustomerTransactions.md)

[Home](../README.md)
