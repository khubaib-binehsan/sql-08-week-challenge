SET search_path = foodie_fi;

-- a-CustomerJourney
-- Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.
-- Try to keep it as short as possible - you may also want to run some sort of join to make your explanations a bit easier!

SELECT
	s.customer_id,
	p.plan_name,
	s.start_date
FROM subscriptions s
INNER JOIN plans p USING (plan_id)
WHERE s.customer_id IN (1,2,11,13,15,16,18,19);
-- some examples:
-- Customer 1 started with free trial on 01-08-2020, and subsequently subscribed to the basic monthly plan on 08-08-2020 after the 7-day free trial period ended.
-- Customer 2 started with free trial on 20-09-2020, and subsequently subscribed to the pro annual plan on 27-09-2020 after the 7-day free trial period ended.
-- Customer 11 started with free trial on 19-11-2020 but did not subscribed to any other plan, thus churned on 26-11-2020 after the 7-day free trial period ended.
-- Customer 15 started with free trial on 17-03-2020, and subsequently subscribed to the pro annula plan on 24-03-2020 after the 7-day free trial period ended. One month later the customer churned on 29-04-2020.

-- b-DataAnalysisQuestions
-- 01. How many customers has Foodie-Fi ever had?

SELECT
	COUNT(DISTINCT customer_id) as customers
FROM subscriptions;

-- 02. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value

SELECT
	DATE_PART('month', start_date) as month_id,
	TO_CHAR(start_date, 'Month') as month_name,
	COUNT(*) as subscriptions
FROM subscriptions
WHERE plan_id = 0
GROUP BY month_id, month_name
ORDER BY month_id;

-- 03. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name

WITH cte AS (
	SELECT
		plan_id,
		COUNT(*) as events
	FROM subscriptions
	WHERE start_date >= '2021-01-01'
	GROUP BY plan_id)

SELECT
	p.plan_name,
	COALESCE(c.events, 0) as events
FROM plans p
LEFT JOIN cte c USING (plan_id);

-- 04. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

WITH cte AS (
	SELECT
		COUNT(DISTINCT customer_id) as total_count,
		SUM(CASE WHEN plan_id = 4 THEN 1 ELSE 0 END) as churned
	FROM subscriptions)
	
SELECT
	churned as customer_count,
	ROUND(100*churned/total_count, 1) as percentage
FROM cte;

-- 05. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?

WITH cte AS (
	SELECT
		customer_id
	FROM subscriptions
	WHERE customer_id IN (SELECT customer_id FROM subscriptions WHERE plan_id = 4)
	GROUP BY customer_id
	HAVING COUNT(*) = 2)

SELECT
	COUNT(customer_id) as customer_count,
	ROUND(100*COUNT(customer_id)/(SELECT COUNT(DISTINCT customer_id) FROM subscriptions), 0) as percentage
FROM cte;

-- 06. What is the number and percentage of customer plans after their initial free trial?

WITH cte_ranked AS (
	SELECT
		*,
		RANK() OVER (PARTITION BY customer_id ORDER BY start_date) as ranked
	FROM subscriptions),

cte_customer_count AS (
	SELECT
		p.plan_name,
		count(*) as customer_count
	FROM cte_ranked c
	INNER JOIN plans p USING (plan_id)
	WHERE ranked < 3
		AND plan_id != 0
	GROUP BY c.plan_id, p.plan_name
	ORDER BY c.plan_id)

SELECT
	plan_name,
	customer_count,
	ROUND(100 * customer_count / (SELECT SUM(customer_count) FROM cte_customer_count), 1) as percentage
FROM cte_customer_count;

-- 07. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?

WITH cte_ranked AS (
	SELECT
		*,
		RANK() OVER (PARTITION BY customer_id ORDER BY start_date DESC) as ranked
	FROM subscriptions
	WHERE start_date <= '2020-12-31'),

cte_customer_count AS (
	SELECT
		p.plan_name,
		count(*) as customer_count
	FROM cte_ranked c
	INNER JOIN plans p USING (plan_id)
	WHERE ranked = 1
	GROUP BY c.plan_id, p.plan_name
	ORDER BY c.plan_id)

SELECT
	plan_name,
	customer_count,
	ROUND(100 * customer_count / (SELECT SUM(customer_count) FROM cte_customer_count), 1) as percentage
FROM cte_customer_count;

-- 08. How many customers have upgraded to an annual plan in 2020?

SELECT
	COUNT(DISTINCT customer_id)
FROM subscriptions
WHERE plan_id = 3
	AND DATE_PART('year', start_date) = 2020
