# Olist Brazilian E-Commerce Dataset

## Dataset Source
**Olist Brazilian E-Commerce Public Dataset**
- Available at: https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce
- License: CC BY-NC-SA 4.0

## Instructions

1. Download the dataset from Kaggle
2. Extract all CSV files to this directory (`data/raw/`)

## Expected Files

The following CSV files should be placed here:

```
data/raw/
├── olist_customers_dataset.csv
├── olist_geolocation_dataset.csv
├── olist_order_items_dataset.csv
├── olist_order_payments_dataset.csv
├── olist_order_reviews_dataset.csv
├── olist_orders_dataset.csv
├── olist_products_dataset.csv
├── olist_sellers_dataset.csv
└── product_category_name_translation.csv
```

## Dataset Overview

### 1. **olist_customers_dataset.csv**
- `customer_id` (unique)
- `customer_unique_id`
- `customer_zip_code_prefix`
- `customer_city`
- `customer_state`

### 2. **olist_orders_dataset.csv**
- `order_id` (unique)
- `customer_id`
- `order_status`
- `order_purchase_timestamp`
- `order_approved_at`
- `order_delivered_carrier_date`
- `order_delivered_customer_date`
- `order_estimated_delivery_date`

### 3. **olist_order_items_dataset.csv**
- `order_id`
- `order_item_id`
- `product_id`
- `seller_id`
- `shipping_limit_date`
- `price`
- `freight_value`

### 4. **olist_order_payments_dataset.csv**
- `order_id`
- `payment_sequential`
- `payment_type`
- `payment_installments`
- `payment_value`

### 5. **olist_products_dataset.csv**
- `product_id` (unique)
- `product_category_name`
- `product_name_length`
- `product_description_length`
- `product_photos_qty`
- `product_weight_g`
- `product_length_cm`
- `product_height_cm`
- `product_width_cm`

### 6. **olist_sellers_dataset.csv**
- `seller_id` (unique)
- `seller_zip_code_prefix`
- `seller_city`
- `seller_state`

### 7. **olist_geolocation_dataset.csv**
- `geolocation_zip_code_prefix`
- `geolocation_lat`
- `geolocation_lng`
- `geolocation_city`
- `geolocation_state`

### 8. **product_category_name_translation.csv**
- `product_category_name` (Portuguese)
- `product_category_name_english`

## Data Statistics

- **Orders**: ~100,000
- **Customers**: ~99,000
- **Products**: ~32,000
- **Sellers**: ~3,000
- **Date Range**: 2016-09-04 to 2018-10-17
- **Total Revenue**: ~R$ 16 million
