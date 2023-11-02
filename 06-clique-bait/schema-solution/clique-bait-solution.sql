SET search_path = clique_bait;

-- b-DigitalAnalysis
-- Using the available datasets - answer the following questions using a single query for each one:

-- 01. How many users are there?

SELECT
	COUNT(DISTINCT user_id) as user_count
FROM users;

-- 02. How many cookies does each user have on average?

SELECT
	ROUND(AVG(cookie_count), 0) as avg_cookie_count
FROM (
	SELECT
		user_id,
		COUNT(DISTINCT cookie_id) as cookie_count
	FROM users
	GROUP BY user_id) AS sq;

-- 03. What is the unique number of visits by all users per month?

SELECT
	TO_CHAR(event_time, 'Month') as _month,
	COUNT(DISTINCT visit_id) as monthly_visits
FROM events
GROUP BY EXTRACT('month' from event_time), _month
ORDER BY EXTRACT('month' from event_time);

-- 04. What is the number of events for each event type?

SELECT
	ed.event_name,
	COUNT(*) as number_of_events
FROM events e
INNER JOIN event_identifier ed USING (event_type)
GROUP BY e.event_type, ed.event_name
ORDER BY e.event_type;

-- 05. What is the percentage of visits which have a purchase event?

WITH base_data AS (
	SELECT
		COUNT(DISTINCT visit_id) as purchase_events
	FROM events e
	INNER JOIN event_identifier ed USING (event_type)
	WHERE ed.event_name = 'Purchase'
),

total_visits AS (
	SELECT COUNT(DISTINCT visit_id) as total_visits FROM events
)

SELECT
	ROUND(100.0 * purchase_events / total_visits, 2) as percent_purchased
FROM base_data, total_visits;

-- 06. What is the percentage of visits which view the checkout page but do not have a purchase event?

WITH visits_list AS (
	SELECT
		COUNT(DISTINCT visit_id) as checkout_visits
	FROM events e
	INNER JOIN page_hierarchy p USING (page_id)
	WHERE p.page_name = 'Checkout'
),

purchase_list AS (
	SELECT
		COUNT(DISTINCT visit_id) as purchases
	FROM events e
	INNER JOIN event_identifier ed USING (event_type)
	WHERE ed.event_name = 'Purchase'
)

SELECT
	ROUND(100.0 * purchases / checkout_visits, 2) as percent_purchased
FROM visits_list, purchase_list;

-- 07. What are the top 3 pages by number of views?

SELECT
	p.page_name,
	COUNT(*) as page_views
FROM events e
INNER JOIN page_hierarchy p USING (page_id)
GROUP BY p.page_name
ORDER BY page_views DESC
LIMIT 3;

-- 08. What is the number of views and cart adds for each product category?

WITH base_table AS (
	SELECT
		visit_id,
		page_id,
		LEAD(page_id) OVER(PARTITION BY visit_id) as next_page_id
	FROM events
),

category_views AS (
	SELECT
		ph.product_category,
		COUNT(*) as category_views
	FROM base_table t
	INNER JOIN page_hierarchy ph ON
		t.page_id = ph.page_id
		AND ph.product_category IS NOT NULL
	GROUP BY ph.product_category
),

cart_counts AS (
	SELECT
		ph.product_category,
		COUNT(*) as cart_counts
	FROM base_table t
	INNER JOIN page_hierarchy ph ON
		t.page_id = ph.page_id
		AND ph.product_category IS NOT NULL
	WHERE t.next_page_id = 12
	GROUP BY ph.product_category
)

SELECT
	*
FROM category_views v
INNER JOIN cart_counts c USING (product_category);

-- 09. What are the top 3 products by purchases?

WITH events_with_purchases AS (
	SELECT
		visit_id
	FROM events e
	INNER JOIN event_identifier ei USING (event_type)
	WHERE ei.event_name = 'Purchase'
),

cte AS (
	SELECT
		ph.page_name
	FROM events e
	INNER JOIN events_with_purchases USING (visit_id)
	INNER JOIN page_hierarchy ph
		ON e.page_id = ph.page_id
		AND ph.product_category IS NOT NULL
	INNER JOIN event_identifier ei
		ON e.event_type = ei.event_type
		AND ei.event_name = 'Add to Cart'
)

SELECT
	page_name,
	COUNT(*) as sales_count
FROM cte
GROUP BY page_name
ORDER BY sales_count DESC
LIMIT 3;

-- c-ProductFunnelAnalysis
-- Using a single SQL query - create a new output table which has the following details:
-- -- How many times was each product viewed?
-- -- How many times was each product added to cart?
-- -- How many times was each product added to a cart but not purchased (abandoned)?
-- -- How many times was each product purchased?

-- Additionally, create another table which further aggregates the data for the above points but this time for each product category instead of individual products.

DROP TABLE IF EXISTS funnel_analysis;
CREATE TEMP TABLE funnel_analysis AS
WITH product_views AS (
	SELECT
		page_id,
		COUNT(*) as product_views
	FROM events e
	GROUP BY page_id
),

