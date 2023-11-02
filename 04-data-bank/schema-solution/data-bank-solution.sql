SET search_path = data_bank;

-- a-CustomerNodesExploration
-- 01. How many unique nodes are there on the Data Bank system?

SELECT
	COUNT(DISTINCT node_id) as node_count
FROM customer_nodes;

-- 02. What is the number of nodes per region?

SELECT
	region_name,
	COUNT(DISTINCT node_id) as node_count
FROM customer_nodes
INNER JOIN regions USING (region_id)
GROUP BY region_name;

-- 03. How many customers are allocated to each region?

SELECT
	region_name,
	COUNT(DISTINCT customer_id) as customer_count
FROM customer_nodes
INNER JOIN regions USING (region_id)
GROUP BY region_name;

-- 04. How many days on average are customers reallocated to a different node?

WITH cte AS (
SELECT
	customer_id,
	node_id,
	end_date - start_date as difference
FROM customer_nodes
WHERE end_date != '9999-12-31')
	
SELECT
	ROUND(AVG(difference), 0) as avg_days_to_relocate
FROM cte;

-- 05. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?

WITH cte AS (
	SELECT
		region_id,
		customer_id,
		node_id,
		end_date - start_date as difference
	FROM customer_nodes
	WHERE end_date != '9999-12-31')
	
SELECT
	region_name,
	PERCENTILE_DISC(0.50) WITHIN GROUP (ORDER BY difference) as median,
	PERCENTILE_DISC(0.80) WITHIN GROUP (ORDER BY difference) as percentile_80,
	PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY difference) as percentile_95
FROM cte
INNER JOIN regions USING (region_id)
GROUP BY region_name;


-- b-CustomerTransactions
-- 01. What is the unique count and total amount for each transaction type?

SELECT
	txn_type,
	COUNT(*) as txn_count,
	SUM(txn_amount) as txn_amount
FROM customer_transactions
GROUP BY txn_type;

-- 02. What is the average total historical deposit counts and amounts for all customers?

WITH customer_agg AS (
	SELECT
		customer_id,
		COUNT(*) as txn_count,
		AVG(txn_amount) as txn_amount
	FROM customer_transactions
	WHERE txn_type = 'deposit'
	GROUP BY customer_id
)

SELECT
	ROUND(AVG(txn_count), 0) as avg_count,
	ROUND(AVG(txn_amount), 0) as avg_amount
FROM customer_agg;

-- 03. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?

WITH aggregated_data AS (
	SELECT
		EXTRACT('month' from txn_date) as month_id,
		TO_CHAR(txn_date, 'Month') as month_name,
		customer_id,
		SUM(CASE WHEN txn_type = 'deposit' THEN 1 ELSE 0 END) as deposit_count,
		SUM(CASE WHEN txn_type = 'purchase' THEN 1 ELSE 0 END) as purchase_count,
		SUM(CASE WHEN txn_type = 'withdrawl' THEN 1 ELSE 0 END) as withdrawl_count
	FROM customer_transactions
	GROUP BY month_id, month_name, customer_id
	ORDER BY month_id, customer_id)

SELECT
	month_name,
	SUM(CASE WHEN
	(deposit_count > 1) AND (purchase_count >= 1 OR withdrawl_count >= 1) 
	THEN 1 ELSE 0 END) as customer_count
FROM aggregated_data
GROUP BY month_id, month_name
ORDER BY month_id;

-- 04. What is the closing balance for each customer at the end of the month?

DROP TABLE IF EXISTS closing_balance;
CREATE TEMP TABLE closing_balance AS
WITH RECURSIVE aggregated_data AS (
	SELECT
		customer_id,
		(DATE_TRUNC('month', txn_date) + INTERVAL '1 MONTH - 1 DAY')::DATE as month_end,
		SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE -txn_amount END) as activity
	FROM customer_transactions
	GROUP BY month_end, customer_id
	ORDER BY customer_id, month_end),
	
aggregated_data0 AS ( -- added next_month column
	SELECT
		*,
		LEAD(month_end, 1) OVER(PARTITION BY customer_id) as next_month
	FROM aggregated_data
),

date_population AS ( -- recursive query
	SELECT	-- non-recursive part
		*
	FROM aggregated_data0
	
	UNION ALL
	
	SELECT	-- recursive part
		customer_id,
		(DATE_TRUNC('month', month_end + INTERVAL '1 MONTH') + INTERVAL '1 MONTH - 1 DAY')::DATE,
		0 as activity,
		next_month
	FROM date_population
	where month_end < '2020-04-30'
		AND EXTRACT('month' FROM month_end) < COALESCE(EXTRACT('month' FROM next_month) - 1, 12)
)

