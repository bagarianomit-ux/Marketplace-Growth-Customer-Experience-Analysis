-- ============================================================
-- Marketplace Growth & Customer Experience Analysis
-- File: E2_load_validation.sql
-- Purpose: Validate the populated MySQL database against the
--          cleaned and validated data-preparation baseline
-- ============================================================

USE marketplace_growth_analysis;


-- ============================================================
-- 1. ROW COUNT RECONCILIATION
-- ============================================================

SELECT
    table_name,
    expected_rows,
    actual_rows,
    CASE
        WHEN expected_rows = actual_rows THEN 'PASS'
        ELSE 'FAIL'
    END AS status
FROM (
    SELECT
        'customers' AS table_name,
        99441 AS expected_rows,
        (SELECT COUNT(*) FROM customers) AS actual_rows

    UNION ALL

    SELECT
        'products',
        32951,
        (SELECT COUNT(*) FROM products)

    UNION ALL

    SELECT
        'sellers',
        3095,
        (SELECT COUNT(*) FROM sellers)

    UNION ALL

    SELECT
        'category_translation',
        71,
        (SELECT COUNT(*) FROM category_translation)

    UNION ALL

    SELECT
        'geolocation',
        738332,
        (SELECT COUNT(*) FROM geolocation)

    UNION ALL

    SELECT
        'orders',
        99441,
        (SELECT COUNT(*) FROM orders)

    UNION ALL

    SELECT
        'order_items',
        112650,
        (SELECT COUNT(*) FROM order_items)

    UNION ALL

    SELECT
        'payments',
        103886,
        (SELECT COUNT(*) FROM payments)

    UNION ALL

    SELECT
        'reviews',
        99224,
        (SELECT COUNT(*) FROM reviews)
) AS row_validation;


-- ============================================================
-- 2. PRIMARY KEY AND GRAIN VALIDATION
-- ============================================================

SELECT
    key_name,
    total_rows,
    distinct_key_rows,
    CASE
        WHEN total_rows = distinct_key_rows THEN 'PASS'
        ELSE 'FAIL'
    END AS status
FROM (
    SELECT
        'customers.customer_id' AS key_name,
        COUNT(*) AS total_rows,
        COUNT(DISTINCT customer_id) AS distinct_key_rows
    FROM customers

    UNION ALL

    SELECT
        'orders.order_id',
        COUNT(*),
        COUNT(DISTINCT order_id)
    FROM orders

    UNION ALL

    SELECT
        'products.product_id',
        COUNT(*),
        COUNT(DISTINCT product_id)
    FROM products

    UNION ALL

    SELECT
        'sellers.seller_id',
        COUNT(*),
        COUNT(DISTINCT seller_id)
    FROM sellers

    UNION ALL

    SELECT
        'order_items.(order_id, order_item_id)',
        COUNT(*),
        COUNT(DISTINCT order_id, order_item_id)
    FROM order_items

    UNION ALL

    SELECT
        'payments.(order_id, payment_sequential)',
        COUNT(*),
        COUNT(DISTINCT order_id, payment_sequential)
    FROM payments

    UNION ALL

    SELECT
        'reviews.(review_id, order_id)',
        COUNT(*),
        COUNT(DISTINCT review_id, order_id)
    FROM reviews

    UNION ALL

    SELECT
        'category_translation.product_category_name',
        COUNT(*),
        COUNT(DISTINCT product_category_name)
    FROM category_translation

    UNION ALL

    SELECT
        'geolocation.geolocation_id',
        COUNT(*),
        COUNT(DISTINCT geolocation_id)
    FROM geolocation
) AS key_validation;


-- ============================================================
-- 3. FOREIGN KEY INTEGRITY
-- ============================================================

SELECT
    relationship_name,
    expected_orphans,
    actual_orphans,
    CASE
        WHEN expected_orphans = actual_orphans THEN 'PASS'
        ELSE 'FAIL'
    END AS status
