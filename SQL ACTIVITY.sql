/* Activity 1*/
CREATE DATABASE MondayCoffee;

USE MondayCoffee;

CREATE TABLE City (
City_ID INT PRIMARY KEY,
City_Name VARCHAR(100),
Population BIGINT,
Estimated_Rent decimal(12,2),
City_Rank int
);

CREATE TABLE customers (
  customer_id INT PRIMARY KEY,
  customer_name VARCHAR(150),
  city_id INT,
  FOREIGN KEY (city_id) REFERENCES city(city_id)
);

CREATE TABLE products (
  product_id INT PRIMARY KEY,
  product_name VARCHAR(150),
  price DECIMAL(10,2)
);

CREATE TABLE sales (
  sale_id INT PRIMARY KEY,
  sale_date DATE,
  product_id INT,
  quantity INT,
  customer_id INT,
  total_amount DECIMAL(12,2),
  rating INT,
  FOREIGN KEY (product_id) REFERENCES products(product_id),
  FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);
DROP TABLE Sales;

SELECT * FROM Sales;

/*Activity 2*/

/*Identifying null values*/

SELECT 
SUM(customer_id IS NULL) AS null_customer_id,
SUM(customer_name IS NULL) AS null_customer_name,
SUM(city_id IS NULL) AS null_city_id
FROM customers;

SELECT
  SUM(product_id IS NULL) AS null_product_id,
  SUM(product_name IS NULL) AS null_product_name,
  SUM(price IS NULL) AS null_price
FROM products;

SELECT
  SUM(sale_id IS NULL) AS null_sale_id,
  SUM(sale_date IS NULL) AS null_sale_date,
  SUM(product_id IS NULL) AS null_product_id,
  SUM(quantity IS NULL) AS null_quantity,
  SUM(customer_id IS NULL) AS null_customer_id,
  SUM(total_amount IS NULL) AS null_total_amount,
  SUM(rating IS NULL) AS null_rating
FROM sales;

/*For dduplicate entries*/
	
SELECT customer_id, COUNT(*) AS cnt
FROM customers
GROUP BY customer_id
HAVING cnt >1;

SELECT customer_name, city_id, COUNT(*) AS cnt
FROM customers
GROUP BY customer_name, city_id
HAVING cnt > 1;

/*For Mismatch*/

SELECT
  s.sale_id,
  s.product_id,
  s.quantity,
  p.price,
  s.total_amount,
  (p.price * s.quantity) AS expected_total,
  (s.total_amount - (p.price * s.quantity)) AS diff
FROM sales s
JOIN products p ON p.product_id = s.product_id
WHERE s.total_amount <> (p.price * s.quantity);

/*Activity 3*/

CREATE OR REPLACE VIEW sales_report AS
SELECT
s.sale_id,
s.sale_date,
c.customer_id,
c.customer_name,
  ci.city_id,
  ci.city_name,
  p.product_id,
  p.product_name,
  p.price,
  s.quantity,
  s.total_amount,
  s.rating
FROM sales s
JOIN customers c ON c.customer_id = s.customer_id
JOIN city ci ON ci.city_id = c.city_id
JOIN products p ON p.product_id = s.product_id;

SELECT * FROM sales_report LIMIT 10;

/*Activity 4*/

/*Total Sales Per City*/

SELECT city_name, SUM(total_amount) AS total_sales
FROM sales_report
GROUP BY city_name
ORDER BY total_sales DESC;

/*Total Transactions Per City*/

SELECT city_name, COUNT(*) AS total_transactions
FROM sales_report
GROUP BY city_name
ORDER BY total_transactions DESC;

/*Unique Customer per City*/

SELECT city_name, COUNT(distinct customer_id) AS unique_customers
FROM sales_report
GROUP BY city_name
ORDER BY unique_customers DESC;

/*Average Order Value per City*/

SELECT city_name, AVG(total_amount) AS avg_order_value
FROM sales_report
GROUP BY city_name
ORDER BY avg_order_value DESC;

/*Product Demand per City (Units Sold) */

SELECT 
city_name,
product_name,
SUM(quantity) AS total_units_sold
FROM sales_report
GROUP BY city_name, product_name
ORDER BY city_name, total_units_sold DESC;

/*Monthly Sales Trend */

SELECT 
DATE_FORMAT(sale_date, '%Y-%m-01') AS month_start,
SUM(total_amount) AS monthly_sales
FROM sales_report
GROUP BY month_start
ORDER BY month_start;

/*Customer Rating Analysis (avg rating per city) */

SELECT 
city_name,
AVG(rating) AS avg_rating
FROM sales_report
GROUP BY city_name
ORDER BY avg_rating DESC;

/* Activity 5*/

WITH city_kpis AS (
SELECT 
city_name,
SUM(total_amount) AS total_sales,
COUNT(*) AS order_count,
COUNT(DISTINCT customer_id) AS unique_customers
FROM sales_report
GROUP BY city_name
),
ranked AS (
SELECT
*,
DENSE_RANK() OVER (ORDER BY total_sales DESC) AS r_sales,
DENSE_RANK() OVER (ORDER BY unique_customers DESC) AS r_customers,
DENSE_RANK() OVER (ORDER BY order_count DESC) AS r_orders
FROM city_kpis
)
SELECT
city_name,
total_sales,
unique_customers,
order_count,
(r_sales + r_customers + r_orders) AS overall_rank_score
FROM ranked
ORDER BY overall_rank_score, total_sales DESC
LIMIT 3;

 WITH city_kpis AS (
 SELECT 
 ci.city_name,
 ci.population,
 ci.estimated_rent,
 SUM(sr.total_amount) AS total_sales,
 COUNT(*) AS order_count,
 COUNT(DISTINCT sr.customer_id) AS unique_customers
 FROM sales_report sr
 JOIN city ci ON ci.city_name = sr.city_name
 GROUP BY ci.city_name, ci.population, ci.estimated_rent
 ),
 ranked AS (
 SELECT 
 *,
 DENSE_RANK() OVER (ORDER BY total_sales DESC) AS r_sales,
 DENSE_RANK() OVER (ORDER BY unique_customers DESC) AS r_customers,
 DENSE_RANK() OVER (ORDER BY order_count DESC) AS r_orders
 FROM city_kpis
 )
 SELECT
 city_name, total_sales, unique_customers, order_count,
 estimated_rent,
 (total_sales / NULLIF(estimated_rent,0)) AS sales_per_rent,
 (r_sales + r_customers + r_orders) AS overall_rank_score
 FROM ranked
 ORDER BY overall_rank_score, total_sales DESC
 LIMIT 3;





