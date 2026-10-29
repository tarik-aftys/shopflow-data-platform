{% snapshot customer_snapshot %}

{{
    config(
        target_schema='snapshots',
        unique_key='customer_id',
        strategy='timestamp',
        updated_at='dbt_updated_at',
        invalidate_hard_deletes=True
    )
}}













select
    customer_id,
    customer_unique_id,
    zip_code,
    city,
    state,
    dbt_updated_at
from {{ ref('stg_customers') }}

{% endsnapshot %}
