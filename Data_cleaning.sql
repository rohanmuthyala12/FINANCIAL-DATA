-- Select all rows and columns from the financials table for review
SELECT * FROM financials;

-- Trim leading and trailing spaces from relevant columns
UPDATE financials
SET 
    `Discount Band` = TRIM(`Discount Band`),
    `Month Name` = TRIM(`Month Name`),
    `Month Number` = TRIM(`Month Number`),
    `Gross Sales` = TRIM(`Gross Sales`),
    `Units Sold` = TRIM(`Units Sold`),
    `Sale Price` = TRIM(`Sale Price`),
    `Manufacturing Price` = TRIM(`Manufacturing Price`);

-- Rename columns to remove spaces and replace them with underscores
ALTER TABLE financials
RENAME COLUMN `Discount Band` TO `Discount_Band`,
RENAME COLUMN `Month Name` TO `Month_Name`,
RENAME COLUMN `Month Number` TO `Month_Number`,
RENAME COLUMN `Gross Sales` TO `Gross_Sales`,
RENAME COLUMN `Units Sold` TO `Units_Sold`,
RENAME COLUMN `Sale Price` TO `Sale_Price`,
RENAME COLUMN `Manufacturing Price` TO `Manufacturing_Price`;

-- Display the structure of the financials table to verify the column names and types
SHOW COLUMNS FROM financials;

-- Remove currency symbols, commas, and spaces from numeric columns for proper conversion
UPDATE financials
SET 
    Units_Sold = REPLACE(REPLACE(Units_Sold, '$', ''),' ', ''),
    Manufacturing_Price = REPLACE(REPLACE(Manufacturing_Price, '$', ''), ',', ''),
    Sale_Price = REPLACE(REPLACE(Sale_Price, '$', ''), ',', ''),
    Gross_Sales = REPLACE(REPLACE(Gross_Sales, '$', ''), ',', ''),
    Discounts = REPLACE(REPLACE(Discounts, '$', ''), ',', ''),
    Sales = REPLACE(REPLACE(Sales, '$', ''), ',', ''),
    COGS = REPLACE(REPLACE(COGS, '$', ''), ',', ''),
    Profit = REPLACE(REPLACE(Profit, '$', ''), ',', '');
    
-- Verify the data after cleaning by selecting the first 10 rows
SELECT * from financials limit 10;

-- Check for any null values in the critical columns
SELECT *
FROM financials
WHERE 
    Units_Sold IS NULL OR
    Manufacturing_Price IS NULL OR
    Sale_Price IS NULL OR
    Gross_Sales IS NULL OR
    Discounts IS NULL OR
    Sales IS NULL OR
    COGS IS NULL OR
    Profit IS NULL;

-- Modify the Units_Sold column to be an integer
ALTER TABLE financials
MODIFY Units_Sold INT;

-- Identify duplicate rows using ROW_NUMBER()
WITH RankedRows AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY Segment, Country, Product, Date, Discount_Band ORDER BY (SELECT NULL)) AS rn
    FROM financials
)
SELECT *
FROM RankedRows
WHERE rn > 1;

-- Delete duplicate rows based on the identified duplicates
WITH RankedRows AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY Segment, Country, Product, Date, Discount_Band ORDER BY (SELECT NULL)) AS rn
    FROM financials
)
DELETE FROM financials
WHERE (Segment, Country, Product, Date, Discount_Band) IN (
    SELECT Segment, Country, Product, Date, Discount_Band
    FROM RankedRows
    WHERE rn > 1
);

-- Convert date strings to a consistent date format
UPDATE financials
SET Date = STR_TO_DATE(Date, '%m/%d/%Y');

-- Replace any '-' in Discounts with '0'
UPDATE financials
SET Discounts = REPLACE(Discounts, '-', '0')
WHERE Discounts LIKE '%-%';

-- Clean any unwanted ')' characters in the Profit column
UPDATE financials
SET Profit = REPLACE(Profit, ')', '')
WHERE Profit LIKE '%)%';

-- Modify columns to their correct data types
ALTER TABLE financials
MODIFY Units_Sold INT,
MODIFY Manufacturing_Price DECIMAL(10,2),
MODIFY Sale_Price DECIMAL(10,2),
MODIFY Gross_Sales DECIMAL(10,2),
MODIFY Discounts DECIMAL(10,2),
MODIFY Sales DECIMAL(10,2),
MODIFY COGS DECIMAL(10,2),
MODIFY Profit DECIMAL(10,2),
MODIFY Date DATE;

-- Create a backup of the cleaned financials table
CREATE TABLE financials_backup AS SELECT * FROM financials;
