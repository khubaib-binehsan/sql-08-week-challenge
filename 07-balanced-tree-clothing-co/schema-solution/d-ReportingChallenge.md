# **Reporting Challenge**

```sql
-- PostgreSQL 15

SET search_path = balanced_tree;
```

> Write a single SQL script that combines all of the previous questions into a scheduled report that the Balanced Tree team can run at the beginning of each month to calculate the previous month’s values.
>
> Imagine that the Chief Financial Officer (which is also Danny) has asked for all of these questions at the end of every month.
>
> He first wants you to generate the data for January only - but then he also wants you to demonstrate that you can easily run the samne analysis for February without many changes (if at all).
>
> Feel free to split up your final outputs into as many tables as you need - but be sure to explicitly reference which table outputs relate to which question for full marks :)

<details>
<summary>Reveal/Hide Solution</summary>

```sql
SET search_path = balanced_tree;

DROP TABLE IF EXISTS monthly_sales CASCADE;
CREATE TEMP TABLE monthly_sales AS
SELECT
	*
FROM sales
WHERE TO_CHAR(start_txn_time, 'MM-YYYY') = '01-2021'; -- user-input

-- 01. What are the top 3 products by total revenue before discount?

CREATE OR REPLACE VIEW Question01 AS
SELECT
	p.product_name,
	SUM(s.qty * s.price) as revenue_before_discount
FROM monthly_sales s
INNER JOIN product_details p
	ON p.product_id = s.prod_id
GROUP BY p.product_name
ORDER BY revenue_before_discount DESC
LIMIT 3;

-- 02. What is the total quantity, revenue and discount for each segment?

CREATE OR REPLACE VIEW Question02 AS
SELECT
	p.segment_name,
	SUM(s.qty) as quantity,
	ROUND(SUM(s.qty * s.price * (100.0 - s.discount) / 100), 2) as revenue,
	ROUND(SUM(s.qty * s.price * (s.discount / 100.0)), 2) as discounted
FROM monthly_sales s
INNER JOIN product_details p
	ON p.product_id = s.prod_id
GROUP BY p.segment_name;

-- 03. What is the top selling product for each segment?

CREATE OR REPLACE VIEW Question03 AS
WITH aggregated AS (
	SELECT
		p.segment_name,
		p.product_name,
		ROUND(SUM(s.qty * s.price * (100.0 - s.discount) / 100), 2) as revenue
	FROM monthly_sales s
	INNER JOIN product_details p
		ON p.product_id = s.prod_id
	GROUP BY p.segment_name, p.product_name
),

ranked AS (
	SELECT
		*, RANK() OVER(PARTITION BY segment_name ORDER BY revenue DESC) as ranked
	FROM aggregated
)

SELECT
	segment_name, product_name, revenue
FROM ranked
WHERE ranked = 1
ORDER BY revenue DESC;

-- 04. What is the total quantity, revenue and discount for each category?

CREATE OR REPLACE VIEW Question04 AS
SELECT
	p.category_name,
	SUM(s.qty) as quantity,
	ROUND(SUM(s.qty * s.price * (100.0 - s.discount) / 100), 2) as revenue,
	ROUND(SUM(s.qty * s.price * (s.discount / 100.0)), 2) as discounted
FROM monthly_sales s
INNER JOIN product_details p
	ON p.product_id = s.prod_id
GROUP BY p.category_name;

-- 05. What is the top selling product for each category?

CREATE OR REPLACE VIEW Question05 AS
WITH aggregated AS (
	SELECT
		p.category_name,
		p.product_name,
		ROUND(SUM(s.qty * s.price * (100.0 - s.discount) / 100), 2) as revenue
	FROM monthly_sales s
	INNER JOIN product_details p
		ON p.product_id = s.prod_id
	GROUP BY p.category_name, p.product_name
),

ranked AS (
	SELECT
		*, RANK() OVER(PARTITION BY category_name ORDER BY revenue DESC) as ranked
	FROM aggregated
)

SELECT
	category_name, product_name, revenue
FROM ranked
WHERE ranked = 1
ORDER BY revenue DESC;

-- 06. What is the percentage split of revenue by product for each segment?

CREATE OR REPLACE VIEW Question06 AS
WITH aggregated AS (
	SELECT
		p.segment_name,
		p.product_name,
		ROUND(SUM(s.qty * s.price * (100.0 - s.discount) / 100), 2) as revenue
	FROM monthly_sales s
	INNER JOIN product_details p
		ON p.product_id = s.prod_id
	GROUP BY p.segment_name, p.product_name
),

segment_agg AS (
	SELECT
		segment_name,
		SUM(revenue) AS group_total
	FROM aggregated
	GROUP BY segment_name
)

SELECT
	segment_name, product_name, revenue,
	ROUND(100 * revenue / group_total) as percentage
FROM aggregated
INNER JOIN segment_agg USING (segment_name)
ORDER BY segment_name, percentage DESC;

-- 07. What is the percentage split of revenue by segment for each category?

CREATE OR REPLACE VIEW Question07 AS
WITH aggregated AS (
	SELECT
		p.category_name,
		p.segment_name,
		ROUND(SUM(s.qty * s.price * (100.0 - s.discount) / 100), 2) as revenue
	FROM monthly_sales s
	INNER JOIN product_details p
		ON p.product_id = s.prod_id
	GROUP BY p.category_name, p.segment_name
),

category_agg AS (
	SELECT
		category_name,
		SUM(revenue) AS group_total
	FROM aggregated
	GROUP BY category_name
)

SELECT
	category_name, segment_name, revenue,
	ROUND(100 * revenue / group_total) as percentage
FROM aggregated
INNER JOIN category_agg USING (category_name)
ORDER BY category_name, percentage DESC;

-- 08. What is the percentage split of total revenue by category?

CREATE OR REPLACE VIEW Question08 AS
WITH aggregated AS (
	SELECT
		p.category_name,
		ROUND(SUM(s.qty * s.price * (100.0 - s.discount) / 100), 2) as revenue
	FROM monthly_sales s
	INNER JOIN product_details p
		ON p.product_id = s.prod_id
	GROUP BY p.category_name
)

SELECT
	category_name, revenue,
	ROUND(100 * revenue / (SELECT SUM(revenue) FROM aggregated)) as percentage
FROM aggregated;

-- 09. What is the total transaction “penetration” for each product? (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)

CREATE OR REPLACE VIEW Question09 AS
SELECT
	p.product_name,
	ROUND(100.0 * transactions / (SELECT COUNT(DISTINCT txn_id) FROM monthly_sales), 2) as penetration_pct
	FROM (
		SELECT
			prod_id,
			COUNT(DISTINCT txn_id) as transactions
		FROM monthly_sales
		GROUP BY prod_id) as agg
INNER JOIN product_details p
	ON p.product_id = agg.prod_id
ORDER BY penetration_pct DESC;

-- 10. What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?

CREATE OR REPLACE VIEW Question10 AS
WITH subset AS (
    SELECT
        s.txn_id,
        p.product_name,
        p.product_id
    FROM
        monthly_sales AS s
        JOIN product_details AS p ON s.prod_id = p.product_id
),

product_combination AS (
    SELECT
        s1.product_name AS product_1,
        s2.product_name AS product_2,
        s3.product_name AS product_3,
		COUNT(*) as combo_total
    FROM
        subset AS s1
    JOIN subset AS s2 ON s1.txn_id = s2.txn_id
        AND s1.product_id > s2.product_id
    JOIN subset AS s3 ON s2.txn_id = s3.txn_id
        AND s2.product_id > s3.product_id
    GROUP BY product_1, product_2, product_3
    ORDER BY combo_total DESC
    LIMIT 1
)

SELECT
	CONCAT(product_1, ', ', product_2, ', ', product_3) as combo,
	combo_total
FROM product_combination;

-- results

SELECT * FROM Question01;
SELECT * FROM Question02;
SELECT * FROM Question03;
SELECT * FROM Question04;
SELECT * FROM Question05;
SELECT * FROM Question06;
SELECT * FROM Question07;
SELECT * FROM Question08;
SELECT * FROM Question09;
SELECT * FROM Question10;
```

