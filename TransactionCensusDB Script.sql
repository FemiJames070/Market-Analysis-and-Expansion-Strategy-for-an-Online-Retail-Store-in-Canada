-- Create New Database
CREATE DATABASE TransactionCensusDB;

-- Switch to New Database
USE TransactionCensusDB;

-- Preview Online Retail Transaction Dataset from the Database
SELECT * FROM [Online_Retail_Transaction]

-- Preview Census Profile Dataset from the Database
SELECT * FROM [Census_Profile_2021]

-- DATA PREPARATION

-- Dataset 1: [Online_Retail_Transaction]

-- Step 1: Check for missing values
SELECT 
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN CustomerID IS NULL THEN 1 ELSE 0 END) AS MissingCustomerID,
    SUM(CASE WHEN Description IS NULL THEN 1 ELSE 0 END) AS MissingDescription,
    SUM(CASE WHEN InvoiceNo IS NULL THEN 1 ELSE 0 END) AS MissingInvoiceNo,
    SUM(CASE WHEN Quantity IS NULL THEN 1 ELSE 0 END) AS MissingQuantity,
    SUM(CASE WHEN UnitPrice IS NULL THEN 1 ELSE 0 END) AS MissingUnitPrice,
    SUM(CASE WHEN InvoiceDate IS NULL THEN 1 ELSE 0 END) AS MissingInvoiceDate
FROM [Online_Retail_Transaction];

-- Step 2: Change CustomerID to NVARCHAR
ALTER TABLE [Online_Retail_Transaction]
ALTER COLUMN CustomerID NVARCHAR(50);

-- Step 3: Handle missing values (example: replace NULLs with default values)
UPDATE [Online_Retail_Transaction]
SET 
    CustomerID = COALESCE(CustomerID, 'Unknown'),
    Description = COALESCE(Description, 'No Description'),
    Quantity = COALESCE(Quantity, 0),
    UnitPrice = COALESCE(UnitPrice, 0.0)
WHERE 
    CustomerID IS NULL OR 
    Description IS NULL OR 
    Quantity IS NULL OR 
    UnitPrice IS NULL;

-- Step 4: Remove duplicates
WITH CTE AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY InvoiceNo, StockCode, Quantity, InvoiceDate, UnitPrice, CustomerID 
               ORDER BY InvoiceDate
           ) AS rn
    FROM [Online_Retail_Transaction]
)
DELETE FROM CTE WHERE rn > 1;

-- Step 5: Ensure correct data types
ALTER TABLE [TransactionCensusDB].[dbo].[Online_Retail_Transaction]
ALTER COLUMN InvoiceDate DATETIME;

ALTER TABLE [TransactionCensusDB].[dbo].[Online_Retail_Transaction]
ALTER COLUMN UnitPrice DECIMAL(18, 2);

ALTER TABLE [TransactionCensusDB].[dbo].[Online_Retail_Transaction]
ALTER COLUMN Quantity INT;

-- Step 6: Create the Customers Table for Canada: This table will store unique customers from Canada.

-- 1. Create Customers_Canada Table: This table will store detailed customer information for Canada only.
CREATE TABLE Customers_Canada (
    CustomerID NVARCHAR(50) PRIMARY KEY,
    Country NVARCHAR(50) DEFAULT 'Canada', -- Ensure all records are for Canada
    FirstPurchaseDate DATETIME,
    LastPurchaseDate DATETIME,
    TotalPurchases INT,
    TotalSpent DECIMAL(18, 2)
);

-- Insert data into Customers_Canada table
INSERT INTO Customers_Canada (CustomerID, Country, FirstPurchaseDate, LastPurchaseDate, TotalPurchases, TotalSpent)
SELECT 
    CustomerID,
    'Canada' AS Country, -- Explicitly set country to Canada
    MIN(InvoiceDate) AS FirstPurchaseDate,
    MAX(InvoiceDate) AS LastPurchaseDate,
    COUNT(DISTINCT InvoiceNo) AS TotalPurchases,
    SUM(Quantity * UnitPrice) AS TotalSpent
FROM [TransactionCensusDB].[dbo].[Online_Retail_Transaction]
WHERE Country = 'Canada' AND CustomerID IS NOT NULL
GROUP BY CustomerID;

