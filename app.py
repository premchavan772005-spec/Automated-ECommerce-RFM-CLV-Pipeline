import streamlit as st
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import warnings
warnings.filterwarnings('ignore')

st.set_page_config(page_title="E-Commerce RFM & CLV Pipeline", layout="wide")

st.title("🛒 E-Commerce RFM Segmentation & Customer Lifetime Value Pipeline")
st.markdown("**End-to-end predictive customer analytics — RFM scoring + 12-month CLV forecasting**")

@st.cache_data
def load_and_process():
    df = pd.read_excel("Online Retail.xlsx", engine="openpyxl")
    df = df.dropna(subset=['CustomerID'])
    df['CustomerID'] = df['CustomerID'].astype(int)
    df['InvoiceDate'] = pd.to_datetime(df['InvoiceDate'])
    df['TotalRevenue'] = df['Quantity'] * df['UnitPrice']
    df = df[(df['UnitPrice'] > 0) & (df['Quantity'] > 0)]
    df = df[~df['InvoiceNo'].astype(str).str.startswith('C')]
    return df

with st.spinner("⏳ Loading 397K+ transaction records and computing RFM scores..."):
    df = load_and_process()

snapshot_date = df['InvoiceDate'].max() + pd.Timedelta(days=1)

rfm = df.groupby('CustomerID').agg(
    Recency=('InvoiceDate', lambda x: (snapshot_date - x.max()).days),
    Frequency=('InvoiceNo', 'nunique'),
    Monetary=('TotalRevenue', 'sum')
).reset_index()

rfm['R_Score'] = pd.qcut(rfm['Recency'], 5, labels=[5,4,3,2,1]).astype(int)
rfm['F_Score'] = pd.qcut(rfm['Frequency'].rank(method='first'), 5, labels=[1,2,3,4,5]).astype(int)
rfm['M_Score'] = pd.qcut(rfm['Monetary'].rank(method='first'), 5, labels=[1,2,3,4,5]).astype(int)
rfm['RFM_Score'] = rfm['R_Score'] + rfm['F_Score'] + rfm['M_Score']

def segment(row):
    score = row['RFM_Score']
    r = row['R_Score']
    if score >= 13: return 'Champions'
    elif score >= 10: return 'Loyal Customers'
    elif r >= 4 and score >= 8: return 'Potential Loyalists'
    elif r >= 4 and score < 8: return 'New Customers'
    elif r == 3: return 'At Risk'
    elif r == 2: return 'Hibernating'
    else: return 'Lost'

rfm['Segment'] = rfm.apply(segment, axis=1)

avg_order = df.groupby('CustomerID')['TotalRevenue'].mean()
rfm = rfm.join(avg_order.rename('AvgOrderValue'), on='CustomerID')
rfm['CLV_12Month'] = rfm['AvgOrderValue'] * rfm['Frequency'] * (12 / max(1, (df['InvoiceDate'].max() - df['InvoiceDate'].min()).days / 30))
rfm['CLV_12Month'] = rfm['CLV_12Month'].clip(upper=rfm['CLV_12Month'].quantile(0.97))

total_clv = rfm['CLV_12Month'].sum()
total_customers = len(rfm)
total_revenue = rfm['Monetary'].sum()
avg_clv = rfm['CLV_12Month'].mean()
champions_count = len(rfm[rfm['Segment'] == 'Champions'])
at_risk_count = len(rfm[rfm['Segment'].isin(['At Risk', 'Hibernating', 'Lost'])])

col1, col2, col3, col4 = st.columns(4)
col1.metric("Total Customers", f"{total_customers:,}")
col2.metric("Total Historical Revenue", f"${total_revenue:,.0f}")
col3.metric("12-Month Forecast CLV", f"${total_clv:,.0f}")
col4.metric("Avg CLV per Customer", f"${avg_clv:,.0f}")

col5, col6 = st.columns(2)
col5.metric("Champions", f"{champions_count:,}", "High-value retained")
col6.metric("At Risk / Lost", f"{at_risk_count:,}", "Needs reactivation", delta_color="inverse")

st.divider()

tab1, tab2, tab3, tab4 = st.tabs(["📊 RFM Segments", "💰 CLV Forecast", "🔍 Customer Explorer", "📈 Revenue Trends"])

