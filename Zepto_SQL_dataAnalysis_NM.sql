--data exploration

--count of rows
select count(*) As Total_rows
from zepto_cleaned 

--null values
SELECT * FROM zepto_cleaned
WHERE name IS NULL
OR
category IS NULL
OR
mrp IS NULL
OR
discountPercent IS NULL
OR
discountedSellingPrice IS NULL
OR
weightInGms IS NULL
OR
availableQuantity IS NULL
OR
outOfStock IS NULL
OR
quantity IS NULL;

--different product categories
SELECT DISTINCT category
FROM zepto_cleaned
ORDER BY category;

--products in stock vs out of stock
SELECT outOfStock, COUNT(*)
FROM zepto_cleaned
GROUP BY outOfStock;

--product names present multiple times
SELECT name, COUNT(*) AS "Number of products"
FROM zepto_cleaned
GROUP BY name
HAVING count(*) > 1
ORDER BY count(*) DESC;

--products with price = 0
SELECT * FROM zepto_cleaned
WHERE mrp = 0 OR discountedSellingPrice = 0;

--convert paise to rupees
UPDATE zepto_cleaned
SET mrp = mrp / 100.0,
discountedSellingPrice = discountedSellingPrice / 100.0;

SELECT mrp, discountedSellingPrice FROM zepto_cleaned;

--data analysis

-- Q1. Find the top 10 best-value products based on the discount percentage.
SELECT DISTINCT TOP 10 name, mrp, discountPercent
FROM zepto_cleaned
ORDER BY discountPercent DESC;

--Q2.What are the Products with High MRP but Out of Stock

SELECT DISTINCT name, mrp
FROM zepto_cleaned
WHERE outOfStock = 1 AND mrp > 300
ORDER BY mrp DESC;

--Q3.Calculate Estimated Revenue for each category
SELECT category,
SUM(discountedSellingPrice * availableQuantity) AS total_revenue
FROM zepto_cleaned
GROUP BY category
ORDER BY total_revenue;

-- Q4. Find top 10 products where MRP is greater than ₹500 and discount is less than 10%.
SELECT DISTINCT Top 10 name, mrp, discountPercent
FROM zepto_cleaned
WHERE mrp > 500 AND discountPercent < 10
ORDER BY mrp DESC, discountPercent DESC;

-- Q5. Identify the top 5 categories offering the highest average discount percentage.
SELECT Top 5 category,
ROUND(AVG(discountPercent),2) AS avg_discount
FROM zepto_cleaned
GROUP BY category
ORDER BY avg_discount DESC;

--Q7.Group the products into categories like Low, Medium, Bulk.
SELECT 
    CASE 
        WHEN weightInGms < 1000 THEN 'Low (< 1kg)'
        WHEN weightInGms < 5000 THEN 'Medium (1kg - 5kg)'
        ELSE 'Bulk (>= 5kg)'
    END AS weight_category,
    COUNT(*) AS total_products,
    ROUND(AVG(mrp), 2) AS avg_mrp,
    SUM(availableQuantity) AS total_units_in_stock
FROM zepto_cleaned
GROUP BY 
    CASE 
        WHEN weightInGms < 1000 THEN 'Low (< 1kg)'
        WHEN weightInGms < 5000 THEN 'Medium (1kg - 5kg)'
        ELSE 'Bulk (>= 5kg)'
    END
ORDER BY total_products DESC;

--Q8.What is the Total Inventory Weight Per Category 
SELECT category, SUM(CAST(weightInGms AS BIGINT) * availableQuantity) AS total_weight
FROM zepto_cleaned
GROUP BY category
ORDER BY total_weight DESC;

--Q9.Stockout & Revenue Risk Analysis

SELECT 
    category,
    COUNT(*) AS out_of_stock_products,
    SUM(discountedSellingPrice) AS lost_revenue_potential
FROM zepto_cleaned
WHERE outOfStock = 1
GROUP BY category
ORDER BY lost_revenue_potential DESC;

--Q10. Discount Efficiency & Margin Squeeze Ratio

SELECT DISTINCT TOP 10
    name,
    category,
    mrp,
    discountedSellingPrice,
    discountPercent,
    availableQuantity
FROM zepto_cleaned
WHERE discountPercent >= 30 AND availableQuantity > 5
ORDER BY availableQuantity DESC, discountPercent DESC;


--Q.11 Price Tier Segmentation (Budget vs. Mid-Range vs. Premium)

SELECT 
    CASE 
        WHEN mrp <= 100 THEN 'Budget (<= ₹100)'
        WHEN mrp <= 300 THEN 'Mid-Tier (₹101 - ₹300)'
        ELSE 'Premium (> ₹300)'
    END AS price_tier,
    COUNT(*) AS total_products,
    SUM(availableQuantity) AS total_stock
FROM zepto_cleaned
GROUP BY 
    CASE 
        WHEN mrp <= 100 THEN 'Budget (<= ₹100)'
        WHEN mrp <= 300 THEN 'Mid-Tier (₹101 - ₹300)'
        ELSE 'Premium (> ₹300)'
    END
ORDER BY total_products DESC;
