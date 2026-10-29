{{
    config(
        materialized='table',
        docs={'node_color': 'lightgreen'}
    )
}}











with products as (
    select * from {{ ref('stg_products') }}
),


product_metrics as (
    select
        oi.product_id,
        count(distinct oi.order_id) as total_orders,
        sum(oi.price) as total_revenue,
        avg(oi.price) as avg_price,
        min(oi.price) as min_price,
        max(oi.price) as max_price,
        count(*) as total_items_sold
    from {{ ref('stg_order_items') }} oi
    inner join {{ ref('stg_orders') }} o
        on oi.order_id = o.order_id
    where o.order_status = 'delivered'
    group by oi.product_id
),

enriched as (
    select
        
        {{ dbt_utils.generate_surrogate_key(['p.product_id']) }} as product_key,
        
        
        p.product_id,
        
        
        p.category_name,
        p.category_name_portuguese,
        
        
        p.product_name_length,
        p.product_description_length,
        p.product_photos_qty,
        p.photo_quality_tier,
        p.description_quality,
        
        
        p.product_weight_g,
        p.product_weight_g / 1000.0 as product_weight_kg,
        p.product_length_cm,
        p.product_height_cm,
        p.product_width_cm,
        p.product_volume_cm3,
        
        
        p.is_uncategorized,
        case when p.product_weight_g > 10000 then true else false end as is_heavy_item,
        case when p.product_volume_cm3 > 100000 then true else false end as is_large_item,
        
        
        coalesce(m.total_orders, 0) as total_orders,
        coalesce(m.total_items_sold, 0) as total_items_sold,
        coalesce(m.total_revenue, 0) as total_revenue,
        coalesce(m.avg_price, 0) as avg_selling_price,
        coalesce(m.min_price, 0) as min_selling_price,
        coalesce(m.max_price, 0) as max_selling_price,
        
        
        case
            when m.max_price > 0 and m.min_price > 0
            then ((m.max_price - m.min_price) / m.min_price) * 100
            else 0
        end as price_variance_pct,
        
        
        case
            when m.total_items_sold >= 50 then 'Best Seller'
            when m.total_items_sold >= 20 then 'Popular'
            when m.total_items_sold >= 5 then 'Average'
            when m.total_items_sold >= 1 then 'Slow Mover'
            else 'Never Sold'
        end as performance_tier,
        
        
        p.dbt_updated_at
        
    from products p
    left join product_metrics m on p.product_id = m.product_id
)

select * from enriched
