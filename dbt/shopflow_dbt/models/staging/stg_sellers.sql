{{ config(materialized='view') }}







with source as (
    select * from {{ source('raw', 'raw_sellers') }}
),

cleaned as (
    select
        
        seller_id,
        
        
        seller_zip_code_prefix as zip_code,
        seller_city as city,
        seller_state as state,
        
        
        loaded_at,
        current_timestamp as dbt_updated_at
        
    from source
    where seller_id is not null
)

select * from cleaned
