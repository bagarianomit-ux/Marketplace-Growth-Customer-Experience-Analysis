-- ============================================================
-- Marketplace Growth & Customer Experience Analysis
-- File: F2_marketplace_performance.sql
-- Purpose: Establish marketplace scale, trends, order-status
--          behaviour, growth patterns, and concentration
-- ============================================================


-- 1. Marketplace Scale

-- 2. Monthly Marketplace Trends

-- 3. Matched-Period Growth

-- 4. Order Status Performance

-- 5. Completed vs Non-Completed Merchandise Activity

-- 6. Marketplace Concentration


USE marketplace_growth_analysis;


-- ============================================================
-- 1. MARKETPLACE SCALE
-- ============================================================

WITH order_metrics AS (
    SELECT
        COUNT(*) AS recorded_orders,
        SUM(
            CASE
                WHEN order_status = 'delivered' THEN 1
                ELSE 0
            END
        ) AS completed_orders
    FROM orders
),

customer_metrics AS (
    SELECT
        COUNT(DISTINCT c.customer_unique_id)
            AS recorded_unique_customers,

        COUNT(
            DISTINCT CASE
                WHEN o.order_status = 'delivered'
                    THEN c.customer_unique_id
            END
        ) AS completed_unique_customers

    FROM orders AS o
    INNER JOIN customers AS c
        ON o.customer_id = c.customer_id
),

item_metrics AS (
    SELECT
        COUNT(*) AS recorded_items,

        SUM(
            CASE
                WHEN o.order_status = 'delivered' THEN 1
                ELSE 0
            END
        ) AS completed_items,

        COUNT(DISTINCT oi.product_id)
            AS recorded_products,

        COUNT(
            DISTINCT CASE
                WHEN o.order_status = 'delivered'
                    THEN oi.product_id
            END
        ) AS completed_products,

        COUNT(DISTINCT oi.seller_id)
            AS recorded_sellers,

        COUNT(
            DISTINCT CASE
                WHEN o.order_status = 'delivered'
                    THEN oi.seller_id
            END
        ) AS completed_sellers,

        SUM(oi.price)
            AS recorded_item_sales_value,

        SUM(
            CASE
                WHEN o.order_status = 'delivered'
                    THEN oi.price
                ELSE 0
            END
        ) AS completed_item_sales_value,

        SUM(oi.freight_value)
            AS recorded_freight_value,

        SUM(
            CASE
                WHEN o.order_status = 'delivered'
                    THEN oi.freight_value
                ELSE 0
            END
        ) AS completed_freight_value

    FROM order_items AS oi
    INNER JOIN orders AS o
        ON oi.order_id = o.order_id
)

SELECT
    om.recorded_orders,
    om.completed_orders,

    ROUND(
        100.0 * om.completed_orders
        / om.recorded_orders,
        2
    ) AS completed_order_rate_pct,

    cm.recorded_unique_customers,
    cm.completed_unique_customers,

    im.recorded_items,
    im.completed_items,

    im.recorded_products,
    im.completed_products,

    im.recorded_sellers,
    im.completed_sellers,

    ROUND(
        im.recorded_item_sales_value,
        2
    ) AS recorded_item_sales_value,

    ROUND(
        im.completed_item_sales_value,
        2
    ) AS completed_item_sales_value,

    ROUND(
        im.recorded_freight_value,
        2
    ) AS recorded_freight_value,

    ROUND(
        im.completed_freight_value,
        2
    ) AS completed_freight_value,

    ROUND(
        im.completed_items
        / om.completed_orders,
        2
    ) AS avg_items_per_completed_order,

    ROUND(
        im.completed_item_sales_value
        / om.completed_orders,
        2
    ) AS avg_item_sales_value_per_completed_order

FROM order_metrics AS om
CROSS JOIN customer_metrics AS cm
CROSS JOIN item_metrics AS im;

-- Recorded metrics include all order statuses.
-- Completed metrics include delivered orders only.
-- Item sales value represents SUM(order_items.price) and is not
-- interpreted as Olist revenue.

-- ============================================================
-- 2. MONTHLY MARKETPLACE TRENDS
-- ============================================================

