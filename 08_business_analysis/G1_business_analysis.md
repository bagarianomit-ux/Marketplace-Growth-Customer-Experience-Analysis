# Business Analysis

## 1. Business Context

The SQL analysis identified substantial marketplace expansion alongside important differences in customer behaviour, delivery reliability, category performance, seller participation, and payment behaviour.

The purpose of this phase is not to repeat the individual analytical outputs produced in F2–F7. Instead, it brings those findings together to determine which patterns are most important from a business perspective and which questions should guide subsequent reporting and decision-making.

The analysis focuses on four primary business themes:

1. Growth model and customer behaviour
2. Delivery reliability and customer experience
3. Category portfolio and commercial mix
4. Seller and supply structure

Payment behaviour is retained as supporting commercial context rather than treated as a primary strategic theme.

Because the dataset is observational and does not contain information such as marketing exposure, acquisition cost, seller economics, logistics-provider detail, or profitability, the conclusions in this phase distinguish clearly between measured evidence, business interpretation, and areas requiring further investigation.


## 2. Growth Model and Customer Behaviour

Marketplace activity expanded substantially between the matched January–August periods of 2017 and 2018. Completed orders increased by 139.94%, completed unique customers by 141.13%, items sold by 141.85%, and completed item sales value by 141.13%.

Average item sales value per completed order increased by only 0.49% over the same comparison. This indicates that the observed marketplace expansion was primarily driven by greater customer and transaction volume rather than materially higher merchandise value per order.

Customer behaviour reinforces this pattern. Across the completed-order population, 93,358 unique customers were observed, of whom 90,557 completed only one order and 2,801 completed more than one. Repeat customers therefore represented approximately 3.00% of completed customers and accounted for 6.14% of completed orders and 5.51% of completed item sales value.

Taken together, these findings indicate that marketplace activity during the observed period was dominated by growth in customer and transaction volume alongside one-time purchasing.

The 3.00% repeat-customer figure should not be interpreted as a cohort-normalized retention rate. Customers entered the dataset at different points in time and therefore had unequal opportunities to make subsequent purchases. The available data nevertheless establishes that observed completed purchasing was heavily concentrated among one-time customers.

### Business Question

To what extent could stronger second-purchase behaviour or higher customer value complement continued growth in customer and transaction volume?


## 3. Delivery Reliability and Customer Experience

Delivery performance presents a more complex picture than average delivery time alone suggests. Between the matched January–August periods of 2017 and 2018, average delivery duration remained broadly stable, moving from 12.18 days to 12.14 days. However, the share of eligible delivered orders arriving after the estimated delivery date increased from 4.18% to 9.37%.

At the same time, average delay among late orders decreased from 12.89 days to 8.88 days, while the average estimated delivery window narrowed from 25.38 days to 22.80 days. This indicates that the marketplace was not simply experiencing slower deliveries. Instead, a larger proportion of orders arrived after the estimated delivery date even though overall delivery duration remained stable and the average severity of late deliveries declined.

The available data does not isolate whether this change resulted from greater operational variability, tighter delivery estimates, changes in geographic or order mix, or a combination of these factors. The appropriate business interpretation is therefore that **delivery reliability relative to customer expectations weakened during the period of rapid marketplace expansion**, rather than that physical delivery speed broadly deteriorated.

Customer-review outcomes make this pattern particularly important. Orders delivered on or before the estimated date had an average review score of 4.29, with 9.22% receiving low scores of 1 or 2. Review outcomes became progressively weaker across several delay-severity bands:

| Delivery Outcome     | Avg Review Score | Low Review Rate |
| -------------------- | ---------------: | --------------: |
| On time or early     |             4.29 |           9.22% |
| Over 0–3 days late   |             3.77 |          19.12% |
| Over 3–7 days late   |             2.32 |          61.31% |
| Over 7–14 days late  |             1.74 |          78.15% |
| Over 14–30 days late |             1.61 |          81.83% |

The pattern provides strong evidence of an association between delivery lateness and poorer customer-review outcomes. It should not, however, be interpreted as proof that lateness alone caused the lower reviews, because other aspects of the order experience may also influence customer satisfaction.

