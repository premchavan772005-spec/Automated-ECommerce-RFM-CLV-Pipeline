-- ============================================================
-- E-Commerce Business Intelligence Analysis
-- Dataset : 397,000+ transactions | UK Online Retail
-- Author  : Prem Chavan
-- Tables  : fact_transactions, customer_rfm, pred_customer_clv
-- Purpose : Answer 12 real business questions using SQL
--           (Joins · Aggregations · Window Functions · CTEs)
-- ============================================================


-- ============================================================
-- QUESTION 1
-- What is the total revenue, total orders, and average order
-- value by month? (Month-over-month revenue trend)
-- Business use: Spot seasonality, plan inventory & campaigns
-- ============================================================

SELECT
    DATE_FORMAT(invoice_date, '%Y-%m')          AS month,
    COUNT(DISTINCT invoice_no)                   AS total_orders,
    COUNT(DISTINCT customer_id)                  AS unique_customers,
    ROUND(SUM(quantity * unit_price), 2)         AS total_revenue,
    ROUND(AVG(quantity * unit_price), 2)         AS avg_order_value,
    ROUND(
        (SUM(quantity * unit_price) - LAG(SUM(quantity * unit_price))
            OVER (ORDER BY DATE_FORMAT(invoice_date, '%Y-%m')))
        / LAG(SUM(quantity * unit_price))
            OVER (ORDER BY DATE_FORMAT(invoice_date, '%Y-%m')) * 100
    , 2)                                         AS mom_revenue_growth_pct
FROM fact_transactions
WHERE quantity > 0
  AND unit_price > 0
  AND customer_id IS NOT NULL
GROUP BY DATE_FORMAT(invoice_date, '%Y-%m')
ORDER BY month;


-- ============================================================
-- QUESTION 2
-- Which customer segments generate the most revenue?
-- (Pareto analysis — do top 20% of customers = 80% revenue?)
-- Business use: Decide where to focus retention budget
-- ============================================================

WITH customer_revenue AS (
    SELECT
        t.customer_id,
        r.rfm_segment,
        ROUND(SUM(t.quantity * t.unit_price), 2)  AS customer_revenue
    FROM fact_transactions t
    JOIN customer_rfm r ON t.customer_id = r.customer_id
    WHERE t.quantity > 0 AND t.unit_price > 0
    GROUP BY t.customer_id, r.rfm_segment
),
segment_summary AS (
    SELECT
        rfm_segment,
        COUNT(DISTINCT customer_id)               AS num_customers,
        ROUND(SUM(customer_revenue), 2)           AS segment_revenue,
        ROUND(AVG(customer_revenue), 2)           AS avg_revenue_per_customer,
        ROUND(MAX(customer_revenue), 2)           AS top_customer_revenue
    FROM customer_revenue
    GROUP BY rfm_segment
)
SELECT
    rfm_segment,
    num_customers,
    segment_revenue,
    avg_revenue_per_customer,
    top_customer_revenue,
    ROUND(
        segment_revenue / SUM(segment_revenue) OVER () * 100
    , 2)                                          AS pct_of_total_revenue,
    ROUND(
        num_customers / SUM(num_customers) OVER () * 100
    , 2)                                          AS pct_of_total_customers
FROM segment_summary
ORDER BY segment_revenue DESC;


-- ============================================================
-- QUESTION 3
-- Who are the Top 10 highest-value customers and what
-- segment do they belong to?
-- Business use: VIP list for account managers / loyalty perks
-- ============================================================

SELECT
    t.customer_id,
    r.rfm_segment,
    r.recency_days,
    r.frequency,
    ROUND(r.monetary, 2)                          AS historical_spend,
    ROUND(c.predicted_clv_12m, 2)                 AS predicted_clv_12m,
    ROUND(SUM(t.quantity * t.unit_price), 2)      AS total_revenue,
    COUNT(DISTINCT t.invoice_no)                  AS total_orders,
    RANK() OVER (ORDER BY SUM(t.quantity * t.unit_price) DESC) AS revenue_rank
