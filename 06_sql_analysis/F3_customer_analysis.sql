-- ============================================================
-- Marketplace Growth & Customer Experience Analysis
-- File: F3_customer_analysis.sql
-- Purpose: Analyse customer base, repeat purchasing behaviour,
--          merchandise activity, and geographic patterns
-- ============================================================


-- 1. Customer Base and Repeat Behaviour

-- 2. Customer Order Frequency

-- 3. One-Time vs Repeat Customer Merchandise Activity

-- 4. Customer Merchandise Distribution

-- 5. Customer Geographic Patterns


USE marketplace_growth_analysis;


-- ============================================================
-- 1. CUSTOMER BASE AND REPEAT BEHAVIOUR
-- ============================================================

WITH customer_order_summary AS (
    SELECT
        c.customer_unique_id,

        COUNT(DISTINCT o.order_id)
            AS recorded_orders,

        COUNT(
            DISTINCT CASE
                WHEN o.order_status = 'delivered'
                    THEN o.order_id
            END
        ) AS completed_orders

    FROM customers AS c

    INNER JOIN orders AS o
        ON c.customer_id = o.customer_id

    GROUP BY
        c.customer_unique_id
)

SELECT
    COUNT(*) AS recorded_unique_customers,

    SUM(
        CASE
            WHEN recorded_orders > 1 THEN 1
            ELSE 0
        END
    ) AS recorded_repeat_customers,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN recorded_orders > 1 THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS recorded_repeat_customer_rate_pct,

    SUM(
        CASE
            WHEN completed_orders > 0 THEN 1
            ELSE 0
        END
    ) AS completed_unique_customers,

    SUM(
        CASE
            WHEN completed_orders > 1 THEN 1
            ELSE 0
        END
    ) AS completed_repeat_customers,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN completed_orders > 1 THEN 1
                ELSE 0
            END
        )
        / SUM(
            CASE
                WHEN completed_orders > 0 THEN 1
                ELSE 0
            END
        ),
        2
    ) AS completed_repeat_customer_rate_pct,

    SUM(completed_orders)
        AS completed_orders,

    SUM(
        CASE
            WHEN completed_orders > 1
                THEN completed_orders
            ELSE 0
        END
    ) AS completed_orders_from_repeat_customers,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN completed_orders > 1
                    THEN completed_orders
                ELSE 0
            END
        )
        / SUM(completed_orders),
        2
    ) AS completed_order_share_from_repeat_customers_pct,

    ROUND(
        1.0 * SUM(completed_orders)
        / SUM(
            CASE
                WHEN completed_orders > 0 THEN 1
                ELSE 0
            END
        ),
        2
    ) AS avg_completed_orders_per_customer,

    ROUND(
        1.0 * SUM(
            CASE
                WHEN completed_orders > 1
                    THEN completed_orders
                ELSE 0
            END
        )
        / NULLIF(
            SUM(
                CASE
                    WHEN completed_orders > 1 THEN 1
                    ELSE 0
                END
            ),
            0
        ),
        2
    ) AS avg_completed_orders_per_repeat_customer

FROM customer_order_summary;

-- ============================================================
-- 2. CUSTOMER ORDER FREQUENCY
-- ============================================================

WITH customer_order_summary AS (
    SELECT
        c.customer_unique_id,

        COUNT(
            DISTINCT CASE
                WHEN o.order_status = 'delivered'
                    THEN o.order_id
            END
        ) AS completed_orders

    FROM customers AS c

    INNER JOIN orders AS o
        ON c.customer_id = o.customer_id

    GROUP BY
        c.customer_unique_id
),

order_frequency AS (
    SELECT
        completed_orders,
        COUNT(*) AS customer_count

    FROM customer_order_summary

    WHERE completed_orders > 0

    GROUP BY completed_orders
),

frequency_metrics AS (
    SELECT
        completed_orders,
        customer_count,

        SUM(customer_count) OVER ()
            AS total_customers,

        SUM(customer_count) OVER (
            ORDER BY completed_orders
            ROWS BETWEEN UNBOUNDED PRECEDING
                     AND CURRENT ROW
        ) AS cumulative_customers

    FROM order_frequency
)

