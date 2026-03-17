-- ================================
-- PROJECT: E-Commerce Sales Analysis
-- AUTHOR: Hanisha Vemireddy
-- CONCEPTS: JOINs, CTEs, Window Functions, REGEX, Dates
-- ================================

-- LESSON 1: Basic JOIN

-- query 1: joining multiple tables
SELECT c.full_name,
       o.order_date,
       p.product_name,
       oi.quantity
FROM orders o
JOIN customers c   ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id  = oi.order_id
JOIN products p    ON oi.product_id = p.product_id;

-- query 2: LEFT JOIN to find customers who NEVER ordered:
SELECT c.full_name,
       c.city,
       o.order_id
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;

-- LESSON 2: CTEs


-- query 3: finding total spending per order
WITH order_totals AS (
    SELECT oi.order_id,
           SUM(oi.quantity * p.price) AS order_value
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    GROUP BY oi.order_id
)
SELECT *
FROM order_totals;

-- query 4: Building on previous CTE to bring in customer names
WITH order_totals AS (
    SELECT oi.order_id,
           SUM(oi.quantity * p.price) AS order_value
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    GROUP BY oi.order_id
)
SELECT c.full_name,
       o.status,
       ot.order_value
FROM order_totals ot
JOIN orders o     ON ot.order_id   = o.order_id
JOIN customers c  ON o.customer_id = c.customer_id
ORDER BY ot.order_value DESC;

-- query 5: Chaining two CTEs together (Stepwise  aggregation)
WITH order_totals AS (
    SELECT oi.order_id,
           SUM(oi.quantity * p.price) AS order_value
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    GROUP BY oi.order_id
),
customer_spending AS (
    SELECT c.full_name,
           c.city,
           SUM(ot.order_value) AS total_spent
    FROM order_totals ot
    JOIN orders o    ON ot.order_id   = o.order_id
    JOIN customers c ON o.customer_id = c.customer_id
    GROUP BY c.customer_id, c.full_name, c.city
)
SELECT city,
       full_name,
       total_spent
FROM customer_spending
ORDER BY city, total_spent DESC;

-- LESSON 3: DATE FUNCTIONS

-- query 6: pulling apart the time into units
SELECT order_id,
       order_date,
       DATE(order_date)      AS date_only,
       YEAR(order_date)      AS order_year,
       MONTH(order_date)     AS order_month,
       MONTHNAME(order_date) AS month_name
FROM orders;

-- query 7: getting how many orders per month:
SELECT MONTHNAME(order_date) AS month,
       MONTH(order_date)     AS month_num,
       COUNT(*)              AS total_orders
FROM orders
GROUP BY month, month_num
ORDER BY month_num;


-- query 8: getting how long has each customer been with us:
SELECT full_name,
       signup_date,
       DATEDIFF(NOW(), signup_date) AS days_since_signup
FROM customers
ORDER BY days_since_signup DESC;

-- query 9: getting total revenue per month
WITH monthly_orders AS (
    SELECT o.order_id,
           MONTHNAME(o.order_date) AS month,
           MONTH(o.order_date)     AS month_num,
           oi.quantity,
           p.price
    FROM orders o
    JOIN order_items oi ON o.order_id    = oi.order_id
    JOIN products p     ON oi.product_id = p.product_id
    WHERE o.status = 'delivered'
)
SELECT month,
       COUNT(DISTINCT order_id)        AS total_orders,
       SUM(quantity * price)           AS total_revenue,
       ROUND(AVG(quantity * price), 2) AS avg_order_value
FROM monthly_orders
GROUP BY month, month_num
ORDER BY month_num;

-- LESSON 4: REGEX

-- query 10: regex finding gmail emails
SELECT full_name,
       email
FROM customers
WHERE email REGEXP 'gmail\\.com$';

-- query 11: regex finding names that start with vowel
SELECT full_name,
       city
FROM customers
WHERE full_name REGEXP '^[AEIOUaeiou]';

-- query 12: regex, find emails with underscore in them
SELECT full_name,
       email
FROM customers
WHERE email REGEXP '_';


-- query 13: Combine REGEX with JOINs and CTEs, to find total spending by Gmail vs non-Gmail customers

WITH customer_type AS (
    SELECT customer_id,
           full_name,
           CASE
               WHEN email REGEXP 'gmail\\.com$' THEN 'Gmail User'
               ELSE 'Other Email'
           END AS email_type
    FROM customers
),
order_totals AS (
    SELECT oi.order_id,
           SUM(oi.quantity * p.price) AS order_value
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    GROUP BY oi.order_id
)
SELECT ct.email_type,
	   COUNT(DISTINCT ct.customer_id)  AS total_customers,
       COUNT(DISTINCT o.order_id)  AS total_orders,
       ROUND(SUM(ot.order_value), 2) AS total_revenue,
       ROUND(AVG(ot.order_value), 2) AS avg_order_value
FROM customer_type ct
JOIN orders o       ON ct.customer_id = o.customer_id
JOIN order_totals ot ON o.order_id    = ot.order_id
GROUP BY ct.email_type;

-- LESSON 5: WINDOW FUNCTIONS