SELECT
	customer_id,
	month_end,
	SUM(activity) OVER(PARTITION BY customer_id ORDER BY month_end) as closing_balance
FROM date_population
ORDER BY customer_id, month_end;

SELECT * FROM closing_balance LIMIT 12;

-- 05. What is the percentage of customers who increase their closing balance by more than 5%?

WITH rows_cte AS (
	SELECT
		*,
		ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY month_end) as row_id
	FROM closing_balance
),

lag_values AS (
	SELECT
		*,
		LAG(closing_balance, 1) OVER(PARTITION BY customer_id ORDER BY month_end) as initial_balance
	FROM rows_cte
	WHERE row_id IN (1, 4)),

percent_change_calc AS (
	SELECT
		customer_id,
		ROUND(100*((closing_balance/initial_balance) - 1), 0) as pct_change
	FROM lag_values
	WHERE row_id = 4
),

total_customers AS (
	SELECT COUNT(DISTINCT customer_id) as total FROM customer_transactions
),

pct_customers AS (
	SELECT
		COUNT(*) as total
	FROM percent_change_calc
	WHERE pct_change > 5)

SELECT
	ROUND(100*p.total / t.total, 0) as percentage
FROM pct_customers p, total_customers t;

-- c-DataAllocationChallenge
-- To test out a few different hypotheses - the Data Bank team wants to run an experiment where different groups of customers would be allocated data using 3 different options:
-- Option 1: data is allocated based off the amount of money at the end of the previous month
-- Option 2: data is allocated on the average amount of money kept in the account in the previous 30 days
-- Option 3: data is updated real-time

-- For this multi-part challenge question - you have been requested to generate the following data elements to help the Data Bank team estimate how much data will need to be provisioned for each option:
-- : running customer balance column that includes the impact each transaction
-- : customer balance at the end of each month
-- : minimum, average and maximum values of the running balance for each customer
-- Using all of the data available - how much data would have been required for each option on a monthly basis?

-- Temporary TABLE: running balance

DROP TABLE IF EXISTS running_balance;
CREATE TEMP TABLE running_balance AS
SELECT
	*,
	SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE -txn_amount END) OVER(PARTITION BY customer_id ORDER BY txn_date) as balance
FROM customer_transactions
ORDER BY customer_id, txn_date;

-- Temporary TABLE: min, avg, max (customer_stats)
DROP TABLE IF EXISTS customer_stats;
CREATE TEMP TABLE customer_stats AS
WITH cte AS (
	SELECT
		*,
		SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE -txn_amount END) OVER(PARTITION BY customer_id ORDER BY txn_date) as balance
	FROM customer_transactions),
	
cte_ranked AS (
	SELECT
		customer_id,
		txn_date,
		balance,
		ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY balance) as minimum,
		ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY balance DESC) as maximum
	FROM cte)

SELECT
	customer_id,
	MIN(balance)::INTEGER as min_balance,
	MAX(balance)::INTEGER as max_balance,
	ROUND(AVG(balance), 0)::INTEGER as avg_balance
FROM cte_ranked
GROUP BY customer_id
ORDER BY customer_id;

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

-- d-ExtraChallenge
-- Data Bank wants to try another option which is a bit more difficult to implement - they want to calculate data growth using an interest calculation, just like in a traditional savings account you might have with a bank.
-- If the annual interest rate is set at 6% and the Data Bank team wants to reward its customers by increasing their data allocation based off the interest calculated on a daily basis at the end of each day, how much data would be required for this option on a monthly basis?
-- Special notes:
-- : Data Bank wants an initial calculation which does not allow for compounding interest, however they may also be interested in a daily compounding interest calculation so you can try to perform this calculation if you have the stamina!

-- e-ExtensionRequest
-- The Data Bank team wants you to use the outputs generated from the above sections to create a quick Powerpoint presentation which will be used as marketing materials for both external investors who might want to buy Data Bank shares and new prospective customers who might want to bank with Data Bank.
-- 01. Using the outputs generated from the customer node questions, generate a few headline insights which Data Bank might use to market it’s world-leading security features to potential investors and customers.
-- 02. With the transaction analysis - prepare a 1 page presentation slide which contains all the relevant information about the various options for the data provisioning so the Data Bank management team can make an informed decision.