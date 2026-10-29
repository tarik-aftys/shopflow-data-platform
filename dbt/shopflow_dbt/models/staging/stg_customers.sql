{{ config(materialized='view') }}








with source as (
    select * from {{ source('raw', 'raw_customers') }}
),

cleaned as (
    select
        
        customer_id,
        
        
        customer_unique_id,
        
        
        customer_zip_code_prefix as zip_code,
        customer_city as city,
        customer_state as state,
        
        
        loaded_at,
        current_timestamp as dbt_updated_at
        
    from source
    where customer_id is not null
),


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
