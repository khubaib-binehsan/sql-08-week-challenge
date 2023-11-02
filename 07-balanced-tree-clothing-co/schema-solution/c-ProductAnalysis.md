# **Product Analysis**

```sql
-- PostgreSQL 15

SET search_path = balanced_tree;
```

**Question 01.**

> What are the top 3 products by total revenue before discount?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
SELECT
	p.product_name,
	SUM(s.qty * s.price) as revenue_before_discount
FROM sales s
INNER JOIN product_details p
	ON p.product_id = s.prod_id
GROUP BY p.product_name
ORDER BY revenue_before_discount DESC
LIMIT 3;
```

</details>

| **product_name**             | **revenue_before_discount** |
| ---------------------------- | --------------------------: |
| Blue Polo Shirt - Mens       |                      217683 |
| Grey Fashion Jacket - Womens |                      209304 |
| White Tee Shirt - Mens       |                      152000 |

<br>

**Question 02.**

> What is the total quantity, revenue and discount for each segment?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
SELECT
	p.segment_name,
	SUM(s.qty) as quantity,
	ROUND(SUM(s.qty * s.price * (100.0 - s.discount) / 100), 2) as revenue,
	ROUND(SUM(s.qty * s.price * (s.discount / 100.0)), 2) as discount
FROM sales s
INNER JOIN product_details p
	ON p.product_id = s.prod_id
GROUP BY p.segment_name;
```

</details>

| **segment_name** | **quantity** | **revenue** | **discount** |
| ---------------- | -----------: | ----------: | -----------: |
| Shirt            |        11265 |   356548.73 |     49594.27 |
| Jeans            |        11349 |   183006.03 |     25343.97 |
| Jacket           |        11385 |   322705.54 |     44277.46 |
| Socks            |        11217 |   270963.56 |     37013.44 |

<br>

**Question 03.**

