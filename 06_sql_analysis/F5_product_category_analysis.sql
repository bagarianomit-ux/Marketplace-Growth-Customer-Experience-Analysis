-- ============================================================
-- Marketplace Growth & Customer Experience Analysis
-- File: F5_product_category_analysis.sql
-- Purpose: Analyse product and category performance, growth,
--          concentration, and review outcomes
-- ============================================================


-- 1. Product & Category Analysis Population

-- 2. Category Commercial Performance

-- 3. Category Growth & Change

-- 4. Product Performance & Concentration

-- 5. Category Review Outcomes

USE marketplace_growth_analysis;


-- ============================================================
-- 1. PRODUCT & CATEGORY ANALYSIS POPULATION
-- ============================================================

WITH completed_items AS (
    SELECT
        oi.order_id,
        oi.product_id,
        oi.price,
        p.product_category_name,
        ct.product_category_name_english

    FROM order_items AS oi

    INNER JOIN orders AS o
        ON oi.order_id = o.order_id

    INNER JOIN products AS p
        ON oi.product_id = p.product_id

    LEFT JOIN category_translation AS ct
        ON p.product_category_name = ct.product_category_name

    WHERE o.order_status = 'delivered'
)

SELECT
    COUNT(*) AS completed_items,

    COUNT(DISTINCT product_id)
        AS completed_products,

    ROUND(
        SUM(price),
        2
    ) AS completed_item_sales_value,

    SUM(
        CASE
            WHEN product_category_name IS NULL
                THEN 1
            ELSE 0
        END
    ) AS items_missing_category,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN product_category_name IS NULL
                    THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS items_missing_category_pct,

    ROUND(
        SUM(
            CASE
                WHEN product_category_name IS NULL
                    THEN price
                ELSE 0
            END
        ),
        2
    ) AS sales_value_missing_category,

    SUM(
        CASE
            WHEN product_category_name IS NOT NULL
             AND product_category_name_english IS NULL
                THEN 1
            ELSE 0
        END
    ) AS items_with_untranslated_category,

    ROUND(
        SUM(
            CASE
                WHEN product_category_name IS NOT NULL
                 AND product_category_name_english IS NULL
                    THEN price
                ELSE 0
            END
        ),
        2
    ) AS sales_value_untranslated_category,

    COUNT(
        DISTINCT CASE
            WHEN product_category_name IS NOT NULL
                THEN product_category_name
        END
    ) AS represented_source_categories,

    COUNT(
        DISTINCT product_category_name_english
    ) AS represented_translated_categories

FROM completed_items;

-- ============================================================
-- 2. CATEGORY COMMERCIAL PERFORMANCE
-- ============================================================

WITH completed_items AS (
    SELECT
        oi.order_id,
        oi.product_id,
        oi.price,
        p.product_category_name AS source_category_name,

        COALESCE(
            ct.product_category_name_english,
            p.product_category_name,
            'unknown'
        ) AS category_name

    FROM order_items AS oi

    INNER JOIN orders AS o
        ON oi.order_id = o.order_id

    INNER JOIN products AS p
        ON oi.product_id = p.product_id

    LEFT JOIN category_translation AS ct
        ON p.product_category_name = ct.product_category_name

    WHERE o.order_status = 'delivered'
),

category_metrics AS (
    SELECT
        source_category_name,
        category_name,

        COUNT(DISTINCT order_id)
            AS completed_orders,

        COUNT(*)
            AS items_sold,

        COUNT(DISTINCT product_id)
            AS products_sold,

        SUM(price)
            AS item_sales_value,

        AVG(price)
            AS avg_item_price,

        SUM(price) / COUNT(DISTINCT order_id)
            AS avg_category_sales_value_per_order

    FROM completed_items

    GROUP BY
        source_category_name,
        category_name
),

marketplace_totals AS (
    SELECT
        COUNT(*) AS total_items,
        SUM(price) AS total_item_sales_value
    FROM completed_items
)

SELECT
    cm.category_name,

    cm.completed_orders,

    cm.items_sold,

    cm.products_sold,

    ROUND(
        cm.item_sales_value,
        2
    ) AS item_sales_value,

    ROUND(
        100.0 * cm.item_sales_value
        / mt.total_item_sales_value,
        2
    ) AS item_sales_value_share_pct,

    ROUND(
        100.0 * cm.items_sold
        / mt.total_items,
        2
    ) AS item_share_pct,

    ROUND(
        cm.avg_item_price,
        2
    ) AS avg_item_price,

    ROUND(
        cm.avg_category_sales_value_per_order,
        2
    ) AS avg_category_sales_value_per_order

FROM category_metrics AS cm

CROSS JOIN marketplace_totals AS mt

ORDER BY
    cm.item_sales_value DESC;
    
-- ============================================================
-- 3. CATEGORY GROWTH & CHANGE
-- ============================================================

