-- ==============================================================================
-- PROJECT: AUTOMATED E-COMMERCE RFM & CLV PIPELINE
-- MODULE: ADVANCED BUSINESS INTELLIGENCE & REVENUE OPTIMIZATION QUERIES
-- PURPOSE: Demonstrating Production-Level SQL (CTEs, Window Functions, Joins)
--          to solve real-world retail business problems.
-- TARGET ROLE: Data Analyst / Business Intelligence Analyst (6-8 LPA Tier)
-- ==============================================================================

USE ecommerce_db;

-- ------------------------------------------------------------------------------
-- QUERY 1: THE OVERALL BUSINESS HEALTH (Month-over-Month Revenue Growth & MoM %)
-- Business Value: Shows executives if revenue is expanding or shrinking.
-- Tech Stack: DATE_FORMAT, SUM, LAG() Window Function, Analytical Math
-- ------------------------------------------------------------------------------
WITH MonthlyRevenue AS (
    SELECT 
        DATE_FORMAT(InvoiceDate, '%Y-%m') AS invoice_month,
        ROUND(SUM(TotalLineRevenue), 2) AS monthly_revenue,
        COUNT(DISTINCT InvoiceNo) AS total_orders
    FROM fact_transactions
    GROUP BY DATE_FORMAT(InvoiceDate, '%Y-%m')
)
SELECT 
    invoice_month,
    monthly_revenue,
    total_orders,
    -- Get previous month's revenue using LAG
    LAG(monthly_revenue, 1) OVER (ORDER BY invoice_month) AS previous_month_revenue,
    -- Calculate MoM growth percentage
    ROUND(
        ((monthly_revenue - LAG(monthly_revenue, 1) OVER (ORDER BY invoice_month)) / 
        LAG(monthly_revenue, 1) OVER (ORDER BY invoice_month)) * 100, 2
    ) AS mom_growth_pct
FROM MonthlyRevenue;


-- ------------------------------------------------------------------------------
-- QUERY 2: THE 80/20 PARETO PRINCIPLE ANALYSIS
-- Business Value: Identifies the top tier of customers driving 80% of total revenue.
-- Tech Stack: CTE, Window Function Cumulative Sum, Percentile Calculation
-- ------------------------------------------------------------------------------
WITH CustomerRevenue AS (
    SELECT 
        CustomerID,
        SUM(TotalLineRevenue) AS total_spend
    FROM fact_transactions
    WHERE CustomerID IS NOT NULL
    GROUP BY CustomerID
),
RunningTotals AS (
    SELECT 
        CustomerID,
        total_spend,
        SUM(total_spend) OVER (ORDER BY total_spend DESC) AS cumulative_revenue,
        SUM(total_spend) OVER () AS total_company_revenue
    FROM CustomerRevenue
)
SELECT 
    CustomerID,
    ROUND(total_spend, 2) AS total_spend,
    ROUND((cumulative_revenue / total_company_revenue) * 100, 2) AS cumulative_revenue_pct,
    CASE 
        WHEN (cumulative_revenue / total_company_revenue) <= 0.80 THEN 'Core 80% Revenue Driver'
        ELSE 'Long Tail Customer'
    END AS pareto_segment
FROM RunningTotals
ORDER BY total_spend DESC;


-- ------------------------------------------------------------------------------
-- QUERY 3: HIGH-RISK CHURN ALERT (The "Slipping Champions")
-- Business Value: Flags customers who used to buy frequently and spend heavily 
--                 but haven't purchased anything in over 90 days. Critical for marketing.
-- Tech Stack: View Join, Multi-conditional filtering
-- ------------------------------------------------------------------------------
SELECT 
    rfm.CustomerID,
    ROUND(rfm.monetary, 2) AS lifetime_spend,
    rfm.frequency AS total_orders,
    rfm.recency AS days_since_last_purchase,
    rfm.r_score,
    rfm.f_score,
    rfm.m_score
FROM view_customer_rfm rfm
WHERE rfm.r_score <= 2       -- Bottom 40% in Recency (Haven't bought in a long time)
  AND rfm.f_score >= 4       -- Top 40% in Frequency (Used to buy very often)
  AND rfm.m_score >= 4       -- Top 40% in Monetary (Big spenders)
ORDER BY rfm.monetary DESC;


-- ------------------------------------------------------------------------------
-- QUERY 4: AVERAGE ORDER VALUE (AOV) BY CUSTOMER SEGMENT
-- Business Value: Helps marketing structure discount thresholds (e.g., "Spend ₹500 more").
-- Tech Stack: CTE, High-level Segmentation Logic, Aggregations
-- ------------------------------------------------------------------------------
WITH CustomerSegmentedAOV AS (
    SELECT 
        CustomerID,
        monetary,
        frequency,
        ROUND(monetary / frequency, 2) AS customer_aov,
        CASE 
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions / VIP'
            WHEN f_score >= 4 AND r_score <= 2 THEN 'Can''t Lose Them'
            WHEN r_score >= 4 AND f_score = 1 THEN 'New Customers'
            WHEN r_score <= 2 AND f_score <= 2 THEN 'Lost / Hibernating'
            ELSE 'Regular Mid-Tier'
        END AS strategic_segment
    FROM view_customer_rfm
)
SELECT 
    strategic_segment,
    COUNT(DISTINCT CustomerID) AS total_customers,
    ROUND(AVG(monetary), 2) AS avg_lifetime_value,
    ROUND(AVG(frequency), 2) AS avg_purchase_frequency,
    ROUND(AVG(customer_aov), 2) AS segment_average_order_value
FROM CustomerSegmentedAOV
GROUP BY strategic_segment
ORDER BY segment_average_order_value DESC;


-- ------------------------------------------------------------------------------
-- QUERY 5: TOP PENETRATING PRODUCTS BY HIGH-VALUE SEGMENTS
-- Business Value: Tells the inventory/merchandising team exactly what VIPs buy most.
-- Tech Stack: Multi-table Joins, Subqueries, Window Function Rankings
-- ------------------------------------------------------------------------------
WITH VIP_Customers AS (
    SELECT CustomerID 
    FROM view_customer_rfm
    WHERE r_score >= 4 AND f_score >= 4 AND m_score >= 4
),
ProductCounts AS (
    SELECT 
        t.StockCode,
        -- Assuming a product description exists in your dataset, otherwise remove line below
        -- t.Description, 
        COUNT(*) AS units_sold_to_vips,
        ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS product_rank
    FROM fact_transactions t
    JOIN VIP_Customers vip ON t.CustomerID = vip.CustomerID
    GROUP BY t.StockCode
)
SELECT 
    product_rank,
    StockCode,
    units_sold_to_vips
FROM ProductCounts
WHERE product_rank <= 10;
