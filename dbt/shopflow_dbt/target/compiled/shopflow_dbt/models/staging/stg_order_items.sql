

-- =================================================================
-- stg_order_items.sql
-- =================================================================
-- Staging model for order items from Olist dataset
-- Grain: One row per order item (order_id + order_item_id)
-- =================================================================

with source as (
    select * from "shopflow_warehouse"."public"."raw_order_items"
),

cleaned as (
    select
        -- Composite primary key
        order_id,
        order_item_id,
        
        -- Foreign keys
        product_id,
        seller_id,
        
        -- Dates
        shipping_limit_date::timestamp as shipping_limit_date,
        
        -- Financial metrics
        price,
        freight_value,
        price + freight_value as total_price,
        
        -- Calculate margins (assuming 30% cost of goods sold - placeholder)
        -- In production, join with actual cost data
        price * 0.70 as estimated_gross_profit,
        
        -- Metadata
        loaded_at,
        current_timestamp as dbt_updated_at
        
    from source
    where order_id is not null 
      and order_item_id is not null
      and price >= 0
      and freight_value >= 0
)

select * from cleaned