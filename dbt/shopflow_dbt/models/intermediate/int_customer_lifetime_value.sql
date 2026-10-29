{{ config(materialized='view') }}








with customer_orders as (
    select
        customer_key,
        customer_id,
        count(distinct order_id) as total_orders,
        sum(total_price) as lifetime_value,
        sum(item_price) as lifetime_revenue,
        sum(freight_value) as lifetime_freight,
        sum(estimated_gross_profit) as lifetime_profit,
        avg(total_price) as avg_order_value,
        min(order_date) as first_order_date,
        max(order_date) as last_order_date,
        max(order_date)::date - min(order_date)::date as customer_tenure_days
    from {{ ref('fact_sales') }}
    where is_delivered = true
    group by customer_key, customer_id
),

recency_frequency_monetary as (
    select
        *,
        current_date - last_order_date::date as recency_days,
        lifetime_value / nullif(total_orders, 0) as avg_transaction_value,
        
        
        ntile(5) over (order by current_date - last_order_date::date desc) as recency_score,
        ntile(5) over (order by total_orders) as frequency_score,
        ntile(5) over (order by lifetime_value) as monetary_score
    from customer_orders
),

final as (
    select
        *,
        (recency_score + frequency_score + monetary_score)/3.0 as rfm_score,
        
        case
            when recency_score >= 4 and frequency_score >= 4 then 'Champions'
            when monetary_score >= 4 and frequency_score >= 3 then 'Loyal Customers'
            when recency_score >= 4 then 'Potential Loyalists'
            when recency_score >= 3 and frequency_score <= 2 then 'Promising'
            when recency_score <= 2 and frequency_score >= 3 then 'At Risk'
            when recency_score <= 2 then 'Lost'
            else 'Other'
        end as customer_rfm_segment
    from recency_frequency_monetary
)

select * from final
