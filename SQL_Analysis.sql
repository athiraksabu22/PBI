SELECT 
    Product_Category, 
    SUM(Revenue) AS TotalRevenue
FROM 
    dbo.Dataset
GROUP BY 
    Product_Category
ORDER BY 
    TotalRevenue DESC;


-----2.What is the average order value for premium vs regular users?
WITH CustomerSpending AS (
    SELECT 
        CustomerID,
        SUM(Revenue) AS TotalRevenue
    FROM 
        dbo.Dataset
    GROUP BY 
        CustomerID
),
-- Add semicolon before second CTE
UserCategory AS (
    SELECT 
        CustomerID,
        CASE 
            WHEN TotalRevenue > 10000 THEN 'Premium'
            ELSE 'Regular'
        END AS UserType
    FROM 
        CustomerSpending
),
OrderRevenue AS (
    SELECT 
        OrderID,
        CustomerID,
        SUM(Revenue) AS OrderValue
    FROM 
        dbo.Dataset
    GROUP BY 
        OrderID, CustomerID
)
SELECT 
    UC.UserType,
    AVG(ORR.OrderValue) AS AvgOrderValue
FROM 
    OrderRevenue ORR
JOIN 
    UserCategory UC ON ORR.CustomerID = UC.CustomerID
GROUP BY 
    UC.UserType;

---3.What is the count of returned orders per campaign?
SELECT 
    D.Campaign,
    SUM(CASE WHEN D.DeliveryStatus = 'Returned' THEN D.Quantity ELSE 0 END) AS ReturnedQuantity
FROM 
    dbo.Dataset AS D
GROUP BY 
    D.Campaign; 

 ----4. Products with the highest return rates

SELECT 
    D.Product_Name,
    SUM(D.Quantity) AS TotalQuantitySold,
    SUM(CASE WHEN D.Returned_Order_Count = 1 THEN D.Quantity ELSE 0 END) AS ReturnedQuantity,
    CAST(
        SUM(CASE WHEN D.Returned_Order_Count = 1 THEN D.Quantity ELSE 0 END) * 100.0 / 
        NULLIF(SUM(D.Quantity), 0)
        AS DECIMAL(5,2)
    ) AS ReturnRatePercentage
FROM 
    dbo.Dataset AS D

GROUP BY 
    D.Product_Name
ORDER BY 
    ReturnRatePercentage DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;


--5. Monthly revenue trend
SELECT 
    DATENAME(MONTH, D.OrderDate) AS MonthName,  -- Get full month name
    SUM(D.Revenue) AS TotalRevenue
FROM 
    dbo.Dataset AS D
GROUP BY 
    DATENAME(MONTH, D.OrderDate), MONTH(D.OrderDate)  -- Group by month name and month number
ORDER BY 
    MONTH(D.OrderDate);  -- Order by the month number

---6.Which customers have the highest lifetime value? (Calculated based on the highest net revenue)
SELECT 
    D.CustomerID,
    D.Customer_Name,
    COUNT(*) AS TotalPurchases,
    SUM(D.Revenue) AS TotalRevenue,
    SUM(CASE WHEN D.Returned_Order_Count = 0 THEN D.Revenue ELSE 0 END) AS NetRevenue,
    SUM(CASE WHEN D.Returned_Order_Count = 1 THEN 1 ELSE 0 END) AS NumberOfReturns
FROM 
    dbo.Dataset AS D

GROUP BY 
    D.CustomerID, D.Customer_Name
ORDER BY 
    NetRevenue DESC;

---7.What is the average discount given in each region?
SELECT 
    D.Customer_region,
	AVG(D.Discount)
FROM 
     dbo.Dataset AS D

GROUP BY 
    D.Customer_region

---8.Which campaigns generated more than 100 refunds?

SELECT 
    D.Campaign,
    COUNT(*) AS ReturnCount
FROM 
    dbo.Dataset AS D
WHERE 
    D.Returned_Order_Count = 1
GROUP BY 
    D.Campaign
HAVING 
    COUNT(*) > 100
ORDER BY 
    ReturnCount DESC;

---9.What is the total quantity sold by category?
SELECT 
    D.Product_Category,
	SUM(D.Quantity) AS TotalQuantity
FROM 
    dbo.Dataset AS D
GROUP BY 
    D.Product_Category

----10.Which customers made purchases but had no returns?
SELECT 
    D.CustomerID,
    D.Customer_Name
FROM 
    dbo.Dataset AS D

GROUP BY 
    D.CustomerID, D.Customer_Name
HAVING 
    SUM(CASE WHEN D.Returned_Order_Count = 1 THEN 1 ELSE 0 END) = 0

--Total number of customers who made returns
SELECT 
    COUNT(DISTINCT D.CustomerID) AS CustomersWithReturns
FROM 
    dbo.Dataset AS D
WHERE 
    D.Returned_Order_Count = 1;

--Total number of customer 
SELECT COUNT(DISTINCT CustomerID) AS TotalUniqueCustomers
FROM dbo.Dataset;

---Customer with no returns region wise
SELECT 
    D.CustomerID,
    D.Customer_Name, D.Customer_Region,
    COUNT(*) AS TotalPurchases
FROM 
    dbo.Dataset AS D

WHERE D.Customer_Region = 'West'
GROUP BY 
    D.CustomerID, D.Customer_Name, D.Customer_Region
HAVING 
    SUM(CASE WHEN D.Returned_Order_Count = 1 THEN 1 ELSE 0 END) = 0
ORDER BY 
    TotalPurchases DESC;

--Count of NO RETURN region wise 
SELECT 
    D.Customer_Region,
    COUNT(DISTINCT D.CustomerID) AS NoReturnCustomers
FROM 
    dbo.Dataset AS D
WHERE 
    D.CustomerID NOT IN (
        SELECT DISTINCT CustomerID 
        FROM dbo.Dataset 
        WHERE Returned_Order_Count = 1
    )
GROUP BY 
    D.Customer_Region
ORDER BY 
    NoReturnCustomers DESC;

--For each product category, what proportion of orders were not returned?
SELECT 
    D.Product_Category, 
    COUNT(CASE WHEN D.Returned_Order_Count = 0 THEN 1 END) * 1.0 / COUNT(*) AS Noreturn
FROM 
     dbo.Dataset AS D
GROUP BY 
    D.Product_Category