FROM (
    SELECT
        'orders -> customers' AS relationship_name,
        0 AS expected_orphans,
        (
            SELECT COUNT(*)
            FROM orders AS o
            LEFT JOIN customers AS c
                ON o.customer_id = c.customer_id
            WHERE c.customer_id IS NULL
        ) AS actual_orphans

    UNION ALL

    SELECT
        'order_items -> orders',
        0,
        (
            SELECT COUNT(*)
            FROM order_items AS oi
            LEFT JOIN orders AS o
                ON oi.order_id = o.order_id
            WHERE o.order_id IS NULL
        )

    UNION ALL

    SELECT
        'order_items -> products',
        0,
        (
            SELECT COUNT(*)
            FROM order_items AS oi
            LEFT JOIN products AS p
                ON oi.product_id = p.product_id
            WHERE p.product_id IS NULL
        )

    UNION ALL

    SELECT
        'order_items -> sellers',
        0,
        (
            SELECT COUNT(*)
            FROM order_items AS oi
            LEFT JOIN sellers AS s
                ON oi.seller_id = s.seller_id
            WHERE s.seller_id IS NULL
        )

    UNION ALL

    SELECT
        'payments -> orders',
        0,
        (
            SELECT COUNT(*)
            FROM payments AS p
            LEFT JOIN orders AS o
                ON p.order_id = o.order_id
            WHERE o.order_id IS NULL
        )

    UNION ALL

    SELECT
        'reviews -> orders',
        0,
        (
            SELECT COUNT(*)
            FROM reviews AS r
            LEFT JOIN orders AS o
                ON r.order_id = o.order_id
            WHERE o.order_id IS NULL
        )
) AS foreign_key_validation;


-- ============================================================
-- 4. RELATIONSHIP COVERAGE
-- ============================================================

SELECT
    metric,
    expected_value,
    actual_value,
    CASE
        WHEN expected_value = actual_value THEN 'PASS'
        ELSE 'FAIL'
    END AS status
FROM (
    SELECT
        'customers_without_orders' AS metric,
        0 AS expected_value,
        (
            SELECT COUNT(*)
            FROM customers AS c
            WHERE NOT EXISTS (
                SELECT 1
                FROM orders AS o
                WHERE o.customer_id = c.customer_id
            )
        ) AS actual_value

    UNION ALL

    SELECT
        'orders_without_items',
        775,
        (
            SELECT COUNT(*)
            FROM orders AS o
            WHERE NOT EXISTS (
                SELECT 1
                FROM order_items AS oi
                WHERE oi.order_id = o.order_id
            )
        )

    UNION ALL

    SELECT
        'orders_without_payments',
        1,
        (
            SELECT COUNT(*)
            FROM orders AS o
            WHERE NOT EXISTS (
                SELECT 1
                FROM payments AS p
                WHERE p.order_id = o.order_id
            )
        )

    UNION ALL

    SELECT
        'orders_without_reviews',
        768,
        (
            SELECT COUNT(*)
            FROM orders AS o
            WHERE NOT EXISTS (
                SELECT 1
                FROM reviews AS r
                WHERE r.order_id = o.order_id
            )
        )

    UNION ALL

    SELECT
        'products_without_sales',
        0,
        (
            SELECT COUNT(*)
            FROM products AS p
            WHERE NOT EXISTS (
                SELECT 1
                FROM order_items AS oi
                WHERE oi.product_id = p.product_id
            )
        )

    UNION ALL

    SELECT
        'sellers_without_sales',
        0,
        (
            SELECT COUNT(*)
            FROM sellers AS s
            WHERE NOT EXISTS (
                SELECT 1
                FROM order_items AS oi
                WHERE oi.seller_id = s.seller_id
            )
        )
) AS coverage_validation;


-- ============================================================
-- 5. CARDINALITY AND BUSINESS REPETITION
-- ============================================================

SELECT
    metric,
    expected_value,
    actual_value,
    CASE
        WHEN expected_value = actual_value THEN 'PASS'
        ELSE 'FAIL'
    END AS status
FROM (
    SELECT
        'distinct_customer_unique_id' AS metric,
        96096 AS expected_value,
        COUNT(DISTINCT customer_unique_id) AS actual_value
    FROM customers

    UNION ALL

    SELECT
        'max_customer_records_per_unique_customer',
        17,
        (
            SELECT MAX(record_count)
            FROM (
                SELECT
                    customer_unique_id,
                    COUNT(*) AS record_count
                FROM customers
                GROUP BY customer_unique_id
            ) AS customer_counts
        )

    UNION ALL

    SELECT
        'max_items_per_order',
        21,
        (
            SELECT MAX(item_count)
            FROM (
                SELECT
                    order_id,
                    COUNT(*) AS item_count
                FROM order_items
                GROUP BY order_id
            ) AS item_counts
        )

    UNION ALL

    SELECT
        'max_payments_per_order',
        29,
        (
            SELECT MAX(payment_count)
            FROM (
                SELECT
                    order_id,
                    COUNT(*) AS payment_count
                FROM payments
                GROUP BY order_id
            ) AS payment_counts
        )

    UNION ALL

    SELECT
        'max_reviews_per_order',
        3,
        (
            SELECT MAX(review_count)
            FROM (
                SELECT
                    order_id,
                    COUNT(*) AS review_count
                FROM reviews
                GROUP BY order_id
            ) AS review_counts
        )

    UNION ALL

    SELECT
        'rows_with_repeated_review_id',
        1603,
        (
            SELECT SUM(review_count)
            FROM (
                SELECT
                    review_id,
                    COUNT(*) AS review_count
                FROM reviews
                GROUP BY review_id
                HAVING COUNT(*) > 1
            ) AS repeated_reviews
        )
) AS cardinality_validation;


