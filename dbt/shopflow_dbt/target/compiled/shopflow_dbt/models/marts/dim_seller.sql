

-- =================================================================
-- dim_seller.sql
-- =================================================================
-- Seller dimension from Olist dataset
-- Includes seller geographic data and performance metrics
-- =================================================================

with sellers as (
    select * from "shopflow_warehouse"."public_staging"."stg_sellers"
),

-- Aggregate seller performance metrics
seller_metrics as (
    select
        oi.seller_id,
        count(distinct oi.order_id) as total_orders,
        sum(oi.price) as total_revenue,
        sum(oi.freight_value) as total_freight,
        avg(oi.price) as avg_item_price,
        count(*) as total_items_sold,
        count(distinct oi.product_id) as unique_products_sold
    from "shopflow_warehouse"."public_staging"."stg_order_items" oi
    inner join "shopflow_warehouse"."public_staging"."stg_orders" o
        on oi.order_id = o.order_id
    where o.order_status = 'delivered'
    group by oi.seller_id
),

-- Get geolocation for seller zip codes
geo as (
    select * from "shopflow_warehouse"."public_staging"."stg_geolocation"
),

enriched as (
    select
        -- Surrogate key
        md5(cast(coalesce(cast(s.seller_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as seller_key,
        
        -- Primary business key
        s.seller_id,
        
        -- Geographic attributes
        s.zip_code,
        s.city,
        s.state,
        g.latitude,
        g.longitude,
        
        -- Performance metrics
        coalesce(m.total_orders, 0) as total_orders,
        coalesce(m.total_items_sold, 0) as total_items_sold,
        coalesce(m.unique_products_sold, 0) as unique_products_sold,
        coalesce(m.total_revenue, 0) as total_revenue,
        coalesce(m.total_freight, 0) as total_freight,
        coalesce(m.avg_item_price, 0) as avg_item_price,
        
        -- Seller segmentation
        case
            when m.total_orders >= 100 then 'Enterprise'
            when m.total_orders >= 50 then 'Professional'
            when m.total_orders >= 10 then 'Growing'
            when m.total_orders >= 1 then 'Small'
            else 'Inactive'
        end as seller_tier,
        
        -- Product diversity score
        case
            when m.total_items_sold > 0
            then round(m.unique_products_sold::numeric / m.total_items_sold::numeric, 2)
            else 0
        end as product_diversity_score,
        
        -- Metadata
        s.dbt_updated_at
        
    from sellers s
    left join seller_metrics m on s.seller_id = m.seller_id
    left join geo g on s.zip_code = g.zip_code
)

select * from enriched