FROM fact_transactions t
JOIN customer_rfm r        ON t.customer_id = r.customer_id
JOIN pred_customer_clv c   ON t.customer_id = c.customer_id
WHERE t.quantity > 0 AND t.unit_price > 0
GROUP BY
    t.customer_id, r.rfm_segment, r.recency_days,
    r.frequency, r.monetary, c.predicted_clv_12m
ORDER BY total_revenue DESC
LIMIT 10;


-- ============================================================
-- QUESTION 4
-- Which customers are at risk of churning?
-- (Bought frequently before but have gone silent 90+ days)
-- Business use: Win-back campaign target list
-- ============================================================

WITH customer_stats AS (
    SELECT
        customer_id,
        MAX(invoice_date)                          AS last_purchase_date,
        COUNT(DISTINCT invoice_no)                 AS total_orders,
        ROUND(SUM(quantity * unit_price), 2)       AS total_spend,
        DATEDIFF(MAX(invoice_date),
                 MIN(invoice_date))                AS customer_lifespan_days
    FROM fact_transactions
    WHERE quantity > 0 AND unit_price > 0
    GROUP BY customer_id
    HAVING total_orders >= 3
)
SELECT
    cs.customer_id,
    cs.last_purchase_date,
    DATEDIFF(CURDATE(), cs.last_purchase_date)     AS days_since_last_purchase,
    cs.total_orders,
    cs.total_spend,
    r.rfm_segment,
    c.predicted_clv_12m
FROM customer_stats cs
JOIN customer_rfm r       ON cs.customer_id = r.customer_id
JOIN pred_customer_clv c  ON cs.customer_id = c.customer_id
WHERE DATEDIFF(CURDATE(), cs.last_purchase_date) > 90
ORDER BY cs.total_spend DESC;


-- ============================================================
-- QUESTION 5
-- What is the revenue contribution by country?
-- Business use: Identify top international markets for expansion
-- ============================================================

SELECT
    country,
    COUNT(DISTINCT customer_id)                    AS unique_customers,
    COUNT(DISTINCT invoice_no)                     AS total_orders,
    ROUND(SUM(quantity * unit_price), 2)           AS total_revenue,
    ROUND(AVG(quantity * unit_price), 2)           AS avg_order_value,
    ROUND(
        SUM(quantity * unit_price)
        / SUM(SUM(quantity * unit_price)) OVER () * 100
    , 2)                                           AS revenue_share_pct,
    RANK() OVER (
        ORDER BY SUM(quantity * unit_price) DESC
    )                                              AS revenue_rank
FROM fact_transactions
WHERE quantity > 0
  AND unit_price > 0
  AND customer_id IS NOT NULL
GROUP BY country
ORDER BY total_revenue DESC;


-- ============================================================
-- QUESTION 6
-- What are the top 10 best-selling products by revenue?
-- And what % of total revenue do they contribute?
-- Business use: Stock prioritisation, promotional planning
-- ============================================================

SELECT
    stock_code,
    description,
    SUM(quantity)                                  AS units_sold,
    COUNT(DISTINCT invoice_no)                     AS times_ordered,
    ROUND(SUM(quantity * unit_price), 2)           AS product_revenue,
    ROUND(
        SUM(quantity * unit_price)
        / SUM(SUM(quantity * unit_price)) OVER () * 100
    , 2)                                           AS pct_of_total_revenue,
    DENSE_RANK() OVER (
        ORDER BY SUM(quantity * unit_price) DESC
    )                                              AS revenue_rank
FROM fact_transactions
WHERE quantity > 0
  AND unit_price > 0
GROUP BY stock_code, description
ORDER BY product_revenue DESC
LIMIT 10;