with tab1:
    st.subheader("Customer Segmentation Distribution")
    col_a, col_b = st.columns(2)

    with col_a:
        seg_counts = rfm['Segment'].value_counts()
        colors = ['#1D9E75','#185FA5','#54A24B','#3B8BD4','#D85A30','#888780','#E45756']
        fig1, ax1 = plt.subplots(figsize=(7, 6))
        wedges, texts, autotexts = ax1.pie(
            seg_counts.values,
            labels=None,
            autopct='%1.1f%%',
            colors=colors[:len(seg_counts)],
            startangle=90,
            pctdistance=0.75,
            wedgeprops=dict(width=0.6)
        )
        for autotext in autotexts:
            autotext.set_fontsize(9)
            autotext.set_fontweight('bold')
        ax1.legend(
            wedges, seg_counts.index,
            title="Segments",
            loc="center left",
            bbox_to_anchor=(1.0, 0, 0.5, 1),
            fontsize=9
        )
        ax1.set_title("Customer Segments", fontsize=13, fontweight='bold')
        st.pyplot(fig1)

    with col_b:
        seg_revenue = rfm.groupby('Segment')['Monetary'].sum().sort_values(ascending=True)
        fig2, ax2 = plt.subplots(figsize=(7, 6))
        bar_colors = ['#1D9E75' if s == 'Champions' else
                      '#185FA5' if s == 'Loyal Customers' else
                      '#D85A30' if s in ['Lost', 'At Risk'] else
                      '#888780' for s in seg_revenue.index]
        bars = ax2.barh(seg_revenue.index, seg_revenue.values, color=bar_colors)
        ax2.set_xlabel("Total Revenue ($)")
        ax2.set_title("Revenue by Segment", fontsize=13, fontweight='bold')
        for bar, val in zip(bars, seg_revenue.values):
            ax2.text(bar.get_width() + seg_revenue.max() * 0.01,
                     bar.get_y() + bar.get_height() / 2,
                     f'${val:,.0f}', va='center', fontsize=8)
        ax2.set_xlim(0, seg_revenue.max() * 1.18)
        st.pyplot(fig2)

    st.subheader("RFM Score Distribution")
    col_c, col_d = st.columns(2)
    with col_c:
        fig3, ax3 = plt.subplots(figsize=(6, 3))
        ax3.hist(rfm['Recency'], bins=40, color='#D85A30', alpha=0.8, edgecolor='white')
        ax3.set_xlabel("Days Since Last Purchase")
        ax3.set_ylabel("Number of Customers")
        ax3.set_title("Recency Distribution")
        st.pyplot(fig3)
    with col_d:
        fig4, ax4 = plt.subplots(figsize=(6, 3))
        ax4.hist(rfm['Frequency'].clip(upper=50), bins=40, color='#1D9E75', alpha=0.8, edgecolor='white')
        ax4.set_xlabel("Number of Orders")
        ax4.set_ylabel("Number of Customers")
        ax4.set_title("Frequency Distribution")
        st.pyplot(fig4)

with tab2:
    st.subheader("12-Month Customer Lifetime Value Forecast")

    col_e, col_f = st.columns(2)
    with col_e:
        clv_seg = rfm.groupby('Segment')['CLV_12Month'].sum().sort_values(ascending=False)
        fig5, ax5 = plt.subplots(figsize=(7, 5))
        bar_colors2 = ['#1D9E75' if s == 'Champions' else
                       '#185FA5' if s == 'Loyal Customers' else
                       '#D85A30' if s in ['Lost', 'At Risk'] else
                       '#888780' for s in clv_seg.index]
        bars2 = ax5.bar(clv_seg.index, clv_seg.values, color=bar_colors2, edgecolor='white')
        ax5.set_ylabel("Forecasted CLV ($)")
        ax5.set_title("12-Month CLV by Segment", fontsize=13, fontweight='bold')
        plt.xticks(rotation=30, ha='right', fontsize=8)
        for bar, val in zip(bars2, clv_seg.values):
            ax5.text(bar.get_x() + bar.get_width() / 2,
                     bar.get_height() + clv_seg.max() * 0.01,
                     f'${val/1000:.0f}K', ha='center', fontsize=8, fontweight='bold')
        ax5.set_ylim(0, clv_seg.max() * 1.15)
        st.pyplot(fig5)

    with col_f:
        fig6, ax6 = plt.subplots(figsize=(7, 5))
        segment_colors_map = {
            'Champions': '#1D9E75', 'Loyal Customers': '#185FA5',
            'Potential Loyalists': '#54A24B', 'New Customers': '#3B8BD4',
            'At Risk': '#D85A30', 'Hibernating': '#888780', 'Lost': '#E45756'
        }
        for seg_name, seg_data in rfm.groupby('Segment'):
            ax6.scatter(seg_data['Frequency'].clip(upper=60),
                        seg_data['CLV_12Month'],
                        alpha=0.4, s=8,
                        color=segment_colors_map.get(seg_name, '#888780'),
                        label=seg_name)
        ax6.set_xlabel("Purchase Frequency")
        ax6.set_ylabel("12-Month CLV ($)")
        ax6.set_title("Frequency vs CLV by Segment", fontsize=13, fontweight='bold')
        ax6.legend(fontsize=7, loc='upper left')
        st.pyplot(fig6)

    st.subheader("🏆 Top 20 Highest CLV Customers")
    top20 = rfm.nlargest(20, 'CLV_12Month')[
        ['CustomerID', 'Segment', 'Recency', 'Frequency', 'Monetary', 'CLV_12Month']]
    top20 = top20.copy()
    top20['Monetary'] = top20['Monetary'].map('${:,.2f}'.format)
    top20['CLV_12Month'] = top20['CLV_12Month'].map('${:,.2f}'.format)
    st.dataframe(top20, use_container_width=True)

    st.subheader("⚠️ Hibernating / Lost Customer Reactivation List")
    st.caption("Hidden residual revenue — targeted campaigns can recover these customers")
    leakage = rfm[rfm['Segment'].isin(['Hibernating', 'Lost'])].nlargest(15, 'Monetary')[
        ['CustomerID', 'Segment', 'Recency', 'Frequency', 'Monetary', 'CLV_12Month']]
    leakage = leakage.copy()
    leakage['Monetary'] = leakage['Monetary'].map('${:,.2f}'.format)
    leakage['CLV_12Month'] = leakage['CLV_12Month'].map('${:,.2f}'.format)
    st.dataframe(leakage, use_container_width=True)

