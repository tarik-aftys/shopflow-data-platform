












SELECT
    d.year,
    d.month_number,
    d.month_name,
    COUNT(DISTINCT f.order_id) AS total_orders,
    COUNT(f.sales_key) AS total_items_sold,
    SUM(f.item_price) AS total_revenue,
    SUM(f.freight_value) AS total_freight,
    SUM(f.total_price) AS total_revenue_with_freight,
    SUM(f.estimated_gross_profit) AS total_profit,
    AVG(f.item_price) AS avg_item_price,
    SUM(f.estimated_gross_profit) / NULLIF(SUM(f.item_price), 0) * 100 AS profit_margin_pct,
    LAG(SUM(f.total_price)) OVER (ORDER BY d.year, d.month_number) AS prev_month_revenue,
    (SUM(f.total_price) - LAG(SUM(f.total_price)) OVER (ORDER BY d.year, d.month_number)) 
        / NULLIF(LAG(SUM(f.total_price)) OVER (ORDER BY d.year, d.month_number), 0) * 100 AS mom_growth_pct
FROM fact_sales f
INNER JOIN dim_date d ON f.date_key = d.date_key
WHERE f.is_delivered = TRUE
GROUP BY d.year, d.month_number, d.month_name
ORDER BY d.year, d.month_number;








WITH product_sales AS (
    SELECT
        p.category_name,
        p.product_id,
        COUNT(DISTINCT f.order_id) AS order_count,
        SUM(f.item_price) AS total_revenue,
        SUM(f.estimated_gross_profit) AS total_profit,
        COUNT(f.sales_key) AS units_sold,
        AVG(f.avg_review_score) AS avg_rating
    FROM fact_sales f
    INNER JOIN dim_product p ON f.product_key = p.product_key
    WHERE f.is_delivered = TRUE
    GROUP BY p.category_name, p.product_id
),
ranked_products AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY category_name ORDER BY total_revenue DESC) AS revenue_rank
    FROM product_sales
)
SELECT
    category_name,
    product_id,
    order_count,
    total_revenue,
    total_profit,
    units_sold,
    ROUND(avg_rating, 2) AS avg_rating,
    revenue_rank
FROM ranked_products
WHERE revenue_rank <= 10
ORDER BY category_name, revenue_rank;








WITH customer_first_purchase AS (
    SELECT
        customer_key,
        DATE_TRUNC('month', MIN(order_date))::DATE AS cohort_month
    FROM fact_sales
    WHERE is_delivered = TRUE
    GROUP BY customer_key
),
customer_purchases AS (
    SELECT
        cfp.cohort_month,
        DATE_TRUNC('month', f.order_date)::DATE AS purchase_month,
        f.customer_key,
        SUM(f.total_price) AS total_spend
    FROM fact_sales f
    INNER JOIN customer_first_purchase cfp ON f.customer_key = cfp.customer_key
    WHERE f.is_delivered = TRUE
    GROUP BY cfp.cohort_month, DATE_TRUNC('month', f.order_date)::DATE, f.customer_key
),
cohort_metrics AS (
    SELECT
        cohort_month,
        purchase_month,
        EXTRACT(MONTH FROM AGE(purchase_month, cohort_month)) AS months_since_cohort,
        COUNT(DISTINCT customer_key) AS active_customers,
        SUM(total_spend) AS cohort_revenue
    FROM customer_purchases
    GROUP BY cohort_month, purchase_month
),
cohort_base AS (
    SELECT
        cohort_month,
        COUNT(DISTINCT customer_key) AS cohort_size
    FROM customer_first_purchase
    GROUP BY cohort_month
)
SELECT
    cm.cohort_month,
    cb.cohort_size,
    cm.months_since_cohort,
    cm.active_customers,
    cm.cohort_revenue,
    ROUND(100.0 * cm.active_customers / cb.cohort_size, 2) AS retention_pct
FROM cohort_metrics cm
INNER JOIN cohort_base cb ON cm.cohort_month = cb.cohort_month
ORDER BY cm.cohort_month, cm.months_since_cohort;








SELECT
    c.customer_id,
    c.customer_segment,
    c.state,
    c.city,
    clv.total_orders,
    clv.lifetime_value,
    clv.lifetime_revenue,
    clv.lifetime_profit,
    ROUND(clv.avg_order_value, 2) AS avg_order_value,
    clv.first_order_date,
    clv.last_order_date,
    clv.recency_days,
    clv.customer_tenure_days,
    clv.recency_score,
    clv.frequency_score,
    clv.monetary_score,
    ROUND(clv.rfm_score, 2) AS rfm_score,
    clv.customer_rfm_segment
FROM dim_customer c
INNER JOIN int_customer_lifetime_value clv ON c.customer_key = clv.customer_key
ORDER BY clv.lifetime_value DESC
LIMIT 100;








WITH product_pairs AS (
    SELECT
        f1.product_key AS product_a_key,
        f2.product_key AS product_b_key,
        COUNT(DISTINCT f1.order_id) AS co_occurrence_count
    FROM fact_sales f1
    INNER JOIN fact_sales f2
        ON f1.order_id = f2.order_id
        AND f1.product_key < f2.product_key
    WHERE f1.is_delivered = TRUE
    GROUP BY f1.product_key, f2.product_key
    HAVING COUNT(DISTINCT f1.order_id) >= 3
)
SELECT
    pa.product_id AS product_a_id,
    pa.category_name AS product_a_category,
    pb.product_id AS product_b_id,
    pb.category_name AS product_b_category,
    pp.co_occurrence_count,
    ROUND(pp.co_occurrence_count::NUMERIC / NULLIF(pa.total_orders, 0) * 100, 2) AS support_pct
