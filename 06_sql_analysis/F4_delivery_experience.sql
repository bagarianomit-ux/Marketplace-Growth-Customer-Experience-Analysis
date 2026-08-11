-- ============================================================
-- Marketplace Growth & Customer Experience Analysis
-- File: F4_delivery_experience.sql
-- Purpose: Analyse delivery performance, lateness, review
--          outcomes, and geographic customer experience
-- ============================================================


-- 1. Delivery Analysis Population

-- 2. Delivery Duration and Reliability

-- 3. Delivery Performance Over Time

-- 4. Delivery Delay Severity and Review Outcomes

-- 5. Geographic Delivery Experience

USE marketplace_growth_analysis;


-- ============================================================
-- 1. DELIVERY ANALYSIS POPULATION
-- ============================================================

SELECT
    COUNT(*) AS delivered_orders,

    SUM(
        CASE
            WHEN order_delivered_customer_date IS NOT NULL
                THEN 1
            ELSE 0
        END
    ) AS orders_with_customer_delivery_date,

    SUM(
        CASE
            WHEN order_delivered_customer_date IS NULL
                THEN 1
            ELSE 0
        END
    ) AS orders_missing_customer_delivery_date,

    SUM(
        CASE
            WHEN order_estimated_delivery_date IS NOT NULL
                THEN 1
            ELSE 0
        END
    ) AS orders_with_estimated_delivery_date,

    SUM(
        CASE
            WHEN order_delivered_customer_date IS NOT NULL
             AND order_estimated_delivery_date IS NOT NULL
                THEN 1
            ELSE 0
        END
    ) AS orders_eligible_for_lateness_analysis,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN order_delivered_customer_date IS NOT NULL
                 AND order_estimated_delivery_date IS NOT NULL
                    THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS lateness_analysis_coverage_pct

FROM orders

WHERE order_status = 'delivered';

-- Chronological checks within the delivered-order population

SELECT
    SUM(
        CASE
            WHEN order_delivered_customer_date
                 < order_purchase_timestamp
                THEN 1
            ELSE 0
        END
    ) AS delivery_before_purchase,

    SUM(
        CASE
            WHEN order_delivered_customer_date
                 < order_delivered_carrier_date
                THEN 1
            ELSE 0
        END
    ) AS customer_delivery_before_carrier,

    SUM(
        CASE
            WHEN order_estimated_delivery_date
                 < order_purchase_timestamp
                THEN 1
            ELSE 0
        END
    ) AS estimate_before_purchase

FROM orders

WHERE order_status = 'delivered';

-- ============================================================
-- 2. DELIVERY DURATION AND RELIABILITY
-- ============================================================

WITH delivery_metrics AS (
    SELECT
        order_id,

        TIMESTAMPDIFF(
            SECOND,
            order_purchase_timestamp,
            order_delivered_customer_date
        ) / 86400.0 AS delivery_days,

        TIMESTAMPDIFF(
            SECOND,
            order_purchase_timestamp,
            order_estimated_delivery_date
        ) / 86400.0 AS estimated_delivery_days,

        TIMESTAMPDIFF(
            SECOND,
            order_estimated_delivery_date,
            order_delivered_customer_date
        ) / 86400.0 AS delivery_delay_days,

        CASE
            WHEN order_delivered_customer_date
                 > order_estimated_delivery_date
                THEN 1
            ELSE 0
        END AS late_delivery_flag

    FROM orders

    WHERE order_status = 'delivered'
      AND order_delivered_customer_date IS NOT NULL
      AND order_estimated_delivery_date IS NOT NULL
)

SELECT
    COUNT(*) AS eligible_delivered_orders,

    ROUND(
        AVG(delivery_days),
        2
    ) AS avg_delivery_days,

    ROUND(
        AVG(estimated_delivery_days),
        2
    ) AS avg_estimated_delivery_days,

    SUM(
        CASE
            WHEN late_delivery_flag = 0 THEN 1
            ELSE 0
        END
    ) AS on_time_or_early_orders,

    SUM(late_delivery_flag)
        AS late_orders,

    ROUND(
        100.0 * SUM(late_delivery_flag)
        / COUNT(*),
        2
    ) AS late_delivery_rate_pct,

    ROUND(
        AVG(
            CASE
                WHEN late_delivery_flag = 1
                    THEN delivery_delay_days
            END
        ),
        2
    ) AS avg_delay_days_for_late_orders,

    ROUND(
        AVG(
            CASE
                WHEN late_delivery_flag = 0
                    THEN -delivery_delay_days
            END
        ),
        2
    ) AS avg_days_early_for_on_time_orders