-- ============================================================
-- QUESTION 7
-- What is the average number of days between purchases
-- for each RFM segment? (Purchase frequency pattern)
-- Business use: Set email cadence correctly per segment
-- ============================================================

WITH ordered_purchases AS (
    SELECT
        t.customer_id,
        r.rfm_segment,
        t.invoice_date,
        LAG(t.invoice_date) OVER (
            PARTITION BY t.customer_id
            ORDER BY t.invoice_date
        )                                          AS prev_purchase_date
    FROM fact_transactions t
    JOIN customer_rfm r ON t.customer_id = r.customer_id
    WHERE t.quantity > 0 AND t.unit_price > 0
    GROUP BY t.customer_id, r.rfm_segment, t.invoice_date
),
days_between AS (
    SELECT
        customer_id,
        rfm_segment,
        DATEDIFF(invoice_date, prev_purchase_date) AS days_between_purchases
    FROM ordered_purchases
    WHERE prev_purchase_date IS NOT NULL
)
SELECT
    rfm_segment,
    COUNT(DISTINCT customer_id)                    AS num_customers,
    ROUND(AVG(days_between_purchases), 1)          AS avg_days_between_purchases,
    ROUND(MIN(days_between_purchases), 1)          AS min_days,
    ROUND(MAX(days_between_purchases), 1)          AS max_days
FROM days_between
GROUP BY rfm_segment
ORDER BY avg_days_between_purchases;


-- ============================================================
-- QUESTION 8
-- Cohort retention: How many customers who bought in
-- Month 1 came back in Month 2, 3, 6?
-- Business use: Measure true customer retention rate
-- ============================================================

WITH first_purchase AS (
    SELECT
        customer_id,
        DATE_FORMAT(MIN(invoice_date), '%Y-%m')    AS cohort_month
    FROM fact_transactions
    WHERE quantity > 0 AND unit_price > 0
    GROUP BY customer_id
),
monthly_activity AS (
    SELECT
        t.customer_id,
        DATE_FORMAT(t.invoice_date, '%Y-%m')       AS activity_month
    FROM fact_transactions t
    WHERE t.quantity > 0 AND t.unit_price > 0
    GROUP BY t.customer_id, DATE_FORMAT(t.invoice_date, '%Y-%m')
)
SELECT
    f.cohort_month,
    COUNT(DISTINCT f.customer_id)                  AS cohort_size,
    COUNT(DISTINCT CASE
        WHEN m.activity_month = f.cohort_month
        THEN m.customer_id END)                    AS month_0,
    COUNT(DISTINCT CASE
        WHEN PERIOD_DIFF(
            REPLACE(m.activity_month,'-',''),
            REPLACE(f.cohort_month,'-','')
        ) = 1 THEN m.customer_id END)             AS month_1,
    COUNT(DISTINCT CASE
        WHEN PERIOD_DIFF(
            REPLACE(m.activity_month,'-',''),
            REPLACE(f.cohort_month,'-','')
        ) = 2 THEN m.customer_id END)             AS month_2,
    COUNT(DISTINCT CASE
        WHEN PERIOD_DIFF(
            REPLACE(m.activity_month,'-',''),
            REPLACE(f.cohort_month,'-','')
        ) = 5 THEN m.customer_id END)             AS month_5
FROM first_purchase f
LEFT JOIN monthly_activity m ON f.customer_id = m.customer_id
GROUP BY f.cohort_month
ORDER BY f.cohort_month;


-- ============================================================
-- QUESTION 9
-- Revenue percentile buckets — which revenue band do most
-- customers fall into?
-- Business use: Understand customer value distribution,
--               identify upsell opportunities
-- ============================================================

