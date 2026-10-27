--Data Cleaning
--1. Check for Missing & Null Values (Completeness)
SELECT 
    COUNT(*) AS total_rows,
    SUM(CASE WHEN Category IS NULL OR Category = '' THEN 1 ELSE 0 END) AS missing_category,
    SUM(CASE WHEN name IS NULL OR name = '' THEN 1 ELSE 0 END) AS missing_name,
    SUM(CASE WHEN mrp IS NULL THEN 1 ELSE 0 END) AS missing_mrp,
    SUM(CASE WHEN discountPercent IS NULL THEN 1 ELSE 0 END) AS missing_discount,
    SUM(CASE WHEN discountedSellingPrice IS NULL THEN 1 ELSE 0 END) AS missing_selling_price,
    SUM(CASE WHEN weightInGms IS NULL THEN 1 ELSE 0 END) AS missing_weight
FROM Zepto;
--There is no missing and null values

--2. Identify Duplicate Records (Uniqueness)
SELECT 
    Category, 
    name, 
    mrp, 
    discountPercent, 
    weightInGms, 
    COUNT(*) AS duplicate_count
FROM zepto_cleaned
GROUP BY Category, name, mrp, discountPercent, weightInGms
HAVING COUNT(*) > 1;

--removing the misclassified prodcucts

SELECT DISTINCT
    Category,
    name,
    mrp,
    discountPercent,
    availableQuantity,
    discountedSellingPrice,
    weightInGms,
    outOfStock,
    quantity
INTO zepto_cleaned
FROM zepto
WHERE mrp > 0 
  AND weightInGms > 0 
  AND name IS NOT NULL
  -- Keep only the logical/primary category for these specific overlapping items
  AND NOT (
      (Category = 'Munchies' AND name IN ('Everest Kesari Milk Masala', 'Mother''s Recipe Tamarind Paste'))
      OR
      (Category = 'Packaged Food' AND name IN ('Mother''s Recipe Tamarind Paste', 'Kitchens Of India Dal Makhani'))
      OR
      (Category IN ('Chocolates & Candies', 'Ice Cream & Desserts'))
  );
  -- Removed all the misclassified products
  IF OBJECT_ID('zepto_cleaned', 'U') IS NOT NULL 
    DROP TABLE zepto_cleaned;

WITH RankedProducts AS (
    SELECT 
        Category,
        name,
        mrp,
        discountPercent,
        availableQuantity,
        discountedSellingPrice,
        weightInGms,
        outOfStock,
        quantity,
        ROW_NUMBER() OVER (
            PARTITION BY Category, name 
            ORDER BY availableQuantity DESC
        ) AS rn
    FROM zepto
    WHERE mrp > 0 
      AND weightInGms > 0 
      AND name IS NOT NULL
      -- Exclude all cross-category misclassifications
      AND NOT (
          (Category IN ('Chocolates & Candies', 'Ice Cream & Desserts', 'Munchies', 'Packaged Food') 
           AND name IN ('Everest Kesari Milk Masala', 'Mother''s Recipe Tamarind Paste', 'Kitchens Of India Dal Makhani'))
          OR
          (Category IN ('Personal Care', 'Paan Corner') 
           AND name LIKE '%Listerine%')
      )
)
SELECT 
    Category,
    name,
    mrp,
    discountPercent,
    availableQuantity,
    discountedSellingPrice,
    weightInGms,
    outOfStock,
    quantity
INTO zepto_cleaned
FROM RankedProducts
WHERE rn = 1;

-- Step 3: Check for Logical Anomalies & Invalid Values (Validity)
--prices, weights, and quantities should not be zero or negative

SELECT * 
FROM zepto_cleaned
WHERE mrp <= 0 
   OR discountedSellingPrice < 0 
   OR weightInGms <= 0 
   OR quantity < 0;

--Verify Price and Discount Logic:
SELECT 
    name, 
    mrp, 
    discountPercent, 
    discountedSellingPrice,
    ROUND(mrp * (1 - discountPercent / 100.0), 2) AS calculated_sp
FROM zepto_cleaned
WHERE ABS(discountedSellingPrice - (mrp * (1 - discountPercent / 100.0))) > 1; -- allowing a small rounding margin

--4. Step 4: Standardize Text and Categorical Data (Consistency)
SELECT DISTINCT Category, COUNT(*) AS item_count
FROM zepto_cleaned
GROUP BY Category
ORDER BY Category;