base_table AS (
	SELECT
		e.visit_id,
		e.page_id
	FROM events e
	INNER JOIN page_hierarchy ph 
		ON e.page_id = ph.page_id
		AND ph.product_category IS NOT NULL
	INNER JOIN event_identifier ei
		ON e.event_type = ei.event_type
		AND ei.event_name = 'Add to Cart'
),

purchase_visits AS (
	SELECT
		visit_id
	FROM events e
	INNER JOIN event_identifier ei USING (event_type)
	WHERE ei.event_name = 'Purchase'
),

added_to_cart AS (
	SELECT
		page_id,
		COUNT(*) as added_to_cart
	FROM base_table
	GROUP BY page_id
),

purchase_count AS (
	SELECT
		page_id,
		COUNT(*) as purchase_count
	FROM base_table bt
	INNER JOIN purchase_visits pv USING (visit_id)
	GROUP BY page_id
)

SELECT
	product_category,
	page_name as product,
	product_views,
	added_to_cart,
	(added_to_cart - purchase_count) as abandoned_count,
	purchase_count
FROM page_hierarchy
LEFT JOIN product_views USING (page_id)
LEFT JOIN added_to_cart USING (page_id)
LEFT JOIN purchase_count USING (page_id)
WHERE product_category IS NOT NULL;

SELECT * FROM funnel_analysis;
-- Use your 2 new output tables - answer the following questions:

-- 01. Which product had the most views, cart adds and purchases?

(SELECT 'Most Viewed' as var, product, product_views as _count FROM funnel_analysis ORDER BY product_views DESC LIMIT 1)
UNION ALL
(SELECT 'Most Added to Cart' as var, product, added_to_cart as _count FROM funnel_analysis ORDER BY added_to_cart DESC LIMIT 1)
UNION ALL
(SELECT 'Most Purchased' as var, product, purchase_count as _count FROM funnel_analysis ORDER BY purchase_count DESC LIMIT 1);

-- 02. Which product was most likely to be abandoned?

SELECT
	product as most_abandoned_product
FROM funnel_analysis
ORDER BY abandoned_count DESC
LIMIT 1;

-- 03. Which product had the highest view to purchase percentage?

SELECT
	product,
	ROUND(100.0 * purchase_count / product_views, 2) as view_purchase_pct
FROM funnel_analysis
ORDER BY view_purchase_pct DESC
LIMIT 1;

-- 04. What is the average conversion rate from view to cart add?

SELECT
	ROUND(100.0 * SUM(added_to_cart) / SUM(product_views), 2) as conversion_rate
FROM funnel_analysis;

-- 05. What is the average conversion rate from cart add to purchase?

SELECT
	ROUND(100.0 * SUM(purchase_count) / SUM(added_to_cart), 2) as conversion_rate
FROM funnel_analysis;

-- d-CampaignAnalysis
-- Generate a table that has 1 single row for every unique visit_id record and has the following columns:

-- -- user_id
-- -- visit_id
-- -- visit_start_time: the earliest event_time for each visit
-- -- page_views: count of page views for each visit
-- -- cart_adds: count of product cart add events for each visit
-- -- purchase: 1/0 flag if a purchase event exists for each visit
-- -- campaign_name: map the visit to a campaign if the visit_start_time falls between the start_date and end_date
-- -- impression: count of ad impressions for each visit
-- -- click: count of ad clicks for each visit
-- -- (Optional column) cart_products: a comma separated text value with products added to the cart sorted by the order they were added to the cart (hint: use the sequence_number)

DROP TABLE IF EXISTS clique_bait_agg;
CREATE TEMP TABLE clique_bait_agg AS
SELECT
	e.visit_id,
	u.user_id,
	MIN(e.event_time) as visit_start,
	SUM(CASE WHEN ei.event_name = 'Page View' THEN 1 ELSE 0 END) as page_views,
	SUM(CASE WHEN ei.event_name = 'Add to Cart' THEN 1 ELSE 0 END) as cart_adds,
	SUM(CASE WHEN ei.event_name = 'Purchase' THEN 1 ELSE 0 END) as purchase,
	c.campaign_name,
	SUM(CASE WHEN ei.event_name = 'Ad Impression' THEN 1 ELSE 0 END) as ad_impressions,
	SUM(CASE WHEN ei.event_name = 'Ad Click' THEN 1 ELSE 0 END) as ad_clicks,
	STRING_AGG(CASE WHEN ei.event_name = 'Add to Cart' THEN p.page_name ELSE NULL END, ', ' ORDER BY e.sequence_number) as cart_products
FROM events e
INNER JOIN users u USING (cookie_id)
INNER JOIN event_identifier ei USING (event_type)
INNER JOIN page_hierarchy p USING (page_id)
LEFT JOIN campaign_identifier c
	ON e.event_time BETWEEN c.start_date AND c.end_date
GROUP BY e.visit_id, u.user_id, c.campaign_name;

SELECT * FROM clique_bait_agg ORDER BY RANDOM() LIMIT 10;