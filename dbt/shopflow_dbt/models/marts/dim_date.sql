



{{
    config(
        materialized='table',
        docs={'node_color': 'lightblue'}
    )
}}








with date_spine as (
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2016-01-01' as date)",
        end_date="cast('2020-12-31' as date)"
    ) }}
),

dates as (
    select
        cast(date_day as date) as full_date
    from date_spine
)

select
    
    cast(to_char(full_date, 'YYYYMMDD') as integer)          as date_key,
    
    
    full_date                                                 as date,
    
    
    extract(isodow from full_date)::smallint                  as day_of_week,
    to_char(full_date, 'Day')                                 as day_name,
    to_char(full_date, 'Dy')                                  as day_name_short,
    extract(day from full_date)::smallint                     as day_of_month,
    extract(doy from full_date)::smallint                     as day_of_year,
    
    
    extract(week from full_date)::smallint                    as week_of_year,
    to_char(full_date, 'YYYY-IW')                             as year_week,
    
    
    extract(month from full_date)::smallint                   as month_number,
    to_char(full_date, 'Month')                               as month_name,
    to_char(full_date, 'Mon')                                 as month_name_short,
    to_char(full_date, 'YYYY-MM')                             as year_month,
    
    
    extract(quarter from full_date)::smallint                 as quarter,
    'Q' || extract(quarter from full_date)::text              as quarter_name,
    extract(year from full_date)::text || '-Q' || 
        extract(quarter from full_date)::text                 as year_quarter,
    
    
    extract(year from full_date)::integer                     as year,
    
    
    case when extract(isodow from full_date) in (6, 7)
         then true else false end                             as is_weekend,
    case when extract(isodow from full_date) not in (6, 7)
         then true else false end                             as is_weekday,
    
    
    case
        when extract(month from full_date) = 1 and extract(day from full_date) = 1
            then true 
        when extract(month from full_date) = 9 and extract(day from full_date) = 7
            then true 
        when extract(month from full_date) = 11 and extract(day from full_date) = 15
            then true 
        when extract(month from full_date) = 12 and extract(day from full_date) = 25
            then true 
        else false
    end as is_holiday,
    
    
    extract(quarter from full_date)::smallint                 as fiscal_quarter,
    extract(year from full_date)::integer                     as fiscal_year,
    
    
    case when full_date = current_date then true else false end as is_today,
    case when full_date = current_date - 1 then true else false end as is_yesterday,
    case when date_trunc('week', full_date) = date_trunc('week', current_date)
         then true else false end as is_current_week,
    case when date_trunc('month', full_date) = date_trunc('month', current_date)
         then true else false end as is_current_month,
    case when date_trunc('quarter', full_date) = date_trunc('quarter', current_date)
         then true else false end as is_current_quarter,
    case when date_trunc('year', full_date) = date_trunc('year', current_date)
         then true else false end as is_current_year

from dates
