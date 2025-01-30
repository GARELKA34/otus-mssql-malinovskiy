/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "03 - Подзапросы, CTE, временные таблицы".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/

--Вариант 1 (подзапрос):

SELECT 
    PersonID,
    FullName
FROM 
    Application.People
WHERE 
    IsSalesperson = 1
    AND PersonID NOT IN (
        SELECT DISTINCT SalespersonPersonID
        FROM Sales.Invoices
        WHERE CAST(InvoiceDate AS DATE) = '2015-07-04'
    );

--Вариант 2 (CTE):

WITH Salespersons AS (
    SELECT DISTINCT SalespersonPersonID
    FROM Sales.Invoices
    WHERE CAST(InvoiceDate AS DATE) = '2015-07-04'
)
SELECT 
    PersonID,
    FullName
FROM 
    Application.People
WHERE 
    IsSalesperson = 1
    AND PersonID NOT IN (SELECT SalespersonPersonID FROM Salespersons);

/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/

 

--Вариант 1 (подзапрос):


SELECT 
    StockItemID,
    StockItemName,
    UnitPrice
FROM 
    Warehouse.StockItems
WHERE 
    UnitPrice = (SELECT MIN(UnitPrice) FROM Warehouse.StockItems);


--Вариант 2 (CTE):


WITH MinPrice AS (
    SELECT MIN(UnitPrice) AS MinPrice
    FROM Warehouse.StockItems
)
SELECT 
    s.StockItemID,
    s.StockItemName,
    s.UnitPrice
FROM 
    Warehouse.StockItems AS s
JOIN 
    MinPrice AS mp ON s.UnitPrice = mp.MinPrice;

/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/
 

--Способ 1 (подзапрос):


SELECT 
    CustomerID,
    CustomerName
FROM 
    Sales.Customers
WHERE 
    CustomerID IN (
        SELECT TOP 5 CustomerID
        FROM Sales.CustomerTransactions
        ORDER BY TransactionAmount DESC
    );


--Способ 2 (CTE):


WITH TopTransactions AS (
    SELECT TOP 5 CustomerID, TransactionAmount
    FROM Sales.CustomerTransactions
    ORDER BY TransactionAmount DESC
)
SELECT 
    c.CustomerID,
    c.CustomerName
FROM 
    Sales.Customers AS c
WHERE 
    c.CustomerID IN (SELECT CustomerID FROM TopTransactions);


/*
4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника, 
который осуществлял упаковку заказов (PackedByPersonID).
*/

WITH TopItems AS (
    SELECT TOP 3 StockItemID
    FROM Warehouse.StockItems
    ORDER BY UnitPrice DESC
),
OrdersWithTopItems AS (
    SELECT 
        o.OrderID,
        o.PickedByPersonID,
        c.DeliveryCityID
    FROM 
        Sales.Orders AS o
    JOIN 
        Sales.OrderLines AS ol ON o.OrderID = ol.OrderID
    JOIN 
        TopItems AS ti ON ol.StockItemID = ti.StockItemID
    JOIN 
        Sales.Customers AS c ON o.CustomerID = c.CustomerID
)
SELECT 
    ci.CityID,
    ci.CityName,
    p.FullName AS PackedByPerson
FROM 
    OrdersWithTopItems AS owti
JOIN 
    Application.Cities AS ci ON owti.DeliveryCityID = ci.CityID
JOIN 
    Application.People AS p ON owti.PickedByPersonID = p.PersonID
GROUP BY 
    ci.CityID, ci.CityName, p.FullName;

-- ---------------------------------------------------------------------------
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- Можно двигаться как в сторону улучшения читабельности запроса, 
-- так и в сторону упрощения плана\ускорения. 
-- Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. 
-- Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). 
-- Напишите ваши рассуждения по поводу оптимизации. 

-- 5. Объясните, что делает и оптимизируйте запрос

SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	(SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName,
	SalesTotals.TotalSumm AS TotalSummByInvoice, 
	(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (SELECT Orders.OrderId 
			FROM Sales.Orders
			WHERE Orders.PickingCompletedWhen IS NOT NULL	
				AND Orders.OrderId = Invoices.OrderId)	
	) AS TotalSummForPickedItems
FROM Sales.Invoices 
	JOIN
	(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
		ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC

-- --

TODO: напишите здесь свое решение
