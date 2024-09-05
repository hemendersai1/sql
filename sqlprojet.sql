create database pizza_project;
use pizza_project;
-- let's  import the csv files
-- Now understand each table (all columns)
select * from order_details;  -- order_details_id	order_id	pizza_id	quantity;

select * from pizzas; -- pizza_id, pizza_type_id, size, price

select * from orders;  -- order_id, date, time;

select * from pizza_types;  -- pizza_type_id, name, category, ingredients;
/*
Basic:
Retrieve the total number of orders placed.
Calculate the total revenue generated from pizza sales.
Identify the highest-priced pizza.
Identify the most common pizza size ordered.
List the top 5 most ordered pizza types along with their quantities.


Intermediate:
Join the necessary tables to find the total quantity of each pizza category ordered.
Determine the distribution of orders by hour of the day.
Join relevant tables to find the category-wise distribution of pizzas.
Group the orders by date and calculate the average number of pizzas ordered per day.
Determine the top 3 most ordered pizza types based on revenue.

Advanced:
Calculate the percentage contribution of each pizza type to total revenue.
Analyze the cumulative revenue generated over time.
Determine the top 3 most ordered pizza types based on revenue for each pizza category.

*/


-- Retrieve the total number of orders placed.
select count(distinct order_id) as 'Total Orders' from orders;

-- Calculate the total revenue generated from pizza sales.

-- to see the details
select order_details.pizza_id, order_details.quantity, pizzas.price
from order_details 
join pizzas on pizzas.pizza_id = order_details.pizza_id;

select cast(sum(order_details.quantity * pizzas.price) as decimal(10,2)) as 'Total Revenue'
from order_details 
join pizzas on pizzas.pizza_id = order_details.pizza_id;


-- Identify the highest-priced pizza.

SELECT pizza_types.name AS 'Pizza Name', CAST(pizzas.price AS DECIMAL(10,2)) AS 'Price' 
FROM pizzas 
JOIN pizza_types ON pizza_types.pizza_type_id = pizzas.pizza_type_id 
ORDER BY price DESC 
LIMIT 1;


-- Identify the most common pizza size ordered.

select pizzas.size, count(distinct order_id) as 'No of Orders', sum(quantity) as 'Total Quantity Ordered' 
from order_details
join pizzas on pizzas.pizza_id = order_details.pizza_id
-- join pizza_types on pizza_types.pizza_type_id = pizzas.pizza_type_id
group by pizzas.size
order by count(distinct order_id) desc;



-- List the top 5 most ordered pizza types along with their quantities.

SELECT pizza_types.name AS 'Pizza', SUM(order_details.quantity) AS 'Total Ordered'
FROM order_details
JOIN pizzas ON pizzas.pizza_id = order_details.pizza_id
JOIN pizza_types ON pizza_types.pizza_type_id = pizzas.pizza_type_id
GROUP BY pizza_types.name 
ORDER BY SUM(order_details.quantity) DESC 
LIMIT 5;




-- Join the necessary tables to find the total quantity of each pizza category ordered.

SELECT pizza_types.category, SUM(order_details.quantity) AS 'Total Quantity Ordered'
FROM order_details
JOIN pizzas ON pizzas.pizza_id = order_details.pizza_id
JOIN pizza_types ON pizza_types.pizza_type_id = pizzas.pizza_type_id
GROUP BY pizza_types.category 
ORDER BY SUM(order_details.quantity) DESC 
LIMIT 5;



-- Determine the distribution of orders by hour of the day.

SELECT HOUR(time) AS 'Hour of the Day', COUNT(DISTINCT order_id) AS 'No of Orders'
FROM orders
GROUP BY HOUR(time)
ORDER BY COUNT(DISTINCT order_id) DESC;




-- find the category-wise distribution of pizzas

SELECT category, COUNT(DISTINCT pizza_type_id) AS 'No of Pizzas'
FROM pizza_types
GROUP BY category
ORDER BY COUNT(DISTINCT pizza_type_id);



-- Calculate the average number of pizzas ordered per day.

