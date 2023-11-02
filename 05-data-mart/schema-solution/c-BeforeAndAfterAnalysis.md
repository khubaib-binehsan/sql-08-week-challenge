# **Before & After Analysis**

```sql
-- PostgreSQL

SET search_path = data_mart;
```

This technique is usually used when we inspect an important event and want to inspect the impact before and after a certain point in time.

Taking the week_date value of 2020-06-15 as the baseline week where the Data Mart sustainable packaging changes came into effect. We would include all week_date values for 2020-06-15 as the start of the period after the change and the previous week_date values would be before

Using this analysis approach - answer the following questions:

**Question 01.**

> What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
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
```

</details>

| **sales_before** | **sales_after** | **growth** | **growth_pct** |
| ---------------: | --------------: | ---------: | -------------: |
|       2311282595 |      2289812739 |  -21469856 |          -0.93 |

<br>

**Question 02.**

> What about the entire 12 weeks before and after?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
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
    ROUND(100.0_(sales_after - sales_before) / sales_before, 2) as growth_pct
FROM period_agg;
```

</details>

| **sales_before** | **sales_after** | **growth** | **growth_pct** |
| ---------------: | --------------: | ---------: | -------------: |
|       7025818620 |      6890073729 | -135744891 |          -1.93 |

<br>

**Question 03.**

> How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
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
```

</details>

| **\_period** | **sales_2020** | **sales_2019** | **sales_2018** |
| -----------: | -------------: | -------------: | -------------: |
|       before |     7025818620 |     6795777943 |     6311822572 |
|        after |     6890073729 |     6776201486 |     6417587790 |

<br>

---

[Previous](b-DataExploration.md) | [Next](d-BonusQuestion.md)

[Home](../README.md)