FROM delivery_metrics;

-- Delivery duration and late-delay distribution

WITH delivery_metrics AS (
    SELECT
        order_id,

        TIMESTAMPDIFF(
            SECOND,
            order_purchase_timestamp,
            order_delivered_customer_date
        ) / 86400.0 AS delivery_days,

        TIMESTAMPDIFF(
            SECOND,
            order_estimated_delivery_date,
            order_delivered_customer_date
        ) / 86400.0 AS delivery_delay_days

    FROM orders

    WHERE order_status = 'delivered'
      AND order_delivered_customer_date IS NOT NULL
      AND order_estimated_delivery_date IS NOT NULL
),

ranked_delivery AS (
    SELECT
        delivery_days,

        ROW_NUMBER() OVER (
            ORDER BY delivery_days
        ) AS row_num,

        COUNT(*) OVER ()
            AS total_rows

    FROM delivery_metrics
),

delivery_percentiles AS (
    SELECT
      AVG(
    CASE
        WHEN row_num IN (
            FLOOR((total_rows + 1) / 2),
            CEIL((total_rows + 1) / 2)
        )
            THEN delivery_days
        END
        ) AS median_delivery_days,

        MAX(
            CASE
                WHEN row_num = CEIL(total_rows * 0.75)
                    THEN delivery_days
            END
        ) AS p75_delivery_days,

        MAX(
            CASE
                WHEN row_num = CEIL(total_rows * 0.90)
                    THEN delivery_days
            END
        ) AS p90_delivery_days,

        MAX(
            CASE
                WHEN row_num = CEIL(total_rows * 0.95)
                    THEN delivery_days
            END
        ) AS p95_delivery_days,

        MAX(delivery_days)
            AS max_delivery_days

    FROM ranked_delivery
),

ranked_late_orders AS (
    SELECT
        delivery_delay_days,

        ROW_NUMBER() OVER (
            ORDER BY delivery_delay_days
        ) AS row_num,

        COUNT(*) OVER ()
            AS total_rows

    FROM delivery_metrics

    WHERE delivery_delay_days > 0
),

late_percentiles AS (
    SELECT
       AVG(
    CASE
        WHEN row_num IN (
            FLOOR((total_rows + 1) / 2),
            CEIL((total_rows + 1) / 2)
            )
            THEN delivery_delay_days
          END
          ) AS median_late_delay_days,

        MAX(
            CASE
                WHEN row_num = CEIL(total_rows * 0.90)
                    THEN delivery_delay_days
            END
        ) AS p90_late_delay_days,

        MAX(
            CASE
                WHEN row_num = CEIL(total_rows * 0.95)
                    THEN delivery_delay_days
            END
        ) AS p95_late_delay_days,

        MAX(delivery_delay_days)
            AS max_late_delay_days

    FROM ranked_late_orders
)

SELECT
    ROUND(
        dp.median_delivery_days,
        2
    ) AS median_delivery_days,

    ROUND(
        dp.p75_delivery_days,
        2
    ) AS p75_delivery_days,

    ROUND(
        dp.p90_delivery_days,
        2
    ) AS p90_delivery_days,

    ROUND(
        dp.p95_delivery_days,
        2
    ) AS p95_delivery_days,

    ROUND(
        dp.max_delivery_days,
        2
    ) AS max_delivery_days,

    ROUND(
        lp.median_late_delay_days,
        2
    ) AS median_late_delay_days,

    ROUND(
        lp.p90_late_delay_days,
        2
    ) AS p90_late_delay_days,

    ROUND(
        lp.p95_late_delay_days,
        2
    ) AS p95_late_delay_days,

    ROUND(
        lp.max_late_delay_days,
        2
    ) AS max_late_delay_days

FROM delivery_percentiles AS dp
CROSS JOIN late_percentiles AS lp;

-- ============================================================
-- 3. DELIVERY PERFORMANCE OVER TIME
-- ============================================================

