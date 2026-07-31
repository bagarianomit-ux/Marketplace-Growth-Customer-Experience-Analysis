# Entity Relationships

## Overview

The Olist dataset consists of nine relational tables representing different aspects of a multi-vendor e-commerce marketplace.

Each table captures a specific business entity, such as customers, orders, products, sellers, payments, or reviews. Together, these entities form a relational database that supports analysis across key stages of the customer purchase lifecycle

Understanding these relationships is essential for accurate SQL analysis, database design, and dashboard development.


# Relationship Overview

The project uses the following core relationships.

| Parent Table | Child Table | Relationship | Type |
|--------------|-------------|--------------|------|
| customers | orders | customer_id | One-to-Many |
| orders | order_items | order_id | One-to-Many |
| products | order_items | product_id | One-to-Many |
| sellers | order_items | seller_id | One-to-Many |
| orders | payments | order_id | One-to-Many |
| orders | reviews | order_id | One-to-Many |
| category_translation | products | product_category_name | One-to-Many (Logical) |
| geolocation | customers | customer_zip_code_prefix | One-to-Many (Logical) |
| geolocation | sellers | seller_zip_code_prefix | One-to-Many (Logical) |



# Relationship Details

## Customers → Orders

**Key**

`customer_id`

**Relationship**

One customer record is associated with one order in this dataset.

The `orders` table references the `customers` table through `customer_id`.

Although each `customer_id` appears only once, the `customer_unique_id` allows multiple customer records to be linked to the same individual across different orders.


## Orders → Order Items

**Key**

`order_id`

**Relationship**

One order may contain one or more purchased items.

This represents the core transactional relationship within the dataset and provides the foundation for revenue and sales analysis.


## Products → Order Items

**Key**

`product_id`

**Relationship**

Each order item references a single product.

A product may appear in many different orders over time.


## Sellers → Order Items

**Key**

`seller_id`

**Relationship**

Each order item is fulfilled by one seller.

A seller may fulfil many order items across multiple customer orders.


## Orders → Payments

**Key**

`order_id`

**Relationship**

An order may contain one or more payment records.

An order may contain multiple payment records, for example when more than one payment method is used.

## Orders → Reviews

**Key**

`order_id`

**Relationship**

Customer reviews are associated with orders after delivery.

Most orders have a single review, although the dataset allows multiple review records for the same order.


## Category Translation → Products (Logical Relationship)

**Key**

`product_category_name`

**Relationship**

The `category_translation` table provides English translations for Portuguese product category names.

This relationship is used for reporting and dashboard development but is not enforced through a foreign key constraint in the source dataset.


## Geolocation → Customers (Logical Relationship)

**Key**

`customer_zip_code_prefix`

**Relationship**

Customer ZIP code prefixes can be matched with the geolocation table to support regional and geographic analysis.

Because multiple geographic coordinates may exist for the same ZIP code prefix, this relationship functions as a lookup rather than a traditional primary key–foreign key relationship.


## Geolocation → Sellers (Logical Relationship)

**Key**

`seller_zip_code_prefix`

**Relationship**

Seller ZIP code prefixes can also be linked to the geolocation table to support seller distribution and regional performance analysis.

Like the customer relationship, this is a logical lookup relationship rather than an enforced database constraint.


# Relationship Types Used

The project contains two types of relationships.

## Physical Relationships

Physical relationships are enforced through foreign key constraints in the project database.

These include:

- Customers → Orders
- Orders → Order Items
- Products → Order Items
- Sellers → Order Items
- Orders → Payments
- Orders → Reviews

These relationships ensure referential integrity during data loading and SQL analysis.


## Logical Relationships

Logical relationships are used for analysis but are not enforced through foreign key constraints.

These include:

- Category Translation → Products
- Geolocation → Customers
- Geolocation → Sellers

These relationships rely on shared business attributes rather than database constraints.


# Role in This Project

The validated entity relationships documented here provide the foundation for:

- Database design
- Foreign key implementation
- SQL joins
- Data validation
- Exploratory analysis
- Business analysis
- Dashboard development

Understanding these relationships ensures that business metrics are calculated using the correct level of granularity and that data from multiple tables is combined accurately.


# Summary

The Olist dataset follows a relational structure centred on customer orders.

Orders connect customers, products, sellers, payments, and reviews, forming the core transaction flow of the marketplace. Supporting lookup tables, such as geolocation and category translation, provide additional context for geographic and product-based analysis.

Together, these relationships enable comprehensive analysis of marketplace revenue, customer behaviour, seller performance, operational efficiency, and customer experience.
