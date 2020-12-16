--Creating Database
--Creating Orders table
DROP TABLE IF EXISTS orders;

CREATE TABLE orders (
	order_id VARCHAR(150) UNIQUE PRIMARY KEY, 
	lat Decimal(9,6) NOT NULL,
	lng Decimal(9,6) NOT NULL,
	dow INT4 NOT NULL,
	promised_time TIME NOT NULL,
	actual_time TIME NOT NULL, 
	on_demand BOOL NOT NULL, 
	picker_id VARCHAR(150) NOT NULL,
	driver_id VARCHAR(150) NOT NULL,
	store_branch_id VARCHAR(150) NOT NULL,
	total_minutes FLOAT8
);

--Loading order table to POSTGRES
COPY orders(order_id, lat, lng, dow, promised_time, actual_time, on_demand, picker_id, driver_id, store_branch_id, total_minutes)
FROM 'D:\data\orders.csv'
DELIMITER ','
CSV HEADER;

--Creating Order_Product table
DROP TABLE IF EXISTS order_product;

CREATE TABLE order_product (
	order_id VARCHAR(150) NOT NULL, 
	product_id VARCHAR(150) NOT NULL,
	quantity FLOAT NOT NULL,
	quantity_found FLOAT NOT NULL,
	buy_unit VARCHAR(30)
);

--Loading order_product table to POSTGRES
COPY order_product(order_id, product_id, quantity, quantity_found, buy_unit)
FROM 'D:\data\order_product.csv'
DELIMITER ','
CSV HEADER;

--Creating Shoppers Table
DROP TABLE IF EXISTS shoppers;

CREATE TABLE shoppers (
	shopper_id VARCHAR(150) NOT NULL,
	seniority VARCHAR(150) NOT NULL,
	found_rate FLOAT,
	picking_speed FLOAT NOT NULL,
	accepted_rate FLOAT, 
	rating FLOAT
);

--Loading shoppers table to POSTGRES
COPY shoppers(shopper_id, seniority, found_rate, picking_speed, accepted_rate, rating)
FROM 'D:\data\shoppers.csv'
DELIMITER ','
CSV HEADER;

SELECT *
FROM shoppers;

--Creating Storebranch Table
DROP TABLE IF EXISTS storebranch;

CREATE TABLE storebranch (
	store_branch_id VARCHAR(150) NOT NULL,
	store VARCHAR(150) NOT NULL, 
	lat Decimal(9,6) NOT NULL,
	lng Decimal(9,6) NOT NULL
);

--Loading storebranch table to POSTGRES
COPY storebranch(store_branch_id, store, lat, lng)
FROM 'D:\data\storebranch.csv'
DELIMITER ','
CSV HEADER;

-----------------------------------------
----ANALYTICS using POSTGRES SQL---------
-----------------------------------------
-- 1. Calculate the number of orders per day of the week, distinguishing if the orders are on_demand.
SELECT dow, COUNT(order_id) AS num_of_orders
FROM orders
WHERE on_demand = true
GROUP BY dow
ORDER BY dow ASC;

-- 2. Calculate the average quantity of distinct products that each order has, grouped by store
WITH t AS(
	SELECT  quantity, store_branch_id
	FROM orders as o 
	INNER JOIN order_product as p
	ON o.order_id = p.order_id
)
SELECT AVG(quantity) AS avg_quantity, store
FROM t
LEFT JOIN storebranch AS s
ON t.store_branch_id = s.store_branch_id
GROUP BY store;

-- 3. Calculate the average found rate(*) of the orders grouped by the product format and day of the week.
SELECT dow, AVG(quantity_found / quantity) AS found_ration, buy_unit AS product_format
FROM orders AS o
INNER JOIN order_product AS op
ON o.order_id = op.order_id
GROUP BY dow, buy_unit
ORDER BY dow ASC;

-- 4. Calculate the average error and mean squared error of our estimation model for each hour of the day.
-- Average Error (Also known as Mean Error MAE)
/* Calculating MAE and MSE in SQL is as simple as:
 SELECT AVG(y_pred - y) AS me FROM ... (Mean Error)
 SELECT AVG(POWER(y - y_pred, 2)) AS mse FROM ... (Mean Square Error)
 
 However, I do not have a model. I have the target column that is used for the model, but I was not provided with
 an actual algorithm or results from the model. 
 
 Therefore, to answer this question, I will use another tool. 
 I will be using python to run a regression model to predict the total minutes that is asked in the question by the 
 stakeholder.
 
 To review the answer to this question:
 - GO TO question_4.html to see the values for ME and MSE
 */

-- 5. Calculate the number of orders in which the picker_id and driver_id are different.
SELECT COUNT(picker_id)
FROM (
	SELECT picker_id, driver_id
	FROM orders
	WHERE picker_id NOT ILIKE driver_id
) AS temp;


/* Question 4 and 5 do not have a visualization in Tableau. The results from both queries are just a number.
However, there is more story telling that I had gathered in the tableau dashboard. 
To review tableau:
- GO TO BI.twbx