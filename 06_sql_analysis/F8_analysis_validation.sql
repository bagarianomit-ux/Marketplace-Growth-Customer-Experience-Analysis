-- ============================================================
-- Marketplace Growth & Customer Experience Analysis
-- File: F8_analysis_validation.sql
-- Purpose: Reconcile critical analytical metrics before
--          closing the SQL analysis phase
-- ============================================================

USE marketplace_growth_analysis;


-- ============================================================
-- FINAL ANALYTICAL VALIDATION
-- ============================================================

WITH marketplace_metrics AS (
    SELECT
        COUNT(*) AS completed_orders
    FROM orders
    WHERE order_status = 'delivered'
),

item_metrics AS (
    SELECT
        COUNT(DISTINCT oi.product_id)
            AS completed_products,

        COUNT(DISTINCT oi.seller_id)
            AS completed_sellers,

        ROUND(
            SUM(oi.price),
            2
        ) AS completed_item_sales_value

    FROM order_items AS oi

    INNER JOIN orders AS o
        ON oi.order_id = o.order_id

    WHERE o.order_status = 'delivered'
),

customer_order_counts AS (
    SELECT
        c.customer_unique_id,

        COUNT(DISTINCT o.order_id)
            AS completed_orders

    FROM orders AS o

    INNER JOIN customers AS c
        ON o.customer_id = c.customer_id

    WHERE o.order_status = 'delivered'

    GROUP BY c.customer_unique_id
),

customer_metrics AS (
    SELECT
        COUNT(*) AS completed_unique_customers,

        SUM(
            CASE
                WHEN completed_orders = 1 THEN 1
                ELSE 0
            END
        ) AS one_time_customers,

        SUM(
            CASE
                WHEN completed_orders > 1 THEN 1
                ELSE 0
            END
        ) AS repeat_customers

    FROM customer_order_counts
),

delivery_metrics AS (
    SELECT
        COUNT(*) AS eligible_delivery_orders,

        SUM(
            CASE
                WHEN order_delivered_customer_date
                     <= order_estimated_delivery_date
                    THEN 1
                ELSE 0
            END
        ) AS on_time_or_early_orders,

        SUM(
            CASE
                WHEN order_delivered_customer_date
                     > order_estimated_delivery_date
                    THEN 1
                ELSE 0
            END
        ) AS late_orders

    FROM orders

    WHERE order_status = 'delivered'
      AND order_delivered_customer_date IS NOT NULL
      AND order_estimated_delivery_date IS NOT NULL
),

payment_metrics AS (
    SELECT
        COUNT(DISTINCT order_id)
            AS paid_orders

    FROM payments
),

validation_checks AS (
    SELECT
        1 AS check_order,
        'completed_orders' AS check_name,
        CAST(96478 AS DECIMAL(18,2))
            AS expected_value,
        CAST(mm.completed_orders AS DECIMAL(18,2))
            AS actual_value

    FROM marketplace_metrics AS mm

    UNION ALL

    SELECT
        2,
        'completed_item_sales_value',
        13221498.11,
        im.completed_item_sales_value

    FROM item_metrics AS im

    UNION ALL

    SELECT
        3,
        'completed_unique_customers',
        93358.00,
        CAST(
            cm.completed_unique_customers
            AS DECIMAL(18,2)
        )

    FROM customer_metrics AS cm

    UNION ALL

    SELECT
        4,
        'repeat_completed_customers',
        2801.00,
        CAST(
            cm.repeat_customers
            AS DECIMAL(18,2)
        )

    FROM customer_metrics AS cm

    UNION ALL

    SELECT
        5,
        'customer_frequency_partition',
        CAST(
            cm.completed_unique_customers
            AS DECIMAL(18,2)
        ),
        CAST(
            cm.one_time_customers
            + cm.repeat_customers
            AS DECIMAL(18,2)
        )

    FROM customer_metrics AS cm

    UNION ALL

    SELECT
        6,
        'eligible_delivery_orders',
        96470.00,
        CAST(
            dm.eligible_delivery_orders
            AS DECIMAL(18,2)
        )

    FROM delivery_metrics AS dm

    UNION ALL

    SELECT
        7,
        'late_orders',
        7826.00,
        CAST(
            dm.late_orders
            AS DECIMAL(18,2)
        )

    FROM delivery_metrics AS dm

    UNION ALL

    SELECT
        8,
        'delivery_status_partition',
        CAST(
            dm.eligible_delivery_orders
            AS DECIMAL(18,2)
        ),
        CAST(
            dm.on_time_or_early_orders
            + dm.late_orders
            AS DECIMAL(18,2)
        )

    FROM delivery_metrics AS dm

    UNION ALL

    SELECT
        9,
        'completed_products',
        32216.00,
        CAST(
            im.completed_products
            AS DECIMAL(18,2)
        )

    FROM item_metrics AS im

    UNION ALL

    SELECT
        10,
        'completed_sellers',
        2970.00,
        CAST(
            im.completed_sellers
            AS DECIMAL(18,2)
        )

    FROM item_metrics AS im

    UNION ALL

    SELECT
        11,
        'paid_orders',
        99440.00,
        CAST(
            pm.paid_orders
            AS DECIMAL(18,2)
        )

    FROM payment_metrics AS pm
),

validation_results AS (
    SELECT
        check_order,
        check_name,
        expected_value,
        actual_value,

        CASE
            WHEN expected_value = actual_value
                THEN 'PASS'
            ELSE 'FAIL'
        END AS validation_status

    FROM validation_checks
)

SELECT
    check_name,
    expected_value,
    actual_value,
    validation_status,

    CASE
        WHEN SUM(
            CASE
                WHEN validation_status = 'FAIL'
                    THEN 1
                ELSE 0
            END
        ) OVER () = 0
            THEN 'ALL CHECKS PASS'
        ELSE 'REVIEW FAILURES'
    END AS overall_validation_status

FROM validation_results

ORDER BY check_order;
