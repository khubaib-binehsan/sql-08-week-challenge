SET search_path = data_mart;

-- a-DataCleansingSteps
-- 01. In a single query, perform the following operations and generate a new table in the data_mart schema named clean_weekly_sales:
-- -- Convert the week_date to a DATE format
-- -- Add a week_number as the second column for each week_date value, for example any value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc
-- -- Add a month_number with the calendar month for each week_date value as the 3rd column
-- -- Add a calendar_year column as the 4th column containing either 2018, 2019 or 2020 values
-- -- Add a new column called age_band after the original segment column using the following mapping on the number inside the segment value
-- -- Add a new demographic column using the following mapping for the first letter in the segment values:
-- -- Ensure all null string values with an "unknown" string value in the original segment column as well as the new age_band and demographic columns
-- -- Generate a new avg_transaction column as the sales value divided by transactions rounded to 2 decimal places for each record

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

-- b-DataExploration
-- 01. What day of the week is used for each week_date value?

SELECT
	DISTINCT(TO_CHAR(week_date, 'Day')) as week_day
FROM clean_weekly_sales;

-- 02. What range of week numbers are missing from the dataset?

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

-- 03. How many total transactions were there for each year in the dataset?

SELECT
	TO_CHAR(week_date::DATE, 'YYYY') as year_value,
	SUM(transactions) as transacion_count
FROM weekly_sales
GROUP BY year_value;

-- 04. What is the total sales for each region for each month?
-- only 10 are shown
SELECT
	region,
	TO_CHAR(week_date::DATE, 'YYYY-MM') as month,
	SUM(sales) as total_sales
FROM weekly_sales
GROUP BY region, month
ORDER BY region, month;

-- 05. What is the total count of transactions for each platform

SELECT
	platform,
	SUM(transactions) as transaction_count
FROM weekly_sales
GROUP BY platform;

-- 06. What is the percentage of sales for Retail vs Shopify for each month?

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

-- 07. What is the percentage of sales by demographic for each year in the dataset?

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

-- 08. Which age_band and demographic values contribute the most to Retail sales?

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

-- 09. Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?

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


-- c-BeforeAndAfterAnalysis
-- This technique is usually used when we inspect an important event and want to inspect the impact before and after a certain point in time.
-- Taking the week_date value of 2020-06-15 as the baseline week where the Data Mart sustainable packaging changes came into effect.
-- We would include all week_date values for 2020-06-15 as the start of the period after the change and the previous week_date values would be before
-- Using this analysis approach - answer the following questions:
-- 01. What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?

WITH week_num AS (
	SELECT week_num FROM clean_weekly_sales where week_date = '2020-06-15' LIMIT 1
),

period_filter AS (
	SELECT
		(c.week_num - w.week_num) as diff,
		CASE WHEN (c.week_num - w.week_num) < 0 THEN 'before' ELSE 'after' END as period,
		(c.transactions * c.avg_transaction) as sales
	FROM clean_weekly_sales c, week_num w
	WHERE year_value = 2020
	ORDER BY week_date
),

period_agg AS (
	SELECT
		SUM(CASE WHEN period = 'before' THEN sales ELSE 0 END)::BIGINT as sales_before,
		SUM(CASE WHEN period = 'after' THEN sales ELSE 0 END)::BIGINT as sales_after
	FROM period_filter
	WHERE diff BETWEEN -4 AND 3 -- filters the value to 4 weeks
)

SELECT
	*,
	sales_after - sales_before as growth,
	ROUND(100.0*(sales_after - sales_before) / sales_before, 2) as growth_pct
FROM period_agg;

-- 02. What about the entire 12 weeks before and after?

WITH week_num AS (
	SELECT week_num FROM clean_weekly_sales where week_date = '2020-06-15' LIMIT 1
),

period_filter AS (
	SELECT
		(c.week_num - w.week_num) as diff,
		CASE WHEN (c.week_num - w.week_num) < 0 THEN 'before' ELSE 'after' END as period,
		(c.transactions * c.avg_transaction) as sales
	FROM clean_weekly_sales c, week_num w
	WHERE year_value = 2020
	ORDER BY week_date
),

period_agg AS (
	SELECT
		SUM(CASE WHEN period = 'before' THEN sales ELSE 0 END)::BIGINT as sales_before,
		SUM(CASE WHEN period = 'after' THEN sales ELSE 0 END)::BIGINT as sales_after
	FROM period_filter
)

SELECT
	*,
	sales_after - sales_before as growth,
	ROUND(100.0*(sales_after - sales_before) / sales_before, 2) as growth_pct
FROM period_agg;

-- 03. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?

WITH week_num AS (
	SELECT week_num FROM clean_weekly_sales where week_date = '2020-06-15' LIMIT 1
),

base_data AS (
	SELECT
		c.year_value,
		CASE WHEN (c.week_num - w.week_num) < 0 THEN 'before' ELSE 'after' END as _period,
		c.transactions * c.avg_transaction as sales
	FROM clean_weekly_sales c, week_num w
),

period_agg AS (
	SELECT
		_period,
		year_value,
		SUM(sales) as sales
	FROM base_data
	GROUP BY _period, year_value
	ORDER BY _period DESC, year_value DESC
)

SELECT
	_period,
	SUM(CASE WHEN year_value = 2020 THEN sales ELSE 0 END)::BIGINT as sales_2020,
	SUM(CASE WHEN year_value = 2019 THEN sales ELSE 0 END)::BIGINT as sales_2019,
	SUM(CASE WHEN year_value = 2018 THEN sales ELSE 0 END)::BIGINT as sales_2018
FROM period_agg
GROUP BY _period;

-- d-BonusQuestion
-- Which areas of the business have the highest negative impact in sales metrics performance in 2020 for the 12 week before and after period?
-- -- region
-- -- platform
-- -- age_band
-- -- demographic
-- -- customer_type
-- Do you have any further recommendations for Danny’s team at Data Mart or any interesting insights based off this analysis?

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