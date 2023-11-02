# **Data Cleansing Steps**

```sql
-- PostgreSQL

SET search_path = data_mart;
```

> In a single query, perform the following operations and generate a new table in the data_mart schema named clean_weekly_sales:
>
> - Convert the week_date to a DATE format
>
> - Add a week_number as the second column for each week_date value, for example any value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc
>
> - Add a month_number with the calendar month for each week_date value as the 3rd column
>
> - Add a calendar_year column as the 4th column containing either 2018, 2019 or 2020 values
>
> - Add a new column called age_band after the original segment column using the following mapping on the number inside the segment value
>
> - Add a new demographic column using the following mapping for the first letter in the segment values:
>
> - Ensure all null string values with an "unknown" string value in the original segment column as well as the new age_band and demographic columns
>
> - Generate a new avg_transaction column as the sales value divided by transactions rounded to 2 decimal places for each record

<details>
<summary>Reveal/Hide Solution</summary>

```sql
DROP TABLE IF EXISTS clean_weekly_sales;
CREATE TEMP TABLE clean_weekly_sales AS
WITH cleaned_table AS (
	SELECT
		week_date::DATE,
		EXTRACT('week' FROM (week_date::DATE - INTERVAL '2 DAY')) as week_num,
		EXTRACT('month' FROM week_date::DATE) as month_num,
		EXTRACT('year' FROM week_date::DATE) as year_value,
		(CASE WHEN segment = 'null' THEN NULL ELSE RIGHT(segment, 1)::NUMERIC END) as segment_age,
		(CASE WHEN segment = 'null' THEN NULL ELSE LEFT(segment, 1) END) as segment_dg,
		region,
		platform,
		customer_type,
		transactions,
		ROUND(sales/transactions, 2) as avg_transaction
	FROM weekly_sales
),

age_band_table AS (
-- 	SELECT UNNEST(STRING_TO_ARRAY('1, 2, 3, 4', ', '))::NUMERIC as segment_age,
-- 	UNNEST(STRING_TO_ARRAY('Young Adults, Middle Aged, Retirees, Retirees', ', ')) as age_band
	SELECT * FROM
		(VALUES (1, 'Young Adults'), (2, 'Middle Aged'), (3, 'Retirees'), (4, 'Retirees')) AS t (segment_age, age_band)
),

demographic_table AS (
-- 	SELECT UNNEST(STRING_TO_ARRAY('C, F', ', ')) as segment_dg,
-- 	UNNEST(STRING_TO_ARRAY('Couples, Families', ', ')) as demographic
	SELECT * FROM (VALUES ('C', 'Couples'), ('F', 'Families')) AS t (segment_dg, demographic)
)

SELECT
	week_date,
	week_num,
	month_num,
	year_value,
	region,
	platform,
	customer_type,
	COALESCE(age.age_band, 'unknown') as age_band,
	COALESCE(dg.demographic, 'unknown') as demographic,
	transactions,
	avg_transaction
FROM cleaned_table c
LEFT JOIN age_band_table age USING (segment_age)
LEFT JOIN demographic_table dg USING (segment_dg);

SELECT * FROM clean_weekly_sales ORDER BY random() LIMIT 10;
```

</details>

| **week_date** | **week_num** | **month_num** | **year_value** | **region**    | **platform** | **customer_type** | **age_band** | **demographic** | **transactions** | **avg_transaction** |
| ------------- | -----------: | ------------: | -------------: | ------------- | ------------ | ----------------- | ------------ | --------------- | ---------------: | ------------------: |
| 15/04/2019    |           15 |             4 |           2019 | OCEANIA       | Retail       | New               | Retirees     | Families        |            96384 |                  35 |
| 15/06/2020    |           24 |             6 |           2020 | SOUTH AMERICA | Shopify      | Existing          | Young Adults | Families        |               67 |                 227 |
| 18/06/2018    |           24 |             6 |           2018 | USA           | Shopify      | New               | Retirees     | Couples         |              119 |                 179 |
| 13/08/2018    |           32 |             8 |           2018 | EUROPE        | Shopify      | New               | unknown      | unknown         |               12 |                 155 |
| 24/08/2020    |           34 |             8 |           2020 | EUROPE        | Retail       | Existing          | Retirees     | Families        |            18657 |                  59 |
| 05/08/2019    |           31 |             8 |           2019 | OCEANIA       | Retail       | New               | Middle Aged  | Families        |            87664 |                  35 |
| 25/05/2020    |           21 |             5 |           2020 | EUROPE        | Shopify      | Existing          | Young Adults | Families        |              158 |                 189 |
| 31/08/2020    |           35 |             8 |           2020 | SOUTH AMERICA | Retail       | Guest             | unknown      | unknown         |           413244 |                  40 |
| 30/03/2020    |           13 |             3 |           2020 | OCEANIA       | Retail       | Existing          | Middle Aged  | Couples         |           173099 |                  39 |
| 04/05/2020    |           18 |             5 |           2020 | AFRICA        | Shopify      | New               | Retirees     | Families        |              111 |                 154 |

<br>

---

[Next](b-DataExploration.md)

[Home](../README.md)