WITH monthly_orders AS (
    SELECT
        DATE_FORMAT(
            order_purchase_timestamp,
            '%Y-%m'
        ) AS order_month,

        COUNT(*) AS recorded_orders,

        SUM(
            CASE
                WHEN order_status = 'delivered' THEN 1
                ELSE 0
            END
        ) AS completed_orders

    FROM orders

    WHERE order_purchase_timestamp >= '2017-01-01'
      AND order_purchase_timestamp < '2018-09-01'

    GROUP BY
        DATE_FORMAT(
            order_purchase_timestamp,
            '%Y-%m'
        )
),

monthly_customers AS (
    SELECT
        DATE_FORMAT(
            o.order_purchase_timestamp,
            '%Y-%m'
        ) AS order_month,

        COUNT(
            DISTINCT c.customer_unique_id
        ) AS recorded_unique_customers,

        COUNT(
            DISTINCT CASE
                WHEN o.order_status = 'delivered'
                    THEN c.customer_unique_id
            END
        ) AS completed_unique_customers

    FROM orders AS o
    INNER JOIN customers AS c
        ON o.customer_id = c.customer_id

    WHERE o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp < '2018-09-01'

    GROUP BY
        DATE_FORMAT(
            o.order_purchase_timestamp,
            '%Y-%m'
        )
),

monthly_items AS (
    SELECT
        DATE_FORMAT(
            o.order_purchase_timestamp,
            '%Y-%m'
        ) AS order_month,

        COUNT(*) AS recorded_items,

        SUM(
            CASE
                WHEN o.order_status = 'delivered' THEN 1
                ELSE 0
            END
        ) AS completed_items,

        SUM(
            CASE
                WHEN o.order_status = 'delivered'
                    THEN oi.price
                ELSE 0
            END
        ) AS completed_item_sales_value

    FROM order_items AS oi
    INNER JOIN orders AS o
        ON oi.order_id = o.order_id

    WHERE o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp < '2018-09-01'

    GROUP BY
        DATE_FORMAT(
            o.order_purchase_timestamp,
            '%Y-%m'
        )
)

SELECT
    mo.order_month,

    mo.recorded_orders,
    mo.completed_orders,

    ROUND(
        100.0 * mo.completed_orders
        / mo.recorded_orders,
        2
    ) AS completed_order_rate_pct,

    mc.recorded_unique_customers,
    mc.completed_unique_customers,

    mi.recorded_items,
    mi.completed_items,

    ROUND(
        mi.completed_item_sales_value,
        2
    ) AS completed_item_sales_value,

    ROUND(
        mi.completed_item_sales_value
        / mo.completed_orders,
        2
    ) AS avg_item_sales_value_per_completed_order

FROM monthly_orders AS mo

INNER JOIN monthly_customers AS mc
    ON mo.order_month = mc.order_month

INNER JOIN monthly_items AS mi
    ON mo.order_month = mi.order_month

ORDER BY mo.order_month;

-- ============================================================
-- 3. MATCHED-PERIOD GROWTH
-- ============================================================

WITH period_orders AS (
    SELECT
        YEAR(order_purchase_timestamp) AS order_year,
        SUM(
            CASE
                WHEN order_status = 'delivered' THEN 1
                ELSE 0
            END
        ) AS completed_orders

    FROM orders

    WHERE (
        order_purchase_timestamp >= '2017-01-01'
        AND order_purchase_timestamp < '2017-09-01'
    )
    OR (
        order_purchase_timestamp >= '2018-01-01'
        AND order_purchase_timestamp < '2018-09-01'
    )

    GROUP BY YEAR(order_purchase_timestamp)
),

period_customers AS (
    SELECT
        YEAR(o.order_purchase_timestamp) AS order_year,

        COUNT(
            DISTINCT c.customer_unique_id
        ) AS recorded_unique_customers,

        COUNT(
            DISTINCT CASE
                WHEN o.order_status = 'delivered'
                    THEN c.customer_unique_id
            END
        ) AS completed_unique_customers

    FROM orders AS o
    INNER JOIN customers AS c
        ON o.customer_id = c.customer_id

    WHERE (
        o.order_purchase_timestamp >= '2017-01-01'
        AND o.order_purchase_timestamp < '2017-09-01'
    )
    OR (
        o.order_purchase_timestamp >= '2018-01-01'
        AND o.order_purchase_timestamp < '2018-09-01'
    )

    GROUP BY YEAR(o.order_purchase_timestamp)
),

