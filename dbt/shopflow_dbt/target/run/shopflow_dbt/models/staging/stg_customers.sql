
  create view "shopflow_warehouse"."public_staging"."stg_customers__dbt_tmp"
    
    
  as (
    

-- =================================================================
-- stg_customers.sql
-- =================================================================
-- Staging model for customer data from Olist dataset
-- Clean, standardize, and deduplicate customer information
-- =================================================================

with source as (
    select * from "shopflow_warehouse"."public"."raw_customers"
),

cleaned as (
    select
        -- Primary key
        customer_id,
        
        -- Business key (multiple customer_ids can map to same unique customer)
        customer_unique_id,
        
        -- Geographic attributes
        customer_zip_code_prefix as zip_code,
        customer_city as city,
        customer_state as state,
        
        -- Metadata
        loaded_at,
        current_timestamp as dbt_updated_at
        
    from source
    where customer_id is not null
),

-- Add row number for deduplication (if needed)
final as (
    select
        *,
        row_number() over (
            partition by customer_id 
            order by loaded_at desc
        ) as row_num
    from cleaned
)

select
    customer_id,
    customer_unique_id,
    zip_code,
    city,
    state,
    loaded_at,
    dbt_updated_at
from final
where row_num = 1
  );