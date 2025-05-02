-- Checking Tables --
SELECT * FROM order_details

SELECT * FROM orders

SELECT * FROM pizza_details

SELECT * FROM pizzas
-- ---------------------------------
-- PRIMARY KEY AND FOREIGN KEY --
-- ---------------------------------
ALTER TABLE orders
ADD CONSTRAINT orders_pk PRIMARY KEY (order_id)

ALTER TABLE order_details
ADD CONSTRAINT order_fk
FOREIGN KEY (order_id) REFERENCES orders(order_id)

ALTER TABLE order_details
ADD CONSTRAINT order_details_id_PK PRIMARY KEY (order_details_id)

ALTER TABLE pizzas
ADD CONSTRAINT pizza_id_pk PRIMARY KEY (pizza_id)

ALTER TABLE order_details
ADD CONSTRAINT pizza_id_fk
FOREIGN KEY (pizza_id) REFERENCES pizzas(pizza_id)

ALTER TABLE pizza_details
ADD CONSTRAINT pizza_type_pk PRIMARY KEY (pizza_type_id)

ALTER TABLE pizzas
ADD CONSTRAINT pizza_type_id_FK
FOREIGN KEY (pizza_type_id) REFERENCES pizza_details(pizza_type_id)

-- ------
-- EDA
-- ------

SELECT 
	*
FROM order_details

-- 1. how many product ordered 

SELECT 
	COUNT(*)
FROM order_details

-- 2. Top order customers

SELECT 
	order_id,
	COUNT(*)
FROM order_details
GROUP BY 1
ORDER BY 2 DESC

-- 3. Total Orders

SELECT
	COUNT(*)
FROM orders

-- 4. pizza sizes

SELECT 
	DISTINCT size
FROM pizzas

-- 5. Pizza Prices

SELECT 
	DISTINCT price
FROM pizzas

-- 6. Pizza Categories

SELECT 
	DISTINCT category
FROM pizza_details

-- 7. How many pizzas are there in the menu

SELECT 
	COUNT(DISTINCT pizza_type_id)
FROM pizza_details


-- -------------------------
-- BUSINES QUESTIONS --
-- -------------------------

-- 1. What is the total sales for each year and month

SELECT
	EXTRACT(YEAR FROM date) as year,
	EXTRACT(MONTH FROM date) as month,
	COUNT(*) AS total_sales_quantity
FROM orders
GROUP BY 1,2
ORDER BY 2

-- 2. What is the total sales overall

SELECT 
	ROUND(SUM(od.quantity * p.price):: NUMERIC,1) as Total_revenue
FROM order_details od
LEFT JOIN pizzas p on od.pizza_id = p.pizza_id

-- 3. What is the distribution of sales across different product sizes?

SELECT 
	size,
	COUNT(*) AS total_order
FROM order_details od
LEFT JOIN pizzas p ON od.pizza_id = p.pizza_id
GROUP BY 1
ORDER BY 2 DESC

-- 4. During which part of the day are most pizzas sold?

ALTER TABLE orders
ALTER COLUMN time TYPE TIME USING time::TIME;


SELECT
	CASE
    	WHEN EXTRACT(HOUR FROM o.time) >= 8 AND EXTRACT(HOUR FROM o.time) < 16 THEN 'Morning'
    	WHEN EXTRACT(HOUR FROM o.time) >= 16 AND EXTRACT(HOUR FROM o.time) < 22 THEN 'Afternoon'
    	ELSE 'Night'
	END AS part_of_day,
	COUNT(od.*)
FROM orders o 
JOIN order_details od ON o.order_id = od.order_id
GROUP BY 1

-- 5. Which category generate the most revenue

SELECT
	pd.category,
	ROUND(SUM(p.price * od.quantity):: NUMERIC,1) AS total_revenue
FROM pizza_details pd
JOIN pizzas p ON pd.pizza_type_id = p.pizza_type_id
JOIN order_details od ON p.pizza_id = od.pizza_id
GROUP BY 1
ORDER BY 2 DESC

-- 6. What is the top 10 most ordered Pizzas name

SELECT
	pd.name,
	COUNT(od.quantity)
FROM order_details od
LEFT JOIN pizzas p ON od.pizza_id = p.pizza_id
LEFT JOIN pizza_details pd ON p.pizza_type_id = pd.pizza_type_id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10

-- 7. Most ordered Pizza size for each pizzas 

SELECT
	p.size,
	SUM(od.quantity)
FROM order_details od
JOIN pizzas p ON od.pizza_id = p.pizza_id
GROUP BY 1
ORDER BY 2 DESC

-- 8- Which days of the week have the highest and lowest total sales?

SELECT
	EXTRACT(DOW FROM date) as day_of_week,
	TRIM(TO_CHAR(date, 'Day')) AS day_name,
	ROUND(SUM(p.price * od.quantity)::NUMERIC, 2) AS total_sales
