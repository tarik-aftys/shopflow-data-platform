# ShopFlow Data Platform — Architecture Documentation

## 🏗️ Overview

The **ShopFlow Data Platform** is a production-ready, end-to-end data engineering solution that implements modern data warehouse design patterns using the **Olist Brazilian E-Commerce dataset**. The platform demonstrates industry best practices for data ingestion, transformation, modeling, and analytics.

## 📐 Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         DATA SOURCES                                     │
├─────────────────────────────────────────────────────────────────────────┤
│  Olist Brazilian E-Commerce Dataset (CSV Files)                         │
│  - Customers, Orders, Order Items, Products, Payments                   │
│  - Sellers, Geolocation, Reviews, Category Translations                 │
└────────────────────────────┬────────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    INGESTION LAYER (Airflow)                             │
├─────────────────────────────────────────────────────────────────────────┤
│  Python Script: load_olist_data.py                                      │
│  - Reads CSV files from /data/raw/                                      │
│  - Loads into PostgreSQL raw tables                                     │
│  - Automated via Airflow DAG (daily schedule)                           │
└────────────────────────────┬────────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                   RAW LAYER (PostgreSQL)                                 │
├─────────────────────────────────────────────────────────────────────────┤
│  Tables: raw_customers, raw_orders, raw_order_items,                    │
│         raw_products, raw_payments, raw_sellers,                        │
│         raw_geolocation, raw_product_category_translation               │
│  - Exact copy of source data                                            │
│  - No transformations applied                                           │
│  - Immutable historical record                                          │
└────────────────────────────┬────────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                  TRANSFORMATION LAYER (dbt)                              │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌──────────────────────────────────────────────────────────────┐      │
│  │ STAGING LAYER (Views)                                         │      │
│  ├──────────────────────────────────────────────────────────────┤      │
│  │ stg_customers, stg_orders, stg_order_items, stg_products,    │      │
│  │ stg_payments, stg_sellers, stg_geolocation, stg_reviews      │      │
│  │ - Data cleaning & standardization                            │      │
│  │ - Column renaming & type casting                             │      │
│  │ - Basic business logic                                        │      │
│  └────────────────────────┬─────────────────────────────────────┘      │
│                           │                                             │
│                           ▼                                             │
│  ┌──────────────────────────────────────────────────────────────┐      │
│  │ INTERMEDIATE LAYER (Views)                                    │      │
│  ├──────────────────────────────────────────────────────────────┤      │
│  │ int_customer_lifetime_value (RFM analysis)                   │      │
│  │ int_product_performance (sales metrics)                      │      │
│  │ - Complex aggregations                                        │      │
│  │ - Feature engineering                                         │      │
│  │ - Reusable business logic                                     │      │
│  └────────────────────────┬─────────────────────────────────────┘      │
│                           │                                             │
│                           ▼                                             │
│  ┌──────────────────────────────────────────────────────────────┐      │
│  │ MARTS LAYER (Tables) - STAR SCHEMA                            │      │
│  ├──────────────────────────────────────────────────────────────┤      │
│  │ DIMENSIONS:                                                   │      │
│  │  - dim_date (calendar dimension)                             │      │
│  │  - dim_customer (customer attributes + metrics)              │      │
│  │  - dim_product (product catalog + categories)                │      │
│  │  - dim_seller (seller information)                           │      │
│  │                                                               │      │
│  │ FACTS:                                                        │      │
│  │  - fact_sales (grain: one row per order item)                │      │
│  │    • Foreign keys to all dimensions                          │      │
│  │    • Additive measures: revenue, freight, profit             │      │
│  │    • Delivery & review metrics                               │      │
│  │                                                               │      │
│  │ SNAPSHOTS (SCD Type 2):                                       │      │
│  │  - customer_snapshot (historical customer changes)           │      │
│  │  - product_snapshot (historical product changes)             │      │
│  │  - seller_snapshot (historical seller changes)               │      │
│  └──────────────────────────────────────────────────────────────┘      │
│                                                                          │
└────────────────────────────┬────────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                      ANALYTICS LAYER (SQL)                               │
├─────────────────────────────────────────────────────────────────────────┤
│  13+ Advanced SQL Queries:                                              │
│  1. Monthly Revenue Trend                                               │
│  2. Top Products by Category                                            │
│  3. Customer Cohort Analysis                                            │
│  4. Customer Lifetime Value (CLV)                                       │
│  5. Product Affinity Analysis                                           │
│  6. Seasonal Sales Patterns                                             │
│  7. RFM Customer Segmentation                                           │
│  8. Inventory Turnover                                                  │
│  9. Geographic Sales Distribution                                       │
│  10. Price Elasticity Analysis                                          │
│  + Delivery Performance, Payment Methods, Seller Leaderboard            │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 🔄 Data Pipeline Flow

### 1. **Ingestion (Airflow)**

**Trigger**: Scheduled daily at 06:00 UTC

