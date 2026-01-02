import pandas as pd
import numpy as np
import streamlit as st

st.set_page_config(page_title="Ecommerce Business Dashboard", layout="wide")

DATA_DIR = "data/processed"

@st.cache_data
def load_csv(name: str) -> pd.DataFrame:
    return pd.read_csv(f"{DATA_DIR}/{name}")

def to_datetime(df: pd.DataFrame, col: str) -> pd.DataFrame:
    if col in df.columns:
        df[col] = pd.to_datetime(df[col], errors="coerce")
    return df

def to_numeric(df: pd.DataFrame, cols: list[str]) -> pd.DataFrame:
    for c in cols:
        if c in df.columns:
            df[c] = pd.to_numeric(df[c], errors="coerce")
    return df

def fix_percent_series(s: pd.Series) -> pd.Series:
    """
    Expected percent in 0-100.
    - If values look like 0-1, convert to 0-100.
    - If values are absurdly large, coerce to NaN (then you can inspect).
    """
    s = pd.to_numeric(s, errors="coerce")
    if s.dropna().empty:
        return s

    
    frac_ratio = ((s >= 0) & (s <= 1)).mean()
    if frac_ratio > 0.7:
        s = s * 100

    # remove absurd values
    s = s.where((s >= 0) & (s <= 100))
    return s

# ===== Load data =====
monthly_rev = load_csv("revenue_by_month.csv")
mom_growth  = load_csv("mom_revenue_growth.csv")
ret_month   = load_csv("return_rate_by_month.csv")
ret_cat     = load_csv("return_rate_by_category.csv")
ret_brand   = load_csv("return_rate_by_brand.csv")
seg_summary = load_csv("customer_segment_summary.csv")
rfm_summary = load_csv("rfm_summary.csv")

# ===== Fix dtypes =====
monthly_rev = to_datetime(monthly_rev, "order_month")
monthly_rev = to_numeric(monthly_rev, ["revenue"])

mom_growth = to_datetime(mom_growth, "order_month")
mom_growth = to_numeric(mom_growth, ["mom_growth_pct"])
mom_growth["mom_growth_pct"] = fix_percent_series(mom_growth["mom_growth_pct"])

ret_month = to_datetime(ret_month, "order_month")
ret_month = to_numeric(ret_month, ["returned_items", "total_items", "return_rate", "return_rate_pct"])

if "return_rate_pct" in ret_month.columns:
    ret_month["return_rate_pct"] = fix_percent_series(ret_month["return_rate_pct"])
elif "return_rate" in ret_month.columns:
    ret_month["return_rate_pct"] = fix_percent_series(ret_month["return_rate"])

ret_cat = to_numeric(ret_cat, ["total_items", "return_rate", "return_rate_pct"])
if "return_rate_pct" in ret_cat.columns:
    ret_cat["return_rate_pct"] = fix_percent_series(ret_cat["return_rate_pct"])
elif "return_rate" in ret_cat.columns:
    ret_cat["return_rate_pct"] = fix_percent_series(ret_cat["return_rate"])

ret_brand = to_numeric(ret_brand, ["total_items", "revenue", "return_rate", "return_rate_pct"])
if "return_rate_pct" in ret_brand.columns:
    ret_brand["return_rate_pct"] = fix_percent_series(ret_brand["return_rate_pct"])
elif "return_rate" in ret_brand.columns:
    ret_brand["return_rate_pct"] = fix_percent_series(ret_brand["return_rate"])

seg_summary = to_numeric(seg_summary, ["customers", "avg_revenue_per_user", "total_revenue", "avg_return_rate", "avg_frequency", "avg_recency"])
if "avg_return_rate" in seg_summary.columns:
    seg_summary["avg_return_rate_pct"] = fix_percent_series(seg_summary["avg_return_rate"])
else:
    seg_summary["avg_return_rate_pct"] = np.nan

rfm_summary = to_numeric(rfm_summary, ["customers", "total_revenue", "avg_return_rate", "avg_frequency", "avg_recency"])
if "avg_return_rate" in rfm_summary.columns:
    rfm_summary["avg_return_rate_pct"] = fix_percent_series(rfm_summary["avg_return_rate"])
