/* --------------------
   Case Study Questions
   --------------------*/
CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

# 1. What is the total amount each customer spent at the restaurant?

SELECT
     customer_id,
     SUM(price) AS total_amount
FROM dannys_diner.menu m INNER JOIN dannys_diner.sales s
ON m.product_id = s.product_id
GROUP BY customer_id


# 2. How many days has each customer visited the restaurant?

SELECT 
     customer_id,
     COUNT(DISTINCT order_date) AS order_count
FROM dannys_diner.sales 
GROUP BY customer_id


# 3. What was the first item from the menu purchased by each customer?

WITH CTE AS(SELECT 
     customer_id,
     order_date,
     product_name, 
     RANK() OVER(PARTITION BY customer_id ORDER BY order_date) AS rk
FROM dannys_diner.menu m INNER JOIN dannys_diner.sales s
ON m.product_id = s.product_id)

SELECT 
     customer_id,
     product_name
FROM CTE
WHERE rk = 1


# 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT
     product_name, 
     COUNT(*) AS  total_count_of_purchases
FROM dannys_diner.menu m INNER JOIN dannys_diner.sales s
ON m.product_id = s.product_id
GROUP BY product_name


# 5. Which item was the most popular for each customer?

WITH CTE AS(SELECT
     customer_id, 
     product_name,
     COUNT(*) AS total_orders,
     RANK() OVER(PARTITION BY customer_id ORDER BY COUNT(s.customer_id) DESC) AS rk
FROM dannys_diner.menu m INNER JOIN dannys_diner.sales s
ON m.product_id = s.product_id
GROUP BY customer_id, product_name)

SELECT 
     customer_id,
     product_name,
     total_orders
FROM CTE
WHERE rk = 1


# 6. Which item was purchased first by the customer after they became a member?

WITH CTE AS(SELECT 
     s.customer_id,
     order_date,
     m.product_id,
     product_name, 
     join_date,
     ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY order_date) AS rn
FROM dannys_diner.members mem INNER JOIN dannys_diner.sales s
ON mem.customer_id = s.customer_id INNER JOIN dannys_diner.menu m ON s.product_id = m. product_id
WHERE order_date >= join_date)

SELECT 
     customer_id,
     product_name
FROM CTE
WHERE rn = 1


# 7. Which item was purchased just before the customer became a member?

WITH CTE AS(SELECT 
     s.customer_id,
     order_date,
     m.product_id,
     product_name, 
     join_date,
     RANK() OVER(PARTITION BY s.customer_id ORDER BY order_date DESC) AS rn
FROM dannys_diner.members mem INNER JOIN dannys_diner.sales s
ON mem.customer_id = s.customer_id INNER JOIN dannys_diner.menu m ON s.product_id = m. product_id
WHERE order_date < join_date)

SELECT 
     customer_id,
     product_name
FROM CTE
WHERE rn = 1


# 8. What is the total items and amount spent for each member before they became a member?

SELECT
     mem.customer_id,
     COUNT(s.product_name) AS total_items,
     SUM(price) AS amount_spent
FROM dannys_diner.members mem INNER JOIN dannys_diner.sales s
ON mem.customer_id = s.customer_id INNER JOIN dannys_diner.menu m ON s.product_id = m. product_id
WHERE order_date < join_date
GROUP BY mem.customer_id


# 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT
     customer_id,
     SUM(CASE 
        WHEN product_name = 'sushi' THEN price*20 
        ELSE price*10
        END) AS Total_points
FROM dannys_diner.menu m INNER JOIN dannys_diner.sales s
ON m.product_id = s.product_id
GROUP BY customer_id
ORDER BY customer_id


# 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

SELECT
     mem.customer_id,
     SUM(CASE
            WHEN order_date <= order_date + INTERVAL '6 DAYS' THEN price*20
END) AS Total_points
FROM dannys_diner.members mem INNER JOIN dannys_diner.sales s
ON mem.customer_id = s.customer_id INNER JOIN dannys_diner.menu m ON s.product_id = m. product_id
WHERE order_date >= join_date AND EXTRACT(MONTH FROM order_date) = 01
GROUP BY mem.customer_id
ORDER BY mem.customer_id