-- Check Customers_Canada table
SELECT * FROM Customers_Canada;


-- 2. Create Products_Canada Table: This table will store detailed product information for products sold in Canada.
CREATE TABLE Products_Canada (
    StockCode NVARCHAR(50) PRIMARY KEY,
    Description NVARCHAR(255),
    UnitPrice DECIMAL(18, 2),
    TotalQuantitySold INT,
    TotalRevenue DECIMAL(18, 2)
);

-- Insert data into Products_Canada table
INSERT INTO Products_Canada (StockCode, Description, UnitPrice, TotalQuantitySold, TotalRevenue)
SELECT 
    ort.StockCode,
    MIN(ort.Description) AS Description, -- Use MIN() to handle duplicates
    MIN(ort.UnitPrice) AS UnitPrice, -- Use MIN() to handle duplicates
    SUM(ort.Quantity) AS TotalQuantitySold,
    SUM(ort.Quantity * ort.UnitPrice) AS TotalRevenue
FROM [TransactionCensusDB].[dbo].[Online_Retail_Transaction] ort
WHERE ort.Country = 'Canada'
GROUP BY ort.StockCode;

-- Check Products_Canada table
SELECT * FROM Products_Canada;


-- 3. Create Invoices_Canada Table: This table will store detailed invoice information for transactions in Canada.
CREATE TABLE Invoices_Canada (
    InvoiceID INT IDENTITY(1,1) PRIMARY KEY, -- Auto-incrementing primary key
    InvoiceNo NVARCHAR(50),
    InvoiceDate DATETIME,
    CustomerID NVARCHAR(50), -- Foreign Key to Customers_Canada
    TotalQuantity INT,
    TotalAmount DECIMAL(18, 2),
    FOREIGN KEY (CustomerID) REFERENCES Customers_Canada(CustomerID)
);

-- Insert data into Invoices_Canada table
INSERT INTO Invoices_Canada (InvoiceNo, InvoiceDate, CustomerID, TotalQuantity, TotalAmount)
SELECT 
    ort.InvoiceNo,
    MIN(ort.InvoiceDate) AS InvoiceDate, -- Use the earliest date for the invoice
    ort.CustomerID,
    SUM(ort.Quantity) AS TotalQuantity,
    SUM(ort.Quantity * ort.UnitPrice) AS TotalAmount
FROM [TransactionCensusDB].[dbo].[Online_Retail_Transaction] ort
WHERE ort.Country = 'Canada'
GROUP BY ort.InvoiceNo, ort.CustomerID;

-- Check Invoices_Canada table
SELECT * FROM Invoices_Canada;


-- 4. Create InvoiceDetails_Canada Table: This table will store line-item details for each invoice in Canada.
CREATE TABLE InvoiceDetails_Canada (
    InvoiceDetailID INT IDENTITY(1,1) PRIMARY KEY, -- Auto-incrementing primary key
    InvoiceID INT, -- Foreign Key to Invoices_Canada
    StockCode NVARCHAR(50), -- Foreign Key to Products_Canada
    Quantity INT,
    UnitPrice DECIMAL(18, 2),
    TotalPrice DECIMAL(18, 2),
    FOREIGN KEY (InvoiceID) REFERENCES Invoices_Canada(InvoiceID),
    FOREIGN KEY (StockCode) REFERENCES Products_Canada(StockCode)
);

-- Insert data into InvoiceDetails_Canada table
INSERT INTO InvoiceDetails_Canada (InvoiceID, StockCode, Quantity, UnitPrice, TotalPrice)
SELECT 
    i.InvoiceID,
    ort.StockCode,
    ort.Quantity,
    ort.UnitPrice,
    ort.Quantity * ort.UnitPrice AS TotalPrice
FROM [TransactionCensusDB].[dbo].[Online_Retail_Transaction] ort
JOIN Invoices_Canada i ON ort.InvoiceNo = i.InvoiceNo
WHERE ort.Country = 'Canada';

-- Check InvoiceDetails_Canada table
SELECT * FROM InvoiceDetails_Canada;