FROM orders o
LEFT JOIN order_details od ON o.order_id = od.order_id
JOIN pizzas p ON p.pizza_id = od.pizza_id
GROUP BY 1,2
ORDER BY 3 DESC

-- 9- What is the trend of daily/weekly/monthly sales over time?

SELECT
	EXTRACT(MONTH FROM date) as month,
	EXTRACT(WEEK FROM date) as week,
	EXTRACT(DAY FROM date) as day,
	ROUND(SUM(p.price * od.quantity)::NUMERIC, 2) AS total_sales
FROM orders o
LEFT JOIN order_details od ON o.order_id = od.order_id
LEFT JOIN pizzas p ON od.pizza_id = p.pizza_id
GROUP BY 1,2,3
ORDER BY 1,2,3

-- 10-What are the total sales and number of pizzas sold per day?

SELECT
	TRIM(TO_CHAR(date,'Day')),
	ROUND(SUM(p.price * od.quantity)::NUMERIC, 2) AS total_sales,
	COUNT(od.quantity) as pizzas_sold
FROM orders o
LEFT JOIN order_details od ON o.order_id = od.order_id
LEFT JOIN pizzas p ON od.pizza_id = p.pizza_id
GROUP BY 1
ORDER BY 3 DESC

-- 11- What are the least popular pizza types and sizes for each type

WITH cte as(
SELECT 
	pd.category,
	p.size,
	COUNT(od.quantity) as Total_order,
	RANK() OVER(PARTITION BY pd.category ORDER BY COUNT(od.quantity) DESC) AS rank
FROM pizza_details pd
LEFT JOIN pizzas P ON pd.pizza_type_id = p.pizza_type_id
LEFT JOIN order_details od ON p.pizza_id = od.pizza_id
GROUP BY 1,2
ORDER BY 1, 4 ASC
)
SELECT 
	category,
	size,
	total_order
FROM cte
WHERE rank = 1

-- 12- What is the average order value (AOV)?

SELECT
	ROUND(SUM(p.price * od.quantity)::NUMERIC / (SELECT COUNT(*) FROM orders),2)
	AS AOV
FROM orders o 
JOIN order_details od ON o.order_id = od.order_id
JOIN pizzas p ON od.pizza_id = p.pizza_id

-- 13- Which pizza types or sizes contribute the most to total revenue?	

SELECT
	pd.category,
	ROUND((SUM(p.price * od.quantity) /
	(SELECT SUM(p2.price * od2.quantity)
	FROM order_details od2
	LEFT JOIN pizzas p2 ON od2.pizza_id = p2.pizza_id)):: NUMERIC,2) AS Cont_total_sales
FROM pizza_details pd
LEFT JOIN pizzas p ON pd.pizza_type_id = p.pizza_type_id
LEft JOIN order_details od ON p.pizza_id = od.pizza_id
GROUP BY 1
ORDER BY 2 DESC

-- 14- How much revenue does each category generate per month?

SELECT
	pd.category,
	EXTRACT(MONTH FROM o.date) as month,
	ROUND(SUM(p.price * od.quantity)::NUMERIC, 2) AS total_sales
FROM orders o
LEFT JOIN order_details od ON o.order_id = od.order_id
LEFT JOIN pizzas p ON od.pizza_id = p.pizza_id
LEFT JOIN pizza_details pd ON p.pizza_type_id = pd.pizza_type_id
GROUP BY 1,2
ORDER BY 1,2

-- 15- What is the average number of pizzas per order?

SELECT
	ROUND(SUM(od.quantity) / COUNT(o.*),2) as pizza_per_order
FROM orders o
LEFT JOIN order_details od ON o.order_id = od.order_id

-- 16- How do weekend sales compare to weekday sales?

SELECT
	CASE
		WHEN EXTRACT(DOW FROM o.date) IN(0,6) THEN 'Weekend'
		ELSE 'Weekday'
	END AS day_type,
	ROUND(SUM(p.price * od.quantity)::NUMERIC, 2) AS total_sales
FROM orders o
JOIN order_details od ON o.order_id = od.order_id
JOIN pizzas p ON od.pizza_id = p.pizza_id
GROUP BY 1
ORDER BY 2 DESC

-- 17- Are there any seasonal trends (e.g., higher sales in December)?

SELECT
    TO_CHAR(o.date, 'Month') AS month_name,
    EXTRACT(MONTH FROM o.date) AS month_num,
    ROUND(SUM(p.price * od.quantity)::NUMERIC, 2) AS total_sales
FROM orders o
JOIN order_details od ON o.order_id = od.order_id
JOIN pizzas p ON od.pizza_id = p.pizza_id
GROUP BY 1, 2
ORDER BY month_num;















