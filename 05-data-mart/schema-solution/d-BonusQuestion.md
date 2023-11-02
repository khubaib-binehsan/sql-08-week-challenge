# **Bonus Question**

```sql
-- PostgreSQL

SET search_path = data_mart;
```

> Which areas of the business have the highest negative impact in sales metrics performance in 2020 for the 12 week before and after period?
>
> - region
>
> - platform
>
> - age_band
>
> - demographic
>
> - customer_type
>
> Do you have any further recommendations for Danny’s team at Data Mart or any interesting insights based off this analysis?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
WITH week_num AS (
	SELECT week_num FROM clean_weekly_sales where week_date = '2020-06-15' LIMIT 1
),

base_data AS (
	SELECT
		c.region,
		c.platform,
		c.age_band,
		c.demographic,
		c.customer_type,
		(c.transactions * c.avg_transaction) as sales,
		CASE WHEN (c.week_num - w.week_num) < 0 THEN 'before' ELSE 'after' END as _period
	FROM clean_weekly_sales c, week_num w
	WHERE year_value = 2020
),

region_data AS (
	SELECT
		region as area,
		ROUND((100.0*after_sales / before_sales) - 100, 2) as impact
	FROM (
		SELECT
			CONCAT('Region: ', region) as region,
			SUM(CASE WHEN _period = 'before' THEN sales ELSE 0 END) as before_sales,
			SUM(CASE WHEN _period = 'after' THEN sales ELSE 0 END) as after_sales
		FROM base_data
		GROUP BY region
	) as sq
	ORDER BY impact
	LIMIT 1
),

platform_data AS (
	SELECT
		platform as area,
		ROUND((100.0*after_sales / before_sales) - 100, 2) as impact
	FROM (
		SELECT
			CONCAT('Platform: ', platform) as platform,
			SUM(CASE WHEN _period = 'before' THEN sales ELSE 0 END) as before_sales,
			SUM(CASE WHEN _period = 'after' THEN sales ELSE 0 END) as after_sales
		FROM base_data
		GROUP BY platform
	) as sq
	ORDER BY impact
	LIMIT 1
),

ageband_data AS (
	SELECT
		age_band as area,
		ROUND((100.0*after_sales / before_sales) - 100, 2) as impact
	FROM (
		SELECT
			CONCAT('Age Band: ', age_band) as age_band,
			SUM(CASE WHEN _period = 'before' THEN sales ELSE 0 END) as before_sales,
			SUM(CASE WHEN _period = 'after' THEN sales ELSE 0 END) as after_sales
		FROM base_data
		GROUP BY age_band
	) as sq
	ORDER BY impact
	LIMIT 1
),

demographic_data AS (
	SELECT
		demographic as area,
		ROUND((100.0*after_sales / before_sales) - 100, 2) as impact
	FROM (
		SELECT
			CONCAT('Demographic: ', demographic) as demographic,
			SUM(CASE WHEN _period = 'before' THEN sales ELSE 0 END) as before_sales,
			SUM(CASE WHEN _period = 'after' THEN sales ELSE 0 END) as after_sales
		FROM base_data
		GROUP BY demographic
	) as sq
	ORDER BY impact
	LIMIT 1
),

customer_type_data AS (
	SELECT
		customer_type as area,
		ROUND((100.0*after_sales / before_sales) - 100, 2) as impact
	FROM (
		SELECT
			CONCAT('Customer Type: ', customer_type) as customer_type,
			SUM(CASE WHEN _period = 'before' THEN sales ELSE 0 END) as before_sales,
			SUM(CASE WHEN _period = 'after' THEN sales ELSE 0 END) as after_sales
		FROM base_data
		GROUP BY customer_type
	) as sq
	ORDER BY impact
	LIMIT 1
)

SELECT * FROM region_data
UNION ALL
SELECT * FROM platform_data
UNION ALL
SELECT * FROM ageband_data
UNION ALL
SELECT * FROM demographic_data
UNION ALL
SELECT * FROM customer_type_data;
```

</details>

| **area**             | **impact** |
| -------------------- | ---------: |
| Region: ASIA         |       -3.1 |
| Platform: Retail     |      -2.23 |
| Age Band: unknown    |      -2.96 |
| Demographic: unknown |      -2.96 |
| Customer Type: Guest |      -2.59 |

<br>

---

[Previous](c-BeforeAndAfterAnalysis.md)

[Home](../README.md)
