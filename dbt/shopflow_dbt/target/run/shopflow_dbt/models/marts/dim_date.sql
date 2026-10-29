
  
    

  create  table "shopflow_warehouse"."public_marts"."dim_date__dbt_tmp"
  
  
    as
  
  (
    -- dim_date.sql
-- Calendar date dimension
-- Pre-generated date spine covering 2023–2025



-- =================================================================
-- dim_date.sql
-- =================================================================
-- Calendar date dimension with comprehensive date attributes
-- Pre-generated date spine covering the full dataset period
-- =================================================================

with date_spine as (
    





with rawdata as (

    

    

    with p as (
        select 0 as generated_number union all select 1
    ), unioned as (

    select

    
    p0.generated_number * power(2, 0)
     + 
    
    p1.generated_number * power(2, 1)
     + 
    
    p2.generated_number * power(2, 2)
     + 
    
    p3.generated_number * power(2, 3)
     + 
    
    p4.generated_number * power(2, 4)
     + 
    
    p5.generated_number * power(2, 5)
     + 
    
    p6.generated_number * power(2, 6)
     + 
    
    p7.generated_number * power(2, 7)
     + 
    
    p8.generated_number * power(2, 8)
     + 
    
    p9.generated_number * power(2, 9)
     + 
    
    p10.generated_number * power(2, 10)
    
    
    + 1
    as generated_number

    from

    
    p as p0
     cross join 
    
    p as p1
     cross join 
    
    p as p2
     cross join 
    
    p as p3
     cross join 
    
    p as p4
     cross join 
    
    p as p5
     cross join 
    
    p as p6
     cross join 
    
    p as p7
     cross join 
    
    p as p8
     cross join 
    
    p as p9
     cross join 
    
    p as p10
    
    

    )

    select *
    from unioned
    where generated_number <= 1826
    order by generated_number



),

all_periods as (

    select (
        

    cast('2016-01-01' as date) + ((interval '1 day') * (row_number() over (order by generated_number) - 1))


    ) as date_day
    from rawdata

),

filtered as (

    select *
    from all_periods
    where date_day <= cast('2020-12-31' as date)

)

select * from filtered


),

dates as (
    select
        cast(date_day as date) as full_date
    from date_spine
)

select
    -- Primary key (integer format: YYYYMMDD)
    cast(to_char(full_date, 'YYYYMMDD') as integer)          as date_key,
    
    -- Full date
    full_date                                                 as date,
    
    -- Day attributes
    extract(isodow from full_date)::smallint                  as day_of_week,
    to_char(full_date, 'Day')                                 as day_name,
    to_char(full_date, 'Dy')                                  as day_name_short,
    extract(day from full_date)::smallint                     as day_of_month,
    extract(doy from full_date)::smallint                     as day_of_year,
    
    -- Week attributes
    extract(week from full_date)::smallint                    as week_of_year,
    to_char(full_date, 'YYYY-IW')                             as year_week,
    
    -- Month attributes
    extract(month from full_date)::smallint                   as month_number,
    to_char(full_date, 'Month')                               as month_name,
    to_char(full_date, 'Mon')                                 as month_name_short,
    to_char(full_date, 'YYYY-MM')                             as year_month,
    
    -- Quarter attributes
    extract(quarter from full_date)::smallint                 as quarter,
    'Q' || extract(quarter from full_date)::text              as quarter_name,
    extract(year from full_date)::text || '-Q' || 
        extract(quarter from full_date)::text                 as year_quarter,
    
    -- Year attributes
    extract(year from full_date)::integer                     as year,
    
    -- Date flags
    case when extract(isodow from full_date) in (6, 7)
         then true else false end                             as is_weekend,
    case when extract(isodow from full_date) not in (6, 7)
         then true else false end                             as is_weekday,
    
    -- Brazilian holidays (simplified - add more as needed)
    case
        when extract(month from full_date) = 1 and extract(day from full_date) = 1
            then true -- New Year
        when extract(month from full_date) = 9 and extract(day from full_date) = 7
            then true -- Independence Day
        when extract(month from full_date) = 11 and extract(day from full_date) = 15
            then true -- Republic Day
        when extract(month from full_date) = 12 and extract(day from full_date) = 25
            then true -- Christmas
        else false
    end as is_holiday,
    
    -- Fiscal year (assuming calendar year = fiscal year)
    extract(quarter from full_date)::smallint                 as fiscal_quarter,
    extract(year from full_date)::integer                     as fiscal_year,
    
    -- Relative date flags (useful for analytics)
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
  );
  