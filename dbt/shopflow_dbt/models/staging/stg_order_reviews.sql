{{ config(materialized='view') }}







with source as (
    select * from {{ source('raw', 'raw_order_reviews') }}
),

cleaned as (
    select
        
        review_id,
        
        
        order_id,
        
        
        review_score,
        review_comment_title,
        review_comment_message,
        
        
        review_creation_date::timestamp as review_creation_date,
        review_answer_timestamp::timestamp as review_answer_timestamp,
        
        
        case
            when review_score >= 4 then 'Positive'
            when review_score = 3 then 'Neutral'
            else 'Negative'
        end as review_sentiment,
        
        case when review_comment_message is not null then true else false end as has_comment,
        case when review_answer_timestamp is not null then true else false end as has_answer,
        
        length(review_comment_message) as comment_length,
        
        
        loaded_at,
        current_timestamp as dbt_updated_at
        
    from source
    where review_id is not null
)

select * from cleaned