period_items AS (
    SELECT
        YEAR(o.order_purchase_timestamp) AS order_year,

        COUNT(*) AS recorded_items,

        SUM(
            CASE
                WHEN o.order_status = 'delivered' THEN 1
                ELSE 0
            END
        ) AS completed_items,

        SUM(
            CASE
                WHEN o.order_status = 'delivered'
                    THEN oi.price
                ELSE 0
            END
        ) AS completed_item_sales_value

    FROM order_items AS oi
    INNER JOIN orders AS o
        ON oi.order_id = o.order_id

    WHERE (
        o.order_purchase_timestamp >= '2017-01-01'
        AND o.order_purchase_timestamp < '2017-09-01'
    )
    OR (
        o.order_purchase_timestamp >= '2018-01-01'
        AND o.order_purchase_timestamp < '2018-09-01'
    )

    GROUP BY YEAR(o.order_purchase_timestamp)
),

period_metrics AS (
    SELECT
        po.order_year,
        po.recorded_orders,
        po.completed_orders,

        ROUND(
            100.0 * po.completed_orders
            / po.recorded_orders,
            2
        ) AS completed_order_rate_pct,

        pc.recorded_unique_customers,
        pc.completed_unique_customers,

        pi.recorded_items,
        pi.completed_items,

        ROUND(
            pi.completed_item_sales_value,
            2
        ) AS completed_item_sales_value,

        ROUND(
            pi.completed_item_sales_value
            / po.completed_orders,
            2
        ) AS avg_item_sales_value_per_completed_order

    FROM period_orders AS po

    INNER JOIN period_customers AS pc
        ON po.order_year = pc.order_year

    INNER JOIN period_items AS pi
        ON po.order_year = pi.order_year
)

SELECT *
FROM period_metrics
ORDER BY order_year;

-- Matched-period growth rates

WITH period_orders AS (
    SELECT
        YEAR(order_purchase_timestamp) AS order_year,

        COUNT(*) AS recorded_orders,

        SUM(
            CASE
                WHEN order_status = 'delivered' THEN 1
                ELSE 0
            END
        ) AS completed_orders

    FROM orders

    WHERE (
        order_purchase_timestamp >= '2017-01-01'
        AND order_purchase_timestamp < '2017-09-01'
    )
    OR (
        order_purchase_timestamp >= '2018-01-01'
        AND order_purchase_timestamp < '2018-09-01'
    )

    GROUP BY YEAR(order_purchase_timestamp)
),

period_customers AS (
    SELECT
        YEAR(o.order_purchase_timestamp) AS order_year,

        COUNT(
            DISTINCT CASE
                WHEN o.order_status = 'delivered'
                    THEN c.customer_unique_id
            END
        ) AS completed_unique_customers

    FROM orders AS o
    INNER JOIN customers AS c
        ON o.customer_id = c.customer_id

    WHERE (
        o.order_purchase_timestamp >= '2017-01-01'
        AND o.order_purchase_timestamp < '2017-09-01'
    )
    OR (
        o.order_purchase_timestamp >= '2018-01-01'
        AND o.order_purchase_timestamp < '2018-09-01'
    )

    GROUP BY YEAR(o.order_purchase_timestamp)
),

period_items AS (
    SELECT
        YEAR(o.order_purchase_timestamp) AS order_year,

        SUM(
            CASE
                WHEN o.order_status = 'delivered' THEN 1
                ELSE 0
            END
        ) AS completed_items,

        SUM(
            CASE
                WHEN o.order_status = 'delivered'
                    THEN oi.price
                ELSE 0
            END
        ) AS completed_item_sales_value

    FROM order_items AS oi
    INNER JOIN orders AS o
        ON oi.order_id = o.order_id

    WHERE (
        o.order_purchase_timestamp >= '2017-01-01'
        AND o.order_purchase_timestamp < '2017-09-01'
    )
    OR (
        o.order_purchase_timestamp >= '2018-01-01'
        AND o.order_purchase_timestamp < '2018-09-01'
    )

    GROUP BY YEAR(o.order_purchase_timestamp)
),

