# **Case Study #1 - Danny's Diner**

## **Introduction:**

Danny seriously loves Japanese food so in the beginning of 2021, he decides to embark upon a risky venture and opens up a cute little restaurant that sells his 3 favourite foods: sushi, curry and ramen. Danny’s Diner is in need of your assistance to help the restaurant stay afloat - the restaurant has captured some very basic data from their few months of operation but have no idea how to use their data to help them run the business.

Danny wants to use the data to answer a few simple questions about his customers, especially about their visiting patterns, how much money they’ve spent and also which menu items are their favourite. Having this deeper connection with his customers will help him deliver a better and more personalised experience for his loyal customers. He plans on using these insights to help him decide whether he should expand the existing customer loyalty program - additionally he needs help to generate some basic datasets so his team can easily inspect the data without needing to use SQL.

## **Data:**

The data consists of three tables, named 'menu', 'sales' & 'members' with the following relationship.

<img title="" alt="" src="images\danny-diner-db-diagram.png">

<br>

Below are snippets for each of the table:

### **menu**

| **product_id** | **product_name** | **price** |
| -------------: | ---------------- | --------: |
|              1 | sushi            |        10 |
|              2 | curry            |        15 |
|              3 | ramen            |        12 |

<br>

### **sales**

| **customer_id** | **order_date** | **product_id** |
| --------------- | -------------- | -------------: |
| A               | 01/01/2021     |              1 |
| A               | 01/01/2021     |              2 |
| A               | 07/01/2021     |              2 |
| A               | 10/01/2021     |              3 |
| A               | 11/01/2021     |              3 |

<br>

### **members**

| **customer_id** | **join_date** |
| --------------- | ------------- |
| A               | 07/01/2021    |
| B               | 09/01/2021    |

<br>

## **Solutions:**

[Case Study Questions](schema-solution/a-CaseStudyQuestions.md)

[Bonus Question](schema-solution/b-BonusQuestions.md)
