









DROP TABLE IF EXISTS raw_order_items CASCADE;
DROP TABLE IF EXISTS raw_order_payments CASCADE;
DROP TABLE IF EXISTS raw_order_reviews CASCADE;
DROP TABLE IF EXISTS raw_orders CASCADE;
DROP TABLE IF EXISTS raw_customers CASCADE;
DROP TABLE IF EXISTS raw_products CASCADE;
DROP TABLE IF EXISTS raw_sellers CASCADE;
DROP TABLE IF EXISTS raw_geolocation CASCADE;
DROP TABLE IF EXISTS raw_product_category_translation CASCADE;




CREATE TABLE raw_customers (
    customer_id VARCHAR(32) NOT NULL,
    customer_unique_id VARCHAR(32),
    customer_zip_code_prefix VARCHAR(5),
    customer_city VARCHAR(100),
    customer_state VARCHAR(2),
    loaded_at TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (customer_id)
);



CREATE TABLE raw_orders (
    order_id VARCHAR(32) NOT NULL,
    customer_id VARCHAR(32),
    order_status VARCHAR(20),
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP,
    loaded_at TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (order_id)
);



CREATE TABLE raw_order_items (
    order_id VARCHAR(32) NOT NULL,
    order_item_id INTEGER NOT NULL,
    product_id VARCHAR(32),
    seller_id VARCHAR(32),
    shipping_limit_date TIMESTAMP,
    price NUMERIC(12,2),
    freight_value NUMERIC(12,2),
    loaded_at TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (order_id, order_item_id)
);



CREATE TABLE raw_order_payments (
    order_id VARCHAR(32) NOT NULL,
    payment_sequential INTEGER NOT NULL,
    payment_type VARCHAR(20),
    payment_installments INTEGER,
    payment_value NUMERIC(12,2),
    loaded_at TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (order_id, payment_sequential)
);



CREATE TABLE raw_products (
    product_id VARCHAR(32) NOT NULL,
    product_category_name VARCHAR(100),
    product_name_length NUMERIC(20,0),
    product_description_length NUMERIC(20,0),
    product_photos_qty NUMERIC(20,0),
    product_weight_g NUMERIC(20,0),
    product_length_cm NUMERIC(20,0),
    product_height_cm NUMERIC(20,0),
    product_width_cm NUMERIC(20,0),
    loaded_at TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (product_id)
);



CREATE TABLE raw_sellers (
    seller_id VARCHAR(32) NOT NULL,
    seller_zip_code_prefix VARCHAR(5),
    seller_city VARCHAR(100),
    seller_state VARCHAR(2),
    loaded_at TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (seller_id)
);



CREATE TABLE raw_geolocation (
    geolocation_zip_code_prefix VARCHAR(5) NOT NULL,
    geolocation_lat NUMERIC(10,8),
    geolocation_lng NUMERIC(11,8),
    geolocation_city VARCHAR(100),
    geolocation_state VARCHAR(2),
    loaded_at TIMESTAMP NOT NULL DEFAULT NOW()
);


CREATE INDEX idx_geolocation_zip ON raw_geolocation(geolocation_zip_code_prefix);



CREATE TABLE raw_product_category_translation (
    product_category_name VARCHAR(100) NOT NULL,
    product_category_name_english VARCHAR(100),
    loaded_at TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (product_category_name)
);



CREATE TABLE raw_order_reviews (
    review_id VARCHAR(32) NOT NULL,
    order_id VARCHAR(32),
    review_score INTEGER,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP,
    loaded_at TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (review_id)
);



CREATE INDEX idx_raw_orders_customer_id ON raw_orders(customer_id);
CREATE INDEX idx_raw_order_items_order_id ON raw_order_items(order_id);
CREATE INDEX idx_raw_order_items_product_id ON raw_order_items(product_id);
CREATE INDEX idx_raw_order_items_seller_id ON raw_order_items(seller_id);
CREATE INDEX idx_raw_order_payments_order_id ON raw_order_payments(order_id);
CREATE INDEX idx_raw_order_reviews_order_id ON raw_order_reviews(order_id);





