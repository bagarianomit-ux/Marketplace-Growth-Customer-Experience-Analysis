-- ============================================================
-- Marketplace Growth & Customer Experience Analysis
-- File: D3_table_creation.sql
-- Purpose: Create the target database tables
-- ============================================================

USE marketplace_growth_analysis;

-- ------------------------------------------------------------
-- Customers
-- Grain: one row per customer_id
-- ------------------------------------------------------------

CREATE TABLE customers (
    customer_id CHAR(32) NOT NULL,
    customer_unique_id CHAR(32) NOT NULL,
    customer_zip_code_prefix CHAR(5) NOT NULL,
    customer_city VARCHAR(50) NOT NULL,
    customer_state CHAR(2) NOT NULL,

    PRIMARY KEY (customer_id)
)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_ci;


-- ------------------------------------------------------------
-- Orders
-- Grain: one row per order_id
-- ------------------------------------------------------------

CREATE TABLE orders (
    order_id CHAR(32) NOT NULL,
    customer_id CHAR(32) NOT NULL,
    order_status VARCHAR(20) NOT NULL,
    order_purchase_timestamp DATETIME NOT NULL,
    order_approved_at DATETIME NULL,
    order_delivered_carrier_date DATETIME NULL,
    order_delivered_customer_date DATETIME NULL,
    order_estimated_delivery_date DATETIME NOT NULL,

    PRIMARY KEY (order_id)
)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_ci;


-- ------------------------------------------------------------
-- Products
-- Grain: one row per product_id
-- ------------------------------------------------------------

CREATE TABLE products (
    product_id CHAR(32) NOT NULL,
    product_category_name VARCHAR(50) NULL,
    product_name_length SMALLINT UNSIGNED NULL,
    product_description_length SMALLINT UNSIGNED NULL,
    product_photos_qty TINYINT UNSIGNED NULL,
    product_weight_g INT UNSIGNED NULL,
    product_length_cm SMALLINT UNSIGNED NULL,
    product_height_cm SMALLINT UNSIGNED NULL,
    product_width_cm SMALLINT UNSIGNED NULL,

    PRIMARY KEY (product_id)
)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_ci;


-- ------------------------------------------------------------
-- Sellers
-- Grain: one row per seller_id
-- ------------------------------------------------------------

CREATE TABLE sellers (
    seller_id CHAR(32) NOT NULL,
    seller_zip_code_prefix CHAR(5) NOT NULL,
    seller_city VARCHAR(50) NOT NULL,
    seller_state CHAR(2) NOT NULL,

    PRIMARY KEY (seller_id)
)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_ci;


-- ------------------------------------------------------------
-- Order Items
-- Grain: one product item within an order
-- ------------------------------------------------------------

CREATE TABLE order_items (
    order_id CHAR(32) NOT NULL,
    order_item_id TINYINT UNSIGNED NOT NULL,
    product_id CHAR(32) NOT NULL,
    seller_id CHAR(32) NOT NULL,
    shipping_limit_date DATETIME NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    freight_value DECIMAL(10, 2) NOT NULL,

    PRIMARY KEY (order_id, order_item_id)
)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_ci;


-- ------------------------------------------------------------
-- Payments
-- Grain: one payment record within an order
-- ------------------------------------------------------------

CREATE TABLE payments (
    order_id CHAR(32) NOT NULL,
    payment_sequential TINYINT UNSIGNED NOT NULL,
    payment_type VARCHAR(20) NOT NULL,
    payment_installments TINYINT UNSIGNED NOT NULL,
    payment_value DECIMAL(10, 2) NOT NULL,

    PRIMARY KEY (order_id, payment_sequential)
)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_ci;


-- ------------------------------------------------------------
-- Reviews
-- Grain: one review record associated with an order
-- ------------------------------------------------------------

CREATE TABLE reviews (
    review_id CHAR(32) NOT NULL,
    order_id CHAR(32) NOT NULL,
    review_score TINYINT UNSIGNED NOT NULL,
    review_comment_title VARCHAR(50) NULL,
    review_comment_message VARCHAR(255) NULL,
    review_creation_date DATETIME NOT NULL,
    review_answer_timestamp DATETIME NOT NULL,

    PRIMARY KEY (review_id, order_id)
)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_ci;


-- ------------------------------------------------------------
-- Geolocation
-- Grain: one distinct geographic coordinate observation
-- ------------------------------------------------------------

CREATE TABLE geolocation (
    geolocation_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    geolocation_zip_code_prefix CHAR(5) NOT NULL,
    geolocation_lat DOUBLE NOT NULL,
    geolocation_lng DOUBLE NOT NULL,
    geolocation_city VARCHAR(50) NOT NULL,
    geolocation_state CHAR(2) NOT NULL,

    PRIMARY KEY (geolocation_id)
)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_ci;


-- ------------------------------------------------------------
-- Category Translation
-- Grain: one row per Portuguese category in the lookup
-- ------------------------------------------------------------

CREATE TABLE category_translation (
    product_category_name VARCHAR(50) NOT NULL,
    product_category_name_english VARCHAR(50) NOT NULL,

    PRIMARY KEY (product_category_name)
)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_ci;


-- ------------------------------------------------------------
-- Verify table creation
-- ------------------------------------------------------------

SHOW TABLES;