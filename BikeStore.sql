create database BikeStore
go
use BikeStore

CREATE TABLE Customers (
	customer_id int not null Primary Key identity(1, 1),
	first_name varchar(30),
	last_name varchar(30),
	phone varchar(20),
	email varchar(40),
	street varchar(50),
	city varchar(30),
	state varchar(30),
	zip_code varchar(10)
)

CREATE TABLE Stores (
	store_id int not null Primary Key,
	store_name varchar(30),
	phone varchar(20),
	email varchar(40),
	street varchar(50),
	city varchar(30),
	state varchar(30),
	zip_code varchar(10)
)


CREATE TABLE Staffs (
	staff_id int not null Primary Key Identity(1, 1),
	first_name varchar(30),
	last_name varchar(30),
	email varchar(40),
	phone varchar(20),
	active bit not null default 1,
	store_id int Foreign Key References Stores(store_id), 
	manager_id int Foreign Key References Staffs(staff_id)
)


CREATE TABLE Orders (
	order_id int not null Primary Key Identity(1, 1),
	customer_id int Foreign Key References Customers(customer_id),
	order_status varchar(20),
	order_date date,
	required_date date,
	shipped_date date,
	store_id int Foreign Key References Stores(store_id),
	staff_id int Foreign Key References Staffs(staff_id)
)

CREATE TABLE Categories (
	category_id int not null Primary Key,
	category_name varchar(30)
)

CREATE TABLE Brands (
	brand_id int not null Primary Key,
	brand_name varchar(30)
)

CREATE TABLE Products (
	product_id int not null Primary Key,
	product_name varchar(50),
	brand_id int Foreign Key References Brands(brand_id), 
	category_id int Foreign Key References Categories(category_id),
	model_year int,
	list_price decimal(12, 2)
) 


CREATE TABLE Stocks (
	store_id int Foreign Key References Stores(store_id),
	product_id int Foreign Key References Products(product_id),
	quantity int,
	PRIMARY KEY (store_id, product_id) 
)


CREATE TABLE Order_items (
	order_id int Foreign Key References Orders(order_id),
	item_id int,
	product_id int Foreign Key References Products(product_id),
	quantity int,
	list_price decimal(12, 2),
	discount decimal(4, 2),
	PRIMARY KEY (order_id, item_id) 
)

SET IDENTITY_INSERT Customers ON
BULK INSERT Customers
FROM 'C:\Data Analytics\SQL Project\csv-files-cleaned\customers.csv'
WITH (Firstrow=2, Fieldterminator=',', Rowterminator='\n', KEEPIDENTITY)
SET IDENTITY_INSERT Customers OFF
select * from Customers

BULK INSERT Stores
FROM 'C:\Data Analytics\SQL Project\csv-files-cleaned\stores.csv'
WITH (Firstrow=2, Fieldterminator=',', Rowterminator='\n')
SELECT * FROM Stores

BULK INSERT Categories
FROM 'C:\Data Analytics\SQL Project\csv-files-cleaned\categories.csv'
WITH (Firstrow=2, Fieldterminator=',', Rowterminator='\n')
SELECT * FROM Categories

BULK INSERT Brands
FROM 'C:\Data Analytics\SQL Project\csv-files-cleaned\brands.csv'
WITH (Firstrow=2, Fieldterminator=',', Rowterminator='\n')
SELECT * FROM Brands

SET IDENTITY_INSERT Staffs ON
BULK INSERT Staffs
FROM 'C:\Data Analytics\SQL Project\csv-files-cleaned\staffs.csv'
WITH (Firstrow=2, Fieldterminator=',', Rowterminator='\n', KEEPIDENTITY)
SET IDENTITY_INSERT Staffs OFF
SELECT * FROM Staffs

SET IDENTITY_INSERT Orders ON
BULK INSERT Orders
FROM 'C:\Data Analytics\SQL Project\csv-files-cleaned\orders.csv'
WITH (Firstrow=2, Fieldterminator=',', Rowterminator='\n', KEEPIDENTITY)
SET IDENTITY_INSERT Orders OFF
SELECT * FROM Orders

