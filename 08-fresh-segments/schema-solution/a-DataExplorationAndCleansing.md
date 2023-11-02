# **Data Exploration and Cleansing**

```sql
-- PostgreSQL 15

SET search_path = fresh_segments;
```

**Question 01.**

> Update the fresh_segments.interest_metrics table by modifying the month_year column to be a date data type with the start of the month

<details>
<summary>Reveal/Hide Solution</summary>

```sql
ALTER TABLE interest_metrics
ALTER month_year SET DATA TYPE DATE
USING TO_DATE(month_year, 'MM-YYYY');
```

</details>

| **\_month** | **\_year** | **month_year** | **interest_id** | **composition** | **index_value** | **ranking** | **percentile_ranking** |
| ----------- | ---------- | -------------- | --------------- | --------------: | --------------: | ----------: | ---------------------: |
| 7           | 2019       | 7/1/2019       | 4925            |            2.02 |            1.21 |         818 |                   5.32 |
| 4           | 2019       | 4/1/2019       | 38              |             3.9 |            2.45 |          14 |                  98.73 |
| 11          | 2018       | 11/1/2018      | 5934            |            2.83 |            1.39 |         468 |                  49.57 |
| 1           | 2019       | 1/1/2019       | 38363           |            2.68 |            1.24 |         531 |                  45.43 |
| 10          | 2018       | 10/1/2018      | 10284           |            4.39 |            1.64 |         215 |                  74.91 |

<br>

**Question 02.**

> What is count of records in the fresh_segments.interest_metrics for each month_year value sorted in chronological order (earliest to latest) with the null values appearing first?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
SELECT
	month_year,
	COUNT(*)
FROM interest_metrics
GROUP BY month_year
ORDER BY month_year NULLS FIRST;
```

</details>

| **month_year** | **count** |
| -------------- | --------: |
|                |      1194 |
| 7/1/2018       |       729 |
| 8/1/2018       |       767 |
| 9/1/2018       |       780 |
| 10/1/2018      |       857 |
| 11/1/2018      |       928 |
| 12/1/2018      |       995 |
| 1/1/2019       |       973 |
| 2/1/2019       |      1121 |
| 3/1/2019       |      1136 |
| 4/1/2019       |      1099 |
| 5/1/2019       |       857 |
| 6/1/2019       |       824 |
| 7/1/2019       |       864 |
| 8/1/2019       |      1149 |

<br>

**Question 03.**

> What do you think we should do with these null values in the fresh_segments.interest_metrics

Without interest_id, there is no point of having index_value, ranking and composition so we will drop these values, but before dropping we will see whether there are any remaining null values in other columns.

We see that month_year also has some null values, so what we will do, is we filter out all the rows which do not have data either for interest_id or month_year column, because without both of these we cannot perform our analysis.

<details>
<summary>Reveal/Hide Solution</summary>

```sql
DELETE FROM interest_metrics
WHERE interest_id IS NULL OR month_year IS NULL;
```

</details>

<br>

**Question 04.**

> How many interest_id values exist in the fresh_segments.interest_metrics table but not in the fresh_segments.interest_map table? What about the other way around?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
WITH metrics AS (SELECT DISTINCT interest_id::NUMERIC FROM interest_metrics),
maps AS (SELECT DISTINCT id::NUMERIC FROM interest_map)

SELECT
	COUNT(metrics.interest_id) as metrics_count,
	COUNT(maps.id) as maps_count,
	SUM(CASE WHEN maps.id IS NULL THEN 1 ELSE NULL END) as not_in_map,
	SUM(CASE WHEN metrics.interest_id IS NULL THEN 1 ELSE NULL END) as not_in_metrics
FROM metrics
FULL OUTER JOIN maps
	ON maps.id = metrics.interest_id;
```

</details>

| **metrics_count** | **maps_count** | **not_in_map** | **not_in_metrics** |
| ----------------: | -------------: | -------------: | -----------------: |
|              1202 |           1209 |              1 |                  8 |

<br>

**Question 05.**

> Summarise the id values in the fresh_segments.interest_map by its total record count in this table

<details>
<summary>Reveal/Hide Solution</summary>

