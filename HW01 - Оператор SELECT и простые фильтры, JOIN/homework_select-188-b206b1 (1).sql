/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, JOIN".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД WideWorldImporters можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

SELECT 
    StockItemID, 
    StockItemName 
FROM Warehouse.StockItems 
WHERE 
    StockItemName LIKE '%urgent%' 
    OR StockItemName LIKE 'Animal%';

/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

SELECT 
    s.SupplierID, 
    s.SupplierName 
FROM Purchasing.Suppliers s 
LEFT JOIN Purchasing.PurchaseOrders po 
    ON s.SupplierID = po.SupplierID 
WHERE po.PurchaseOrderID IS NULL;

/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/

SELECT 
    o.OrderID,
    FORMAT(o.OrderDate, 'dd.MM.yyyy') AS OrderDate,
    DATENAME(month, o.OrderDate) AS OrderMonth,
    DATEPART(quarter, o.OrderDate) AS OrderQuarter,
    CASE 
        WHEN MONTH(o.OrderDate) BETWEEN 1 AND 4 THEN 1
        WHEN MONTH(o.OrderDate) BETWEEN 5 AND 8 THEN 2
        ELSE 3 
    END AS YearThird,
    c.CustomerName AS Customer
FROM Sales.Orders o
JOIN Sales.OrderLines ol 
    ON o.OrderID = ol.OrderID
JOIN Sales.Customers c 
    ON o.CustomerID = c.CustomerID
WHERE 
    (ol.UnitPrice > 100 OR ol.Quantity > 20)
    AND o.PickingCompletedWhen IS NOT NULL
ORDER BY 
    OrderQuarter, 
    YearThird, 
    o.OrderDate
-- Постраничная выборка
OFFSET 1000 ROWS FETCH NEXT 100 ROWS ONLY;

/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

SELECT 
    dm.DeliveryMethodName,
    po.ExpectedDeliveryDate,
    s.SupplierName,
    p.FullName AS ContactPerson
FROM Purchasing.PurchaseOrders po
JOIN Purchasing.Suppliers s 
    ON po.SupplierID = s.SupplierID
JOIN Application.DeliveryMethods dm 
    ON po.DeliveryMethodID = dm.DeliveryMethodID
JOIN Application.People p 
    ON po.ContactPersonID = p.PersonID
WHERE 
    po.ExpectedDeliveryDate BETWEEN '2013-01-01' AND '2013-01-31'
    AND dm.DeliveryMethodName IN ('Air Freight', 'Refrigerated Air Freight')
    AND po.IsOrderFinalized = 1;

/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

SELECT TOP 10 
    o.OrderID,
    o.OrderDate,
    c.CustomerName,
    p.FullName AS Salesperson
FROM Sales.Orders o
JOIN Sales.Customers c 
    ON o.CustomerID = c.CustomerID
JOIN Application.People p 
    ON o.SalespersonPersonID = p.PersonID
ORDER BY o.OrderDate DESC;

/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

SELECT DISTINCT
    c.CustomerID,
    c.CustomerName,
    c.PhoneNumber
FROM Sales.Customers c
JOIN Sales.Orders o 
    ON c.CustomerID = o.CustomerID
JOIN Sales.OrderLines ol 
    ON o.OrderID = ol.OrderID
JOIN Warehouse.StockItems si 
    ON ol.StockItemID = si.StockItemID
WHERE si.StockItemName = 'Chocolate frogs 250g';