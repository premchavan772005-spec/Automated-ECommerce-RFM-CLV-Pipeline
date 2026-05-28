# End-to-End Predictive Customer Analytics & Data Engineering Pipeline

An enterprise-grade, data engineering and predictive machine learning pipeline that extracts raw historical e-commerce transactional data, processes behavioral metrics inside a optimized MySQL data warehouse, applies probability models to forecast long-term financial metrics, and visualizes historical and future enterprise value within an executive-level Power BI dashboard.

## 📊 Business Value Delivered
* **Total 12-Month Enterprise Customer Valuation:** **$8.64M** in forecasted customer lifetime value.
* **Leakage Recovery Mapping:** Quantified hidden residual revenue trapped within the *Hibernating / Lost* cohort, providing targeted reactivation coordinates for marketing squads.
* **Automated Engineering:** Transformed manual, fragmented workflows into an automated, structured data engineering asset ready for production scheduling.

---

## 🏗️ System Architecture & Data Flow

Below is the structured data lifecycle of this predictive infrastructure:

┌────────────────────────┐
│ Raw Excel Data Stream  │ (397K+ Invoices & Transaction Log Records)
└───────────┬────────────┘
│
│ [Python Ingestion Script: Pandas, SQLAlchemy]
▼
┌────────────────────────┐
│ MySQL Data Warehouse   │ (Target Storage Engine: ecommerce_db.fact_transactions)
└───────────┬────────────┘
│
├─► [MySQL Views & DB Optimization] ──► view_customer_rfm (Historical Metrics via Window Functions)
│
├─► [Python ML Scoring Engine]     ──► pred_customer_clv (12-Mo Projections via BG/NBD & Gamma-Gamma)
▼
┌────────────────────────┐
│   Data Modeling Core   │ (1-to-1 Analytical Entity Relationship Engine)
└───────────┬────────────┘
│
▼
┌────────────────────────┐
│ Power BI Dashboard     │ (Executive Visualization Layer: RFM Heatmaps & Financial Forecast Cards)
└────────────────────────┘


---

## 📁 Repository Structure

Organize your GitHub repository exactly like this to signal clean software architecture to technical hiring managers:

```text
predictive-customer-clv-pipeline/
├── data/
│   └── README.md                  # Instructions for downloading/placing the raw dataset
├── database/
│   └── customer_rfm_view_final.sql # SQL Warehouse script (CTEs, NTILE Window Functions)
├── scripts/
│   ├── etl_pipeline.py            # Automated raw data ingestion script
│   └── clv_prediction.py          # Python Machine Learning scoring model script
├── dashboard/
│   └── E_Commerce_Predictive_Analytics_Pipeline.pbix # Multi-page interactive Power BI Dashboard
└── README.md                      # Comprehensive project documentation
🛠️ Tech Stack & Advanced Implementation Details
1. Ingestion Layer (Python ETL Pipeline)
Libraries: pandas, pymysql, sqlalchemy

Mechanism: Automates extraction of raw transactional receipts, applies strict schema typing, formats transaction date-stamps (InvoiceDate), and handles batched streaming directly into a relational database tablespace with optimized parameters (if_exists='replace').

2. Analytics & Warehouse Engineering (MySQL Server)
Advanced Mechanics: Developed modular database architectures utilizing multi-layered Common Table Expressions (CTEs) and mathematical analytics Window Functions (NTILE, DENSE_RANK).

RFM Scoring Framework: Segmented customers across Recency, Frequency, and Monetary scores on an indexed 1-5 scalar system, outputting highly optimized performance structures directly to client-facing visualization platforms via the database view tier (view_customer_rfm).

3. Machine Learning Scoring Engine (Python Predictive Layer)
Frameworks: lifetimes, scipy

BG/NBD Model: Quantified specific consumer attributes modeling transaction frequency and drop-out rates (penalizer_coef=0.01) to calculate exact individual purchase probabilities.

Gamma-Gamma Model: Calculated expected conditional transaction averages to cleanly separate transaction frequency from actual financial values.

Pipeline Integration: Unified probability functions with financial spent values to score every active consumer ID for precise 12-Month Customer Lifetime Value (CLV) predictions, saving records directly back into database layers using structured automated schemas (pred_customer_clv).

4. Enterprise BI Analytics Interface (Power BI Desktop)
Architecture: Ingested analytical assets using specialized network application channels (ODBC User Data Source Names), building clean structural schemas mapped across explicit 1-to-1 Primary Key Relationships on CustomerID.

Data Enrichment: Integrated advanced DAX Logical Layer Switching Switching Equations (SWITCH, TRUE, LEFT, MID) to systematically convert complex raw matrix cells into distinct consumer persona tiers.

C-Suite Interface Layout:

Tab 1: RFM Performance Matrix – Renders multi-dimensional treemaps alongside advanced scatter charts correlating raw transactional parameters.

Tab 2: Value Analytics Projections – Highlights overall forecasted performance metrics using dynamic KPI highlight cards and clustered column projections.

🚀 Quick Start Setup & Replication Guide
1. Database Initialization
Execute the setup script to construct your database environment, and run your baseline ETL pipeline scripts to populate your tables:

Bash
python scripts/etl_pipeline.py
2. Analytical Optimization View Setup
Open MySQL Workbench and run database/customer_rfm_view_final.sql to compile your optimized, analytical window-function layer.

3. Run Predictive Scoring Machine Learning Engine
Execute your predictive models to compute machine learning projections and update database records:

Bash
python scripts/clv_prediction.py
4. Dashboard Visual Reporting
Open dashboard/E_Commerce_Predictive_Analytics_Pipeline.pbix within Power BI Desktop, click Refresh on the top ribbon to load your updated machine learning and warehouse tables, and explore live metrics!
📜 Portfolio Verification Statement
This pipeline represents a verified, standalone data platform. It contains production-grade scripting pipelines, mathematical optimizations, and business intelligence visuals engineered to demonstrate elite, senior-level data engineering and predictive operations.
