/*
====================================================
Project Title : Pizza Sales Analysis
Author        : Murasoli
Tools Used    : MySQL, Power BI, PowerPoint
Domain        : Food & Beverage Analytics
====================================================

Project Overview:
This project analyzes pizza sales data to evaluate
business performance, customer ordering behavior,
sales trends, and revenue generation.

Objectives:
1. Calculate key business KPIs:
   - Total Revenue
   - Total Orders
   - Average Order Value
   - Total Pizzas Sold

2. Identify top-performing and low-performing pizzas.

3. Analyze sales trends by:
   - Category
   - Pizza Size
   - Day of Week
   - Time of Day

4. Understand customer purchasing patterns.

5. Generate actionable business insights using SQL
   and visualize findings in Power BI.

Dataset Tables:
- orders
- order_details
- pizzas
- pizza_types

====================================================
*/

-- ==================================================
-- SECTION 1: Data Cleaning & Preparation
-- ==================================================

-- Create Database
CREATE DATABASE data_analyst_project;
USE data_analyst_project;

-- Check for NULL values in Orders Table
SELECT *
FROM orders
WHERE order_id IS NULL
   OR date IS NULL
   OR time IS NULL;

-- Check for NULL values in Order Details Table
SELECT *
FROM order_details
WHERE order_details_id IS NULL
   OR order_id IS NULL
   OR pizza_id IS NULL
   OR quantity IS NULL;

-- Check for NULL values in Pizzas Table
SELECT *
FROM pizzas
WHERE pizza_id IS NULL
   OR pizza_type_id IS NULL
   OR size IS NULL
   OR price IS NULL;
   
-- Check for NULL values in Pizza Types Table
SELECT *
FROM pizza_types
WHERE pizza_type_id IS NULL
   OR name IS NULL
   OR category IS NULL
   OR ingredients IS NULL;


-- Check for duplicate order IDs
SELECT order_id, COUNT(*) AS duplicate_count
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;

-- Verify record counts
SELECT COUNT(*) AS total_order_details
FROM order_details;

SELECT COUNT(*) AS total_orders
FROM orders;

SELECT COUNT(*) AS total_pizza_types
FROM pizza_types;

SELECT COUNT(*) AS total_pizzas
FROM pizzas;


-- Data Type Standardization
alter table order_details modify pizza_id varchar(30);

alter table orders modify date date;
alter table orders modify time time;

alter table pizza_types modify pizza_type_id varchar(50);
alter table pizza_types modify name varchar(100);
alter table pizza_types modify category varchar(100);
alter table pizza_types modify ingredients varchar(200);

alter table pizzas modify pizza_id varchar(50);
alter table pizzas modify pizza_type_id varchar(100);
alter table pizzas modify size varchar(10);
alter table pizzas modify price decimal(10,2);

-- Verify Updated Structure
describe order_details;
describe orders;
describe pizza_types;
describe pizzas;

-- ==================================================
-- SECTION 2: Business Analysis
-- ==================================================

-- Query 1: Retrieve the total number of orders placed.

SELECT 
    COUNT(order_id) AS total_orders
FROM
    orders;
    
-- Query 2: Calculate the total revenue generated from pizza sales. 

SELECT 
    ROUND(SUM(od.quantity * pz.price)) as total_revenue
FROM
    order_details od
        JOIN
    pizzas pz ON od.pizza_id = pz.pizza_id;

    
-- Query 3: Identify the highest-priced pizza.

SELECT 
    pt.name, pz.price
FROM
    pizza_types pt  
        JOIN
    pizzas pz ON pt.pizza_type_id = pz.pizza_type_id
ORDER BY pz.price DESC
limit 1;

-- Query 4: Identify the most common pizza size ordered.

SELECT 
    COUNT(od.order_details_id) AS total_orders, pz.size
FROM
    order_details od
        JOIN
    pizzas pz ON od.pizza_id = pz.pizza_id
GROUP BY pz.size
ORDER BY total_orders DESC
LIMIT 1;

-- Query 5: List the top 5 most ordered pizza types along with their quantities.

SELECT 
    pt.name AS pizzatype, SUM(od.quantity) AS total_qnty
FROM
    pizzas pz
        JOIN
    order_details od ON pz.pizza_id = od.pizza_id
        JOIN
    pizza_types pt ON pt.pizza_type_id = pz.pizza_type_id
