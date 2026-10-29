{% snapshot product_snapshot %}

{{
    config(
        target_schema='snapshots',
        unique_key='product_id',
        strategy='timestamp',
        updated_at='dbt_updated_at',
        invalidate_hard_deletes=True
    )
}}














select
    product_id,
    category_name,
    category_name_portuguese,
    product_name_length,
    product_description_length,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm,
    product_volume_cm3,
    photo_quality_tier,
    description_quality,
    is_uncategorized,
    dbt_updated_at
from {{ ref('stg_products') }}

{% endsnapshot %}
