# Power BI Semantic Model and Report Design

## 1. Objective

The purpose of the Power BI phase is to build a controlled semantic model and stakeholder-facing report that communicates the validated business priorities identified during the business-analysis phase.

Power BI will be used as a reporting and decision-support layer rather than as a replacement for the SQL analysis.

The model should:

- preserve the analytical grains established during SQL analysis;
- prevent duplication and fanout across orders, items, payments, reviews, and sellers;
- provide reusable business measures through DAX;
- support the decision questions defined in `G1_business_analysis.md`;
- allow stakeholders to move from executive-level performance to focused investigation;
- retain the metric definitions and limitations established earlier in the project.

The validated MySQL database remains the primary data source.

---

## 2. Modeling Approach

The Power BI semantic model will use a small fact-and-dimension structure rather than importing the nine operational tables directly and relying on Power BI to reconstruct analytical logic.

The reporting model will separate business processes according to their natural grain.

### Planned Fact Tables

| Fact Table | Grain | Primary Purpose |
|---|---|---|
| `bi_fact_orders` | 1 row = 1 order | Marketplace performance, customers, delivery, reviews, customer geography |
| `bi_fact_order_categories` | 1 row = 1 order × 1 category | Category performance, category growth, category review outcomes |
| `bi_fact_seller_orders` | 1 row = 1 order × 1 seller | Seller participation, seller merchandise activity, seller concentration |
| `bi_fact_payments` | 1 row = 1 payment record | Payment method and installment behaviour |

### Planned Dimensions

| Dimension | Grain | Primary Purpose |
|---|---|---|
| `DimDate` | 1 row = 1 calendar date | Time filtering and period comparison |
| `DimCustomerState` | 1 row = 1 state | Customer and delivery geography |
| `DimCategory` | 1 row = 1 analytical category | Category filtering and display labels |
| `DimSeller` | 1 row = 1 seller | Seller attributes and seller geography |

This structure separates analytical processes that operate at different grains and prevents measures from being calculated across incompatible levels of detail.

---

## 3. Core Modeling Principles

### 3.1 Grain Is Defined Before Relationships

Every fact table must have an explicit grain before it is loaded into Power BI.

Measures will only be calculated from tables whose grain supports the business metric being evaluated.

For example:

- order counts and delivery metrics belong at order grain;
- category merchandise metrics belong at order-category grain;
- seller merchandise metrics belong at order-seller grain;
- payment metrics belong at payment-record grain.

---

### 3.2 Fact Tables Will Not Be Directly Related

Fact tables may contain shared identifiers such as `order_id`, but they will not be joined directly to one another in the semantic model.

For example, the following direct relationships will not be created:

- `bi_fact_orders` → `bi_fact_payments`
- `bi_fact_orders` → `bi_fact_order_categories`
- `bi_fact_order_categories` → `bi_fact_seller_orders`

Shared dimensions will provide the required filtering context.

This protects the model from unintended duplication and ambiguous filter propagation.

---

### 3.3 Relationships Will Normally Be One-to-Many

The preferred relationship pattern is:

`Dimension (1) → Fact (*)`

Examples:

- `DimDate` → `bi_fact_orders`
- `DimCategory` → `bi_fact_order_categories`
- `DimSeller` → `bi_fact_seller_orders`

Relationships will normally use single-direction filtering from the dimension to the fact table.

Bidirectional filtering will not be introduced unless a specific reporting requirement cannot be solved safely without it.

---

### 3.4 Order Purchase Date Is the Primary Reporting Date

The primary reporting timeline will use the date derived from `order_purchase_timestamp`.

This provides a consistent timeline across:

- orders;
- category activity;
- seller activity;
- payments.

Customer delivery date and estimated delivery date will remain available as analytical attributes in the order fact table but will not initially be used as additional active relationships to `DimDate`.

---

### 3.5 Analytical Conventions Established in SQL Will Be Preserved

Power BI will not redefine analytical conventions that were already established and validated during SQL analysis.

Examples include:

- delivered orders as the primary completed-order population;
- `SUM(order_items.price)` as item sales value rather than marketplace revenue;
- latest `review_answer_timestamp` as the representative order review;
- one representative order review per distinct order-category combination for category review analysis;
- customer analysis based on `customer_unique_id`;
- state as the primary geographic reporting level;
- January 2017 through August 2018 as the primary continuous trend period;
- January–August 2017 versus January–August 2018 as the matched-period growth comparison.

---

## 4. Calculation Responsibility

Calculations will be divided between SQL and Power BI according to purpose.

### SQL Reporting Layer

SQL will handle:

- safe joins;
- grain control;
- child-table aggregation;
- representative review selection;
- delivery-duration calculations;
- late-delivery classification;
- order-category aggregation;
- order-seller aggregation;
- preparation of business-safe reporting fields.

### Power BI / DAX

DAX will handle:

- reusable KPIs;
- ratios and percentages;
- filter-context calculations;
- dynamic marketplace shares;
- period comparisons;
- report-level customer, category, seller, and delivery measures.

This separation keeps row-level analytical preparation in SQL while allowing Power BI to provide interactive business calculations.

---

## 5. Initial Semantic Model

The planned model is:

```text
                         DimDate
                            |
          -------------------------------------
          |                 |                 |
          v                 v                 v
   bi_fact_orders   bi_fact_order_categories   bi_fact_seller_orders
          |                 |                 |
      ---------             |                 |
      |       |             v                 v
      v       v        DimCategory         DimSeller
DimCustomer  DimCustomerState


                         DimDate
                            |
                            v
                     bi_fact_payments


## 6. Fact and Dimension Specifications

### 6.1 Primary Order Fact Design — `bi_fact_orders`

`bi_fact_orders` will be the primary fact table in the Power BI semantic model.

It will support the majority of marketplace, customer, delivery, geographic, and order-level customer-experience reporting.

### 6.1.1 Grain

The table grain is:

> **1 row = 1 recorded order**

The expected row count is therefore:

**99,441 rows**

`order_id` must remain unique.

The table will include all recorded order statuses rather than delivered orders only. This is necessary because the reporting layer must support metrics such as:

* recorded orders;
* completed orders;
* completion rate;
* order-status distribution;
* completed customer activity;
* delivery reliability.

Delivered-order measures will be implemented through explicit filtering rather than by removing non-delivered orders from the source view.

---

### 6.1.2 Source Tables

The view will use only the source tables required to construct a safe order-level record:

| Source Table  | Purpose                                                  |
| ------------- | -------------------------------------------------------- |
| `orders`      | Base order grain and order lifecycle fields              |
| `customers`   | `customer_unique_id` and order-associated customer state |
| `order_items` | Aggregated item count and item sales value               |
| `reviews`     | Representative order-level review                        |

The following tables will **not** be joined directly into this fact:

* `payments`
* `products`
* `sellers`
* `geolocation`
* `category_translation`

Those business processes either have a different grain or belong in separate fact/dimension tables.

This prevents order-level measures from being multiplied by unrelated child-table records.

---

### 6.1.3 Planned Columns

| Column                          | Purpose                                                          |
| ------------------------------- | ---------------------------------------------------------------- |
| `order_id`                      | Unique order key                                                 |
| `customer_unique_id`            | Underlying customer key                                          |
| `customer_state`                | State associated with the order's customer record                |
| `order_status`                  | Recorded order status                                            |
| `order_purchase_date`           | Date used for the primary `DimDate` relationship                 |
| `order_purchase_timestamp`      | Original purchase timestamp for traceability                     |
| `order_delivered_customer_date` | Actual customer-delivery timestamp                               |
| `order_estimated_delivery_date` | Estimated delivery timestamp                                     |
| `is_delivered`                  | Delivered-order indicator                                        |
| `has_items`                     | Indicates whether an order has recorded item rows                |
| `item_count`                    | Number of recorded order-item rows                               |
| `item_sales_value`              | Sum of `order_items.price` at order grain                        |
| `has_review`                    | Indicates whether an order has a retained review                 |
| `representative_review_score`   | Review score selected using the representative-review convention |
| `is_delivery_eligible`          | Indicates whether delivery reliability can be evaluated          |
| `delivery_days`                 | Purchase-to-customer-delivery duration                           |
| `delivery_variance_days`        | Actual delivery date minus estimated delivery date               |
| `is_late`                       | Indicates delivery after the estimated delivery date             |
| `late_days`                     | Positive delay duration for late orders                          |
| `delay_band`                    | Delivery-severity classification                                 |

The final SQL view should remain intentionally compact. Additional operational fields should only be added if a defined reporting requirement requires them.

---

## 6.1.4 Item Aggregation

`order_items` contains multiple rows per order and therefore cannot be joined directly to `orders` without aggregation.

Item activity will first be reduced to order grain.

Conceptually:

```sql
SELECT
    order_id,
    COUNT(*) AS item_count,
    SUM(price) AS item_sales_value
FROM order_items
GROUP BY order_id
```

The resulting order-level item aggregation will then be left joined to `orders`.

This preserves:

> **1 order = 1 row**

Orders without recorded item rows will remain in the view.

For these orders:

* `has_items = 0`
* `item_count = 0`
* `item_sales_value = 0`

The `has_items` field preserves the distinction between an order with no recorded item rows and an ordinary order with recorded merchandise activity.

This is important because the source data contains **775 orders without item records**.

---

## 6.1.5 Item Sales Value Definition

`item_sales_value` will be defined as:

```sql
SUM(order_items.price)
```

This represents:

> **Recorded merchandise / item sales value**

It must not be described as:

* marketplace revenue;
* profit;
* gross margin;
* seller revenue;
* commission.

The same terminology established during SQL analysis will be preserved throughout Power BI.

---

## 6.1.6 Representative Order Review

Some orders contain more than one review record.

The SQL analysis established the analytical convention:

> **Use the review with the latest `review_answer_timestamp` as the representative order review.**

The BI source view will apply this convention before reviews are joined to orders.

Conceptually:

```text
reviews
    ↓
rank reviews within each order
    ↓
latest answered review
    ↓
maximum 1 review per order
    ↓
join to orders
```

A `ROW_NUMBER()` window function will be used to rank reviews within each order.

The primary ordering field will be:

```text
review_answer_timestamp DESC
```

Secondary fields may be used only as deterministic tie-breakers if two reviews share the same answer timestamp. They will not carry additional business meaning.

Orders without a review will remain in the fact table with:

```text
has_review = 0
representative_review_score = NULL
```

The expected number of orders containing at least one retained review is:

**98,673**

---

## 6.1.7 Customer Identification

The operational Olist `customer_id` represents the customer record associated with an individual order.

Customer-level analysis instead uses:

```text
customer_unique_id
```

Therefore:

```text
orders.customer_id
        ↓
customers.customer_id
        ↓