FROM product_pairs pp
INNER JOIN dim_product pa ON pp.product_a_key = pa.product_key
INNER JOIN dim_product pb ON pp.product_b_key = pb.product_key
ORDER BY pp.co_occurrence_count DESC
LIMIT 50;








SELECT
    d.quarter_name,
    d.month_name,
    d.day_name,
    d.is_weekend,
    COUNT(DISTINCT f.order_id) AS total_orders,
    SUM(f.total_price) AS total_revenue,
    AVG(f.total_price) AS avg_order_value,
    SUM(f.total_price) / NULLIF(SUM(SUM(f.total_price)) OVER (PARTITION BY d.quarter), 0) * 100 AS pct_of_quarter_revenue
FROM fact_sales f
INNER JOIN dim_date d ON f.date_key = d.date_key
WHERE f.is_delivered = TRUE
GROUP BY d.quarter_name, d.quarter, d.month_name, d.month_number, d.day_name, d.day_of_week, d.is_weekend
ORDER BY d.quarter, d.month_number, d.day_of_week;








SELECT
    customer_rfm_segment,
    COUNT(DISTINCT customer_key) AS customer_count,
    SUM(lifetime_value) AS total_lifetime_value,
    AVG(lifetime_value) AS avg_lifetime_value,
    AVG(total_orders) AS avg_orders_per_customer,
    AVG(recency_days) AS avg_recency_days,
    AVG(rfm_score) AS avg_rfm_score,
    SUM(lifetime_value) / NULLIF(SUM(SUM(lifetime_value)) OVER (), 0) * 100 AS pct_of_total_value
FROM int_customer_lifetime_value
GROUP BY customer_rfm_segment
ORDER BY total_lifetime_value DESC;








SELECT
    p.category_name,
    p.product_id,
    p.performance_tier,
    pp.item_count AS units_sold,
    pp.total_revenue,
    pp.avg_selling_price,
    pp.first_sale_date,
    pp.last_sale_date,
    pp.sales_period_days,
    CASE
        WHEN pp.sales_period_days > 0
        THEN ROUND(pp.item_count::NUMERIC / pp.sales_period_days, 2)
        ELSE 0
    END AS units_per_day,
    pp.avg_product_rating,
    pp.profit_margin_pct
FROM dim_product p
INNER JOIN int_product_performance pp ON p.product_key = pp.product_key
WHERE pp.item_count >= 5
ORDER BY units_per_day DESC
LIMIT 50;








SELECT
    c.state AS customer_state,
    s.state AS seller_state,
    COUNT(DISTINCT f.order_id) AS total_orders,
    COUNT(f.sales_key) AS total_items,
    SUM(f.item_price) AS total_revenue,
    SUM(f.freight_value) AS total_freight,
    AVG(f.actual_delivery_days) AS avg_delivery_days,
    SUM(CASE WHEN f.delivered_on_time THEN 1 ELSE 0 END)::NUMERIC / 
        NULLIF(COUNT(*), 0) * 100 AS on_time_delivery_pct,
    AVG(f.avg_review_score) AS avg_review_score
FROM fact_sales f
INNER JOIN dim_customer c ON f.customer_key = c.customer_key
INNER JOIN dim_seller s ON f.seller_key = s.seller_key
WHERE f.is_delivered = TRUE
GROUP BY c.state, s.state
HAVING COUNT(DISTINCT f.order_id) >= 10
ORDER BY total_revenue DESC;








WITH product_price_bands AS (
    SELECT
        product_key,
        NTILE(5) OVER (PARTITION BY product_key ORDER BY item_price) AS price_quintile,
        item_price,
        COUNT(*) AS units_sold,
        SUM(total_price) AS revenue
    FROM fact_sales
    WHERE is_delivered = TRUE
    GROUP BY product_key, item_price
),
price_elasticity AS (
    SELECT
        p.category_name,
        p.product_id,
        ppb.price_quintile,
        AVG(ppb.item_price) AS avg_price_in_band,
        SUM(ppb.units_sold) AS total_units_in_band,
        SUM(ppb.revenue) AS total_revenue_in_band
    FROM product_price_bands ppb
    INNER JOIN dim_product p ON ppb.product_key = p.product_key
    GROUP BY p.category_name, p.product_id, ppb.price_quintile
)
SELECT
    category_name,
    product_id,
    price_quintile,
    ROUND(avg_price_in_band, 2) AS avg_price,
    total_units_in_band,
    ROUND(total_revenue_in_band, 2) AS revenue,
    LAG(avg_price_in_band) OVER (PARTITION BY product_id ORDER BY price_quintile) AS prev_price,
    LAG(total_units_in_band) OVER (PARTITION BY product_id ORDER BY price_quintile) AS prev_units,
    CASE
        WHEN LAG(avg_price_in_band) OVER (PARTITION BY product_id ORDER BY price_quintile) > 0
             AND LAG(total_units_in_band) OVER (PARTITION BY product_id ORDER BY price_quintile) > 0
        THEN ROUND(
            ((total_units_in_band - LAG(total_units_in_band) OVER (PARTITION BY product_id ORDER BY price_quintile))::NUMERIC /
             LAG(total_units_in_band) OVER (PARTITION BY product_id ORDER BY price_quintile)) /
            ((avg_price_in_band - LAG(avg_price_in_band) OVER (PARTITION BY product_id ORDER BY price_quintile)) /
             LAG(avg_price_in_band) OVER (PARTITION BY product_id ORDER BY price_quintile))
        , 2)
        ELSE NULL
    END AS price_elasticity
FROM price_elasticity
ORDER BY product_id, price_quintile;
