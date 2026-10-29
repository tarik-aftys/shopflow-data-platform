{{
    config(
        materialized='incremental',
        unique_key='sales_key',
        on_schema_change='sync_all_columns',
        docs={'node_color': 'orange'}
    )
}}














with order_items as (
    select * from {{ ref('stg_order_items') }}
),

orders as (
    select * from {{ ref('stg_orders') }}
),


order_payments as (
    select
        order_id,
        sum(payment_value) as total_payment_value,
        max(payment_type_standardized) as primary_payment_type,
        bool_or(is_installment) as has_installment,
        sum(payment_installments) as total_installments
    from {{ ref('stg_payments') }}
    group by order_id
),


order_reviews as (
    select
        order_id,
        avg(review_score) as avg_review_score,
        max(review_score) as max_review_score,
        min(review_score) as min_review_score,
        count(*) as review_count
    from {{ ref('stg_order_reviews') }}
    group by order_id
),


dim_customer as (
    select
        customer_id,
        customer_key
    from {{ ref('dim_customer') }}
),

dim_product as (
    select
        product_id,
        product_key
    from {{ ref('dim_product') }}
),

dim_seller as (
    select
        seller_id,
        seller_key
    from {{ ref('dim_seller') }}
),


fact as (
    select
        
        {{ dbt_utils.generate_surrogate_key([
            'oi.order_id', 
            'oi.order_item_id'
        ]) }} as sales_key,
        
        
        cast(to_char(o.order_date, 'YYYYMMDD') as integer) as date_key,
        dc.customer_key,
        dp.product_key,
        ds.seller_key,
        
        
        oi.order_id,
        oi.order_item_id,
        o.order_status,
        
        
        o.order_purchase_timestamp,
        o.order_approved_at,
        o.order_delivered_carrier_date,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date,
        o.order_date,
        o.order_year,
        o.order_month,
        o.order_quarter,
        
        
        o.delivery_days_vs_estimate,
        o.delivered_on_time,
        
        
        oi.price as item_price,
        oi.freight_value,
        oi.total_price,
        oi.estimated_gross_profit,
        
        
        pay.total_payment_value as order_payment_value,
        pay.primary_payment_type,
        
        
        rev.avg_review_score,
        rev.review_count,
        
        
        o.is_delivered,
        o.is_canceled,
        pay.has_installment,
        
        
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
    
    {% if is_incremental() %}
    
    where o.order_purchase_timestamp > (
        select max(order_purchase_timestamp) from {{ this }}
    )
    {% endif %}
)

select * from fact