-- query 14: Running total of revenue over time
WITH order_totals AS (
    SELECT o.order_id,
           DATE(o.order_date)            AS order_date,
           SUM(oi.quantity * p.price)    AS order_value
    FROM orders o
    JOIN order_items oi ON o.order_id    = oi.order_id
    JOIN products p     ON oi.product_id = p.product_id
    GROUP BY o.order_id, order_date
)
SELECT order_id,
       order_date,
       order_value,
       SUM(order_value) OVER(ORDER BY order_date) AS running_total
FROM order_totals;

-- query 15: rank customers by total spending
WITH customer_spending AS (
    SELECT c.full_name,
           c.city,
           SUM(oi.quantity * p.price) AS total_spent
    FROM customers c
    JOIN orders o       ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id    = oi.order_id
    JOIN products p     ON oi.product_id = p.product_id
    GROUP BY c.customer_id, c.full_name, c.city
)
SELECT full_name,
       city,
       total_spent,
       RANK() OVER(ORDER BY total_spent DESC) AS spending_rank
FROM customer_spending;

-- query 16: Rank customers WITHIN each city:
WITH customer_spending AS (
    SELECT c.full_name,
           c.city,
           SUM(oi.quantity * p.price) AS total_spent
    FROM customers c
    JOIN orders o       ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id    = oi.order_id
    JOIN products p     ON oi.product_id = p.product_id
    GROUP BY c.customer_id, c.full_name, c.city
)
SELECT full_name,
       city,
       total_spent,
       RANK() OVER(PARTITION BY city ORDER BY total_spent DESC) AS city_rank
FROM customer_spending;

-- query 17: Each order's value vs that customer's average
WITH order_totals AS (
    SELECT o.order_id,
           o.customer_id,
           SUM(oi.quantity * p.price) AS order_value
    FROM orders o
    JOIN order_items oi ON o.order_id    = oi.order_id
    JOIN products p     ON oi.product_id = p.product_id
    GROUP BY o.order_id, o.customer_id
)
SELECT c.full_name,
       ot.order_id,
       ot.order_value,
       ROUND(AVG(ot.order_value) OVER(PARTITION BY ot.customer_id), 2) AS customer_avg,
       ROUND(ot.order_value - AVG(ot.order_value) OVER(PARTITION BY ot.customer_id), 2) AS diff_from_avg
FROM order_totals ot
JOIN customers c ON ot.customer_id = c.customer_id
ORDER BY c.full_name;


-- FINAL CAPSTONE: Full Monthly Performance Report

-- QUERY 18: Getting monthly performance report showing revenue, order counts, and how each month ranks; but only for delivered orders from Gmail customers, and flag any months with unusually high revenue.

WITH 
-- STEP 1: Label customers as Gmail or Other (REGEX + CASE WHEN)
customer_type AS (
    SELECT customer_id,
           full_name,
           CASE
               WHEN email REGEXP 'gmail\\.com$' THEN 'Gmail'
               ELSE 'Other'
           END AS email_type
    FROM customers
),

-- STEP 2: Calculate value of each order (JOIN + aggregation)
order_totals AS (
    SELECT o.order_id,
           o.customer_id,
           DATE(o.order_date)         AS order_date,
           MONTH(o.order_date)        AS month_num,
           MONTHNAME(o.order_date)    AS month_name,
           o.status,
           SUM(oi.quantity * p.price) AS order_value
    FROM orders o
    JOIN order_items oi ON o.order_id    = oi.order_id
    JOIN products p     ON oi.product_id = p.product_id
    GROUP BY o.order_id, o.customer_id, order_date, month_num, month_name, o.status
),

-- STEP 3: Join orders with customer type, filter Gmail + delivered (JOIN + filter)
gmail_delivered AS (
    SELECT ot.*,
           ct.full_name,
           ct.email_type
    FROM order_totals ot
    JOIN customer_type ct ON ot.customer_id = ct.customer_id
    WHERE ot.status     = 'delivered'
    AND   ct.email_type = 'Gmail'
),

-- STEP 4: Summarize by month
monthly_summary AS (
    SELECT month_num,
           month_name,
           COUNT(DISTINCT order_id)        AS total_orders,
           ROUND(SUM(order_value), 2)      AS total_revenue,
           ROUND(AVG(order_value), 2)      AS avg_order_value
    FROM gmail_delivered
    GROUP BY month_num, month_name
)

-- FINAL SELECT: Add window functions + flag high revenue months
SELECT month_name,
       total_orders,
       total_revenue,
       avg_order_value,

       -- Rank months by revenue (WINDOW FUNCTION)
       RANK() OVER(ORDER BY total_revenue DESC) AS revenue_rank,

       -- Running total of revenue across months (WINDOW FUNCTION)
       ROUND(SUM(total_revenue) OVER(ORDER BY month_num), 2) AS running_total,

       -- Flag months above average revenue (CASE WHEN + WINDOW FUNCTION)
       CASE
           WHEN total_revenue > AVG(total_revenue) OVER() THEN '🔥 Above Average'
           ELSE '➡️ Below Average'
       END AS performance_flag

FROM monthly_summary
ORDER BY month_num;