else:
    rfm_summary["avg_return_rate_pct"] = np.nan

# ===== Sidebar filters =====
st.sidebar.header("Filters")

# Filter waktu dari monthly_rev 
min_dt = monthly_rev["order_month"].min()
max_dt = monthly_rev["order_month"].max()

start_dt, end_dt = st.sidebar.date_input(
    "Date Range",
    value=(min_dt.date() if pd.notna(min_dt) else None, max_dt.date() if pd.notna(max_dt) else None),
)

def filter_date(df, date_col, start, end):
    if date_col not in df.columns or start is None or end is None:
        return df
    s = pd.to_datetime(start)
    e = pd.to_datetime(end)
    return df[(df[date_col] >= s) & (df[date_col] <= e)].copy()

monthly_rev_f = filter_date(monthly_rev, "order_month", start_dt, end_dt)
mom_growth_f  = filter_date(mom_growth,  "order_month", start_dt, end_dt)
ret_month_f   = filter_date(ret_month,   "order_month",   start_dt, end_dt)

# ===== KPI calculations =====
total_revenue = monthly_rev_f["revenue"].sum()
avg_monthly_revenue = monthly_rev_f["revenue"].mean()
avg_mom_growth = mom_growth_f["mom_growth_pct"].mean()
avg_return_rate = ret_month_f["return_rate_pct"].mean()

# ===== Page layout =====
st.title("Ecommerce Business Dashboard")

col1, col2, col3, col4 = st.columns(4)
col1.metric("Total Revenue", f"{total_revenue:,.0f}")
col2.metric("Avg Monthly Revenue", f"{avg_monthly_revenue:,.0f}")
col3.metric("Avg MoM Growth (%)", f"{avg_mom_growth:,.2f}")
col4.metric("Avg Return Rate (%)", f"{avg_return_rate:,.2f}")

st.divider()

# ===== Charts =====
left, right = st.columns(2)

with left:
    st.subheader("Revenue by Month")
    rev_plot = monthly_rev_f.sort_values("order_month").set_index("order_month")["revenue"]
    st.line_chart(rev_plot)

with right:
    st.subheader("Return Rate by Month (%)")
    rr_plot = ret_month_f.sort_values("order_month").set_index("order_month")["return_rate_pct"]
    st.line_chart(rr_plot)

st.divider()

colA, colB = st.columns(2)

with colA:
    st.subheader("MoM Revenue Growth (%)")
    mg_plot = mom_growth_f.sort_values("order_month").set_index("order_month")["mom_growth_pct"]
    st.line_chart(mg_plot)

with colB:
    st.subheader("Total Revenue by Customer Segment")
    seg_plot = seg_summary.set_index("segment")["total_revenue"].sort_values(ascending=False)
    st.bar_chart(seg_plot)

st.divider()

colC, colD = st.columns(2)
with colC:
    st.subheader("Return Rate by Category (Top 10)")
    top_cat = ret_cat.dropna(subset=["return_rate_pct"]).sort_values("return_rate_pct", ascending=False).head(10)
    st.dataframe(top_cat[["product_category", "return_rate_pct", "total_items"]], use_container_width=True)

with colD:
    st.subheader("Return Rate by Brand (Top 10)")
    top_brand = ret_brand.dropna(subset=["return_rate_pct"]).sort_values("return_rate_pct", ascending=False).head(10)
    st.dataframe(top_brand[["product_brand", "return_rate_pct", "total_items", "revenue"]], use_container_width=True)

st.divider()

st.subheader("RFM Summary (Top by Revenue)")
rfm_show = rfm_summary.sort_values("total_revenue", ascending=False).head(15)
st.dataframe(
    rfm_show[["rfm_code", "customers", "total_revenue", "avg_frequency", "avg_recency", "avg_return_rate_pct"]],
    use_container_width=True
)

with st.expander("Data Quality Checks (quick)"):
    st.write("Return rate monthly (describe):")
    st.write(ret_month_f["return_rate_pct"].describe())
    st.write("MoM growth (describe):")
    st.write(mom_growth_f["mom_growth_pct"].describe())