```sql
SELECT
	mp.id,
	mp.interest_name,
	COUNT(*) as total
FROM interest_metrics mt
LEFT JOIN interest_map mp
	ON mp.id::NUMERIC = mt.interest_id::NUMERIC
GROUP BY mp.id, mp.interest_name
ORDER BY total DESC, mp.id;
```

</details>

| **id** | **interest_name**         | **total** |
| -----: | ------------------------- | --------: |
|        |                           |      1193 |
|      4 | Luxury Retail Researchers |        14 |
|      5 | Brides & Wedding Planners |        14 |
|      6 | Vacation Planners         |        14 |
|     12 | Thrift Store Shoppers     |        14 |
|     15 | NBA Fans                  |        14 |
|     16 | NCAA Fans                 |        14 |
|     17 | MLB Fans                  |        14 |
|     18 | Nascar Fans               |        14 |
|     20 | Moviegoers                |        14 |

<br>

**Question 06.**

> What sort of table join should we perform for our analysis and why? Check your logic by checking the rows where interest_id = 21246 in your joined output and include all columns from fresh_segments.interest_metrics and all columns from fresh_segments.interest_map except from the id column.

We should be performing an inner join using the metrics.interest_id and map.id columns, but while joining the keys should be type casted to have the same data type since id is integer while interest_id is varchar.

<details>
<summary>Reveal/Hide Solution</summary>

```sql
SELECT
	mt.*,
	mp.interest_name,
	mp.interest_summary,
	mp.created_at,
	mp.last_modified
FROM interest_metrics mt
INNER JOIN interest_map mp
ON mp.id::VARCHAR= mt.interest_id
WHERE mt.interest_id = '21246';
```

</details>

| **\_month** | **\_year** | **month_year** | **interest_id** | **composition** | **index_value** | **ranking** | **percentile_ranking** | **interest_name**                | **interest_summary**                     | **created_at**  | **last_modified** |
| ----------- | ---------- | -------------- | --------------- | --------------: | --------------: | ----------: | ---------------------: | -------------------------------- | ---------------------------------------- | --------------- | ----------------- |
| 7           | 2018       | 7/1/2018       | 21246           |            2.26 |            0.65 |         722 |                   0.96 | Readers of El Salvadoran Content | People reading news from El Salvadoran m | 6/11/2018 17:50 | 6/11/2018 17:50   |
| 8           | 2018       | 8/1/2018       | 21246           |            2.13 |            0.59 |         765 |                   0.26 | Readers of El Salvadoran Content | People reading news from El Salvadoran m | 6/11/2018 17:50 | 6/11/2018 17:50   |
| 9           | 2018       | 9/1/2018       | 21246           |            2.06 |            0.61 |         774 |                   0.77 | Readers of El Salvadoran Content | People reading news from El Salvadoran m | 6/11/2018 17:50 | 6/11/2018 17:50   |
| 10          | 2018       | 10/1/2018      | 21246           |            1.74 |            0.58 |         855 |                   0.23 | Readers of El Salvadoran Content | People reading news from El Salvadoran m | 6/11/2018 17:50 | 6/11/2018 17:50   |
| 11          | 2018       | 11/1/2018      | 21246           |            2.25 |            0.78 |         908 |                   2.16 | Readers of El Salvadoran Content | People reading news from El Salvadoran m | 6/11/2018 17:50 | 6/11/2018 17:50   |
| 12          | 2018       | 12/1/2018      | 21246           |            1.97 |             0.7 |         983 |                   1.21 | Readers of El Salvadoran Content | People reading news from El Salvadoran m | 6/11/2018 17:50 | 6/11/2018 17:50   |
| 1           | 2019       | 1/1/2019       | 21246           |            2.05 |            0.76 |         954 |                   1.95 | Readers of El Salvadoran Content | People reading news from El Salvadoran m | 6/11/2018 17:50 | 6/11/2018 17:50   |
| 2           | 2019       | 2/1/2019       | 21246           |            1.84 |            0.68 |        1109 |                   1.07 | Readers of El Salvadoran Content | People reading news from El Salvadoran m | 6/11/2018 17:50 | 6/11/2018 17:50   |
| 3           | 2019       | 3/1/2019       | 21246           |            1.75 |            0.67 |        1123 |                   1.14 | Readers of El Salvadoran Content | People reading news from El Salvadoran m | 6/11/2018 17:50 | 6/11/2018 17:50   |
| 4           | 2019       | 4/1/2019       | 21246           |            1.58 |            0.63 |        1092 |                   0.64 | Readers of El Salvadoran Content | People reading news from El Salvadoran m | 6/11/2018 17:50 | 6/11/2018 17:50   |

