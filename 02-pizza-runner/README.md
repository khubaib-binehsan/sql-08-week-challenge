# **Case Study #2 - Pizza Runner**

## **Introduction:**

Did you know that over 115 million kilograms of pizza is consumed daily worldwide??? (Well according to Wikipedia anyway…)

Danny was scrolling through his Instagram feed when something really caught his eye - “80s Retro Styling and Pizza Is The Future!” Danny was sold on the idea, but he knew that pizza alone was not going to help him get seed funding to expand his new Pizza Empire - so he had one more genius idea to combine with it - he was going to Uberize it - and so Pizza Runner was launched!

Danny started by recruiting “runners” to deliver fresh pizza from Pizza Runner Headquarters (otherwise known as Danny’s house) and also maxed out his credit card to pay freelance developers to build a mobile app to accept orders from customers.

He has prepared for us an entity relationship diagram of his database design but requires further assistance to clean his data and apply some basic calculations so he can better direct his runners and optimise Pizza Runner’s operations.

## **Data:**

The dataset consists of six tables namely 'customer_orders', 'runner_orders', 'runners', 'pizza_names', 'pizza_recipes' & 'pizza_toppings' with the following relationship:

<img title="" alt="" src="images\pizza-runner-db-diagram.png">

<br>

Below are snippets for each of the table:

### **customer_orders**

| **order_id** | **customer_id** | **pizza_id** | **exclusions** | **extras** | **order_time**   |
| -----------: | --------------: | -----------: | -------------- | ---------- | ---------------- |
|            1 |             101 |            1 |                |            | 01/01/2020 18:05 |
|            2 |             101 |            1 |                |            | 01/01/2020 19:00 |
|            3 |             102 |            1 |                |            | 02/01/2020 23:51 |
|            3 |             102 |            2 |                |            | 02/01/2020 23:51 |
|            4 |             103 |            1 | 4              |            | 04/01/2020 13:23 |

<br>

### **runner_orders**

| **order_id** | **runner_id** | **pickup_time**  | **distance** | **duration** | **cancellation** |
| -----------: | ------------: | ---------------- | ------------ | ------------ | ---------------- |
|            1 |             1 | 01/01/2020 18:15 | 20km         | 32 minutes   |                  |
|            2 |             1 | 01/01/2020 19:10 | 20km         | 27 minutes   |                  |
|            3 |             1 | 03/01/2020 0:12  | 13.4km       | 20 mins      |                  |
|            4 |             2 | 04/01/2020 13:53 | 23.4         | 40           |                  |
|            5 |             3 | 08/01/2020 21:10 | 10           | 15           |                  |

<br>

### **runners**

| **runner_id** | **registration_date** |
| ------------: | --------------------- |
|             1 | 01/01/2021            |
|             2 | 03/01/2021            |
|             3 | 08/01/2021            |
|             4 | 15/01/2021            |

<br>

### **pizza_names**

| **pizza_id** | **pizza_name** |
| -----------: | -------------- |
|            1 | Meatlovers     |
|            2 | Vegetarian     |

<br>

### **pizza_recipes**

| **pizza_id** | **toppings**            |
| -----------: | ----------------------- |
|            1 | 1, 2, 3, 4, 5, 6, 8, 10 |
|            2 | 4, 6, 7, 9, 11, 12      |

<br>

### **pizza_toppings**

| **topping_id** | **topping_name** |
| -------------: | ---------------- |
|              1 | Bacon            |
|              2 | BBQ Sauce        |
|              3 | Beef             |
|              4 | Cheese           |
|              5 | Chicken          |

<br>

## **Solutions:**

[Pizza Metrics](./schema-solution/a-PizzaMetrics.md)

[Runner and Customer Experience](./schema-solution/b-RunnerAndCustomerExperience.md)

[Ingredient Optimisation](./schema-solution/c-IngredientOptimisation.md)

[Pricing and Ratings](./schema-solution/d-PricingAndRatings.md)

[Bonus Question](./schema-solution/e-BonusQuestion.md)
