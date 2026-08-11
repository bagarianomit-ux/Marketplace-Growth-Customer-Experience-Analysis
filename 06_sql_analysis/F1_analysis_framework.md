# Marketplace Growth & Customer Experience Analysis

## F1. SQL Analysis Framework

## 1. Purpose

This phase uses the validated MySQL database to investigate marketplace performance and customer experience through SQL.

The objective is to identify:

- How marketplace activity changes over time.
- Which customers and regions contribute most to marketplace activity.
- How delivery performance affects customer experience.
- Which product categories and sellers drive marketplace activity.
- How payment behaviour varies across orders and customers.
- Where meaningful performance gaps or growth opportunities exist.

This phase focuses on analytical investigation rather than data cleaning, database redesign, dashboard development, or final business recommendations.

The findings produced here will provide the evidence base for later Excel analysis, business interpretation, reporting, and recommendations.


## 2. Analytical Approach

The analysis follows this sequence:

> Business question → metric definition → population → grain → safe join → SQL calculation → validation → interpretation

SQL queries should answer business questions rather than exist only to demonstrate SQL syntax.

Advanced SQL techniques such as CTEs, window functions, conditional aggregation, ranking, and subqueries will be used where they improve the analysis or make the logic clearer.


## 3. Source of Truth

All analysis will use the populated and validated MySQL database:

`marketplace_growth_analysis`

The database contains the cleaned representation approved during data preparation and verified after loading.

Phases 01–05 are treated as frozen unless later analysis reveals a genuine factual or technical contradiction.


## 4. Analytical Boundaries

This phase may:

- Aggregate validated database records.
- Calculate business and operational metrics.
- Create temporary analytical CTEs or derived fields inside SQL queries.
- Compare performance across time, customers, sellers, categories, and geography.
- Rank entities and calculate contribution shares.
- Investigate relationships between marketplace performance and customer experience.
- Apply metric-specific eligibility filters.

This phase will not:

- Modify source tables.
- Perform additional data cleaning.
- Impute missing values.
- Correct uncertain timestamps.
- Remove statistical outliers only because they appear unusual.
- Fabricate missing category translations.
- Redesign the database.
- Treat unsupported commercial measures as known business facts.
- Produce final recommendations before analytical evidence is established.


## 5. Core Table Grains

Analytical queries must preserve or deliberately transform the known table grains.

| Table | Grain |
|---|---|
| `customers` | One row per `customer_id` |
| `orders` | One row per `order_id` |
| `order_items` | One product item within an order |
| `payments` | One payment record within an order |
| `reviews` | One review record associated with an order |
| `products` | One row per `product_id` |
| `sellers` | One row per `seller_id` |
| `geolocation` | One distinct geographic coordinate |
| `category_translation` | One translation record per available Portuguese category |

`customer_unique_id` represents the underlying customer across customer records and will be used for repeat-customer analysis.


## 6. Grain and Join Rules

The required analytical grain must be identified before combining tables.

Several tables have one-to-many relationships with orders:

- An order may contain multiple items.
- An order may contain multiple payments.
- An order may contain multiple reviews.
- An order may contain items from multiple sellers.

Therefore, a direct join such as:

`orders → order_items → payments → reviews`

must not be treated as an order-grain dataset.

Where measures from multiple child tables are required, each child table must first be aggregated to the required common grain.

Example:

`order_items`
→ aggregate to `order_id`

`payments`
→ aggregate to `order_id`

`reviews`
→ aggregate to `order_id` when an order-level review measure is required

Then join the order-level results to `orders`.

This rule is required to prevent analytical fanout and duplicated measures.

## 7. Metric Terminology

Metric names must reflect what the dataset actually contains.

### Item Sales Value

`order_items.price`

Aggregated item prices represent item sales value or merchandise value.

For example:

`SUM(order_items.price)`

may be described as:

- Item sales value
- Merchandise value
- GMV-like merchandise value where clearly explained

It will not automatically be described as Olist revenue.

The dataset does not provide the information required to calculate Olist's actual marketplace revenue.


