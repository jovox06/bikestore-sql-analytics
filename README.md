# BikeStore Retail Performance System

A SQL Server (T-SQL) analytics project built on a bicycle retail database (BikeStores sample dataset). Raw transaction data is turned into ready-to-use KPIs through reusable **views** and parameterized **stored procedures**.

## Business Problem
Data was stored as raw transactions, which made it hard to quickly answer:
- How much revenue does each store generate, and how are sales trending over time?
- Which products and categories drive the most sales?
- Which products are low or out of stock in each store?
- How do staff and regions compare in orders and revenue?

## Database Schema
9 related tables: `Customers`, `Stores`, `Staffs`, `Orders`, `Order_items`, `Products`, `Categories`, `Brands`, `Stocks`, with primary/foreign keys and a self-referencing manager relationship in `Staffs`.

## What I Built

### 7 Views (always-available KPIs)
| View | Purpose |
|---|---|
| `vw_StoreSalesSummary` | Revenue, number of orders and average order value (AOV) per store |
| `vw_TopSellingProducts` | Products ranked by total sales (`DENSE_RANK`) |
| `vw_InventoryStatus` | Out of stock / low stock items per store |
| `vw_StaffPerformance` | Orders and revenue handled per staff member |
| `vw_RegionalTrends` | Revenue and orders by state and city |
| `vw_SalesByCategory` | Sales volume and revenue per product category |
| `vw_MonthlySalesTrend` | Monthly orders, volume and revenue |

### 5 Stored Procedures (parameterized analysis)
| Procedure | Input | Output |
|---|---|---|
| `sp_CalculateStoreKPI` | store ID | Revenue, total orders, sales volume |
| `sp_GenerateRestockList` | store ID | Low-stock items to restock |
| `sp_CompareSalesYearOverYear` | two years | Revenue comparison between years |
| `sp_GetCustomerProfile` | customer ID | Total spend, orders, most bought product |
| `sp_GetProductPerformance` | product ID | Units sold, orders, revenue, average selling price |

Revenue is calculated as `quantity * list_price * (1 - discount)`.

## Skills Demonstrated
Joins, aggregations (`GROUP BY`), window functions (`DENSE_RANK`), `CASE` logic, views, stored procedures with parameters, `BULK INSERT`, data modeling with keys and constraints.

## How to Run
1. Open `BikeStore.sql` in SQL Server Management Studio.
2. Update the CSV file paths in the `BULK INSERT` statements to your local folder.
3. Run the script, then query the views or execute the procedures, e.g.:
```sql
SELECT * FROM vw_StoreSalesSummary;
EXEC sp_CalculateStoreKPI @store_id = 3;
```

## Presentation
See `BikeStore_Presentation.pdf` for the business context and key findings (low stock items, weak stores, staff and regional differences).

## Author
Javohir Yunusov, Data Analyst | [LinkedIn](https://www.linkedin.com/in/javohir-yunusov-705424295)
