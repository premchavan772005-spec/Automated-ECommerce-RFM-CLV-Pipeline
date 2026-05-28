import pandas as pd
import numpy as np
from sqlalchemy import create_engine
import os

# ⚠️ UPDATE THESE WITH YOUR ACTUAL MYSQL WORKBENCH CREDENTIALS
DB_USER = "root"          
DB_PASSWORD = "its_prem7725$67" # 👈 Change this to your actual MySQL password!
DB_HOST = "localhost"
DB_PORT = "3306"          
DB_NAME = "ecommerce_db"

def run_etl():
    print("🚀 Starting ETL Pipeline for MySQL...")
    
    # Check for dataset path
    file_path = "./data/Online Retail.xlsx"
    if not os.path.exists(file_path):
        raise FileNotFoundError(f"❌ Cannot find data file at {file_path}")
        
    print("📥 Extracting data from Excel file (this might take a minute)...")
    df = pd.read_excel(file_path)
    
    print("🧹 Transforming and cleaning data...")
    # Drop records missing Customer IDs
    df = df.dropna(subset=['CustomerID'])
    df['CustomerID'] = df['CustomerID'].astype(int)
    
    # Standardize data types
    df['InvoiceDate'] = pd.to_datetime(df['InvoiceDate'])
    df['Description'] = df['Description'].str.strip()
    df['TotalLineRevenue'] = df['Quantity'] * df['UnitPrice']
    df['IsCancelled'] = df['InvoiceNo'].astype(str).str.startswith('C')
    
    # Filter valid purchases
    df_clean = df[(df['UnitPrice'] > 0) & (df['Quantity'] > 0) & (df['IsCancelled'] == False)].copy()
    print(f"✅ Cleaned data! Kept {len(df_clean)} valid transactions.")
    
    print("💾 Loading clean records into MySQL Workbench...")
    # Fixed string connection dialect for MySQL
    engine = create_engine(f"mysql+pymysql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}")
    df_clean.to_sql('fact_transactions', engine, if_exists='replace', index=False)
    print("🎉 ETL Execution finished successfully!")

if __name__ == "__main__":
    run_etl()