# **Data Exploration**

```sql
-- PostgreSQL

SET search_path = data_mart;
```

**Question 01.**

> What day of the week is used for each week_date value?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
SELECT
	DISTINCT(TO_CHAR(week_date, 'Day')) as week_day
FROM clean_weekly_sales;
```

</details>

| **week_day** |
| ------------ |
| Monday       |

<br>

**Question 02.**

> What range of week numbers are missing from the dataset?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
WITH cte AS (
	SELECT * FROM generate_series(1, 52) as week_num

	EXCEPT

	SELECT
		DISTINCT week_num::INTEGER
	FROM clean_weekly_sales
	ORDER BY week_num
)

SELECT
	ARRAY_TO_STRING(ARRAY_AGG(week_num::text), ', ') as missing_weeks
FROM cte;
-- In order to show the output, the final result in aggregated into a single cell, otherwise the result of cre is required output.
```

</details>

| **missing_weeks**                                                                                     |
| ----------------------------------------------------------------------------------------------------- |
| 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52 |

<br>

**Question 03.**

> How many total transactions were there for each year in the dataset?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
SELECT
	TO_CHAR(week_date::DATE, 'YYYY') as year_value,
	SUM(transactions) as transacion_count
FROM weekly_sales
GROUP BY year_value;
```

</details>

| **year_value** | **transacion_count** |
| -------------- | -------------------: |
| 2019           |            365639285 |
| 2018           |            346406460 |
| 2020           |            375813651 |

<br>

**Question 04.**

> What is the total sales for each region for each month?

Only the first 10 rows of the ouput are shown here

<details>
<summary>Reveal/Hide Solution</summary>

```sql
SELECT
	region,
	TO_CHAR(week_date::DATE, 'YYYY-MM') as month,
	SUM(sales) as total_sales
FROM weekly_sales
GROUP BY region, month
ORDER BY region, month;
```

</details>

| **region** | **month** | **total_sales** |
| ---------- | --------- | --------------: |
| AFRICA     | 2018-03   |       130542213 |
| AFRICA     | 2018-04   |       650194751 |
| AFRICA     | 2018-05   |       522814997 |
| AFRICA     | 2018-06   |       519127094 |
| AFRICA     | 2018-07   |       674135866 |
| AFRICA     | 2018-08   |       539077371 |
| AFRICA     | 2018-09   |       135084533 |
| AFRICA     | 2019-03   |       141619349 |
| AFRICA     | 2019-04   |       700447301 |
| AFRICA     | 2019-05   |       553828220 |

<br>

**Question 05.**

> What is the total count of transactions for each platform

<details>
<summary>Reveal/Hide Solution</summary>

```sql
SELECT
	platform,
	SUM(transactions) as transaction_count
FROM weekly_sales
GROUP BY platform;
```

</details>

| **platform** | **transaction_count** |
| ------------ | --------------------: |
| Shopify      |               5925169 |
| Retail       |            1081934227 |

<br>

**Question 06.**

> What is the percentage of sales for Retail vs Shopify for each month?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
WITH unpivot_data AS (
	SELECT
		DATE_TRUNC('month', week_date::DATE)::DATE as month,
		SUM(CASE WHEN platform = 'Retail' THEN sales ELSE 0 END) as retail,
		SUM(CASE WHEN platform = 'Shopify' THEN sales ELSE 0 END) as shopify
	FROM weekly_sales
	GROUP BY month
	ORDER BY month
)

SELECT
	month,
	ROUND(100.0*retail / (retail + shopify), 1) as retial_pct,
	ROUND(100.0*shopify / (retail + shopify), 1) as shopify_pct
FROM unpivot_data;
```

</details>

| **month**  | **retial_pct** | **shopify_pct** |
| ---------- | -------------: | --------------: |
| 01/03/2018 |           97.9 |             2.1 |
| 01/04/2018 |           97.9 |             2.1 |
| 01/05/2018 |           97.7 |             2.3 |
| 01/06/2018 |           97.8 |             2.2 |
| 01/07/2018 |           97.8 |             2.2 |
| 01/08/2018 |           97.7 |             2.3 |
| 01/09/2018 |           97.7 |             2.3 |
| 01/03/2019 |           97.7 |             2.3 |
| 01/04/2019 |           97.8 |             2.2 |
| 01/05/2019 |           97.5 |             2.5 |
| 01/06/2019 |           97.4 |             2.6 |
| 01/07/2019 |           97.4 |             2.6 |
| 01/08/2019 |           97.2 |             2.8 |
| 01/09/2019 |           97.1 |             2.9 |
| 01/03/2020 |           97.3 |             2.7 |