**Process**:
1. Check CSV files exist in `/data/raw/`
2. Load CSV data into PostgreSQL raw tables
3. Trigger dbt transformation pipeline

**Key Files**:
- `airflow/dags/shopflow_pipeline.py` — Main DAG
- `airflow/scripts/load_olist_data.py` — Python data loader

---

### 2. **Transformation (dbt)**

#### **Staging Layer** (`models/staging/`)
- **Materialization**: Views
- **Purpose**: Clean and standardize data from raw tables
- **Operations**:
  - Column renaming (snake_case)
  - Type casting timestamps
  - Joining category translations (Portuguese → English)
  - Basic calculated fields
  - Data quality filters (remove nulls, negatives)

#### **Intermediate Layer** (`models/intermediate/`)
- **Materialization**: Views
- **Purpose**: Business logic and feature engineering
- **Models**:
  - `int_customer_lifetime_value`: RFM segmentation, CLV calculation
  - `int_product_performance`: Product metrics, ratings, inventory turnover

#### **Marts Layer** (`models/marts/`)
- **Materialization**: Tables (incremental for facts)
- **Purpose**: Production-ready dimensional model
- **Star Schema**:
  - **Fact Table**: `fact_sales` (grain: order item)
  - **Dimensions**: `dim_date`, `dim_customer`, `dim_product`, `dim_seller`

#### **Snapshots** (`snapshots/`)
- **Strategy**: Timestamp-based SCD Type 2
- **Purpose**: Track historical changes in dimensions
- **Columns Added**: `dbt_valid_from`, `dbt_valid_to`, `dbt_scd_id`

---

## 🎯 Design Patterns & Best Practices

### **1. Medallion Architecture**
- **Bronze** (Raw Layer): Untransformed source data
- **Silver** (Staging/Intermediate): Cleaned and enriched data
- **Gold** (Marts): Business-ready dimensional model

### **2. Star Schema**
- **Fact Table**: Additive measures at atomic grain
- **Dimensions**: Descriptive attributes with surrogate keys
- **Conformed Dimensions**: Shared across marts

### **3. Slowly Changing Dimensions (SCD Type 2)**
- Preserves full history of dimension changes
- Enables time-travel queries
- Implemented via dbt snapshots

### **4. Incremental Loading**
- `fact_sales` uses incremental materialization
- Only processes new/changed data after initial load
- Performance optimization for large datasets

### **5. Data Quality Testing**
- **Primary Key Tests**: Uniqueness and not-null
- **Referential Integrity**: Foreign key relationships
- **Accepted Values**: Categorical field validation
- **Custom Tests**: Business rule enforcement

---

## 🛠️ Technology Stack

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Orchestration** | Apache Airflow | Workflow scheduling and monitoring |
| **Data Warehouse** | PostgreSQL 16 | OLAP database for analytics |
| **Transformation** | dbt (Data Build Tool) | SQL-based ELT framework |
| **Data Source** | Olist Dataset (CSV) | Brazilian e-commerce data |
| **Containerization** | Docker & Docker Compose | Infrastructure deployment |
| **Programming** | Python 3.11 | Data loading scripts |
| **Version Control** | Git | Code versioning |

---

## 📊 Key Metrics & KPIs

The platform enables analysis of:

1. **Revenue Metrics**: Total sales, growth rates, profitability
2. **Customer Analytics**: CLV, retention, RFM segments, churn
3. **Product Performance**: Best sellers, turnover, margins
4. **Operational Metrics**: Delivery times, on-time rates
5. **Geographic Analysis**: Sales by state, cross-region shipping
6. **Payment Behavior**: Method preferences, installment usage

---

## 🔐 Data Governance

### **Data Lineage**
- Fully tracked through dbt's DAG
- From raw → staging → intermediate → marts
- Documented in dbt docs (`dbt docs generate`)

### **Testing Framework**
- Source data quality checks
- Transformation validation
- Referential integrity enforcement
- Business logic tests

### **Schema Evolution**
- `on_schema_change='sync_all_columns'` for fact tables
- Non-breaking changes handled automatically

---

## 🚀 Deployment

### **Local Development**
```bash
docker-compose up
```

### **Production Considerations**
- Use managed Airflow (e.g., AWS MWAA, Google Cloud Composer)
- Leverage cloud data warehouses (Snowflake, BigQuery, Redshift)
- Implement CI/CD for dbt models
- Set up data quality monitoring (Great Expectations, dbt tests)

---

## 📚 Further Reading

- [dbt Best Practices](https://docs.getdbt.com/guides/best-practices)
- [Dimensional Modeling (Kimball)](https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/)
- [Apache Airflow Documentation](https://airflow.apache.org/docs/)
- [Olist Dataset on Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)

---

**Last Updated**: March 2026  
**Author**: Data Engineering Team  
**Project**: ShopFlow Data Platform v2.0