GROUP BY pt.name
ORDER BY total_qnty DESC
LIMIT 5;

-- Query 6: Join the necessary tables to find the total quantity of each pizza category ordered

SELECT 
    pt.category, SUM(od.quantity) AS total_qnty
FROM
    pizzas pz
        JOIN
    pizza_types pt ON pt.pizza_type_id = pz.pizza_type_id
        JOIN
    order_details od ON od.pizza_id = pz.pizza_id
GROUP BY pt.category;

-- Query 7: Determine the distribution of orders by hour of the day.

SELECT 
    HOUR(time) AS hour, COUNT(order_id) AS order_count
FROM
    orders
GROUP BY HOUR(time)
ORDER BY hour;

-- Query 8: Join relevant tables to find the category-wise distribution of pizzas.

SELECT 
    category, COUNT(name) as count
FROM
    pizza_types
GROUP BY category;

-- Query 9: Group the orders by date and calculate the average number of pizzas ordered per day.

SELECT 
    ROUND(AVG(quantity), 0) as avg_quantity
FROM
    (SELECT 
        os.date, SUM(od.quantity) AS quantity
    FROM
        orders os
    JOIN order_details od ON od.order_id = os.order_id
    GROUP BY os.date) AS order_qnty;
    
-- Query 10: Determine the top 3 most ordered pizza types based on revenue.

SELECT 
    pt.name, SUM(od.quantity * pz.price) AS revenue
FROM
    pizza_types pt
        JOIN
    pizzas pz ON pz.pizza_type_id = pt.pizza_type_id
        JOIN
    order_details od ON od.pizza_id = pz.pizza_id
GROUP BY pt.name
ORDER BY revenue DESC
LIMIT 3;

-- Query 11: Calculate the percentage contribution of each pizza category to total revenue.

SELECT 
    pt.category,
    ROUND(SUM(od.quantity * pz.price) / (SELECT 
                    ROUND(SUM(od.quantity * pz.price), 2) AS total_revenue
                FROM
                    order_details od
                        JOIN
                    pizzas pz ON od.pizza_id = pz.pizza_id) * 100,
            2) AS revenue
FROM
    pizza_types pt
        JOIN
    pizzas pz ON pt.pizza_type_id = pz.pizza_type_id
        JOIN
    order_details od ON od.pizza_id = pz.pizza_id
GROUP BY pt.category
ORDER BY revenue DESC;

-- Query 12: Analyze the cumulative revenue generated over time.

SELECT
    date,
    SUM(revenue) OVER (ORDER BY date) AS cum_revenue
FROM
(
    SELECT
        os.date,
        SUM(od.quantity * pz.price) AS revenue
    FROM order_details od
    JOIN pizzas pz
        ON pz.pizza_id = od.pizza_id
    JOIN orders os
        ON os.order_id = od.order_id
    GROUP BY os.date
) AS sales;

-- Query 13: Determine the top 3 most ordered pizza types based on revenue for each pizza category.

SELECT category,name,revenue
FROM (
    SELECT category,name,revenue,
           RANK() OVER(PARTITION BY category ORDER BY revenue DESC) AS rn
    FROM (
        SELECT pt.category,pt.name,
               SUM(od.quantity*pz.price) AS revenue
        FROM pizza_types pt
        JOIN pizzas pz
            ON pz.pizza_type_id=pt.pizza_type_id
        JOIN order_details od
            ON od.pizza_id=pz.pizza_id
        GROUP BY pt.category,pt.name
    ) a
) b
WHERE rn<=3
ORDER BY category,revenue DESC;


-- ==================================================
-- SECTION 3: Key Insights
-- ==================================================

/*
1. Large-sized pizzas generated the highest revenue,
   making them the most profitable size category.

2. The Classic pizza category contributed the highest
   share of total sales volume.

3. Customer orders peaked during lunch and evening hours,
   indicating the busiest periods of the day.

4. The Thai Chicken Pizza generated the highest revenue
   among all pizza types.

5. Average order value remained strong, reflecting
   healthy customer spending patterns.

6. A small number of pizza types contributed a large
   portion of total revenue, highlighting key products.

7. Low-performing pizzas may require promotional
   strategies or menu optimization.

8. Revenue trends showed consistent sales performance
   throughout the analysis period.
*/
