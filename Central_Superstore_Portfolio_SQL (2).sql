-- Central Superstore
-- Sales Analysis

USE Centralsuperstore;
GO

-- Check the original data
SELECT COUNT(*) AS SourceRows,
       COUNT(DISTINCT [Order ID]) AS TotalOrders,
       SUM(CAST(Sales AS DECIMAL(19,4))) AS TotalSales,
       SUM(CAST(Profit AS DECIMAL(19,4))) AS TotalProfit
FROM Raw_Superstore;

-- Check missing values
SELECT
    SUM(CASE WHEN [Order ID] IS NULL THEN 1 ELSE 0 END) AS MissingOrderID,
    SUM(CASE WHEN [Customer ID] IS NULL THEN 1 ELSE 0 END) AS MissingCustomerID,
    SUM(CASE WHEN [Product ID] IS NULL THEN 1 ELSE 0 END) AS MissingProductID,
    SUM(CASE WHEN [Order Date] IS NULL THEN 1 ELSE 0 END) AS MissingOrderDate,
    SUM(CASE WHEN Sales IS NULL THEN 1 ELSE 0 END) AS MissingSales
FROM Raw_Superstore;

-- Check repeated Row IDs
SELECT [Row ID], COUNT(*) AS RepeatedRows
FROM Raw_Superstore
GROUP BY [Row ID]
HAVING COUNT(*) > 1;


SELECT TOP 10 *
FROM Raw_Superstore;

-- =====================================================
-- Normalize the dataset into Fact & Dimension Tables
-- =====================================================

CREATE TABLE DimCustomer ( 
	CustomerKey INT IDENTITY(1,1) PRIMARY KEY,
	CustomerID NVARCHAR(50),
	CustomerName NVARCHAR(100),
	Segment NVARCHAR(50)
);

INSERT INTO DimCustomer (CustomerID, CustomerName, Segment)
SELECT DISTINCT
    [Customer ID],
    [Customer Name],
    [Segment]
FROM Raw_Superstore;

SELECT *
FROM DimCustomer;

CREATE TABLE DimProduct (
    ProductKey INT IDENTITY(1,1) PRIMARY KEY,
    ProductID NVARCHAR(50),
    ProductName NVARCHAR(255),
    Category NVARCHAR(100),
    SubCategory NVARCHAR(100)
);

INSERT INTO DimProduct (ProductID, ProductName, Category, SubCategory)
SELECT DISTINCT
    [Product ID],
    [Product Name],
    [Category],
    [Sub-Category]
FROM Raw_Superstore;

SELECT *
FROM DimProduct;

CREATE TABLE DimLocation (
    LocationKey INT IDENTITY(1,1) PRIMARY KEY,
    Country NVARCHAR(100),
    City NVARCHAR(100),
    State NVARCHAR(100),
    PostalCode NVARCHAR(20),
    Region NVARCHAR(50)
);

INSERT INTO DimLocation (Country, City, State, PostalCode, Region)
SELECT DISTINCT
    [Country],
    [City],
    [State],
    [Postal Code],
    [Region]
FROM Raw_Superstore;

SELECT *
FROM DimLocation;

CREATE TABLE DimShipMode (
    ShipModeKey INT IDENTITY(1,1) PRIMARY KEY,
    ShipMode NVARCHAR(50)
);

INSERT INTO DimShipMode (ShipMode)
SELECT DISTINCT [Ship Mode]
FROM Raw_Superstore;

SELECT *
FROM DimShipMode;

CREATE TABLE DimDate (
    DateKey INT PRIMARY KEY,
    FullDate DATE,
    Day INT,
    Month INT,
    MonthName NVARCHAR(20),
    Quarter INT,
    Year INT
);

INSERT INTO DimDate
    (DateKey, FullDate, Day, Month, MonthName, Quarter, Year)

SELECT DISTINCT
    YEAR([Order Date]) * 10000
        + MONTH([Order Date]) * 100
        + DAY([Order Date]),

    [Order Date],
    DAY([Order Date]),
    MONTH([Order Date]),
    DATENAME(MONTH, [Order Date]),
    DATEPART(QUARTER, [Order Date]),
    YEAR([Order Date])

FROM Raw_Superstore;

INSERT INTO DimDate
    (DateKey, FullDate, Day, Month, MonthName, Quarter, Year)