LIMIT 100;

-- 09. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?

WITH cte AS (
	SELECT
		a.customer_id,
		a.start_date as annual_start,
		s.start_date as trial_start,
		a.start_date - s.start_date as days_count
	FROM subscriptions a
	INNER JOIN subscriptions s
		ON s.customer_id = a.customer_id
		AND s.plan_id = 0
	WHERE a.plan_id = 3)

SELECT
	ROUND(AVG(days_count), 0) as avg_days
FROM cte;

-- 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)

WITH cte AS (
	SELECT
		WIDTH_BUCKET(a.start_date - s.start_date, 0 , 360, 12) as bin
	FROM subscriptions a
	INNER JOIN subscriptions s
		ON s.customer_id = a.customer_id
		AND s.plan_id = 0
	WHERE a.plan_id = 3)

SELECT
	(CASE WHEN bin = 1 THEN 0 ELSE (bin - 1) * 30 + 1 END) || ' - ' || bin*30 || ' days' as breakdown,
	COUNT(*) as customers
FROM cte
GROUP BY bin
ORDER BY bin;

-- 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?

WITH cte_ranked AS (
	SELECT
		customer_id,
		plan_id,
		LAG(plan_id, 1) OVER(PARTITION BY customer_id ORDER BY start_date) as last_subscription
	FROM subscriptions
	WHERE DATE_PART('year', start_date) = 2020)

SELECT
	COUNT(*) as downgraded
FROM cte_ranked
WHERE plan_id = 1
	AND last_subscription - plan_id = 1;

-- c-ChallengePaymentQuestion
-- 01. The Foodie-Fi team wants you to create a new payments table for the year 2020 that includes amounts paid by each customer in the subscriptions table with the following requirements:
-- monthly payments always occur on the same day of month as the original start_date of any monthly paid plan
-- upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately
-- upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period
-- once a customer churns they will no longer make payments
--only the first 10 rows are shown as output
WITH RECURSIVE base_table AS ( -- base table
	SELECT
		s.*,
		LEAD(s.start_date, 1) OVER(PARTITION BY s.customer_id ORDER BY s.start_date) as next_date,
		p.price as amount
	FROM subscriptions s
	INNER JOIN plans p USING (plan_id)
),

filter_table AS ( -- filter table used for filtering out 'trial' & 'churn'
	SELECT
		customer_id,
		plan_id,
		start_date,
		CASE WHEN next_date IS NULL OR next_date > '2020-12-31' THEN '2020-12-31' ELSE next_date END as next_date,
		amount
	FROM base_table
	WHERE plan_id NOT IN (0, 4)),

filter_table_mod AS ( -- adds new column "next_date1" which is 1 month before the next date
	SELECT
		customer_id, plan_id, start_date, next_date,
		(next_date - INTERVAL '1 Month')::DATE as next_date1,
		amount
	FROM filter_table),
	
date_population AS ( -- recursive query to generate payment dates for each customer
	SELECT -- non-recursive part
		customer_id, plan_id, start_date, next_date, next_date1,
		(select start_date FROM filter_table_mod WHERE customer_id = a.customer_id AND plan_id = a.plan_id LIMIT 1) as payment_date,
		amount
	FROM filter_table_mod a
	
	UNION
	
	SELECT -- recursive part
		customer_id, plan_id, start_date, next_date, next_date1,
		(payment_date + INTERVAL '1 Month')::DATE as payment_date,
		amount
	FROM date_population b
	WHERE payment_date < next_date1 and plan_id != 3 -- condition that terminates the recursion
)

SELECT
	customer_id,
	plan_id,
	plan_name,
	payment_date,
	amount,
	ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY payment_date) as payment_order
FROM date_population
INNER JOIN plans USING (plan_id)
ORDER BY customer_id, payment_order;

-- d-OutsideTheBoxQuestions
-- The following are open ended questions which might be asked during a technical interview for this case study - there are no right or wrong answers, but answers that make sense from both a technical and a business perspective make an amazing impression!

-- 01. How would you calculate the rate of growth for Foodie-Fi?
-- 02. What key metrics would you recommend Foodie-Fi management to track over time to assess performance of their overall business?
-- 03. What are some key customer journeys or experiences that you would analyse further to improve customer retention?
-- 04. If the Foodie-Fi team were to create an exit survey shown to customers who wish to cancel their subscription, what questions would you include in the survey?
-- 05. What business levers could the Foodie-Fi team use to reduce the customer churn rate? How would you validate the effectiveness of your ideas?