The relationship also varies geographically. Large states such as São Paulo recorded comparatively low late-delivery rates of 5.89%, while Rio de Janeiro recorded 13.47%. Bahia and Ceará recorded late-delivery rates of 14.04% and 15.32% respectively. These differences indicate that delivery reliability is not uniform across the marketplace and that aggregate marketplace averages can conceal materially different regional experiences.

Taken together, the evidence suggests that delivery performance should be evaluated through **reliability against the estimated delivery date**, not only through average delivery speed. The increase in late-delivery incidence, its strong association with weaker review outcomes, and the differences across states make delivery reliability one of the clearest customer-experience issues identified in the analysis.

### Business Question

Which markets and delivery conditions contribute most to missed estimated delivery dates, and where could improvements in operational reliability or delivery-estimate calibration have the greatest potential customer-experience impact?


## 4. Category Portfolio and Commercial Mix

Marketplace merchandise activity was distributed across a broad category portfolio, but commercial performance was concentrated among a relatively small number of categories. The five largest category groups accounted for approximately 39.83% of completed item sales value, while the top ten accounted for approximately 62.43%.

The largest completed merchandise categories included:

| Category                | Item Sales Value | Marketplace Share |
| ----------------------- | ---------------: | ----------------: |
| Health & Beauty         |     1,233,131.72 |             9.33% |
| Watches & Gifts         |     1,166,176.98 |             8.82% |
| Bed Bath & Table        |     1,023,434.76 |             7.74% |
| Sports & Leisure        |       954,852.55 |             7.22% |
| Computers & Accessories |       888,724.61 |             6.72% |

Category scale alone, however, does not fully explain marketplace growth. During the matched January–August periods, several major categories contributed disproportionately to the increase in item sales value.

Health & Beauty contributed 12.12% of total matched-period marketplace growth, while Watches & Gifts contributed 11.52%. Together, these two categories accounted for approximately 23.64% of the increase in completed item sales value. Sports & Leisure, Computers & Accessories, and Bed Bath & Table were also important contributors.

The direction of marketplace-share movement differed across these categories. Health & Beauty increased its merchandise-value share by 2.33 percentage points and Watches & Gifts by 2.81 percentage points. In contrast, Bed Bath & Table remained one of the marketplace's largest categories but lost approximately 1.12 percentage points of share during the matched comparison.

This distinction is important because a category can remain commercially significant while growing more slowly than the marketplace overall. Category performance should therefore be evaluated using several dimensions together:

* current commercial scale;
* absolute contribution to marketplace growth;
* percentage growth;
* marketplace-share movement;
* and associated customer-review outcomes.

Customer experience also differs across important categories. For example, Health & Beauty recorded an average associated review score of 4.18 with a 12.70% low-review rate, while Bed Bath & Table recorded an average score of 3.97 with a 16.76% low-review rate. These differences do not establish that review performance caused differences in commercial growth, but they provide additional context when evaluating the quality of category performance.

Growth was not limited to a small number of categories. Sixty category groups increased their matched-period item sales value, while fourteen decreased. At the same time, very high percentage growth in some smaller categories should be interpreted cautiously because small starting values can produce unusually large growth rates without making a large contribution to total marketplace growth.

Product-level activity was also concentrated. Of 32,216 products represented in completed orders, approximately 5.65% generated 50% of completed item sales value and approximately 25.93% generated 80%. This suggests that commercial performance is concentrated not only across categories but also within the product assortment itself.

Taken together, the evidence indicates that marketplace growth was broad but uneven. A limited number of large categories generated a substantial share of commercial activity and growth, while individual categories differed in scale, growth rate, marketplace-share movement, and customer-review outcomes. This supports evaluating the category portfolio by **business role and performance pattern**, rather than relying only on simple sales rankings.

### Business Question

Which categories should be treated as established growth leaders, which large categories require closer investigation because they are losing share or showing weaker customer outcomes, and which smaller high-growth categories have sufficient scale to justify further commercial attention?


## 5. Seller and Supply Structure

