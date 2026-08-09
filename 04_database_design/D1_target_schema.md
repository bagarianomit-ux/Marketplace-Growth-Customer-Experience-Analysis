# Target Database Schema

## Overview

This document defines the target relational schema for the cleaned Olist datasets before physical implementation in MySQL.

The design is based on the cleaned and validated data produced during `03_data_preparation`.

The schema aims to:

- Preserve the validated grain of each dataset.
- Use SQL data types appropriate for the observed source values.
- Preserve legitimate missing values.
- Enforce validated primary and foreign-key relationships.
- Avoid constraints that conflict with known source-data limitations.
- Support later SQL analysis without altering the underlying business meaning.

The database layer follows the cleaned data representation rather than the original raw CSV structure.


## Database Design Conventions

The following conventions will be used throughout the database:

| Design Area | Convention |
|---|---|
| Database system | MySQL 8.0.16 or later |
| Storage engine | InnoDB |
| Character set | `utf8mb4` |
| Naming convention | `snake_case` |
| Table naming | Plural table names matching the cleaned layer |
| Fixed-length Olist IDs | `CHAR(32)` |
| ZIP-code prefixes | `CHAR(5)` |
| Brazilian state codes | `CHAR(2)` |
| Timestamps | `DATETIME` |
| Monetary values | Fixed-point `DECIMAL` |
| Optional source values | Nullable |
| Unknown business values | Preserved rather than imputed |
| Analytical features | Not stored in source tables |

Fixed-length identifiers are stored as character values rather than numeric values because they are identifiers and are not used for mathematical operations.

ZIP-code prefixes are stored as `CHAR(5)` so that leading zeros are preserved.


# 1. Customers

### Grain

One row represents one customer record identified by `customer_id`.

`customer_unique_id` represents the underlying customer identity and may appear across multiple customer records.

### Target Schema

| Column | SQL Type | Nullable | Constraint | Design Basis |
|---|---|---:|---|---|
| `customer_id` | `CHAR(32)` | No | Primary Key | Fixed 32-character identifier and validated unique |
| `customer_unique_id` | `CHAR(32)` | No | — | Fixed 32-character business customer identifier; may repeat |
| `customer_zip_code_prefix` | `CHAR(5)` | No | — | Five-character geographic identifier |
| `customer_city` | `VARCHAR(50)` | No | — | Observed maximum length = 32 |
| `customer_state` | `CHAR(2)` | No | — | Two-character Brazilian state code |

### Index Consideration

`customer_unique_id` should be indexed because customer-level analysis across multiple orders will frequently use this field.

ZIP and state fields do not require standalone indexes solely because they are categorical fields. Their usefulness will depend on later query patterns.


# 2. Orders

### Grain

One row represents one order identified by `order_id`.

### Target Schema

| Column | SQL Type | Nullable | Constraint | Design Basis |
|---|---|---:|---|---|
| `order_id` | `CHAR(32)` | No | Primary Key | Fixed 32-character identifier and validated unique |
| `customer_id` | `CHAR(32)` | No | Foreign Key | Every order references a valid customer record |
| `order_status` | `VARCHAR(20)` | No | — | Observed maximum length = 11 |
| `order_purchase_timestamp` | `DATETIME` | No | — | Validated timestamp |
| `order_approved_at` | `DATETIME` | Yes | — | Missing values legitimately retained |
| `order_delivered_carrier_date` | `DATETIME` | Yes | — | Missing values legitimately retained |
| `order_delivered_customer_date` | `DATETIME` | Yes | — | Missing values legitimately retained |
| `order_estimated_delivery_date` | `DATETIME` | No | — | Complete validated timestamp |

### Foreign Key

`customer_id` references:

`customers(customer_id)`

The relationship passed referential-integrity validation with no orphan order records.

### Index Consideration

`order_purchase_timestamp` is a strong secondary-index candidate because later marketplace analysis will frequently use time periods.

`customer_id` must support the foreign-key relationship.

A standalone index on `order_status` is not required at this stage because the field has low cardinality.


# 3. Order Items

### Grain

One row represents one product item within an order.

### Target Schema