### Freight Value

`order_items.freight_value`

Freight value represents the recorded freight amount associated with an order item.

It is not treated as:

- Seller cost
- Olist cost
- Profit deduction
- Logistics expense incurred by Olist


### Payment Value

`payments.payment_value`

Payment value represents the recorded payment amount.

Because orders may contain multiple payment records, payment values must be aggregated to order grain before combining them with order-level or item-derived measures.


### Profit and Margin

Profit, gross margin, contribution margin, and seller cost cannot be calculated reliably from the available dataset.

Therefore:

`price - freight_value`

will not be labelled as profit.


### Customer Merchandise Activity

Where appropriate, customer merchandise activity may be measured by aggregating item sales value across orders associated with `customer_unique_id`.

This represents observed merchandise value associated with the customer.

It will not be labelled as true Customer Lifetime Value because the dataset does not contain the complete economic and lifetime information required for a formal CLV calculation.


## 8. Population Rules

There will not be one universal order population for every metric.

Eligibility will depend on the business question.

### Marketplace Activity

Recorded order activity may include all order statuses when the purpose is to measure order creation, marketplace demand, or order-status behaviour.

Completed marketplace activity will be reported separately using delivered orders.


### Merchandise Analysis

Primary completed merchandise-performance metrics will use item records associated with delivered orders.

This population represents completed marketplace activity and will be used for measures such as completed item sales value, item volume, category contribution, and seller contribution.

Item records associated with non-delivered orders will not be discarded. They may be analysed separately when investigating cancellations, unresolved orders, non-completed merchandise activity, or other operational issues.

When all item records are used, the metric will be explicitly described as recorded or ordered merchandise activity rather than completed merchandise activity.


### Delivery Analysis

Delivery-duration metrics require:

- A valid purchase timestamp.
- A valid customer delivery timestamp.

Metrics comparing actual delivery with the estimate also require:

- A valid estimated delivery date.

Known chronological anomalies will not be silently corrected. Metric-specific eligibility conditions will be applied where required.


### Seller Fulfilment Analysis

Metrics involving seller fulfilment or carrier handoff must use only records containing the timestamps required by the metric.

Order-level delivery timestamps must not automatically be interpreted as seller-specific events when an order contains multiple sellers.


### Review Analysis

Review-level analysis may use all retained review records.

When review information is required at order grain, the representative order-level review defined in Section 11 will be used before joining reviews to other order-level measures.


### Repeat-Customer Analysis

Repeat customers will be identified using:

`customer_unique_id`

not `customer_id`.

A repeat customer is an underlying customer associated with more than one distinct order.

The analysis should distinguish:

- Customer records
- Unique customers
- Repeat customers
- Orders per unique customer


## 9. Temporal Analysis

### Core Analytical Period

The complete order history spans September 2016 through October 2018. However, the dataset contains sparse activity during 2016 and only a small number of mostly non-completed orders during September and October 2018.

The primary continuous period for marketplace trend analysis will therefore be:

**January 2017 through August 2018**

Records outside this period remain available for historical and order-status investigation but will not be treated as directly comparable full marketplace periods.

Full-year 2017 will not be compared directly with incomplete 2018.

Year-over-year comparisons will use matched periods, such as January–August 2017 versus January–August 2018.


## 10. Delivery Definitions

The following definitions will be used where the required timestamps are available.

### Delivery Duration

Time between:

`order_purchase_timestamp`

and:

`order_delivered_customer_date`


### Estimated Delivery Window

Time between:

`order_purchase_timestamp`

and:

`order_estimated_delivery_date`


### Late Delivery

An order is late when:

`order_delivered_customer_date > order_estimated_delivery_date`


### On-Time or Early Delivery

An order is on time or early when:

`order_delivered_customer_date <= order_estimated_delivery_date`


### Delivery Delay

Difference between actual customer delivery and estimated delivery.

Positive values indicate late delivery.

Negative values indicate delivery before the estimated date.


## 11. Customer Experience Measures

Customer experience will primarily be assessed using:

