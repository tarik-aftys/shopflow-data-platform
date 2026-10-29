{{ config(materialized='view') }}








with source as (
    select * from {{ source('raw', 'raw_geolocation') }}
),


aggregated as (
    select
        geolocation_zip_code_prefix as zip_code,
        avg(geolocation_lat) as latitude,
        avg(geolocation_lng) as longitude,
        
        mode() within group (order by geolocation_city) as city,
        mode() within group (order by geolocation_state) as state,
        count(*) as coordinate_count
    from source
    where geolocation_zip_code_prefix is not null
      and geolocation_lat is not null
      and geolocation_lng is not null
    group by geolocation_zip_code_prefix
)

select
    *,
    current_timestamp as dbt_updated_at
from aggregated