WITH delivery_metrics AS (
    SELECT
        DATE_FORMAT(
            order_purchase_timestamp,
            '%Y-%m'
        ) AS order_month,

        TIMESTAMPDIFF(
            SECOND,
            order_purchase_timestamp,
            order_delivered_customer_date
        ) / 86400.0 AS delivery_days,

        TIMESTAMPDIFF(
            SECOND,
            order_purchase_timestamp,
            order_estimated_delivery_date
        ) / 86400.0 AS estimated_delivery_days,

        TIMESTAMPDIFF(
            SECOND,
            order_estimated_delivery_date,
            order_delivered_customer_date
        ) / 86400.0 AS delivery_delay_days,

        CASE
            WHEN order_delivered_customer_date
                 > order_estimated_delivery_date
                THEN 1
            ELSE 0
        END AS late_delivery_flag

    FROM orders

    WHERE order_status = 'delivered'
      AND order_delivered_customer_date IS NOT NULL
      AND order_estimated_delivery_date IS NOT NULL
      AND order_purchase_timestamp >= '2017-01-01'
      AND order_purchase_timestamp < '2018-09-01'
)

SELECT
    order_month,

    COUNT(*) AS eligible_delivered_orders,

    ROUND(
        AVG(delivery_days),
        2
    ) AS avg_delivery_days,

    ROUND(
        AVG(estimated_delivery_days),
        2
    ) AS avg_estimated_delivery_days,

    SUM(late_delivery_flag)
        AS late_orders,

    ROUND(
        100.0 * SUM(late_delivery_flag)
        / COUNT(*),
        2
    ) AS late_delivery_rate_pct,

    ROUND(
        AVG(
            CASE
                WHEN late_delivery_flag = 1
                    THEN delivery_delay_days
            END
        ),
        2
    ) AS avg_delay_days_for_late_orders,

    ROUND(
        AVG(
            CASE
                WHEN late_delivery_flag = 0
                    THEN -delivery_delay_days
            END
        ),
        2
    ) AS avg_days_early_for_on_time_orders

FROM delivery_metrics

GROUP BY order_month

ORDER BY order_month;

-- Matched-period delivery comparison

WITH delivery_metrics AS (
    SELECT
        YEAR(order_purchase_timestamp) AS order_year,

        TIMESTAMPDIFF(
            SECOND,
            order_purchase_timestamp,
            order_delivered_customer_date
        ) / 86400.0 AS delivery_days,

        TIMESTAMPDIFF(
            SECOND,
            order_purchase_timestamp,
            order_estimated_delivery_date
        ) / 86400.0 AS estimated_delivery_days,

        TIMESTAMPDIFF(
            SECOND,
            order_estimated_delivery_date,
            order_delivered_customer_date
        ) / 86400.0 AS delivery_delay_days,

        CASE
            WHEN order_delivered_customer_date
                 > order_estimated_delivery_date
                THEN 1
            ELSE 0
        END AS late_delivery_flag

    FROM orders

    WHERE order_status = 'delivered'
      AND order_delivered_customer_date IS NOT NULL
      AND order_estimated_delivery_date IS NOT NULL

      AND (
            (
                order_purchase_timestamp >= '2017-01-01'
                AND order_purchase_timestamp < '2017-09-01'
            )
            OR
            (
                order_purchase_timestamp >= '2018-01-01'
                AND order_purchase_timestamp < '2018-09-01'
            )
      )
)

SELECT
    order_year,

    COUNT(*) AS eligible_delivered_orders,

    ROUND(
        AVG(delivery_days),
        2
    ) AS avg_delivery_days,

    ROUND(
        AVG(estimated_delivery_days),
        2
    ) AS avg_estimated_delivery_days,

    SUM(late_delivery_flag)
        AS late_orders,

    ROUND(
        100.0 * SUM(late_delivery_flag)
        / COUNT(*),
        2
    ) AS late_delivery_rate_pct,

    ROUND(
        AVG(
            CASE
                WHEN late_delivery_flag = 1
                    THEN delivery_delay_days
            END
        ),
        2
    ) AS avg_delay_days_for_late_orders,

    ROUND(
        AVG(
            CASE
                WHEN late_delivery_flag = 0
                    THEN -delivery_delay_days
            END
        ),
        2
    ) AS avg_days_early_for_on_time_orders

FROM delivery_metrics

GROUP BY order_year

ORDER BY order_year;

-- ============================================================
-- 4. DELIVERY DELAY SEVERITY AND REVIEW OUTCOMES
-- ============================================================

-- Review coverage for the eligible delivery population