WITH completed_items AS (
    SELECT
        YEAR(o.order_purchase_timestamp) AS order_year,

        oi.order_id,
        oi.product_id,
        oi.price,

        p.product_category_name AS source_category_name,

        COALESCE(
            ct.product_category_name_english,
            p.product_category_name,
            'unknown'
        ) AS category_name

    FROM order_items AS oi

    INNER JOIN orders AS o
        ON oi.order_id = o.order_id

    INNER JOIN products AS p
        ON oi.product_id = p.product_id

    LEFT JOIN category_translation AS ct
        ON p.product_category_name = ct.product_category_name

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
),

category_year_metrics AS (
    SELECT
        source_category_name,
        category_name,
        order_year,

        COUNT(*) AS items_sold,

        COUNT(DISTINCT order_id)
            AS completed_orders,

        SUM(price)
            AS item_sales_value

    FROM completed_items

    GROUP BY
        source_category_name,
        category_name,
        order_year
),

category_comparison AS (
    SELECT
        source_category_name,
        category_name,

        SUM(
            CASE
                WHEN order_year = 2017
                    THEN completed_orders
                ELSE 0
            END
        ) AS completed_orders_2017,

        SUM(
            CASE
                WHEN order_year = 2018
                    THEN completed_orders
                ELSE 0
            END
        ) AS completed_orders_2018,

        SUM(
            CASE
                WHEN order_year = 2017
                    THEN items_sold
                ELSE 0
            END
        ) AS items_sold_2017,

        SUM(
            CASE
                WHEN order_year = 2018
                    THEN items_sold
                ELSE 0
            END
        ) AS items_sold_2018,

        SUM(
            CASE
                WHEN order_year = 2017
                    THEN item_sales_value
                ELSE 0
            END
        ) AS item_sales_value_2017,

        SUM(
            CASE
                WHEN order_year = 2018
                    THEN item_sales_value
                ELSE 0
            END
        ) AS item_sales_value_2018

    FROM category_year_metrics

    GROUP BY
        source_category_name,
        category_name
),

marketplace_totals AS (
    SELECT
        SUM(
            CASE
                WHEN order_year = 2017
                    THEN price
                ELSE 0
            END
        ) AS marketplace_sales_2017,

        SUM(
            CASE
                WHEN order_year = 2018
                    THEN price
                ELSE 0
            END
        ) AS marketplace_sales_2018

    FROM completed_items
)

SELECT
    cc.category_name,

    cc.completed_orders_2017,
    cc.completed_orders_2018,

    cc.items_sold_2017,
    cc.items_sold_2018,

    ROUND(
        cc.item_sales_value_2017,
        2
    ) AS item_sales_value_2017,

    ROUND(
        cc.item_sales_value_2018,
        2
    ) AS item_sales_value_2018,

    ROUND(
        cc.item_sales_value_2018
        - cc.item_sales_value_2017,
        2
    ) AS item_sales_value_change,

    ROUND(
        100.0 * (
            cc.item_sales_value_2018
            - cc.item_sales_value_2017
        )
        / NULLIF(
            cc.item_sales_value_2017,
            0
        ),
        2
    ) AS item_sales_value_growth_pct,

    ROUND(
        100.0 * cc.item_sales_value_2017
        / mt.marketplace_sales_2017,
        2
    ) AS marketplace_share_2017_pct,

    ROUND(
        100.0 * cc.item_sales_value_2018
        / mt.marketplace_sales_2018,
        2
    ) AS marketplace_share_2018_pct,

    ROUND(
        (
            100.0 * cc.item_sales_value_2018
            / mt.marketplace_sales_2018
        )
        -
        (
            100.0 * cc.item_sales_value_2017
            / mt.marketplace_sales_2017
        ),
        2
    ) AS marketplace_share_change_pp,

    ROUND(
        100.0 * (
            cc.item_sales_value_2018
            - cc.item_sales_value_2017
        )
        / NULLIF(
            mt.marketplace_sales_2018
            - mt.marketplace_sales_2017,
            0
        ),
        2
    ) AS contribution_to_sales_growth_pct

FROM category_comparison AS cc

CROSS JOIN marketplace_totals AS mt

ORDER BY
    item_sales_value_change DESC;
    
-- ============================================================
-- 4. PRODUCT PERFORMANCE & CONCENTRATION
-- ============================================================

WITH product_metrics AS (
    SELECT
        oi.product_id,
        SUM(oi.price) AS item_sales_value

    FROM order_items AS oi

    INNER JOIN orders AS o
        ON oi.order_id = o.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY oi.product_id
),

ranked_products AS (
    SELECT
        product_id,
        item_sales_value,

        ROW_NUMBER() OVER (
            ORDER BY item_sales_value DESC
        ) AS product_rank,

        COUNT(*) OVER ()
            AS total_products,

        SUM(item_sales_value) OVER ()
            AS total_item_sales_value,

        SUM(item_sales_value) OVER (
            ORDER BY item_sales_value DESC
            ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
        ) AS cumulative_item_sales_value

    FROM product_metrics
),