period_metrics AS (
    SELECT
        po.order_year,
        po.completed_orders,
        pc.completed_unique_customers,
        pi.completed_items,
        pi.completed_item_sales_value,

        pi.completed_item_sales_value
        / po.completed_orders
            AS avg_item_sales_value_per_completed_order

    FROM period_orders AS po

    INNER JOIN period_customers AS pc
        ON po.order_year = pc.order_year

    INNER JOIN period_items AS pi
        ON po.order_year = pi.order_year
),

growth_metrics AS (
    SELECT
        *,

        LAG(completed_orders)
            OVER (ORDER BY order_year)
            AS previous_completed_orders,

        LAG(completed_unique_customers)
            OVER (ORDER BY order_year)
            AS previous_completed_unique_customers,

        LAG(completed_items)
            OVER (ORDER BY order_year)
            AS previous_completed_items,

        LAG(completed_item_sales_value)
            OVER (ORDER BY order_year)
            AS previous_completed_item_sales_value,

        LAG(avg_item_sales_value_per_completed_order)
            OVER (ORDER BY order_year)
            AS previous_avg_item_sales_value_per_order

    FROM period_metrics
)

SELECT
    order_year,

    ROUND(
        100.0 * (
            completed_orders
            - previous_completed_orders
        ) / previous_completed_orders,
        2
    ) AS completed_order_growth_pct,

    ROUND(
        100.0 * (
            completed_unique_customers
            - previous_completed_unique_customers
        ) / previous_completed_unique_customers,
        2
    ) AS completed_customer_growth_pct,

    ROUND(
        100.0 * (
            completed_items
            - previous_completed_items
        ) / previous_completed_items,
        2
    ) AS completed_item_growth_pct,

    ROUND(
        100.0 * (
            completed_item_sales_value
            - previous_completed_item_sales_value
        ) / previous_completed_item_sales_value,
        2
    ) AS completed_item_sales_value_growth_pct,

    ROUND(
        100.0 * (
            avg_item_sales_value_per_completed_order
            - previous_avg_item_sales_value_per_order
        ) / previous_avg_item_sales_value_per_order,
        2
    ) AS avg_item_sales_value_per_order_growth_pct

FROM growth_metrics

WHERE previous_completed_orders IS NOT NULL

ORDER BY order_year;

-- ============================================================
-- 4. ORDER STATUS PERFORMANCE
-- ============================================================

WITH status_metrics AS (
    SELECT
        YEAR(order_purchase_timestamp) AS order_year,
        order_status,
        COUNT(*) AS order_count

    FROM orders

    WHERE (
        order_purchase_timestamp >= '2017-01-01'
        AND order_purchase_timestamp < '2017-09-01'
    )
    OR (
        order_purchase_timestamp >= '2018-01-01'
        AND order_purchase_timestamp < '2018-09-01'
    )

    GROUP BY
        YEAR(order_purchase_timestamp),
        order_status
),

year_totals AS (
    SELECT
        order_year,
        SUM(order_count) AS total_orders
    FROM status_metrics
    GROUP BY order_year
)

SELECT
    sm.order_year,
    sm.order_status,
    sm.order_count,

    ROUND(
        100.0 * sm.order_count
        / yt.total_orders,
        2
    ) AS status_share_pct

FROM status_metrics AS sm

INNER JOIN year_totals AS yt
    ON sm.order_year = yt.order_year

ORDER BY
    sm.order_year,
    sm.order_count DESC;
    
-- ============================================================
-- 5. COMPLETED VS NON-COMPLETED MERCHANDISE ACTIVITY
-- ============================================================

WITH order_item_metrics AS (
    SELECT
        order_id,
        COUNT(*) AS item_count,
        SUM(price) AS item_sales_value,
        SUM(freight_value) AS freight_value
    FROM order_items
    GROUP BY order_id
),