SELECT
    completed_orders,
    customer_count,

    ROUND(
        100.0 * customer_count
        / total_customers,
        2
    ) AS customer_share_pct,

    ROUND(
        100.0 * cumulative_customers
        / total_customers,
        2
    ) AS cumulative_customer_share_pct

FROM frequency_metrics

ORDER BY completed_orders;

-- ============================================================
-- 3. ONE-TIME VS REPEAT CUSTOMER MERCHANDISE ACTIVITY
-- ============================================================

WITH order_item_summary AS (
    SELECT
        order_id,
        COUNT(*) AS item_count,
        SUM(price) AS item_sales_value
    FROM order_items
    GROUP BY order_id
),

customer_summary AS (
    SELECT
        c.customer_unique_id,

        COUNT(DISTINCT o.order_id)
            AS completed_orders,

        SUM(oi.item_count)
            AS completed_items,

        SUM(oi.item_sales_value)
            AS completed_item_sales_value

    FROM customers AS c

    INNER JOIN orders AS o
        ON c.customer_id = o.customer_id

    INNER JOIN order_item_summary AS oi
        ON o.order_id = oi.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY
        c.customer_unique_id
),

customer_segments AS (
    SELECT
        customer_unique_id,
        completed_orders,
        completed_items,
        completed_item_sales_value,

        CASE
            WHEN completed_orders > 1
                THEN 'repeat'
            ELSE 'one_time'
        END AS customer_type

    FROM customer_summary
),

segment_metrics AS (
    SELECT
        customer_type,

        COUNT(*) AS customer_count,

        SUM(completed_orders)
            AS completed_orders,

        SUM(completed_items)
            AS completed_items,

        SUM(completed_item_sales_value)
            AS completed_item_sales_value

    FROM customer_segments

    GROUP BY customer_type
),

totals AS (
    SELECT
        SUM(customer_count) AS total_customers,
        SUM(completed_orders) AS total_orders,
        SUM(completed_item_sales_value)
            AS total_item_sales_value
    FROM segment_metrics
)

SELECT
    sm.customer_type,

    sm.customer_count,

    ROUND(
        100.0 * sm.customer_count
        / t.total_customers,
        2
    ) AS customer_share_pct,

    sm.completed_orders,

    ROUND(
        100.0 * sm.completed_orders
        / t.total_orders,
        2
    ) AS completed_order_share_pct,

    sm.completed_items,

    ROUND(
        sm.completed_item_sales_value,
        2
    ) AS completed_item_sales_value,

    ROUND(
        100.0 * sm.completed_item_sales_value
        / t.total_item_sales_value,
        2
    ) AS item_sales_value_share_pct,

    ROUND(
        1.0 * sm.completed_orders
        / sm.customer_count,
        2
    ) AS avg_completed_orders_per_customer,

    ROUND(
        1.0 * sm.completed_items
        / sm.customer_count,
        2
    ) AS avg_items_per_customer,

    ROUND(
        sm.completed_item_sales_value
        / sm.customer_count,
        2
    ) AS avg_item_sales_value_per_customer,

    ROUND(
        sm.completed_item_sales_value
        / sm.completed_orders,
        2
    ) AS avg_item_sales_value_per_completed_order

FROM segment_metrics AS sm

CROSS JOIN totals AS t

ORDER BY customer_type;

-- ============================================================
-- 4. CUSTOMER MERCHANDISE DISTRIBUTION
-- ============================================================

WITH order_item_summary AS (
    SELECT
        order_id,
        SUM(price) AS item_sales_value
    FROM order_items
    GROUP BY order_id
),

customer_value AS (
    SELECT
        c.customer_unique_id,
        SUM(oi.item_sales_value)
            AS completed_item_sales_value
    FROM customers AS c

    INNER JOIN orders AS o
        ON c.customer_id = o.customer_id

    INNER JOIN order_item_summary AS oi
        ON o.order_id = oi.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY
        c.customer_unique_id
),

ranked_customers AS (
    SELECT
        customer_unique_id,
        completed_item_sales_value,

        NTILE(10) OVER (
            ORDER BY completed_item_sales_value
        ) AS value_decile

    FROM customer_value
)