| Column | SQL Type | Nullable | Constraint | Design Basis |
|---|---|---:|---|---|
| `order_id` | `CHAR(32)` | No | Composite Primary Key, Foreign Key | Valid order reference |
| `order_item_id` | `TINYINT UNSIGNED` | No | Composite Primary Key | Observed range = 1–21 |
| `product_id` | `CHAR(32)` | No | Foreign Key | Valid product reference |
| `seller_id` | `CHAR(32)` | No | Foreign Key | Valid seller reference |
| `shipping_limit_date` | `DATETIME` | No | — | Complete parsed timestamp |
| `price` | `DECIMAL(10,2)` | No | — | Observed range = 0.85–6,735.00 |
| `freight_value` | `DECIMAL(10,2)` | No | — | Observed range = 0.00–409.68 |

### Primary Key

Composite primary key:

`(order_id, order_item_id)`

### Foreign Keys

`order_id` references:

`orders(order_id)`

`product_id` references:

`products(product_id)`

`seller_id` references:

`sellers(seller_id)`

All three relationships passed referential-integrity validation.

### Index Consideration

Secondary indexes should support:

- `product_id`
- `seller_id`

The composite primary key already begins with `order_id`, so a separate index on `order_id` is unnecessary.


# 4. Payments

### Grain

One row represents one payment record within an order.

### Target Schema

| Column | SQL Type | Nullable | Constraint | Design Basis |
|---|---|---:|---|---|
| `order_id` | `CHAR(32)` | No | Composite Primary Key, Foreign Key | Valid order reference |
| `payment_sequential` | `TINYINT UNSIGNED` | No | Composite Primary Key | Observed range = 1–29 |
| `payment_type` | `VARCHAR(20)` | No | — | Observed maximum length = 11 |
| `payment_installments` | `TINYINT UNSIGNED` | No | — | Observed range = 0–24 |
| `payment_value` | `DECIMAL(10,2)` | No | — | Observed range = 0.00–13,664.08 |

### Primary Key

Composite primary key:

`(order_id, payment_sequential)`

### Foreign Key

`order_id` references:

`orders(order_id)`

The relationship contains no orphan payment records.

### Design Note

Values such as `not_defined`, zero instalments, and zero payment values were retained during data preparation because there was insufficient evidence to replace them.

The database schema must therefore allow these validated source values.

A standalone index on `payment_type` is not required at this stage because the field has low cardinality.


# 5. Reviews

### Grain

One row represents one review record associated with an order.

### Target Schema

| Column | SQL Type | Nullable | Constraint | Design Basis |
|---|---|---:|---|---|
| `review_id` | `CHAR(32)` | No | Composite Primary Key | Identifier may repeat independently |
| `order_id` | `CHAR(32)` | No | Composite Primary Key, Foreign Key | Valid order reference |
| `review_score` | `TINYINT UNSIGNED` | No | — | Validated range = 1–5 |
| `review_comment_title` | `VARCHAR(50)` | Yes | — | Observed maximum length = 26 |
| `review_comment_message` | `VARCHAR(255)` | Yes | — | Observed maximum length = 208 |
| `review_creation_date` | `DATETIME` | No | — | Complete parsed timestamp |
| `review_answer_timestamp` | `DATETIME` | No | — | Complete parsed timestamp |

### Primary Key

Composite primary key:

`(review_id, order_id)`

`review_id` alone is not unique in the source data.

### Foreign Key

`order_id` references:

`orders(order_id)`

The relationship passed referential-integrity validation.

### Index Consideration

A separate index on `order_id` is required because the composite primary key begins with `review_id`.

A standalone index on `review_score` is not required at this stage because the field contains only five possible score values.


# 6. Products

### Grain

One row represents one product identified by `product_id`.

### Target Schema

| Column | SQL Type | Nullable | Constraint | Design Basis |
|---|---|---:|---|---|
| `product_id` | `CHAR(32)` | No | Primary Key | Fixed 32-character unique identifier |
| `product_category_name` | `VARCHAR(50)` | Yes | Logical lookup only | Observed maximum length = 46 |
| `product_name_length` | `SMALLINT UNSIGNED` | Yes | — | Observed range = 5–76 |
| `product_description_length` | `SMALLINT UNSIGNED` | Yes | — | Observed range = 4–3,992 |
| `product_photos_qty` | `TINYINT UNSIGNED` | Yes | — | Observed range = 1–20 |
| `product_weight_g` | `INT UNSIGNED` | Yes | — | Observed range = 0–40,425 |
| `product_length_cm` | `SMALLINT UNSIGNED` | Yes | — | Observed range = 7–105 |
| `product_height_cm` | `SMALLINT UNSIGNED` | Yes | — | Observed range = 2–105 |
| `product_width_cm` | `SMALLINT UNSIGNED` | Yes | — | Observed range = 6–118 |

