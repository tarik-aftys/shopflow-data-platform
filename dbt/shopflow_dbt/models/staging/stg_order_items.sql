{{ config(materialized='view') }}








with source as (
    select * from {{ source('raw', 'raw_order_items') }}
),

cleaned as (
    select
        
        order_id,
        order_item_id,
        
        
        product_id,
        seller_id,
        
        
        shipping_limit_date::timestamp as shipping_limit_date,
        
        
        price,
        freight_value,
        price + freight_value as total_price,
        
        
        
        price * 0.70 as estimated_gross_profit,
        
        
        loaded_at,
        current_timestamp as dbt_updated_at
        
    from source
    where order_id is not null 
      and order_item_id is not null
      and price >= 0
      and freight_value >= 0
)

select * from cleaned
