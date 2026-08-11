-- ============================================================
-- Marketplace Growth & Customer Experience Analysis
-- File: F6_seller_analysis.sql
-- Purpose: Analyse seller commercial activity, participation,
--          growth, and geographic supply distribution
-- ============================================================


-- 1. Seller Analysis Population & Order Structure

-- 2. Seller Commercial Performance

-- 3. Seller Base Growth & Participation Change

-- 4. Seller Geographic Supply Distribution

USE marketplace_growth_analysis;


-- ============================================================
-- 1. SELLER ANALYSIS POPULATION & ORDER STRUCTURE
-- ============================================================

WITH completed_order_sellers AS (
    SELECT
        oi.order_id,

        COUNT(DISTINCT oi.seller_id)
            AS seller_count,

        COUNT(*)
            AS item_count

    FROM order_items AS oi

    INNER JOIN orders AS o
        ON oi.order_id = o.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY oi.order_id
),

completed_seller_activity AS (
    SELECT
        COUNT(DISTINCT oi.seller_id)
            AS active_sellers,

        COUNT(DISTINCT oi.product_id)
            AS products_sold,

        COUNT(*)
            AS completed_items,

        ROUND(
            SUM(oi.price),
            2
        ) AS completed_item_sales_value

    FROM order_items AS oi

    INNER JOIN orders AS o
        ON oi.order_id = o.order_id

    WHERE o.order_status = 'delivered'
),

completed_order_total AS (
    SELECT
        COUNT(*) AS completed_orders

    FROM orders

    WHERE order_status = 'delivered'
)

SELECT
    cot.completed_orders,

    COUNT(*) AS completed_orders_with_items,

    cot.completed_orders - COUNT(*)
        AS completed_orders_without_items,

    csa.active_sellers,

    csa.products_sold,

    csa.completed_items,

    csa.completed_item_sales_value,

    SUM(
        CASE
            WHEN cos.seller_count = 1 THEN 1
            ELSE 0
        END
    ) AS single_seller_orders,

    SUM(
        CASE
            WHEN cos.seller_count > 1 THEN 1
            ELSE 0
        END
    ) AS multi_seller_orders,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN cos.seller_count > 1 THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS multi_seller_order_pct,

    ROUND(
        AVG(cos.seller_count),
        2
    ) AS avg_sellers_per_order,

    MAX(cos.seller_count)
        AS max_sellers_per_order,

    SUM(cos.seller_count)
        AS seller_order_relationships

FROM completed_order_sellers AS cos

CROSS JOIN completed_seller_activity AS csa
CROSS JOIN completed_order_total AS cot

GROUP BY
    cot.completed_orders,
    csa.active_sellers,
    csa.products_sold,
    csa.completed_items,
    csa.completed_item_sales_value;
    
-- ============================================================
-- 2. SELLER COMMERCIAL PERFORMANCE
-- ============================================================

WITH seller_metrics AS (
    SELECT
        oi.seller_id,

        COUNT(DISTINCT oi.order_id)
            AS completed_orders,

        COUNT(*)
            AS items_sold,

        COUNT(DISTINCT oi.product_id)
            AS products_sold,

        SUM(oi.price)
            AS item_sales_value,

        AVG(oi.price)
            AS avg_item_price,

        SUM(oi.price)
        / COUNT(DISTINCT oi.order_id)
            AS avg_seller_sales_value_per_order

    FROM order_items AS oi

    INNER JOIN orders AS o
        ON oi.order_id = o.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY oi.seller_id
),

marketplace_total AS (
    SELECT
        SUM(item_sales_value)
            AS total_item_sales_value

    FROM seller_metrics
),

ranked_sellers AS (
    SELECT
        sm.*,

        ROW_NUMBER() OVER (
            ORDER BY
                item_sales_value DESC,
                seller_id
        ) AS seller_rank

    FROM seller_metrics AS sm
)

SELECT
    rs.seller_rank,
    rs.seller_id,

    rs.completed_orders,
    rs.items_sold,
    rs.products_sold,

    ROUND(
        rs.item_sales_value,
        2
    ) AS item_sales_value,

    ROUND(
        100.0 * rs.item_sales_value
        / mt.total_item_sales_value,
        2
    ) AS item_sales_value_share_pct,

    ROUND(
        rs.avg_item_price,
        2
    ) AS avg_item_price,

    ROUND(
        rs.avg_seller_sales_value_per_order,
        2
    ) AS avg_seller_sales_value_per_order

FROM ranked_sellers AS rs

CROSS JOIN marketplace_total AS mt

WHERE rs.seller_rank <= 20

ORDER BY rs.seller_rank;

-- ============================================================
-- 3. SELLER BASE GROWTH & PARTICIPATION CHANGE
-- ============================================================

WITH seller_year_metrics AS (
    SELECT
        YEAR(o.order_purchase_timestamp) AS order_year,
        oi.seller_id,

        COUNT(DISTINCT oi.order_id)
            AS completed_orders,

        COUNT(*)
            AS items_sold,

        SUM(oi.price)
            AS item_sales_value

    FROM order_items AS oi

    INNER JOIN orders AS o
        ON oi.order_id = o.order_id

    WHERE o.order_status = 'delivered'

      AND (
            (
                o.order_purchase_timestamp >= '2017-01-01'
                AND o.order_purchase_timestamp < '2017-09-01'
            )
            OR
            (
                o.order_purchase_timestamp >= '2018-01-01'
                AND o.order_purchase_timestamp < '2018-09-01'
            )
      )

    GROUP BY
        YEAR(o.order_purchase_timestamp),
        oi.seller_id
),

