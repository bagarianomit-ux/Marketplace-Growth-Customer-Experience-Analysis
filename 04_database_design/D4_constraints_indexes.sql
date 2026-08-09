-- ============================================================
-- Marketplace Growth & Customer Experience Analysis
-- File: D4_constraints_indexes.sql
-- Purpose: Add relational constraints, domain checks,
--          and justified secondary indexes
-- ============================================================

USE marketplace_growth_analysis;


-- ============================================================
-- 1. SECONDARY INDEXES
-- ============================================================

-- Supports repeat-customer analysis across customer records.

CREATE INDEX idx_customers_unique_id
    ON customers (customer_unique_id);


-- Supports customer-to-order access.
-- Also provides the required index for the orders foreign key.

CREATE INDEX idx_orders_customer_id
    ON orders (customer_id);


-- Supports time-based order analysis.

CREATE INDEX idx_orders_purchase_timestamp
    ON orders (order_purchase_timestamp);


-- order_items.order_id is already indexed because it is the
-- first column of the composite primary key.

-- Supports product-to-item joins.

CREATE INDEX idx_order_items_product_id
    ON order_items (product_id);


-- Supports seller-to-item joins.

CREATE INDEX idx_order_items_seller_id
    ON order_items (seller_id);


-- payments.order_id is already indexed because it is the
-- first column of the composite primary key.


-- reviews has primary key (review_id, order_id), so order_id
-- requires a separate index for order-to-review access.

CREATE INDEX idx_reviews_order_id
    ON reviews (order_id);


-- Supports product-category analysis.

CREATE INDEX idx_products_category
    ON products (product_category_name);


-- ------------------------------------------------------------
-- Logical relationship not enforced as a foreign key
-- ------------------------------------------------------------

-- products.product_category_name logically relates to
-- category_translation.product_category_name.
--
-- A foreign key is intentionally not created because the
-- translation lookup does not cover all product categories.
-- Products with untranslated categories must remain loadable.


-- Supports geographic lookup by ZIP prefix.

CREATE INDEX idx_geolocation_zip_prefix
    ON geolocation (geolocation_zip_code_prefix);


-- ============================================================
-- 2. FOREIGN KEY CONSTRAINTS
-- ============================================================

-- Orders → Customers

ALTER TABLE orders
ADD CONSTRAINT fk_orders_customer
    FOREIGN KEY (customer_id)
    REFERENCES customers (customer_id);


-- Order Items → Orders

ALTER TABLE order_items
ADD CONSTRAINT fk_order_items_order
    FOREIGN KEY (order_id)
    REFERENCES orders (order_id);


-- Order Items → Products

ALTER TABLE order_items
ADD CONSTRAINT fk_order_items_product
    FOREIGN KEY (product_id)
    REFERENCES products (product_id);


-- Order Items → Sellers

ALTER TABLE order_items
ADD CONSTRAINT fk_order_items_seller
    FOREIGN KEY (seller_id)
    REFERENCES sellers (seller_id);


-- Payments → Orders

ALTER TABLE payments
ADD CONSTRAINT fk_payments_order
    FOREIGN KEY (order_id)
    REFERENCES orders (order_id);


-- Reviews → Orders

ALTER TABLE reviews
ADD CONSTRAINT fk_reviews_order
    FOREIGN KEY (order_id)
    REFERENCES orders (order_id);


-- ============================================================
-- 3. DOMAIN CHECK CONSTRAINTS
-- ============================================================

-- ------------------------------------------------------------
-- Order Items
-- ------------------------------------------------------------

ALTER TABLE order_items
ADD CONSTRAINT chk_order_items_item_id
    CHECK (order_item_id >= 1),
ADD CONSTRAINT chk_order_items_price
    CHECK (price > 0),
ADD CONSTRAINT chk_order_items_freight
    CHECK (freight_value >= 0);


-- ------------------------------------------------------------
-- Payments
-- ------------------------------------------------------------

ALTER TABLE payments
ADD CONSTRAINT chk_payments_sequence
    CHECK (payment_sequential >= 1),
ADD CONSTRAINT chk_payments_value
    CHECK (payment_value >= 0);


-- payment_installments is TINYINT UNSIGNED, so negative
-- values are already prevented by the column data type.


-- ------------------------------------------------------------
-- Reviews
-- ------------------------------------------------------------

ALTER TABLE reviews
ADD CONSTRAINT chk_reviews_score
    CHECK (review_score BETWEEN 1 AND 5);


-- ------------------------------------------------------------
-- Products
-- ------------------------------------------------------------

-- Product count and measurement columns use UNSIGNED integer
-- types, so negative values are already prevented by their
-- column definitions. Nullable fields remain allowed to be NULL.


-- ------------------------------------------------------------
-- Geolocation
-- ------------------------------------------------------------

ALTER TABLE geolocation
ADD CONSTRAINT chk_geolocation_latitude
    CHECK (
        geolocation_lat BETWEEN -90 AND 90
    ),
ADD CONSTRAINT chk_geolocation_longitude
    CHECK (
        geolocation_lng BETWEEN -180 AND 180
    );


-- ============================================================
-- 4. VERIFY FOREIGN KEYS
-- ============================================================

SELECT
    table_name,
    constraint_name,
    column_name,
    referenced_table_name,
    referenced_column_name
FROM information_schema.key_column_usage
WHERE table_schema = DATABASE()
  AND referenced_table_name IS NOT NULL
ORDER BY
    table_name,
    constraint_name,
    ordinal_position;


-- ============================================================
-- 5. VERIFY INDEXES
-- ============================================================

SELECT
    table_name,
    index_name,
    column_name,
    seq_in_index,
    non_unique
FROM information_schema.statistics
WHERE table_schema = DATABASE()
ORDER BY
    table_name,
    index_name,
    seq_in_index;


-- ============================================================
-- 6. VERIFY CHECK CONSTRAINTS
-- ============================================================

SELECT
    tc.table_name,
    tc.constraint_name,
    cc.check_clause
FROM information_schema.table_constraints AS tc
JOIN information_schema.check_constraints AS cc
    ON tc.constraint_schema = cc.constraint_schema
   AND tc.constraint_name = cc.constraint_name
WHERE tc.constraint_schema = DATABASE()
  AND tc.constraint_type = 'CHECK'
ORDER BY
    tc.table_name,
    tc.constraint_name;