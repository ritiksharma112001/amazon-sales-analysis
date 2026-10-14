CREATE TABLE amazon_sales (
    row_index INTEGER,
    order_id VARCHAR(30),
    date DATE,
    status VARCHAR(100),
    fulfilment VARCHAR(30),
    sales_channel VARCHAR(50),
    ship_service_level VARCHAR(30),
    style VARCHAR(30),
    sku VARCHAR(50),
    category VARCHAR(50),
    size VARCHAR(10),
    asin VARCHAR(20),
    courier_status VARCHAR(30),
    qty INTEGER,
    currency VARCHAR(10),
    amount NUMERIC(12, 2),
    ship_city VARCHAR(100),
    ship_state VARCHAR(100),
    ship_postal_code VARCHAR(20),
    ship_country VARCHAR(10),
    promotion_ids TEXT,
    b2b BOOLEAN,
    fulfilled_by VARCHAR(50)
);

-- Amazon Sales Analysis — 25 SQL Business Questions
-- A. Basic Data Analysis
-- 1. How many total records are present in the dataset?
SELECT COUNT(*) AS total_records
FROM amazon_sales;


-- 2. How many unique order IDs are present?
SELECT COUNT(DISTINCT(order_id)) AS total_unique_order_IDs
FROM amazon_sales;

-- 3. How many records belong to each order status?
SELECT status, COUNT(*) AS total_order_status
FROM amazon_sales
GROUP BY status
ORDER BY total_order_status DESC;

-- 4. How many unique product categories are present?
SELECT COUNT(DISTINCT category) AS total_unique_category
FROM amazon_sales;

-- 5. How many records have a missing amount value?
SELECT COUNT(*)
FROM amazon_sales
WHERE amount IS NULL;

-- B. Sales and Revenue Analysis
-- 6. What is the total sales amount?
SELECT SUM(amount) AS total_sales_amount
FROM amazon_sales;

-- 7. What is the total sales amount for each product category?
SELECT category, SUM(amount) AS total_sales_amount
FROM amazon_sales
GROUP BY category;

-- 8. What are the top 5 product categories by total sales?
SELECT category, SUM(amount) AS total_sales
FROM amazon_sales
GROUP BY category
ORDER BY total_sales DESC
LIMIT 5;

-- 9. What is the total sales amount for each month?
SELECT TO_CHAR(date, 'Month') AS month, SUM(amount) AS total_sales
FROM amazon_sales
GROUP BY TO_CHAR(date, 'Month'), EXTRACT(MONTH FROM date) 
ORDER BY EXTRACT(MONTH FROM date);

-- 10. Which month recorded the highest total sales?
SELECT TO_CHAR(date, 'Month') AS month, SUM(amount) AS highest_sales
FROM amazon_sales
GROUP BY TO_CHAR(date, 'Month'), EXTRACT(MONTH FROM date)
ORDER BY highest_sales DESC
LIMIT 1;

-- 11. What is the total sales amount for each product size?
SELECT size, SUM(amount) AS total_sales
FROM amazon_sales
GROUP BY size;

-- 12. What is the Average Order Value (AOV)?
WITH revenue AS (
	SELECT order_id, SUM(amount) AS total_amount
	FROM amazon_sales
	GROUP BY order_id
)
SELECT ROUND(AVG(total_amount),2) AS average_order_value
FROM revenue;

-- C. Product Performance
-- 13. What are the top 10 SKUs by quantity sold?
SELECT sku AS top_10, SUM(qty) AS quantity_sold
FROM amazon_sales
GROUP BY sku
ORDER BY quantity_sold DESC
LIMIT 10;

-- 14. What are the top 10 SKUs by total sales?
SELECT sku AS top_10_sku, COALESCE(SUM(amount),0) AS total_sales
FROM amazon_sales
GROUP BY sku
ORDER BY total_sales DESC
LIMIT 10;

-- 15. How many units were sold in each product category?
SELECT category, SUM(qty) AS unit_sold
FROM amazon_sales
GROUP BY category
ORDER BY unit_sold DESC;

-- 16. Which products have high quantities sold but comparatively low total sales?
SELECT sku, SUM(qty) AS qty_sold, SUM(amount) AS sales
FROM amazon_sales
GROUP BY sku
ORDER BY qty_sold DESC, sales ASC;

-- D. Order and Fulfilment Analysis
-- 17. How many records belong to each fulfilment type?
SELECT fulfilment, COUNT(*) AS total_records
FROM amazon_sales
GROUP BY fulfilment
ORDER BY total_records DESC;

-- 18. What is the cancellation rate for each fulfilment type?
WITH fulfilment_total_records AS (
	SELECT fulfilment, COUNT(*) AS total_records
	FROM amazon_sales
	GROUP BY fulfilment
),
cancelled_records AS (
	SELECT fulfilment, COUNT(*) AS total_cancelled_orders
	FROM amazon_sales
	WHERE status = 'Cancelled'
	GROUP BY fulfilment
)
SELECT f.fulfilment, 
	ROUND(100.0 * COALESCE (c.total_cancelled_orders,0) / f.total_records, 2) AS cancellation_rate_pct
FROM fulfilment_total_records f
LEFT JOIN cancelled_records c
ON f.fulfilment = c.fulfilment;

-- 19. What is the distribution of records across courier statuses?
SELECT courier_status, COUNT(*) AS distribution_of_records
FROM amazon_sales
GROUP BY courier_status
ORDER BY distribution_of_records DESC;

-- 20. What is the total quantity associated with each order status?
SELECT status, SUM(qty) AS total_quantity
FROM amazon_sales
GROUP BY status
ORDER BY total_quantity DESC;

-- E. Regional and Customer Analysis
-- 21. Which are the top 10 states by number of records?
SELECT ship_state, COUNT(*) AS total_records
FROM amazon_sales
GROUP BY ship_state
ORDER BY total_records DESC
LIMIT 10;

-- 22. What is the total sales amount for each state?
SELECT ship_state, SUM(amount) AS total_sales
FROM amazon_sales
GROUP BY ship_state
ORDER BY total_sales DESC;

-- 23. Which state has the highest number of cancelled records?
SELECT ship_state, COUNT(*) AS highest_cancelled_records
FROM amazon_sales
WHERE status = 'Cancelled'
GROUP BY ship_state
ORDER BY highest_cancelled_records DESC
LIMIT 1;

-- 24. How do B2B and B2C records compare in record count and total sales?
SELECT
	CASE
		WHEN b2b = false THEN 'B2C'
		WHEN b2b = true THEN 'B2B'
		ELSE 'Unknown'
	END AS B2B_B2C_records,
	COUNT(*) AS total_records, 
	SUM(amount) AS total_sales
FROM amazon_sales
GROUP BY b2b;

-- 25. Which states have a high number of records but a relatively low proportion of delivered records?
WITH states_records AS (
	SELECT ship_state, COUNT(*) total_records
	FROM amazon_sales
	GROUP BY ship_state
),
states_delivered_records AS (
	SELECT ship_state, COUNT(*) as total_delivered_records
	FROM amazon_sales
	WHERE status = 'Shipped - Delivered to Buyer'
	GROUP BY ship_state
)
SELECT s.ship_state, s.total_records,
	ROUND(100.0 * COALESCE (sd.total_delivered_records,0) / NULLIF(s.total_records, 0),2) AS delivered_percentage
FROM states_records s
LEFT JOIN states_delivered_records sd
ON s.ship_state = sd.ship_state
ORDER BY s.total_records DESC, delivered_percentage ASC;