WITH ranked_reviews AS (
    SELECT
        order_id,
        review_id,
        review_score,
        review_answer_timestamp,

        ROW_NUMBER() OVER (
            PARTITION BY order_id
            ORDER BY
                review_answer_timestamp DESC,
                review_id DESC
        ) AS review_rank

    FROM reviews
),

representative_reviews AS (
    SELECT
        order_id,
        review_score
    FROM ranked_reviews
    WHERE review_rank = 1
),

eligible_delivery AS (
    SELECT
        order_id,

        CASE
            WHEN order_delivered_customer_date
                 > order_estimated_delivery_date
                THEN 1
            ELSE 0
        END AS late_delivery_flag

    FROM orders

    WHERE order_status = 'delivered'
      AND order_delivered_customer_date IS NOT NULL
      AND order_estimated_delivery_date IS NOT NULL
)

SELECT
    COUNT(*) AS eligible_delivered_orders,

    SUM(
        CASE
            WHEN rr.order_id IS NOT NULL THEN 1
            ELSE 0
        END
    ) AS reviewed_eligible_orders,

    SUM(
        CASE
            WHEN rr.order_id IS NULL THEN 1
            ELSE 0
        END
    ) AS orders_without_review,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN rr.order_id IS NOT NULL THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS review_coverage_pct,

    SUM(
        CASE
            WHEN ed.late_delivery_flag = 0 THEN 1
            ELSE 0
        END
    ) AS on_time_or_early_orders,

    SUM(
        CASE
            WHEN ed.late_delivery_flag = 0
             AND rr.order_id IS NOT NULL
                THEN 1
            ELSE 0
        END
    ) AS reviewed_on_time_or_early_orders,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN ed.late_delivery_flag = 0
                 AND rr.order_id IS NOT NULL
                    THEN 1
                ELSE 0
            END
        )
        / SUM(
            CASE
                WHEN ed.late_delivery_flag = 0 THEN 1
                ELSE 0
            END
        ),
        2
    ) AS on_time_review_coverage_pct,

    SUM(
        CASE
            WHEN ed.late_delivery_flag = 1 THEN 1
            ELSE 0
        END
    ) AS late_orders,

    SUM(
        CASE
            WHEN ed.late_delivery_flag = 1
             AND rr.order_id IS NOT NULL
                THEN 1
            ELSE 0
        END
    ) AS reviewed_late_orders,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN ed.late_delivery_flag = 1
                 AND rr.order_id IS NOT NULL
                    THEN 1
                ELSE 0
            END
        )
        / SUM(
            CASE
                WHEN ed.late_delivery_flag = 1 THEN 1
                ELSE 0
            END
        ),
        2
    ) AS late_review_coverage_pct

FROM eligible_delivery AS ed

LEFT JOIN representative_reviews AS rr
    ON ed.order_id = rr.order_id;
    
-- Review outcomes by delivery-delay severity

WITH ranked_reviews AS (
    SELECT
        order_id,
        review_id,
        review_score,
        review_answer_timestamp,

        ROW_NUMBER() OVER (
            PARTITION BY order_id
            ORDER BY
                review_answer_timestamp DESC,
                review_id DESC
        ) AS review_rank

    FROM reviews
),

representative_reviews AS (
    SELECT
        order_id,
        review_score
    FROM ranked_reviews
    WHERE review_rank = 1
),

delivery_metrics AS (
    SELECT
        order_id,

        TIMESTAMPDIFF(
            SECOND,
            order_estimated_delivery_date,
            order_delivered_customer_date
        ) / 86400.0 AS delivery_delay_days

    FROM orders

    WHERE order_status = 'delivered'
      AND order_delivered_customer_date IS NOT NULL
      AND order_estimated_delivery_date IS NOT NULL
),

delivery_groups AS (
    SELECT
        order_id,
        delivery_delay_days,

       CASE
    WHEN delivery_delay_days <= 0
        THEN 'on_time_or_early'
    WHEN delivery_delay_days <= 3
        THEN 'over_0_to_3_days_late'
    WHEN delivery_delay_days <= 7
        THEN 'over_3_to_7_days_late'
    WHEN delivery_delay_days <= 14
        THEN 'over_7_to_14_days_late'
    WHEN delivery_delay_days <= 30
        THEN 'over_14_to_30_days_late'
    ELSE 'over_30_days_late'
END AS delay_group,

        CASE
            WHEN delivery_delay_days <= 0 THEN 1
            WHEN delivery_delay_days <= 3 THEN 2
            WHEN delivery_delay_days <= 7 THEN 3
            WHEN delivery_delay_days <= 14 THEN 4
            WHEN delivery_delay_days <= 30 THEN 5
            ELSE 6
        END AS delay_group_order

    FROM delivery_metrics
)

