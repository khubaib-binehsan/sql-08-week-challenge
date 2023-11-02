# **Product Funnel Analysis**

```sql
-- PostgreSQL

SET search_path = clique_bait;
```

> Using a single SQL query - create a new output table which has the following details:
>
> - How many times was each product viewed?
>
> - How many times was each product added to cart?
>
> - How many times was each product added to a cart but not purchased (abandoned)?
>
> - How many times was each product purchased?
>
> Additionally, create another table which further aggregates the data for the above points but this time for each product category instead of individual products.

<details>
<summary>Reveal/Hide Solution</summary>

```sql
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
```

</details>

| **product_category** | **product**    | **product_views** | **added_to_cart** | **abandoned_count** | **purchase_count** |
| -------------------- | -------------- | ----------------: | ----------------: | ------------------: | -----------------: |
| Fish                 | Salmon         |              2497 |               938 |                 227 |                711 |
| Fish                 | Kingfish       |              2479 |               920 |                 213 |                707 |
| Fish                 | Tuna           |              2446 |               931 |                 234 |                697 |
| Luxury               | Russian Caviar |              2509 |               946 |                 249 |                697 |
| Luxury               | Black Truffle  |              2393 |               924 |                 217 |                707 |
| Shellfish            | Abalone        |              2457 |               932 |                 233 |                699 |
| Shellfish            | Lobster        |              2515 |               968 |                 214 |                754 |
| Shellfish            | Crab           |              2513 |               949 |                 230 |                719 |
| Shellfish            | Oyster         |              2511 |               943 |                 217 |                726 |

<br>

Use your 2 new output tables - answer the following questions:

**Question 01.**

> Which product had the most views, cart adds and purchases?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
(SELECT 'Most Viewed' as var, product, product_views as _count FROM funnel_analysis ORDER BY product_views DESC LIMIT 1)
UNION ALL
(SELECT 'Most Added to Cart' as var, product, added_to_cart as _count FROM funnel_analysis ORDER BY added_to_cart DESC LIMIT 1)
UNION ALL
(SELECT 'Most Purchased' as var, product, purchase_count as _count FROM funnel_analysis ORDER BY purchase_count DESC LIMIT 1);
```

</details>

| **var**            | **product** | **\_count** |
| ------------------ | ----------- | ----------: |
| Most Viewed        | Lobster     |        2515 |
| Most Added to Cart | Lobster     |         968 |
| Most Purchased     | Lobster     |         754 |

<br>

**Question 02.**

> Which product was most likely to be abandoned?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
SELECT
	product as most_abandoned_product
FROM funnel_analysis
ORDER BY abandoned_count DESC
LIMIT 1;
```

</details>

| **most_abandoned_product** |
| -------------------------- |
| Russian Caviar             |

<br>

**Question 03.**

> Which product had the highest view to purchase percentage?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
SELECT
	product,
	ROUND(100.0 * purchase_count / product_views, 2) as view_purchase_pct
FROM funnel_analysis
ORDER BY view_purchase_pct DESC
LIMIT 1;
```

</details>

| **product** | **view_purchase_pct** |
| ----------- | --------------------: |
| Lobster     |                 29.98 |

<br>

**Question 04.**

> What is the average conversion rate from view to cart add?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
SELECT
	ROUND(100.0 * SUM(added_to_cart) / SUM(product_views), 2) as conversion_rate
FROM funnel_analysis;
```

</details>

| **conversion_rate** |
| ------------------: |
|               37.86 |

<br>

**Question 05.**

> What is the average conversion rate from cart add to purchase?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
SELECT
ROUND(100.0 \* SUM(purchase_count) / SUM(added_to_cart), 2) as conversion_rate
FROM funnel_analysis;
```

</details>

| **conversion_rate** |
| ------------------: |
|               75.93 |

<br>

---

[Previous](b-DigitalAnalysis.md) | [Next](d-CampaignAnalysis.md)

[Home](../README.md)