SELECT DISTINCT
    YEAR([Ship Date]) * 10000
        + MONTH([Ship Date]) * 100
        + DAY([Ship Date]),

    [Ship Date],
    DAY([Ship Date]),
    MONTH([Ship Date]),
    DATENAME(MONTH, [Ship Date]),
    DATEPART(QUARTER, [Ship Date]),
    YEAR([Ship Date])

FROM Raw_Superstore

WHERE [Ship Date] NOT IN (
    SELECT FullDate
    FROM DimDate
);

SELECT *
FROM DimDate
ORDER BY FullDate;


CREATE TABLE FactSales (
    SalesKey INT IDENTITY(1,1) PRIMARY KEY,

    OrderID NVARCHAR(50),
    SourceRowID INT UNIQUE,

    CustomerKey INT,
    ProductKey INT,
    LocationKey INT,
    ShipModeKey INT,

    OrderDateKey INT,
    ShipDateKey INT,

    Sales DECIMAL(19,4),
    Quantity INT,
    Discount DECIMAL(5,2),
    Profit DECIMAL(19,4)
    );

SELECT TOP 10
    r.[Customer ID],
    r.[Customer Name],
    c.CustomerKey,

    r.[Product ID],
    r.[Product Name],
    p.ProductKey,

    r.[City],
    l.LocationKey,

    r.[Ship Mode],
    s.ShipModeKey,

    r.[Order Date],
    od.DateKey AS OrderDateKey,

    r.[Ship Date],
    sd.DateKey AS ShipDateKey

FROM Raw_Superstore r

JOIN DimCustomer c
    ON r.[Customer ID] = c.CustomerID
    AND r.[Customer Name] = c.CustomerName
    AND r.[Segment] = c.Segment

JOIN DimProduct p
    ON r.[Product ID] = p.ProductID
    AND r.[Product Name] = p.ProductName
    AND r.[Category] = p.Category
    AND r.[Sub-Category] = p.SubCategory

JOIN DimLocation l
    ON r.[Country] = l.Country
    AND r.[City] = l.City
    AND r.[State] = l.State
    AND (r.[Postal Code] = l.PostalCode OR (r.[Postal Code] IS NULL AND l.PostalCode IS NULL))
    AND r.[Region] = l.Region

JOIN DimShipMode s
    ON r.[Ship Mode] = s.ShipMode

JOIN DimDate od
    ON r.[Order Date] = od.FullDate

JOIN DimDate sd
    ON r.[Ship Date] = sd.FullDate;



SELECT TOP 5 *
FROM DimLocation;

SELECT TOP 5 *
FROM DimDate;

INSERT INTO FactSales
(
    OrderID,
    SourceRowID,
    CustomerKey,
    ProductKey,
    LocationKey,
    ShipModeKey,
    OrderDateKey,
    ShipDateKey,
    Sales,
    Quantity,
    Discount,
    Profit
)
SELECT
    r.[Order ID],
    r.[Row ID],
    c.CustomerKey,
    p.ProductKey,
    l.LocationKey,
    s.ShipModeKey,
    od.DateKey,
    sd.DateKey,
    r.[Sales],
    r.[Quantity],
    r.[Discount],
    r.[Profit]
FROM Raw_Superstore r
JOIN DimCustomer c
    ON r.[Customer ID] = c.CustomerID
    AND r.[Customer Name] = c.CustomerName
    AND r.[Segment] = c.Segment

JOIN DimProduct p
    ON r.[Product ID] = p.ProductID
    AND r.[Product Name] = p.ProductName
    AND r.[Category] = p.Category
    AND r.[Sub-Category] = p.SubCategory

JOIN DimLocation l
    ON r.[Country] = l.Country
    AND r.[City] = l.City
    AND r.[State] = l.State
    AND (r.[Postal Code] = l.PostalCode OR (r.[Postal Code] IS NULL AND l.PostalCode IS NULL))
    AND r.[Region] = l.Region

JOIN DimShipMode s
    ON r.[Ship Mode] = s.ShipMode

JOIN DimDate od
    ON r.[Order Date] = od.FullDate

JOIN DimDate sd
    ON r.[Ship Date] = sd.FullDate;


SELECT COUNT(*) AS FactRows
FROM FactSales;

SELECT TOP 10 *
FROM FactSales;

SELECT COUNT(*)
FROM Raw_Superstore;

SELECT 
    MIN(SalesKey) AS MinKey,
    MAX(SalesKey) AS MaxKey,
    COUNT(*) AS TotalRows
FROM FactSales;

SELECT
    Country,
    City,
    State,
    PostalCode,
    Region,
    COUNT(*) AS HowMany
