SET search_path = balanced_tree;

-- a-HighLevelSalesAnalysis
-- 01. What was the total quantity sold for all products?

SELECT
	SUM(qty) as qty_sold
FROM sales;

-- 02. What is the total generated revenue for all products before discounts?

SELECT
	SUM(qty * price) as revenue
FROM sales;

-- 03. What was the total discount amount for all products?

SELECT
	SUM(qty * price * discount / 100) as discount
FROM sales;


-- b-TransactionAnalysis
-- 01. How many unique transactions were there?

SELECT
	COUNT(DISTINCT txn_id) as total_transactions
FROM sales;

-- 02. What is the average unique products purchased in each transaction?

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

-- 03. What are the 25th, 50th and 75th percentile values for the revenue per transaction?

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

-- 04. What is the average discount value per transaction?

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

-- 05. What is the percentage split of all transactions for members vs non-members?

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

-- 06. What is the average revenue for member transactions and non-member transactions?

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


-- c-ProductAnalysis
-- 01. What are the top 3 products by total revenue before discount?

SELECT
	p.product_name,
	SUM(s.qty * s.price) as revenue_before_discount
FROM sales s
INNER JOIN product_details p
	ON p.product_id = s.prod_id
GROUP BY p.product_name
ORDER BY revenue_before_discount DESC
LIMIT 3;

-- 02. What is the total quantity, revenue and discount for each segment?

SELECT
	p.segment_name,
	SUM(s.qty) as quantity,
	ROUND(SUM(s.qty * s.price * (100.0 - s.discount) / 100), 2) as revenue,
	ROUND(SUM(s.qty * s.price * (s.discount / 100.0)), 2) as discount
FROM sales s
INNER JOIN product_details p
	ON p.product_id = s.prod_id
GROUP BY p.segment_name;

-- 03. What is the top selling product for each segment?

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

-- 04. What is the total quantity, revenue and discount for each category?

SELECT
	p.category_name,
	SUM(s.qty) as quantity,
	ROUND(SUM(s.qty * s.price * (100.0 - s.discount) / 100), 2) as revenue,
	ROUND(SUM(s.qty * s.price * (s.discount / 100.0)), 2) as discount
FROM sales s
INNER JOIN product_details p
	ON p.product_id = s.prod_id
GROUP BY p.category_name;

-- 05. What is the top selling product for each category?

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

-- 06. What is the percentage split of revenue by product for each segment?

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

-- 07. What is the percentage split of revenue by segment for each category?

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

-- 08. What is the percentage split of total revenue by category?

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

-- 09. What is the total transaction “penetration” for each product? (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)

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

-- 10. What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?

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