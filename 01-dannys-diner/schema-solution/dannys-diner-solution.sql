SET search_path = dannys_diner;

-- a-CaseStudyQuestions
-- 01 - What is the total amount each customer spent at the restaurant?

SELECT
	s.customer_id as customer,
	SUM(price) as amount_spent
FROM sales s
INNER JOIN menu m
	ON s.product_id = m.product_id
GROUP BY customer
ORDER BY customer;

-- 02 - How many days has each customer visited the restaurant?

SELECT
	customer_id as customer,
	COUNT(DISTINCT order_date) as days_count
FROM sales
GROUP BY customer
ORDER BY customer;

-- 03 - What was the first item from the menu purchased by each customer?

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

-- 04 - What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT
	product_name,
	COUNT(*) as times_purchased
FROM sales
INNER JOIN menu USING (product_id)
GROUP BY product_name
ORDER BY times_purchased DESC LIMIT 1;

-- 05 - Which item was the most popular for each customer?

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

-- 06 - Which item was purchased first by the customer after they became a member?

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

-- 07 - Which item was purchased just before the customer became a member?

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

-- 08 - What is the total items and amount spent for each member before they became a member?

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

-- 09 - If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT
	customer_id,
	SUM(m.price*(CASE WHEN m.product_name = 'sushi' THEN 20 ELSE 10 END)) as points
FROM sales s
INNER JOIN menu m
	ON s.product_id = m.product_id
GROUP BY customer_id
ORDER BY customer_id;

-- 10 - In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

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


-- b-BonusQuestions

WITH joined_data AS (
	SELECT
		s.customer_id,
		s.order_date,
		m.product_name,
		m.price,
		(CASE WHEN mb.join_date <= s.order_date THEN 'Y' ELSE 'N' END) as member,
		ROW_NUMBER() OVER() as _row
	FROM sales s
	INNER JOIN menu m USING (product_id)
	LEFT JOIN members mb USING (customer_id)
),

rankings AS (
	SELECT
		_row,
		RANK() OVER(PARTITION BY customer_id ORDER BY order_date) as ranking
	FROM joined_data
	WHERE member = 'Y'
)

SELECT
	customer_id,
	order_date,
	product_name,
	price,
	member,
	ranking
FROM joined_data
LEFT JOIN rankings USING (_row)
ORDER BY customer_id, order_date;