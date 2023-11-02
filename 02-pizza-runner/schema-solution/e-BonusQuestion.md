# **Bonus Question**

```sql
-- PostgreSQL 15

SET search_path = pizza_runner;

-- Use (if any) temp table created in "a-PizzaMetrics" file.
```

> If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?

We only need to update two tables i.e., pizza_names and pizza_recipes for this change.

<details>
<summary>Reveal/Hide Solution</summary>

```sql
INSERT INTO pizza_names
	("pizza_id", "pizza_name")
VALUES
	(3, 'Supreme Pizza');

INSERT INTO pizza_recipes
	("pizza_id", "toppings")
VALUES
	(3, '1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12');
```

</details>

| **pizza_id** | **pizza_name** |
| -----------: | -------------- |
|            1 | Meatlovers     |
|            2 | Vegetarian     |
|            3 | Supreme Pizza  |

| **pizza_id** | **toppings**                          |
| -----------: | ------------------------------------- |
|            1 | 1, 2, 3, 4, 5, 6, 8, 10               |
|            2 | 4, 6, 7, 9, 11, 12                    |
|            3 | 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 |

<br>

---

[Previous](d-PricingAndRatings.md)

[Home](../README.md)
