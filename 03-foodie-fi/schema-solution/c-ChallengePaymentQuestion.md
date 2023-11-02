# **Challenge Payment Question**

```sql
-- PostgreSQL 15

SET search_path = foodie_fi;
```

> The Foodie-Fi team wants you to create a new payments table for the year 2020 that includes amounts paid by each customer in the subscriptions table with the following requirements:
>
> - monthly payments always occur on the same day of month as the original start_date of any monthly paid plan
>
> - upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately
>
> - upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period
>
> - once a customer churns they will no longer make payments

Only the first 10 rows are shown as output

<details>
<summary>Reveal/Hide Solution</summary>

```sql
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
```

</details>

| **customer_id** | **plan_id** | **plan_name** | **payment_date** | **amount** | **payment_order** |
| --------------: | ----------: | ------------- | ---------------- | ---------: | ----------------: |
|               1 |           1 | basic monthly | 08/08/2020       |        9.9 |                 1 |
|               1 |           1 | basic monthly | 08/09/2020       |        9.9 |                 2 |
|               1 |           1 | basic monthly | 08/10/2020       |        9.9 |                 3 |
|               1 |           1 | basic monthly | 08/11/2020       |        9.9 |                 4 |
|               1 |           1 | basic monthly | 08/12/2020       |        9.9 |                 5 |
|               2 |           3 | pro annual    | 27/09/2020       |        199 |                 1 |
|               3 |           1 | basic monthly | 20/01/2020       |        9.9 |                 1 |
|               3 |           1 | basic monthly | 20/02/2020       |        9.9 |                 2 |
|               3 |           1 | basic monthly | 20/03/2020       |        9.9 |                 3 |
|               3 |           1 | basic monthly | 20/04/2020       |        9.9 |                 4 |

<br>

---

[Previous](b-DataAnalysisQuestions.md) | [Next](d-OutsideTheBoxQuestions.md)

[Home](../README.md)