- Review score
- Delivery duration
- Late-delivery rate
- Delivery-delay severity
- Order completion status
- Repeat-purchase behaviour where appropriate

Relationships between these measures will be investigated without automatically assuming causation.

For example, an association between late delivery and lower review scores may be observed, but this alone does not prove that delivery delay caused the review outcome.

### Order-Level Review Representation

Review-level analysis may use all retained review records.

When a single review representation is required at order grain, the review with the latest `review_answer_timestamp` will be used as the representative order-level review.

This convention prevents orders containing multiple reviews from multiplying order-level measures and avoids averaging conflicting review scores into synthetic values.

The latest answered review is an analytical convention for creating a consistent order-level representation and is not assumed to be the uniquely correct customer opinion.

## 12. Product and Category Analysis

Product analysis may examine:

- Item sales value
- Item volume
- Order participation
- Average item price
- Freight characteristics
- Review outcomes
- Delivery performance
- Category concentration
- Product characteristics where relevant

Category translations will be joined using a `LEFT JOIN`.

Products belonging to untranslated categories must remain in the analysis rather than being removed.

Portuguese category values remain the authoritative category identifier.

Reviews are recorded at order level rather than product level.

For category-level review analysis, reviews must first be reduced to the representative order-level review. The review may then be associated once with each distinct category represented in the order.

This produces a measure of review outcomes for orders containing a category and must not be interpreted as a direct product-level rating.

## 13. Seller Analysis

Seller analysis may examine:

- Item sales value
- Items sold
- Orders served
- Category participation
- Customer geography
- Delivery outcomes
- Review outcomes
- Marketplace contribution
- Seller concentration

Seller metrics must account for multi-seller orders.

Order-level measures must not be duplicated across sellers without a clearly defined allocation rule.


## 14. Payment Analysis

Payment analysis may examine:

- Payment type
- Payment value
- Number of payment records
- Instalment behaviour
- Payment mix
- Relationship between payment behaviour and order value

Multiple payment records belonging to the same order must be aggregated appropriately before joining to item-level or order-level commercial measures.

Valid unusual values retained during preparation, including zero-value payments, zero instalment counts, and `not_defined` payment types, will remain visible unless a metric-specific rule requires otherwise.


## 15. Geographic Analysis

Primary geographic segmentation may use:

- Customer state
- Customer city
- Seller state
- Seller city

State-level analysis will generally be preferred where city-level fragmentation would reduce interpretability.

The raw geolocation table contains multiple rows for many ZIP prefixes.

Therefore, directly joining customers or sellers to geolocation by ZIP prefix can create row multiplication.

Geolocation coordinates will only be used after defining an appropriate one-row-per-ZIP analytical representation.

ZIP-prefix relationships are analytical rather than enforced database foreign keys because geolocation values are non-unique and coverage is incomplete.


## 16. Known Analytical Limitations

The following validated limitations must remain visible during analysis:

- Missing order lifecycle timestamps.
- Missing review text.
- Missing product categories and metadata.
- Missing product dimensions.
- `not_defined` payment types.
- Zero payment values.
- Zero payment instalment counts.
- Zero product weights.
- Repeated `review_id` values with valid composite review keys.
- Product categories without English translations.
- Retained chronological anomalies.
- Statistical outliers that were not proven invalid.
- Incomplete and non-unique geolocation ZIP coverage.

These records were deliberately retained during preparation rather than altered without evidence.

Analysis will therefore use metric-specific eligibility rules instead of deleting these records globally.

## 17. Analytical Question Map

The SQL analysis will be organised around the following business questions.

### A. Marketplace Performance and Growth

1. How large is the observed marketplace in terms of orders, items, customers, sellers, and item sales value?
2. How does marketplace activity change over time?
3. Which periods contribute most to order volume and item sales value?
4. How do order statuses change over time?
5. Is marketplace activity concentrated in particular customer regions?
6. How concentrated is marketplace merchandise activity across customers, categories, and sellers?


### B. Customer Behaviour

