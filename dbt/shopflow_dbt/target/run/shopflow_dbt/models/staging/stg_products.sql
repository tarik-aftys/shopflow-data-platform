
  create view "shopflow_warehouse"."public_staging"."stg_products__dbt_tmp"
    
    
  as (
    

-- =================================================================
-- stg_products.sql
-- =================================================================
-- Staging model for products from Olist dataset
-- Joins with category translation to get English names
-- =================================================================

with source_products as (
    select * from "shopflow_warehouse"."public"."raw_products"
),

source_categories as (
    select * from "shopflow_warehouse"."public"."raw_product_category_translation"
),

cleaned as (
    select
        -- Primary key
        p.product_id,
        
        -- Category information (with English translation)
        p.product_category_name as category_name_portuguese,
        coalesce(c.product_category_name_english, p.product_category_name, 'uncategorized') as category_name,
        
        -- Product attributes
        p.product_name_length,
        p.product_description_length,
        p.product_photos_qty,
        
        -- Physical dimensions
        p.product_weight_g,
        p.product_length_cm,
        p.product_height_cm,
        p.product_width_cm,
        
        -- Calculate volume (cubic cm)
        coalesce(
            p.product_length_cm * p.product_height_cm * p.product_width_cm,
            0
        ) as product_volume_cm3,
        
        -- Product quality indicators
        case
            when p.product_photos_qty >= 3 then 'High'
            when p.product_photos_qty >= 1 then 'Medium'
            else 'Low'
        end as photo_quality_tier,
        
        case
            when p.product_description_length >= 500 then 'Detailed'
            when p.product_description_length >= 100 then 'Standard'
            else 'Brief'
        end as description_quality,
        
        -- Flags
        case when p.product_category_name is null then true else false end as is_uncategorized,
        
        -- Metadata
        p.loaded_at,
        current_timestamp as dbt_updated_at
        
    from source_products p
    left join source_categories c
        on p.product_category_name = c.product_category_name
    where p.product_id is not null
)

select * from cleaned
  );