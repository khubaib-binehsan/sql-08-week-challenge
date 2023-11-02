# **Digital Analysis**

```sql
-- PostgreSQL

SET search_path = clique_bait;
```

**Question 01.**

> How many users are there?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
SELECT
	COUNT(DISTINCT user_id) as user_count
FROM users;
```

</details>

| **user_count** |
| -------------: |
|            500 |

<br>

**Question 02.**

> How many cookies does each user have on average?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
SELECT
	ROUND(AVG(cookie_count), 0) as avg_cookie_count
FROM (
	SELECT
		user_id,
		COUNT(DISTINCT cookie_id) as cookie_count
	FROM users
	GROUP BY user_id) AS sq;
```

</details>

| **avg_cookie_count** |
| -------------------: |
|                    4 |

<br>

**Question 03.**

> What is the unique number of visits by all users per month?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
SELECT
	TO_CHAR(event_time, 'Month') as _month,
	COUNT(DISTINCT visit_id) as monthly_visits
FROM events
GROUP BY EXTRACT('month' from event_time), _month
ORDER BY EXTRACT('month' from event_time);
```

</details>

| **\_month** | **monthly_visits** |
| ----------- | -----------------: |
| January     |                876 |
| February    |               1488 |
| March       |                916 |
| April       |                248 |
| May         |                 36 |

<br>

**Question 04.**

> What is the number of events for each event type?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
SELECT
    ed.event_name,
    COUNT(*) as number_of_events
FROM events e
INNER JOIN event_identifier ed USING (event_type)
GROUP BY e.event_type, ed.event_name
ORDER BY e.event_type;
```

</details>

| **event_name** | **number_of_events** |
| -------------- | -------------------: |
| Page View      |                20928 |
| Add to Cart    |                 8451 |
| Purchase       |                 1777 |
| Ad Impression  |                  876 |
| Ad Click       |                  702 |

<br>

**Question 05.**

> What is the percentage of visits which have a purchase event?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
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
```

</details>

| **percent_purchased** |
| --------------------: |
|                 49.86 |

<br>

**Question 06.**

> What is the percentage of visits which view the checkout page but do not have a purchase event?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
WITH visits_list AS (
    SELECT
        COUNT(DISTINCT visit_id) as checkout_visits
    FROM events e
    INNER JOIN page_hierarchy p USING (page_id)
    WHERE p.page_name = 'Checkout'
),

purchase_list AS (
    SELECT
        COUNT(DISTINCT visit_id) as purchased
        FROM events e
    INNER JOIN event_identifier ed USING (event_type)
    WHERE ed.event_name = 'Purchase'
)

SELECT
    ROUND(100.0 * purchases / checkout_visits, 2) as percent_purchases
FROM visits_list, purchase_list;
```

</details>

| **percent_purchased** |
| --------------------: |
|                  84.5 |

<br>

**Question 07.**

> What are the top 3 pages by number of views?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
SELECT
    p.page_name,
    COUNT(*) as page_views
FROM events e
INNER JOIN page_hierarchy p USING (page_id)
GROUP BY p.page_name
ORDER BY page_views DESC
LIMIT 3;
```

</details>

| **page_name** | **page_views** |
| ------------- | -------------: |
| All Products  |           4752 |
| Lobster       |           2515 |
| Crab          |           2513 |

<br>

**Question 08.**

> What is the number of views and cart adds for each product category?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
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
    INNER JOIN page_hierarchy ph
        ON t.page_id = ph.page_id
        AND ph.product_category IS NOT NULL
    GROUP BY ph.product_category
),

cart_counts AS (
    SELECT
        ph.product_category,
        COUNT(*) as cart_counts
    FROM base_table t
    INNER JOIN page_hierarchy ph
        ON t.page_id = ph.page_id
        AND ph.product_category IS NOT NULL
    WHERE t.next_page_id = 12
    GROUP BY ph.product_category
)

SELECT
    *
FROM category_views v
INNER JOIN cart_counts c USING (product_category);
```

</details>

| **product_category** | **category_views** | **cart_counts** |
| -------------------- | -----------------: | --------------: |
| Luxury               |               4902 |              55 |
| Shellfish            |               9996 |            2036 |
| Fish                 |               7422 |              12 |

<br>

**Question 09.**

> What are the top 3 products by purchases?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
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
```

</details>

| **page_name** | **sales_count** |
| ------------- | --------------: |
| Lobster       |             754 |
| Oyster        |             726 |
| Crab          |             719 |

<br>

---

[Previous](a-EnterpriseRelationshipDiagram.md) | [Next](c-ProductFunnelAnalysis.md)

[Home](../README.md)