customers.customer_unique_id
```

will be used to attach the underlying customer key to each order.

This allows Power BI to calculate customer-level measures such as:

* completed unique customers;
* observed repeat customers;
* customer order frequency;
* one-time versus repeat activity.

The expected number of distinct customers across all recorded orders is:

**96,096**

The expected number across delivered orders is:

**93,358**

---

## 6.1.8 Customer Geography

`customer_state` will be attached to the order fact through the customer record associated with that specific order.

It will **not** be permanently assigned to `DimCustomer`.

This preserves an important source-data characteristic:

> A small number of `customer_unique_id` values appear across more than one state.

Assigning one state permanently to those customers would require an unsupported primary-state rule.

The order fact therefore preserves the actual state associated with each order.

---

## 6.1.9 Delivered-Order Indicator

The view will contain:

```text
is_delivered
```

defined conceptually as:

```sql
CASE
    WHEN order_status = 'delivered' THEN 1
    ELSE 0
END
```

This allows the semantic model to retain all recorded orders while explicitly defining completed-order measures.

Expected result:

```text
Recorded orders      99,441
Delivered orders     96,478
```

---

## 6.1.10 Delivery Eligibility

Delivery reliability should only be evaluated where the required fields are available.

An order will be considered delivery-eligible when:

* `order_status = 'delivered'`;
* `order_delivered_customer_date IS NOT NULL`;
* `order_estimated_delivery_date IS NOT NULL`.

The expected eligible population is:

**96,470 orders**

This preserves the delivery-analysis population established in SQL.

---

## 6.1.11 Delivery Duration

For eligible delivered orders:

```text
delivery_days
```

will represent the elapsed duration between:

```text
order_purchase_timestamp
        ↓
order_delivered_customer_date
```

The calculation should preserve fractional days rather than rounding each order to an integer number of days.

Conceptually:

```text
delivery seconds / 86,400
```

Non-eligible orders will return `NULL`.

This allows Power BI to calculate measures such as:

* average delivery days;
* delivery-duration distribution;
* delivery performance by state.

---

## 6.1.12 Delivery Variance Against Estimate

The view will contain:

```text
delivery_variance_days
```

defined as:

```text
actual delivery timestamp
-
estimated delivery timestamp
```

Interpretation:

```text
< 0    delivered before estimate
= 0    delivered on estimated date
> 0    delivered after estimate
```

This signed field preserves more information than a simple late flag.

---

## 6.1.13 Late-Delivery Indicator

For delivery-eligible orders:

```text
is_late = 1
```

when:

```text
order_delivered_customer_date
>
order_estimated_delivery_date
```

Otherwise:

```text
is_late = 0
```

Orders outside the delivery-analysis population should remain `NULL` rather than being classified as on time.

This distinction prevents non-delivered or incomplete records from entering the late-delivery denominator.

Expected results:

```text
Eligible delivery orders     96,470
Late orders                   7,826
On-time or early orders      88,644
```

---

## 6.1.14 Late Days

`late_days` will represent positive delay duration only.

For example:

```text
Delivery variance = -5.2 days
late_days = 0

Delivery variance = +3.7 days
late_days = 3.7
```

For non-eligible orders, `late_days` will remain `NULL`.

This supports measures such as:

* average delay among late orders;
* delay-severity analysis.

---

## 6.1.15 Delay Band

The same delay-severity convention used during SQL analysis will be preserved:

```text
on_time_or_early
over_0_to_3_days_late
over_3_to_7_days_late
over_7_to_14_days_late
over_14_to_30_days_late
over_30_days_late
not_eligible
```

The classification will be based on `delivery_variance_days`.

Using the same bands allows the Power BI report to reproduce the validated relationship between delivery severity and customer-review outcomes without redefining the analytical population.

---

## 6.1.16 Fields Deliberately Excluded

The first version of `bi_fact_orders` will not include fields simply because they are available.

Examples intentionally excluded include:

* seller identifiers;
* product identifiers;
* raw payment fields;
* individual order-item identifiers;
* raw review comments;
* raw geolocation coordinates;
* order-level category lists;
* seller delivery attribution.

These fields either belong to a different analytical grain or are not required by the current reporting questions.

The reporting fact should remain understandable and business-focused.

---

## 6.1.17 Expected Validation Results

Before `bi_fact_orders` is loaded into Power BI, the SQL view must pass the following reconciliation checks:

| Validation Check                  | Expected Result |
| --------------------------------- | --------------: |
| View row count                    |          99,441 |
| Distinct `order_id`               |          99,441 |
| Delivered orders                  |          96,478 |
| Distinct recorded customers       |          96,096 |
| Distinct delivered customers      |          93,358 |
| Orders without item records       |             775 |
| Sum of recorded `item_count`      |         112,650 |
| Sum of delivered `item_count`     |         110,197 |
| Recorded item sales value         |   13,591,643.70 |
| Delivered item sales value        |   13,221,498.11 |
| Orders with representative review |          98,673 |
| Delivery-eligible orders          |          96,470 |
| Late orders                       |           7,826 |
| On-time or early eligible orders  |          88,644 |

Any mismatch must be investigated before the view enters Power BI.

---

## 6.1.18 Power BI Relationships

`bi_fact_orders` will initially participate in the following relationships:

```text
DimDate[Date]
    1
    ↓
    *
bi_fact_orders[order_purchase_date]
```

```text
DimCustomerState[state_code]
    1
    ↓
    *
bi_fact_orders[customer_state]
```

All relationships will use single-direction filtering from the dimension to the fact table unless a later validated reporting requirement demonstrates the need for a different configuration.

---

## 6.1.19 Reporting Responsibility

`bi_fact_orders` will provide the analytical foundation for:

### Marketplace Performance

* recorded orders;
* completed orders;
* completion rate;
* item sales value;
* items sold;
* average item sales value per completed order.

### Customer Behaviour

* unique customers;
* completed unique customers;
* order frequency;
* one-time and repeat purchasing;
* customer merchandise activity.

### Delivery Reliability

* average delivery duration;
* late-delivery rate;
* average late delay;
* delay severity;
* state-level delivery performance.

### Customer Experience

* representative review score;
* low-review rate;
* review outcomes by delivery status;
* review outcomes by delay severity.

This makes `bi_fact_orders` the central reporting fact in the Power BI model while preserving the analytical definitions established during SQL analysis.

### 6.2 Order-Category Fact — `bi_fact_order_categories`

`bi_fact_order_categories` will provide the reporting grain required for category-level commercial performance and category-associated customer-review analysis.

It will preserve category activity without exposing Power BI directly to individual order-item rows.

#### 6.2.1 Grain

The table grain is:

> **1 row = 1 order × 1 analytical category**

If an order contains several items belonging to the same category, those items will be aggregated into a single row.

For example:

```text
Order A
├── Health & Beauty item
├── Health & Beauty item
└── Sports & Leisure item
```

will become:

```text
Order A | Health & Beauty   | 2 items | category item sales value
Order A | Sports & Leisure  | 1 item  | category item sales value
```

This grain allows category merchandise activity and order-level review outcomes to be analyzed without duplicating a review once for every individual item.

---

#### 6.2.2 Source Tables

The view will use:

| Source Table           | Purpose                                |
| ---------------------- | -------------------------------------- |
| `order_items`          | Item-level merchandise activity        |
| `orders`               | Order status and purchase date         |
| `products`             | Product-to-category assignment         |
| `category_translation` | English category label where available |
| `reviews`              | Representative order-level review      |

The category translation table will be joined using a left join because translation coverage is incomplete.

No category translation will be fabricated where a source category does not have a corresponding English translation.

---

#### 6.2.3 Category Identification

Category reporting will preserve both the source category and the business-facing category label.

The analytical category label will follow the convention established during SQL analysis:

```sql
COALESCE(
    category_translation.product_category_name_english,
    products.product_category_name,
    'unknown'
)
```

This produces three possible situations:

```text
Translated source category
→ English display label

Untranslated source category
→ original Portuguese source value

Missing product category
→ unknown
```

The source category will also be retained separately.

This prevents different source categories from being grouped together solely because of display-label handling.

---

#### 6.2.4 Planned Columns

| Column                        | Purpose                                                                         |
| ----------------------------- | ------------------------------------------------------------------------------- |
| `order_id`                    | Order identifier                                                                |
| `order_purchase_date`         | Date used for the `DimDate` relationship                                        |
| `order_status`                | Recorded order status                                                           |
| `is_delivered`                | Delivered-order indicator                                                       |
| `source_category_name`        | Original product category value                                                 |
| `category_display_name`       | Translated, source, or `unknown` reporting label                                |
| `category_key`                | Stable analytical category key                                                  |
| `category_item_count`         | Number of item rows belonging to the category within the order                  |
| `category_item_sales_value`   | Sum of item prices belonging to the category within the order                   |
| `has_review`                  | Indicates whether the order has a representative review                         |
| `representative_review_score` | Representative order review associated once with the order-category combination |

The final view should remain limited to fields required for category reporting.

---

#### 6.2.5 Category Merchandise Aggregation

Individual order items will first be mapped to their product category and then aggregated to:

```text
order_id
×
analytical category
```

Conceptually:

```sql
SELECT
    order_id,
    category_key,
    COUNT(*) AS category_item_count,
    SUM(price) AS category_item_sales_value
FROM ...
GROUP BY
    order_id,
    category_key
```

This ensures that multiple items from the same category within one order do not create unnecessary category-level rows in Power BI.

---

#### 6.2.6 Missing Categories

Products with missing category information will not be removed from the reporting population.

They will be assigned:

```text
category_display_name = 'unknown'
```

This preserves the merchandise activity represented by those products.

The completed-order population previously identified:

```text
1,537 items
```

with missing category information, representing approximately:

```text
1.39% of completed items
```

and approximately:

```text
1.29% of completed item sales value
```

will therefore remain visible in the category reporting layer.

---

#### 6.2.7 Untranslated Categories

The known untranslated source categories:

```text
pc_gamer
portateis_cozinha_e_preparadores_de_alimentos
```

will retain their original source-category values as their display labels.

No artificial English translation will be introduced.

The untranslated population is commercially small but should remain analytically visible.

---

#### 6.2.8 Representative Review Treatment

Category-review analysis will preserve the convention established during SQL analysis:

> **One representative order review is associated once with each distinct category appearing in that order.**

For example, if an order contains:

```text
2 Health & Beauty items
3 Sports & Leisure items
```

and the representative order review score is:

```text
2
```

the category fact will contain:

```text
Health & Beauty   | review score = 2
Sports & Leisure  | review score = 2
```

The review will not be repeated once for every item.

This makes category review metrics interpretable as:

> **Review outcomes for orders containing the category**

They must not be described as:

* product ratings;
* direct category ratings;
* seller ratings;
* product-quality scores.

---

#### 6.2.9 Order Population

The view will retain category activity from all recorded orders that contain order-item records.

This is intentional.

Commercial category measures will normally filter to:

```text
order_status = 'delivered'
```

while category-associated review analysis may use the broader retained order population according to the analytical convention established in SQL.

The source view therefore preserves the underlying records rather than permanently restricting all reporting to delivered orders.

---

#### 6.2.10 Item Sales Value Definition

`category_item_sales_value` will be defined as:

```text
sum of order_items.price
```

for the items belonging to the order-category combination.

It represents:

> **Category merchandise / item sales value**

It does not represent:

* marketplace revenue;
* category profit;
* contribution margin;
* seller earnings.

---

#### 6.2.11 Category Dimension Relationship

`bi_fact_order_categories` will be related to:

```text
DimCategory
```

through:

```text
category_key
```

using:

```text
DimCategory[category_key]
        1
        ↓
        *