> What is the top selling product for each segment?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
WITH aggregated AS (
	SELECT
		p.segment_name,
		p.product_name,
		ROUND(SUM(s.qty * s.price * (100.0 - s.discount) / 100), 2) as revenue
	FROM sales s
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
```

</details>

| **segment_name** | **product_name**              | **revenue** |
| ---------------- | ----------------------------- | ----------: |
| Shirt            | Blue Polo Shirt - Mens        |   190863.93 |
| Jacket           | Grey Fashion Jacket - Womens  |   183912.12 |
| Socks            | Navy Solid Socks - Mens       |   119861.64 |
| Jeans            | Black Straight Jeans - Womens |   106407.04 |

<br>

**Question 04.**

> What is the total quantity, revenue and discount for each category?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
SELECT
	p.category_name,
	SUM(s.qty) as quantity,
	ROUND(SUM(s.qty * s.price * (100.0 - s.discount) / 100), 2) as revenue,
	ROUND(SUM(s.qty * s.price * (s.discount / 100.0)), 2) as discount
FROM sales s
INNER JOIN product_details p
	ON p.product_id = s.prod_id
GROUP BY p.category_name;
```

</details>

| **category_name** | **quantity** | **revenue** | **discount** |
| ----------------- | -----------: | ----------: | -----------: |
| Mens              |        22482 |   627512.29 |     86607.71 |
| Womens            |        22734 |   505711.57 |     69621.43 |

<br>

**Question 05.**

> What is the top selling product for each category?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
WITH aggregated AS (
	SELECT
		p.category_name,
		p.product_name,
		ROUND(SUM(s.qty * s.price * (100.0 - s.discount) / 100), 2) as revenue
	FROM sales s
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
```

</details>

| **category_name** | **product_name**             | **revenue** |
| ----------------- | ---------------------------- | ----------: |
| Mens              | Blue Polo Shirt - Mens       |   190863.93 |
| Womens            | Grey Fashion Jacket - Womens |   183912.12 |

<br>

**Question 06.**

> What is the percentage split of revenue by product for each segment?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
WITH aggregated AS (
	SELECT
		p.segment_name,
		p.product_name,
		ROUND(SUM(s.qty * s.price * (100.0 - s.discount) / 100), 2) as revenue
	FROM sales s
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
```

</details>

| **segment_name** | **product_name**                 | **revenue** | **percentage** |
| ---------------- | -------------------------------- | ----------: | -------------: |
| Jacket           | Grey Fashion Jacket - Womens     |   183912.12 |             57 |
| Jacket           | Khaki Suit Jacket - Womens       |    76052.95 |             24 |
| Jacket           | Indigo Rain Jacket - Womens      |    62740.47 |             19 |
| Jeans            | Black Straight Jeans - Womens    |   106407.04 |             58 |
| Jeans            | Navy Oversized Jeans - Womens    |    43992.39 |             24 |
| Jeans            | Cream Relaxed Jeans - Womens     |     32606.6 |             18 |
| Shirt            | Blue Polo Shirt - Mens           |   190863.93 |             54 |
| Shirt            | White Tee Shirt - Mens           |    133622.4 |             37 |
| Shirt            | Teal Button Up Shirt - Mens      |     32062.4 |              9 |
| Socks            | Navy Solid Socks - Mens          |   119861.64 |             44 |
| Socks            | Pink Fluro Polkadot Socks - Mens |    96377.73 |             36 |
| Socks            | White Striped Socks - Mens       |    54724.19 |             20 |

<br>

**Question 07.**

> What is the percentage split of revenue by segment for each category?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
WITH aggregated AS (
	SELECT
		p.category_name,
		p.segment_name,
		ROUND(SUM(s.qty * s.price * (100.0 - s.discount) / 100), 2) as revenue
	FROM sales s
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
```

</details>

| **category_name** | **segment_name** | **revenue** | **percentage** |
| ----------------- | ---------------- | ----------: | -------------: |
| Mens              | Shirt            |   356548.73 |             57 |
| Mens              | Socks            |   270963.56 |             43 |
| Womens            | Jacket           |   322705.54 |             64 |
| Womens            | Jeans            |   183006.03 |             36 |

<br>

**Question 08.**

> What is the percentage split of total revenue by category?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
WITH aggregated AS (
	SELECT
		p.category_name,
		ROUND(SUM(s.qty * s.price * (100.0 - s.discount) / 100), 2) as revenue
	FROM sales s
	INNER JOIN product_details p
		ON p.product_id = s.prod_id
	GROUP BY p.category_name
)

SELECT
	category_name, revenue,
	ROUND(100 * revenue / (SELECT SUM(revenue) FROM aggregated)) as percentage
FROM aggregated;
```

</details>

| **category_name** | **revenue** | **percentage** |
| ----------------- | ----------: | -------------: |
| Mens              |   627512.29 |             55 |
| Womens            |   505711.57 |             45 |

<br>

**Question 09.**

> What is the total transaction “penetration” for each product? (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)

<details>
<summary>Reveal/Hide Solution</summary>

```sql
SELECT
	p.product_name,
	ROUND(100.0 * transactions / (SELECT COUNT(DISTINCT txn_id) FROM sales), 2) as penetration_pct
	FROM (
		SELECT
			prod_id,
			COUNT(DISTINCT txn_id) as transactions
		FROM sales
		GROUP BY prod_id) as agg
INNER JOIN product_details p
	ON p.product_id = agg.prod_id
ORDER BY penetration_pct DESC;
```

</details>

| **product_name**                 | **penetration_pct** |
| -------------------------------- | ------------------: |
| Navy Solid Socks - Mens          |               51.24 |
| Grey Fashion Jacket - Womens     |                  51 |
| Navy Oversized Jeans - Womens    |               50.96 |
| Blue Polo Shirt - Mens           |               50.72 |
| White Tee Shirt - Mens           |               50.72 |
| Pink Fluro Polkadot Socks - Mens |               50.32 |
| Indigo Rain Jacket - Womens      |                  50 |
| Khaki Suit Jacket - Womens       |               49.88 |
| Black Straight Jeans - Womens    |               49.84 |
| Cream Relaxed Jeans - Womens     |               49.72 |
| White Striped Socks - Mens       |               49.72 |
| Teal Button Up Shirt - Mens      |               49.68 |

<br>

**Question 10.**

> What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
WITH subset AS (
    SELECT
        s.txn_id,
        p.product_name,
        p.product_id
    FROM
        sales AS s
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
```

</details>

| **combo**                                                                         | **combo_total** |
| --------------------------------------------------------------------------------- | --------------: |
| Teal Button Up Shirt - Mens, Grey Fashion Jacket - Womens, White Tee Shirt - Mens |             352 |

<br>

---

[Previous](b-TransactionAnalysis.md) | [Next](d-ReportingChallenge.md)

[Home](..\README.md)
