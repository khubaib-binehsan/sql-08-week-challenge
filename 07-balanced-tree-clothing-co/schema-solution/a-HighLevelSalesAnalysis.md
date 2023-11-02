# **High Level Sales Analysis**

```sql
-- PostgreSQL 15

SET search_path = balanced_tree;
```

**Question 01.**

> What was the total quantity sold for all products?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
SELECT
	SUM(qty) as qty_sold
FROM sales;
```

</details>

| **qty_sold** |
| -----------: |
|        45216 |

<br>

**Question 02.**

> What is the total generated revenue for all products before discounts?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
SELECT
	SUM(qty * price) as revenue
FROM sales;
```

</details>

| **revenue** |
| ----------: |
|     1289453 |

<br>

**Question 03.**

> What was the total discount amount for all products?

<details>
<summary>Reveal/Hide Solution</summary>

```sql
SELECT
	SUM(qty * price * discount / 100) as discount
FROM sales;
```

</details>

| **discount** |
| -----------: |
|       149486 |

<br>

---

[Next](b-TransactionAnalysis.md)

[Home](../README.md)