bi_fact_order_categories[category_key]
```

The category dimension will contain the display attributes used by report users.

Technical source fields may remain hidden from normal report consumers.

---

#### 6.2.12 Date Relationship

The primary date relationship will be:

```text
DimDate[Date]
        1
        ↓
        *
bi_fact_order_categories[order_purchase_date]
```

This keeps category reporting aligned with the same purchase-date timeline used elsewhere in the semantic model.

---

#### 6.2.13 Critical Validation Requirements

Before the view is loaded into Power BI, it must satisfy the following structural checks:

```text
Each order-category combination is unique
category_item_count sums back to order-item population
category_item_sales_value reconciles to order-item sales value
delivered category totals reconcile to F5
missing-category activity is retained
untranslated categories are retained
representative reviews appear no more than once per order-category
```

Known completed-order reconciliation targets include:

| Validation Check                                    | Expected Result |
| --------------------------------------------------- | --------------: |
| Completed category item count                       |         110,197 |
| Completed category item sales value                 |   13,221,498.11 |
| Completed products represented in category analysis |          32,216 |
| Completed items with missing category               |           1,537 |
| Completed untranslated-category items               |              22 |
| Represented source categories                       |              73 |
| Translated source categories                        |              71 |

The exact number of order-category rows will be established and validated when the SQL view is implemented in `H2_bi_source_views.sql`.

It will not be estimated in advance.

---

#### 6.2.14 Reporting Responsibility

`bi_fact_order_categories` will support:

### Category Scale

* category item sales value;
* category items sold;
* category completed orders;
* marketplace merchandise share.

### Category Growth

* matched-period item sales value;
* absolute growth contribution;
* percentage growth;
* marketplace-share movement.

### Category Portfolio Analysis

* large established categories;
* major growth contributors;
* share-gaining and share-losing categories;
* smaller high-growth categories.

### Customer Experience Context

* representative review score by category;
* low-review rate by category;
* review outcomes for orders containing each category.

This fact provides the category-specific reporting grain required by the Power BI model while preserving the conventions and limitations established during SQL analysis.

### 6.3 Seller-Order Fact — `bi_fact_seller_orders`

`bi_fact_seller_orders` will provide the reporting grain required for seller participation, seller merchandise activity, seller concentration, and seller-supply geography.

It will aggregate individual order-item rows before they enter the Power BI semantic model.

#### 6.3.1 Grain

The table grain is:

> **1 row = 1 order × 1 seller**

If a seller supplies several items within the same order, those item rows will be aggregated into a single seller-order record.

For example:

```text
Order A
├── Seller X — Item 1
├── Seller X — Item 2
└── Seller Y — Item 3
```

will become:

```text
Order A | Seller X | 2 items | seller item sales value
Order A | Seller Y | 1 item  | seller item sales value
```

This preserves seller merchandise activity without exposing Power BI directly to individual order-item rows.

---

#### 6.3.2 Source Tables

The view will use:

| Source Table  | Purpose                                   |
| ------------- | ----------------------------------------- |
| `order_items` | Seller-item activity and item sales value |
| `orders`      | Order status and purchase date            |

Seller descriptive attributes such as city and state will remain in `DimSeller` rather than being duplicated across every seller-order row.

The following tables will not be joined into this fact:

* `reviews`
* `payments`
* `customers`
* `geolocation`
* `category_translation`

`products` is also not required for the current seller-reporting questions.

---

#### 6.3.3 Planned Columns

| Column                    | Purpose                                                     |
| ------------------------- | ----------------------------------------------------------- |
| `order_id`                | Order identifier                                            |
| `seller_id`               | Seller identifier                                           |
| `order_purchase_date`     | Date used for the `DimDate` relationship                    |
| `order_status`            | Recorded order status                                       |
| `is_delivered`            | Delivered-order indicator                                   |
| `seller_item_count`       | Number of item rows supplied by the seller within the order |
| `seller_item_sales_value` | Sum of item prices supplied by the seller within the order  |

The fact will remain intentionally compact.

Seller location and other descriptive attributes will be supplied through `DimSeller`.

---

#### 6.3.4 Seller Merchandise Aggregation

Individual order-item rows will be aggregated to:

```text
order_id
×
seller_id
```

Conceptually:

```sql
SELECT
    order_id,
    seller_id,
    COUNT(*) AS seller_item_count,
    SUM(price) AS seller_item_sales_value
FROM order_items
GROUP BY
    order_id,
    seller_id
```

Order information will then be attached after the seller-item aggregation.

This ensures that multiple products supplied by the same seller within one order do not create unnecessary seller-order rows in Power BI.

---

#### 6.3.5 Seller Item Sales Value Definition

`seller_item_sales_value` will be defined as:

```text
SUM(order_items.price)
```

for the items supplied by the seller within the order.

It represents:

> **Merchandise / item sales value associated with that seller's items**

It must not be interpreted as:

* seller profit;
* seller net revenue;
* marketplace commission;
* contribution margin;
* seller earnings after fees.

The dataset does not contain the commercial information required for those measures.

---

#### 6.3.6 Order Population

The source fact will retain seller-item activity from all recorded orders containing order-item rows.

Commercial seller reporting will normally apply:

```text
order_status = 'delivered'
```

because the validated seller analysis used completed marketplace activity as its primary population.

Retaining all statuses in the source fact provides traceability and avoids permanently removing valid source records.

However, non-delivered order status should not automatically be interpreted as seller failure.

---

#### 6.3.7 Multi-Seller Orders

Most completed orders contain items from only one seller, but some contain multiple sellers.

The validated completed-order population contains:

```text
Single-seller orders     95,203
Multi-seller orders       1,275
Maximum sellers/order         5
```

A multi-seller order therefore produces more than one row in `bi_fact_seller_orders`.

For example:

```text
Order A | Seller X
Order A | Seller Y
```

Consequently:

> **Seller-order relationship counts are additive, but order counts across sellers are not.**

If the same order contains two sellers, counting seller-order rows produces two seller relationships but still represents only one marketplace order.

Power BI measures must preserve this distinction.

---

#### 6.3.8 No Seller Attribution of Order-Level Delivery Outcomes

Delivery timestamps exist at order level rather than seller-shipment level.

A multi-seller order can therefore have:

```text
one customer delivery timestamp
multiple sellers
```

The dataset does not identify which seller caused, avoided, or contributed to a delivery delay.

For this reason, `bi_fact_seller_orders` will not contain:

* delivery duration;
* late-delivery indicators;
* delivery-delay bands;
* estimated-delivery performance.

Seller-level delivery-performance measures will not be created from the available data.

This prevents an order-level logistics outcome from being incorrectly attributed to individual sellers.

---

#### 6.3.9 No Seller Attribution of Reviews

Customer reviews also operate at order level.

An order containing multiple sellers may receive one representative review, but the dataset does not establish which seller that review refers to.

Therefore `bi_fact_seller_orders` will not contain:

* representative review score;
* low-review indicator;
* seller review score;
* seller satisfaction measures.

Seller review performance will not be inferred from order-level reviews.

---

#### 6.3.10 Seller Participation

Seller participation will be evaluated primarily through delivered marketplace activity.

Measures supported by this fact will include:

```text
Active Sellers
Seller-Order Relationships
Seller Items Sold
Seller Item Sales Value
Average Seller Orders
Average Item Sales Value per Seller
```

An active seller will generally mean:

> **A seller represented in at least one delivered order within the current reporting context**

The exact measure definition will be implemented as an explicit DAX measure rather than inferred from row presence alone.

---

#### 6.3.11 Seller Participation Across Periods

The matched January–August comparison established substantial changes in seller participation.

Known validated results include:

| Metric                     | Jan–Aug 2017 | Jan–Aug 2018 |
| -------------------------- | -----------: | -----------: |
| Active sellers             |        1,153 |        2,330 |
| Seller-order relationships |       22,223 |       53,622 |
| Items                      |       24,943 |       60,324 |
| Item sales value           | 2,993,456.13 | 7,218,125.12 |

The reporting model may reproduce these comparisons dynamically using `DimDate` and DAX.

Sellers appearing in only one matched period must not automatically be labeled:

* new sellers;
* churned sellers;
* acquired sellers;
* exited sellers.

The available data establishes participation differences, not the underlying reason for those differences.

---

#### 6.3.12 Seller Concentration

Seller concentration is an important reporting use case for this fact.

The validated completed-order analysis established that:

```text
2,970 active sellers
```

participated in completed marketplace activity.

Approximately:

```text
4.28% of active sellers
→ generated 50% of completed item sales value

17.95% of active sellers
→ generated 80% of completed item sales value
```

Power BI may use this fact to communicate concentration and productive-supply distribution.

However, seller concentration will not automatically be labeled as:

* excessive;
* unhealthy;
* risky;
* inefficient.

Those interpretations require additional commercial and operational evidence.

---

#### 6.3.13 Seller Dimension Relationship

The relationship will be:

```text
DimSeller[seller_id]
        1
        ↓
        *
bi_fact_seller_orders[seller_id]
```

`DimSeller` will provide descriptive attributes including:

```text
seller_id
seller_city
seller_state
```

This allows seller geography to be analyzed without duplicating those attributes throughout the fact table.

---

#### 6.3.14 Seller Geography

Seller geography will be based on the seller's recorded state.

The validated completed-order analysis showed substantial geographic concentration, including:

```text
São Paulo
→ 59.56% of active sellers
→ 64.36% of completed item sales value
```

Geographic reporting will therefore support questions related to:

* active sellers by state;
* seller merchandise activity by state;
* geographic concentration of productive supply.

Seller geography should not be interpreted as a direct measure of logistics capacity, inventory availability, or regional profitability.

---

#### 6.3.15 Date Relationship

The primary relationship will be:

```text
DimDate[Date]
        1
        ↓
        *
