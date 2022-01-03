USE gbc_superstore;
CREATE TABLE `Orders` (
  `Row ID` int,
  `Order ID` varchar(20),
  `Order Date` varchar(20),
  `Ship Date` varchar(20),
  `Ship Mode` varchar(20),
  `Customer ID` varchar(20),
  `Customer Name` varchar(50),
  `Segment` varchar(20),
  `Country/Region` varchar(20),
  `City` varchar(20),
  `State` varchar(20),
  `Postal Code` varchar(20),
  `Region` varchar(20),
  `Product ID` varchar(20),
  `Category` varchar(20),
  `Sub-Category` varchar(20),
  `Product Name` varchar(150),
  `Sales` float,
  `Quantity` int,
  `Discount` float,
  `Profit` decimal(8,4),
  PRIMARY KEY (`Row ID`)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Superstore.csv' 
INTO TABLE Orders
FIELDS terminated by ','
optionally enclosed by '"'
ignore 1 rows
;

ALTER TABLE Orders RENAME COLUMN `Order ID` TO Order_ID;
ALTER TABLE Orders RENAME COLUMN `Order Date` TO Order_Date;
ALTER TABLE Orders RENAME COLUMN `Ship Date` TO Ship_Date;
ALTER TABLE Orders RENAME COLUMN `Ship Mode` TO Ship_Mode;
ALTER TABLE Orders RENAME COLUMN `Customer ID` TO Customer_ID;
ALTER TABLE Orders RENAME COLUMN `Customer Name` TO Customer_Name;
ALTER TABLE Orders RENAME COLUMN `Country/Region` TO Country_Region;
ALTER TABLE Orders RENAME COLUMN `Postal Code` TO Postal_Code;
ALTER TABLE Orders RENAME COLUMN `Product ID` TO Product_ID;
ALTER TABLE Orders RENAME COLUMN `Product Name` TO Product_Name;
ALTER TABLE Orders RENAME COLUMN `Sub-Category` TO Subcategory;



UPDATE Orders
   SET Order_Date = DATE_FORMAT(STR_TO_DATE(Order_Date,'%m/%d/%Y'), '%Y-%m-%d');
UPDATE Orders
	SET Ship_Date = DATE_FORMAT(STR_TO_DATE(Ship_Date,'%m/%d/%Y'), '%Y-%m-%d');

ALTER TABLE Orders ADD new_Order_Date DATE;
UPDATE Orders 
	SET new_Order_Date = Order_Date;
    
ALTER TABLE Orders ADD new_Ship_Date DATE;
UPDATE Orders 
	SET new_Ship_Date = Ship_Date;

ALTER TABLE Orders DROP Order_Date, DROP Ship_Date;
ALTER TABLE Orders RENAME COLUMN new_Order_Date TO Order_Date, RENAME COLUMN new_Ship_Date TO Ship_Date;


CREATE TABLE `Returns` (
  `Returned` varchar(3),
  `Order ID` varchar(20)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Returns.csv' 
INTO TABLE `Returns`
FIELDS terminated by ','
optionally enclosed by '"'
ignore 1 rows
;

ALTER TABLE Returns RENAME COLUMN `Order ID` TO Order_ID;


#Entity tables

CREATE TABLE `Customer` (
   Customer_ID varchar(20),
   Customer_Name varchar(50),
   Segment varchar(20),
   Country_Region varchar(20),
   City varchar(20),
   State varchar(20),
   Postal_Code varchar(20),
   Region varchar(20)
   )AS SELECT DISTINCT Customer_ID, Customer_Name, Segment, Country_Region, City, State, Postal_Code, Region FROM Orders 
   GROUP BY Customer_ID;
ALTER TABLE Customer ADD PRIMARY KEY (Customer_ID);


CREATE TABLE `Order` (
  Customer_ID varchar(20),
  Order_ID varchar(20),
  Order_Date date,
  Product_ID varchar(20),
  Sales float
  ) AS SELECT DISTINCT Customer_ID, Order_ID, Order_Date, Product_ID, Sales FROM Orders 
   GROUP BY Order_ID;
ALTER TABLE `Order` ADD PRIMARY KEY (Order_ID);
ALTER TABLE `Order` ADD FOREIGN KEY (Customer_ID) REFERENCES `Customer`(Customer_ID);

CREATE TABLE `Product` (
  Product_ID varchar(20),
  Product_Name varchar(150),
  Category varchar(20),
  Subcategory varchar(20),
  Quantity int
  ) AS SELECT DISTINCT Product_ID, Product_Name, Category, Subcategory, Quantity FROM Orders 
   GROUP BY Product_ID;
   
SELECT * FROM Product;
ALTER TABLE `Product` ADD PRIMARY KEY (Product_ID);
ALTER TABLE `Order` ADD FOREIGN KEY (Product_ID) REFERENCES `Product`(Product_ID);


CREATE TABLE `Shipping` (
  Customer_ID varchar(20),
  Order_ID varchar(20),
  Ship_Date date,
  Ship_Mode varchar(20)
) AS SELECT DISTINCT Customer_ID, Order_ID, Ship_Date, Ship_Mode, Quantity FROM Orders 
   GROUP BY Customer_ID, Order_ID;
ALTER TABLE `Shipping` ADD PRIMARY KEY (Customer_ID, Order_ID);
ALTER TABLE `Shipping` ADD FOREIGN KEY (Order_ID) REFERENCES `Order`(Order_ID);
ALTER TABLE `Shipping` ADD FOREIGN KEY (Customer_ID) REFERENCES `Customer`(Customer_ID);


CREATE TABLE `Sales` (
  Sales float,
  Discount float,
  Profit decimal(8,4),
  Order_ID varchar(20),
  Product_ID varchar(20)
) AS SELECT Sales, Discount, Profit, Order_ID, Product_ID FROM Orders;
ALTER TABLE `Sales` ADD FOREIGN KEY (Order_ID) REFERENCES `Order`(Order_ID);
ALTER TABLE `Sales` ADD FOREIGN KEY (Product_ID) REFERENCES `Product`(Product_ID);


CREATE TABLE `Return` (
  Sales float,
  Order_ID varchar(20),
  Returned varchar(20)
) AS SELECT Sales, R.Order_ID, Returned FROM Returns R
INNER JOIN Orders O ON  R.Order_ID = O.Order_ID
GROUP BY Sales;
ALTER TABLE `Return` ADD FOREIGN KEY (Order_ID) REFERENCES `Order`(Order_ID);

SELECT * FROM Orders;
SELECT * FROM Returns;

SELECT * FROM `Order`;
SELECT * FROM Product;
SELECT * FROM Shipping;
SELECT * FROM Sales;
SELECT * FROM `Return`;

SELECT * FROM Orders WHERE Postal_Code;

SELECT C.Customer_ID, Customer_Name, City, Profit FROM Customer C
INNER JOIN `Order` O ON C.Customer_ID = O.Customer_ID 
JOIN Sales S ON O.Order_ID = S.Order_ID WHERE S.Profit > 1000
ORDER BY Profit DESC;



SELECT Category, Subcategory, SUM(Sales) AS Total_Sales FROM Product P
JOIN `Order` O ON P.Product_ID = O.Product_ID 
GROUP BY SubCategory
Order BY Sales DESC;


SELECT Product_Name, Category, SUM(Quantity) As Total_Quantity, SUM(S.Sales) AS Sales  FROM `Order` O
JOIN Product P ON P.Product_ID = O.Product_ID
JOIN Customer C ON C.Customer_ID = O.Customer_ID
JOIN Sales S ON S.Order_ID = O.Order_ID
Order By Sales DESC;




# Operations Report Table 1

SELECT Category, Subcategory, SUM(Quantity) AS Quantity, ROUND(SUM(S.Sales), 2) AS Sales FROM  Product P
JOIN Sales S ON P.Product_ID = S.Product_ID
JOIN `Order` O ON O.Product_ID = S.Product_ID
WHERE Order_Date BETWEEN "2017-12-01" AND "2017-12-31"
GROUP BY Subcategory
ORDER BY Sales DESC;


# Operations Report Table 2
SELECT Product_Name, Subcategory, SUM(Quantity) AS Quantity, ROUND(SUM(S.Sales), 2) AS Sales FROM  Product P
JOIN Sales S ON P.Product_ID = S.Product_ID
JOIN `Order` O ON O.Product_ID = S.Product_ID
WHERE Order_Date BETWEEN "2017-12-01" AND "2017-12-31"
GROUP BY Product_Name, Subcategory
ORDER BY Quantity DESC;

# Operations Report Table 3
SELECT State, ROUND(SUM(S.Sales), 2) AS Sales, ROUND(SUM(Profit), 2) AS Profit FROM  Product P
JOIN Sales S ON P.Product_ID = S.Product_ID
JOIN `Order` O ON O.Product_ID = S.Product_ID
JOIN Customer C ON C.Customer_ID = O.Customer_ID
WHERE Order_Date BETWEEN "2017-12-01" AND "2017-12-31"
GROUP BY State
ORDER BY Sales DESC;


# Operations Report Table 4
SELECT Region, State, Count(O.Order_ID) AS Orders, COUNT(Ship_Mode) AS Shipments, ROUND(SUM(S.Sales), 2) AS Sales FROM  Shipping Sh
JOIN Sales S ON S.Order_ID = Sh.Order_ID
JOIN `Order` O ON O.Order_ID = Sh.Order_ID
JOIN Customer C ON C.Customer_ID = Sh.Customer_ID
WHERE Order_Date BETWEEN "2017-12-01" AND "2017-12-31"
GROUP BY State
ORDER BY Orders DESC;


# Excutive Report Table 1

SELECT Category, Subcategory, SUM(Quantity) AS Quantity, ROUND(SUM(S.Sales), 2) AS 2020_Sales FROM  Product P
JOIN Sales S ON P.Product_ID = S.Product_ID
JOIN `Order` O ON O.Product_ID = S.Product_ID
WHERE Order_Date BETWEEN "2020-01-01" AND "2020-12-31"
GROUP BY Subcategory
ORDER BY Quantity DESC;


# Excutive Report Table 2
SELECT Region, ROUND(SUM(S.Sales), 0) AS 2020_Sales, ROUND(SUM(Profit), 2) AS 2020_Profit FROM `Order` O
JOIN Sales S ON S.Order_ID = O.Order_ID
JOIN Customer C ON C.Customer_ID = O.Customer_ID
WHERE Order_Date BETWEEN "2020-01-01" AND "2020-12-31"
GROUP BY Region
ORDER BY 2020_Profit DESC;


# Excutive Report Table 3
SELECT State, ROUND(SUM(S.Sales), 2) AS 2020_Sales, ROUND(SUM(Profit), 2) AS 2020_Profit FROM `Order` O
JOIN Sales S ON S.Order_ID = O.Order_ID
JOIN Customer C ON C.Customer_ID = O.Customer_ID
WHERE Order_Date BETWEEN "2020-01-01" AND "2020-12-31"
GROUP BY State
ORDER BY 2020_Profit DESC;


# Excutive Report Table 4
SELECT Region, Count(O.Order_ID) AS Orders, ROUND(SUM(S.Sales), 2) AS 2020_Sales, ROUND(SUM(Profit), 2) AS 2020_Profit FROM `Order` O
JOIN Sales S ON S.Order_ID = O.Order_ID
JOIN Customer C ON C.Customer_ID = O.Customer_ID
WHERE Order_Date BETWEEN "2020-01-01" AND "2020-12-31"
GROUP BY Region
ORDER BY Orders DESC;

# Excutive Report Table 5
SELECT State, Count(O.Order_ID) AS Orders, ROUND(SUM(S.Sales), 2) AS 2020_Sales, ROUND(SUM(Profit), 2) AS 2020_Profit FROM `Order` O
JOIN Sales S ON S.Order_ID = O.Order_ID
JOIN Customer C ON C.Customer_ID = O.Customer_ID
WHERE Order_Date BETWEEN "2020-01-01" AND "2020-12-31"
GROUP BY State
ORDER BY Orders DESC;


# Executive Report Table 6
SELECT Segment, Count(O.Order_ID) AS Orders, ROUND(SUM(S.Sales), 2) AS 2020_Sales, ROUND(SUM(Profit), 2) AS 2020_Profit FROM `Order` O
JOIN Sales S ON S.Order_ID = O.Order_ID
JOIN Customer C ON C.Customer_ID = O.Customer_ID
WHERE Order_Date BETWEEN "2020-01-01" AND "2020-12-31"
GROUP BY Segment
ORDER BY 2020_Profit DESC;





# Executive Report Comparison Table 2017-2020 Regions Profit

SELECT D.Region, 2020_Profit, 2019_Profit, 2018_Profit, 2017_Profit
FROM 
	(SELECT Region, ROUND(SUM(Profit), 2) AS 2017_Profit
	FROM `Order` O
	JOIN Sales S ON S.Order_ID = O.Order_ID
	JOIN Customer C ON C.Customer_ID = O.Customer_ID
	WHERE Order_Date BETWEEN "2017-01-01" AND "2017-12-31"
	GROUP BY Region
	ORDER BY 2017_Profit DESC) AS A
JOIN 
	( SELECT Region, ROUND(SUM(Profit), 2) AS 2018_Profit
	FROM `Order` O
	JOIN Sales S ON S.Order_ID = O.Order_ID
	JOIN Customer C ON C.Customer_ID = O.Customer_ID
	WHERE Order_Date BETWEEN "2018-01-01" AND "2018-12-31"
	GROUP BY Region
	ORDER BY 2018_Profit DESC) AS B

ON A.Region = B.Region

JOIN 
	( SELECT Region, ROUND(SUM(Profit), 2) AS 2019_Profit
	FROM `Order` O
	JOIN Sales S ON S.Order_ID = O.Order_ID
	JOIN Customer C ON C.Customer_ID = O.Customer_ID
	WHERE Order_Date BETWEEN "2019-01-01" AND "2019-12-31"
	GROUP BY Region
	ORDER BY 2019_Profit DESC) AS C

ON A.Region = C.Region

JOIN 
	( SELECT Region, ROUND(SUM(Profit), 2) AS 2020_Profit
	FROM `Order` O
	JOIN Sales S ON S.Order_ID = O.Order_ID
	JOIN Customer C ON C.Customer_ID = O.Customer_ID
	WHERE Order_Date BETWEEN "2020-01-01" AND "2020-12-31"
	GROUP BY Region
	ORDER BY 2020_Profit DESC) AS D

ON A.Region = D.Region;



# Executive Report Comparison Table 2017-2020 Profit

SELECT D.State, 2020_Profit, 2019_Profit, 2018_Profit, 2017_Profit
FROM 
	(SELECT State, ROUND(SUM(Profit), 2) AS 2017_Profit
	FROM `Order` O
	JOIN Sales S ON S.Order_ID = O.Order_ID
	JOIN Customer C ON C.Customer_ID = O.Customer_ID
	WHERE Order_Date BETWEEN "2017-01-01" AND "2017-12-31"
	GROUP BY State
	ORDER BY 2017_Profit DESC) AS A
JOIN 
	( SELECT State, ROUND(SUM(Profit), 2) AS 2018_Profit
	FROM `Order` O
	JOIN Sales S ON S.Order_ID = O.Order_ID
	JOIN Customer C ON C.Customer_ID = O.Customer_ID
	WHERE Order_Date BETWEEN "2018-01-01" AND "2018-12-31"
	GROUP BY State
	ORDER BY 2018_Profit DESC) AS B

ON A.State = B.State

JOIN 
	( SELECT State, ROUND(SUM(Profit), 2) AS 2019_Profit
	FROM `Order` O
	JOIN Sales S ON S.Order_ID = O.Order_ID
	JOIN Customer C ON C.Customer_ID = O.Customer_ID
	WHERE Order_Date BETWEEN "2019-01-01" AND "2019-12-31"
	GROUP BY State
	ORDER BY 2019_Profit DESC) AS C

ON A.State = C.State

JOIN 
	( SELECT State, ROUND(SUM(Profit), 2) AS 2020_Profit
	FROM `Order` O
	JOIN Sales S ON S.Order_ID = O.Order_ID
	JOIN Customer C ON C.Customer_ID = O.Customer_ID
	WHERE Order_Date BETWEEN "2020-01-01" AND "2020-12-31"
	GROUP BY State
	ORDER BY 2020_Profit DESC) AS D

ON A.State = D.State;




# Executive Report Comparison table Product Subcategory quantities 2017-2020

SELECT D.Subcategory, 2020_Quantity, 2019_Quantity, 2018_Quantity, 2017_Quantity
FROM 
	(SELECT Subcategory, SUM(Quantity) AS 2017_Quantity
	FROM `Order` O
	JOIN Product P ON P.Product_ID = O.Product_ID
	WHERE Order_Date BETWEEN "2017-01-01" AND "2017-12-31"
	GROUP BY Subcategory
	ORDER BY 2017_Quantity DESC) AS A
JOIN 
	(SELECT Subcategory, SUM(Quantity) AS 2018_Quantity
	FROM `Order` O
	JOIN Product P ON P.Product_ID = O.Product_ID
	WHERE Order_Date BETWEEN "2018-01-01" AND "2018-12-31"
	GROUP BY Subcategory
	ORDER BY 2018_Quantity DESC) AS B

ON A.Subcategory = B.Subcategory

JOIN 
	(SELECT Subcategory, SUM(Quantity) AS 2019_Quantity
	FROM `Order` O
	JOIN Product P ON P.Product_ID = O.Product_ID
	WHERE Order_Date BETWEEN "2019-01-01" AND "2019-12-31"
	GROUP BY Subcategory
	ORDER BY 2019_Quantity DESC) AS C

ON A.Subcategory = C.Subcategory

JOIN 
	(SELECT Subcategory, SUM(Quantity) AS 2020_Quantity
	FROM `Order` O
	JOIN Product P ON P.Product_ID = O.Product_ID
	WHERE Order_Date BETWEEN "2020-01-01" AND "2020-12-31"
	GROUP BY Subcategory
	ORDER BY 2020_Quantity DESC) AS D

ON A.Subcategory = D.Subcategory