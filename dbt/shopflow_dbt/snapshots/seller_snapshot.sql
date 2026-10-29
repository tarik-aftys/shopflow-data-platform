{% snapshot seller_snapshot %}

{{
    config(
        target_schema='snapshots',
        unique_key='seller_id',
        strategy='timestamp',
        updated_at='dbt_updated_at',
        invalidate_hard_deletes=True
    )
}}













select
    seller_id,
    zip_code,
    city,
    state,
    dbt_updated_at
from {{ ref('stg_sellers') }}

{% endsnapshot %}