-- ============================================================
-- 6. NULL PRESERVATION
-- ============================================================

SELECT
    field_name,
    expected_nulls,
    actual_nulls,
    CASE
        WHEN expected_nulls = actual_nulls THEN 'PASS'
        ELSE 'FAIL'
    END AS status
FROM (
    SELECT
        'orders.order_approved_at' AS field_name,
        160 AS expected_nulls,
        SUM(order_approved_at IS NULL) AS actual_nulls
    FROM orders

    UNION ALL

    SELECT
        'orders.order_delivered_carrier_date',
        1783,
        SUM(order_delivered_carrier_date IS NULL)
    FROM orders

    UNION ALL

    SELECT
        'orders.order_delivered_customer_date',
        2965,
        SUM(order_delivered_customer_date IS NULL)
    FROM orders

    UNION ALL

    SELECT
        'reviews.review_comment_title',
        87658,
        SUM(review_comment_title IS NULL)
    FROM reviews

    UNION ALL

    SELECT
        'reviews.review_comment_message',
        58274,
        SUM(review_comment_message IS NULL)
    FROM reviews

    UNION ALL

    SELECT
        'products.product_category_name',
        610,
        SUM(product_category_name IS NULL)
    FROM products

    UNION ALL

    SELECT
        'products.product_name_length',
        610,
        SUM(product_name_length IS NULL)
    FROM products

    UNION ALL

    SELECT
        'products.product_description_length',
        610,
        SUM(product_description_length IS NULL)
    FROM products

    UNION ALL

    SELECT
        'products.product_photos_qty',
        610,
        SUM(product_photos_qty IS NULL)
    FROM products

    UNION ALL

    SELECT
        'products.product_weight_g',
        2,
        SUM(product_weight_g IS NULL)
    FROM products

    UNION ALL

    SELECT
        'products.product_length_cm',
        2,
        SUM(product_length_cm IS NULL)
    FROM products

    UNION ALL

    SELECT
        'products.product_height_cm',
        2,
        SUM(product_height_cm IS NULL)
    FROM products

    UNION ALL

    SELECT
        'products.product_width_cm',
        2,
        SUM(product_width_cm IS NULL)
    FROM products
) AS null_validation;


-- ============================================================
-- 7. NUMERIC VALUE PRESERVATION
-- ============================================================

SELECT
    metric,
    expected_min,
    actual_min,
    expected_max,
    actual_max,
    CASE
        WHEN expected_min = actual_min
         AND expected_max = actual_max
        THEN 'PASS'
        ELSE 'FAIL'
    END AS status
FROM (
    SELECT
        'order_items.price' AS metric,
        0.85 AS expected_min,
        MIN(price) AS actual_min,
        6735.00 AS expected_max,
        MAX(price) AS actual_max
    FROM order_items

    UNION ALL

    SELECT
        'order_items.freight_value',
        0.00,
        MIN(freight_value),
        409.68,
        MAX(freight_value)
    FROM order_items

    UNION ALL

    SELECT
        'payments.payment_value',
        0.00,
        MIN(payment_value),
        13664.08,
        MAX(payment_value)
    FROM payments

    UNION ALL

    SELECT
        'reviews.review_score',
        1,
        MIN(review_score),
        5,
        MAX(review_score)
    FROM reviews

    UNION ALL

    SELECT
        'products.product_weight_g',
        0,
        MIN(product_weight_g),
        40425,
        MAX(product_weight_g)
    FROM products
) AS numeric_validation;


-- ============================================================
-- 8. RETAINED UNUSUAL VALUES
-- ============================================================

SELECT
    metric,
    expected_value,
    actual_value,
    CASE
        WHEN expected_value = actual_value THEN 'PASS'
        ELSE 'FAIL'
    END AS status
FROM (
    SELECT
        'zero_payment_values' AS metric,
        9 AS expected_value,
        SUM(payment_value = 0) AS actual_value
    FROM payments

    UNION ALL

    SELECT
        'zero_payment_installments',
        2,
        SUM(payment_installments = 0)
    FROM payments

    UNION ALL

    SELECT
        'not_defined_payment_type',
        3,
        SUM(payment_type = 'not_defined')
    FROM payments

    UNION ALL

    SELECT
        'zero_product_weight',
        4,
        SUM(product_weight_g = 0)
    FROM products
) AS retained_value_validation;


