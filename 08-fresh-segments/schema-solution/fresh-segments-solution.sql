SET search_path = fresh_segments;

-- a-DataExplorationAndCleansing
-- 01. Update the fresh_segments.interest_metrics table by modifying the month_year column to be a date data type with the start of the month

ALTER TABLE interest_metrics
ALTER month_year SET DATA TYPE DATE
USING TO_DATE(month_year, 'MM-YYYY');

-- 02. What is count of records in the fresh_segments.interest_metrics for each month_year value sorted in chronological order (earliest to latest) with the null values appearing first?

SELECT
	month_year,
	COUNT(*)
FROM interest_metrics
GROUP BY month_year
ORDER BY month_year NULLS FIRST;

-- 03. What do you think we should do with these null values in the fresh_segments.interest_metrics

-- depends on how the data is being stored
-- without interest_id, there is no point of having index_value, ranking and composition so we will drop these values, but before dropping we will see whether there are any remaining null values in other columns.
-- we see that month_year also has some null values, so what we will do, is we filter out all the rows which do not have data either for interest_id or month_year column, because without both of these we cannot perform our analysis.

DELETE FROM interest_metrics
WHERE interest_id IS NULL OR month_year IS NULL;

-- 04. How many interest_id values exist in the fresh_segments.interest_metrics table but not in the fresh_segments.interest_map table? What about the other way around?

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

-- 05. Summarise the id values in the fresh_segments.interest_map by its total record count in this table

SELECT
	mp.id,
	mp.interest_name,
	COUNT(*) as total
FROM interest_metrics mt
LEFT JOIN interest_map mp
	ON mp.id::NUMERIC = mt.interest_id::NUMERIC
GROUP BY mp.id, mp.interest_name
ORDER BY total DESC, mp.id;

-- 06. What sort of table join should we perform for our analysis and why? Check your logic by checking the rows where interest_id = 21246 in your joined output and include all columns from fresh_segments.interest_metrics and all columns from fresh_segments.interest_map except from the id column.

-- we should be performing an inner join using the metrics.interest_id and map.id columns, but while joining the keys should be type casted to have the same data type since id is integer while interest_id is varchar.
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

-- 07. Are there any records in your joined table where the month_year value is before the created_at value from the fresh_segments.interest_map table? Do you think these values are valid and why?

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

-- there are 188 rows of data where the month_year is before the created_at timestamp. But that is not an issue in our case since the interest_map table is only a descriptive table telling us about the nature of interest_id we are analysing. It doesn't matter whether the id was generated before or after the observation.

-- b-InterestAnalysis
-- 01. Which interests have been present in all month_year dates in our dataset?

SELECT
	interest_id::NUMERIC
FROM interest_metrics
GROUP BY interest_id
HAVING COUNT(DISTINCT month_year) = (SELECT COUNT(DISTINCT month_year) FROM interest_metrics)
ORDER BY interest_id;

-- 02. Using this same total_months measure - calculate the cumulative percentage of all records starting at 14 months - which total_months value passes the 90% cumulative percentage value?

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

-- another solution for the same answer

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

-- 03. If we were to remove all interest_id values which are lower than the total_months value we found in the previous question - how many total data points would we be removing?

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

-- 04. Does this decision make sense to remove these data points from a business perspective? Use an example where there are all 14 months present to a removed interest example for your arguments - think about what it means to have less months present from a segment perspective.
-- 05. After removing these interests - how many unique interests are there for each month?

-- c-SegmentAnalysis
-- 01. Using our filtered dataset by removing the interests with less than 6 months worth of data, which are the top 10 and bottom 10 interests which have the largest composition values in any month_year? Only use the maximum composition value for each interest but you must keep the corresponding month_year

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

-- 02. Which 5 interests had the lowest average ranking value?

SELECT
	interest_id,
	ROUND(AVG(ranking), 2) as avg_ranking
FROM interest_metrics
GROUP BY interest_id
ORDER BY avg_ranking
LIMIT 5;

-- 03. Which 5 interests had the largest standard deviation in their percentile_ranking value?

SELECT
	interest_id,
	ROUND(STDDEV(percentile_ranking)::NUMERIC, 2) as standard_deviation
FROM interest_metrics
GROUP BY interest_id
ORDER BY standard_deviation DESC NULLS LAST
LIMIT 5;

-- 04. For the 5 interests found in the previous question - what was minimum and maximum percentile_ranking values for each interest and its corresponding year_month value? Can you describe what is happening for these 5 interests?

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

-- 05. How would you describe our customers in this segment based off their composition and ranking values? What sort of products or services should we show to these customers and what should we avoid?

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

-- d-IndexAnalysis
-- 01. What is the top 10 interests by the average composition for each month?

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

-- 02. For all of these top 10 interests - which interest appears the most often?

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

-- 03. What is the average of the average composition for the top 10 interests for each month?

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

-- 04. What is the 3 month rolling average of the max average composition value from September 2018 to August 2019 and include the previous top ranking interests in the same output shown below.

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

-- 05. Provide a possible reason why the max average composition might change from month to month? Could it signal something is not quite right with the overall business model for Fresh Segments?