bi_fact_seller_orders[order_purchase_date]
```

This keeps seller activity aligned with the same purchase-date timeline used throughout the reporting model.

---

#### 6.3.16 Critical Validation Requirements

Before the view enters Power BI, it must satisfy the following checks:

```text
Each order-seller combination is unique
seller_item_count reconciles to the order-item population
seller_item_sales_value reconciles to order-item sales value
delivered seller activity reconciles to F6
all source sellers represented in applicable item activity remain traceable
multi-seller orders create multiple seller relationships without duplicating seller-level merchandise values
```

Known completed-order reconciliation targets include:

| Validation Check                     | Expected Result |
| ------------------------------------ | --------------: |
| Active completed sellers             |           2,970 |
| Completed seller-order relationships |          97,819 |
| Completed item count                 |         110,197 |
| Completed item sales value           |   13,221,498.11 |
| Single-seller completed orders       |          95,203 |
| Multi-seller completed orders        |           1,275 |
| Maximum sellers in a completed order |               5 |

The exact total number of seller-order rows across all recorded order statuses will be measured when the SQL view is implemented.

It will not be estimated in advance.

---

#### 6.3.17 Reporting Responsibility

`bi_fact_seller_orders` will support:

### Seller Participation

* active sellers;
* seller-order relationships;
* seller participation over time;
* matched-period participation comparisons.

### Seller Commercial Activity

* seller item sales value;
* seller item volume;
* average commercial activity per active seller.

### Seller Concentration

* share of merchandise activity generated by leading sellers;
* seller productivity distribution;
* concentration of productive supply.

### Seller Geography

* active sellers by state;
* seller item sales value by state;
* geographic distribution of productive seller supply.

The fact will intentionally exclude delivery and review attribution because the available order-level data does not support assigning those outcomes reliably to individual sellers.

### 6.4 Payment Fact — `bi_fact_payments`

`bi_fact_payments` will provide the reporting grain required for payment-method usage, payment value, multi-payment behaviour, mixed payment methods, and credit-card installment analysis.

Payment activity will remain separate from merchandise facts because an order can contain multiple payment records independently of the number of products, categories, or sellers associated with that order.

#### 6.4.1 Grain

The table grain is:

> **1 row = 1 payment record within an order**

The natural key is:

```text
order_id
+
payment_sequential
```

The expected source population is:

```text
103,886 payment records
```

representing:

```text
99,440 paid orders
```

One recorded order has no associated payment record and therefore will not appear in this fact table.

---

#### 6.4.2 Source Tables

The view will use:

| Source Table | Purpose                                                   |
| ------------ | --------------------------------------------------------- |
| `payments`   | Payment method, sequence, installments, and payment value |
| `orders`     | Order purchase date used for the reporting timeline       |

No merchandise, seller, review, or customer tables are required for the current payment-reporting questions.

The following tables will therefore not be joined directly into this fact:

* `order_items`
* `products`
* `sellers`
* `reviews`
* `customers`
* `geolocation`
* `category_translation`

This keeps payment activity independent from unrelated one-to-many business processes.

---

#### 6.4.3 Planned Columns

| Column                   | Purpose                                                      |
| ------------------------ | ------------------------------------------------------------ |
| `order_id`               | Order identifier                                             |
| `payment_sequential`     | Payment-record sequence within the order                     |
| `order_purchase_date`    | Date used for the `DimDate` relationship                     |
| `payment_type`           | Recorded payment method                                      |
| `payment_installments`   | Number of recorded installments                              |
| `payment_value`          | Recorded value of the payment record                         |
| `payment_record_count`   | Number of payment records associated with the order          |
| `payment_method_count`   | Number of distinct payment methods associated with the order |
| `is_multi_payment_order` | Indicates an order containing more than one payment record   |
| `is_multi_method_order`  | Indicates an order containing more than one payment method   |
| `installment_band`       | Credit-card installment classification                       |

The order-level payment counts and flags will be repeated across payment records belonging to the same order.

They will therefore be used with **distinct order measures**, not summed across payment rows.

---

#### 6.4.4 Payment Value Definition

`payment_value` will retain the recorded value from the payment dataset.

The validated payment population contains:

```text
Total recorded payment value
= 16,008,872.12
```

This measure must not be described as:

* marketplace revenue;
* item sales value;
* profit;
* seller revenue;
* commission.

`payment_value` and `item_sales_value` represent different business concepts and will remain in separate fact tables.

---

#### 6.4.5 Paid Orders

A paid order is an order represented by at least one record in `bi_fact_payments`.

Known validated populations are:

```text
Recorded orders        99,441
Paid orders            99,440
Orders without payment      1
```

The payment fact itself contains only paid orders because an order with no payment record cannot generate a payment-row fact.

The missing-payment order remains preserved in the order fact.

---

#### 6.4.6 Multiple Payment Records

An order may contain more than one payment record.

The validated payment analysis established:

```text
Single-payment-record orders     96,479
Multiple-payment-record orders    2,961
```

representing approximately:

```text
2.98% of paid orders
```

The maximum number of payment records associated with a single order is:

```text
29
```

`payment_record_count` will therefore be calculated at order level before being attached to individual payment records.

Conceptually:

```sql
SELECT
    order_id,
    COUNT(*) AS payment_record_count
FROM payments
GROUP BY order_id
```

The flag:

```text
is_multi_payment_order
```

will equal `1` when:

```text
payment_record_count > 1
```

and `0` otherwise.

---

#### 6.4.7 Multiple Payment Methods

Multiple payment records do not necessarily mean that an order used multiple payment methods.

For example:

```text
Order A
├── Voucher
└── Voucher
```

contains:

```text
2 payment records
1 payment method
```

while:

```text
Order B
├── Credit card
└── Voucher
```

contains:

```text
2 payment records
2 payment methods
```

The validated payment analysis identified:

```text
Multiple-payment-record orders       2,961
Multiple-method orders               2,246
```

Therefore:

```text
715
```

multi-record orders still used only one payment method.

`payment_method_count` will be calculated using the number of distinct `payment_type` values associated with each order.

The flag:

```text
is_multi_method_order
```

will equal `1` when:

```text
payment_method_count > 1
```

---

#### 6.4.8 Payment-Method Usage

The retained payment types are:

```text
credit_card
boleto
voucher
debit_card
not_defined
```

Validated payment-record counts are:

| Payment Type | Payment Records |
| ------------ | --------------: |
| Credit card  |          76,795 |
| Boleto       |          19,784 |
| Voucher      |           5,775 |
| Debit card   |           1,529 |
| Not defined  |               3 |

These values reconcile to:

```text
103,886 payment records
```

Payment-method **record count** and payment-method **order usage** are different measures.

For example:

```text
Payment records by method
→ COUNTROWS(payment fact)

Orders using method
→ DISTINCTCOUNT(order_id)
```

An order may use more than one payment type.

Therefore:

> **Payment-method order usage is not additive across methods.**

The sum of distinct orders using each payment method can exceed the total number of paid orders.

---

#### 6.4.9 Mixed Payment Methods

Mixed-method orders were relatively uncommon.

The validated analysis identified:

```text
2,246 mixed-method orders
```

with the following combinations:

```text
Credit card + Voucher      2,245
Credit card + Debit card       1
```

The reporting layer may communicate the prevalence of mixed-method behaviour, but this is supporting commercial context rather than a primary strategic metric.

No additional mixed-method classification table is required.

---

#### 6.4.10 Credit-Card Installment Analysis

Installment analysis will be restricted to:

```text
payment_type = 'credit_card'
```

This preserves the analytical convention established during SQL analysis.

`payment_installments` will remain at its original payment-record grain.

The validated analysis showed that approximately:

```text
66.85%
```

of credit-card payment records used more than one installment.

This should be interpreted as payment behaviour, not as proof that installments caused customers to make larger purchases.

---

#### 6.4.11 Installment Band

For credit-card records, `installment_band` will use the same grouping established during SQL analysis:

```text
1_installment
2_to_3_installments
4_to_6_installments
7_to_12_installments
13_plus_installments
non_positive
```

For non-credit-card records:

```text
installment_band = 'not_applicable'
```

The `non_positive` group preserves the two retained credit-card records with non-positive installment values rather than silently correcting or removing them.

Validated positive-installment distributions include:

| Installment Band  | Share of Credit-Card Records | Avg Payment Value |
| ----------------- | ---------------------------: | ----------------: |
| 1 installment     |                       33.15% |             95.87 |
| 2–3 installments  |                       29.79% |            134.23 |
| 4–6 installments  |                       21.17% |            181.32 |
| 7–12 installments |                       15.65% |            333.29 |
| 13+ installments  |                        0.24% |            413.72 |

The association between installment depth and payment value will remain descriptive.

---

#### 6.4.12 Order-Level Attributes Repeated Across Payment Rows

The following fields operate at order level:

```text
payment_record_count
payment_method_count
is_multi_payment_order
is_multi_method_order
```

but will appear on each payment record belonging to that order.

For example:

```text
Order A | Credit card | payment_record_count = 2 | is_multi_method_order = 1
Order A | Voucher     | payment_record_count = 2 | is_multi_method_order = 1
```

Therefore these fields must not be summed to calculate order counts.

Measures such as:

```text
Multi-Payment Orders
Mixed-Method Orders
```

must use:

```text
DISTINCTCOUNT(order_id)
```

under the appropriate filter condition.

This rule will be enforced through explicit DAX measures.

---

#### 6.4.13 Date Relationship

The primary relationship will be:

```text
DimDate[Date]
        1
        ↓
        *
