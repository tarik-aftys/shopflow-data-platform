{{ config(materialized='view') }}








with source as (
    select * from {{ source('raw', 'raw_order_payments') }}
),

cleaned as (
    select
        
        order_id,
        payment_sequential,
        
        
        lower(trim(payment_type)) as payment_type,
        payment_installments,
        payment_value,
        
        
        case lower(trim(payment_type))
            when 'credit_card' then 'Credit Card'
            when 'boleto' then 'Boleto'
            when 'voucher' then 'Voucher'
            when 'debit_card' then 'Debit Card'
            else 'Other'
        end as payment_type_standardized,
        
        
        case when payment_installments > 1 then true else false end as is_installment,
        case when lower(payment_type) = 'credit_card' then true else false end as is_credit_card,
        case when lower(payment_type) = 'boleto' then true else false end as is_boleto,
        
        
        loaded_at,
        current_timestamp as dbt_updated_at
        
    from source
    where order_id is not null
      and payment_sequential is not null
      and payment_value >= 0
)

select * from cleaned