FROM DimLocation
GROUP BY
    Country,
    City,
    State,
    PostalCode,
    Region
HAVING COUNT(*) > 1;

SELECT
    CustomerID,
    COUNT(*) AS HowMany
FROM DimCustomer
GROUP BY CustomerID
HAVING COUNT(*) > 1;

SELECT
    ProductID,
    COUNT(*) AS HowMany
FROM DimProduct
GROUP BY ProductID
HAVING COUNT(*) > 1;

SELECT
    ProductID,
    ProductName,
    Category,
    SubCategory
FROM DimProduct
WHERE ProductID = 'FUR-CH-10001146';

-- Do not truncate FactSales here: the reports below use its data.
-- Compare row counts and totals with the source after loading.
SELECT
    (SELECT COUNT(*) FROM Raw_Superstore) AS SourceRows,
    (SELECT COUNT(*) FROM FactSales) AS FactRows,
    (SELECT SUM(CAST(Sales AS DECIMAL(19,4))) FROM Raw_Superstore) AS SourceSales,
    (SELECT SUM(Sales) FROM FactSales) AS FactSalesTotal,
    (SELECT SUM(CAST(Profit AS DECIMAL(19,4))) FROM Raw_Superstore) AS SourceProfit,
    (SELECT SUM(Profit) FROM FactSales) AS FactProfitTotal;

-- If the row counts differ, check the dimension joins before continuing.






--- Write advanced SQL queries using JOINs, Subqueries, CTEs, and CASE statements.----

-- Query 1 — Total Sales & Profit by Category -- 

SELECT
    p.Category,
    SUM(f.Sales) AS TotalSales,
    SUM(f.Profit) AS TotalProfit
FROM FactSales f
JOIN DimProduct p
    ON f.ProductKey = p.ProductKey
GROUP BY p.Category
ORDER BY TotalSales DESC;

-- Query 2 - Total Sales & Profit by Region

SELECT
    l.Region,
    SUM(f.Sales) AS TotalSales,
    SUM(f.Profit) AS TotalProfit
FROM FactSales f
JOIN DimLocation l
    ON f.LocationKey = l.LocationKey
GROUP BY l.Region
ORDER BY TotalSales DESC;


SELECT 
    [Region],
    COUNT(*) AS RowsCount
FROM Raw_Superstore
GROUP BY [Region];

-- Query 3 - Total Sales & Profit by Customer Segment

SELECT
    c.Segment,
    SUM(f.Sales) AS TotalSales,
    SUM(f.Profit) AS TotalProfit
FROM FactSales f
JOIN DimCustomer c
    ON f.CustomerKey = c.CustomerKey
GROUP BY c.Segment
ORDER BY TotalSales DESC;

-- Query 4 - Classify Sales by Profit Status using CASE

SELECT
    SalesKey,
    OrderID,
    Sales,
    Profit,
    CASE
        WHEN Profit > 0 THEN 'Profitable'
        WHEN Profit < 0 THEN 'Loss'
        ELSE 'Break Even'
    END AS ProfitStatus
FROM FactSales;

-- Query 5 - Sales Above Average using Subquery

SELECT
    SalesKey,
    OrderID,
    Sales,
    Profit
FROM FactSales
WHERE Sales > (
    SELECT AVG(Sales)
    FROM FactSales
)
ORDER BY Sales DESC;

-- Query 6 - Sales & Profit by Year using CTE

WITH YearlySales AS
(
    SELECT
        d.Year,
        SUM(f.Sales) AS TotalSales,
        SUM(f.Profit) AS TotalProfit
    FROM FactSales f
    JOIN DimDate d
        ON f.OrderDateKey = d.DateKey
    GROUP BY d.Year
)

SELECT *
FROM YearlySales
ORDER BY Year;


-- Query 7 - Top 10 Customers by Sales using CTE

WITH CustomerSales AS
(
    SELECT
        c.CustomerKey,
        c.CustomerName,
        SUM(f.Sales) AS TotalSales,
        SUM(f.Profit) AS TotalProfit
    FROM FactSales f
    JOIN DimCustomer c
        ON f.CustomerKey = c.CustomerKey
    GROUP BY
        c.CustomerKey,
        c.CustomerName
)

SELECT TOP 10 *
FROM CustomerSales
ORDER BY TotalSales DESC;


-- Query 8 - Top 10 Products by Sales

SELECT TOP 10
    p.ProductName,
    p.Category,
    p.SubCategory,
    SUM(f.Sales) AS TotalSales,
    SUM(f.Profit) AS TotalProfit