bi_fact_payments[order_purchase_date]
```

This aligns payment behaviour with the same purchase-date reporting timeline used by the other fact tables.

The payment dataset does not provide a separate payment timestamp, so order purchase date is the appropriate available reporting date.

---

#### 6.4.14 Payment Type as a Fact Attribute

A separate payment-method dimension will not initially be created.

`payment_type` contains only a small number of stable categorical values and currently has no additional descriptive attributes requiring a separate dimension.

It can therefore remain as a low-cardinality attribute within `bi_fact_payments`.

The same approach applies to:

```text
installment_band
```

A separate dimension should only be introduced later if a genuine reporting or semantic requirement justifies it.

---

#### 6.4.15 Analytical Population

Unlike the primary marketplace, category, and seller commercial metrics, payment analysis will use the **recorded paid-order population rather than delivered orders only**.

This is intentional because payment activity occurs at checkout and exists independently of whether the order was ultimately delivered.

The primary payment population is therefore:

```text
all recorded payment records
```

rather than:

```text
delivered-order payment records only
```

This distinction must remain clear in report measure names and documentation.

---

#### 6.4.16 Critical Validation Requirements

Before the view enters Power BI, it must satisfy the following checks:

```text
(order_id, payment_sequential) is unique
payment-record count reconciles to the payments table
distinct paid-order count reconciles to F7
payment value reconciles to F7
payment-type record counts reconcile to source data
single- and multi-record paid orders partition the paid-order population
single- and multi-method paid orders partition the paid-order population
maximum payment-record count remains 29
maximum payment-method count remains 2
non-positive installment records are retained
```

Known reconciliation targets include:

| Validation Check                  | Expected Result |
| --------------------------------- | --------------: |
| Payment records                   |         103,886 |
| Paid orders                       |          99,440 |
| Recorded payment value            |   16,008,872.12 |
| Single-payment-record orders      |          96,479 |
| Multiple-payment-record orders    |           2,961 |
| Multiple-method orders            |           2,246 |
| Maximum payment records per order |              29 |
| Maximum payment methods per order |               2 |
| Credit-card records               |          76,795 |
| Boleto records                    |          19,784 |
| Voucher records                   |           5,775 |
| Debit-card records                |           1,529 |
| `not_defined` records             |               3 |
| Non-positive installment records  |               2 |

Any mismatch must be investigated before the view is loaded into Power BI.

---

#### 6.4.17 Reporting Responsibility

`bi_fact_payments` will support:

### Payment Structure

* paid orders;
* payment records;
* average payment records per paid order;
* single-payment versus multi-payment behaviour;
* mixed-method usage.

### Payment Method Mix

* payment records by method;
* paid-order usage by method;
* payment value by method;
* payment-value share by method.

### Installment Behaviour

* credit-card installment distribution;
* single versus multi-installment usage;
* average payment value by installment band.

### Payment Behaviour Over Time

* payment-method usage by purchase period;
* payment-method value share over time;
* installment behaviour over time.

Payment reporting will remain a supporting commercial layer and will not be used to infer payment profitability, financing economics, or customer credit behaviour without additional data.


### 6.5 Date Dimension — `DimDate`

`DimDate` will provide the shared calendar structure used across the Power BI semantic model.

It will allow orders, category activity, seller activity, and payment behaviour to be analyzed through one consistent purchase-date timeline.

Unlike the BI fact tables, `DimDate` will be created within the Power BI semantic model rather than as a MySQL reporting view.

#### 6.5.1 Grain

The table grain is:

> **1 row = 1 calendar date**

Each date must appear exactly once.

The date table will contain a continuous sequence of dates without gaps.

---

#### 6.5.2 Date Range

`DimDate` will cover the full recorded order-purchase period:

```text
04 September 2016
through
17 October 2018
```

The date dimension will therefore preserve all recorded marketplace activity, including the sparse beginning and non-comparable ending periods.

The existence of those dates in the model does not mean that all dates will be used for primary trend or growth reporting.

The analytical-period conventions established during SQL analysis remain:

```text
Primary continuous trend
→ January 2017 through August 2018

Matched growth comparison
→ January–August 2017
   versus
   January–August 2018
```

---

#### 6.5.3 Date Table Creation

The date dimension will be generated in Power BI using DAX.

The initial table can be based on the minimum and maximum purchase dates available in `bi_fact_orders`.

Conceptually:

```DAX
DimDate =
CALENDAR(
    MIN(bi_fact_orders[order_purchase_date]),
    MAX(bi_fact_orders[order_purchase_date])
)
```

Because all four BI facts derive their reporting date from the order purchase date, `bi_fact_orders` provides the appropriate boundaries for the shared calendar.

The exact DAX implementation will be added during semantic-model construction.

---

#### 6.5.4 Planned Columns

The date dimension will contain:

| Column                    | Purpose                                       |
| ------------------------- | --------------------------------------------- |
| `Date`                    | Unique calendar date and relationship key     |
| `Year`                    | Calendar year                                 |
| `Quarter Number`          | Numeric quarter                               |
| `Quarter`                 | Display label such as `Q1`                    |
| `Month Number`            | Numeric month from 1 to 12                    |
| `Month`                   | Full month name                               |
| `Month Short`             | Abbreviated month label                       |
| `Year Month`              | Display label such as `2018-08`               |
| `Year Month Sort`         | Numeric sort key such as `201808`             |
| `Month Start`             | First date of the calendar month              |
| `Is Core Analysis Period` | Identifies January 2017 through August 2018   |
| `Is Matched Period`       | Identifies January–August in 2017 or 2018     |
| `Matched Period Year`     | Identifies the applicable matched-period year |

Only fields that support actual reporting requirements will be retained.

Additional calendar attributes such as week number, fiscal periods, or weekday indicators will not be added unless the report later requires them.

---

#### 6.5.5 Year and Month Hierarchy

The primary time hierarchy will support:

```text
Year
  ↓
Month
```

Quarter may remain available for optional grouping, but the current business analysis primarily uses monthly trends and matched January–August comparisons.

A more complicated hierarchy is unnecessary.

---

#### 6.5.6 Month Sorting

Month names must not be sorted alphabetically.

Therefore:

```text
Month
```

will be sorted by:

```text
Month Number
```

Similarly:

```text
Year Month
```

will be sorted using:

```text
Year Month Sort
```

For example:

```text
Year Month        Year Month Sort

2017-01          201701
2017-02          201702
...
2018-08          201808
```

This ensures chronological ordering in Power BI visuals.

---

#### 6.5.7 Core Analysis Period

The primary continuous analytical window is:

```text
01 January 2017
through
31 August 2018
```

`Is Core Analysis Period` will identify dates inside this range.

Conceptually:

```text
TRUE
→ 2017-01-01 through 2018-08-31

FALSE
→ all other dates
```

This allows report visuals to focus on the comparable continuous period without removing earlier or later observations from the semantic model.

Sparse 2016 activity and September–October 2018 activity therefore remain available for traceability.

---

#### 6.5.8 Matched Comparison Period

The primary growth comparison established during SQL analysis is:

```text
January–August 2017
versus
January–August 2018
```

`Is Matched Period` will therefore identify dates meeting either of these conditions:

```text
Year = 2017
Month = January through August
```

or:

```text
Year = 2018
Month = January through August
```

This ensures that matched-period growth measures do not accidentally compare:

```text
full-year 2017
versus
partial-year 2018
```

---

#### 6.5.9 Matched Period Year

For dates inside the matched comparison:

```text
Matched Period Year
```

will contain:

```text
2017
```

or:

```text
2018
```

Dates outside the matched comparison will remain blank.

This provides a simple reporting field where the two matched populations need to be shown side by side.

It does not replace explicit DAX measures for growth calculations.

---

#### 6.5.10 Why the Full Date Range Is Retained

The date dimension will not be restricted to January 2017 through August 2018.

Doing so would remove legitimate recorded marketplace activity from the semantic model.

Instead:

```text
Full recorded period
→ preserved in model

Primary continuous period
→ identified by analytical flag

Matched comparison
→ identified separately
```

This preserves the distinction between:

> **data availability**

and:

> **business-comparable analytical periods**

---

#### 6.5.11 Primary Relationship Date

All four fact tables will use:

```text
order_purchase_date
```

as their active relationship to `DimDate`.

The relationships will be:

```text
DimDate[Date]
        1
        ↓
        *
bi_fact_orders[order_purchase_date]
```

```text
DimDate[Date]
        1
        ↓
        *
bi_fact_order_categories[order_purchase_date]
```

```text
DimDate[Date]
        1
        ↓
        *
bi_fact_seller_orders[order_purchase_date]
```

```text
DimDate[Date]
        1
        ↓
        *
bi_fact_payments[order_purchase_date]
```

Each relationship will use single-direction filtering from `DimDate` to the corresponding fact.

---

#### 6.5.12 Delivery Dates

`bi_fact_orders` also contains:

```text
order_delivered_customer_date
order_estimated_delivery_date
```

These dates will not initially receive additional active relationships to `DimDate`.

The current delivery business questions evaluate the delivery outcome of orders purchased during a given period.

For example:

> Of the orders purchased in a particular month, what proportion were delivered after their estimated delivery date?

This is different from asking:

> How many deliveries physically occurred during that calendar month?

The first question is the one supported by the current analytical framework.

Additional role-playing date relationships will therefore not be introduced without a genuine reporting requirement.

---

#### 6.5.13 Time Intelligence

DAX measures may use `DimDate` for calculations such as:

```text
monthly marketplace trends
matched-period comparisons
period-specific marketplace share
seller participation over time
payment-method trends
```

However, generic time-intelligence calculations will not automatically be used where they conflict with the validated analytical periods.

For example:

```text
Previous Year
```

should not be assumed to be the correct comparison for every visual.

The project specifically requires:

```text
Jan–Aug 2017
vs
Jan–Aug 2018
```

for its primary matched growth comparison.

The measure logic must preserve that definition.

---

#### 6.5.14 Date Table Configuration

During Power BI implementation:

```text
DimDate
```

will be explicitly configured as the model's date table using:

```text
DimDate[Date]
```

as its unique date column.

The following conditions must hold:

```text
Date contains no duplicates
Date contains no blanks
Date sequence has no gaps
Date data type is Date
```

---

#### 6.5.15 Auto Date/Time

The model should rely on the explicit `DimDate` table rather than automatically generated hidden date structures.

The reporting model will therefore use the shared date dimension for report filtering, grouping, and time calculations.

This keeps time logic centralized and visible.

---

#### 6.5.16 Critical Validation Requirements

After `DimDate` is created, the following checks must pass:

```text
one row exists per calendar date
minimum date matches the earliest recorded purchase date
maximum date matches the latest recorded purchase date
no date values are duplicated
no dates are missing within the calendar range
Year Month sorts chronologically
core-period flag covers Jan 2017 through Aug 2018 only
matched-period flag covers Jan–Aug 2017 and Jan–Aug 2018 only
all fact-table purchase dates successfully match DimDate
```

No fact row should be left unmatched because of a missing calendar date.

---

#### 6.5.17 Reporting Responsibility

`DimDate` will support:

### Marketplace Trends

* monthly completed orders;
* monthly customers;
* monthly items sold;
* monthly item sales value.

### Matched Growth

* January–August 2017;
* January–August 2018;
* matched-period growth measures.

### Delivery Analysis

* delivery outcomes for orders purchased over time;
* late-delivery trends by purchase period.

### Category and Seller Analysis

* category growth over time;
* seller participation over time;
* matched-period commercial comparisons.

### Payment Analysis

* payment-method usage over time;
* payment-value mix over time.

`DimDate` therefore provides a single consistent reporting timeline across the semantic model while preserving the analytical period definitions established earlier in the project.

### 6.6 Category Dimension — `DimCategory`

`DimCategory` will provide the business-facing category labels used to filter and group `bi_fact_order_categories`.

The dimension will preserve the original Olist category value while using the English translation where one is available.

Because category translation is a source-data preparation rule rather than an interactive report calculation, the dimension will be prepared in the SQL reporting layer and imported into Power BI.

#### 6.6.1 Grain

The table grain is:

> **1 row = 1 analytical category key**

The expected analytical category population is:

```text
73 represented source categories
+
1 missing-category group
=
74 analytical category groups
```

Each `category_key` must be unique.

---

#### 6.6.2 Source Tables

The dimension will use:

| Source Table           | Purpose                                                                  |
| ---------------------- | ------------------------------------------------------------------------ |
| `products`             | Identifies source product-category values represented in the marketplace |
| `category_translation` | Provides English category labels where available                         |

`order_items` is not required to define category labels themselves.

Commercial activity belongs in `bi_fact_order_categories`, not in the category dimension.

---

#### 6.6.3 Category Key

The dimension requires a stable technical key that does not depend on the translated display label.

For products with a known source category:

```text
category_key
=
products.product_category_name
```

For products with no recorded source category, a dedicated missing-category key will be used.

Conceptually:

```text
source category exists
→ category_key = source category

