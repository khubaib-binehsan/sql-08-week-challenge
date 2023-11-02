# **Case Study #6 - Clique Bait**

## **Introduction:**

Clique Bait is not like your regular online seafood store - the founder and CEO Danny, was also a part of a digital data analytics team and wanted to expand his knowledge into the seafood industry!

In this case study - you are required to support Danny’s vision and analyse his dataset and come up with creative solutions to calculate funnel fallout rates for the Clique Bait online store.

## **Data:**

The dataset consists of five tables namely 'users', 'event_identifier', 'events', 'page_hierarchy' & 'campaign_identifier' with the following relationship:

<img title="db-diagram" alt="Entity Relationship Diagram"  src="images\clique-bait-db-diagram.png">

<br>

Below are snippets for each of the table:

### **users**

| **user_id** | **cookie_id** | **start_date**  |
| ----------: | ------------- | --------------- |
|          13 | c39c27        | 29/02/2020 0:00 |
|         252 | 5900f6        | 30/01/2020 0:00 |
|         490 | 34cc8e        | 13/02/2020 0:00 |
|         429 | 0bb40c        | 28/01/2020 0:00 |
|          49 | ed7099        | 08/02/2020 0:00 |
|          73 | 9.27E+07      | 17/03/2020 0:00 |
|         216 | d0acc5        | 29/02/2020 0:00 |
|         199 | f7dc81        | 03/04/2020 0:00 |
|         275 | 1c6b65        | 29/01/2020 0:00 |
|          72 | 6b93e2        | 03/02/2020 0:00 |

<br>

### **event_identifier**

| **event_type** | **event_name** |
| -------------: | -------------- |
|              1 | Page View      |
|              2 | Add to Cart    |
|              3 | Purchase       |
|              4 | Ad Impression  |
|              5 | Ad Click       |

<br>

### **events**

| **visit_id** | **cookie_id** | **page_id** | **event_type** | **sequence_number** | **event_time** |
| ------------ | ------------- | ----------: | -------------: | ------------------: | -------------- |
| 71740f       | b6d767        |           8 |              1 |                   9 | 34:24.0        |
| 3ff02e       | 827828        |           6 |              2 |                   8 | 18:32.7        |
| 1869be       | b1a59b        |           9 |              2 |                   9 | 52:33.1        |
| 05ddf7       | 631d53        |           7 |              1 |                  12 | 57:24.5        |
| ed9843       | 1a8379        |          11 |              1 |                  19 | 38:30.0        |
| 331b7d       | f4f6dc        |           9 |              1 |                  14 | 54:02.2        |
| 7b1d35       | 9394d9        |          11 |              2 |                  16 | 37:11.7        |
| 1ec8cf       | 2b18cf        |           1 |              1 |                   1 | 51:51.3        |
| 4.56E+15     | 525c96        |           4 |              1 |                   6 | 44:44.4        |
| 69aa1c       | 9b70e8        |           4 |              1 |                   4 | 55:05.7        |

<br>

### **page_hierarchy**

| **page_id** | **page_name**  | **product_category** | **product_id** |
| ----------: | -------------- | -------------------- | -------------: |
|           1 | Home Page      |                      |                |
|           2 | All Products   |                      |                |
|           3 | Salmon         | Fish                 |              1 |
|           4 | Kingfish       | Fish                 |              2 |
|           5 | Tuna           | Fish                 |              3 |
|           6 | Russian Caviar | Luxury               |              4 |
|           7 | Black Truffle  | Luxury               |              5 |
|           8 | Abalone        | Shellfish            |              6 |
|           9 | Lobster        | Shellfish            |              7 |
|          10 | Crab           | Shellfish            |              8 |

<br>

### **campaign_identifier**

| **campaign_id** | **products** | **campaign_name**                 | **start_date**  | **end_date**    |
| --------------: | ------------ | --------------------------------- | --------------- | --------------- |
|               1 | 1-3          | BOGOF - Fishing For Compliments   | 01/01/2020 0:00 | 14/01/2020 0:00 |
|               2 | 4-5          | 25% Off - Living The Lux Life     | 15/01/2020 0:00 | 28/01/2020 0:00 |
|               3 | 6-8          | Half Off - Treat Your Shellf(ish) | 01/02/2020 0:00 | 31/03/2020 0:00 |

<br>

## **Solutions:**

[Enterprise Relationship Diagram](./schema-solution/a-EnterpriseRelationshipDiagram.md)

[Digital Analysis](./schema-solution/b-DigitalAnalysis.md)

[Product Funnel Analysis](./schema-solution/c-ProductFunnelAnalysis.md)

[Campaign Analysis](./schema-solution/d-CampaignAnalysis.md)
