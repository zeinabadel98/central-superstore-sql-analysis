# Central Superstore Sales Analysis | SQL

## Project Overview

In this project, I used SQL to analyze sales data from the Central Region of the Superstore dataset.

The main goal was to understand sales performance, identify profitable and unprofitable products, and explore how different categories, customer segments, and discounts affect the business.

I also created a simple data warehouse using a star schema to organize the data and make the analysis easier.

## Tools Used

- SQL Server (SSMS)
- SQL
- Excel (Dataset)

## Dataset

The dataset contains 2,323 records from the Central Region of Superstore.

It includes information about:

- Orders and customers
- Products and categories
- Sales and profits
- Discounts and quantities
- Shipping details
- Locations

## Database Design

I organized the original data into a star schema consisting of one fact table and five dimension tables.

**Fact Table:**
- FactSales

**Dimension Tables:**
- DimCustomer
- DimProduct
- DimLocation
- DimShipMode
- DimDate

The fact table stores the sales transactions and numerical values, while the dimension tables contain the details used for analysis.

## Data Validation

Before analyzing the data, I used SQL queries to check the dataset and compare the results with the fact table.

The checks included:

- Counting the total records
- Counting distinct orders
- Checking for missing values
- Checking for duplicate records
- Comparing total sales and profit

## SQL Analysis

I wrote SQL queries to answer different business questions, such as:

1. Which product categories generate the highest sales and profits?
2. Which products are making losses?
3. How do discounts affect profitability?
4. Which customer segments contribute the most to sales?
5. How does sales performance change over time?
6. Which products perform best based on profit?

During the project, I worked with JOINs, CTEs, aggregate functions, CASE statements, subqueries, and window functions.

I also included views, a stored procedure, and indexes.

## Key Findings

The initial analysis of the Central Region dataset showed:

| Metric | Value |
|---|---:|
| Total Records | 2,323 |
| Total Orders | 1,175 |
| Total Sales | $501,239.89 |
| Total Profit | $39,706.36 |
| Profit Margin | 7.92% |

These results provide an overview of the region's performance.

The next part of the analysis focuses on identifying which products and categories contribute to profits and which areas may need improvement.

## Project Files

- **Central_Superstore_Portfolio_SQL_Revised.sql** — SQL code for the database structure and analysis.
- **README.md** — Project overview and documentation.

## How to Run

1. Open SQL Server Management Studio (SSMS).
2. Create a database named `Centralsuperstore` if it does not already exist.
3. Import the Central Region dataset into a table named `Raw_Superstore`.
4. Open the SQL project file.
5. Run the database creation and analysis queries in the appropriate order.

If the database tables already exist, review the CREATE TABLE statements before running them again.

## What I Learned

This project helped me practice SQL beyond writing basic queries.

I worked on organizing data into fact and dimension tables, checking data quality, and using SQL to answer business questions.

It also helped me understand how database design and data validation support accurate business analysis.
