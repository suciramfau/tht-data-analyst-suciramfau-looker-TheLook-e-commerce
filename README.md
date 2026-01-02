# End-to-End Ecommerce Analytics

Looker Ecommerce Dataset | Data Analyst Portfolio Project

## Project Overview

This project demonstrates an end-to-end data analytics workflow using the Looker Ecommerce public dataset.
The objective is to transform raw, normalized ecommerce data into business-ready insights through structured SQL modeling, exploratory analysis in Python, and an interactive Streamlit dashboard.

The project emphasizes:

* Strong data modeling in SQL

* Clear analytical reasoning

* Business-oriented insights

* Reproducible and well-documented analytics pipeline

## Business Objectives

Key business questions addressed in this project:

* How does ecommerce revenue grow over time?

* How stable is month-over-month revenue growth?

* What is the overall return rate, and how does it vary by category and brand?

* Which customer segments contribute the most value to the business?

* How can analytics outputs be packaged for stakeholder consumption?

--- 

## Dataset Overview

Source: Looker Ecommerce Dataset
Initial Tables: 7 normalized tables, including:

1. users
2. orders
3. order_items
4. products
5. inventory_items
6. distribution_centers
7. events

The raw dataset is highly normalized, requiring data modeling and aggregation before analysis.

---

## Data Modeling (SQL Layer)

SQL is used as the primary transformation layer to ensure correctness and scalability.

**Key SQL Activities:**
* Joining transactional and dimensional tables
* Building a clean fact table at order-item level
* Deriving business metrics:
    * Revenue
    * Cost & margin
    * Return indicators
* Aggregating data for analytics use cases

**Outputs from SQL:**
* Clean analytical tables
* CSV exports for downstream analytics (Python & dashboards)
An Entity Relationship Diagram (ERD) is used to validate joins and avoid data duplication.

---

## Python Analytics & EDA

Python is used for Exploratory Data Analysis (EDA) and feature engineering.

**Key Activities:**
* Data quality validation (missing values, datatypes)
* Revenue trend analysis
* Month-over-Month (MoM) revenue growth calculation
* Return rate analysis (monthly, by category, by brand)
* Customer segmentation using RFM analysis

**Key Metrics Engineered:**
* Monthly revenue
* MoM revenue growth (%)
* Return rate (%)
* RFM scores and segment labels
All numeric fields are kept BI- and dashboard-ready (no formatted strings).

---
## Key Business Insights (Summary)

* Revenue shows a consistent upward trend, with stronger acceleration after 2022.
* MoM revenue growth is volatile in early periods but stabilizes over time.
* Overall return rate remains relatively stable (~10%), indicating controlled operations.
* Fit-sensitive product categories exhibit higher return rates.
* High-value customer segments contribute a disproportionate share of revenue.

---
## Streamlit Dashboard

An interactive Streamlit app is built to present insights in a stakeholder-friendly format.

Dashboard Features:

* KPI cards (Revenue, Growth, Return Rate)
* Revenue trend visualization
* MoM revenue growth analysis
* Return rate by time, category, and brand
* Customer segmentation summary (RFM)

The dashboard enables lightweight exploration without requiring BI tools.

---
## Project Structure

---
## Tools & Technologies
* SQL: PostgreSQL
* Python: pandas, numpy, matplotlib, seaborn
* Dashboard: Streamlit
* Version Control: GitHub
* Documentation: Markdown / Notion

---
## Limitations
* Analysis is descriptive (no predictive modeling)
* Static historical dataset
* No automated data ingestion pipeline

---
## Future Improvements
* Power BI or Looker Studio dashboard
* Customer churn or return prediction (Machine Learning)
* Cohort and retention analysis
* Automated pipeline (dbt / Airflow)

---------------
Live Demo: [Streamlit](https://tht-data-analyst-suciramfau-looker-thelook-e-commerce.streamlit.app/)

Author
Suci Ramadhani Fauzi | Data Analyst

Email: suciramfau15@gmail.com

LinkedIn:[View Profile](https://www.linkedin.com/in/suciramadhanifauzi/)

Portfolio in Notion:[View Notion](https://www.notion.so/Suci-Ramadhani-Fauzi-Dashboard-2d22490fec64804ca096d8f4cee4c7ac)
