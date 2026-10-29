{{ config(materialized='view') }}








with product_sales as (
    select
        product_key,
        count(distinct order_id) as order_count,
        count(*) as item_count,
        sum(item_price) as total_revenue,
        sum(freight_value) as total_freight,
        sum(estimated_gross_profit) as total_profit,
        avg(item_price) as avg_selling_price,
        min(item_price) as min_selling_price,
        max(item_price) as max_selling_price,
        stddev(item_price) as price_stddev,
        min(order_date) as first_sale_date,
        max(order_date) as last_sale_date
    from {{ ref('fact_sales') }}
    where is_delivered = true
    group by product_key
),

product_reviews as (
    select
        f.product_key,
        avg(f.avg_review_score) as avg_product_rating,
        count(distinct f.order_id) as reviewed_order_count
    from {{ ref('fact_sales') }} f
    where f.avg_review_score is not null
    group by f.product_key
),

final as (
    select
        ps.*,
        pr.avg_product_rating,
        pr.reviewed_order_count,
        
        
        ps.total_revenue / nullif(ps.item_count, 0) as revenue_per_unit,
        ps.total_profit / nullif(ps.total_revenue, 0) * 100 as profit_margin_pct,
        
        
        ps.last_sale_date::date - ps.first_sale_date::date as sales_period_days,
        
        
        case
            when ps.max_selling_price > 0 and ps.min_selling_price > 0
            then ((ps.max_selling_price - ps.min_selling_price) / ps.min_selling_price) * 100
            else 0
        end as price_variation_pct
        
    from product_sales ps
    left join product_reviews pr on ps.product_key = pr.product_key
)

select * from final
