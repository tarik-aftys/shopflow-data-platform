
  create view "shopflow_warehouse"."public_staging"."stg_geolocation__dbt_tmp"
    
    
  as (
    

-- =================================================================
-- stg_geolocation.sql
-- =================================================================
-- Staging model for geolocation data from Olist dataset
-- Maps zip codes to latitude/longitude coordinates
-- =================================================================

with source as (
    select * from "shopflow_warehouse"."public"."raw_geolocation"
),

-- Aggregate to get average location per zip code (many duplicates exist)
aggregated as (
    select
        geolocation_zip_code_prefix as zip_code,
        avg(geolocation_lat) as latitude,
        avg(geolocation_lng) as longitude,
        -- Take most common city/state for this zip
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
  );