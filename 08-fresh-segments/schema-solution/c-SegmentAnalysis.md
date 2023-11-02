# **Segment Analysis**

```sql
-- PostgreSQL 15

SET search_path = fresh_segments;
```

**Question 01.**

> Using our filtered dataset by removing the interests with less than 6 months worth of data, which are the top 10 and bottom 10 interests which have the largest composition values in any month_year? Only use the maximum composition value for each interest but you must keep the corresponding month_year

<details>
<summary>Reveal/Hide Solution</summary>

```sql
WITH id_filter AS (
	SELECT
		interest_id
	FROM interest_metrics
	GROUP BY interest_id
	HAVING COUNT(DISTINCT month_year) >= 6
),

filtered_data AS (
	SELECT
		mt.*
	FROM interest_metrics mt
	INNER JOIN id_filter id
		ON mt.interest_id = id.interest_id
),

ranked_data AS (
	SELECT
		*,
		RANK() OVER(PARTITION BY interest_id ORDER BY composition DESC) as _top,
		RANK() OVER(PARTITION BY interest_id ORDER BY composition) as _bottom
	FROM filtered_data
)

(SELECT interest_id, month_year, composition FROM ranked_data WHERE _top = 1 ORDER BY composition DESC LIMIT 10)
UNION
(SELECT interest_id, month_year, composition FROM ranked_data WHERE _bottom = 1 ORDER BY composition LIMIT 10)
ORDER BY composition DESC;
```

</details>

| **interest_id** | **month_year** | **composition** |
| --------------- | -------------- | --------------: |
| 21057           | 12/1/2018      |            21.2 |
| 6284            | 7/1/2018       |           18.82 |
| 39              | 7/1/2018       |           17.44 |
| 77              | 7/1/2018       |           17.19 |
| 12133           | 10/1/2018      |           15.15 |
| 5969            | 12/1/2018      |           15.05 |
| 171             | 7/1/2018       |           14.91 |
| 4898            | 7/1/2018       |           14.23 |
| 6286            | 7/1/2018       |            14.1 |
| 4               | 7/1/2018       |           13.97 |
| 6314            | 6/1/2019       |            1.53 |
| 36877           | 5/1/2019       |            1.53 |
| 6127            | 5/1/2019       |            1.53 |
| 35742           | 6/1/2019       |            1.52 |
| 4918            | 5/1/2019       |            1.52 |
| 44449           | 4/1/2019       |            1.52 |
| 34083           | 6/1/2019       |            1.52 |

<br>

**Question 02.**

> Which 5 interests had the lowest average ranking value?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
SELECT
	interest_id,
	ROUND(AVG(ranking), 2) as avg_ranking
FROM interest_metrics
GROUP BY interest_id
ORDER BY avg_ranking
LIMIT 5;
```

</details>

| **interest_id** | **avg_ranking** |
| --------------- | --------------: |
| 41548           |               1 |
| 42203           |            4.11 |
| 115             |            5.93 |
| 48154           |             7.8 |
| 171             |            9.36 |

<br>

**Question 03.**

> Which 5 interests had the largest standard deviation in their percentile_ranking value?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
SELECT
	interest_id,
	ROUND(STDDEV(percentile_ranking)::NUMERIC, 2) as standard_deviation
FROM interest_metrics
GROUP BY interest_id
ORDER BY standard_deviation DESC NULLS LAST
LIMIT 5;
```

</details>

| **interest_id** | **standard_deviation** |
| --------------- | ---------------------: |
| 6260            |                  41.27 |
| 131             |                  30.72 |
| 150             |                  30.36 |
| 23              |                  30.18 |
| 20764           |                  28.97 |

<br>

**Question 04.**

> For the 5 interests found in the previous question - what was minimum and maximum percentile_ranking values for each interest and its corresponding year_month value? Can you describe what is happening for these 5 interests?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
DROP TABLE IF EXISTS segments;
CREATE TEMP TABLE segments AS
WITH id_filter AS (
	SELECT
		interest_id,
		ROUND(STDDEV(percentile_ranking)::NUMERIC, 2) as standard_deviation
	FROM interest_metrics
	GROUP BY interest_id
	ORDER BY standard_deviation DESC NULLS LAST
	LIMIT 5
),