BULK INSERT Products
FROM 'C:\Data Analytics\SQL Project\csv-files-cleaned\products.csv'
WITH (Firstrow=2, Fieldterminator=',', Rowterminator='\n')
SELECT * FROM Products

BULK INSERT Stocks
FROM 'C:\Data Analytics\SQL Project\csv-files-cleaned\stocks.csv'
WITH (Firstrow=2, Fieldterminator=',', Rowterminator='\n')
SELECT * FROM Stocks

BULK INSERT Order_items
FROM 'C:\Data Analytics\SQL Project\csv-files-cleaned\order_items.csv'
WITH (Firstrow=2, Fieldterminator=',', Rowterminator='\n')
SELECT * FROM Order_items
-------------------------------------------------------------------------------------


--• 1 - vw_StoreSalesSummary: Revenue, #Orders, AOV per store
use BikeStore

CREATE VIEW vw_StoreSalesSummary as 
SELECT 
	o.store_id,
	CAST(SUM(it.quantity*it.list_price * (1-it.discount)) AS DECIMAL(10, 2)) as Revenue,
	count(distinct it.order_id) as Orders,
	CAST(SUM(it.quantity*it.list_price * (1-it.discount))/(count(distinct it.order_id)) as decimal (10, 2)) as AOV
FROM Order_items it
JOIN Orders o
on it.order_id=o.order_id
group by o.store_id


SELECT * FROM vw_StoreSalesSummary
order by store_id

--• 2- vw_TopSellingProducts: Rank products by total sales

CREATE VIEW vw_TopSellingProducts as 
SELECT
	p.product_id,
	p.product_name,
	cast(sum(oi.quantity*oi.list_price*(1-oi.discount)) as decimal (10, 2)) as Total_Sales,
	dense_rank() over(order by sum(oi.quantity*oi.list_price*(1-oi.discount)) desc) as Sales_Rank
FROM Order_items oi
join Products p
on oi.product_id=p.product_id
group by p.product_id, p.product_name

SELECT * FROM vw_TopSellingProducts


--• 3 -	vw_InventoryStatus: Items running low on stock

CREATE VIEW vw_InventoryStatus as
SELECT 
	s.store_id,
	s.product_id,
	p.product_name,
	s.quantity,
	case 
		when s.quantity=0 then 'Out of stock'
		when s.quantity<10 then 'Low stock'
		end as Stock_status
FROM Stocks s 
join Products p
on s.product_id=p.product_id

SELECT * FROM vw_InventoryStatus
ORDER BY store_id, quantity


--• 4 -	vw_StaffPerformance: Orders and revenue handled per staff

CREATE VIEW vw_StaffPerformance as 
SELECT 
	s.staff_id,
	s.first_name,
	s.last_name,
	count(distinct o.order_id) as Tottal_orders,
	sum(it.quantity*it.list_price*(1-it.discount)) as Revenue
FROM Orders o
join Order_items it
on o.order_id=it.order_id
join Staffs s
on o.staff_id=s.staff_id
group by s.staff_id, s.first_name, s.last_name

SELECT * FROM vw_StaffPerformance
ORDER BY Revenue DESC


--• 5 -	vw_RegionalTrends: Revenue by city or region

CREATE VIEW vw_RegionalTrends AS 
SELECT
	s.state,
	s.city,
	count(distinct o.order_id) as Total_orders,
	sum(it.quantity*it.list_price*(1-it.discount)) as Revenue
FROM Stores s
join Orders o
on s.store_id=o.store_id
join Order_items it
on o.order_id=it.order_id
group by s.state, s.city

SELECT * FROM vw_RegionalTrends
ORDER BY Revenue DESC


--•	6 - vw_SalesByCategory: Sales volume and revenue -(margin) by product category

CREATE VIEW vw_SalesByCategory AS
SELECT 
	c.category_id,
	c.category_name,
	sum(it.quantity) as Sales_volume,
	sum(it.quantity*it.list_price*(1-it.discount)) as Revenue
