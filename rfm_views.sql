USE ecommerce_db;

CREATE OR REPLACE VIEW view_customer_rfm AS
WITH customer_base_metrics AS (
    SELECT 
        CustomerID,
        -- Recency: Days between the maximum date in the entire dataset and each customer's latest purchase
        DATEDIFF((SELECT MAX(InvoiceDate) FROM fact_transactions), MAX(InvoiceDate)) AS recency,
        -- Frequency: Count of distinct invoice numbers per customer
        COUNT(DISTINCT InvoiceNo) AS frequency,
        -- Monetary: Total spend sum per customer
        SUM(TotalLineRevenue) AS monetary
    FROM fact_transactions
    GROUP BY CustomerID
),
rfm_scores AS (
    SELECT 
        CustomerID,
        recency,
        frequency,
        monetary,
        -- Calculate NTILE scores (1-5 ranking splits) for MySQL
        NTILE(5) OVER (ORDER BY recency DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
    FROM customer_base_metrics
)
SELECT 
    CustomerID,
    recency,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    -- Combine values to form an RFM matrix cell string identifier (e.g., '554')
    CONCAT(CAST(r_score AS CHAR), CAST(f_score AS CHAR), CAST(m_score AS CHAR)) AS rfm_cell_string
FROM rfm_scores;