ranked AS (
	SELECT
		f.*,
		mt.month_year,
		mt.percentile_ranking,
		ROW_NUMBER() OVER(PARTITION BY interest_id ORDER BY mt.percentile_ranking) as _bottom,
		ROW_NUMBER() OVER(PARTITION BY interest_id ORDER BY mt.percentile_ranking DESC) as _top
	FROM interest_metrics mt
	INNER JOIN id_filter f USING (interest_id)
)

(SELECT
	interest_id, standard_deviation,
	'min' as min_max,
	month_year, percentile_ranking
FROM ranked
WHERE _bottom = 1)

UNION

(SELECT
	interest_id, standard_deviation,
	'max' as min_max,
	month_year, percentile_ranking
FROM ranked
WHERE _top = 1)

ORDER BY percentile_ranking DESC;

SELECT * FROM segments;
```

</details>

| **interest_id** | **standard_deviation** | **min_max** | **month_year** | **percentile_ranking** |
| --------------- | ---------------------: | ----------- | -------------- | ---------------------: |
| 150             |                  30.36 | max         | 7/1/2018       |                  93.28 |
| 23              |                  30.18 | max         | 7/1/2018       |                  86.69 |
| 20764           |                  28.97 | max         | 7/1/2018       |                  86.15 |
| 131             |                  30.72 | max         | 7/1/2018       |                  75.03 |
| 6260            |                  41.27 | max         | 7/1/2018       |                  60.63 |
| 20764           |                  28.97 | min         | 8/1/2019       |                  11.23 |
| 150             |                  30.36 | min         | 8/1/2019       |                  10.01 |
| 23              |                  30.18 | min         | 8/1/2019       |                   7.92 |
| 131             |                  30.72 | min         | 3/1/2019       |                   4.84 |
| 6260            |                  41.27 | min         | 8/1/2019       |                   2.26 |

<br>

**Question 05.**

> How would you describe our customers in this segment based off their composition and ranking values? What sort of products or services should we show to these customers and what should we avoid?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
SELECT
	mp.interest_name,
	s.standard_deviation,
	s.min_max,
	s.month_year,
	s.percentile_ranking,
	mt.composition,
	mt.ranking
FROM segments s
INNER JOIN interest_metrics mt
	ON mt.interest_id = s.interest_id
	AND mt.month_year = s.month_year
INNER JOIN interest_map mp
	ON mp.id::VARCHAR = s.interest_id;
```

</details>

| **interest_name**                      | **standard_deviation** | **min_max** | **month_year** | **percentile_ranking** | **composition** | **ranking** |
| -------------------------------------- | ---------------------: | ----------: | -------------: | ---------------------: | --------------: | ----------: |
| Techies                                |                  30.18 |         min |       8/1/2019 |                   7.92 |             1.9 |        1058 |
| Techies                                |                  30.18 |         max |       7/1/2018 |                  86.69 |            5.41 |          97 |
| Android Fans                           |                  30.72 |         min |       3/1/2019 |                   4.84 |            1.72 |        1081 |
| Android Fans                           |                  30.72 |         max |       7/1/2018 |                  75.03 |            5.09 |         182 |
| TV Junkies                             |                  30.36 |         min |       8/1/2019 |                  10.01 |            1.94 |        1034 |
| TV Junkies                             |                  30.36 |         max |       7/1/2018 |                  93.28 |             5.3 |          49 |
| Blockbuster Movie Fans                 |                  41.27 |         min |       8/1/2019 |                   2.26 |            1.83 |        1123 |
| Blockbuster Movie Fans                 |                  41.27 |         max |       7/1/2018 |                  60.63 |            5.27 |         287 |
| Entertainment Industry Decision Makers |                  28.97 |         min |       8/1/2019 |                  11.23 |            1.91 |        1020 |
| Entertainment Industry Decision Makers |                  28.97 |         max |       7/1/2018 |                  86.15 |            5.85 |         101 |

<br>

---

[Previous](b-InterestAnalysis.md) | [Next](d-IndexAnalysis.md)

[Home](../README.md)