Marketplace supply expanded substantially during the observed period, but seller activity remained highly uneven. Across completed orders, 2,970 sellers were active and collectively generated 13,221,498.11 in completed item sales value.

Seller participation increased markedly between the matched January–August periods. Active sellers increased from 1,153 in 2017 to 2,330 in 2018, representing growth of approximately 102.08%. Over the same comparison, average completed seller-order relationships increased from 19.27 to 23.01 per active seller, while average item sales value per seller increased from 2,596.23 to 3,097.91.

This indicates that marketplace expansion was supported not only by a larger seller base but also by higher average commercial activity among active sellers.

However, seller performance was strongly concentrated. Approximately 4.28% of active sellers generated 50% of completed item sales value, while approximately 17.95% generated 80%. This shows that a relatively small share of sellers accounted for a disproportionate amount of marketplace merchandise activity.

Seller concentration should not automatically be interpreted as a business problem. Uneven seller productivity is common in marketplace environments and may reflect differences in assortment, category participation, pricing, seller maturity, or customer demand. The available data does not establish whether the observed concentration creates operational or commercial risk.

Seller participation also changed considerably between matched periods. Of the sellers active in either period:

* 673 were active in both 2017 and 2018;
* 480 were active only in the 2017 matched period;
* 1,657 were active only in the 2018 matched period.

The available dataset does not establish whether sellers appearing in only one period were newly onboarded, inactive, temporarily absent, or permanently exited. These groups should therefore be treated as participation patterns rather than interpreted directly as seller acquisition or churn.

Supply was also geographically concentrated. São Paulo accounted for approximately 59.56% of active completed sellers and 64.36% of completed item sales value. Paraná and Minas Gerais were the next largest seller states, and the three largest seller states together represented approximately 78.79% of active sellers and 81.08% of completed item sales value.

This geographic concentration suggests that marketplace supply capacity was heavily centered in a small number of states. However, seller geography alone does not establish whether broader geographic diversification would improve marketplace performance, because the dataset does not contain seller operating costs, logistics capacity, inventory availability, or profitability.

Taken together, the evidence shows that marketplace growth was accompanied by substantial expansion in seller participation, while commercial activity remained concentrated among a relatively small share of sellers and within a few major seller states. The main business implication is therefore not that concentration is necessarily undesirable, but that **seller productivity and supply dependence are uneven and should be understood when evaluating marketplace resilience and future expansion.**

### Business Question

Which seller segments and supply regions contribute most to marketplace performance, and where should the business monitor concentration, seller participation, and productive supply capacity as the marketplace continues to grow?


## 6. Payment Behaviour — Supporting Commercial Context

Payment behaviour provides useful context for how customers completed marketplace transactions, but the available evidence does not indicate that payments should be treated as a primary strategic problem area.

Across the recorded order population, 99,440 orders had at least one payment record, while only one recorded order had no associated payment. The dataset contained 103,886 payment records with a total recorded payment value of 16,008,872.12.

Most paid orders used a single payment record. Approximately 2.98% of paid orders contained multiple payment records, while 2.26% used more than one payment method. Nearly all mixed-method orders combined credit cards with vouchers, indicating that multi-method payment behaviour existed but remained relatively uncommon.

Credit cards were the dominant payment method:

| Payment Method | Paid-Order Usage | Payment Value Share |
| -------------- | ---------------: | ------------------: |
| Credit card    |           76.94% |              78.34% |
| Boleto         |           19.90% |              17.92% |
| Voucher        |            3.89% |               2.37% |
| Debit card     |            1.54% |               1.36% |

Payment-method order usage is not additive because an order can contain more than one method.

Credit-card customers also made substantial use of installments. Approximately 66.85% of credit-card payment records used more than one installment. Average payment value increased across higher installment bands:

| Installment Band  | Share of Credit-Card Records | Avg Payment Value |
| ----------------- | ---------------------------: | ----------------: |
| 1 installment     |                       33.15% |             95.87 |
| 2–3 installments  |                       29.79% |            134.23 |
| 4–6 installments  |                       21.17% |            181.32 |
| 7–12 installments |                       15.65% |            333.29 |
| 13+ installments  |                        0.24% |            413.72 |

