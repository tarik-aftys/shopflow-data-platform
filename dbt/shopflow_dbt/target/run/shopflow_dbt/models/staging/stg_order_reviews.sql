
  create view "shopflow_warehouse"."public_staging"."stg_order_reviews__dbt_tmp"
    
    
  as (
    

-- =================================================================
-- stg_order_reviews.sql
-- =================================================================
-- Staging model for customer reviews from Olist dataset
-- =================================================================

with source as (
    select * from "shopflow_warehouse"."public"."raw_order_reviews"
),

cleaned as (
    select
        -- Primary key
        review_id,
        
        -- Foreign keys
        order_id,
        
        -- Review attributes
        review_score,
        review_comment_title,
        review_comment_message,
        
        -- Timestamps
        review_creation_date::timestamp as review_creation_date,
        review_answer_timestamp::timestamp as review_answer_timestamp,
        
        -- Derived attributes
        case
            when review_score >= 4 then 'Positive'
            when review_score = 3 then 'Neutral'
            else 'Negative'
        end as review_sentiment,
        
        case when review_comment_message is not null then true else false end as has_comment,
        case when review_answer_timestamp is not null then true else false end as has_answer,
        
        length(review_comment_message) as comment_length,
        
        -- Metadata
        loaded_at,
        current_timestamp as dbt_updated_at
        
    from source
    where review_id is not null
)

select * from cleaned
  );