### Column Naming

The database uses the corrected cleaned-layer names:

- `product_name_length`
- `product_description_length`

The original source misspellings are not carried into the physical database.

### Category Translation Relationship

`product_category_name` logically relates to:

`category_translation(product_category_name)`

However, this relationship will **not** be implemented as a foreign-key constraint.

The cleaned products contain 73 distinct non-null categories while the translation lookup contains 71 categories.

The untranslated categories are:

- `pc_gamer`
- `portateis_cozinha_e_preparadores_de_alimentos`

A strict foreign key would therefore reject valid source product records.

### Index Consideration

`product_category_name` should receive a secondary index because product-category analysis is expected later in the project.


# 7. Sellers

### Grain

One row represents one seller identified by `seller_id`.

### Target Schema

| Column | SQL Type | Nullable | Constraint | Design Basis |
|---|---|---:|---|---|
| `seller_id` | `CHAR(32)` | No | Primary Key | Fixed 32-character unique identifier |
| `seller_zip_code_prefix` | `CHAR(5)` | No | — | Five-character geographic identifier |
| `seller_city` | `VARCHAR(50)` | No | — | Observed maximum length = 40 |
| `seller_state` | `CHAR(2)` | No | — | Two-character Brazilian state code |

### Index Consideration

No standalone state index is required at this stage because state has low cardinality.

Seller access through order items will use `seller_id`.


# 8. Geolocation

### Grain

One row represents one distinct geographic coordinate observation retained after exact duplicate removal.

The cleaned geolocation table contains:

- 738,332 rows
- 19,015 distinct ZIP prefixes
- As many as 779 rows for one ZIP prefix
- No remaining exact duplicate rows

Therefore, `geolocation_zip_code_prefix` cannot serve as a primary key.

### Target Schema

| Column | SQL Type | Nullable | Constraint | Design Basis |
|---|---|---:|---|---|
| `geolocation_id` | `BIGINT UNSIGNED` | No | Primary Key, Auto Increment | Database-generated surrogate identifier |
| `geolocation_zip_code_prefix` | `CHAR(5)` | No | — | ZIP prefix is non-unique |
| `geolocation_lat` | `DOUBLE` | No | — | Geographic coordinate with fractional precision |
| `geolocation_lng` | `DOUBLE` | No | — | Geographic coordinate with fractional precision |
| `geolocation_city` | `VARCHAR(50)` | No | — | Observed maximum length = 38 |
| `geolocation_state` | `CHAR(2)` | No | — | Two-character state code |

### Surrogate Key Decision

The raw source does not contain a suitable natural primary key.

A database-generated `geolocation_id` is introduced only in the physical database layer.

It does not change the grain or business meaning of the source records.

A large composite primary key containing ZIP, coordinates, city, and state is avoided because it would produce a wide and inefficient clustered key.

### Geographic Relationships

Customer and seller ZIP prefixes may be compared with geolocation ZIP prefixes during analysis.

These relationships will **not** be implemented as foreign keys because:

1. ZIP prefixes are not unique in geolocation.
2. Geolocation coverage is incomplete for some customer and seller ZIP prefixes.

### Index Consideration

`geolocation_zip_code_prefix` should be indexed because geographic lookups will commonly begin with ZIP prefix.


# 9. Category Translation

### Grain

One row represents one English translation for a Portuguese product-category value contained in the lookup table.

### Target Schema

| Column | SQL Type | Nullable | Constraint | Design Basis |
|---|---|---:|---|---|
| `product_category_name` | `VARCHAR(50)` | No | Primary Key | Validated complete and unique lookup key |
| `product_category_name_english` | `VARCHAR(50)` | No | — | Observed maximum length = 39 |

### Relationship Note

Products may be left-joined to this lookup table using `product_category_name`.

Because lookup coverage is incomplete, the database will not enforce a foreign key from products to this table.


# 10. Physical Relationships

The following relationships will be enforced with foreign keys:

