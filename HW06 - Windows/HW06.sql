/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "06 - Оконные функции".

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
-- ---------------------------------------------------------------------------

USE WideWorldImporters
/*
1. Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года 
(в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки).
Выведите: id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом

Пример:
-------------+----------------------------
Дата продажи | Нарастающий итог по месяцу
-------------+----------------------------
 2015-01-29   | 4801725.31
 2015-01-30	 | 4801725.31
 2015-01-31	 | 4801725.31
 2015-02-01	 | 9626342.98
 2015-02-02	 | 9626342.98
 2015-02-03	 | 9626342.98
Продажи можно взять из таблицы Invoices.
Нарастающий итог должен быть без оконной функции.
*/
set statistics time, io on
; WITH Total AS (SELECT 
	YEAR(i.InvoiceDate) AS InvoiceYear, 
	MONTH(i.InvoiceDate) AS InvoiceMonth, 
	(SELECT sum(tx.TransactionAmount) FROM Sales.Invoices ix
	JOIN Sales.CustomerTransactions tx ON tx.InvoiceID=ix.InvoiceID
	WHERE YEAR(ix.InvoiceDate)>2014 and ix.InvoiceDate<=EOMONTH(DATEFROMPARTS(YEAR(i.InvoiceDate), MONTH(i.InvoiceDate), 1 ))) AS TotalAmount
FROM Sales.Invoices i
	JOIN Sales.CustomerTransactions t ON t.InvoiceID=i.InvoiceID
WHERE YEAR(i.InvoiceDate)>2014
GROUP BY YEAR(i.InvoiceDate), MONTH(i.InvoiceDate))
SELECT 
	i.InvoiceID,
	CustomerName,
	InvoiceDate, 
	TransactionAmount,
	TotalAmount
FROM Sales.Invoices i
JOIN Sales.Customers c ON c.CustomerID=i.CustomerID
JOIN Sales.CustomerTransactions t ON t.InvoiceID=i.InvoiceID
JOIN Total ON YEAR(InvoiceDate)=InvoiceYear and MONTH(InvoiceDate)=InvoiceMonth
ORDER BY InvoiceDate;

/*
2. Сделайте расчет суммы нарастающим итогом в предыдущем запросе с помощью оконной функции.
   Сравните производительность запросов 1 и 2 с помощью set statistics time, io on
*/

SELECT 
	i.InvoiceID,
	CustomerName,
	InvoiceDate, 
	TransactionAmount,
	SUM(TransactionAmount) OVER (ORDER BY YEAR(i.InvoiceDate), Month(InvoiceDate)) AS TransactionAmountNar
FROM Sales.Invoices i
JOIN Sales.Customers c ON c.CustomerID=i.CustomerID
JOIN Sales.CustomerTransactions t ON t.InvoiceID=i.InvoiceID
WHERE YEAR(i.InvoiceDate)>2014
ORDER BY InvoiceDate;

--(31440 rows affected)
--Таблица "Worktable". Число просмотров 17, логических чтений 144878, физических чтений 0, упреждающих чтений 0, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.
--Таблица "Workfile". Число просмотров 0, логических чтений 0, физических чтений 0, упреждающих чтений 0, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.
--Таблица "CustomerTransactions". Число просмотров 95, логических чтений 20529, физических чтений 8, упреждающих чтений 1378, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.
--Таблица "Invoices". Число просмотров 3, логических чтений 34200, физических чтений 3, упреждающих чтений 11388, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.
--Таблица "Worktable". Число просмотров 0, логических чтений 0, физических чтений 0, упреждающих чтений 0, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.
--Таблица "Customers". Число просмотров 1, логических чтений 40, физических чтений 0, упреждающих чтений 0, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.

-- Время работы SQL Server:
--   Время ЦП = 906 мс, затраченное время = 10499 мс.

--(31440 rows affected)
--Таблица "Worktable". Число просмотров 18, логических чтений 73197, физических чтений 0, упреждающих чтений 0, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.
--Таблица "Workfile". Число просмотров 0, логических чтений 0, физических чтений 0, упреждающих чтений 0, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.
--Таблица "CustomerTransactions". Число просмотров 5, логических чтений 1126, физических чтений 0, упреждающих чтений 0, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.
--Таблица "Invoices". Число просмотров 1, логических чтений 11400, физических чтений 0, упреждающих чтений 0, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.
--Таблица "Worktable". Число просмотров 0, логических чтений 0, физических чтений 0, упреждающих чтений 0, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.
--Таблица "Customers". Число просмотров 1, логических чтений 40, физических чтений 0, упреждающих чтений 0, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.