SELECT
    value_decile,

    COUNT(*) AS customer_count,

    ROUND(
        MIN(completed_item_sales_value),
        2
    ) AS min_customer_item_sales_value,

    ROUND(
        AVG(completed_item_sales_value),
        2
    ) AS avg_customer_item_sales_value,

    ROUND(
        MAX(completed_item_sales_value),
        2
    ) AS max_customer_item_sales_value,

    ROUND(
        SUM(completed_item_sales_value),
        2
    ) AS total_item_sales_value,

    ROUND(
        100.0 * SUM(completed_item_sales_value)
        / SUM(
            SUM(completed_item_sales_value)
        ) OVER (),
        2
    ) AS item_sales_value_share_pct

FROM ranked_customers

GROUP BY value_decile

ORDER BY value_decile;

-- ============================================================
-- 5. CUSTOMER GEOGRAPHIC PATTERNS
-- ============================================================

-- Customer state is associated with each order record.
-- A small number of customer_unique_id values appear in more than
-- one state, so state-level distinct customer counts are not additive.
-- Repeat-customer rates identify customers who are repeat customers
-- across their full completed-order history, not necessarily within
-- the individual state.

WITH order_item_summary AS (
    SELECT
        order_id,
        COUNT(*) AS item_count,
        SUM(price) AS item_sales_value
    FROM order_items
    GROUP BY order_id
),

customer_order_summary AS (
    SELECT
        c.customer_unique_id,

        COUNT(DISTINCT o.order_id)
            AS completed_orders

    FROM customers AS c

    INNER JOIN orders AS o
        ON c.customer_id = o.customer_id

    WHERE o.order_status = 'delivered'

    GROUP BY
        c.customer_unique_id
),

completed_order_metrics AS (
    SELECT
        o.order_id,
        c.customer_unique_id,
        c.customer_state,
        oi.item_count,
        oi.item_sales_value,

        CASE
            WHEN cos.completed_orders > 1
                THEN 1
            ELSE 0
        END AS repeat_customer_flag

    FROM orders AS o

    INNER JOIN customers AS c
        ON o.customer_id = c.customer_id

    INNER JOIN order_item_summary AS oi
        ON o.order_id = oi.order_id

    INNER JOIN customer_order_summary AS cos
        ON c.customer_unique_id
         = cos.customer_unique_id

    WHERE o.order_status = 'delivered'
),

state_metrics AS (
    SELECT
        customer_state,

        COUNT(DISTINCT customer_unique_id)
            AS completed_unique_customers,

        COUNT(
            DISTINCT CASE
                WHEN repeat_customer_flag = 1
                    THEN customer_unique_id
            END
        ) AS completed_repeat_customers,

        COUNT(DISTINCT order_id)
            AS completed_orders,

        SUM(item_count)
            AS completed_items,

        SUM(item_sales_value)
            AS completed_item_sales_value

    FROM completed_order_metrics

    GROUP BY customer_state
),

totals AS (
    SELECT
        SUM(completed_orders)
            AS total_completed_orders,

        SUM(completed_item_sales_value)
            AS total_item_sales_value

    FROM state_metrics
)

SELECT
    sm.customer_state,

    sm.completed_unique_customers,

    sm.completed_repeat_customers,

    ROUND(
        100.0 * sm.completed_repeat_customers
        / sm.completed_unique_customers,
        2
    ) AS repeat_customer_rate_pct,

    sm.completed_orders,

    ROUND(
        100.0 * sm.completed_orders
        / t.total_completed_orders,
        2
    ) AS completed_order_share_pct,

    sm.completed_items,

    ROUND(
        sm.completed_item_sales_value,
        2
    ) AS completed_item_sales_value,

    ROUND(
        100.0 * sm.completed_item_sales_value
        / t.total_item_sales_value,
        2
    ) AS item_sales_value_share_pct,

    ROUND(
        sm.completed_item_sales_value
        / sm.completed_orders,
        2
    ) AS avg_item_sales_value_per_completed_order

FROM state_metrics AS sm

CROSS JOIN totals AS t

ORDER BY
    sm.completed_item_sales_value DESC;
