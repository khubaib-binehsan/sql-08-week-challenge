# **Ingredient Optimisation**

```sql
-- PostgreSQL 15

SET search_path = pizza_runner;

-- Use (if any) temp table created in "a-PizzaMetrics" file.
```

**Question 01.**

> What are the standard ingredients for each pizza?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
SELECT
	pizza_name,
	ARRAY_TO_STRING(array_agg(topping_name), ',') as toppings
FROM PIZZA_RECIPES_CLEAN
INNER JOIN pizza_names USING (pizza_id)
INNER JOIN pizza_toppings USING (topping_id)
GROUP BY pizza_name;
```

</details>

| **pizza_name** | **toppings**                                                   |
| -------------- | -------------------------------------------------------------- |
| Meatlovers     | BBQ Sauce,Pepperoni,Cheese,Salami,Chicken,Bacon,Mushrooms,Beef |
| Vegetarian     | Tomato Sauce,Cheese,Mushrooms,Onions,Peppers,Tomatoes          |

<br>

**Question 02.**

> What was the most commonly added extra?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
WITH cte AS (
	SELECT
		UNNEST(STRING_TO_ARRAY(extras, ', '))::NUMERIC as topping_id
	FROM CUSTOMER_ORDERS_CLEAN
	WHERE extras IS NOT null
)

SELECT
	topping_name,
	COUNT(*) as times_added
FROM cte c
INNER JOIN pizza_toppings USING (topping_id)
GROUP BY topping_name
ORDER BY times_added DESC
LIMIT 1;
```

</details>

| **topping_name** | **times_added** |
| ---------------- | --------------: |
| Bacon            |               4 |

<br>

**Question 03.**

> What was the most common exclusion?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
WITH cte AS (
	SELECT
		UNNEST(STRING_TO_ARRAY(exclusions, ', '))::NUMERIC as topping_id
	FROM CUSTOMER_ORDERS_CLEAN
	WHERE exclusions IS NOT null
)

SELECT
	topping_name,
	COUNT(*) as times_excluded
FROM cte c
INNER JOIN pizza_toppings USING (topping_id)
GROUP BY topping_name
ORDER BY times_excluded DESC
LIMIT 1;
```

</details>

| **topping_name** | **times_excluded** |
| ---------------- | -----------------: |
| Cheese           |                  4 |

<br>

**Question 04.**

> Generate an order item for each record in the customers_orders table in the format of one of the following:
>
> - Meat Lovers
>
> - Meat Lovers - Exclude Beef
>
> - Meat Lovers - Extra Bacon
>
> - Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

<details>
<summary>Reveal/Hide Solution</summary>

```sql
WITH cleaned_ranked AS (
	SELECT
		ROW_NUMBER() OVER(ORDER BY pizza_id) as _id,
		order_id,
		pizza_id,
		COALESCE(exclusions, '0') as exclusions,
		COALESCE(extras , '0') as extras
	FROM CUSTOMER_ORDERS_CLEAN
),

table_unnested AS (
	SELECT
		_id,
		order_id,
		pizza_id,
		UNNEST(STRING_TO_ARRAY(exclusions, ', '))::NUMERIC as exclusions,
		UNNEST(STRING_TO_ARRAY(extras, ', '))::NUMERIC as extras
	FROM cleaned_ranked
),

aggregated_table AS (
	SELECT
		_id,
		order_id,
		pizza_name,
		ARRAY_TO_STRING(ARRAY_AGG(t.topping_name), ', ') as exclusions,
		ARRAY_TO_STRING(ARRAY_AGG(t2.topping_name), ', ') as extras
	FROM table_unnested un
	LEFT JOIN pizza_toppings t
		ON t.topping_id = un.exclusions
	LEFT JOIN pizza_toppings t2
		ON t2.topping_id = un.extras
	LEFT JOIN pizza_names USING (pizza_id)
	GROUP BY _id, order_id, pizza_name
)

SELECT
	order_id,
	CONCAT(pizza_name,
		   CASE WHEN LENGTH(exclusions) > 1 THEN ' - Exclude ' ELSE '' END,
		   exclusions,
		   CASE WHEN LENGTH(extras) > 1 THEN ' - Extra ' ELSE '' END,
		   extras) as _order
FROM aggregated_table
ORDER BY order_id;
```

</details>

| **order_id** | **\_order**                                                     |
| -----------: | --------------------------------------------------------------- |
|            1 | Meatlovers                                                      |
|            2 | Meatlovers                                                      |
|            3 | Meatlovers                                                      |
|            3 | Vegetarian                                                      |
|            4 | Vegetarian - Exclude Cheese                                     |
|            4 | Meatlovers - Exclude Cheese                                     |
|            4 | Meatlovers - Exclude Cheese                                     |
|            5 | Meatlovers - Extra Bacon                                        |
|            6 | Vegetarian                                                      |
|            7 | Vegetarian - Extra Bacon                                        |
|            8 | Meatlovers                                                      |
|            9 | Meatlovers - Exclude Cheese - Extra Bacon, Chicken              |
|           10 | Meatlovers - Exclude BBQ Sauce, Mushrooms - Extra Bacon, Cheese |
|           10 | Meatlovers                                                      |

<br>

**Question 05.**

> Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
>
> - For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"

<details>
<summary>Reveal/Hide Solution</summary>

```sql
WITH exclusions_table AS (
	SELECT
		_id,
		UNNEST(STRING_TO_ARRAY(exclusions, ', '))::NUMERIC as topping_id
	FROM CUSTOMER_ORDERS_CLEAN
	WHERE exclusions IS NOT NULL
),

