{{
    config(
        materialized='table',
        docs={'node_color': 'lightgreen'}
    )
}}












with customers as (
    select * from {{ ref('stg_customers') }}
),


customer_metrics as (
    select
        o.customer_id,
        count(distinct o.order_id) as total_orders,
        min(o.order_purchase_timestamp) as first_order_date,
        max(o.order_purchase_timestamp) as last_order_date,
        count(distinct case when o.order_status = 'delivered' then o.order_id end) as delivered_orders,
        count(distinct case when o.order_status = 'canceled' then o.order_id end) as canceled_orders
    from {{ ref('stg_orders') }} o
    group by o.customer_id
),


geo as (
    select * from {{ ref('stg_geolocation') }}
),

enriched as (
    select
        
        {{ dbt_utils.generate_surrogate_key(['c.customer_id']) }} as customer_key,
        
        
        c.customer_id,
        c.customer_unique_id,
        
        
        c.zip_code,
        c.city,
        c.state,
        g.latitude,
        g.longitude,
        
        
        coalesce(m.total_orders, 0) as total_orders,
        coalesce(m.delivered_orders, 0) as delivered_orders,
        coalesce(m.canceled_orders, 0) as canceled_orders,
        m.first_order_date,
        m.last_order_date,
        
        
        case
            when m.total_orders >= 3 then 'Repeat'
            when m.total_orders = 2 then 'Second-time'
            when m.total_orders = 1 then 'One-time'
            else 'No orders'
        end as customer_segment,
        
        
        case
            when m.last_order_date is not null
            then current_date - m.last_order_date::date
            else null
        end as days_since_last_order,
        
        
        case
            when m.total_orders = 0 then 'Inactive'
            when current_date - m.last_order_date::date <= 90 then 'Active'
            when current_date - m.last_order_date::date <= 180 then 'At Risk'
            else 'Churned'
        end as lifecycle_status,
        
        
        c.dbt_updated_at
        
    from customers c
    left join customer_metrics m on c.customer_id = m.customer_id
    left join geo g on c.zip_code = g.zip_code
)

select * from enriched
