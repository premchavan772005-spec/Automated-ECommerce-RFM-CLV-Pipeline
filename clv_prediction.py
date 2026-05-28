import pandas as pd
import numpy as np
from sqlalchemy import create_engine
from lifetimes import BetaGeoFitter, GammaGammaFitter
from lifetimes.utils import summary_data_from_transaction_data
import os

# ⚠️ MYSQL DATABASE WORKBENCH CREDENTIALS
DB_USER = "root"          
DB_PASSWORD = "its_prem7725$67" 
DB_HOST = "localhost"
DB_PORT = "3306"          
DB_NAME = "ecommerce_db"

def generate_predictions():
    print("📈 Fetching transactional records from MySQL for statistical modeling...")
    engine = create_engine(f"mysql+pymysql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}")
    
    df = pd.read_sql("SELECT * FROM fact_transactions", engine)
    
    print("⚙️ Formatting data into RFM-T Customer matrix layout...")
    df['InvoiceDate'] = pd.to_datetime(df['InvoiceDate'])
    
    rfm_matrix = summary_data_from_transaction_data(
        df, 
        customer_id_col='CustomerID', 
        datetime_col='InvoiceDate', 
        monetary_value_col='TotalLineRevenue',
        observation_period_end=df['InvoiceDate'].max()
    )
    
    # Filter out customers with zero repeating frequency
    rfm_matrix = rfm_matrix[rfm_matrix['frequency'] > 0]
    
    print("🤖 Training BG/NBD Model (Probability of future purchase)...")
    bgf = BetaGeoFitter(penalizer_coef=0.01) # 👈 Updated param name
    bgf.fit(rfm_matrix['frequency'], rfm_matrix['recency'], rfm_matrix['T'])
    
    print("🤖 Training Gamma-Gamma Model (Future monetary value projections)...")
    ggf = GammaGammaFitter(penalizer_coef=0.01) # 👈 Updated param name
    ggf.fit(rfm_matrix['frequency'], rfm_matrix['monetary_value'])
    
    print("🔮 Calculating expected average transaction spend value...")
    expected_avg_profit = ggf.conditional_expected_average_profit(
        rfm_matrix['frequency'],
        rfm_matrix['monetary_value']
    )
    
    print("🔮 Projecting 12-Month Predictive CLV scores...")
    clv_365 = ggf.customer_lifetime_value(
        bgf,
        rfm_matrix['frequency'],
        rfm_matrix['recency'],
        rfm_matrix['T'],
        rfm_matrix['monetary_value'],
        time=12,            
        discount_rate=0.01  
    )
    
    # Combine predictions cleanly
    predictions = pd.DataFrame(index=rfm_matrix.index)
    predictions['expected_avg_spend'] = expected_avg_profit
    predictions['predicted_clv_12mo'] = clv_365
    predictions = predictions.reset_index()
    
    print("💾 Uploading predictive results back into MySQL database table...")
    predictions.to_sql('pred_customer_clv', engine, if_exists='replace', index=False)
    print("🎯 Predictive CLV computations successfully created and integrated!")

if __name__ == "__main__":
    generate_predictions()