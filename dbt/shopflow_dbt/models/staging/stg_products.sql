{{ config(materialized='view') }}








with source_products as (
    select * from {{ source('raw', 'raw_products') }}
),

source_categories as (
    select * from {{ source('raw', 'raw_product_category_translation') }}
),

cleaned as (
    select
        
        p.product_id,
        
        
        p.product_category_name as category_name_portuguese,
        coalesce(c.product_category_name_english, p.product_category_name, 'uncategorized') as category_name,
        
        
        p.product_name_length,
        p.product_description_length,
        p.product_photos_qty,
        
        
        p.product_weight_g,
        p.product_length_cm,
        p.product_height_cm,
        p.product_width_cm,
        
        
        coalesce(
            p.product_length_cm * p.product_height_cm * p.product_width_cm,
            0
        ) as product_volume_cm3,
        
        
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
        
        
        case when p.product_category_name is null then true else false end as is_uncategorized,
        
        
        p.loaded_at,
        current_timestamp as dbt_updated_at
        
    from source_products p
    left join source_categories c
        on p.product_category_name = c.product_category_name
    where p.product_id is not null
)

select * from cleaned
