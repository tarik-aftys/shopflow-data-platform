
  create view "shopflow_warehouse"."public_staging"."stg_sellers__dbt_tmp"
    
    
  as (
    

-- =================================================================
-- stg_sellers.sql
-- =================================================================
-- Staging model for sellers from Olist dataset
-- =================================================================

with source as (
    select * from "shopflow_warehouse"."public"."raw_sellers"
),

cleaned as (
    select
        -- Primary key
        seller_id,
        
        -- Geographic attributes
        seller_zip_code_prefix as zip_code,
        seller_city as city,
        seller_state as state,
        
        -- Metadata
        loaded_at,
        current_timestamp as dbt_updated_at
        
    from source
    where seller_id is not null
)

select * from cleaned
  );