extras_table AS (
	SELECT
		_id,
		UNNEST(STRING_TO_ARRAY(extras, ', '))::NUMERIC as topping_id
	FROM CUSTOMER_ORDERS_CLEAN
	WHERE extras IS NOT NULL
),

recipe_with_extras AS (
	SELECT
		_id,
		c.pizza_id,
		UNNEST(STRING_TO_ARRAY(CONCAT(p.toppings,
			   CASE WHEN c.extras IS NULL THEN '' ELSE ', ' END,
			   c.extras), ', '))::NUMERIC as topping_id
	FROM CUSTOMER_ORDERS_CLEAN c
	INNER JOIN RUNNER_ORDERS_CLEAN r
		ON r.order_id = c.order_id
	INNER JOIN pizza_recipes p USING (pizza_id)
),

recipe_summary AS (
	SELECT
		_id, pizza_id,
		(CASE
			WHEN topping_id IN (SELECT topping_id FROM extras_table e WHERE r._id = e._id)
			THEN CONCAT('2x', t.topping_name)
			ELSE topping_name END) as toppings
	FROM recipe_with_extras r
	INNER JOIN pizza_toppings t USING (topping_id)
	WHERE r.topping_id NOT IN (SELECT topping_id FROM exclusions_table e WHERE r._id = e._id)
),

recipe_cte AS (
	SELECT
		_id,
		pizza_id,
		ARRAY_TO_STRING(ARRAY_AGG(toppings), ', ') as _order_
	FROM recipe_summary
	GROUP BY _id, pizza_id
)

SELECT
	c.order_id,
	CONCAT(n.pizza_name,': ', _order_) as _order
FROM recipe_cte r
INNER JOIN CUSTOMER_ORDERS_CLEAN c USING (_id)
INNER JOIN pizza_names n
	ON r.pizza_id = n.pizza_id
ORDER BY order_id;
```

</details>

| **order_id** | **\_order**                                                                                       |
| -----------: | ------------------------------------------------------------------------------------------------- |
|            1 | Meatlovers: BBQ Sauce, Beef, Cheese, Chicken, Bacon, Mushrooms, Pepperoni, Salami                 |
|            2 | Meatlovers: Chicken, Bacon, BBQ Sauce, Beef, Cheese, Mushrooms, Pepperoni, Salami                 |
|            3 | Meatlovers: Beef, Chicken, Bacon, Mushrooms, Pepperoni, Salami, BBQ Sauce, Cheese                 |
|            3 | Vegetarian: Peppers, Onions, Mushrooms, Tomatoes, Tomato Sauce, Cheese                            |
|            4 | Meatlovers: Pepperoni, Chicken, Beef, BBQ Sauce, Bacon, Salami, Mushrooms                         |
|            4 | Meatlovers: Beef, Salami, Pepperoni, Mushrooms, Chicken, BBQ Sauce, Bacon                         |
|            4 | Vegetarian: Mushrooms, Onions, Peppers, Tomatoes, Tomato Sauce                                    |
|            5 | Meatlovers: Pepperoni, 2xBacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Salami, 2xBacon      |
|            6 | Vegetarian: Mushrooms, Onions, Tomato Sauce, Tomatoes, Peppers, Cheese                            |
|            7 | Vegetarian: Tomatoes, Peppers, Onions, Cheese, Mushrooms, 2xBacon, Tomato Sauce                   |
|            8 | Meatlovers: Pepperoni, Salami, Bacon, BBQ Sauce, Beef, Cheese, Mushrooms, Chicken                 |
|            9 | Meatlovers: 2xChicken, 2xBacon, Salami, Pepperoni, Mushrooms, 2xChicken, Beef, BBQ Sauce, 2xBacon |
|           10 | Meatlovers: Bacon, Salami, Pepperoni, Mushrooms, Chicken, Cheese, Beef, BBQ Sauce                 |
|           10 | Meatlovers: 2xBacon, 2xCheese, Beef, 2xCheese, 2xBacon, Chicken, Pepperoni, Salami                |

<br>

**Question 06.**

> What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
WITH cte_mergedIngredients AS (
	SELECT
			CONCAT(p.toppings,
				   CASE WHEN c.extras IS NULL THEN '' ELSE ', ' END,
				   c.extras,
				   CASE WHEN c.exclusions IS NULL THEN '' ELSE ', ' END,
				   c.exclusions) as ingredients
	FROM CUSTOMER_ORDERS_CLEAN c
	INNER JOIN RUNNER_ORDERS_CLEAN r
		ON r.order_id = c.order_id
		AND r.cancellation IS NULL
	LEFT JOIN pizza_recipes p
		ON p.pizza_id = c.pizza_id),

cte_unnested AS (
	SELECT
		UNNEST(STRING_TO_ARRAY(ingredients, ', '))::NUMERIC as ingredient
	FROM cte_mergedIngredients
)

SELECT
	t.topping_name as ingredient_name,
	COUNT(*) as times_used
FROM cte_unnested i
LEFT JOIN pizza_toppings t
	ON t.topping_id = i.ingredient
GROUP BY t.topping_name
ORDER BY times_used DESC;
```

</details>

| **ingredient_name** | **times_used** |
| ------------------- | -------------: |
| Cheese              |             16 |
| Mushrooms           |             13 |
| Bacon               |             12 |
| BBQ Sauce           |             10 |
| Pepperoni           |              9 |
| Chicken             |              9 |
| Salami              |              9 |
| Beef                |              9 |
| Tomato Sauce        |              3 |
| Onions              |              3 |
| Tomatoes            |              3 |
| Peppers             |              3 |

<br>

---

[Previous](b-RunnerAndCustomerExperience.md) | [Next](d-PricingAndRatings.md)

[Home](../README.md)
