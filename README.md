# 🛒 E-Commerce Sales Analysis in SQL

## Project Overview
Analysis of an e-commerce order database using advanced SQL concepts.
The dataset includes customers, orders, products and order items across 8 months.

## Concepts Demonstrated
- **JOINs** — Combining data across 4 related tables
- **CTEs** — Breaking complex logic into readable layered steps
- **Date Functions** — Extracting and analyzing timestamp data
- **REGEX** — Pattern matching on email and text fields
- **Window Functions** — Rankings and running totals without collapsing rows
- **CASE WHEN** — Conditional logic and performance flagging

## Key Business Questions Answered
1. Which customers have never placed an order?
2. What is the monthly revenue trend for delivered orders?
3. Who are the top spenders globally and within each city?
4. How does each order compare to that customer's average spending?
5. Which months had above-average revenue from Gmail customers?

## Tools Used
- MySQL 8.0
- DB Fiddle (browser-based SQL editor)

## How to Run
1. Open [db-fiddle.com](https://db-fiddle.com) and select MySQL 8.0
2. Paste the schema setup from `ecommerce_analysis.sql` into the left panel
3. Run any query from the right panel