This shows a clear association between installment depth and recorded payment value. However, the analysis does not establish that installments caused customers to spend more. Higher-value purchases may simply be more likely to be divided into a greater number of installments.

Payment behaviour also changed somewhat over time. Credit cards remained dominant throughout the core analytical period, while boleto usage declined from approximately 24.63% of paid-order usage in January 2017 to 17.49% in August 2018. Debit-card usage remained relatively small but increased during the later months of the dataset.

These patterns suggest that payment flexibility was an established part of marketplace purchasing behaviour, particularly through credit-card installments. However, the dataset does not contain payment-processing costs, financing costs, merchant fees, credit risk, profitability, or customer financing preferences. It therefore cannot determine whether encouraging particular payment methods or installment structures would improve marketplace economics.

For this reason, payment behaviour is best treated as **supporting commercial context** rather than a primary strategic priority. It helps explain how customers transact and may provide useful segmentation or monitoring information, but the available evidence is insufficient to justify a major payment-policy recommendation.

### Business Question

How should payment-method and installment behaviour be monitored as supporting indicators of customer purchasing patterns, and what additional economic information would be required before making decisions about payment incentives or financing strategy?


## 7. Cross-Domain Business Priorities

The individual analytical themes do not carry equal business importance. To avoid treating every finding as an equal priority, the evidence was assessed qualitatively across four considerations:

* **Business magnitude** — how much marketplace activity is exposed to the pattern;
* **Customer or commercial relevance** — whether the pattern is materially connected to marketplace growth or customer experience;
* **Evidence strength** — how clearly the available data supports the interpretation;
* **Actionability** — whether the finding can reasonably guide further investigation, monitoring, or business experimentation.

This prioritization does not represent final recommendations. Its purpose is to determine which findings deserve the greatest attention in subsequent reporting and recommendation development.

| Business Theme                               | Business Relevance | Evidence Strength                                             | Priority Role |
| -------------------------------------------- | ------------------ | ------------------------------------------------------------- | ------------- |
| Delivery reliability and customer experience | High               | High for the observed pattern and review association          | Primary       |
| Growth model and customer behaviour          | High               | High for growth; moderate for repeat-behaviour interpretation | Primary       |
| Category portfolio and commercial mix        | High               | High                                                          | Primary       |
| Seller and supply structure                  | Moderate           | High descriptively; moderate strategically                    | Secondary     |
| Payment behaviour                            | Supporting         | High descriptively; limited strategically                     | Supporting    |

Three themes therefore carry the greatest decision relevance.

**Delivery reliability and customer experience** combines substantial order exposure, a material increase in late-delivery incidence, strong association with customer-review outcomes, and meaningful geographic variation.

**Growth model and customer behaviour** shows that marketplace expansion was primarily volume-driven while observed purchasing remained heavily concentrated among one-time customers. The growth pattern is strongly supported, while the implications for customer retention require greater caution.

**Category portfolio and commercial mix** is also a primary area because commercial scale and growth are unevenly distributed, and categories differ in growth contribution, marketplace-share movement, and associated customer outcomes.

Seller concentration remains important for understanding marketplace structure and productive supply dependence, but the available evidence does not establish that concentration itself is harmful. Payment behaviour provides useful commercial context but lacks the economic information required to support a major strategic intervention.

These priorities determine where the Power BI reporting layer should place the greatest emphasis. They do not prescribe specific actions; final recommendations will be developed only after evidence strength, limitations, and decision requirements are considered together.


## 8. Evidence Strength and Limitations

The business conclusions in this analysis are based on validated transactional data and independently reconciled SQL outputs. However, the strength of the evidence differs across themes, and several important limitations constrain how far the findings can be interpreted.

The purpose of documenting these limitations is not to weaken the analysis, but to distinguish clearly between:

* what the data directly establishes;
* what the analysis reasonably suggests;
* and what would require additional data or experimentation.

### 8.1 Growth Evidence Is Strong, but Long-Term Sustainability Cannot Be Established

