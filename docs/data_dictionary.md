# ShopFlow Data Platform — Data Dictionary

## 📖 Overview

This document provides comprehensive column-level documentation for all tables in the ShopFlow data warehouse, organized by data layer.

---

## 🗂️ Table of Contents

1. [Raw Layer](#raw-layer)
2. [Staging Layer](#staging-layer)
3. [Intermediate Layer](#intermediate-layer)
4. [Marts Layer (Star Schema)](#marts-layer-star-schema)
5. [Snapshots (SCD Type 2)](#snapshots-scd-type-2)

---

## Raw Layer

### raw_customers
**Source**: `olist_customers_dataset.csv`  
**Grain**: One row per customer_id  
**Description**: Customer master data from Olist marketplace

| Column | Type | Description | Example |
|--------|------|-------------|---------|
| `customer_id` | VARCHAR(32) | Unique customer identifier | `8d50f5ea...` |
| `customer_unique_id` | VARCHAR(32) | Unique customer across orders | `861eff48...` |
| `customer_zip_code_prefix` | VARCHAR(5) | First 5 digits of zip code | `14409` |
| `customer_city` | VARCHAR(100) | Customer city name | `São Paulo` |
| `customer_state` | VARCHAR(2) | Customer state (2-letter code) | `SP` |
| `loaded_at` | TIMESTAMP | ETL load timestamp | `2026-03-06 10:00:00` |

---

### raw_orders
**Source**: `olist_orders_dataset.csv`  
**Grain**: One row per order  
**Description**: Order header information

| Column | Type | Description | Example |
|--------|------|-------------|---------|
| `order_id` | VARCHAR(32) | Unique order identifier | `e48181...` |
| `customer_id` | VARCHAR(32) | Customer who placed order | `8d50f5ea...` |
| `order_status` | VARCHAR(20) | Order status | `delivered` |
| `order_purchase_timestamp` | TIMESTAMP | Purchase timestamp | `2017-10-02 10:56:33` |
| `order_approved_at` | TIMESTAMP | Approval timestamp | `2017-10-02 11:07:15` |
| `order_delivered_carrier_date` | TIMESTAMP | Handoff to carrier | `2017-10-04 19:55:00` |
| `order_delivered_customer_date` | TIMESTAMP | Delivered to customer | `2017-10-10 21:25:13` |
| `order_estimated_delivery_date` | TIMESTAMP | Estimated delivery | `2017-10-18 00:00:00` |

**Order Statuses**: `delivered`, `shipped`, `canceled`, `unavailable`, `invoiced`, `processing`, `created`, `approved`

---

### raw_order_items
**Source**: `olist_order_items_dataset.csv`  
**Grain**: One row per order item (order_id + order_item_id)  
**Description**: Line items within orders

| Column | Type | Description | Example |
|--------|------|-------------|---------|
| `order_id` | VARCHAR(32) | Order identifier | `e48181...` |
| `order_item_id` | INTEGER | Item sequence in order | `1` |
| `product_id` | VARCHAR(32) | Product identifier | `a2e4e4c8...` |
| `seller_id` | VARCHAR(32) | Seller identifier | `cc419e05...` |
| `shipping_limit_date` | TIMESTAMP | Seller shipping deadline | `2017-10-09 03:10:00` |
| `price` | NUMERIC(12,2) | Item price (BRL) | `29.99` |
| `freight_value` | NUMERIC(12,2) | Freight cost (BRL) | `8.72` |

---

### raw_products
**Source**: `olist_products_dataset.csv`  
**Grain**: One row per product  
**Description**: Product catalog with physical attributes

| Column | Type | Description | Example |
|--------|------|-------------|---------|
| `product_id` | VARCHAR(32) | Unique product ID | `a2e4e4c8...` |
| `product_category_name` | VARCHAR(100) | Category (Portuguese) | `cama_mesa_banho` |
| `product_name_length` | INTEGER | Length of product name | `58` |
| `product_description_length` | INTEGER | Length of description | `621` |
| `product_photos_qty` | INTEGER | Number of photos | `4` |
| `product_weight_g` | INTEGER | Weight in grams | `700` |
| `product_length_cm` | INTEGER | Length in cm | `26` |
| `product_height_cm` | INTEGER | Height in cm | `7` |
| `product_width_cm` | INTEGER | Width in cm | `17` |

---

## Staging Layer

### stg_customers
**Materialization**: View  
**Description**: Cleaned and standardized customer data

| Column | Type | Description | Business Logic |
|--------|------|-------------|----------------|
| `customer_id` | VARCHAR(32) | Primary key | - |
| `customer_unique_id` | VARCHAR(32) | Business key | Maps multiple customer_ids to single customer |
| `zip_code` | VARCHAR(5) | Zip code prefix | Renamed from `customer_zip_code_prefix` |
| `city` | VARCHAR(100) | City name | - |
| `state` | VARCHAR(2) | State code | - |
| `dbt_updated_at` | TIMESTAMP | dbt refresh time | Current timestamp |

---

### stg_orders
**Materialization**: View  
**Description**: Cleaned order data with calculated attributes

| Column | Type | Description | Business Logic |
|--------|------|-------------|----------------|
| `order_id` | VARCHAR(32) | Primary key | - |
| `customer_id` | VARCHAR(32) | Foreign key | - |
| `order_status` | VARCHAR(20) | Status | - |
| `order_date` | DATE | Purchase date | Cast from timestamp |
| `order_year` | INTEGER | Year | Extracted from timestamp |
| `order_month` | INTEGER | Month (1-12) | Extracted from timestamp |
| `order_quarter` | INTEGER | Quarter (1-4) | Extracted from timestamp |
| `delivery_days_vs_estimate` | INTEGER | Delay/Early days | `delivered_date - estimated_date` |
| `delivered_on_time` | BOOLEAN | On-time flag | `delivered_date <= estimated_date` |
| `is_delivered` | BOOLEAN | Delivered flag | `order_status = 'delivered'` |
| `is_canceled` | BOOLEAN | Canceled flag | `order_status = 'canceled'` |

---

### stg_products
**Materialization**: View  
**Description**: Products with English category names

| Column | Type | Description | Business Logic |
|--------|------|-------------|----------------|
| `product_id` | VARCHAR(32) | Primary key | - |
| `category_name` | VARCHAR(100) | Category (English) | Joined with translation table |
| `category_name_portuguese` | VARCHAR(100) | Original category | From raw table |
| `product_volume_cm3` | NUMERIC | Volume | `length × height × width` |
| `photo_quality_tier` | VARCHAR(10) | Photo quality | `High` (≥3), `Medium` (≥1), `Low` |
| `description_quality` | VARCHAR(10) | Description quality | `Detailed` (≥500), `Standard` (≥100), `Brief` |
| `is_uncategorized` | BOOLEAN | Missing category | `category_name IS NULL` |

---

## Marts Layer (Star Schema)

### dim_date
**Type**: Dimension  
**Materialization**: Table  
**Grain**: One row per calendar day  
**Date Range**: 2016-01-01 to 2020-12-31

| Column | Type | Description | Example |
|--------|------|-------------|---------|
| `date_key` | INTEGER | Primary key (YYYYMMDD) | `20171002` |
| `date` | DATE | Full date | `2017-10-02` |
| `day_of_week` | SMALLINT | Day (1=Mon, 7=Sun) | `1` |
| `day_name` | VARCHAR(10) | Day name | `Monday` |
| `week_of_year` | SMALLINT | Week number (1-53) | `40` |
| `month_number` | SMALLINT | Month (1-12) | `10` |
| `month_name` | VARCHAR(10) | Month name | `October` |
| `quarter` | SMALLINT | Quarter (1-4) | `4` |
| `year` | INTEGER | Year | `2017` |
| `is_weekend` | BOOLEAN | Weekend flag | `FALSE` |
| `is_holiday` | BOOLEAN | Brazilian holiday | `FALSE` |
| `year_month` | VARCHAR(7) | YYYY-MM | `2017-10` |
| `year_quarter` | VARCHAR(7) | YYYY-Qn | `2017-Q4` |

---

### dim_customer
**Type**: Dimension  
**Materialization**: Table  
**Grain**: One row per customer (current state)

| Column | Type | Description | Business Logic |
|--------|------|-------------|----------------|
| `customer_key` | VARCHAR(32) | Surrogate key | Generated hash |
| `customer_id` | VARCHAR(32) | Business key | From staging |
| `customer_unique_id` | VARCHAR(32) | Unique customer ID | - |
| `state` | VARCHAR(2) | State code | - |
| `city` | VARCHAR(100) | City name | - |
| `latitude` | NUMERIC | Geo coordinate | From geolocation table |
| `longitude` | NUMERIC | Geo coordinate | From geolocation table |
| `total_orders` | INTEGER | Order count | Aggregated from fact_sales |
| `delivered_orders` | INTEGER | Successful orders | Where `is_delivered = TRUE` |
| `first_order_date` | DATE | First purchase | MIN(order_date) |
| `last_order_date` | DATE | Most recent purchase | MAX(order_date) |
| `customer_segment` | VARCHAR(20) | Segmentation | `Repeat`, `Second-time`, `One-time` |
| `lifecycle_status` | VARCHAR(20) | Status | `Active`, `At Risk`, `Churned` |

---

### dim_product
**Type**: Dimension  
**Materialization**: Table  
**Grain**: One row per product (current state)

| Column | Type | Description | Business Logic |
|--------|------|-------------|----------------|
| `product_key` | VARCHAR(32) | Surrogate key | Generated hash |
| `product_id` | VARCHAR(32) | Business key | From staging |
| `category_name` | VARCHAR(100) | Category (English) | - |
| `product_weight_g` | INTEGER | Weight (grams) | - |
| `product_volume_cm3` | NUMERIC | Volume | Calculated |
| `total_orders` | INTEGER | Orders containing product | From fact_sales |
| `total_items_sold` | INTEGER | Units sold | COUNT(*) from fact_sales |
| `total_revenue` | NUMERIC | Lifetime revenue | SUM(item_price) |
| `avg_selling_price` | NUMERIC | Average price | AVG(item_price) |
| `performance_tier` | VARCHAR(20) | Performance class | Based on sales volume |
| `photo_quality_tier` | VARCHAR(10) | Photo quality | `High`, `Medium`, `Low` |

---

### dim_seller
**Type**: Dimension  
**Materialization**: Table  
**Grain**: One row per seller

| Column | Type | Description | Business Logic |
|--------|------|-------------|----------------|
| `seller_key` | VARCHAR(32) | Surrogate key | Generated hash |
| `seller_id` | VARCHAR(32) | Business key | From staging |
| `state` | VARCHAR(2) | Seller state | - |
| `city` | VARCHAR(100) | Seller city | - |
| `total_orders` | INTEGER | Orders fulfilled | From fact_sales |
| `total_revenue` | NUMERIC | Total sales | SUM(item_price) |
| `seller_tier` | VARCHAR(20) | Tier | `Enterprise`, `Professional`, `Growing`, `Small` |

---

### fact_sales
**Type**: Fact Table  
**Materialization**: Incremental Table  
**Grain**: One row per order item  
**Update Strategy**: Append new/changed orders based on `order_purchase_timestamp`

| Column | Type | Description | Example |
|--------|------|-------------|---------|
| `sales_key` | VARCHAR(64) | Surrogate key | Generated from order_id + order_item_id |
| `date_key` | INTEGER | FK to dim_date | `20171002` |
| `customer_key` | VARCHAR(32) | FK to dim_customer | Hash value |
| `product_key` | VARCHAR(32) | FK to dim_product | Hash value |
| `seller_key` | VARCHAR(32) | FK to dim_seller | Hash value |
| `order_id` | VARCHAR(32) | Degenerate dimension | `e48181...` |
| `order_item_id` | INTEGER | Degenerate dimension | `1` |
| `item_price` | NUMERIC(12,2) | Item price (BRL) | `29.99` |
| `freight_value` | NUMERIC(12,2) | Freight cost (BRL) | `8.72` |
| `total_price` | NUMERIC(12,2) | Item + freight | `38.71` |
| `estimated_gross_profit` | NUMERIC(12,2) | Profit estimate | `item_price × 0.70` |
| `gross_margin_pct` | NUMERIC(5,2) | Margin % | `70.00` |
| `actual_delivery_days` | NUMERIC(6,2) | Delivery time | `8.44` |
| `delivered_on_time` | BOOLEAN | On-time flag | `TRUE` |
| `is_delivered` | BOOLEAN | Delivered flag | `TRUE` |
| `avg_review_score` | NUMERIC(3,2) | Review score (1-5) | `4.5` |

**Additive Measures**: `item_price`, `freight_value`, `total_price`, `estimated_gross_profit`  
**Semi-Additive Measures**: `order_payment_value` (aggregate at order level)  
**Non-Additive Measures**: `avg_review_score`, `gross_margin_pct` (require special handling)

---

## Intermediate Layer

### int_customer_lifetime_value
**Materialization**: View  
**Description**: Customer RFM segmentation and CLV metrics

| Column | Type | Description | Calculation |
|--------|------|-------------|-------------|
| `customer_key` | VARCHAR(32) | Primary key | - |
| `total_orders` | INTEGER | Order count | COUNT(DISTINCT order_id) |
| `lifetime_value` | NUMERIC | Total spend | SUM(total_price) |
| `recency_days` | INTEGER | Days since last order | CURRENT_DATE - last_order_date |
| `recency_score` | INTEGER | RFM recency (1-5) | NTILE(5) |
| `frequency_score` | INTEGER | RFM frequency (1-5) | NTILE(5) |
| `monetary_score` | INTEGER | RFM monetary (1-5) | NTILE(5) |
| `rfm_score` | NUMERIC | Average RFM | (R + F + M) / 3 |
| `customer_rfm_segment` | VARCHAR(30) | RFM segment | `Champions`, `Loyal`, `At Risk`, etc. |

**RFM Segments**:
- **Champions**: High recency + high frequency
- **Loyal Customers**: High monetary + high frequency
- **At Risk**: Low recency + high frequency
- **Lost**: Low recency
- **Promising**: High recency + low frequency

---

## Snapshots (SCD Type 2)

### customer_snapshot, product_snapshot, seller_snapshot
**Strategy**: Timestamp-based SCD Type 2  
**Auto-Generated Columns by dbt**:

| Column | Type | Description |
|--------|------|-------------|
| `dbt_scd_id` | VARCHAR(32) | Unique snapshot record ID |
| `dbt_valid_from` | TIMESTAMP | Version start timestamp |
| `dbt_valid_to` | TIMESTAMP | Version end timestamp (NULL if current) |
| `dbt_updated_at` | TIMESTAMP | Last update timestamp |

**Usage**:
```sql
-- Get current records
SELECT * FROM customer_snapshot WHERE dbt_valid_to IS NULL;

-- Get historical state at specific date
SELECT * FROM customer_snapshot 
WHERE '2017-10-01' BETWEEN dbt_valid_from AND COALESCE(dbt_valid_to, '9999-12-31');
```

---

## 🔍 Data Types Reference

| PostgreSQL Type | Description | Example |
|----------------|-------------|---------|
| `VARCHAR(n)` | Variable character string | `São Paulo` |
| `INTEGER` | 4-byte integer | `12345` |
| `SMALLINT` | 2-byte integer | `7` |
| `NUMERIC(p,s)` | Exact numeric with precision | `29.99` |
| `BOOLEAN` | True/false | `TRUE` |
| `DATE` | Date (no time) | `2017-10-02` |
| `TIMESTAMP` | Date with time | `2017-10-02 10:56:33` |

---

**Last Updated**: March 2026  
**Maintained By**: Data Engineering Team