WITH cte AS (
    SELECT orders.date AS `Date`, SUM(order_details.quantity) AS `Total Pizza Ordered That Day`
    FROM order_details
    JOIN orders ON order_details.order_id = orders.order_id
    GROUP BY orders.date
)
SELECT `Date`, `Total Pizza Ordered That Day`
FROM cte;

SELECT AVG(`Total Pizza Ordered That Day`) AS `Avg Number of Pizzas Ordered Per Day`
FROM (
    SELECT orders.date AS `Date`, SUM(order_details.quantity) AS `Total Pizza Ordered That Day`
    FROM order_details
    JOIN orders ON order_details.order_id = orders.order_id
    GROUP BY orders.date
) AS pizzas_ordered;



-- Determine the top 3 most ordered pizza types based on revenue.

SELECT pizza_types.name, SUM(order_details.quantity * pizzas.price) AS `Revenue from Pizza`
FROM order_details
JOIN pizzas ON pizzas.pizza_id = order_details.pizza_id
JOIN pizza_types ON pizza_types.pizza_type_id = pizzas.pizza_type_id
GROUP BY pizza_types.name
ORDER BY SUM(order_details.quantity * pizzas.price) DESC
LIMIT 3;

-- try doing it using window functions also


/*
Advanced:
Calculate the percentage contribution of each pizza type to total revenue.
Analyze the cumulative revenue generated over time.
Determine the top 3 most ordered pizza types based on revenue for each pizza category.
*/


-- Calculate the percentage contribution of each pizza type to total revenues


select pizza_types.category, 
concat(cast((sum(order_details.quantity*pizzas.price) /
(select sum(order_details.quantity*pizzas.price) 
from order_details 
join pizzas on pizzas.pizza_id = order_details.pizza_id 
))*100 as decimal(10,2)), '%')
as 'Revenue contribution from pizza'
from order_details 
join pizzas on pizzas.pizza_id = order_details.pizza_id
join pizza_types on pizza_types.pizza_type_id = pizzas.pizza_type_id
group by pizza_types.category;
-- order by [Revenue from pizza] desc

-- revenue contribution from each pizza by pizza name
SELECT pizza_types.name, 
       CONCAT(CAST((SUM(order_details.quantity * pizzas.price) /
           (SELECT SUM(order_details.quantity * pizzas.price)
            FROM order_details
            JOIN pizzas ON pizzas.pizza_id = order_details.pizza_id
           )) * 100 AS DECIMAL(10,2)), '%') AS `Revenue Contribution from Pizza`
FROM order_details
JOIN pizzas ON pizzas.pizza_id = order_details.pizza_id
JOIN pizza_types ON pizza_types.pizza_type_id = pizzas.pizza_type_id
GROUP BY pizza_types.name
ORDER BY CAST(SUM(order_details.quantity * pizzas.price) /
           (SELECT SUM(order_details.quantity * pizzas.price)
            FROM order_details
            JOIN pizzas ON pizzas.pizza_id = order_details.pizza_id
           ) * 100 AS DECIMAL(10,2)) DESC;


-- Analyze the cumulative revenue generated over time.
-- use of aggregate window function (to get the cumulative sum)
with cte as (
select date as 'Date', cast(sum(quantity*price) as decimal(10,2)) as Revenue
from order_details 
join orders on order_details.order_id = orders.order_id
join pizzas on pizzas.pizza_id = order_details.pizza_id
group by date
-- order by [Revenue] desc
)
select Date, Revenue, sum(Revenue) over (order by date) as 'Cumulative Sum'
from cte 
group by date, Revenue;


-- Determine the top 3 most ordered pizza types based on revenue for each pizza category.

WITH cte AS (
    SELECT category, 
           name, 
           CAST(SUM(order_details.quantity * pizzas.price) AS DECIMAL(10,2)) AS `Revenue`
    FROM order_details
    JOIN pizzas ON pizzas.pizza_id = order_details.pizza_id
    JOIN pizza_types ON pizza_types.pizza_type_id = pizzas.pizza_type_id
    GROUP BY category, name
)

-- order by category, name, Revenue desc

, cte1 as (
select category, name, Revenue,
rank() over (partition by category order by Revenue desc) as rnk
from cte 
)
select category, name, Revenue
from cte1 
where rnk in (1,2,3)
order by category, name, Revenue