source category missing
→ category_key = '__unknown__'
```

Using a technical sentinel such as:

```text
__unknown__
```

keeps the key distinct from the user-facing label:

```text
Unknown
```

and avoids treating the display label itself as a technical identifier.

The same category-key rule must be used when `bi_fact_order_categories` is created.

---

#### 6.6.4 Planned Columns

| Column                  | Purpose                                                           |
| ----------------------- | ----------------------------------------------------------------- |
| `category_key`          | Unique analytical category key                                    |
| `source_category_name`  | Original Olist product-category value                             |
| `category_display_name` | Business-facing reporting label                                   |
| `translation_status`    | Identifies translated, untranslated, or missing-source categories |

The dimension will remain intentionally small.

Measures such as category sales value, item count, growth, review outcomes, and marketplace share belong in the fact table and DAX layer rather than in the dimension.

---

#### 6.6.5 Display-Label Logic

The business-facing label will follow the convention established during SQL analysis.

Conceptually:

```sql
COALESCE(
    category_translation.product_category_name_english,
    products.product_category_name,
    'Unknown'
)
```

This produces:

```text
English translation available
→ use English label

Source category exists but translation is unavailable
→ use original source category

Source category missing
→ use "Unknown"
```

No category translation will be inferred or manually fabricated.

---

#### 6.6.6 Translation Status

`translation_status` will make the category-label condition explicit.

The planned values are:

```text
translated
untranslated
missing_source_category
```

Their meaning is:

| Translation Status        | Meaning                                              |
| ------------------------- | ---------------------------------------------------- |
| `translated`              | Source category has an English translation           |
| `untranslated`            | Source category exists but has no translation lookup |
| `missing_source_category` | Product category itself is missing                   |

This field may remain hidden from normal report users unless it becomes useful for data-quality explanation or validation.

---

#### 6.6.7 Known Untranslated Categories

The validated dataset contains two represented source categories without an English translation:

```text
pc_gamer

portateis_cozinha_e_preparadores_de_alimentos
```

These categories will remain separate analytical categories.

Their reporting labels will remain their original source values.

They must not be:

* removed;
* merged into `Unknown`;
* manually translated;
* grouped with another category.

This preserves the original business data without fabricating information.

---

#### 6.6.8 Missing Source Category

Products with no recorded category will map to:

```text
category_key = '__unknown__'
category_display_name = 'Unknown'
translation_status = 'missing_source_category'
```

This group remains part of category reporting because the underlying merchandise activity is valid even though the category attribute is missing.

The completed-order analysis identified:

```text
1,537 completed items
```

with missing category information, representing approximately:

```text
1.39% of completed items
```

and approximately:

```text
1.29% of completed item sales value
```

This activity must remain visible rather than being silently removed.

---

#### 6.6.9 Why the Source Category Is Preserved

`category_display_name` will not be used as the semantic key.

The source category is retained separately because:

* translation coverage is incomplete;
* display labels are descriptive rather than technical identifiers;
* grouping logic should remain traceable to the source dataset;
* category identity should not depend on presentation wording.

The relationship will therefore use:

```text
category_key
```

rather than:

```text
category_display_name
```

---

#### 6.6.10 Relationship

The relationship will be:

```text
DimCategory[category_key]
        1
        ↓
        *
bi_fact_order_categories[category_key]
```

The relationship will use single-direction filtering from `DimCategory` to `bi_fact_order_categories`.

No direct relationship is required between `DimCategory` and any other fact table.

---

#### 6.6.11 Report-Facing Fields

For most report visuals, users should interact primarily with:

```text
category_display_name
```

rather than:

```text
category_key
source_category_name
translation_status
```

Technical fields can remain hidden from report view where they do not support business interpretation.

This keeps the semantic model understandable without removing traceability.

---

#### 6.6.12 Category Sorting

No permanent sales-based sort order will be stored in `DimCategory`.

Category commercial ranking changes according to:

* report filters;
* selected period;
* metric;
* marketplace context.

Therefore rankings such as:

```text
Top category by item sales value
Top growth contributor
Highest review score
```

will be calculated dynamically through DAX or visual sorting.

The dimension should contain descriptive attributes, not results that depend on analytical context.

---

#### 6.6.13 Critical Validation Requirements

Before the dimension is loaded into Power BI, the following checks must pass:

```text
category_key is unique
no category_key is null
every category key in bi_fact_order_categories matches DimCategory
all represented source categories remain present
two untranslated categories remain distinct
missing-category activity maps to the dedicated Unknown member
no English translation is fabricated
```

Expected structural results are:

| Validation Check                    | Expected Result |
| ----------------------------------- | --------------: |
| Represented source categories       |              73 |
| Translated represented categories   |              71 |
| Untranslated represented categories |               2 |
| Missing-category analytical member  |               1 |
| Total analytical category members   |              74 |

The exact reconciliation will be confirmed when the SQL reporting views are implemented.

---

#### 6.6.14 Reporting Responsibility

`DimCategory` will support category filtering and grouping for:

### Commercial Performance

* category item sales value;
* category item volume;
* category completed orders;
* marketplace share.

### Growth Analysis

* matched-period growth;
* absolute growth contribution;
* marketplace-share movement.

### Customer-Experience Context

* representative review score for orders containing the category;
* low-review rate;
* comparisons across commercially important categories.

The dimension provides consistent business-facing category labels while preserving the original source categories and known translation limitations.

### 6.7 Seller Dimension — `DimSeller`

`DimSeller` will provide the descriptive seller attributes used to filter and group `bi_fact_seller_orders`.

The dimension will contain stable seller information from the source dataset rather than analytical results derived from seller activity.

Because seller identity and geography already exist in the validated MySQL database, `DimSeller` will be prepared in the SQL reporting layer and imported into Power BI.

#### 6.7.1 Grain

The table grain is:

> **1 row = 1 seller**

The natural key is:

```text
seller_id
```

The source seller population contains:

```text
3,095 sellers
```

Each `seller_id` must therefore appear at most once in the dimension.

The number of sellers considered active in any particular report period will be determined from `bi_fact_seller_orders`, not from the dimension row count.

---

#### 6.7.2 Source Table

The dimension will use:

| Source Table | Purpose                                       |
| ------------ | --------------------------------------------- |
| `sellers`    | Seller identity and recorded seller geography |

No order-item activity is required to define seller descriptive attributes.

Seller performance belongs in the fact table and DAX layer.

---

#### 6.7.3 Planned Columns

| Column         | Purpose               |
| -------------- | --------------------- |
| `seller_id`    | Unique seller key     |
| `seller_city`  | Recorded seller city  |
| `seller_state` | Recorded seller state |

The dimension will remain intentionally compact.

No commercial metrics will be stored as seller attributes.

---

#### 6.7.4 Seller Geography

Seller geography will use the location recorded in the source `sellers` table.

The primary geographic reporting attribute will be:

```text
seller_state
```

because state-level analysis was established as the appropriate geographic level during earlier project phases.

`seller_city` may remain available for traceability and optional drill-down, but it will not automatically become a primary dashboard segmentation.

The model will not use raw geolocation coordinates to redefine seller location.

---

#### 6.7.5 Why Seller State Belongs in the Dimension

Unlike customer geography, seller geography is naturally associated with the seller entity itself.

The source structure provides:

```text
seller_id
→ seller_city
→ seller_state
```

Therefore seller location can safely reside in `DimSeller`.

This differs from `customer_unique_id`, where a small number of underlying customers appear across multiple customer-state records and therefore cannot be assigned one state without an unsupported rule.

---

#### 6.7.6 Active Seller Status Is Not a Dimension Attribute

The dimension will not contain a permanent field such as:

```text
is_active
```

Seller activity depends on the current analytical context.

For example, a seller may be:

```text
active in Jan–Aug 2017
inactive in Jan–Aug 2018
```

or the reverse.

Therefore:

> **Active seller status is a measure determined from fact-table activity within the selected reporting period.**

It is not a stable seller attribute.

---

#### 6.7.7 Seller Participation Labels Will Not Be Stored

The dimension will not contain permanent classifications such as:

```text
new_seller
retained_seller
churned_seller
inactive_seller
```

The dataset does not provide sufficient evidence to assign those lifecycle labels.

The matched-period analysis only established whether sellers were observed in:

```text
2017 matched period only
2018 matched period only
both matched periods
```

Those are analytical participation patterns rather than permanent seller characteristics.

If those comparisons are needed in Power BI, they should be derived through measures or controlled analytical logic.

---

#### 6.7.8 Seller Performance Tiers Will Not Be Stored

`DimSeller` will not contain fixed categories such as:

```text
top seller
high-value seller
low-performing seller
strategic seller
```

Seller performance depends on:

* selected time period;
* selected commercial metric;
* current report filters;
* marketplace context.

For example, a seller may rank highly by:

```text
item sales value
```

but not by:

```text
item volume
```

Therefore seller rankings and concentration groups should remain dynamic analytical calculations rather than static dimension attributes.

---

#### 6.7.9 No Seller Delivery Attributes

`DimSeller` will not contain fields such as:

```text
average_delivery_days
late_delivery_rate
delivery_performance_band
```

Delivery outcomes exist at order level and cannot be reliably attributed to individual sellers, particularly for multi-seller orders.

Adding these fields to the seller dimension would create an unsupported seller-performance interpretation.

---

#### 6.7.10 No Seller Review Attributes

Similarly, the dimension will not contain:

```text
seller_review_score
seller_rating
customer_satisfaction_score
```

because reviews operate at order level rather than seller level.

A customer review for a multi-seller order cannot be reliably assigned to one seller using the available data.

---

#### 6.7.11 Relationship

The relationship will be:

```text
DimSeller[seller_id]
        1
        ↓
        *
bi_fact_seller_orders[seller_id]
```

The relationship will use single-direction filtering from `DimSeller` to `bi_fact_seller_orders`.

No direct relationship is required between `DimSeller` and:

* `bi_fact_orders`;
* `bi_fact_order_categories`;
* `bi_fact_payments`.

This preserves the fact-specific seller grain.

---

#### 6.7.12 Seller State Reporting

Seller-state analysis will be performed through:

```text
DimSeller[seller_state]
        ↓
