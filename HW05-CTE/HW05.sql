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
SELECT 
	PersonId,
	FullName 
FROM Application.People
WHERE IsSalesPerson=1 AND NOT EXISTS(SELECT 1 FROM Sales.Invoices WHERE InvoiceDate = '20150704' AND SalespersonPersonID=PersonId);

; WITH InvoicesCTE AS (SELECT SalespersonPersonID FROM Sales.Invoices WHERE InvoiceDate = '20150704')
SELECT 
	PersonId,
	FullName 
FROM Application.People
LEFT JOIN InvoicesCTE ON SalespersonPersonID=PersonId
WHERE IsSalesPerson=1 AND SalespersonPersonID IS NULL;


/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/

SELECT 
	StockItemID, 
	StockItemName, 
	UnitPrice 
FROM Warehouse.StockItems
WHERE UnitPrice = (SELECT MIN(UnitPrice) FROM Warehouse.StockItems);

SELECT 
	StockItemID, 
	StockItemName, 
	UnitPrice 
FROM Warehouse.StockItems
WHERE UnitPrice = (SELECT TOP 1 UnitPrice FROM Warehouse.StockItems ORDER BY UnitPrice);

SELECT 
	StockItemID, 
	StockItemName, 
	UnitPrice 
FROM Warehouse.StockItems
WHERE UnitPrice <= ALL (SELECT UnitPrice FROM Warehouse.StockItems);

/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/

SELECT * 
FROM Sales.Customers
WHERE CustomerID IN (SELECT TOP 5 CustomerID FROM Sales.CustomerTransactions ORDER BY TransactionAmount DESC);

; WITH CustomerTransactionsCTE AS (SELECT TOP 5 CustomerID FROM Sales.CustomerTransactions ORDER BY TransactionAmount DESC)
SELECT * 
FROM Sales.Customers c
WHERE c.CustomerID IN (SELECT CustomerID FROM CustomerTransactionsCTE);

/*
4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника, 
который осуществлял упаковку заказов (PackedByPersonID).
*/

; WITH StockItemTransactionsCTE AS (SELECT	CustomerID,
											InvoiceID 
									FROM Warehouse.StockItemTransactions w 
										JOIN Warehouse.StockItems a ON a.StockItemID=w.StockItemID
									WHERE UnitPrice IN (SELECT TOP 3 UnitPrice FROM Warehouse.StockItems ORDER BY UnitPrice DESC))
SELECT
		CityID AS DeliveryCityID,
		CityName AS DeliveryCityName,
		FullName AS PackedByPersonName
FROM Application.Cities
	JOIN Sales.Customers s ON s.DeliveryCityID=CityID
	JOIN StockItemTransactionsCTE b ON b.CustomerID=s.CustomerID
	JOIN Sales.Invoices i ON i.InvoiceID=b.InvoiceID
	JOIN Application.People ON PersonId=PackedByPersonID
WHERE i.DeliveryRun IS NOT NULL
GROUP BY CityID, CityName, FullName
ORDER BY CityID, FullName

-- ---------------------------------------------------------------------------
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- Можно двигаться как в сторону улучшения читабельности запроса, 
-- так и в сторону упрощения плана\ускорения. 
-- Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. 
-- Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). 
-- Напишите ваши рассуждения по поводу оптимизации. 

-- 5. Объясните, что делает и оптимизируйте запрос

--Запрос выбирает счета в порядке убывания Суммы по счету, 
--в виде: Номер счета, Дата счета, ФИО продавца, Сумма по счету, Сумма скомплектованных товаров по счету, 
--где Сумма по счету более 27 тыс
 SET STATISTICS IO, TIME ON
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
--С точки зрения улучшения читабельности запроса, убрала подзапрос определения "ФИО продавца", перенесла таблицу People в JOIN, это не влияет на скорость выполнения. 
--Расчет и ограничение "Суммы по счету" перенесла в СТЕ 
--Убрала подзапрос, где Позиции заказа (OrderLines) связываются с Заказами (Orders)

;WITH SalesTotals AS (SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
						FROM Sales.InvoiceLines
						GROUP BY InvoiceId
						HAVING SUM(Quantity*UnitPrice) > 27000) 
SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate, 
	People.FullName AS SalesPersonName, 
	SalesTotals.TotalSumm AS TotalSummByInvoice, 
	(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.Orders
		JOIN Sales.OrderLines ON OrderLines.OrderId=Orders.OrderId 
		WHERE Orders.PickingCompletedWhen IS NOT NULL	 
				AND Orders.OrderId = Invoices.OrderId	
	) AS TotalSummForPickedItems  
FROM Sales.Invoices 
	JOIN SalesTotals ON Invoices.InvoiceID = SalesTotals.InvoiceID
	JOIN Application.People ON People.PersonID = Invoices.SalespersonPersonID
ORDER BY TotalSumm DESC

-- Сравнивая производительность запросов можно убедится, что второй запрос выполняется быстрее, за счет СТЕ снизилось число обращений к таблице OrderLines

--(8 rows affected)
--Таблица "OrderLines". Число просмотров 16, логических чтений 0, физических чтений 0, упреждающих чтений 0, lob логических чтений 505, lob физических чтений 3, lob упреждающих чтений 790.
--Таблица "OrderLines". Считано сегментов 1, пропущено 0.
--Таблица "InvoiceLines". Число просмотров 16, логических чтений 0, физических чтений 0, упреждающих чтений 0, lob логических чтений 500, lob физических чтений 3, lob упреждающих чтений 778.
--Таблица "InvoiceLines". Считано сегментов 1, пропущено 0.
--Таблица "Orders". Число просмотров 9, логических чтений 725, физических чтений 0, упреждающих чтений 677, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.
--Таблица "Invoices". Число просмотров 9, логических чтений 11994, физических чтений 0, упреждающих чтений 11290, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.
--Таблица "People". Число просмотров 4, логических чтений 28, физических чтений 0, упреждающих чтений 0, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.
--Таблица "Worktable". Число просмотров 0, логических чтений 0, физических чтений 0, упреждающих чтений 0, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.

-- Время работы SQL Server:
--   Время ЦП = 46 мс, затраченное время = 209 мс.

--(8 rows affected)
--Таблица "OrderLines". Число просмотров 16, логических чтений 0, физических чтений 0, упреждающих чтений 0, lob логических чтений 326, lob физических чтений 0, lob упреждающих чтений 0.
--Таблица "OrderLines". Считано сегментов 1, пропущено 0.
--Таблица "InvoiceLines". Число просмотров 16, логических чтений 0, физических чтений 0, упреждающих чтений 0, lob логических чтений 322, lob физических чтений 0, lob упреждающих чтений 0.
--Таблица "InvoiceLines". Считано сегментов 1, пропущено 0.
--Таблица "Orders". Число просмотров 9, логических чтений 725, физических чтений 0, упреждающих чтений 0, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.
--Таблица "Invoices". Число просмотров 9, логических чтений 11994, физических чтений 0, упреждающих чтений 0, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.
--Таблица "People". Число просмотров 9, логических чтений 28, физических чтений 0, упреждающих чтений 0, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.
--Таблица "Worktable". Число просмотров 0, логических чтений 0, физических чтений 0, упреждающих чтений 0, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.

-- Время работы SQL Server:
--   Время ЦП = 125 мс, затраченное время = 73 мс.

--Completion time: 2022-10-11T23:37:30.5073558+03:00