1. How many unique customers are represented in the marketplace?
2. What proportion of customers make repeat purchases?
3. How many orders do repeat customers place?
4. How does merchandise activity differ between one-time and repeat customers?
5. Which customer states contribute the most orders and item sales value?
6. Are repeat-customer patterns different across geographic regions or other useful dimensions?


### C. Delivery and Customer Experience

1. How long does delivery typically take?
2. What proportion of eligible orders arrive late?
3. How severe are delivery delays when they occur?
4. How does delivery performance change over time?
5. Which customer regions experience weaker delivery performance?
6. How do review scores differ between late and on-time deliveries?
7. Does review score change as delivery delay becomes more severe?
8. Which marketplace segments combine high activity with weak customer experience?


### D. Product and Category Performance

1. Which categories generate the highest item sales value?
2. Which categories account for the most items and orders?
3. How concentrated is marketplace activity across categories?
4. Which categories have higher or lower average item prices?
5. Which categories carry higher freight values relative to item value?
6. Which categories experience weaker delivery performance?
7. Which categories receive weaker review outcomes?
8. Which categories combine strong commercial activity with customer-experience problems?


### E. Seller Performance

1. Which sellers contribute the most item sales value and item volume?
2. How concentrated is marketplace activity among sellers?
3. Which sellers participate across multiple categories?
4. Which sellers are associated with stronger or weaker delivery outcomes?
5. Which sellers are associated with stronger or weaker review outcomes?
6. Which high-contribution sellers also show customer-experience risks?
7. How does seller performance vary geographically?


### F. Payment Behaviour

1. Which payment methods are most commonly used?
2. How does payment value vary by payment type?
3. How frequently are instalments used?
4. How does instalment behaviour change with order value?
5. How often do orders contain multiple payment records or payment methods?
6. Are payment patterns different across important customer or marketplace segments?


### G. Geographic Patterns

1. Which states generate the most customers, orders, and item sales value?
2. Which states show the highest and lowest marketplace participation?
3. How does delivery performance differ across customer states?
4. How does seller supply vary geographically?
5. Are high-demand customer regions supported by strong seller presence?
6. Which geographic areas combine strong demand with weaker customer experience?


## 18. Cross-Domain Investigation

The most important findings may come from combining analytical domains rather than ranking each domain independently.

Examples include:

- High-sales categories with high late-delivery rates.
- High-volume sellers with poor review outcomes.
- High-demand regions with weak delivery performance.
- Repeat customers with different order-value or review behaviour.
- High item-value orders with different payment or delivery patterns.

Cross-domain analysis must use controlled grains and must distinguish correlation or association from causation.


## 19. SQL Validation Strategy

Analytical results will not be considered reliable only because a query executes successfully.

Important metrics will be independently reconciled where appropriate.

Validation will include checks such as:

- Total order count.
- Distinct customer count.
- Item count.
- Total item sales value.
- Total freight value.
- Total payment value.
- Review count.
- Delivered-order population.
- Late-delivery population.
- Repeat-customer population.
- Distinct reviewed orders.
- Multi-review order count.
- Representative order-review count.
- Confirmation that each order contributes at most one review after order-level review reduction.

Queries that combine multiple one-to-many tables will receive particular attention for fanout.

Analytical validation will be maintained separately from the business-analysis queries.


## 20. Interpretation Rules

Analytical outputs will distinguish:

### Observation

What the SQL result directly shows.

### Interpretation

What the observed pattern may mean for marketplace performance or customer experience.

### Limitation

What cannot be concluded from the available data.

### Follow-up

Whether a finding deserves deeper SQL analysis, Excel investigation, dashboard reporting, or later recommendation work.

Descriptive relationships will not automatically be presented as causal relationships.


## 21. Phase Output

Phase 06 will produce:

- A documented analytical framework.
- Reproducible SQL analysis.
- Validated foundational metrics.
- A set of evidence-based analytical findings.
- Selected analytical outputs suitable for deeper Excel analysis.
- A clear evidence base for later business analysis and reporting.

Final recommendations will not be produced until the analytical findings have been consolidated and evaluated in the later business-analysis phase.
