-- d-ReportingChallenge

SET search_path = balanced_tree;

-- change the user input value as desired

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