FROM FactSales f
JOIN DimProduct p
    ON f.ProductKey = p.ProductKey
GROUP BY
    p.ProductName,
    p.Category,
    p.SubCategory
ORDER BY TotalSales DESC;


-- Query 9 - Sales & Profit by SubCategory

SELECT
    p.SubCategory,
    SUM(f.Sales) AS TotalSales,
    SUM(f.Profit) AS TotalProfit
FROM FactSales f
JOIN DimProduct p
    ON f.ProductKey = p.ProductKey
GROUP BY p.SubCategory
ORDER BY TotalSales DESC;


-- Query 10 - Monthly Sales & Profit Trend

SELECT
    d.Year,
    d.Month,
    d.MonthName,
    SUM(f.Sales) AS TotalSales,
    SUM(f.Profit) AS TotalProfit
FROM FactSales f
JOIN DimDate d
    ON f.OrderDateKey = d.DateKey
GROUP BY
    d.Year,
    d.Month,
    d.MonthName
ORDER BY
    d.Year,
    d.Month;


-- Query 11 - Top 10 Most Profitable Customers

SELECT TOP 10
    c.CustomerName,
    c.Segment,
    SUM(f.Sales) AS TotalSales,
    SUM(f.Profit) AS TotalProfit
FROM FactSales f
JOIN DimCustomer c
    ON f.CustomerKey = c.CustomerKey
GROUP BY
    c.CustomerName,
    c.Segment
ORDER BY TotalProfit DESC;


-- Query 12 - Discount Impact on Sales & Profit

SELECT
    Discount,
    COUNT(*) AS NumberOfSales,
    SUM(Sales) AS TotalSales,
    SUM(Profit) AS TotalProfit,
    AVG(Profit) AS AverageProfit
FROM FactSales
GROUP BY Discount
ORDER BY Discount;


-- Query 13 - Sales & Profit by Ship Mode

SELECT
    s.ShipMode,
    COUNT(*) AS NumberOfSales,
    SUM(f.Sales) AS TotalSales,
    SUM(f.Profit) AS TotalProfit
FROM FactSales f
JOIN DimShipMode s
    ON f.ShipModeKey = s.ShipModeKey
GROUP BY s.ShipMode
ORDER BY TotalSales DESC;


-- Query 14 - Top 10 States by Sales

SELECT TOP 10
    l.State,
    SUM(f.Sales) AS TotalSales,
    SUM(f.Profit) AS TotalProfit
FROM FactSales f
JOIN DimLocation l
    ON f.LocationKey = l.LocationKey
GROUP BY l.State
ORDER BY TotalSales DESC;



-- Query 15 - Top 10 States by Profit

SELECT TOP 10
    l.State,
    SUM(f.Sales) AS TotalSales,
    SUM(f.Profit) AS TotalProfit
FROM FactSales f
JOIN DimLocation l
    ON f.LocationKey = l.LocationKey
GROUP BY l.State
ORDER BY TotalProfit DESC;










-- Create View for Category Performance

GO
CREATE VIEW vw_CategoryPerformance AS

SELECT
    p.Category,
    SUM(f.Sales) AS TotalSales,
    SUM(f.Profit) AS TotalProfit
FROM FactSales f
JOIN DimProduct p
    ON f.ProductKey = p.ProductKey
GROUP BY p.Category;

SELECT *
FROM vw_CategoryPerformance
ORDER BY TotalSales DESC;





-- Stored Procedure - Category Performance

GO
CREATE PROCEDURE sp_CategoryPerformance
    @Category VARCHAR(100)
AS
BEGIN
    SELECT
        p.Category,
        SUM(f.Sales) AS TotalSales,
        SUM(f.Profit) AS TotalProfit
    FROM FactSales f
    JOIN DimProduct p
        ON f.ProductKey = p.ProductKey
    WHERE p.Category = @Category
    GROUP BY p.Category;
END;
GO

EXEC sp_CategoryPerformance
    @Category = 'Technology';





-- =====================================================
-- TASK: Optimize Queries for Performance
-- =====================================================


CREATE INDEX IX_FactSales_CustomerKey
ON FactSales(CustomerKey);

CREATE INDEX IX_FactSales_ProductKey
ON FactSales(ProductKey);

CREATE INDEX IX_FactSales_LocationKey
ON FactSales(LocationKey);

CREATE INDEX IX_FactSales_ShipModeKey
ON FactSales(ShipModeKey);

