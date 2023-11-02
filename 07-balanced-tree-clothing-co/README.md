# **Balanced Tree Clothing Co.**

## **Introduction:**

Balanced Tree Clothing Company prides themselves on providing an optimised range of clothing and lifestyle wear for the modern adventurer!

Danny, the CEO of this trendy fashion company has asked you to assist the team’s merchandising teams analyse their sales performance and generate a basic financial report to share with the wider business.

## **Data:**

The dataset consists of four tables namely 'product_hierarchy', 'product_prices', 'product_details' & 'sales' with the following relationship:

<img src="images\balanced-tree-db-diagram.png">

<br>

Below are snippets for each of the table:

### **product_hierarchy**

| **id** | **parent_id** | **level_text**      | **level_name** |
| -----: | ------------: | ------------------- | -------------- |
|      8 |             3 | Black Straight      | Style          |
|     18 |             6 | Pink Fluro Polkadot | Style          |
|     17 |             6 | White Striped       | Style          |
|      6 |             2 | Socks               | Segment        |
|      4 |             1 | Jacket              | Segment        |

<br>

### **product_prices**

| **id** | **product_id** | **price** |
| -----: | -------------- | --------: |
|     13 | 5d267b         |        40 |
|      9 | e31d39         |        10 |
|     11 | 72f5d4         |        19 |
|     17 | b9a74d         |        17 |
|     14 | c8d436         |        10 |

<br>

### **product_details**

| **product_id** | **price** | **product_name**                 | **category_id** | **segment_id** | **style_id** | **category_name** | **segment_name** | **style_name**      |
| -------------- | --------: | -------------------------------- | --------------: | -------------: | -----------: | ----------------- | ---------------- | ------------------- |
| 9ec847         |        54 | Grey Fashion Jacket - Womens     |               1 |              4 |           12 | Womens            | Jacket           | Grey Fashion        |
| e83aa3         |        32 | Black Straight Jeans - Womens    |               1 |              3 |            8 | Womens            | Jeans            | Black Straight      |
| c4a632         |        13 | Navy Oversized Jeans - Womens    |               1 |              3 |            7 | Womens            | Jeans            | Navy Oversized      |
| 2feb6b         |        29 | Pink Fluro Polkadot Socks - Mens |               2 |              6 |           18 | Mens              | Socks            | Pink Fluro Polkadot |
| 72f5d4         |        19 | Indigo Rain Jacket - Womens      |               1 |              4 |           11 | Womens            | Jacket           | Indigo Rain         |

<br>

### **sales**

| **prod_id** | **qty** | **price** | **discount** | **member** | **txn_id** | **start_txn_time** |
| ----------- | ------: | --------: | -----------: | ---------- | ---------- | ------------------ |
| 72f5d4      |       3 |        19 |            5 | TRUE       | 213c69     | 15:50.6            |
| b9a74d      |       3 |        17 |            4 | FALSE      | f16705     | 06:25.7            |
| 72f5d4      |       4 |        19 |            9 | TRUE       | 7a9c4c     | 09:26.8            |
| 2a2353      |       5 |        57 |           20 | FALSE      | 40217      | 44:41.0            |
| f084eb      |       2 |        36 |           13 | TRUE       | a6210b     | 21:54.1            |

<br>

## **Solutions:**

[High Level Sales Analysis](./schema-solution/a-HighLevelSalesAnalysis.md)

[Transaction Analysis](./schema-solution/b-TransactionAnalysis.md)

[Product Analysis](./schema-solution/c-ProductAnalysis.md)

[Reporting Challenge](./schema-solution/d-ReportingChallenge.md)

[Bonus Challenge](./schema-solution/e-BonusChallenge.md)