status_merchandise AS (
    SELECT
        o.order_status,

        COUNT(*) AS recorded_orders,

        SUM(
            CASE
                WHEN oi.order_id IS NOT NULL THEN 1
                ELSE 0
            END
        ) AS orders_with_items,

        COALESCE(
            SUM(oi.item_count),
            0
        ) AS item_count,

        COALESCE(
            SUM(oi.item_sales_value),
            0
        ) AS item_sales_value,

        COALESCE(
            SUM(oi.freight_value),
            0
        ) AS freight_value

    FROM orders AS o

    LEFT JOIN order_item_metrics AS oi
        ON o.order_id = oi.order_id

    GROUP BY o.order_status
),

totals AS (
    SELECT
        SUM(item_sales_value)
            AS total_item_sales_value
    FROM status_merchandise
)

SELECT
    sm.order_status,
    sm.recorded_orders,
    sm.orders_with_items,
    sm.item_count,

    ROUND(
        sm.item_sales_value,
        2
    ) AS item_sales_value,

    ROUND(
        100.0 * sm.item_sales_value
        / t.total_item_sales_value,
        2
    ) AS item_sales_value_share_pct,

    ROUND(
        sm.freight_value,
        2
    ) AS freight_value

FROM status_merchandise AS sm

CROSS JOIN totals AS t

ORDER BY sm.item_sales_value DESC;

-- ============================================================
-- 6. MARKETPLACE CONCENTRATION
-- ============================================================

WITH customer_value AS (
    SELECT
        c.customer_unique_id AS entity_id,
        SUM(oi.price) AS item_sales_value
    FROM orders AS o
    INNER JOIN customers AS c
        ON o.customer_id = c.customer_id
    INNER JOIN order_items AS oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),

category_value AS (
    SELECT
        COALESCE(
            p.product_category_name,
            'unknown'
        ) AS entity_id,
        SUM(oi.price) AS item_sales_value
    FROM orders AS o
    INNER JOIN order_items AS oi
        ON o.order_id = oi.order_id
    INNER JOIN products AS p
        ON oi.product_id = p.product_id
    WHERE o.order_status = 'delivered'
    GROUP BY
        COALESCE(
            p.product_category_name,
            'unknown'
        )
),

seller_value AS (
    SELECT
        oi.seller_id AS entity_id,
        SUM(oi.price) AS item_sales_value
    FROM orders AS o
    INNER JOIN order_items AS oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY oi.seller_id
),

combined_entities AS (
    SELECT
        'customer' AS entity_type,
        entity_id,
        item_sales_value
    FROM customer_value

    UNION ALL

    SELECT
        'category',
        entity_id,
        item_sales_value
    FROM category_value

    UNION ALL

    SELECT
        'seller',
        entity_id,
        item_sales_value
    FROM seller_value
),

ranked_entities AS (
    SELECT
        entity_type,
        entity_id,
        item_sales_value,

        ROW_NUMBER() OVER (
            PARTITION BY entity_type
            ORDER BY item_sales_value DESC
        ) AS entity_rank,

        SUM(item_sales_value) OVER (
            PARTITION BY entity_type
            ORDER BY item_sales_value DESC
            ROWS BETWEEN UNBOUNDED PRECEDING
                     AND CURRENT ROW
        ) AS cumulative_item_sales_value,

        SUM(item_sales_value) OVER (
            PARTITION BY entity_type
        ) AS total_item_sales_value,

        COUNT(*) OVER (
            PARTITION BY entity_type
        ) AS total_entities

    FROM combined_entities
),

concentration AS (
    SELECT
        entity_type,
        total_entities,

        MIN(
            CASE
                WHEN cumulative_item_sales_value
                     >= total_item_sales_value * 0.50
                THEN entity_rank
            END
        ) AS entities_for_50_pct,

        MIN(
            CASE
                WHEN cumulative_item_sales_value
                     >= total_item_sales_value * 0.80
                THEN entity_rank
            END
        ) AS entities_for_80_pct

    FROM ranked_entities

    GROUP BY
        entity_type,
        total_entities
)

SELECT
    entity_type,
    total_entities,
    entities_for_50_pct,

    ROUND(
        100.0 * entities_for_50_pct
        / total_entities,
        2
    ) AS entity_share_for_50_pct,

    entities_for_80_pct,

    ROUND(
        100.0 * entities_for_80_pct
        / total_entities,
        2
    ) AS entity_share_for_80_pct

FROM concentration

ORDER BY entity_type;
