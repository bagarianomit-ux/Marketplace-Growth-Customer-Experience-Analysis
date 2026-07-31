# Data Dictionary

## Overview

This document describes the structure and business purpose of each table used in the project.

For every table, it identifies:

- The business entity represented.
- The level of detail (grain).
- The primary key.
- Foreign key relationships.
- A brief description of each column.

The definitions provided here serve as the reference for the database design, SQL analysis, and dashboard development stages of the project.


# 1. customers

## Business Purpose

Stores information about marketplace customers and their geographic location.

Each record represents a customer associated with a single order. Multiple records may belong to the same individual through `customer_unique_id`.

### Table Grain

**1 row = 1 customer ID associated with 1 order**

### Primary Key

`customer_id`

### Referenced By

- orders.customer_id

| Column | Data Type | Description |
|---------|-----------|-------------|
| customer_id | VARCHAR | Unique identifier for each customer record |
| customer_unique_id | VARCHAR | Unique identifier representing the actual customer across multiple orders |
| customer_zip_code_prefix | INT | ZIP code prefix of the customer's location |
| customer_city | VARCHAR | Customer city |
| customer_state | VARCHAR | Customer state |

---

# 2. orders

## Business Purpose

Stores the complete lifecycle of each order, from purchase through delivery.

### Table Grain

**1 row = 1 order**

### Primary Key

`order_id`

### Foreign Keys

- customer_id → customers.customer_id

### Referenced By

- order_items.order_id
- payments.order_id
- reviews.order_id

| Column | Data Type | Description |
|---------|-----------|-------------|
| order_id | VARCHAR | Unique order identifier |
| customer_id | VARCHAR | Customer who placed the order |
| order_status | VARCHAR | Current order status |
| order_purchase_timestamp | DATETIME | Date and time the order was placed |
| order_approved_at | DATETIME | Payment approval timestamp |
| order_delivered_carrier_date | DATETIME | Date the order was handed to the carrier |
| order_delivered_customer_date | DATETIME | Date delivered to the customer |
| order_estimated_delivery_date | DATETIME | Estimated delivery date |

---

# 3. order_items

## Business Purpose

Stores individual products purchased within each order.

This is the most granular transactional table in the dataset.

### Table Grain

**1 row = 1 product item within an order**

### Primary Key

Composite Key

- order_id
- order_item_id

### Foreign Keys

- order_id → orders.order_id
- product_id → products.product_id
- seller_id → sellers.seller_id

| Column | Data Type | Description |
|---------|-----------|-------------|
| order_id | VARCHAR | Order identifier |
| order_item_id | INT | Item sequence within the order |
| product_id | VARCHAR | Purchased product |
| seller_id | VARCHAR | Seller fulfilling the item |
| shipping_limit_date | DATETIME | Shipping deadline |
| price | DECIMAL | Product selling price |
| freight_value | DECIMAL | Shipping cost |

---

# 4. products

## Business Purpose

Stores descriptive information about marketplace products.

### Table Grain

**1 row = 1 product**

### Primary Key

`product_id`

### Referenced By

- order_items.product_id
- category_translation.product_category_name (logical relationship)

| Column | Data Type | Description |
|---------|-----------|-------------|
| product_id | VARCHAR | Unique product identifier |
| product_category_name | VARCHAR | Product category (Portuguese) |
| product_name_length | INT | Number of characters in the product name |
| product_description_length | INT | Number of characters in the product description |
| product_photos_qty | INT | Number of product images |
| product_weight_g | INT | Product weight (grams) |
| product_length_cm | INT | Product length (cm) |
| product_height_cm | INT | Product height (cm) |
| product_width_cm | INT | Product width (cm) |

---

# 5. sellers

## Business Purpose

Stores information about marketplace sellers.

### Table Grain

**1 row = 1 seller**

### Primary Key

`seller_id`

### Referenced By

- order_items.seller_id

| Column | Data Type | Description |
|---------|-----------|-------------|
| seller_id | VARCHAR | Unique seller identifier |
| seller_zip_code_prefix | INT | Seller ZIP code prefix |
| seller_city | VARCHAR | Seller city |
| seller_state | VARCHAR | Seller state |

---

# 6. payments

## Business Purpose

Stores payment information associated with customer orders.

Multiple payment records may exist for a single order.

### Table Grain

**1 row = 1 payment transaction within an order**

### Candidate Key

- order_id
- payment_sequential

### Foreign Keys

- order_id → orders.order_id

| Column | Data Type | Description |
|---------|-----------|-------------|
| order_id | VARCHAR | Order identifier |
| payment_sequential | INT | Payment sequence number |
| payment_type | VARCHAR | Payment method |
| payment_installments | INT | Number of installments |
| payment_value | DECIMAL | Payment amount |

---

# 7. reviews

## Business Purpose

Stores customer ratings and review information after order delivery.

### Table Grain

**1 row = 1 review associated with an order**

### Candidate Key

- review_id
- order_id

### Foreign Keys

- order_id → orders.order_id

| Column | Data Type | Description |
|---------|-----------|-------------|
| review_id | VARCHAR | Review identifier |
| order_id | VARCHAR | Reviewed order |
| review_score | INT | Rating from 1 to 5 |
| review_comment_title | TEXT | Review title |
| review_comment_message | TEXT | Review description |
| review_creation_date | DATETIME | Review creation date |
| review_answer_timestamp | DATETIME | Seller response timestamp |

---

# 8. geolocation

## Business Purpose

Provides geographic reference information for Brazilian ZIP code prefixes.

This table is used as a lookup dataset rather than a transactional table.

### Table Grain

**1 row = 1 geolocation record**

### Primary Key

None (multiple records may exist for the same ZIP code prefix)

| Column | Data Type | Description |
|---------|-----------|-------------|
| geolocation_zip_code_prefix | INT | ZIP code prefix |
| geolocation_lat | DECIMAL | Latitude |
| geolocation_lng | DECIMAL | Longitude |
| geolocation_city | VARCHAR | City |
| geolocation_state | VARCHAR | State |

---

# 9. category_translation

## Business Purpose

Translates Portuguese product category names into English.

### Table Grain

**1 row = 1 product category**

### Primary Key

`product_category_name`

### Referenced By

- products.product_category_name

| Column | Data Type | Description |
|---------|-----------|-------------|
| product_category_name | VARCHAR | Original Portuguese category |
| product_category_name_english | VARCHAR | English translation |

---

## Summary

Together, these nine tables capture the core entities and relationships of the Olist marketplace.

The validated keys, table grain, and relationships documented here provide the foundation for the database design, SQL analysis, and dashboard development stages presented later in this project.
