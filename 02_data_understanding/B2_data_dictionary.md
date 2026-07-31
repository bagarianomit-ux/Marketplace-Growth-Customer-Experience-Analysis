# Data Dictionary

## Overview

This document describes the structure and business purpose of each table used in the project.

For every table, it identifies:

- The business entity represented.
- The level of detail (table grain).
- Primary or candidate keys.
- Foreign key relationships.
- Column definitions.

The table grain, key definitions, and relationships documented below were validated during the Data Audit & Profiling stage before being implemented in the project database.

These definitions serve as the reference for the database design, data loading, SQL analysis, and dashboard development stages of the project.


# 1. customers

## Business Purpose

Stores information about marketplace customers and their geographic location.

Each record represents a customer identifier used for a single order within the dataset. The `customer_unique_id` identifies the same customer across multiple orders, allowing repeat purchase behaviour to be analysed.

### Table Grain

**1 row = 1 customer record (`customer_id`)**

### Primary Key

`customer_id`

### Referenced By

- orders.customer_id

| Column | Data Type | Description |
|---------|-----------|-------------|
| customer_id | VARCHAR(32) | Unique identifier for each customer record |
| customer_unique_id | VARCHAR(32) | Unique identifier representing the same customer across multiple orders |
| customer_zip_code_prefix | INT | ZIP code prefix of the customer's location |
| customer_city | VARCHAR(100) | Customer city |
| customer_state | VARCHAR(2) | Customer state |


# 2. orders

## Business Purpose

Stores the complete lifecycle of each customer order, from purchase through delivery.

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
| order_id | VARCHAR(32) | Unique order identifier |
| customer_id | VARCHAR(32) | Customer who placed the order |
| order_status | VARCHAR(20) | Current order status |
| order_purchase_timestamp | DATETIME | Date and time the order was placed |
| order_approved_at | DATETIME | Date and time the payment was approved |
| order_delivered_carrier_date | DATETIME | Date the order was handed to the carrier |
| order_delivered_customer_date | DATETIME | Date the order was delivered to the customer |
| order_estimated_delivery_date | DATETIME | Estimated delivery date |


# 3. order_items

## Business Purpose

Stores individual products purchased within each order.

This is the most granular transactional table in the dataset and forms the foundation for revenue and sales analysis.

### Table Grain

**1 row = 1 product item within an order**

### Composite Primary Key

- order_id
- order_item_id

### Foreign Keys

- order_id → orders.order_id
- product_id → products.product_id
- seller_id → sellers.seller_id

| Column | Data Type | Description |
|---------|-----------|-------------|
| order_id | VARCHAR(32) | Order identifier |
| order_item_id | INT | Item sequence within the order |
| product_id | VARCHAR(32) | Purchased product |
| seller_id | VARCHAR(32) | Seller fulfilling the item |
| shipping_limit_date | DATETIME | Shipping deadline for the seller |
| price | DECIMAL(10,2) | Product selling price |
| freight_value | DECIMAL(10,2) | Shipping cost charged for the item |


# 4. products

## Business Purpose

Stores descriptive information about marketplace products.

### Table Grain

**1 row = 1 product**

### Primary Key

`product_id`

### Logical Lookup Relationship

- product_category_name → category_translation.product_category_name

### Referenced By

- order_items.product_id

| Column | Data Type | Description |
|---------|-----------|-------------|
| product_id | VARCHAR(32) | Unique product identifier |
| product_category_name | VARCHAR(100) | Product category (Portuguese) |
| product_name_length | INT | Number of characters in the product name |
| product_description_length | INT | Number of characters in the product description |
| product_photos_qty | INT | Number of product images |
| product_weight_g | INT | Product weight (grams) |
| product_length_cm | INT | Product length (cm) |
| product_height_cm | INT | Product height (cm) |
| product_width_cm | INT | Product width (cm) |


# 5. sellers

## Business Purpose

Stores information about marketplace sellers and their geographic location.

### Table Grain

**1 row = 1 seller**

### Primary Key

`seller_id`

### Referenced By

- order_items.seller_id

| Column | Data Type | Description |
|---------|-----------|-------------|
| seller_id | VARCHAR(32) | Unique seller identifier |
| seller_zip_code_prefix | INT | Seller ZIP code prefix |
| seller_city | VARCHAR(100) | Seller city |
| seller_state | VARCHAR(2) | Seller state |


# 6. payments

## Business Purpose

Stores payment information associated with customer orders.

An order may contain multiple payment records when more than one payment method or installment sequence is used.

### Table Grain

**1 row = 1 payment transaction within an order**

### Composite Primary Key

- order_id
- payment_sequential

> **Note:** The original dataset does not explicitly define a primary key for this table. During data validation, the combination of `order_id` and `payment_sequential` was confirmed to uniquely identify each payment record and was implemented as the composite primary key in the project database.

### Foreign Keys

- order_id → orders.order_id

| Column | Data Type | Description |
|---------|-----------|-------------|
| order_id | VARCHAR(32) | Order identifier |
| payment_sequential | INT | Payment sequence number within the order |
| payment_type | VARCHAR(20) | Payment method |
| payment_installments | INT | Number of payment installments |
| payment_value | DECIMAL(10,2) | Payment amount |


# 7. reviews

## Business Purpose

Stores customer ratings and review information submitted after order delivery.

### Table Grain

**1 row = 1 customer review**

### Composite Primary Key

- review_id
- order_id

> **Note:** The original dataset does not explicitly define a primary key for this table. During data validation, the combination of `review_id` and `order_id` was confirmed to uniquely identify each review record and was implemented as the composite primary key in the project database.

### Foreign Keys

- order_id → orders.order_id

| Column | Data Type | Description |
|---------|-----------|-------------|
| review_id | VARCHAR(32) | Review identifier |
| order_id | VARCHAR(32) | Order associated with the review |
| review_score | INT | Customer rating (1–5) |
| review_comment_title | TEXT | Review title |
| review_comment_message | TEXT | Review comment |
| review_creation_date | DATETIME | Date the review was created |
| review_answer_timestamp | DATETIME | Timestamp when the review received a response |


# 8. geolocation

## Business Purpose

Provides geographic reference information for Brazilian ZIP code prefixes.

This table serves as a lookup dataset supporting geographic analysis rather than representing business transactions.

### Table Grain

**1 row = 1 geolocation record**

### Primary Key

None

> **Note:** Multiple records may exist for the same ZIP code prefix because a postal area can contain multiple geographic coordinates. Therefore, no unique primary key exists for this table.

| Column | Data Type | Description |
|---------|-----------|-------------|
| geolocation_zip_code_prefix | INT | ZIP code prefix |
| geolocation_lat | DECIMAL(10,6) | Latitude |
| geolocation_lng | DECIMAL(10,6) | Longitude |
| geolocation_city | VARCHAR(100) | City |
| geolocation_state | VARCHAR(2) | State |


# 9. category_translation

## Business Purpose

Provides English translations for Portuguese product category names.

This lookup table standardises product categories for reporting and dashboard development.

### Table Grain

**1 row = 1 product category translation**

### Primary Key

`product_category_name`

### Referenced By

- products.product_category_name (logical relationship)

| Column | Data Type | Description |
|---------|-----------|-------------|
| product_category_name | VARCHAR(100) | Original Portuguese product category |
| product_category_name_english | VARCHAR(100) | English translation of the product category |


## Summary

Together, these nine tables capture the core entities and relationships of the Olist marketplace.

The validated table grain, key definitions, relationships, and column structures documented here establish a common reference for the database design, data loading, SQL analysis, dashboard development, and business recommendations presented throughout the remainder of the project.