<br>

**Question 07.**

> Are there any records in your joined table where the month_year value is before the created_at value from the fresh_segments.interest_map table? Do you think these values are valid and why?

There are 188 rows of data where the month_year is before the created_at timestamp. But that is not an issue in our case since the interest_map table is only a descriptive table telling us about the nature of interest_id we are analysing. It doesn't matter whether the id was generated before or after the observation.

<details>
<summary>Reveal/Hide Solution</summary>

```sql
SELECT
	mt.*,
	mp.interest_name,
	mp.interest_summary,
	mp.created_at,
	mp.last_modified
FROM interest_metrics mt
INNER JOIN interest_map mp
ON mp.id::VARCHAR= mt.interest_id
WHERE mt.month_year::TIMESTAMP < mp.created_at::TIMESTAMP;
```

</details>

| **\_month** | **\_year** | **month_year** | **interest_id** | **composition** | **index_value** | **ranking** | **percentile_ranking** | **interest_name**              | **interest_summary**                     | **created_at**  | **last_modified** |
| ----------- | ---------- | -------------- | --------------- | --------------: | --------------: | ----------: | ---------------------: | ------------------------------ | ---------------------------------------- | --------------- | ----------------- |
| 9           | 2018       | 9/1/2018       | 35903           |            5.23 |            2.14 |          26 |                  96.67 | Trendy Denim Shoppers          | Customers shopping for denim from trends | 9/5/2018 18:10  | 9/5/2018 18:10    |
| 12          | 2018       | 12/1/2018      | 41547           |            3.07 |            1.43 |         472 |                  52.56 | Electronics Shoppers           | Consumers shopping for electronics produ | 12/3/2018 11:10 | 12/3/2018 11:10   |
| 7           | 2018       | 7/1/2018       | 32701           |            4.23 |            1.41 |         483 |                  33.74 | Womens Equality Advocates      | People visiting sites advocating for wom | 7/6/2018 14:35  | 7/6/2018 14:35    |
| 7           | 2018       | 7/1/2018       | 32702           |            3.56 |            1.18 |         580 |                  20.44 | Romantics                      | People reading about romance and researc | 7/6/2018 14:35  | 7/6/2018 14:35    |
| 7           | 2018       | 7/1/2018       | 32703           |            5.53 |             1.8 |         375 |                  48.56 | School Supply Shoppers         | Consumers shopping for classroom supplie | 7/6/2018 14:35  | 7/6/2018 14:35    |
| 7           | 2018       | 7/1/2018       | 32704           |            8.04 |            2.27 |         225 |                  69.14 | Major Airline Customers        | People visiting sites for major airline  | 7/6/2018 14:35  | 7/6/2018 14:35    |
| 7           | 2018       | 7/1/2018       | 32705           |            4.38 |            1.34 |         505 |                  30.73 | Certified Events Professionals | Professionals reading industry news and  | 7/6/2018 14:35  | 7/6/2018 14:35    |
| 7           | 2018       | 7/1/2018       | 33191           |            3.99 |            2.11 |         283 |                  61.18 | Online Shoppers                | People who spend money online            | 7/17/2018 10:40 | 7/17/2018 10:46   |
| 8           | 2018       | 8/1/2018       | 33957           |            2.01 |            0.84 |         704 |                   8.21 | Call of Duty Enthusiasts       | People reading news and product releases | 8/2/2018 16:05  | 8/2/2018 16:05    |
| 8           | 2018       | 8/1/2018       | 33958           |            1.88 |            0.73 |         740 |                   3.52 | Astrology Enthusiasts          | People reading daily horoscopes and astr | 8/2/2018 16:05  | 8/2/2018 16:05    |

<br>

---

[Next](b-InterestAnalysis.md)

[Home](..\README.md)