CREATE INDEX IX_FactSales_OrderDateKey
ON FactSales(OrderDateKey);

CREATE INDEX IX_FactSales_ShipDateKey
ON FactSales(ShipDateKey);

SELECT
    c.CustomerName,
    SUM(f.Sales) AS TotalSales
FROM FactSales f
JOIN DimCustomer c
    ON f.CustomerKey = c.CustomerKey
WHERE f.CustomerKey = 10
GROUP BY c.CustomerName;


-- =====================================================
-- ANALYTICAL REPORT 1: PROFITABILITY ANALYSIS
-- =====================================================

SELECT
    p.Category,
    SUM(f.Sales) AS TotalSales,
    SUM(f.Profit) AS TotalProfit,
    ROUND(
        (SUM(f.Profit) / NULLIF(SUM(f.Sales), 0)) * 100,
        2
    ) AS ProfitMarginPercentage
FROM FactSales f
JOIN DimProduct p
    ON f.ProductKey = p.ProductKey
GROUP BY p.Category
ORDER BY TotalProfit DESC;


-- =====================================================
-- ANALYTICAL REPORT 2: CUSTOMER BEHAVIOR
-- =====================================================

SELECT
    c.Segment,
    COUNT(DISTINCT f.OrderID) AS NumberOfOrders,
    SUM(f.Sales) AS TotalSales,
    SUM(f.Profit) AS TotalProfit,
    ROUND(
        SUM(f.Sales) / COUNT(DISTINCT f.OrderID),
        2
    ) AS AverageOrderValue
FROM FactSales f
JOIN DimCustomer c
    ON f.CustomerKey = c.CustomerKey
GROUP BY c.Segment
ORDER BY TotalSales DESC;



-- =====================================================
-- ANALYTICAL REPORT 3: SALES TREND
-- =====================================================

SELECT
    d.Year,
    SUM(f.Sales) AS TotalSales,
    SUM(f.Profit) AS TotalProfit
FROM FactSales f
JOIN DimDate d
    ON f.OrderDateKey = d.DateKey
GROUP BY d.Year
ORDER BY d.Year;

-- =====================================================
-- ADDITIONAL BUSINESS QUESTIONS
-- =====================================================

-- Which subcategories are losing money?
SELECT
    p.Category,
    p.SubCategory,
    COUNT(*) AS OrderLines,
    SUM(f.Sales) AS TotalSales,
    SUM(f.Profit) AS TotalProfit,
    ROUND(100.0 * SUM(f.Profit) / NULLIF(SUM(f.Sales), 0), 2) AS ProfitMargin
FROM FactSales f
JOIN DimProduct p ON f.ProductKey = p.ProductKey
GROUP BY p.Category, p.SubCategory
HAVING SUM(f.Profit) < 0
ORDER BY TotalProfit;

-- Does higher discounting relate to lower profit?
SELECT
    CASE
        WHEN Discount = 0 THEN 'No Discount'
        WHEN Discount <= 0.20 THEN '1-20%'
        WHEN Discount <= 0.40 THEN '21-40%'
        ELSE 'Above 40%'
    END AS DiscountGroup,
    COUNT(*) AS OrderLines,
    SUM(Sales) AS TotalSales,
    SUM(Profit) AS TotalProfit,
    ROUND(100.0 * SUM(Profit) / NULLIF(SUM(Sales), 0), 2) AS ProfitMargin
FROM FactSales
GROUP BY CASE
        WHEN Discount = 0 THEN 'No Discount'
        WHEN Discount <= 0.20 THEN '1-20%'
        WHEN Discount <= 0.40 THEN '21-40%'
        ELSE 'Above 40%'
    END
ORDER BY ProfitMargin DESC;

-- Rank subcategories by profit within each category
WITH SubcategoryProfit AS (
    SELECT p.Category, p.SubCategory,
           SUM(f.Sales) AS TotalSales,
           SUM(f.Profit) AS TotalProfit
    FROM FactSales f
    JOIN DimProduct p ON f.ProductKey = p.ProductKey
    GROUP BY p.Category, p.SubCategory
)
SELECT *,
       DENSE_RANK() OVER (PARTITION BY Category ORDER BY TotalProfit DESC) AS ProfitRank
FROM SubcategoryProfit
ORDER BY Category, ProfitRank;

-- Check repeated rows in FactSales
SELECT SourceRowID, COUNT(*) AS RepeatedRows
FROM FactSales
GROUP BY SourceRowID
HAVING COUNT(*) > 1;