-- Join all the tables together for analysis:
-- The tables can be joined using the following relationships:
-- Customers_Canada → Invoices_Canada: Linked by CustomerID.
-- Invoices_Canada → InvoiceDetails_Canada: Linked by InvoiceID.
-- Products_Canada → InvoiceDetails_Canada: Linked by StockCode.

-- Create a new table and insert the joined data
SELECT 
    c.CustomerID,
    c.Country,
    c.FirstPurchaseDate,
    c.LastPurchaseDate,
    c.TotalPurchases,
    c.TotalSpent,
    i.InvoiceID,
    i.InvoiceNo,
    i.InvoiceDate,
    i.TotalQuantity AS InvoiceTotalQuantity,
    i.TotalAmount AS InvoiceTotalAmount,
    id.InvoiceDetailID,
    id.StockCode,
    p.Description AS ProductDescription,
    p.UnitPrice AS ProductUnitPrice,
    id.Quantity AS LineItemQuantity,
    id.UnitPrice AS LineItemUnitPrice,
    id.TotalPrice AS LineItemTotalPrice
INTO JoinedData -- Creates a new table called JoinedData
FROM Customers_Canada c
JOIN Invoices_Canada i ON c.CustomerID = i.CustomerID
JOIN InvoiceDetails_Canada id ON i.InvoiceID = id.InvoiceID
JOIN Products_Canada p ON id.StockCode = p.StockCode;

-- DATA EXPLORATION

-- 1. Customer Segmentation: Group by CustomerID and analyze metrics like TotalSpent, TotalPurchases, and FirstPurchaseDate
SELECT 
    CustomerID,
    COUNT(DISTINCT InvoiceID) AS TotalInvoices,
    SUM(LineItemTotalPrice) AS TotalSpent,
    DATEDIFF(DAY, MIN(InvoiceDate), MAX(InvoiceDate)) AS CustomerLifetime
FROM JoinedData
GROUP BY CustomerID;

-- Product Analysis: Group by StockCode or ProductCategory to analyze sales performance.
SELECT 
    ProductDescription,
    SUM(LineItemQuantity) AS TotalQuantitySold,
    SUM(LineItemTotalPrice) AS TotalRevenue
FROM JoinedData
GROUP BY ProductDescription
ORDER BY TotalRevenue DESC;

-- Sales Trends: Group by InvoiceDate (or extract year/month) to analyze sales trends over time.
SELECT 
    YEAR(InvoiceDate) AS InvoiceYear,
    MONTH(InvoiceDate) AS InvoiceMonth,
    SUM(LineItemTotalPrice) AS MonthlyRevenue
FROM JoinedData
GROUP BY YEAR(InvoiceDate), MONTH(InvoiceDate)
ORDER BY InvoiceYear, InvoiceMonth;


-- Dataset 2: [Online_Retail_Transaction]

-- DATA PREPARATION

-- 2.1. Check for Missing Values: Identify and handle missing values in key columns like Total, Men, Women, etc.
SELECT 
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN Total IS NULL THEN 1 ELSE 0 END) AS MissingTotal,
    SUM(CASE WHEN Men IS NULL THEN 1 ELSE 0 END) AS MissingMen,
    SUM(CASE WHEN Women IS NULL THEN 1 ELSE 0 END) AS MissingWomen,
    SUM(CASE WHEN Total2 IS NULL THEN 1 ELSE 0 END) AS MissingTotal2,
    SUM(CASE WHEN Men_2 IS NULL THEN 1 ELSE 0 END) AS MissingMen2,
    SUM(CASE WHEN Women_2 IS NULL THEN 1 ELSE 0 END) AS MissingWomen2
FROM [TransactionCensusDB].[dbo].[Census_Profile_2021];

-- 2.2. Handle Missing Values: Replace missing values with appropriate defaults (e.g., 0 for numeric columns).
UPDATE [TransactionCensusDB].[dbo].[Census_Profile_2021]
SET 
    Total = COALESCE(Total, 0),
    Men = COALESCE(Men, 0),
    Women = COALESCE(Women, 0),
    Total2 = COALESCE(Total2, 0),
    Men_2 = COALESCE(Men_2, 0),
    Women_2 = COALESCE(Women_2, 0)
WHERE 
    Total IS NULL OR 
    Men IS NULL OR 
    Women IS NULL OR 
    Total2 IS NULL OR 
    Men_2 IS NULL OR 
    Women_2 IS NULL;

