









CREATE TABLE dim_date (
    date_key       INTEGER     PRIMARY KEY,   
    full_date      DATE        NOT NULL UNIQUE,
    day_of_week    SMALLINT    NOT NULL,       
    day_name       VARCHAR(10) NOT NULL,
    day_of_month   SMALLINT    NOT NULL,
    day_of_year    SMALLINT    NOT NULL,
    week_of_year   SMALLINT    NOT NULL,
    month_number   SMALLINT    NOT NULL,
    month_name     VARCHAR(10) NOT NULL,
    quarter        SMALLINT    NOT NULL,
    year           INTEGER     NOT NULL,
    is_weekend     BOOLEAN     NOT NULL,
    is_holiday     BOOLEAN     NOT NULL DEFAULT FALSE,
    fiscal_quarter SMALLINT,
    fiscal_year    INTEGER
);




CREATE TABLE dim_customer (
    customer_key   SERIAL      PRIMARY KEY,   
    customer_id    INTEGER     NOT NULL,       
    first_name     VARCHAR(100) NOT NULL,
    last_name      VARCHAR(100) NOT NULL,
    email          VARCHAR(255) NOT NULL,
    phone          VARCHAR(30),
    gender         VARCHAR(10),
    date_of_birth  DATE,
    city           VARCHAR(100),
    state          VARCHAR(100),
    country        VARCHAR(100),
    
    valid_from     TIMESTAMP   NOT NULL,
    valid_to       TIMESTAMP   NOT NULL DEFAULT '9999-12-31 23:59:59',
    is_current     BOOLEAN     NOT NULL DEFAULT TRUE
);

CREATE INDEX idx_dim_customer_natural ON dim_customer(customer_id, is_current);




CREATE TABLE dim_product (
    product_key    SERIAL      PRIMARY KEY,   
    product_id     INTEGER     NOT NULL,       
    product_name   VARCHAR(255) NOT NULL,
    sku            VARCHAR(50)  NOT NULL,
    category_name  VARCHAR(100) NOT NULL,
    brand_name     VARCHAR(100),
    unit_price     NUMERIC(12,2) NOT NULL,
    cost_price     NUMERIC(12,2),
    is_active      BOOLEAN     NOT NULL,
    
    valid_from     TIMESTAMP   NOT NULL,
    valid_to       TIMESTAMP   NOT NULL DEFAULT '9999-12-31 23:59:59',
    is_current     BOOLEAN     NOT NULL DEFAULT TRUE
);

CREATE INDEX idx_dim_product_natural ON dim_product(product_id, is_current);





CREATE TABLE fact_sales (
    sales_key        SERIAL        PRIMARY KEY,
    order_id         INTEGER       NOT NULL,
    order_item_id    INTEGER       NOT NULL,
    order_number     VARCHAR(30)   NOT NULL,

    
    date_key         INTEGER       NOT NULL REFERENCES dim_date(date_key),
    customer_key     INTEGER       NOT NULL REFERENCES dim_customer(customer_key),
    product_key      INTEGER       NOT NULL REFERENCES dim_product(product_key),

    
    order_status     VARCHAR(30)   NOT NULL,
    payment_method   VARCHAR(50),

    
    quantity         INTEGER       NOT NULL,
    unit_price       NUMERIC(12,2) NOT NULL,
    discount_pct     NUMERIC(5,2)  NOT NULL DEFAULT 0,
    line_total       NUMERIC(12,2) NOT NULL,
    tax_amount       NUMERIC(12,2) NOT NULL DEFAULT 0,
    shipping_cost    NUMERIC(12,2) NOT NULL DEFAULT 0,
    cost_amount      NUMERIC(12,2),          
    profit_amount    NUMERIC(12,2)           
);

CREATE INDEX idx_fact_sales_date     ON fact_sales(date_key);
CREATE INDEX idx_fact_sales_customer ON fact_sales(customer_key);
CREATE INDEX idx_fact_sales_product  ON fact_sales(product_key);
CREATE INDEX idx_fact_sales_order    ON fact_sales(order_id);





INSERT INTO dim_date (
    date_key, full_date, day_of_week, day_name, day_of_month,
    day_of_year, week_of_year, month_number, month_name,
    quarter, year, is_weekend, fiscal_quarter, fiscal_year
)
SELECT
    TO_CHAR(d, 'YYYYMMDD')::INTEGER                       AS date_key,
    d                                                       AS full_date,
    EXTRACT(ISODOW FROM d)::SMALLINT                       AS day_of_week,
    TO_CHAR(d, 'Day')                                      AS day_name,
    EXTRACT(DAY FROM d)::SMALLINT                          AS day_of_month,
    EXTRACT(DOY FROM d)::SMALLINT                          AS day_of_year,
    EXTRACT(WEEK FROM d)::SMALLINT                         AS week_of_year,
    EXTRACT(MONTH FROM d)::SMALLINT                        AS month_number,
    TO_CHAR(d, 'Month')                                    AS month_name,
    EXTRACT(QUARTER FROM d)::SMALLINT                      AS quarter,
    EXTRACT(YEAR FROM d)::INTEGER                          AS year,
    CASE WHEN EXTRACT(ISODOW FROM d) IN (6, 7) THEN TRUE ELSE FALSE END AS is_weekend,
    EXTRACT(QUARTER FROM d)::SMALLINT                      AS fiscal_quarter,
    EXTRACT(YEAR FROM d)::INTEGER                          AS fiscal_year
FROM generate_series('2023-01-01'::DATE, '2025-12-31'::DATE, '1 day'::INTERVAL) AS d;