product_shares AS (
    SELECT
        product_id,
        product_rank,
        total_products,

        100.0 * cumulative_item_sales_value
        / total_item_sales_value
            AS cumulative_sales_share_pct

    FROM ranked_products
)

SELECT
    MAX(total_products)
        AS completed_products,

    MIN(
        CASE
            WHEN cumulative_sales_share_pct >= 50
                THEN product_rank
        END
    ) AS products_for_50_pct_sales,

    ROUND(
        100.0 * MIN(
            CASE
                WHEN cumulative_sales_share_pct >= 50
                    THEN product_rank
            END
        ) / MAX(total_products),
        2
    ) AS product_share_for_50_pct_sales,

    MIN(
        CASE
            WHEN cumulative_sales_share_pct >= 80
                THEN product_rank
        END
    ) AS products_for_80_pct_sales,

    ROUND(
        100.0 * MIN(
            CASE
                WHEN cumulative_sales_share_pct >= 80
                    THEN product_rank
            END
        ) / MAX(total_products),
        2
    ) AS product_share_for_80_pct_sales

FROM product_shares;

-- Leading products by completed item sales value

WITH product_metrics AS (
    SELECT
        oi.product_id,

        COALESCE(
            ct.product_category_name_english,
            p.product_category_name,
            'unknown'
        ) AS category_name,

        COUNT(DISTINCT oi.order_id)
            AS completed_orders,

        COUNT(*) AS items_sold,

        SUM(oi.price)
            AS item_sales_value,

        AVG(oi.price)
            AS avg_item_price

    FROM order_items AS oi

    INNER JOIN orders AS o
        ON oi.order_id = o.order_id

    INNER JOIN products AS p
        ON oi.product_id = p.product_id

    LEFT JOIN category_translation AS ct
        ON p.product_category_name = ct.product_category_name

    WHERE o.order_status = 'delivered'

    GROUP BY
        oi.product_id,
        p.product_category_name,
        ct.product_category_name_english
),

marketplace_total AS (
    SELECT
        SUM(item_sales_value)
            AS total_item_sales_value
    FROM product_metrics
),

ranked_products AS (
    SELECT
        pm.*,

        ROW_NUMBER() OVER (
            ORDER BY item_sales_value DESC
        ) AS product_rank

    FROM product_metrics AS pm
)

SELECT
    rp.product_rank,
    rp.product_id,
    rp.category_name,

    rp.completed_orders,
    rp.items_sold,

    ROUND(
        rp.item_sales_value,
        2
    ) AS item_sales_value,

    ROUND(
        100.0 * rp.item_sales_value
        / mt.total_item_sales_value,
        2
    ) AS item_sales_value_share_pct,

    ROUND(
        rp.avg_item_price,
        2
    ) AS avg_item_price

FROM ranked_products AS rp

CROSS JOIN marketplace_total AS mt

WHERE rp.product_rank <= 20

ORDER BY rp.product_rank;

-- ============================================================
-- 5. CATEGORY REVIEW OUTCOMES
-- ============================================================

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

order_categories AS (
    SELECT DISTINCT
        oi.order_id,

        p.product_category_name AS source_category_name,

        COALESCE(
            ct.product_category_name_english,
            p.product_category_name,
            'unknown'
        ) AS category_name

    FROM order_items AS oi

    INNER JOIN products AS p
        ON oi.product_id = p.product_id

    LEFT JOIN category_translation AS ct
        ON p.product_category_name = ct.product_category_name
),

category_review_metrics AS (
    SELECT
        oc.source_category_name,
        oc.category_name,

        COUNT(*) AS orders_with_category,

        COUNT(rr.order_id)
            AS reviewed_orders,

        AVG(rr.review_score)
            AS avg_review_score,

        100.0 * SUM(
            CASE
                WHEN rr.review_score <= 2 THEN 1
                ELSE 0
            END
        ) / COUNT(rr.order_id)
            AS low_review_rate_pct,

        100.0 * SUM(
            CASE
                WHEN rr.review_score >= 4 THEN 1
                ELSE 0
            END
        ) / COUNT(rr.order_id)
            AS high_review_rate_pct

    FROM order_categories AS oc

    LEFT JOIN representative_reviews AS rr
        ON oc.order_id = rr.order_id

    GROUP BY
        oc.source_category_name,
        oc.category_name
)

SELECT
    category_name,

    orders_with_category,
    reviewed_orders,

    ROUND(
        100.0 * reviewed_orders
        / orders_with_category,
        2
    ) AS review_coverage_pct,

    ROUND(
        avg_review_score,
        2
    ) AS avg_review_score,

    ROUND(
        low_review_rate_pct,
        2
    ) AS low_review_rate_pct,

    ROUND(
        high_review_rate_pct,
        2
    ) AS high_review_rate_pct

FROM category_review_metrics

ORDER BY
    reviewed_orders DESC;