</details>

**Top 3 products before discount:**

| **product_name**             | **revenue_before_discount** |
| ---------------------------- | --------------------------: |
| Grey Fashion Jacket - Womens |                       70200 |
| Blue Polo Shirt - Mens       |                       69198 |
| White Tee Shirt - Mens       |                       50240 |

<br>

**Quantity, Revenue, Discount for each segment:**

| **segment_name** | **quantity** | **revenue** | **discounted** |
| ---------------- | -----------: | ----------: | -------------: |
| Shirt            |         3690 |   115409.62 |       16228.38 |
| Jeans            |         3777 |    60294.32 |        8482.68 |
| Jacket           |         3750 |   106778.62 |       14871.38 |
| Socks            |         3571 |    86600.34 |       12006.66 |

<br>

**Top selling product for each segment:**

| **segment_name** | **product_name**              | **revenue** |
| ---------------- | ----------------------------- | ----------: |
| Jacket           | Grey Fashion Jacket - Womens  |     61619.4 |
| Shirt            | Blue Polo Shirt - Mens        |    60674.22 |
| Socks            | Navy Solid Socks - Mens       |    39946.68 |
| Jeans            | Black Straight Jeans - Womens |    34752.96 |

<br>

**Quantity, Revenue, Discount for each category:**

| **category_name** | **quantity** | **revenue** | **discounted** |
| ----------------- | -----------: | ----------: | -------------: |
| Mens              |         7261 |   202009.96 |       28235.04 |
| Womens            |         7527 |   167072.94 |       23354.06 |

