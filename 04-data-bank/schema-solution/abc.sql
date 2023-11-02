-- C. Data Allocation Challenge
-- To test out a few different hypotheses - the Data Bank team wants to run an experiment where different groups of customers would be allocated data using 3 different options:
-- Option 1: data is allocated based off the amount of money at the end of the previous month
-- Option 2: data is allocated on the average amount of money kept in the account in the previous 30 days
-- Option 3: data is updated real-time
--
-- For this multi-part challenge question - you have been requested to generate the following data elements to help the Data Bank team estimate how much data will need to be provisioned for each option:
-- : running customer balance column that includes the impact each transaction
-- : customer balance at the end of each month
-- : minimum, average and maximum values of the running balance for each customer
-- Using all of the data available - how much data would have been required for each option on a monthly basis?

-- closing_balance, running_balance, customer_stats

-- assuming that for every 1$ of balance, a user is credited 10 units of data, if the closing-balance at the previous month is negative then the allocated data will be zero. In a realistic scenario, what would happen that the customer will have access to data for another month, and if the balance is not

SELECT
	customer_id,
	closing_balance,
	(CASE WHEN closing_balance > 1 THEN 10*closing_balance ELSE NULL END) as alloted_data
FROM closing_balance
WHERE month_end = (SELECT month_end FROM closing_balance ORDER BY month_end DESC LIMIT 1);

WITH cte AS (
	SELECT
		customer_id,
		ROUND(AVG(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE -txn_amount END), 0)::INTEGER as last_30_days
	FROM running_balance
	WHERE txn_date >= ((select txn_date FROM customer_transactions ORDER BY txn_date DESC LIMIT 1) - INTERVAL '30 DAYS')::DATE
	GROUP BY customer_id
	ORDER BY customer_id)

SELECT
	DISTINCT ct.customer_id,
	c.last_30_days,
	(CASE WHEN c.last_30_days > 1 THEN 10*last_30_days ELSE NULL END) as alloted_data
FROM customer_transactions ct
LEFT JOIN cte c USING (customer_id)
ORDER BY ct.customer_id;