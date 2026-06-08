# E-Commerce Customer Analytics Pipeline
### RFM Segmentation + 12-Month CLV Forecasting | 397,000+ Transactions

---

## What Business Problem Does This Solve?

An e-commerce company has **4,300+ customers** but treats them all the same —
same emails, same discounts, same campaigns. This wastes marketing budget on
customers who would buy anyway, and ignores customers who are about to churn.

**This project answers 3 questions every marketing and sales team needs:**
1. Which customers are most valuable — and which are about to leave?
2. How much revenue can we expect from each customer in the next 12 months?
3. Where should we focus our retention budget to get the highest ROI?

---

## Business Results

| Metric | Value |
|---|---|
| Customers analysed | 4,300+ |
| Transactions processed | 397,000+ |
| Total revenue analysed | £8.64M |
| Predicted 12-month CLV (portfolio) | Modelled per segment |
| Champion customers (top segment) | Drive ~60% of total revenue |
| At-risk customers identified | Available for win-back campaigns |

---

## Key Business Insights (from SQL Analysis)

- **Top 20% of customers generate ~80% of revenue** — Pareto principle confirmed
- **Champion segment** has avg purchase frequency of 12x/year vs 1.4x for Lost customers
- **UK is the dominant market** but 3 international markets show 40%+ YoY growth
- **Tuesday–Thursday, 10AM–3PM** drives peak order volume — optimal campaign window
- **Cohort analysis** shows Month 1 → Month 2 retention drops sharply — key intervention point

---

## Project Architecture

```
Raw Excel Data (397K transactions)
        │
        ▼
  etl_pipeline.py          ← Cleans data, loads into MySQL
        │
        ▼
    MySQL Database
  (fact_transactions)
        │
        ├──────────────────────────────────┐
        ▼                                  ▼
customer_rfm_view.sql           clv_prediction.py
(RFM Scoring via                (BG/NBD + Gamma-Gamma
 Window Functions)               ML Models)
        │                                  │
        └──────────────┬───────────────────┘
                       ▼
              Power BI Dashboard
           (Executive KPI Report)
```

---

## SQL Business Analysis

📄 **[ecommerce_business_analysis.sql](./ecommerce_business_analysis.sql)**
— 12 business questions answered using advanced SQL

| Query | Business Question |
|---|---|
| Q1 | Month-over-month revenue trend |
| Q2 | Revenue contribution by customer segment |
| Q3 | Top 10 VIP customers with CLV |
| Q4 | At-risk churn customer identification |
| Q5 | Revenue by country — market expansion view |
| Q6 | Top 10 products by revenue |
| Q7 | Avg days between purchases per segment |
| Q8 | Cohort retention analysis |
| Q9 | Customer revenue percentile (decile) buckets |
| Q10 | Best day & hour for revenue (campaign timing) |
| Q11 | 12-month CLV opportunity by segment |
| Q12 | Executive KPI dashboard — single query |

**SQL skills demonstrated:** CTEs, Window Functions (`RANK`, `DENSE_RANK`,
`NTILE`, `LAG`, `PARTITION BY`), Multi-table JOINs, Cohort Analysis,
Date Functions, Subqueries, Aggregations

---

## RFM Segmentation Logic

Customers are scored 1–5 on each dimension and grouped into segments:

| Segment | Description | Business Action |
|---|---|---|
| Champions | Bought recently, buy often, spend most | Reward & upsell |
| Loyal Customers | Regular buyers, good spend | Loyalty programme |
| At Risk | Used to buy often — gone quiet | Win-back campaign |
| Lost | Haven't bought in 6+ months | Re-engagement or drop |
| New Customers | First purchase recently | Onboarding sequence |

---

## CLV Forecasting Model

**Models used:** BG/NBD (purchase frequency) + Gamma-Gamma (monetary value)

- BG/NBD predicts **how many times** a customer will buy in the next 12 months
- Gamma-Gamma predicts **how much** they will spend per transaction
- Combined output = **predicted 12-month revenue per customer**

This gives the marketing team a prioritised list — ranked by future value,
not just past spend.

---

## Tech Stack

| Layer | Tool |
|---|---|
| Data ingestion & cleaning | Python, Pandas |
| Database | MySQL |
| RFM scoring | SQL (Window Functions) |
| CLV modelling | Python, `lifetimes` library (BG/NBD + Gamma-Gamma) |
| Dashboard | Power BI |
| Dataset | UCI Online Retail II (UK, 2009–2011) |

---

## Repository Structure

```
├── etl_pipeline.py                   # Data cleaning + MySQL loader
├── clv_prediction.py                 # BG/NBD + Gamma-Gamma ML models
├── customer_rfm_view_final.sql       # RFM scoring views
├── ecommerce_business_analysis.sql   # 12 business questions (SQL showcase)
├── E_Commerce_Predictive_Analytics_Pipeline.pbix  # Power BI dashboard
└── data/
    └── README.md                     # Dataset download instructions
```

---

## How to Run

```bash
# 1. Install dependencies
pip install pandas sqlalchemy pymysql lifetimes openpyxl

# 2. Set your DB credentials in etl_pipeline.py

# 3. Run ETL — loads data into MySQL
python etl_pipeline.py

# 4. Run CLV model — writes predictions to MySQL
python clv_prediction.py

# 5. Open customer_rfm_view_final.sql in MySQL Workbench

# 6. Open .pbix in Power BI Desktop for the dashboard
```

---

## Dataset

**UCI Online Retail II Dataset**
- 397,000+ transactions
- UK-based online gift retailer
- Period: December 2009 – December 2011
- Download: [UCI ML Repository](https://archive.ics.uci.edu/ml/datasets/Online+Retail+II)

---

*Built by Prem Chavan | Data Analyst*
*Skills: SQL · Python · Pandas · Power BI · Machine Learning · Business Analytics*