<br>

**Top selling product for each category:**

| **category_name** | **product_name**             | **revenue** |
| ----------------- | ---------------------------- | ----------: |
| Womens            | Grey Fashion Jacket - Womens |     61619.4 |
| Mens              | Blue Polo Shirt - Mens       |    60674.22 |

<br>

**Percentage revenue split of product for each segment:**

| **segment_name** | **product_name**                 | **revenue** | **percentage** |
| ---------------- | -------------------------------- | ----------: | -------------: |
| Jacket           | Grey Fashion Jacket - Womens     |     61619.4 |             58 |
| Jacket           | Khaki Suit Jacket - Womens       |     24736.5 |             23 |
| Jacket           | Indigo Rain Jacket - Womens      |    20422.72 |             19 |
| Jeans            | Black Straight Jeans - Womens    |    34752.96 |             58 |
| Jeans            | Navy Oversized Jeans - Womens    |    14317.16 |             24 |
| Jeans            | Cream Relaxed Jeans - Womens     |     11224.2 |             19 |
| Shirt            | Blue Polo Shirt - Mens           |    60674.22 |             53 |
| Shirt            | White Tee Shirt - Mens           |     44074.4 |             38 |
| Shirt            | Teal Button Up Shirt - Mens      |       10661 |              9 |
| Socks            | Navy Solid Socks - Mens          |    39946.68 |             46 |
| Socks            | Pink Fluro Polkadot Socks - Mens |    29461.39 |             34 |
| Socks            | White Striped Socks - Mens       |    17192.27 |             20 |

<br>

**Percentage revenue split of segment for each category:**

| **category_name** | **segment_name** | **revenue** | **percentage** |
| ----------------- | ---------------- | ----------: | -------------: |
| Mens              | Shirt            |   115409.62 |             57 |
| Mens              | Socks            |    86600.34 |             43 |
| Womens            | Jacket           |   106778.62 |             64 |
| Womens            | Jeans            |    60294.32 |             36 |

<br>

**Percentage revenue split by category:**

| **category_name** | **revenue** | **percentage** |
| ----------------- | ----------: | -------------: |
| Mens              |   202009.96 |             55 |
| Womens            |   167072.94 |             45 |

<br>

**Transaction penetration of each product:**

| **product_name**                 | **penetration_pct** |
| -------------------------------- | ------------------: |
| Cream Relaxed Jeans - Womens     |               52.17 |
| Grey Fashion Jacket - Womens     |               52.05 |
| Navy Oversized Jeans - Womens    |               51.09 |
| Navy Solid Socks - Mens          |               50.72 |
| White Tee Shirt - Mens           |               50.24 |
| Blue Polo Shirt - Mens           |               49.88 |
| Teal Button Up Shirt - Mens      |               49.64 |
| Black Straight Jeans - Womens    |               49.28 |
| Indigo Rain Jacket - Womens      |               49.15 |
| Khaki Suit Jacket - Womens       |               48.55 |
| White Striped Socks - Mens       |               48.19 |
| Pink Fluro Polkadot Socks - Mens |               47.83 |

<br>

**Most common combination:**

| **combo**                                                                            | **combo_total** |
| ------------------------------------------------------------------------------------ | --------------: |
| Navy Solid Socks - Mens, Black Straight Jeans - Womens, Grey Fashion Jacket - Womens |             125 |

<br>

---

[Previous](c-ProductAnalysis.md) | [Next](e-BonusChallenge.md)

[Home](../README.md)