The marketplace growth findings are supported by large transaction volumes and matched-period comparisons using January–August 2017 and January–August 2018.

The analysis provides strong evidence that:

* completed orders increased substantially;
* completed unique customers increased at a similar rate;
* completed item sales value increased substantially;
* average item sales value per order remained comparatively stable.

These results support the conclusion that observed growth was primarily scale-driven.

However, the dataset does not include:

* customer acquisition cost;
* marketing spend;
* channel attribution;
* marketplace profitability;
* contribution margin;
* or external market conditions.

The analysis therefore cannot determine whether the observed growth was economically efficient or sustainable.

**Evidence strength: High for the observed growth pattern; limited for profitability and long-term sustainability.**

---

### 8.2 Repeat Purchasing Is Directly Measured, but Retention Is Not

The completed-order data directly establishes that approximately 3.00% of observed completed customers placed more than one completed order.

However, this should not be interpreted as a formal retention rate.

Customers entered the dataset at different points in time and therefore had different opportunities to make another purchase. Customers first observed near the end of the available period had substantially less time to return than customers first observed earlier.

The dataset also does not contain:

* customer acquisition dates outside the observed marketplace history;
* marketing exposure;
* loyalty-program participation;
* customer intent;
* competitor activity;
* or customer-level profitability.

The analysis can therefore state confidently that **observed marketplace purchasing was dominated by one-time customers**, but it cannot establish the causes of this pattern or determine the effectiveness of any specific retention intervention.

**Evidence strength: High for observed purchase frequency; moderate for retention-related business interpretation.**

---

### 8.3 Delivery Reliability Has Strong Observational Evidence, but Causality Is Not Established

Delivery analysis is based on a large eligible delivered-order population and contains reliable information on:

* purchase dates;
* customer delivery dates;
* estimated delivery dates;
* delay severity;
* state-level delivery outcomes;
* and customer reviews.

The increase in late-delivery incidence and the deterioration in review outcomes across several delay bands provide strong evidence of an association between delivery reliability and customer experience.

However, the dataset does not identify all operational factors that could explain lateness.

It does not contain sufficiently detailed information on:

* logistics providers;
* transportation routes;
* warehouse capacity;
* fulfillment-process changes;
* inventory availability;
* weather or external disruption;
* or the logic used to generate estimated delivery dates.

The analysis therefore cannot determine whether increased lateness resulted primarily from operational performance, tighter delivery estimates, changing geographic mix, marketplace growth pressure, or another factor.

Similarly, poorer reviews among late orders should not be interpreted as proof that lateness alone caused customer dissatisfaction.

**Evidence strength: High for the observed association; moderate for causal or operational interpretation.**

---

### 8.4 Category Performance Is Well Supported, but Profitability Is Unknown

Category analysis is supported by detailed order-item data and allows reliable comparison of:

* completed item sales value;
* orders;
* items;
* products;
* marketplace share;
* matched-period growth;
* growth contribution;
* and associated review outcomes.

This provides strong evidence for differences in category commercial performance.

However, the dataset contains item price and freight value but does not contain:

* product cost;
* seller commission;
* marketplace fees;
* gross margin;
* promotional spending;
* return costs;
* or category profitability.

A category generating high item sales value therefore cannot automatically be described as highly profitable.

Similarly, strong percentage growth in a small category may reflect a low starting base rather than major commercial importance.

Category recommendations should therefore be based on a combination of scale, absolute growth contribution, share movement, and customer outcomes rather than on a single metric.

**Evidence strength: High for commercial activity and growth; limited for profitability.**

---

### 8.5 Seller Concentration Is Clearly Measured, but Seller Health Is Not

Seller-level analysis establishes that commercial activity is unevenly distributed across the marketplace.

The data reliably supports findings related to:

* active seller counts;
* seller-order relationships;
* item sales value;
* seller concentration;
* participation across matched periods;
* and seller geography.

However, the dataset does not contain seller-level information such as:

* seller operating costs;
* inventory levels;
* capacity;
* margins;
* contractual terms;
* seller satisfaction;
* onboarding date;
* seller acquisition source;
* or reasons for inactivity.

