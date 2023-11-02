# **Bonus Questions**

```sql
-- PostgreSQl 15

SET search_path = dannys_diner;
```

### **Join All The Things**

> The following questions are related creating basic data tables that Danny and his team can use to quickly derive insights without needing to join the underlying tables using SQL.
>
> Recreate the table with the following columns:
>
> - customer_id
> - order_date
> - product_name
> - price
> - member ('Y' if the customer is a member at that point in time else 'N')

### **Rank All The Things**

> Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for non-member purchases so he expects null ranking values for the records when customers are not yet part of the loyalty program.

<details>
<summary>Reveal/Hide Solution</summary>

```sql
-- Since the second question requires just anohter column for the table in previous question, I'll merge both into one single query.
WITH joined_data AS (
	SELECT
		s.customer_id,
		s.order_date,
		m.product_name,
		m.price,
		(CASE WHEN mb.join_date <= s.order_date THEN 'Y' ELSE 'N' END) as member,
		ROW_NUMBER() OVER() as _row
	FROM sales s
	INNER JOIN menu m USING (product_id)
	LEFT JOIN members mb USING (customer_id)
),

rankings AS (
	SELECT
		_row,
		RANK() OVER(PARTITION BY customer_id ORDER BY order_date) as ranking
	FROM joined_data
	WHERE member = 'Y'
)

SELECT
	customer_id,
	order_date,
	product_name,
	price,
	member,
	ranking
FROM joined_data
LEFT JOIN rankings USING (_row)
ORDER BY customer_id, order_date;
-- The above solution can be saved to a temporary table using a simple CREATE TEMP TABLE query.
```

</details>

| **customer_id** | **order_date** | **product_name** | **price** | **member** | **ranking** |
| --------------- | -------------- | ---------------- | --------: | ---------- | ----------: |
| A               | 01/01/2021     | sushi            |        10 | N          |             |
| A               | 01/01/2021     | curry            |        15 | N          |             |
| A               | 07/01/2021     | curry            |        15 | Y          |           1 |
| A               | 10/01/2021     | ramen            |        12 | Y          |           2 |
| A               | 11/01/2021     | ramen            |        12 | Y          |           3 |
| A               | 11/01/2021     | ramen            |        12 | Y          |           3 |
| B               | 01/01/2021     | curry            |        15 | N          |             |
| B               | 02/01/2021     | curry            |        15 | N          |             |
| B               | 04/01/2021     | sushi            |        10 | N          |             |
| B               | 11/01/2021     | sushi            |        10 | Y          |           1 |
| B               | 16/01/2021     | ramen            |        12 | Y          |           2 |
| B               | 01/02/2021     | ramen            |        12 | Y          |           3 |
| C               | 01/01/2021     | ramen            |        12 | N          |             |
| C               | 01/01/2021     | ramen            |        12 | N          |             |
| C               | 07/01/2021     | ramen            |        12 | N          |             |

<br>

---

[Previous](./a-CaseStudyQuestions.md)

[Home](../README.md)