FROM Products p
join Categories c
on p.category_id=c.category_id
join Order_items it
on p.product_id=it.product_id
group by c.category_id, c.category_name

SELECT * FROM vw_SalesByCategory
ORDER BY Revenue DESC


-- 7 - vw_MonthlySalesTrend, monthly sales

CREATE VIEW vw_MonthlySalesTrend as
SELECT
    year(o.order_date) as Sales_year,
    month(o.order_date) as Sales_month,
    count(distinct o.order_id) as Total_orders,
    sum(it.quantity) as Sales_volume,
    sum(it.quantity*it.list_price*(1-it.discount)) as Revenue
FROM Orders o
join Order_items it
on o.order_id=it.order_id
group by year(o.order_date), month(o.order_date)


SELECT * FROM vw_MonthlySalesTrend
ORDER BY Sales_year, Sales_month


--• 8 - sp_CalculateStoreKPI: Input store ID, return full KPI breakdown

CREATE PROCEDURE sp_CalculateStoreKPI @store_id int 
as begin

SELECT 
	o.store_id,
	sum(it.quantity*it.list_price*(1-it.discount)) as Revenue,
	count(distinct o.order_id) as Total_orders,
	sum(it.quantity) as sales_volume
FROM Orders o
join Order_items it
on o.order_id=it.order_id
where o.store_id=@store_id
group by o.store_id

end 

exec sp_CalculateStoreKPI @store_id=3


--• 9 -	sp_GenerateRestockList: Output low-stock items per store

CREATE PROCEDURE sp_GenerateRestockList @store_id int
as begin 

SELECT 
	s.store_id,
	s.product_id,
	p.product_name,
	s.quantity,
	case 
		when s.quantity=0 then 'Out of stock'
		when s.quantity<10 then 'Low stock'
		else 'High stock' end as Stock_status
FROM Stocks s 
join Products p
on s.product_id=p.product_id
where s.store_id=@store_id
and s.quantity<10

end

exec sp_GenerateRestockList @store_id=1


--• 10 -	sp_CompareSalesYearOverYear: Compare sales between two years

CREATE PROCEDURE sp_CompareSalesYearOverYear  
				@year1 int, @year2 int
as begin 

SELECT 
	year(o.order_date) as sales_year,
	sum(it.quantity*it.list_price*(1-it.discount)) as Revenue
FROM Orders o
join Order_items it
on o.order_id=it.order_id
where year(o.order_date) in (@year1, @year2)
group by year(o.order_date)

end

exec sp_CompareSalesYearOverYear 
@year1=2016, @year2=2018


--• 11 - sp_GetCustomerProfile: Returns total spend, orders, and most bought items

CREATE PROCEDURE sp_GetCustomerProfile @customer_id int
as begin 

SELECT 
	o.customer_id,
	c.first_name,
	c.last_name,
	sum(it.quantity*it.list_price*(1-it.discount)) as Total_spend,
	count(distinct o.order_id) as Total_orders
FROM Customers c
join Orders o
on c.customer_id=o.customer_id
join Order_items it
on o.order_id=it.order_id
where o.customer_id=@customer_id
group by o.customer_id, c.first_name, c.last_name

SELECT top 1
	p.product_name,
	sum(it.quantity) as Total_quantity
FROM Orders o
join Order_items it
on o.order_id=it.order_id
join Products p
on it.product_id=p.product_id
where o.customer_id=@customer_id
group by p.product_name
order by Total_quantity desc

end

exec sp_GetCustomerProfile @customer_id=250


-- 12 - sp_GetProductPerformance, 

CREATE PROCEDURE sp_GetProductPerformance @product_id INT
as begin

SELECT
    p.product_id,
    p.product_name,
    sum(it.quantity) as Units_sold,
    count(distinct it.order_id) as Total_orders,
    sum(it.quantity*it.list_price * (1-it.discount)) as Revenue,
    avg(it.list_price*(1-it.discount)) as Avg_selling_price
FROM Products p
join Order_items it
on p.product_id=it.product_id
where p.product_id=@product_id
group by p.product_id, p.product_name;

end

exec sp_GetProductPerformance @product_id = 10