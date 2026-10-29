

-- =================================================================
-- dim_customer.sql
-- =================================================================
-- Customer dimension from Olist dataset
-- Includes both customer_id and customer_unique_id
-- Geographic attributes from staging layer
-- =================================================================
-- Note: For SCD Type 2, use the customer_snapshot model
-- This dimension provides current state only
-- =================================================================

with customers as (
    select * from "shopflow_warehouse"."public_staging"."stg_customers"
),

-- Aggregate customer order metrics for enrichment
customer_metrics as (
    select
        o.customer_id,
        count(distinct o.order_id) as total_orders,
        min(o.order_purchase_timestamp) as first_order_date,
        max(o.order_purchase_timestamp) as last_order_date,
        count(distinct case when o.order_status = 'delivered' then o.order_id end) as delivered_orders,
        count(distinct case when o.order_status = 'canceled' then o.order_id end) as canceled_orders
    from "shopflow_warehouse"."public_staging"."stg_orders" o
    group by o.customer_id
),

-- Get geolocation data for customer zip codes
geo as (
    select * from "shopflow_warehouse"."public_staging"."stg_geolocation"
),

enriched as (
    select
        -- Surrogate key
        md5(cast(coalesce(cast(c.customer_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as customer_key,
        
        -- Primary business key
        c.customer_id,
        c.customer_unique_id,
        
        -- Geographic attributes
        c.zip_code,
        c.city,
        c.state,
        g.latitude,
        g.longitude,
        
        -- Order metrics
        coalesce(m.total_orders, 0) as total_orders,
        coalesce(m.delivered_orders, 0) as delivered_orders,
        coalesce(m.canceled_orders, 0) as canceled_orders,
        m.first_order_date,
        m.last_order_date,
        
        -- Customer segmentation
        case
            when m.total_orders >= 3 then 'Repeat'
            when m.total_orders = 2 then 'Second-time'
            when m.total_orders = 1 then 'One-time'
            else 'No orders'
        end as customer_segment,
        
        -- Days since last order (for churn analysis)
        case
            when m.last_order_date is not null
            then current_date - m.last_order_date::date
            else null
        end as days_since_last_order,
        
        -- Customer lifecycle status
        case
            when m.total_orders = 0 then 'Inactive'
            when current_date - m.last_order_date::date <= 90 then 'Active'
            when current_date - m.last_order_date::date <= 180 then 'At Risk'
            else 'Churned'
        end as lifecycle_status,
        
        -- Metadata
        c.dbt_updated_at
        
    from customers c
    left join customer_metrics m on c.customer_id = m.customer_id
    left join geo g on c.zip_code = g.zip_code
)

select * from enriched