-- Время работы SQL Server:
--   Время ЦП = 234 мс, затраченное время = 730 мс.

/*
3. Вывести список 2х самых популярных продуктов (по количеству проданных) 
в каждом месяце за 2016 год (по 2 самых популярных продукта в каждом месяце).
*/

SELECT 
	InvoiceMonth,
	StockItemID,
	TotalQuantity
FROM (
SELECT 
	StockItemID,
	MONTH(InvoiceDate) AS InvoiceMonth,
	SUM(l.Quantity) AS TotalQuantity, 
	ROW_NUMBER() OVER (PARTITION BY MONTH(InvoiceDate) ORDER BY MONTH(InvoiceDate), SUM(l.Quantity) DESC) AS RnTotal
FROM Sales.Invoices i
		JOIN Sales.InvoiceLines l ON i.InvoiceID=l.InvoiceID
WHERE YEAR(InvoiceDate)=2016 
GROUP BY MONTH(InvoiceDate), StockItemID) Sales
WHERE RnTotal<3
ORDER BY InvoiceMonth, TotalQuantity DESC;

/*
4. Функции одним запросом
Посчитайте по таблице товаров (в вывод также должен попасть ид товара, название, брэнд и цена):
* пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
* посчитайте общее количество товаров и выведете полем в этом же запросе
* посчитайте общее количество товаров в зависимости от первой буквы названия товара
* отобразите следующий id товара исходя из того, что порядок отображения товаров по имени 
* предыдущий ид товара с тем же порядком отображения (по имени)
* названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
* сформируйте 30 групп товаров по полю вес товара на 1 шт

Для этой задачи НЕ нужно писать аналог без аналитических функций.
*/

SELECT 
		StockItemID,
		StockItemName,
		Brand, 
		UnitPrice,
		ROW_NUMBER() OVER (PARTITION BY left(StockItemName,1) ORDER BY StockItemName) AS rnABC,
		COUNT(StockItemID) OVER() AS cn,
		COUNT(StockItemID) OVER(PARTITION BY left(StockItemName,1)) AS cnABC,
		LAG(StockItemID) OVER (ORDER BY StockItemName) AS StockItemIDPrevName,
		LEAD(StockItemID) OVER (ORDER BY StockItemName) AS StockItemIDFollowName,
		LAG(StockItemName,2,'No items') OVER (ORDER BY StockItemName) AS StockItemNamePrevName,
		NTILE(30) OVER (ORDER BY TypicalWeightPerUnit) AS GroupWeight
FROM Warehouse.StockItems
ORDER BY StockItemName;

/*
5. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал.
   В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки.
*/

SELECT TOP 1 WITH Ties
	i.SalespersonPersonID,
	p.FullName,
	i.CustomerID,
	c.CustomerName,
	i.InvoiceDate,
	l.Quantity*l.UnitPrice AS Amount
FROM Sales.Invoices i
	JOIN Sales.InvoiceLines l ON i.InvoiceID=l.InvoiceID
	JOIN Application.People p ON p.PersonID=i.SalespersonPersonID
	JOIN Sales.Customers c ON c.CustomerID=i.CustomerID
ORDER BY ROW_NUMBER() OVER (PARTITION BY i.SalespersonPersonID ORDER BY i.InvoiceDate DESC);

/*
6. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

SELECT 
	s.CustomerID,
	c.CustomerName,
	StockItemID,
	s.UnitPrice,
	s.InvoiceDate
FROM (
SELECT 
	i.CustomerID,
	l.StockItemID,
	MAX(l.UnitPrice) AS UnitPrice, 
	MAX(i.InvoiceDate) AS InvoiceDate,
	ROW_NUMBER() OVER (PARTITION BY i.CustomerID ORDER BY i.CustomerID, MAX(l.UnitPrice) DESC) AS RnTotal
FROM Sales.Invoices i
	JOIN Sales.InvoiceLines l ON i.InvoiceID=l.InvoiceID
GROUP BY i.CustomerID, l.StockItemID
) s
	JOIN Sales.Customers c ON c.CustomerID=s.CustomerID
WHERE RnTotal<3
ORDER BY s.CustomerID,s.UnitPrice DESC;


--Опционально можете для каждого запроса без оконных функций сделать вариант запросов с оконными функциями и сравнить их производительность. 
