-- ============================================================
-- Marketplace Growth & Customer Experience Analysis
-- File: F7_payment_analysis.sql
-- Purpose: Analyse payment methods, payment structure,
--          installment behaviour, and payment trends
-- ============================================================


-- 1. Payment Analysis Population & Structure

-- 2. Payment Method Mix & Multi-Payment Behaviour

-- 3. Installment Behaviour & Payment Value

-- 4. Payment Behaviour Over Time

USE marketplace_growth_analysis;


-- ============================================================
-- 1. PAYMENT ANALYSIS POPULATION & STRUCTURE
-- ============================================================

WITH order_payment_structure AS (
    SELECT
        order_id,

        COUNT(*) AS payment_records,

        COUNT(DISTINCT payment_type)
            AS payment_methods,

        SUM(payment_value)
            AS order_payment_value,

        MAX(payment_installments)
            AS max_installments

    FROM payments

    GROUP BY order_id
),

order_totals AS (
    SELECT
        COUNT(*) AS recorded_orders
    FROM orders
),

payment_totals AS (
    SELECT
        COUNT(*) AS payment_records,

        COUNT(DISTINCT order_id)
            AS orders_with_payments,

        ROUND(
            SUM(payment_value),
            2
        ) AS recorded_payment_value

    FROM payments
)

SELECT
    ot.recorded_orders,

    pt.orders_with_payments,

    ot.recorded_orders - pt.orders_with_payments
        AS orders_without_payments,

    pt.payment_records,

    pt.recorded_payment_value,

    SUM(
        CASE
            WHEN ops.payment_records = 1 THEN 1
            ELSE 0
        END
    ) AS single_payment_record_orders,

    SUM(
        CASE
            WHEN ops.payment_records > 1 THEN 1
            ELSE 0
        END
    ) AS multiple_payment_record_orders,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN ops.payment_records > 1 THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS multiple_payment_record_order_pct,

    SUM(
        CASE
            WHEN ops.payment_methods > 1 THEN 1
            ELSE 0
        END
    ) AS multiple_payment_method_orders,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN ops.payment_methods > 1 THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS multiple_payment_method_order_pct,

    ROUND(
        AVG(ops.payment_records),
        2
    ) AS avg_payment_records_per_paid_order,

    MAX(ops.payment_records)
        AS max_payment_records_per_order,

    MAX(ops.payment_methods)
        AS max_payment_methods_per_order

FROM order_payment_structure AS ops

CROSS JOIN order_totals AS ot
CROSS JOIN payment_totals AS pt

GROUP BY
    ot.recorded_orders,
    pt.orders_with_payments,
    pt.payment_records,
    pt.recorded_payment_value;
    
 -- ============================================================
-- 2. PAYMENT METHOD MIX & MULTI-PAYMENT BEHAVIOUR
-- ============================================================

-- Payment method mix

WITH payment_method_metrics AS (
    SELECT
        payment_type,

        COUNT(*) AS payment_records,

        COUNT(DISTINCT order_id)
            AS orders_using_method,

        SUM(payment_value)
            AS recorded_payment_value,

        AVG(payment_value)
            AS avg_payment_record_value

    FROM payments

    GROUP BY payment_type
),

payment_totals AS (
    SELECT
        COUNT(*) AS total_payment_records,

        COUNT(DISTINCT order_id)
            AS total_paid_orders,

        SUM(payment_value)
            AS total_recorded_payment_value

    FROM payments
)

SELECT
    pmm.payment_type,

    pmm.payment_records,

    ROUND(
        100.0 * pmm.payment_records
        / pt.total_payment_records,
        2
    ) AS payment_record_share_pct,

    pmm.orders_using_method,

    ROUND(
        100.0 * pmm.orders_using_method
        / pt.total_paid_orders,
        2
    ) AS paid_order_usage_pct,

    ROUND(
        pmm.recorded_payment_value,
        2
    ) AS recorded_payment_value,

    ROUND(
        100.0 * pmm.recorded_payment_value
        / pt.total_recorded_payment_value,
        2
    ) AS payment_value_share_pct,

    ROUND(
        pmm.avg_payment_record_value,
        2
    ) AS avg_payment_record_value

FROM payment_method_metrics AS pmm

CROSS JOIN payment_totals AS pt

ORDER BY
    pmm.recorded_payment_value DESC;   

-- Payment-method combinations for mixed-payment orders

WITH mixed_payment_orders AS (
    SELECT
        order_id,

        GROUP_CONCAT(
            DISTINCT payment_type
            ORDER BY payment_type
            SEPARATOR ' + '
        ) AS payment_method_combination,

        SUM(payment_value)
            AS order_payment_value

    FROM payments

    GROUP BY order_id

    HAVING COUNT(DISTINCT payment_type) > 1
),

