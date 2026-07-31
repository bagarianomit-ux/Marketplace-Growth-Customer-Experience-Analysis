# Grain Definition

## Overview

Table grain defines the level of detail represented by each row in a table. Clearly defining the grain is essential for accurate SQL analysis, database design, data validation, and dashboard development.

Understanding table grain helps ensure that:

- Business metrics are calculated correctly.
- Tables are joined at the appropriate level of detail.
- Duplicate counting is avoided.
- Analytical queries produce reliable results.

Each table in the Olist dataset has a specific grain based on the business entity it represents.


# Table Grain Summary

| Table | Grain |
|--------|-------|
| customers | 1 row = 1 customer record (`customer_id`) |
| orders | 1 row = 1 order |
| order_items | 1 row = 1 product item within an order |
| products | 1 row = 1 product |
| sellers | 1 row = 1 seller |
| payments | 1 row = 1 payment transaction within an order |
| reviews | 1 row = 1 review record |
| geolocation | 1 row = 1 geolocation record |
| category_translation | 1 row = 1 product category translation |


# Grain Details

## customers

Each row represents a single customer record identified by `customer_id`.

Although the same individual may place multiple orders, each order receives a different `customer_id`. The `customer_unique_id` links multiple customer records belonging to the same individual.


## orders

Each row represents one marketplace order identified by `order_id`.

The order stores lifecycle information, including purchase, approval, shipment, delivery, and estimated delivery dates.


## order_items

Each row represents one product item purchased within an order.

This is the most granular transactional table in the dataset.

An order containing multiple products will generate multiple rows in this table, one for each purchased item.


## products

Each row represents one unique product identified by `product_id`.

The table contains descriptive product attributes and physical characteristics.


## sellers

Each row represents one marketplace seller.

Seller information is referenced whenever a seller fulfils an order item.


## payments

Each row represents one payment transaction associated with an order.

Some orders contain multiple payment transaction because payment can be split across multiple payment sequences.

## reviews

Each row represents one customer review record.

Although most orders have a single review, the dataset allows multiple review records to reference the same order.


## geolocation

Each row represents one geographic coordinate record associated with a ZIP code prefix.

Multiple records may exist for the same ZIP code prefix because different latitude and longitude values are present in the source dataset.


## category_translation

Each row represents one Portuguese product category mapped to its English translation.

This table functions as a lookup table during reporting and dashboard development.


# Why Grain Matters

Correctly defining table grain helps prevent common analytical errors, including:

- Double counting revenue or orders.
- Incorrect aggregation after joins.
- Inflated customer or seller counts.
- Misinterpreting transactional data.
- Building inaccurate dashboards.

Understanding the grain of each table ensures that business metrics are calculated at the correct level of detail throughout the project.


# Role in This Project

The grain definitions documented here are used throughout the project to support:

- Database design
- Data validation
- SQL joins
- Exploratory analysis
- Business analysis
- Dashboard development

Defining table grain before analysis helps maintain consistency across every stage of the analytics workflow.


# Summary

Each table in the Olist dataset represents a distinct level of business detail, ranging from customers and orders to individual order items and payments.

Clearly defining these levels of detail provides the foundation for accurate data modelling, reliable SQL analysis, and meaningful business insights throughout the project.
