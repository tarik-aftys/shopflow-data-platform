
  create view "shopflow_warehouse"."public_staging"."stg_orders__dbt_tmp"
    
    
  as (
    

-- =================================================================
-- stg_orders.sql
-- =================================================================
-- Staging model for orders from Olist dataset
-- Clean and standardize order data with proper date handling
-- =================================================================

with source as (
    select * from "shopflow_warehouse"."public"."raw_orders"
),

cleaned as (
    select
        -- Primary key
        order_id,
        
        -- Foreign keys
        customer_id,
        
        -- Order attributes
        order_status,
        
        -- Timestamps (convert to proper timestamps)
        order_purchase_timestamp::timestamp as order_purchase_timestamp,
        order_approved_at::timestamp as order_approved_at,
        order_delivered_carrier_date::timestamp as order_delivered_carrier_date,
        order_delivered_customer_date::timestamp as order_delivered_customer_date,
        order_estimated_delivery_date::timestamp as order_estimated_delivery_date,
        
        -- Derived attributes
        order_purchase_timestamp::date as order_date,
        date_part('year', order_purchase_timestamp::timestamp) as order_year,
        date_part('month', order_purchase_timestamp::timestamp) as order_month,
        date_part('quarter', order_purchase_timestamp::timestamp) as order_quarter,
        
        -- Calculate delivery performance
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
        
        -- Order flags
        case when order_status = 'delivered' then true else false end as is_delivered,
        case when order_status = 'canceled' then true else false end as is_canceled,
        
        -- Metadata
        loaded_at,
        current_timestamp as dbt_updated_at
        
    from source
    where order_id is not null
)

select * from cleaned
  );