Sellers appearing only in one matched period therefore cannot be classified confidently as newly acquired or churned sellers.

Likewise, high seller concentration cannot by itself be interpreted as unhealthy marketplace dependence.

**Evidence strength: High for seller participation and concentration; moderate for strategic implications.**

---

### 8.6 Payment Behaviour Is Descriptively Reliable but Economically Incomplete

Payment records provide strong descriptive evidence regarding:

* payment-method usage;
* payment value;
* multi-payment behaviour;
* mixed payment methods;
* and installment patterns.

However, the dataset does not provide the financial information required to evaluate the economics of these behaviours.

Missing information includes:

* processing fees;
* financing costs;
* interest subsidies;
* credit risk;
* payment failure rates;
* fraud costs;
* or payment-method conversion effects.

The association between higher installment counts and larger payment values should therefore remain descriptive.

**Evidence strength: High for payment behaviour; limited for economic or policy conclusions.**

---

### 8.7 Review Outcomes Represent Order Experience, Not Product Ratings

Reviews in the dataset operate at the order level.

For category analysis, a representative order-level review was associated once with each distinct category appearing in the order. This provides a useful indication of the customer experience surrounding orders containing a particular category.

However, these review outcomes should not be interpreted as:

* individual product ratings;
* seller-specific ratings;
* or direct measures of product quality.

An order may contain multiple products, sellers, or experience factors that influence the customer's review.

**Evidence strength: High for order-level customer sentiment; limited for attributing that sentiment to individual products, categories, or sellers.**

---

### 8.8 Geographic Analysis Is Appropriate at State Level

Customer, seller, and delivery analysis uses state-level geography as the primary geographic level.

The raw geolocation dataset contains multiple records for individual ZIP prefixes and incomplete marketplace coverage. For this reason, raw geolocation coordinates were not joined directly into transactional analysis.

State-level comparisons are therefore more reliable for the current business questions.

Geographic differences should still be interpreted alongside the size of the underlying population. High rates in very small markets should not automatically receive the same business priority as similar rates affecting large order volumes.

**Evidence strength: High for state-level comparisons; limited for precise location-level operational conclusions.**

---

### 8.9 Observational Data Limits Causal Conclusions

The Olist dataset records historical marketplace activity. It does not represent a controlled experiment.

Consequently, the analysis can identify:

* trends;
* differences;
* associations;
* concentration;
* and potential areas for investigation.

It generally cannot establish that one observed factor directly caused another.

Statements such as:

> late orders have poorer review outcomes

are supported.

Statements such as:

> late delivery caused all of the reduction in review scores

are not.

Similarly, the dataset can identify potential opportunities for customer retention, category development, seller management, or delivery improvement, but the effectiveness of specific interventions would need to be evaluated through additional data and business experimentation.

---

### 8.10 Overall Evidence Assessment

The strongest evidence in the project concerns **what happened within the marketplace**:

* marketplace scale expanded rapidly;
* observed repeat purchasing was limited;
* delivery reliability against estimated dates weakened;
* late delivery was strongly associated with poorer review outcomes;
* category performance was uneven;
* seller activity was concentrated;
* credit cards dominated payment behaviour, while multi-installment use was common among credit-card payments.

The greatest uncertainty concerns **why these patterns occurred and which interventions would improve them**.

This distinction will guide the remaining project phases. Power BI will focus on communicating and exploring the strongest validated patterns, while final recommendations will be framed as evidence-backed priorities, investigations, or business experiments rather than unsupported causal prescriptions.


## 9. Decision Questions for Business Reporting

The purpose of the reporting layer is not to reproduce every metric calculated during the SQL analysis. It should help stakeholders monitor the strongest business patterns, compare relevant segments, identify exceptions, and decide where further investigation may be required.

The following decision questions are derived from the business priorities established in this analysis. They define what the Power BI phase should help users understand without prescribing the exact visual design in advance.

### 9.1 Marketplace Growth and Customer Behaviour

The reporting layer should help stakeholders understand the structure of marketplace growth and the role of customer purchasing behaviour.