SELECT
    dg.delay_group,

    COUNT(*) AS eligible_orders,

    COUNT(rr.order_id)
        AS reviewed_orders,

    ROUND(
        100.0 * COUNT(rr.order_id)
        / COUNT(*),
        2
    ) AS review_coverage_pct,

    ROUND(
        AVG(rr.review_score),
        2
    ) AS avg_review_score,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN rr.review_score <= 2 THEN 1
                ELSE 0
            END
        )
        / COUNT(rr.order_id),
        2
    ) AS low_review_rate_pct,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN rr.review_score >= 4 THEN 1
                ELSE 0
            END
        )
        / COUNT(rr.order_id),
        2
    ) AS high_review_rate_pct

FROM delivery_groups AS dg

LEFT JOIN representative_reviews AS rr
    ON dg.order_id = rr.order_id

GROUP BY
    dg.delay_group,
    dg.delay_group_order

ORDER BY
    dg.delay_group_order;   
    
-- ============================================================
-- 5. GEOGRAPHIC DELIVERY EXPERIENCE
-- ============================================================

WITH delivery_metrics AS (
    SELECT
        c.customer_state,
        o.order_id,

        TIMESTAMPDIFF(
            SECOND,
            o.order_purchase_timestamp,
            o.order_delivered_customer_date
        ) / 86400.0 AS delivery_days,

        TIMESTAMPDIFF(
            SECOND,
            o.order_purchase_timestamp,
            o.order_estimated_delivery_date
        ) / 86400.0 AS estimated_delivery_days,

        TIMESTAMPDIFF(
            SECOND,
            o.order_estimated_delivery_date,
            o.order_delivered_customer_date
        ) / 86400.0 AS delivery_delay_days,

        CASE
            WHEN o.order_delivered_customer_date
                 > o.order_estimated_delivery_date
                THEN 1
            ELSE 0
        END AS late_delivery_flag

    FROM orders AS o

    INNER JOIN customers AS c
        ON o.customer_id = c.customer_id

    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL
),

state_metrics AS (
    SELECT
        customer_state,

        COUNT(*) AS eligible_delivered_orders,

        AVG(delivery_days)
            AS avg_delivery_days,

        AVG(estimated_delivery_days)
            AS avg_estimated_delivery_days,

        SUM(late_delivery_flag)
            AS late_orders,

        100.0 * SUM(late_delivery_flag)
        / COUNT(*)
            AS late_delivery_rate_pct,

        AVG(
            CASE
                WHEN late_delivery_flag = 1
                    THEN delivery_delay_days
            END
        ) AS avg_delay_days_for_late_orders

    FROM delivery_metrics

    GROUP BY customer_state
),

marketplace_metrics AS (
    SELECT
        COUNT(*) AS total_eligible_orders,

        AVG(delivery_days)
            AS marketplace_avg_delivery_days,

        100.0 * SUM(late_delivery_flag)
        / COUNT(*)
            AS marketplace_late_delivery_rate_pct

    FROM delivery_metrics
)

SELECT
    sm.customer_state,

    sm.eligible_delivered_orders,

    ROUND(
        100.0 * sm.eligible_delivered_orders
        / mm.total_eligible_orders,
        2
    ) AS eligible_order_share_pct,

    ROUND(
        sm.avg_delivery_days,
        2
    ) AS avg_delivery_days,

    ROUND(
        sm.avg_estimated_delivery_days,
        2
    ) AS avg_estimated_delivery_days,

    sm.late_orders,

    ROUND(
        sm.late_delivery_rate_pct,
        2
    ) AS late_delivery_rate_pct,

    ROUND(
        sm.late_delivery_rate_pct
        - mm.marketplace_late_delivery_rate_pct,
        2
    ) AS late_rate_vs_marketplace_pp,

    ROUND(
        sm.avg_delivery_days
        - mm.marketplace_avg_delivery_days,
        2
    ) AS delivery_days_vs_marketplace,

    ROUND(
        sm.avg_delay_days_for_late_orders,
        2
    ) AS avg_delay_days_for_late_orders

FROM state_metrics AS sm

CROSS JOIN marketplace_metrics AS mm

ORDER BY
    sm.eligible_delivered_orders DESC;