| Child Table | Child Column | Parent Table | Parent Column | Relationship |
|---|---|---|---|---|
| `orders` | `customer_id` | `customers` | `customer_id` | Customer record → orders |
| `order_items` | `order_id` | `orders` | `order_id` | Order → items |
| `order_items` | `product_id` | `products` | `product_id` | Product → items |
| `order_items` | `seller_id` | `sellers` | `seller_id` | Seller → items |
| `payments` | `order_id` | `orders` | `order_id` | Order → payments |
| `reviews` | `order_id` | `orders` | `order_id` | Order → reviews |

These relationships passed cleaned-data referential-integrity validation with zero child-side orphan records.


# 11. Logical Relationships Not Enforced as Foreign Keys

The following relationships are useful analytically but are deliberately not implemented as database foreign keys.

| Source | Target | Reason |
|---|---|---|
| `products.product_category_name` | `category_translation.product_category_name` | Translation coverage is incomplete |
| `customers.customer_zip_code_prefix` | `geolocation.geolocation_zip_code_prefix` | Geolocation ZIP values are non-unique and coverage is incomplete |
| `sellers.seller_zip_code_prefix` | `geolocation.geolocation_zip_code_prefix` | Geolocation ZIP values are non-unique and coverage is incomplete |


# 12. Initial Secondary Index Strategy

Secondary indexes will be limited to columns with clear relational or analytical value.

Planned secondary indexes are:

| Table | Column | Reason |
|---|---|---|
| `customers` | `customer_unique_id` | Repeat-customer analysis |
| `orders` | `customer_id` | Foreign-key and customer-order access |
| `orders` | `order_purchase_timestamp` | Time-based analysis |
| `order_items` | `product_id` | Product-item joins |
| `order_items` | `seller_id` | Seller-item joins |
| `reviews` | `order_id` | Order-review joins |
| `products` | `product_category_name` | Category analysis |
| `geolocation` | `geolocation_zip_code_prefix` | Geographic lookup |

Indexes already provided by primary-key structures will not be duplicated unnecessarily.

Low-cardinality columns such as:

- `order_status`
- `payment_type`
- `review_score`
- state codes

will not receive standalone indexes at this stage without evidence from later query workloads that such indexes provide value.


# 13. Domain Constraints

The physical schema may enforce business rules already supported by the validated cleaned data.

Planned constraints include:

| Column | Rule |
|---|---|
| `order_items.order_item_id` | Greater than or equal to 1 |
| `order_items.price` | Greater than 0 |
| `order_items.freight_value` | Greater than or equal to 0 |
| `payments.payment_sequential` | Greater than or equal to 1 |
| `payments.payment_installments` | Greater than or equal to 0 |
| `payments.payment_value` | Greater than or equal to 0 |
| `reviews.review_score` | Between 1 and 5 |
| `products` numeric count and measurement fields | Non-negative when present |
| `geolocation.geolocation_lat` | Between -90 and 90 |
| `geolocation.geolocation_lng` | Between -180 and 180 |

The database will not enforce temporal ordering constraints because known source-data anomalies were deliberately retained and cannot be corrected reliably.


# 14. Join-Grain Considerations

The physical database preserves the original business grains.

In particular:

- One order may contain multiple order items.
- One order may contain multiple payment records.
- One order may contain multiple review records.
- One order may contain items from multiple sellers.

Therefore, directly joining multiple one-to-many order tables can multiply rows.

For example:

`orders → order_items → payments → reviews`

must not be treated as an order-grain dataset without first controlling the grain of each child table.

Later analytical queries must explicitly define the required output grain and aggregate one-to-many tables where necessary before combining measures.


# 15. Database Layer Changes from the Cleaned Layer

The database largely preserves the cleaned schema.

One additional field is introduced:

`geolocation.geolocation_id`

This is a database-generated surrogate primary key required for efficient physical identification of geolocation records.

No business values are changed by this addition.

Other important cleaned-layer decisions preserved in the database include:

- Corrected product column names.
- Five-character ZIP-prefix representation.
- Nullable product metadata.
- Nullable order lifecycle timestamps.
- Preserved untranslated product categories.
- Preserved unusual payment records.
- Preserved temporal anomalies.


# Final Design Decision

The target relational schema preserves all validated source entities while enforcing only relationships and domain rules supported by the cleaned data.

Strict constraints are deliberately avoided where the source contains known limitations that cannot be corrected reliably.

This target schema will be implemented in:

- `D2_database_setup.sql`
- `D3_table_creation.sql`
- `D4_constraints_indexes.sql`

The implemented schema will be verified before any data is loaded.