-- 2.3. Standardize Column Names: Rename columns to make them more understandable and consistent.
EXEC sp_rename '[TransactionCensusDB].[dbo].[Census_Profile_2021].[column16]', 'AdditionalInfo', 'COLUMN';

-- 2.4. Remove Unnecessary Columns: Drop unnecessary columns one by one
ALTER TABLE [TransactionCensusDB].[dbo].[Census_Profile_2021]
DROP COLUMN Note;

ALTER TABLE [TransactionCensusDB].[dbo].[Census_Profile_2021]
DROP COLUMN Total_Flag;

ALTER TABLE [TransactionCensusDB].[dbo].[Census_Profile_2021]
DROP COLUMN Men_Flag;

ALTER TABLE [TransactionCensusDB].[dbo].[Census_Profile_2021]
DROP COLUMN Women_Flag;

ALTER TABLE [TransactionCensusDB].[dbo].[Census_Profile_2021]
DROP COLUMN Total_Flag2;

ALTER TABLE [TransactionCensusDB].[dbo].[Census_Profile_2021]
DROP COLUMN Men_Flag2;

ALTER TABLE [TransactionCensusDB].[dbo].[Census_Profile_2021]
DROP COLUMN Women_Flag2;

ALTER TABLE [TransactionCensusDB].[dbo].[Census_Profile_2021]
DROP COLUMN AdditionalInfo;

-- 2.5. Pivot Data: Pivoting data to a long format for easier analysis.
SELECT 
    Topic,
    Characteristic,
    'Total' AS Metric,
    Total AS Value
FROM [TransactionCensusDB].[dbo].[Census_Profile_2021]
UNION ALL
SELECT 
    Topic,
    Characteristic,
    'Men' AS Metric,
    Men AS Value
FROM [TransactionCensusDB].[dbo].[Census_Profile_2021]
UNION ALL
SELECT 
    Topic,
    Characteristic,
    'Women' AS Metric,
    Women AS Value
FROM [TransactionCensusDB].[dbo].[Census_Profile_2021];

-- Step 3: Create a cleaned census table with a Country column
CREATE TABLE Cleaned_Census_2021 (
    Country NVARCHAR(50) DEFAULT 'Canada', -- Add a Country column
    Topic NVARCHAR(MAX), -- Increase size to NVARCHAR(MAX)
    Characteristic NVARCHAR(MAX), -- Keep as NVARCHAR(MAX)
    Total INT,
    Men INT,
    Women INT,
    Total2 INT,
    Men_2 INT,
    Women_2 INT
);

-- Insert cleaned data into the new table
INSERT INTO Cleaned_Census_2021 (Country, Topic, Characteristic, Total, Men, Women, Total2, Men_2, Women_2)
SELECT 
    'Canada' AS Country, -- Explicitly set Country to Canada
    Topic,
    Characteristic,
    Total,
    Men,
    Women,
    Total2,
    Men_2,
    Women_2
FROM [TransactionCensusDB].[dbo].[Census_Profile_2021];

-- Verify Cleaned_Census_2021 table
SELECT * FROM Cleaned_Census_2021;

-- DATA EXPLORATION

-- Step 3: Explore Unique Topics: Identify the unique topics in the dataset. This will help us understand the main categories of the census data.
SELECT DISTINCT Topic
FROM Cleaned_Census_2021;

-- Step 4: Explore Unique Characteristics: Explore the unique characteristics within each topic. This will help us understand the specific attributes being measured.
SELECT Topic, Characteristic
FROM Cleaned_Census_2021
GROUP BY Topic, Characteristic
ORDER BY Topic, Characteristic;

-- Step 5: Analyze Population Data: Focus on the Population topic and analyze the total population, male population, and female population.
SELECT 
    Characteristic,
    SUM(Total) AS Total,
    SUM(Men) AS Men,
    SUM(Women) AS Women
FROM Cleaned_Census_2021
WHERE Topic = 'Population, 2021'
  AND Characteristic IN (
      'Total private dwellings', 
      'Private dwellings occupied by usual residents', 
      'Population, 2021'
  )
GROUP BY Characteristic
ORDER BY Total DESC;