year_metrics AS (
    SELECT
        order_year,

        COUNT(*) AS active_sellers,

        SUM(completed_orders)
            AS seller_order_relationships,

        SUM(items_sold)
            AS completed_items,

        SUM(item_sales_value)
            AS item_sales_value,

        AVG(completed_orders)
            AS avg_completed_orders_per_active_seller,

        AVG(item_sales_value)
            AS avg_item_sales_value_per_active_seller

    FROM seller_year_metrics

    GROUP BY order_year
)

SELECT
    order_year,

    active_sellers,

    seller_order_relationships,

    completed_items,

    ROUND(
        item_sales_value,
        2
    ) AS item_sales_value,

    ROUND(
        avg_completed_orders_per_active_seller,
        2
    ) AS avg_completed_orders_per_active_seller,

    ROUND(
        avg_item_sales_value_per_active_seller,
        2
    ) AS avg_item_sales_value_per_active_seller

FROM year_metrics

ORDER BY order_year;

-- Seller participation across matched periods

WITH seller_period_activity AS (
    SELECT
        oi.seller_id,

        SUM(
            CASE
                WHEN o.order_purchase_timestamp >= '2017-01-01'
                 AND o.order_purchase_timestamp < '2017-09-01'
                    THEN 1
                ELSE 0
            END
        ) AS items_2017,

        SUM(
            CASE
                WHEN o.order_purchase_timestamp >= '2018-01-01'
                 AND o.order_purchase_timestamp < '2018-09-01'
                    THEN 1
                ELSE 0
            END
        ) AS items_2018,

        SUM(
            CASE
                WHEN o.order_purchase_timestamp >= '2017-01-01'
                 AND o.order_purchase_timestamp < '2017-09-01'
                    THEN oi.price
                ELSE 0
            END
        ) AS item_sales_value_2017,

        SUM(
            CASE
                WHEN o.order_purchase_timestamp >= '2018-01-01'
                 AND o.order_purchase_timestamp < '2018-09-01'
                    THEN oi.price
                ELSE 0
            END
        ) AS item_sales_value_2018

    FROM order_items AS oi

    INNER JOIN orders AS o
        ON oi.order_id = o.order_id

    WHERE o.order_status = 'delivered'

      AND (
            (
                o.order_purchase_timestamp >= '2017-01-01'
                AND o.order_purchase_timestamp < '2017-09-01'
            )
            OR
            (
                o.order_purchase_timestamp >= '2018-01-01'
                AND o.order_purchase_timestamp < '2018-09-01'
            )
      )

    GROUP BY oi.seller_id
),

seller_participation AS (
    SELECT
        seller_id,
        items_2017,
        items_2018,
        item_sales_value_2017,
        item_sales_value_2018,

        CASE
            WHEN items_2017 > 0
             AND items_2018 > 0
                THEN 'active_in_both_periods'

            WHEN items_2017 > 0
             AND items_2018 = 0
                THEN 'active_2017_only'

            WHEN items_2017 = 0
             AND items_2018 > 0
                THEN 'active_2018_only'
        END AS participation_group,

        CASE
            WHEN items_2017 > 0
             AND items_2018 > 0 THEN 1
            WHEN items_2017 > 0
             AND items_2018 = 0 THEN 2
            ELSE 3
        END AS participation_order

    FROM seller_period_activity
)

SELECT
    participation_group,

    COUNT(*) AS sellers,

    ROUND(
        SUM(item_sales_value_2017),
        2
    ) AS item_sales_value_2017,

    ROUND(
        SUM(item_sales_value_2018),
        2
    ) AS item_sales_value_2018

FROM seller_participation

GROUP BY
    participation_group,
    participation_order

ORDER BY participation_order;

-- ============================================================
-- 4. SELLER GEOGRAPHIC SUPPLY DISTRIBUTION
-- ============================================================

WITH seller_activity AS (
    SELECT
        s.seller_state,
        oi.seller_id,
        oi.order_id,
        oi.product_id,
        oi.price

    FROM order_items AS oi

    INNER JOIN orders AS o
        ON oi.order_id = o.order_id

    INNER JOIN sellers AS s
        ON oi.seller_id = s.seller_id

    WHERE o.order_status = 'delivered'
),

state_metrics AS (
    SELECT
        seller_state,

        COUNT(DISTINCT seller_id)
            AS active_sellers,

        COUNT(DISTINCT order_id)
            AS completed_orders_with_state_seller,

        COUNT(*)
            AS items_sold,

        COUNT(DISTINCT product_id)
            AS products_sold,

        SUM(price)
            AS item_sales_value,

        SUM(price)
        / COUNT(DISTINCT seller_id)
            AS avg_item_sales_value_per_active_seller

    FROM seller_activity

    GROUP BY seller_state
),

marketplace_totals AS (
    SELECT
        COUNT(DISTINCT seller_id)
            AS total_active_sellers,

        COUNT(*) AS total_items,

        SUM(price)
            AS total_item_sales_value

    FROM seller_activity
)

SELECT
    sm.seller_state,

    sm.active_sellers,

    ROUND(
        100.0 * sm.active_sellers
        / mt.total_active_sellers,
        2
    ) AS active_seller_share_pct,

    sm.completed_orders_with_state_seller,

    sm.items_sold,

    ROUND(
        100.0 * sm.items_sold
        / mt.total_items,
        2
    ) AS item_share_pct,

    sm.products_sold,

    ROUND(
        sm.item_sales_value,
        2
    ) AS item_sales_value,

    ROUND(
        100.0 * sm.item_sales_value
        / mt.total_item_sales_value,
        2
    ) AS item_sales_value_share_pct,

    ROUND(
        sm.avg_item_sales_value_per_active_seller,
        2
    ) AS avg_item_sales_value_per_active_seller

FROM state_metrics AS sm

CROSS JOIN marketplace_totals AS mt

ORDER BY
    sm.item_sales_value DESC;