with tab3:
    st.subheader("🔍 Customer Explorer")
    col_filter1, col_filter2 = st.columns(2)
    with col_filter1:
        seg_filter = st.multiselect(
            "Filter by Segment",
            rfm['Segment'].unique().tolist(),
            default=rfm['Segment'].unique().tolist()
        )
    with col_filter2:
        min_clv = st.slider("Minimum CLV ($)", 0, int(rfm['CLV_12Month'].max()), 0)

    filtered = rfm[(rfm['Segment'].isin(seg_filter)) & (rfm['CLV_12Month'] >= min_clv)]

    col_g, col_h, col_i = st.columns(3)
    col_g.metric("Filtered Customers", f"{len(filtered):,}")
    col_h.metric("Filtered Revenue", f"${filtered['Monetary'].sum():,.0f}")
    col_i.metric("Filtered CLV", f"${filtered['CLV_12Month'].sum():,.0f}")

    st.dataframe(
        filtered[['CustomerID', 'Segment', 'Recency', 'Frequency', 'Monetary',
                  'R_Score', 'F_Score', 'M_Score', 'RFM_Score', 'CLV_12Month']]
        .sort_values('CLV_12Month', ascending=False).head(200),
        use_container_width=True
    )

with tab4:
    st.subheader("📈 Monthly Revenue Trend")
    df['YearMonth'] = df['InvoiceDate'].dt.to_period('M')
    monthly = df.groupby('YearMonth')['TotalRevenue'].sum().reset_index()
    monthly['YearMonth'] = monthly['YearMonth'].astype(str)

    fig7, ax7 = plt.subplots(figsize=(12, 4))
    ax7.plot(monthly['YearMonth'], monthly['TotalRevenue'],
             color='#185FA5', linewidth=2.5, marker='o', markersize=5, markerfacecolor='white',
             markeredgewidth=2)
    ax7.fill_between(range(len(monthly)), monthly['TotalRevenue'], alpha=0.12, color='#185FA5')
    ax7.set_ylabel("Revenue ($)")
    ax7.set_title("Monthly Revenue Trend", fontsize=13, fontweight='bold')
    plt.xticks(range(len(monthly)), monthly['YearMonth'], rotation=45, ha='right', fontsize=8)
    ax7.yaxis.set_major_formatter(plt.FuncFormatter(lambda x, _: f'${x/1000:.0f}K'))
    ax7.grid(axis='y', alpha=0.3)
    st.pyplot(fig7)

    col_j, col_k = st.columns(2)
    with col_j:
        st.subheader("🌍 Top 10 Countries by Revenue")
        country_rev = df.groupby('Country')['TotalRevenue'].sum().sort_values(ascending=False).head(10)
        fig8, ax8 = plt.subplots(figsize=(7, 4))
        bars8 = ax8.bar(country_rev.index, country_rev.values, color='#1D9E75', edgecolor='white')
        ax8.set_ylabel("Revenue ($)")
        ax8.set_title("Revenue by Country", fontsize=12, fontweight='bold')
        ax8.yaxis.set_major_formatter(plt.FuncFormatter(lambda x, _: f'${x/1000:.0f}K'))
        plt.xticks(rotation=30, ha='right', fontsize=8)
        ax8.grid(axis='y', alpha=0.3)
        st.pyplot(fig8)

    with col_k:
        st.subheader("📦 Top 10 Products by Revenue")
        product_rev = df.groupby('Description')['TotalRevenue'].sum().sort_values(ascending=False).head(10)
        fig9, ax9 = plt.subplots(figsize=(7, 4))
        ax9.barh(product_rev.index, product_rev.values, color='#D85A30', edgecolor='white')
        ax9.set_xlabel("Revenue ($)")
        ax9.set_title("Top Products", fontsize=12, fontweight='bold')
        ax9.xaxis.set_major_formatter(plt.FuncFormatter(lambda x, _: f'${x/1000:.0f}K'))
        plt.yticks(fontsize=7)
        ax9.grid(axis='x', alpha=0.3)
        st.pyplot(fig9)

st.divider()
st.caption("Built by Prem Chavan | github.com/premchavan772005-spec | End-to-End RFM & CLV Analytics Pipeline")
