# **Campaign Analysis**

```sql
-- PostgreSQL

SET search_path = clique_bait;
```

> Generate a table that has 1 single row for every unique visit_id record and has the following columns:
>
> - user_id
>
> - visit_id
>
> - visit_start_time: the earliest event_time for each visit
>
> - page_views: count of page views for each visit
>
> - cart_adds: count of product cart add events for each visit
>
> - purchase: 1/0 flag if a purchase event exists for each visit
>
> - campaign_name: map the visit to a campaign if the visit_start_time falls between the start_date and end_date
>
> - impression: count of ad impressions for each visit
>
> - click: count of ad clicks for each visit
>
> - (Optional column) cart_products: a comma separated text value with products added to the cart sorted by the order they were added to the cart (hint: use the sequence_number)

<details>
<summary>Reveal/Hide Solution</summary>

```sql
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
```

</details>

| **visit_id** | **user_id** | **visit_start** | **page_views** | **cart_adds** | **purchase** | **campaign_name**                 | **ad_impressions** | **ad_clicks** | **cart_products**                                                            |
| ------------ | ----------: | --------------- | -------------: | ------------: | -----------: | --------------------------------- | -----------------: | ------------: | ---------------------------------------------------------------------------- |
| 905563       |         436 | 19:43.4         |              9 |             5 |            0 |                                   |                  0 |             0 | Kingfish, Tuna, Russian Caviar, Abalone, Oyster                              |
| bb4869       |         355 | 50:31.0         |              1 |             0 |            0 | Half Off - Treat Your Shellf(ish) |                  0 |             0 |                                                                              |
| 07ae21       |         417 | 13:17.0         |              5 |             3 |            0 | Half Off - Treat Your Shellf(ish) |                  0 |             0 | Tuna, Russian Caviar, Abalone                                                |
| dff056       |         205 | 05:38.2         |             10 |             7 |            0 | BOGOF - Fishing For Compliments   |                  1 |             1 | Salmon, Tuna, Black Truffle, Abalone, Lobster, Crab, Oyster                  |
| ef55ca       |         451 | 16:27.2         |              9 |             1 |            1 | Half Off - Treat Your Shellf(ish) |                  0 |             0 | Kingfish                                                                     |
| cfbc1c       |          44 | 52:56.6         |              6 |             1 |            1 | BOGOF - Fishing For Compliments   |                  0 |             0 | Oyster                                                                       |
| b201a9       |         272 | 29:11.8         |             11 |             3 |            1 | 25% Off - Living The Lux Life     |                  0 |             0 | Russian Caviar, Crab, Oyster                                                 |
| c0e5fe       |         147 | 18:01.0         |              8 |             1 |            1 | Half Off - Treat Your Shellf(ish) |                  0 |             0 | Salmon                                                                       |
| f97402       |         469 | 57:41.4         |             11 |             8 |            1 | Half Off - Treat Your Shellf(ish) |                  1 |             1 | Salmon, Kingfish, Tuna, Russian Caviar, Black Truffle, Abalone, Crab, Oyster |
| 794f72       |         293 | 33:34.6         |              5 |             1 |            0 | BOGOF - Fishing For Compliments   |                  0 |             0 | Tuna                                                                         |

Use the subsequent dataset to generate at least 5 insights for the Clique Bait team - bonus: prepare a single A4 infographic that the team can use for their management reporting sessions, be sure to emphasise the most important points from your findings.

Some ideas you might want to investigate further include:

Identifying users who have received impressions during each campaign period and comparing each metric with other users who did not have an impression event

Does clicking on an impression lead to higher purchase rates?

What is the uplift in purchase rate when comparing users who click on a campaign impression versus users who do not receive an impression? What if we compare them with users who just an impression but do not click?

What metrics can you use to quantify the success or failure of each campaign compared to eachother?

<br>

---

[Previous](c-ProductFunnelAnalysis.md)

[Home](../README.md)
