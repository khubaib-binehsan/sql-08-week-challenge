# **Interest Analysis**

```sql
-- PostgreSQL 15

SET search_path = fresh_segments;
```

**Question 01.**

> Which interests have been present in all month_year dates in our dataset?

There are a total of 480 rows but only 5 are being shown in the output.

<details>
<summary>Reveal/Hide Solution</summary>

```sql
SELECT
	interest_id::NUMERIC
FROM interest_metrics
GROUP BY interest_id
HAVING COUNT(DISTINCT month_year) = (SELECT COUNT(DISTINCT month_year) FROM interest_metrics)
ORDER BY interest_id;
```

</details>

| **interest_id** |
| --------------: |
|               4 |
|               5 |
|               6 |
|              12 |
|              15 |

<br>

**Question 02.**

> Using this same total_months measure - calculate the cumulative percentage of all records starting at 14 months - which total_months value passes the 90% cumulative percentage value?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
WITH cte AS (
	SELECT
		interest_id,
		COUNT(DISTINCT month_year) as total_months
	FROM interest_metrics
	GROUP BY interest_id
),

month_agg AS (
	SELECT
		total_months,
		COUNT(*) as id_counts
	FROM cte
	GROUP BY total_months
	ORDER BY total_months DESC
)

SELECT
	*,
	ROUND(100 * (SUM(id_counts) OVER(ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)) / (SELECT SUM(id_counts) FROM month_agg), 2) as cum_pct
FROM month_agg;
```

Another solution for the same answer

```sql
WITH cte AS (
	SELECT
		interest_id,
		COUNT(DISTINCT month_year) as total_months
	FROM interest_metrics
	GROUP BY interest_id
)

SELECT
	PERCENTILE_DISC(0.90) WITHIN GROUP (ORDER BY total_months DESC) as total_months
FROM cte;
```

</details>

| **total_months** | **id_counts** | **cum_pct** |
| ---------------: | ------------: | ----------: |
|               14 |           480 |       39.93 |
|               13 |            82 |       46.76 |
|               12 |            65 |       52.16 |
|               11 |            94 |       59.98 |
|               10 |            86 |       67.14 |
|                9 |            95 |       75.04 |
|                8 |            67 |       80.62 |
|                7 |            90 |        88.1 |
|                6 |            33 |       90.85 |
|                5 |            38 |       94.01 |
|                4 |            32 |       96.67 |
|                3 |            15 |       97.92 |
|                2 |            12 |       98.92 |
|                1 |            13 |         100 |

<br>

**Question 03.**

> If we were to remove all interest_id values which are lower than the total_months value we found in the previous question - how many total data points would we be removing?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
WITH cte AS (
	SELECT
		interest_id
	FROM interest_metrics
	GROUP BY interest_id
	HAVING COUNT(DISTINCT month_year) < 6
)

SELECT
	COUNT(*)
FROM interest_metrics mt
INNER JOIN cte c USING (interest_id);
```

</details>

| **count** |
| --------: |
|       400 |

<br>

**Question 04.**

> Does this decision make sense to remove these data points from a business perspective? Use an example where there are all 14 months present to a removed interest example for your arguments - think about what it means to have less months present from a segment perspective.

**Question 05.**

> After removing these interests - how many unique interests are there for each month?

[Previous](a-DataExplorationAndCleansing.md) | [Next](c-SegmentAnalysis.md)

[Home](../README.md)
