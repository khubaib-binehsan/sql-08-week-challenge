# **Case Study #8 - Fresh Segments**

## **Introduction:**

Danny created Fresh Segments, a digital marketing agency that helps other businesses analyse trends in online ad click behaviour for their unique customer base. Clients share their customer lists with the Fresh Segments team who then aggregate interest metrics and generate a single dataset worth of metrics for further analysis. In particular - the composition and rankings for different interests are provided for each client showing the proportion of their customer list who interacted with online assets related to each interest for each month.

Danny has asked for your assistance to analyse aggregated metrics for an example client and provide some high level insights about the customer list and their interests.

## **Data:**

The dataset consists of two table namely 'interest_metrics' & 'interest_map' with the following relationship:

<img src="images\fresh-segments-db-diagram.png">

<br>

Below are snippets for each of the table:

### interest_metrics

| **\_month** | **\_year** | **month_year** | **interest_id** | **composition** | **index_value** | **ranking** | **percentile_ranking** |
| ----------- | ---------- | -------------- | --------------- | --------------: | --------------: | ----------: | ---------------------: |
| 4           | 2019       | 04-2019        | 4912            |            3.19 |            1.67 |         158 |                  85.62 |
| 9           | 2018       | 09-2018        | 6144            |            4.53 |            1.99 |          41 |                  94.74 |
| 4           | 2019       | 04-2019        | 6206            |            5.38 |            2.55 |          11 |                     99 |
| 8           | 2019       | 08-2019        | 93              |            2.36 |             1.5 |         787 |                  31.51 |
|             |            |                |                 |            4.64 |            2.22 |         205 |                  82.83 |

<br>

### interest_map

| **id** | **interest_name**                   | **interest_summary**                                      | **created_at**  | **last_modified** |
| -----: | ----------------------------------- | --------------------------------------------------------- | --------------- | ----------------- |
|  45523 | Welding Tools and Supplies Shoppers | Consumers shopping for welding tools and supplies.        | 2/4/2019 22:00  | 2/6/2019 16:21    |
|   4929 | Right Wing Radicals                 | The Oathkeepers movement.                                 | 9/7/2016 16:12  | 5/23/2018 11:30   |
|  21292 | Smart Home Product Researchers      | Consumers comparing and shopping for smart home products. | 6/12/2018 11:45 | 6/12/2018 11:45   |
|  44460 | Military Benefits Researchers       | People researching military benefits                      | 1/28/2019 9:00  | 1/28/2019 9:00    |
|   6378 | Luggage Shoppers                    | Consumers in-market for new luggage.                      | 5/31/2017 16:26 | 5/23/2018 11:30   |

<br>

## **Solutions:**

[Data Exploration and Cleansing](./schema-solution/a-DataExplorationAndCleansing.md)

[Interest Analysis](./schema-solution/b-InterestAnalysis.md)

[Segment Analysis](./schema-solution/c-SegmentAnalysis.md)

[Index Analysis](./schema-solution/d-IndexAnalysis.md)