Key questions include:

- How did completed orders, unique customers, and item sales value change over time?
- Did merchandise value grow primarily through transaction volume or through higher value per order?
- What proportion of observed customers completed more than one order?
- How much completed marketplace activity was generated by one-time versus repeat customers?

---

### 9.2 Delivery Reliability and Customer Experience

Key questions include:

- How did average delivery duration and late-delivery rate change over time?
- How do customer-review outcomes differ between on-time and increasingly late orders?
- Which states combine meaningful order volume with comparatively weak delivery reliability?
- How do delivery duration and performance against the estimated delivery date differ across major states?

---

### 9.3 Category Portfolio and Commercial Mix

Category reporting should help stakeholders evaluate categories by commercial role rather than through a single sales ranking.

Key questions include:

* Which categories currently generate the greatest completed item sales value?
* Which categories contribute most to marketplace growth in absolute terms?
* Which categories are gaining or losing marketplace share?
* Which large categories are growing more slowly than the marketplace overall?
* Which smaller categories are growing rapidly but still have limited commercial scale?
* How do associated review outcomes differ across commercially important categories?
* Which categories combine strong scale, growth, share gains, and comparatively strong customer outcomes?
* Which categories require closer investigation because commercial importance is accompanied by weaker growth, share loss, or customer-experience indicators?

These questions should support a **portfolio view of category performance**, rather than encourage decisions based only on percentage growth or current scale.

---

### 9.4 Seller and Supply Structure

Seller reporting should help stakeholders understand marketplace supply participation and concentration without implying that concentration is inherently problematic.

Key questions include:

* How many sellers are actively participating in completed marketplace activity?
* How has active seller participation changed over time?
* How concentrated is completed item sales value across sellers?
* What proportion of marketplace merchandise activity depends on the highest-contributing seller groups?
* How is productive seller supply distributed geographically?
* Which seller states contribute the greatest number of active sellers and merchandise activity?
* Is seller-base expansion accompanied by broader productive participation or continued concentration among a small seller subset?

The purpose is to support monitoring of **seller participation, productivity distribution, and supply dependence**, not to classify individual sellers as healthy or unhealthy without additional evidence.

---

### 9.5 Payment Behaviour as Supporting Context

Payment information should remain available where it helps explain customer purchasing behaviour, but it should not dominate the reporting layer.

Relevant questions include:

* Which payment methods are most commonly used?
* How is payment-method mix changing over time?
* How frequently are credit-card purchases made using installments?
* How does recorded payment value differ across installment bands?
* Are meaningful changes in payment behaviour occurring alongside broader marketplace growth?

These measures should remain descriptive unless additional economic information becomes available.

---

### 9.6 Executive-Level Questions

The highest-level report view should allow a business stakeholder to answer a small number of questions quickly:

1. **How did the marketplace grow during the observed period, and what contributed most to that growth?**
2. **Was marketplace growth accompanied by stronger customer purchasing depth, or was observed activity still dominated by one-time customers?**
3. **How did delivery reliability change, and how was it associated with customer experience?**
4. **Which categories are contributing most to commercial growth and which require closer attention?**
5. **How concentrated is productive seller supply, and where is that supply located?**
6. **Are there material exceptions that require deeper investigation?**

These questions should guide the reporting hierarchy from executive overview to deeper analytical views.

---

### 9.7 Reporting Design Principle

The Power BI phase should follow one governing rule:

> **A visual should be included only when it helps answer a defined business question, monitor an important condition, compare meaningful segments, or investigate a validated finding.**

The reporting layer should therefore avoid:

* reproducing every SQL output;
* displaying metrics solely because they are available;
* creating separate report pages for every analytical domain;
* presenting unsupported causal conclusions;
* or prioritizing visual complexity over business interpretation.

Detailed SQL outputs remain available as analytical evidence even when they are not included in the final dashboard.

The next phase should begin by designing a controlled Power BI semantic model that preserves the grain and metric definitions established earlier in the project. Exact report pages, measures, interactions, and visual choices should then be selected according to the decision questions defined above.
