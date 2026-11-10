# Cart-Abandonment-Analysis
## 1. Project Overview
Cart Abandonment Analysis is an e-commerce data analytics project focused on understanding customer behaviour during the online shopping checkout process.
The project identifies where customers drop off during checkout and explores factors associated with cart abandonment.

## 2. Business Problem
Customers add products to their carts but do not always complete their purchases. This leads to lost sales opportunities.
**Key Business Question:**
Where in the checkout flow are customers dropping off most, and what should the product team fix first?

## 3. Project Objectives
- Analyse customer checkout behaviour.
- Identify the stages with the highest drop-off.
- Compare abandonment across device types.
- Analyse traffic sources, product categories and locations.
- Evaluate payment method completion.
- Understand the relationship between discounts and purchases.
- Provide data-driven business recommendations.

## 4. Tools & Technologies
| Tool | Purpose |
|---|---|
| Excel | Data Inspection |
| Power Query | Data Cleaning |
| SQL Server | Data Storage |
| SQL | Business Analysis |
| Power BI | Dashboard Development |

## 5. Dataset Description
The project uses three datasets:
### Customer Sessions
- Session ID
- Customer ID
- Date and Time
- Device Type
- Traffic Source
- Location
### Cart Product Activity
- Session ID
- Product ID
- Product Category
- Quantity
- Product Price
- Cart Value
- Discount
- Add to Cart Time
### Checkout Activity
- Session ID
- Checkout Started
- Payment Started
- Payment Method
- Purchase Completed
- Checkout Time
- Purchase Time
Dataset period: 2025.

## 6. Data Cleaning
Data cleaning was performed using Excel Power Query.
- Inspected data types and data quality.
- Handled missing location values.
- Reviewed missing values.
- Checked duplicate records.
- Validated session identifiers.
- Prepared cleaned datasets for SQL Server.

## 7. SQL Analysis – 15 Business Questions
1. Checkout stage session counts.
2. Highest checkout drop-off stage.
3. Device-wise cart abandonment.
4. Category-wise abandonment.
5. Product-wise abandonment.
6. New vs returning customer abandonment.
7. Average cart value of abandoned sessions.
8. Time-of-day abandonment.
9. Traffic source abandonment.
10. Daily abandonment trend.
11. Monthly abandonment trend.
12. Payment method completion.
13. Discount impact on purchase completion.
14. Location-wise abandonment.
15. Device and traffic source combination analysis.

## 8. Key Findings
### Checkout Funnel
| Stage | Sessions |
| Checkout Started | 16,294 |
| Payment Started | 13,520 |
| Purchase Completed | 10,598 |
- Checkout to Payment Drop-off: 17.03%
- Payment to Purchase Drop-off: 21.61%
### Device-wise Abandonment
| Device | Abandonment Rate |
| Mobile | 62.56% |
| Desktop | 62.26% |
| Tablet | 60.97% |
Mobile has the highest abandonment rate.
### Traffic Source Analysis
| Traffic Source | Abandonment Rate |
| Unknown | 68.35% |
| Organic Search | 63.49% |
| Paid Search | 62.57% |
| Direct | 62.09% |
| Social Media | 61.98% |
| Referral | 61.08% |
| Email | 60.68% |
Unknown traffic has a high abandonment rate, but the sample size is only 79 sessions.
### Discount Analysis
- No Discount Completion Rate: 37.99%
- Discount Applied Completion Rate: 37.57%
Discounts did not show a higher observed completion rate.
### Time Analysis
Morning recorded approximately 4.3K abandoned sessions, the highest count among the time periods.

## 9. Business Recommendations
1. Improve the payment process and investigate payment failures.
2. Optimise the mobile checkout experience.
3. Improve traffic source tracking.
4. Evaluate discount campaigns through testing.
5. Investigate morning traffic and checkout performance.

## 10. Power BI Dashboard
The interactive dashboard includes:
- KPI Cards
- Checkout Funnel
- Monthly Abandonment Trend
- Device Distribution
- Payment Method Completion
- Traffic Source Abandonment
- Time-of-Day Analysis
- Product Category Analysis
- Location Analysis
- Interactive Filters and Slicers
- Bookmark-based Navigation
- Key Insights and Recommendations

## 11. Conclusion
This project demonstrates an end-to-end data analytics workflow using Excel, Power Query, SQL Server and Power BI.
The analysis identifies the payment stage as the major area for checkout improvement. Mobile experience and traffic source tracking are additional areas for investigation.
The dashboard helps stakeholders understand customer behaviour and make data-driven business decisions.

---

**Project Name:** Cart Abandonment Analysis

**Domain:** E-commerce Analytics

**Role:** Data Analyst Portfolio Project

**Tools:** Excel, Power Query, SQL Server, SQL, Power BI
