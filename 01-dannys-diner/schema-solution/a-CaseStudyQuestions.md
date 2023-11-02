# **Case Study Questions**

```sql
-- PostgreSQl 15

SET search_path = dannys_diner;
```

**Question 01.**

> What is the total amount each customer spent at the restaurant?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
SELECT
	s.customer_id,
	SUM(price) as amount_spent
FROM sales s
INNER JOIN menu m
	ON s.product_id = m.product_id
GROUP BY s.customer
ORDER BY s.customer;
```

</details>

| **customer_id** | **amount_spent** |
| --------------- | ---------------: |
| A               |               76 |
| B               |               74 |
| C               |               36 |

<br>

**Question 02.**

> How many days has each customer visited the restaurant?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
SELECT
	customer_id,
	COUNT(DISTINCT order_date) as days_count
FROM sales
GROUP BY customer_id
ORDER BY customer_id;
```

</details>

| **customer_id** | **days_count** |
| --------------- | -------------: |
| A               |              4 |
| B               |              6 |
| C               |              2 |

<br>

**Question 03.**

> What was the first item from the menu purchased by each customer?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
WITH cte_ranked AS (
	SELECT
		s.customer_id,
		m.product_name,
		ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) as ranked
	FROM sales s
	INNER JOIN menu m USING (product_id)
)

SELECT
	customer_id,
	product_name
FROM cte_ranked
WHERE ranked = 1
ORDER BY customer_id;
```

</details>

| **customer_id** | **product_name** |
| --------------- | ---------------- |
| A               | curry            |
| B               | curry            |
| C               | ramen            |

<br>

**Question 04.**

> What is the most purchased item on the menu and how many times was it purchased by all customers?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
SELECT
	product_name,
	COUNT(*) as times_purchased
FROM sales
INNER JOIN menu USING (product_id)
GROUP BY product_name
ORDER BY times_purchased DESC LIMIT 1;
```

</details>

| **product_name** | **times_purchased** |
| ---------------- | ------------------: |
| ramen            |                   8 |

<br>

**Question 05.**

> Which item was the most popular for each customer?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
WITH cte AS (
	SELECT
		customer_id,
		product_name,
		COUNT(*) as times_purchased
	FROM sales
	INNER JOIN menu USING (product_id)
	GROUP BY customer_id, product_name
	ORDER BY customer_id
),

cte_ranked AS (
	SELECT
		*,
		RANK() OVER(PARTITION BY customer_id ORDER BY times_purchased DESC) as ranked
	FROM cte
)

SELECT
	customer_id,
	product_name,
	times_purchased
FROM cte_ranked
WHERE ranked = 1;
```

</details>

| **customer_id** | **product_name** | **times_purchased** |
| --------------- | ---------------- | ------------------: |
| A               | ramen            |                   3 |
| B               | curry            |                   2 |
| B               | ramen            |                   2 |
| B               | sushi            |                   2 |
| C               | ramen            |                   3 |

<br>

**Question 06.**

> Which item was purchased first by the customer after they became a member?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
WITH cte as (
	SELECT
		s.customer_id,
		s.order_date,
		m.product_name,
		mb.join_date <= s.order_date as _joined
	FROM sales s
	INNER JOIN menu m USING (product_id)
	LEFT JOIN members mb
		ON s.customer_id = mb.customer_id
),

cte_ranked AS (
	SELECT
		customer_id,
		order_date,
		CASE WHEN _joined THEN product_name ELSE null END as product_name,
		ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_date) as ranked
	FROM cte
	WHERE _joined = true
		OR _joined IS null
)

SELECT
	customer_id,
	product_name
FROM cte_ranked
WHERE ranked = 1
ORDER BY customer_id;
```

</details>

| **customer_id** | **product_name** |
| --------------- | ---------------- |
| A               | curry            |
| B               | sushi            |
| C               |                  |

<br>

**Question 07.**

> Which item was purchased just before the customer became a member?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
WITH cte as (
	SELECT
		s.customer_id,
		s.order_date,
		m.product_name,
		mb.join_date <= s.order_date as _joined,
		ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) as order_number
	FROM sales s
	INNER JOIN menu m USING (product_id)
	LEFT JOIN members mb
		ON s.customer_id = mb.customer_id
),

cte_ranked AS (
	SELECT
		customer_id,
		CASE WHEN NOT _joined THEN product_name ELSE null END as product_name,
		ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_number DESC) as ranked
	FROM cte
	WHERE _joined = false
		OR _joined IS null
)

SELECT
	customer_id,
	product_name
FROM cte_ranked
WHERE ranked = 1
ORDER BY customer_id;
```

</details>

| **customer_id** | **product_name** |
| --------------- | ---------------- |
| A               | curry            |
| B               | sushi            |
| C               |                  |

<br>

**Question 08.**

> What is the total items and amount spent for each member before they became a member?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
WITH cte as (
	SELECT
		s.customer_id,
		p.price,
		m.join_date <= s.order_date as _joined
	FROM sales s
	LEFT JOIN members m
		ON s.customer_id = m.customer_id
	INNER JOIN menu p
		ON s.product_id = p.product_id
)

SELECT
	customer_id,
	NULLIF(COUNT(CASE WHEN NOT _joined THEN price ELSE null END), 0) as item_count,
	SUM(CASE WHEN NOT _joined THEN price ELSE null END) as total_price
FROM cte
WHERE _joined = false
	OR _joined IS null
GROUP BY customer_id
ORDER BY customer_id;
```

</details>

| **customer_id** | **item_count** | **total_price** |
| --------------- | -------------: | --------------: |
| A               |              2 |              25 |
| B               |              3 |              40 |
| C               |                |                 |

<br>

**Question 09.**

> If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
SELECT
	customer_id,
	SUM(m.price*(CASE WHEN m.product_name = 'sushi' THEN 20 ELSE 10 END)) as points
FROM sales s
INNER JOIN menu m
	ON s.product_id = m.product_id
GROUP BY customer_id
ORDER BY customer_id;
```

</details>

| **customer_id** | **points** |
| --------------- | ---------: |
| A               |        860 |
| B               |        940 |
| C               |        360 |

<br>

**Question 10.**

> In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
WITH cte AS (
	SELECT
		s.customer_id,
		p.price,
		s.order_date - m.join_date as _joined_days
	FROM sales s
	INNER JOIN members m
		ON s.customer_id = m.customer_id
		AND m.customer_id IN ('A' , 'B')
	INNER JOIN menu p
		ON s.product_id = p.product_id
	WHERE s.order_date <= '2021-01-31'
)

SELECT
	customer_id,
	SUM(price*(CASE WHEN (_joined_days BETWEEN 0 AND 6) THEN 20 ELSE 10 END)) as points
FROM cte
GROUP BY customer_id
ORDER BY customer_id;
```

</details>

| **customer_id** | **points** |
| --------------- | ---------: |
| A               |       1270 |
| B               |        720 |

<br>

---

[Next](./b-BonusQuestions.md)

[Home](../README.md)