WITH customer_revenue AS (
    SELECT
        customer_id,
        ROUND(SUM(quantity * unit_price), 2)       AS total_revenue
    FROM fact_transactions
    WHERE quantity > 0 AND unit_price > 0
    GROUP BY customer_id
),
percentile_buckets AS (
    SELECT
        customer_id,
        total_revenue,
        NTILE(10) OVER (
            ORDER BY total_revenue
        )                                          AS revenue_decile
    FROM customer_revenue
)
SELECT
    revenue_decile,
    COUNT(customer_id)                             AS num_customers,
    ROUND(MIN(total_revenue), 2)                   AS min_revenue,
    ROUND(MAX(total_revenue), 2)                   AS max_revenue,
    ROUND(AVG(total_revenue), 2)                   AS avg_revenue,
    ROUND(SUM(total_revenue), 2)                   AS decile_total_revenue,
    ROUND(
        SUM(total_revenue)
        / SUM(SUM(total_revenue)) OVER () * 100
    , 2)                                           AS pct_of_total_revenue
FROM percentile_buckets
GROUP BY revenue_decile
ORDER BY revenue_decile;


-- ============================================================
-- QUESTION 10
-- Which day of week and hour of day drives highest revenue?
-- Business use: Schedule email campaigns and flash sales
-- ============================================================

SELECT
    DAYNAME(invoice_date)                          AS day_of_week,
    HOUR(invoice_date)                             AS hour_of_day,
    COUNT(DISTINCT invoice_no)                     AS total_orders,
    ROUND(SUM(quantity * unit_price), 2)           AS total_revenue,
    ROUND(AVG(quantity * unit_price), 2)           AS avg_order_value,
    RANK() OVER (
        ORDER BY SUM(quantity * unit_price) DESC
    )                                              AS revenue_rank
FROM fact_transactions
WHERE quantity > 0 AND unit_price > 0
GROUP BY DAYNAME(invoice_date), HOUR(invoice_date)
ORDER BY total_revenue DESC
LIMIT 20;


-- ============================================================
-- QUESTION 11
-- What is the predicted 12-month CLV by segment, and what
-- is the total revenue opportunity if we retain them?
-- Business use: Justify marketing spend per segment to CFO
-- ============================================================

SELECT
    r.rfm_segment,
    COUNT(DISTINCT r.customer_id)                  AS num_customers,
    ROUND(AVG(c.predicted_clv_12m), 2)             AS avg_predicted_clv,
    ROUND(SUM(c.predicted_clv_12m), 2)             AS total_clv_opportunity,
    ROUND(AVG(r.recency_days), 1)                  AS avg_recency_days,
    ROUND(AVG(r.frequency), 1)                     AS avg_purchase_frequency,
    ROUND(AVG(r.monetary), 2)                      AS avg_historical_spend,
    ROUND(
        SUM(c.predicted_clv_12m)
        / SUM(SUM(c.predicted_clv_12m)) OVER () * 100
    , 2)                                           AS clv_share_pct
FROM customer_rfm r
JOIN pred_customer_clv c ON r.customer_id = c.customer_id
GROUP BY r.rfm_segment
ORDER BY total_clv_opportunity DESC;


-- ============================================================
-- QUESTION 12
-- Executive Summary — Single-query KPI dashboard
-- Business use: One-page summary for stakeholder presentation
-- ============================================================

SELECT
    COUNT(DISTINCT customer_id)                    AS total_customers,
    COUNT(DISTINCT invoice_no)                     AS total_orders,
    ROUND(SUM(quantity * unit_price), 2)           AS total_gross_revenue,
    ROUND(AVG(quantity * unit_price), 2)           AS avg_order_value,
    ROUND(SUM(quantity * unit_price)
          / COUNT(DISTINCT customer_id), 2)        AS revenue_per_customer,
    COUNT(DISTINCT stock_code)                     AS unique_products,
    COUNT(DISTINCT country)                        AS countries_served,
    MIN(invoice_date)                              AS data_from,
    MAX(invoice_date)                              AS data_to
FROM fact_transactions
WHERE quantity > 0
  AND unit_price > 0
  AND customer_id IS NOT NULL;
