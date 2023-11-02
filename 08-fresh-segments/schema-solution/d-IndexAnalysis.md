# **Index Analysis**

```sql
-- PostgreSQL 15

SET search_path = fresh_segments;
```

**Question 01.**

> What is the top 10 interests by the average composition for each month?

Data is only shown for the month '07-2018'.

<details>
<summary>Reveal/Hide Solution</summary>

```sql
WITH ranked AS (
	SELECT
		*,
		ROUND((composition/index_value)::NUMERIC, 2) as avg_composition,
		ROW_NUMBER() OVER(PARTITION BY month_year ORDER BY ROUND((composition/index_value)::NUMERIC, 2) DESC) as _rank
	FROM interest_metrics
)

SELECT
	r.month_year,
	r.interest_id,
	mp.interest_name,
	r.avg_composition
FROM ranked r
INNER JOIN interest_map mp
	ON r.interest_id = mp.id::VARCHAR
WHERE r._rank <= 10
ORDER BY r.month_year, r.avg_composition DESC;
```

</details>

| **month_year** | **interest_id** | **interest_name**             | **avg_composition** |
| -------------- | --------------- | ----------------------------- | ------------------: |
| 7/1/2018       | 6324            | Las Vegas Trip Planners       |                7.36 |
| 7/1/2018       | 6284            | Gym Equipment Owners          |                6.94 |
| 7/1/2018       | 4898            | Cosmetics and Beauty Shoppers |                6.78 |
| 7/1/2018       | 77              | Luxury Retail Shoppers        |                6.61 |
| 7/1/2018       | 39              | Furniture Shoppers            |                6.51 |
| 7/1/2018       | 18619           | Asian Food Enthusiasts        |                 6.1 |
| 7/1/2018       | 6208            | Recently Retired Individuals  |                5.72 |
| 7/1/2018       | 21060           | Family Adventures Travelers   |                4.85 |
| 7/1/2018       | 21057           | Work Comes First Travelers    |                 4.8 |
| 7/1/2018       | 82              | HDTV Researchers              |                4.71 |

<br>

**Question 02.**

> For all of these top 10 interests - which interest appears the most often?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
WITH ranked AS (
	SELECT
		*,
		ROUND((composition/index_value)::NUMERIC, 2) as avg_composition,
		ROW_NUMBER() OVER(PARTITION BY month_year ORDER BY ROUND((composition/index_value)::NUMERIC, 2) DESC) as _rank
	FROM interest_metrics
)

SELECT
	r.interest_id,
	mp.interest_name,
	COUNT(*) as times_appeared
FROM ranked r
INNER JOIN interest_map mp
	ON r.interest_id = mp.id::VARCHAR
WHERE r._rank <= 10
GROUP BY r.interest_id, mp.interest_name
ORDER BY times_appeared DESC
LIMIT 1;
```

</details>

| **interest_id** | **interest_name**     | **times_appeared** |
| --------------- | --------------------- | -----------------: |
| 7541            | Alabama Trip Planners |                 10 |

<br>

**Question 03.**

> What is the average of the average composition for the top 10 interests for each month?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
WITH ranked AS (
	SELECT
		*,
		ROUND((composition/index_value)::NUMERIC, 2) as avg_composition,
		ROW_NUMBER() OVER(PARTITION BY month_year ORDER BY ROUND((composition/index_value)::NUMERIC, 2) DESC) as _rank
	FROM interest_metrics
)

SELECT
	month_year,
	ROUND(AVG(avg_composition), 2) as avg_composition
FROM ranked
WHERE _rank <= 10
GROUP BY month_year
ORDER BY month_year;
```

</details>

| **month_year** | **avg_composition** |
| -------------- | ------------------: |
| 7/1/2018       |                6.04 |
| 8/1/2018       |                5.95 |
| 9/1/2018       |                 6.9 |
| 10/1/2018      |                7.07 |
| 11/1/2018      |                6.62 |
| 12/1/2018      |                6.65 |
| 1/1/2019       |                 6.4 |
| 2/1/2019       |                6.58 |
| 3/1/2019       |                6.17 |
| 4/1/2019       |                5.75 |
| 5/1/2019       |                3.54 |
| 6/1/2019       |                2.43 |
| 7/1/2019       |                2.77 |
| 8/1/2019       |                2.63 |