combination_metrics AS (
    SELECT
        payment_method_combination,

        COUNT(*) AS mixed_payment_orders,

        AVG(order_payment_value)
            AS avg_order_payment_value

    FROM mixed_payment_orders

    GROUP BY payment_method_combination
)

SELECT
    payment_method_combination,

    mixed_payment_orders,

    ROUND(
        100.0 * mixed_payment_orders
        / SUM(mixed_payment_orders) OVER (),
        2
    ) AS mixed_order_share_pct,

    ROUND(
        avg_order_payment_value,
        2
    ) AS avg_order_payment_value

FROM combination_metrics

ORDER BY
    mixed_payment_orders DESC;
    
-- ============================================================
-- 3. INSTALLMENT BEHAVIOUR & PAYMENT VALUE
-- ============================================================

-- Credit-card installment distribution

WITH credit_card_payments AS (
    SELECT
        order_id,
        payment_installments,
        payment_value

    FROM payments

    WHERE payment_type = 'credit_card'
)

SELECT
    payment_installments,

    COUNT(*) AS credit_card_payment_records,

    COUNT(DISTINCT order_id)
        AS orders_using_installment_count,

    ROUND(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER (),
        2
    ) AS payment_record_share_pct,

    ROUND(
        SUM(payment_value),
        2
    ) AS recorded_credit_card_value,

    ROUND(
        AVG(payment_value),
        2
    ) AS avg_credit_card_payment_value

FROM credit_card_payments

GROUP BY payment_installments

ORDER BY payment_installments;

-- Credit-card installment bands

WITH credit_card_payments AS (
    SELECT
        payment_installments,
        payment_value,

        CASE
            WHEN payment_installments <= 0
                THEN 'non_positive'
            WHEN payment_installments = 1
                THEN '1_installment'
            WHEN payment_installments <= 3
                THEN '2_to_3_installments'
            WHEN payment_installments <= 6
                THEN '4_to_6_installments'
            WHEN payment_installments <= 12
                THEN '7_to_12_installments'
            ELSE '13_plus_installments'
        END AS installment_group,

        CASE
            WHEN payment_installments <= 0 THEN 1
            WHEN payment_installments = 1 THEN 2
            WHEN payment_installments <= 3 THEN 3
            WHEN payment_installments <= 6 THEN 4
            WHEN payment_installments <= 12 THEN 5
            ELSE 6
        END AS installment_group_order

    FROM payments

    WHERE payment_type = 'credit_card'
)

SELECT
    installment_group,

    COUNT(*) AS credit_card_payment_records,

    ROUND(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER (),
        2
    ) AS payment_record_share_pct,

    ROUND(
        SUM(payment_value),
        2
    ) AS recorded_credit_card_value,

    ROUND(
        AVG(payment_value),
        2
    ) AS avg_credit_card_payment_value

FROM credit_card_payments

GROUP BY
    installment_group,
    installment_group_order

ORDER BY installment_group_order;

-- ============================================================
-- 4. PAYMENT BEHAVIOUR OVER TIME
-- ============================================================

WITH monthly_payment_metrics AS (
    SELECT
        DATE_FORMAT(
            o.order_purchase_timestamp,
            '%Y-%m'
        ) AS order_month,

        p.payment_type,

        COUNT(DISTINCT p.order_id)
            AS orders_using_method,

        SUM(p.payment_value)
            AS recorded_payment_value

    FROM payments AS p

    INNER JOIN orders AS o
        ON p.order_id = o.order_id

    WHERE o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp < '2018-09-01'

    GROUP BY
        DATE_FORMAT(
            o.order_purchase_timestamp,
            '%Y-%m'
        ),
        p.payment_type
),

monthly_totals AS (
    SELECT
        DATE_FORMAT(
            o.order_purchase_timestamp,
            '%Y-%m'
        ) AS order_month,

        COUNT(DISTINCT p.order_id)
            AS paid_orders,

        SUM(p.payment_value)
            AS total_recorded_payment_value

    FROM payments AS p

    INNER JOIN orders AS o
        ON p.order_id = o.order_id

    WHERE o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp < '2018-09-01'

    GROUP BY
        DATE_FORMAT(
            o.order_purchase_timestamp,
            '%Y-%m'
        )
)

SELECT
    mpm.order_month,
    mpm.payment_type,

    mpm.orders_using_method,

    ROUND(
        100.0 * mpm.orders_using_method
        / mt.paid_orders,
        2
    ) AS paid_order_usage_pct,

    ROUND(
        mpm.recorded_payment_value,
        2
    ) AS recorded_payment_value,

    ROUND(
        100.0 * mpm.recorded_payment_value
        / mt.total_recorded_payment_value,
        2
    ) AS payment_value_share_pct

FROM monthly_payment_metrics AS mpm

INNER JOIN monthly_totals AS mt
    ON mpm.order_month = mt.order_month

ORDER BY
    mpm.order_month,
    mpm.recorded_payment_value DESC;
