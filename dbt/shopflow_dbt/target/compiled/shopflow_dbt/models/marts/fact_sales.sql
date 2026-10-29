

-- =================================================================
-- fact_sales.sql
-- =================================================================
-- Fact table at the grain of ONE ROW PER ORDER ITEM
-- Central fact table in the star schema
-- =================================================================
-- Conforms to the dimensional model with surrogate keys to:
--   - dim_date
--   - dim_customer
--   - dim_product
--   - dim_seller
-- =================================================================

with order_items as (
    select * from "shopflow_warehouse"."public_staging"."stg_order_items"
),

orders as (
    select * from "shopflow_warehouse"."public_staging"."stg_orders"
),

-- Aggregate payments by order
order_payments as (
    select
        order_id,
        sum(payment_value) as total_payment_value,
        max(payment_type_standardized) as primary_payment_type,
        max(case when is_installment then true else false end) as has_installment,
        sum(payment_installments) as total_installments
    from "shopflow_warehouse"."public_staging"."stg_payments"
    group by order_id
),

-- Get primary review score per order
order_reviews as (
    select
        order_id,
        avg(review_score) as avg_review_score,
        max(review_score) as max_review_score,
        min(review_score) as min_review_score,
        count(*) as review_count
    from "shopflow_warehouse"."public_staging"."stg_order_reviews"
    group by order_id
),

-- Get dimension surrogate keys
dim_customer as (
    select
        customer_id,
        customer_key
    from "shopflow_warehouse"."public_marts"."dim_customer"
),

dim_product as (
    select
        product_id,
        product_key
    from "shopflow_warehouse"."public_marts"."dim_product"
),

dim_seller as (
    select
        seller_id,
        seller_key
    from "shopflow_warehouse"."public_marts"."dim_seller"
),

-- Join all components
fact as (
    select
        -- Surrogate key (unique identifier for this fact record)
        md5(cast(coalesce(cast(oi.order_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(oi.order_item_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as sales_key,
        
        -- Foreign keys to dimensions
        cast(to_char(o.order_date, 'YYYYMMDD') as integer) as date_key,
        dc.customer_key,
        dp.product_key,
        ds.seller_key,
        
        -- Degenerate dimensions (don't warrant separate dimension tables)
        oi.order_id,
        oi.order_item_id,
        o.order_status,
        
        -- Date/Time stamps
        o.order_purchase_timestamp,
        o.order_approved_at,
        o.order_delivered_carrier_date,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date,
        o.order_date,
        o.order_year,
        o.order_month,
        o.order_quarter,
        
        -- Delivery metrics
        o.delivery_days_vs_estimate,
        o.delivered_on_time,
        
        -- Financial measures (additive facts)
        oi.price as item_price,
        oi.freight_value,
        oi.total_price,
        oi.estimated_gross_profit,
        
        -- Order-level payment info (semi-additive - need to handle aggregates carefully)
        pay.total_payment_value as order_payment_value,
        pay.primary_payment_type,
        
        -- Review metrics (non-additive - need special handling)
        rev.avg_review_score,
        rev.review_count,
        
        -- Flags
        o.is_delivered,
        o.is_canceled,
        pay.has_installment,
        
        -- Calculated metrics
        case
            when oi.price > 0
            then (oi.estimated_gross_profit / oi.price) * 100
            else 0
        end as gross_margin_pct,
        
        case
            when oi.total_price > 0
            then (oi.freight_value / oi.total_price) * 100
            else 0
        end as freight_pct_of_total,
        
        -- Shipping performance metrics
        case
            when o.order_delivered_customer_date is not null 
                 and o.order_purchase_timestamp is not null
            then extract(epoch from (
                o.order_delivered_customer_date - o.order_purchase_timestamp
            )) / 86400.0
            else null
        end as actual_delivery_days,
        
        case
            when o.order_estimated_delivery_date is not null 
                 and o.order_purchase_timestamp is not null
            then extract(epoch from (
                o.order_estimated_delivery_date - o.order_purchase_timestamp
            )) / 86400.0
            else null
        end as estimated_delivery_days,
        
        -- Metadata
        current_timestamp as dbt_updated_at
        
    from order_items oi
    inner join orders o
        on oi.order_id = o.order_id
    left join order_payments pay
        on o.order_id = pay.order_id
    left join order_reviews rev
        on o.order_id = rev.order_id
    inner join dim_customer dc
        on o.customer_id = dc.customer_id
    inner join dim_product dp
        on oi.product_id = dp.product_id
    inner join dim_seller ds
        on oi.seller_id = ds.seller_id
    
    
)

select * from fact