bi_fact_seller_orders
```

This will support measures such as:

```text
Active Sellers by State
Seller Item Sales Value by State
Seller Item Count by State
Seller Share of Marketplace Activity
```

Known validated completed-order results include:

```text
São Paulo
→ 1,769 active sellers
→ 59.56% of active sellers
→ 64.36% of completed item sales value
```

These results will be reproduced through fact-table measures rather than stored directly in `DimSeller`.

---

#### 6.7.13 City-Level Reporting

`seller_city` will remain available in the model because it is a valid source attribute.

However, city-level visuals will only be created if they answer a defined business question.

The existence of a more granular geographic field does not require the dashboard to use it.

The current business-analysis framework prioritizes state-level supply structure.

---

#### 6.7.14 Technical Fields and Report Visibility

For report users:

```text
seller_state
seller_city
```

may remain visible when useful for filtering or drill-down.

`seller_id` is primarily a technical identifier and may remain hidden from normal report consumers unless a seller-level detail visual requires it.

The model should expose business-relevant fields without unnecessarily cluttering the report field list.

---

#### 6.7.15 Critical Validation Requirements

Before `DimSeller` is loaded into Power BI, the following checks must pass:

```text
seller_id is unique
seller_id contains no null values
seller dimension row count reconciles to the sellers table
every seller_id in bi_fact_seller_orders matches DimSeller
seller city and state values are preserved from the validated source
no activity-based or unsupported performance classification is introduced
```

Expected structural result:

| Validation Check                     | Expected Result |
| ------------------------------------ | --------------: |
| Seller dimension rows                |           3,095 |
| Distinct `seller_id`                 |           3,095 |
| Active sellers in completed activity |           2,970 |

The final value is a fact-table analytical result rather than the dimension row count.

---

#### 6.7.16 Reporting Responsibility

`DimSeller` will support descriptive filtering and grouping for:

### Seller Participation

* active sellers by state;
* seller participation over time.

### Seller Commercial Activity

* item sales value by seller state;
* item volume by seller state;
* seller-level commercial comparisons where appropriate.

### Supply Structure

* geographic distribution of seller supply;
* concentration of productive seller activity across states.

The dimension will remain focused on stable seller attributes while all commercial and participation measures remain in `bi_fact_seller_orders` and the DAX layer.


### 6.8 Customer State Dimension — `DimCustomerState`

`DimCustomerState` will provide the state-level geographic attributes used to filter and group order, customer, and delivery activity in `bi_fact_orders`.

Customer geography is attached to the specific customer record associated with each order rather than permanently assigned to `customer_unique_id`.

The dimension will therefore represent geographic values rather than customers.

#### 6.8.1 Grain

The table grain is:

> **1 row = 1 customer state code**

The natural key is:

```text
state_code
```

Each state represented in the order-associated customer data must appear only once.

---

#### 6.8.2 Source Data

The state values originate from:

```text
customers.customer_state
```

and enter the Power BI reporting layer through:

```text
bi_fact_orders.customer_state
```

`DimCustomerState` may therefore be created from the distinct state codes represented in the validated customer data or BI order fact.

No raw geolocation table is required.

---

#### 6.8.3 Planned Columns

The initial dimension will contain:

| Column       | Purpose                                                                                         |
| ------------ | ----------------------------------------------------------------------------------------------- |
| `state_code` | Unique Brazilian state abbreviation                                                             |
| `state_name` | Optional business-facing full state name, only if explicitly mapped from a controlled reference |

The minimum required version of the dimension is therefore simply:

```text
state_code
```

The model does not require a full state-name mapping to function correctly.

If full state names are later added for report readability, the mapping should be explicit and documented rather than inferred from transactional data.

---

#### 6.8.4 Why Geography Remains at Order Context

Customer analysis uses:

```text
customer_unique_id
```

to identify the underlying customer across orders.

However, the validated data showed that a small number of `customer_unique_id` values appear across multiple states.

The known pattern is:

```text
37 customer_unique_id values
appear across more than one state
```

including:

```text
36 customers across 2 states
1 customer across 3 states
```

Assigning one permanent state to those customers would require an unsupported rule such as:

* first observed state;
* latest observed state;
* most frequent state;
* highest-value state.

No such rule is required by the current business questions.

Therefore:

> **Customer state remains an attribute of the order-associated customer record rather than a permanent attribute of the underlying customer.**

---

#### 6.8.5 Relationship

The relationship will be:

```text
DimCustomerState[state_code]
        1
        ↓
        *
bi_fact_orders[customer_state]
```

The relationship will use single-direction filtering from `DimCustomerState` to `bi_fact_orders`.

No direct relationship is required between `DimCustomerState` and:

* `bi_fact_order_categories`;
* `bi_fact_seller_orders`;
* `bi_fact_payments`.

Those facts do not currently require customer-state analysis.

---

#### 6.8.6 Customer Geography Reporting

The dimension will support order-context geographic analysis such as:

```text
Completed Orders by Customer State
Completed Item Sales Value by Customer State
Completed Unique Customers by Customer State
Late Delivery Rate by Customer State
Average Delivery Days by Customer State
Review Outcomes by Customer State
```

However, customer counts across states are not necessarily additive.

Because some `customer_unique_id` values appear in more than one state:

> **The sum of distinct customers across individual states may exceed the marketplace-wide distinct-customer count.**

This must be preserved in DAX interpretation and report documentation.

---

#### 6.8.7 Delivery Geography

Customer state is also the primary geographic field for delivery-experience analysis.

This supports comparisons such as:

```text
Late Delivery Rate by State
Average Delivery Days by State
Eligible Delivery Orders by State
Review Outcomes by Delivery State
```

The validated SQL analysis showed meaningful variation across states.

Examples include:

| State          | Eligible Delivery Orders | Late Delivery Rate |
| -------------- | -----------------------: | -----------------: |
| São Paulo      |                   40,494 |              5.89% |
| Rio de Janeiro |                   12,350 |             13.47% |
| Bahia          |                    3,256 |             14.04% |
| Ceará          |                    1,279 |             15.32% |

These values will be reproduced through fact-table measures rather than stored in the dimension.

---

#### 6.8.8 Geographic Population Size

State-level rates must be interpreted together with their underlying order populations.

A high late-delivery rate in a low-volume state does not necessarily have the same marketplace impact as a similar rate affecting a large state.

Therefore geographic visuals should normally make both of the following available:

```text
rate
+
affected population / order volume
```

This supports the Phase 08 decision question of identifying states that combine:

```text
meaningful marketplace exposure
+
comparatively weak delivery reliability
```

---

#### 6.8.9 Why Raw Geolocation Is Not Used

The raw geolocation dataset will not be directly related to `DimCustomerState` or `bi_fact_orders`.

The source geolocation data contains:

* multiple records per ZIP prefix;
* duplicated geographic observations in the raw source;
* incomplete marketplace coverage.

Joining it directly into transactional reporting would introduce unnecessary complexity and potential duplication.

State-level geography already supports the current reporting questions and was established as the appropriate primary geographic level during SQL analysis.

---

#### 6.8.10 No Geographic Performance Classification

The dimension will not contain static classifications such as:

```text
high_lateness_state
low_performance_state
priority_market
high_value_state
```

These labels depend on:

* selected period;
* selected metric;
* current report context;
* business thresholds that have not been formally defined.

Geographic performance will therefore remain dynamic through DAX measures and visual context.

---

#### 6.8.11 Customer and Seller Geography Remain Separate

`DimCustomerState` will not be reused as the seller geography dimension.

Seller geography already exists within:

```text
DimSeller[seller_state]
```

The two concepts represent different business roles:

```text
Customer state
→ where the order-associated customer is located

Seller state
→ where the seller is recorded
```

Although both use Brazilian state codes, combining them into one shared geography dimension is not necessary for the current reporting requirements and could create confusing filter behavior across unrelated facts.

They will therefore remain semantically separate.

---

#### 6.8.12 Report-Facing Fields

The primary report-facing field will be:

```text
state_code
```

If a controlled full-state-name mapping is later added, report users may instead interact with:

```text
state_name
```

while `state_code` remains available for traceability.

No other attributes are required initially.

---

#### 6.8.13 Critical Validation Requirements

Before the dimension is used in the semantic model, the following checks must pass:

```text
state_code is unique
state_code contains no unexpected null values
every customer_state represented in bi_fact_orders matches DimCustomerState
state values reconcile to the validated customer source
no customer_unique_id is forced into one permanent state
no raw geolocation join is introduced
```

State-level Power BI measures should later reconcile to the validated SQL geographic outputs for selected major states.

---

#### 6.8.14 Reporting Responsibility

`DimCustomerState` will support:

### Customer Geography

* completed orders by state;
* completed unique customers by state;
* item sales value by state.

### Delivery Reliability

* eligible delivery orders by state;
* late-delivery rate by state;
* average delivery duration by state;
* delay severity by state.

### Customer Experience

* representative review outcomes by state;
* comparison of delivery reliability and review outcomes across major markets.

The dimension provides a simple and controlled geographic filter while preserving the fact that customer state belongs to the order context rather than permanently to the underlying customer.


### 6.9 Customer Dimension Decision

A separate `DimCustomer` was initially considered with the proposed grain:

> **1 row = 1 `customer_unique_id`**

After reviewing the reporting requirements and available customer attributes, it will **not be included in the initial Power BI semantic model**.

#### 6.9.1 Reason for the Decision

Customer-level analysis in this project is based on:

```text
customer_unique_id
```

which is already retained in:

```text
bi_fact_orders
```

The current reporting questions require measures such as:

* unique customers;
* completed unique customers;
* observed repeat customers;
* one-time versus repeat purchasing;
* completed-order frequency;
* customer merchandise activity.

All of these can be calculated directly from the order fact using `customer_unique_id`.

A separate customer dimension would currently contain very little descriptive information beyond the customer identifier itself.

Creating a key-only dimension would therefore add another table and relationship without materially improving the semantic model.

---

#### 6.9.2 Customer Geography Does Not Justify a Customer Dimension

Customer state cannot be treated as a permanent attribute of `customer_unique_id`.

The validated data shows that a small number of underlying customers appear across more than one state.

Customer geography therefore remains at the order context and is handled through:

```text
DimCustomerState
        ↓
bi_fact_orders
```

rather than:

```text
DimCustomer
        ↓
customer state
```

This avoids introducing an unsupported primary-state rule.

---

#### 6.9.3 Customer Identifier in the Order Fact

`customer_unique_id` will remain directly available in:

```text
bi_fact_orders
```

It will support customer-level DAX measures such as:

```text
DISTINCTCOUNT(customer_unique_id)
```

and controlled customer-frequency calculations.

The identifier may be hidden from normal report users if it is not needed for visible reporting, while remaining available to the semantic model for calculations.

---

#### 6.9.4 Repeat-Customer Analysis

Repeat behaviour depends on the number of completed orders associated with each `customer_unique_id`.

This is an analytical result rather than a permanent customer attribute.

A customer should therefore not receive a static field such as:

```text
repeat_customer = yes/no
```

inside a dimension.

The classification can change according to the reporting population or date context.

For example:

```text
Customer A
January–June
→ 1 completed order