-- ============================================================
-- 9. TEMPORAL ANOMALY PRESERVATION
-- ============================================================

SELECT
    metric,
    expected_value,
    actual_value,
    CASE
        WHEN expected_value = actual_value THEN 'PASS'
        ELSE 'FAIL'
    END AS status
FROM (
    SELECT
        'carrier_before_purchase' AS metric,
        166 AS expected_value,
        SUM(
            order_delivered_carrier_date
            < order_purchase_timestamp
        ) AS actual_value
    FROM orders

    UNION ALL

    SELECT
        'customer_delivery_before_carrier',
        23,
        SUM(
            order_delivered_customer_date
            < order_delivered_carrier_date
        )
    FROM orders

    UNION ALL

    SELECT
        'review_creation_before_purchase_date',
        64,
        (
            SELECT COUNT(*)
            FROM reviews AS r
            INNER JOIN orders AS o
                ON r.order_id = o.order_id
            WHERE DATE(r.review_creation_date)
                < DATE(o.order_purchase_timestamp)
        )

    UNION ALL

    SELECT
        'shipping_limit_in_2019_or_later',
        4,
        SUM(shipping_limit_date >= '2019-01-01')
    FROM order_items
) AS temporal_validation;


-- ============================================================
-- 10. CATEGORY TRANSLATION COVERAGE
-- ============================================================

SELECT
    metric,
    expected_value,
    actual_value,
    CASE
        WHEN expected_value = actual_value THEN 'PASS'
        ELSE 'FAIL'
    END AS status
FROM (
    SELECT
        'distinct_product_categories' AS metric,
        73 AS expected_value,
        COUNT(DISTINCT product_category_name) AS actual_value
    FROM products
    WHERE product_category_name IS NOT NULL

    UNION ALL

    SELECT
        'translation_lookup_categories',
        71,
        COUNT(*)
    FROM category_translation

    UNION ALL

    SELECT
        'untranslated_categories',
        2,
        (
            SELECT COUNT(*)
            FROM (
                SELECT DISTINCT
                    p.product_category_name
                FROM products AS p
                LEFT JOIN category_translation AS ct
                    ON p.product_category_name
                     = ct.product_category_name
                WHERE p.product_category_name IS NOT NULL
                  AND ct.product_category_name IS NULL
            ) AS untranslated
        )

    UNION ALL

    SELECT
        'products_in_untranslated_categories',
        13,
        (
            SELECT COUNT(*)
            FROM products AS p
            LEFT JOIN category_translation AS ct
                ON p.product_category_name
                 = ct.product_category_name
            WHERE p.product_category_name IS NOT NULL
              AND ct.product_category_name IS NULL
        )
) AS category_validation;


-- Show the known untranslated categories.

SELECT DISTINCT
    p.product_category_name
FROM products AS p
LEFT JOIN category_translation AS ct
    ON p.product_category_name = ct.product_category_name
WHERE p.product_category_name IS NOT NULL
  AND ct.product_category_name IS NULL
ORDER BY p.product_category_name;


-- ============================================================
-- 11. GEOLOCATION LOAD VALIDATION
-- ============================================================

SELECT
    metric,
    expected_value,
    actual_value,
    CASE
        WHEN expected_value = actual_value THEN 'PASS'
        ELSE 'FAIL'
    END AS status
FROM (
    SELECT
        'geolocation_rows' AS metric,
        738332 AS expected_value,
        COUNT(*) AS actual_value
    FROM geolocation

    UNION ALL

    SELECT
        'unique_geolocation_ids',
        738332,
        COUNT(DISTINCT geolocation_id)
    FROM geolocation

    UNION ALL

    SELECT
        'distinct_geolocation_zip_prefixes',
        19015,
        COUNT(DISTINCT geolocation_zip_code_prefix)
    FROM geolocation

    UNION ALL

    SELECT
        'maximum_rows_per_zip_prefix',
        779,
        (
            SELECT MAX(zip_rows)
            FROM (
                SELECT
                    geolocation_zip_code_prefix,
                    COUNT(*) AS zip_rows
                FROM geolocation
                GROUP BY geolocation_zip_code_prefix
            ) AS zip_counts
        )

    UNION ALL

    SELECT
        'exact_duplicate_geolocation_rows',
        0,
        COUNT(*) - COUNT(
            DISTINCT
            geolocation_zip_code_prefix,
            geolocation_lat,
            geolocation_lng,
            geolocation_city,
            geolocation_state
        )
    FROM geolocation
) AS geolocation_validation;


-- ============================================================
-- FINAL VALIDATION NOTE
-- ============================================================

SELECT
    'Review each validation result above. Phase 05 passes when all status values are PASS and the untranslated-category result contains only the two documented categories.'
        AS validation_note;