<br>

**Question 04.**

> What is the 3 month rolling average of the max average composition value from September 2018 to August 2019 and include the previous top ranking interests in the same output shown below.

<details>
<summary>Reveal/Hide Solution</summary>

```sql
WITH ranked AS (
	SELECT
		month_year,
		interest_id,
		ROUND((composition/index_value)::NUMERIC, 2) as avg_composition,
		ROW_NUMBER() OVER(PARTITION BY month_year ORDER BY ROUND((composition/index_value)::NUMERIC, 2) DESC) as _rank
	FROM interest_metrics
),

filtered_segments AS (
	SELECT
		r.month_year,
		mp.interest_name,
		r.avg_composition,
		LAG(interest_name, 1) OVER(ORDER BY month_year) as lag_1,
		LAG(avg_composition, 1) OVER(ORDER BY month_year) as lag_1_value,
		LAG(interest_name, 2) OVER(ORDER BY month_year) as lag_2,
		LAG(avg_composition, 2) OVER(ORDER BY month_year) as lag_2_value
	FROM ranked r
	INNER JOIN interest_map mp
		ON r.interest_id = mp.id::VARCHAR
	WHERE _rank = 1
)

SELECT
	month_year,
	interest_name,
	avg_composition,
	ROUND((avg_composition + lag_1_value + lag_2_value) / 3, 2) as rolling_average,
	(lag_1 || ': ' || lag_1_value::text) as one_month_ago,
	(lag_2 || ': ' || lag_2_value::text) as two_month_ago
FROM filtered_segments
WHERE month_year >= '2018-09-01';
```

</details>

| **month_year** | **interest_name**             | **avg_composition** | **rolling_average** | **one_month_ago**                 | **two_month_ago**                 |
| -------------- | ----------------------------- | ------------------: | ------------------: | --------------------------------- | --------------------------------- |
| 9/1/2018       | Work Comes First Travelers    |                8.26 |                7.61 | Las Vegas Trip Planners: 7.21     | Las Vegas Trip Planners: 7.36     |
| 10/1/2018      | Work Comes First Travelers    |                9.14 |                 8.2 | Work Comes First Travelers: 8.26  | Las Vegas Trip Planners: 7.21     |
| 11/1/2018      | Work Comes First Travelers    |                8.28 |                8.56 | Work Comes First Travelers: 9.14  | Work Comes First Travelers: 8.26  |
| 12/1/2018      | Work Comes First Travelers    |                8.31 |                8.58 | Work Comes First Travelers: 8.28  | Work Comes First Travelers: 9.14  |
| 1/1/2019       | Work Comes First Travelers    |                7.66 |                8.08 | Work Comes First Travelers: 8.31  | Work Comes First Travelers: 8.28  |
| 2/1/2019       | Work Comes First Travelers    |                7.66 |                7.88 | Work Comes First Travelers: 7.66  | Work Comes First Travelers: 8.31  |
| 3/1/2019       | Alabama Trip Planners         |                6.54 |                7.29 | Work Comes First Travelers: 7.66  | Work Comes First Travelers: 7.66  |
| 4/1/2019       | Solar Energy Researchers      |                6.28 |                6.83 | Alabama Trip Planners: 6.54       | Work Comes First Travelers: 7.66  |
| 5/1/2019       | Readers of Honduran Content   |                4.41 |                5.74 | Solar Energy Researchers: 6.28    | Alabama Trip Planners: 6.54       |
| 6/1/2019       | Las Vegas Trip Planners       |                2.77 |                4.49 | Readers of Honduran Content: 4.41 | Solar Energy Researchers: 6.28    |
| 7/1/2019       | Las Vegas Trip Planners       |                2.82 |                3.33 | Las Vegas Trip Planners: 2.77     | Readers of Honduran Content: 4.41 |
| 8/1/2019       | Cosmetics and Beauty Shoppers |                2.73 |                2.77 | Las Vegas Trip Planners: 2.82     | Las Vegas Trip Planners: 2.77     |

<br>

**Question 05.**

> Provide a possible reason why the max average composition might change from month to month? Could it signal something is not quite right with the overall business model for Fresh Segments?

<br>

---

[Previous](c-SegmentAnalysis.md)

[Home](../README.md)