January–August
→ 2 completed orders
```

The same customer can therefore move from one-time to repeat status as the observation window changes.

Repeat-customer logic will be implemented through explicit DAX measures using the order fact.

---

#### 6.9.5 No Unsupported Customer Attributes

The model will not create inferred customer attributes such as:

* primary state;
* customer value tier;
* loyalty segment;
* acquisition channel;
* retention status;
* customer lifecycle stage.

The available dataset does not provide sufficient evidence to treat these as stable descriptive characteristics.

Where customer segmentation is required for a defined business question, it should be derived transparently from measurable marketplace activity rather than introduced as an unsupported dimension attribute.

---

#### 6.9.6 When a Customer Dimension Would Become Justified

A separate customer dimension could become useful if reliable customer-level descriptive attributes became available, such as:

```text
customer acquisition date
acquisition channel
customer demographic attributes
loyalty membership
customer segment from an established business system
```

It could also be reconsidered if a future analytical requirement explicitly requires a persistent customer-level semantic entity.

Those conditions do not exist in the current project.

---

#### 6.9.7 Final Decision

The initial semantic model will therefore contain:

### Fact Tables

```text
bi_fact_orders
bi_fact_order_categories
bi_fact_seller_orders
bi_fact_payments
```

### Dimensions

```text
DimDate
DimCategory
DimSeller
DimCustomerState
```

`customer_unique_id` will remain an analytical identifier within `bi_fact_orders` rather than being represented through a separate dimension.

This keeps the model smaller, avoids an unnecessary relationship, and preserves the principle that every semantic-model table should have a clear reporting purpose.

## 7. Relationship Matrix

The semantic model will use a limited number of explicit relationships between dimensions and fact tables.

The relationship design follows four principles:

* dimensions filter facts;
* fact tables do not directly filter other fact tables;
* relationships use one-to-many cardinality;
* single-direction filtering is the default.

The model will not introduce additional relationships unless a defined reporting requirement demonstrates that they are necessary.

### 7.1 Approved Relationships

| Dimension          | Dimension Key  | Fact Table                 | Fact Key              | Cardinality | Filter Direction | Active | Purpose                                                                 |
| ------------------ | -------------- | -------------------------- | --------------------- | ----------- | ---------------- | ------ | ----------------------------------------------------------------------- |
| `DimDate`          | `Date`         | `bi_fact_orders`           | `order_purchase_date` | 1 → *       | Single           | Yes    | Marketplace, customer, delivery, and review analysis over purchase time |
| `DimDate`          | `Date`         | `bi_fact_order_categories` | `order_purchase_date` | 1 → *       | Single           | Yes    | Category performance and growth over purchase time                      |
| `DimDate`          | `Date`         | `bi_fact_seller_orders`    | `order_purchase_date` | 1 → *       | Single           | Yes    | Seller participation and commercial activity over purchase time         |
| `DimDate`          | `Date`         | `bi_fact_payments`         | `order_purchase_date` | 1 → *       | Single           | Yes    | Payment behaviour over purchase time                                    |
| `DimCustomerState` | `state_code`   | `bi_fact_orders`           | `customer_state`      | 1 → *       | Single           | Yes    | Customer and delivery geography                                         |
| `DimCategory`      | `category_key` | `bi_fact_order_categories` | `category_key`        | 1 → *       | Single           | Yes    | Category filtering and business-facing labels                           |
| `DimSeller`        | `seller_id`    | `bi_fact_seller_orders`    | `seller_id`           | 1 → *       | Single           | Yes    | Seller filtering and seller geography                                   |

These seven relationships form the complete initial relationship structure.

---

### 7.2 Relationship Direction

All approved relationships will use:

> **single-direction filtering from the dimension to the fact table**

Conceptually:

```text
Dimension
    1
    ↓
    *
Fact
```

For example:

```text
DimCategory
      ↓
bi_fact_order_categories
```

Selecting a category will filter category activity.

The category fact will not filter the category dimension back automatically.

This keeps filter propagation predictable and reduces the risk of ambiguous model behaviour.

---

### 7.3 Date Relationships

`DimDate` is the only dimension shared by all four fact tables.

Its active relationships use:

```text
order_purchase_date
```

in every fact.

This creates one consistent reporting timeline:

```text
                    DimDate
                       |
        --------------------------------
        |            |         |       |
        v            v         v       v
     Orders      Categories  Sellers  Payments
```

A date filter can therefore place multiple business processes into the same purchase-period context without requiring direct fact-to-fact relationships.

---

### 7.4 Customer State Relationship

The relationship:

```text
DimCustomerState[state_code]
        1
        ↓
        *
bi_fact_orders[customer_state]
```

exists only for the primary order fact.

Customer state will not directly filter:

* category activity;
* seller activity;
* payment activity.

Adding those relationships would imply cross-domain geographic analysis that has not been established as a current reporting requirement.

If a future business question genuinely requires customer-state category or payment analysis, the appropriate grain and modeling approach should be evaluated separately rather than creating a relationship for convenience.

---

### 7.5 Category Relationship

The relationship:

```text
DimCategory[category_key]
        1
        ↓
        *
bi_fact_order_categories[category_key]
```

will be the only relationship involving `DimCategory`.

The dimension will not directly filter:

* `bi_fact_orders`;
* `bi_fact_seller_orders`;
* `bi_fact_payments`.

Category-level measures will be calculated from the category fact, whose grain was specifically designed for that purpose.

---

### 7.6 Seller Relationship

The relationship:

```text
DimSeller[seller_id]
        1
        ↓
        *
bi_fact_seller_orders[seller_id]
```

will be the only relationship involving `DimSeller`.

Seller attributes will not directly filter the primary order fact.

This prevents order-level delivery or review metrics from being interpreted as seller-level outcomes.

---

### 7.7 Fact-to-Fact Relationships Will Not Be Created

Although multiple fact tables contain:

```text
order_id
```

that shared identifier will not be used to create direct relationships between facts.

The following relationships are explicitly excluded:

```text
bi_fact_orders
    X
bi_fact_order_categories
```

```text
bi_fact_orders
    X
bi_fact_seller_orders
```

```text
bi_fact_orders
    X
bi_fact_payments
```

```text
bi_fact_order_categories
    X
bi_fact_seller_orders
```

```text
bi_fact_order_categories
    X
bi_fact_payments
```

```text
bi_fact_seller_orders
    X
bi_fact_payments
```

`order_id` remains available inside the fact tables for:

* traceability;
* validation;
* distinct-order measures where appropriate.

Its presence does not imply that fact tables should be related.

---

### 7.8 Why Direct Fact Relationships Are Avoided

Each fact represents a different grain:

```text
bi_fact_orders
→ 1 row per order

bi_fact_order_categories
→ 1 row per order × category

bi_fact_seller_orders
→ 1 row per order × seller

bi_fact_payments
→ 1 row per payment record
```

Directly relating these grains could create ambiguous or misleading filter behaviour.

For example, one order may contain:

```text
3 categories
2 sellers
2 payment records
```

Those represent separate business processes.

The semantic model should not implicitly combine them simply because they share an `order_id`.

Where multiple business processes need to be compared, common dimensions and separately defined measures will provide the analytical context.

---

### 7.9 Bidirectional Filtering

No relationship will initially use bidirectional filtering.

Bidirectional filtering will not be introduced simply to make a visual work.

If a future requirement appears to require it, the following questions must first be answered:

1. What business question requires reverse filter propagation?
2. Why cannot the requirement be solved using the existing dimension-to-fact model?
3. Could the relationship create an ambiguous filter path?
4. Could the requirement instead be solved through an explicit DAX measure?

Only after those questions are resolved should a relationship change be considered.

---

### 7.10 Many-to-Many Relationships

No many-to-many relationship is planned.

Dimension keys must remain unique:

```text
DimDate[Date]
DimCustomerState[state_code]
DimCategory[category_key]
DimSeller[seller_id]
```

If Power BI identifies one of these relationships as many-to-many during implementation, that will be treated as a modeling or source-data problem requiring investigation.

The cardinality will not simply be accepted or manually changed to many-to-many.

---

### 7.11 Inactive Date Relationships

Additional relationships from `DimDate` to:

```text
order_delivered_customer_date
order_estimated_delivery_date
```

will not initially be created.

The current analytical framework evaluates delivery outcomes according to the purchase period of the order.

Therefore:

```text
DimDate
        ↓
order_purchase_date
```

is sufficient for the defined business questions.

Inactive role-playing relationships will only be introduced later if a specific reporting question requires analysis by delivery-occurrence date or estimated-delivery date.

---

### 7.12 Relationship Key Requirements

Before relationships are created, dimension keys must satisfy:

```text
unique
non-null
correct data type
compatible with the corresponding fact key
```

Fact foreign-key columns must use compatible data types.

Examples include:

```text
DimDate[Date]
        Date
↔
bi_fact_orders[order_purchase_date]
        Date
```

and:

```text
DimSeller[seller_id]
        Text
↔
bi_fact_seller_orders[seller_id]
        Text
```

Power BI should not rely on automatic type conversion to make relationships function.

---

### 7.13 Referential Coverage

Every fact key used in an approved relationship should resolve successfully to the corresponding dimension.

Required checks include:

```text
every order_purchase_date
→ DimDate

every customer_state
→ DimCustomerState

every category_key
→ DimCategory

every seller_id
→ DimSeller
```

Unexpected unmatched keys must be investigated before the semantic model is considered valid.

The dedicated `__unknown__` category member ensures that missing source categories remain intentionally represented rather than becoming unmatched fact rows.

---

### 7.14 Filter Behaviour Example

A report filter such as:

```text
Year Month = 2018-08
```

will filter all four facts through `DimDate`.

However, a filter such as:

```text
Category = Health & Beauty
```

will filter only:

```text
bi_fact_order_categories
```

It will not automatically change:

* marketplace-wide order KPIs;
* seller KPIs;
* payment KPIs.

This is intentional.

Those measures belong to different business processes and should not inherit category context unless a dedicated analytical design explicitly supports it.

---

### 7.15 Relationship Validation in Power BI

After the relationships are created, the model must be inspected to confirm:

```text
7 approved relationships only
all approved relationships active
all relationships 1-to-many
all relationships single-direction
no direct fact-to-fact relationships
no many-to-many relationships
no unexpected ambiguous paths
no unmatched dimension keys
```

The model view should visually remain simple enough that the relationship structure can be understood without tracing complex dependency chains.

---

### 7.16 Final Relationship Structure

The initial semantic model relationship structure is:

```text
                         DimDate
                            |
          -----------------------------------------
          |                 |           |         |
          v                 v           v         v
   bi_fact_orders   bi_fact_order_  bi_fact_   bi_fact_
                    categories      seller_     payments
                                    orders
          |                 |           |
          v                 v           v
 DimCustomerState      DimCategory   DimSeller
```

Or logically:

```text
DimDate
├── bi_fact_orders
├── bi_fact_order_categories
├── bi_fact_seller_orders
└── bi_fact_payments

DimCustomerState
└── bi_fact_orders

DimCategory
└── bi_fact_order_categories

DimSeller
└── bi_fact_seller_orders
```

This structure is intentionally small, controlled, and aligned with the analytical grains established throughout the project.




