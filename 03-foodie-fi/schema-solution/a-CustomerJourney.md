# **Customer Journey**

```sql
-- PostgreSQL 15

SET search_path = foodie_fi;
```

> Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.
>
> Try to keep it as short as possible - you may also want to run some sort of join to make your explanations a bit easier!

Customer 1 started with free trial on 01-08-2020, and subsequently subscribed to the basic monthly plan on 08-08-2020 after the 7-day free trial period ended.

Customer 2 started with free trial on 20-09-2020, and subsequently subscribed to the pro annual plan on 27-09-2020 after the 7-day free trial period ended.

Customer 11 started with free trial on 19-11-2020 but did not subscribed to any other plan, thus churned on 26-11-2020 after the 7-day free trial period ended.

Customer 15 started with free trial on 17-03-2020, and subsequently subscribed to the pro annula plan on 24-03-2020 after the 7-day free trial period ended. One month later the customer churned on 29-04-2020.

<details>
<summary>Reveal/Hide Solution</summary>

```sql
SELECT
	s.customer_id,
	p.plan_name,
	s.start_date
FROM subscriptions s
INNER JOIN plans p USING (plan_id)
WHERE s.customer_id IN (1,2,11,13,15,16,18,19);
```

</details>

| **customer_id** | **plan_name** | **start_date** |
| --------------: | ------------- | -------------- |
|               1 | trial         | 01/08/2020     |
|               1 | basic monthly | 08/08/2020     |
|               2 | trial         | 20/09/2020     |
|               2 | pro annual    | 27/09/2020     |
|              11 | trial         | 19/11/2020     |
|              11 | churn         | 26/11/2020     |
|              13 | trial         | 15/12/2020     |
|              13 | basic monthly | 22/12/2020     |
|              13 | pro monthly   | 29/03/2021     |
|              15 | trial         | 17/03/2020     |

<br>

---

[Next](b-DataAnalysisQuestions.md)

[Home](../README.md)
