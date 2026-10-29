{{ config(materialized='view') }}








with source as (
    select * from {{ source('raw', 'raw_orders') }}
),

cleaned as (
    select
        
        order_id,
        
        
        customer_id,
        
        
        order_status,
        
        
        order_purchase_timestamp::timestamp as order_purchase_timestamp,
        order_approved_at::timestamp as order_approved_at,
        order_delivered_carrier_date::timestamp as order_delivered_carrier_date,
        order_delivered_customer_date::timestamp as order_delivered_customer_date,
        order_estimated_delivery_date::timestamp as order_estimated_delivery_date,
        
        
        order_purchase_timestamp::date as order_date,
        date_part('year', order_purchase_timestamp::timestamp) as order_year,
        date_part('month', order_purchase_timestamp::timestamp) as order_month,
        date_part('quarter', order_purchase_timestamp::timestamp) as order_quarter,
        
        
        case 
            when order_delivered_customer_date is not null 
                 and order_estimated_delivery_date is not null
            then (order_delivered_customer_date::date - order_estimated_delivery_date::date)
            else null
        end as delivery_days_vs_estimate,
        
        case
            when order_delivered_customer_date <= order_estimated_delivery_date
            then true
            when order_delivered_customer_date > order_estimated_delivery_date
            then false
            else null
        end as delivered_on_time,
        
        
        case when order_status = 'delivered' then true else false end as is_delivered,
        case when order_status = 'canceled' then true else false end as is_canceled,
        
        
        loaded_at,
        current_timestamp as dbt_updated_at
        
    from source
    where order_id is not null
)

select * from cleaned