<br>

**Question 07.**

> What is the percentage of sales by demographic for each year in the dataset?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
WITH unpivoted_data AS (
	SELECT
		year_value,
		SUM(CASE WHEN demographic = 'Couples' THEN avg_transaction*transactions ELSE 0 END) as couples,
		SUM(CASE WHEN demographic = 'Families' THEN avg_transaction*transactions ELSE 0 END) as families,
		SUM(CASE WHEN demographic = 'unknown' THEN avg_transaction*transactions ELSE 0 END) as unknown
	FROM clean_weekly_sales
	GROUP BY year_value)

SELECT
	year_value,
	ROUND(100*couples / (couples + families + unknown), 1) as couples_pct,
	ROUND(100*families / (couples + families + unknown), 1) as families_pct,
	ROUND(100*unknown / (couples + families + unknown), 1) as unknown_pct
FROM unpivoted_data;
```

</details>

| **year_value** | **couples_pct** | **families_pct** | **unknown_pct** |
| -------------: | --------------: | ---------------: | --------------: |
|           2018 |            26.4 |             32.1 |            41.5 |
|           2019 |            27.3 |             32.6 |            40.1 |
|           2020 |            28.7 |             32.8 |            38.4 |

<br>

**Question 08.**

> Which age_band and demographic values contribute the most to Retail sales?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
WITH age_band_contributor AS (
	SELECT
		CONCAT('age_band: ', age_band) as demographic_or_age_band,
		SUM(transactions*avg_transaction)::BIGINT as sales
	FROM clean_weekly_sales
	WHERE platform = 'Retail'
	GROUP BY demographic_or_age_band
	ORDER BY sales DESC
	LIMIT 1
),

demographic_contributor AS (
	SELECT
		CONCAT('demographic: ', demographic) as demographic_or_age_band,
		SUM(transactions*avg_transaction)::BIGINT as sales
	FROM clean_weekly_sales
	WHERE platform = 'Retail'
	GROUP BY demographic_or_age_band
	ORDER BY sales DESC
	LIMIT 1
)

SELECT * FROM age_band_contributor
UNION ALL
SELECT * FROM demographic_contributor;
```

</details>

| **demographic_or_age_band** |   **sales** |
| --------------------------- | ----------: |
| age_band: unknown           | 15802776385 |
| demographic: unknown        | 15802776385 |

<br>

**Question 09.**

> Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?

No, the avg_transaction column can not be used directly to calculate the yearly average transaction value since the value it contains is already an aggregated result. If we were to again perform an aggregation, it would be an aggregation over an aggregation, which in this case does not make sense.

Therefore, we calculate the product **transactions \* avg_transaction** for each record, then sum them all together to get the sales of the group. Same we sum the transactions in order to get the total transaction count for the group. Dividing the total sales with total transactions gives us our desired result.

<details>
<summary>Reveal/Hide Solution</summary>

```sql
WITH cte AS (
	SELECT
		platform,
		year_value,
		SUM(transactions) as transactions,
		SUM(transactions * avg_transaction) as sales
	FROM clean_weekly_sales
	GROUP BY platform, year_value
)

SELECT
	year_value,
	SUM(CASE WHEN platform = 'Retail' THEN
	ROUND(sales/transactions, 2) ELSE 0 END) as retails_avg,
	SUM(CASE WHEN platform = 'Shopify' THEN
	ROUND(sales/transactions, 2) ELSE 0 END) as shopify_avg
FROM cte
GROUP BY year_value;
```

</details>

| **year_value** | **retails_avg** | **shopify_avg** |
| -------------: | --------------: | --------------: |
|           2018 |           36.08 |          191.98 |
|           2019 |           36.36 |          182.86 |
|           2020 |           36.07 |          178.55 |

<br>

---

[Previous](a-DataCleansingSteps.md) | [Next](c-BeforeAndAfterAnalysis.md)

[Home](../README.md)
