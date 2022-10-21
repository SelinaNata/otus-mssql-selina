/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "05 - Операторы CROSS APPLY, PIVOT, UNPIVOT".

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
1. Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Клиентов взять с ID 2-6, это все подразделение Tailspin Toys.
Имя клиента нужно поменять так чтобы осталось только уточнение.
Например, исходное значение "Tailspin Toys (Gasport, NY)" - вы выводите только "Gasport, NY".
Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+-------------+--------------+------------
InvoiceMonth | Peeples Valley, AZ | Medicine Lodge, KS | Gasport, NY | Sylvanite, MT | Jessie, ND
-------------+--------------------+--------------------+-------------+--------------+------------
01.01.2013   |      3             |        1           |      4      |      2        |     2
01.02.2013   |      7             |        3           |      4      |      2        |     1
-------------+--------------------+--------------------+-------------+--------------+------------
*/

SELECT * FROM
	(
	SELECT	i.InvoiceID,			
			FORMAT(DATEADD(mm, DATEDIFF(mm,0,InvoiceDate), 0), 'dd.MM.yyyy') InvoiceMonth,			
			REPLACE(SUBSTRING(c.CustomerName, CHARINDEX('(', c.CustomerName)+1,50),')','') CustomerName
	FROM Sales.Invoices i
		JOIN Sales.Customers c ON c.CustomerID=i.CustomerID
	WHERE i.CustomerID between 2 and 6
	) AS Sales
PIVOT (COUNT(InvoiceID)
FOR CustomerName IN ([Peeples Valley, AZ], [Medicine Lodge, KS], [Gasport, NY], [Sylvanite, MT],[Jessie, ND])) AS PVT_Sales
ORDER BY InvoiceMonth;

/*
2. Для всех клиентов с именем, в котором есть "Tailspin Toys"
вывести все адреса, которые есть в таблице, в одной колонке.

Пример результата:
----------------------------+--------------------
CustomerName                | AddressLine
----------------------------+--------------------
Tailspin Toys (Head Office) | Shop 38
Tailspin Toys (Head Office) | 1877 Mittal Road
Tailspin Toys (Head Office) | PO Box 8975
Tailspin Toys (Head Office) | Ribeiroville
----------------------------+--------------------
*/
SELECT 
		CustomerName,
		AddressLine
FROM (
SELECT 
		CustomerName,
		DeliveryAddressLine1,
		DeliveryAddressLine2,
		PostalAddressLine1,
		PostalAddressLine2
FROM Sales.Customers
WHERE CustomerName like '%Tailspin Toys%') AS Customer
UNPIVOT(AddressLine FOR Address IN (
		DeliveryAddressLine1,
		DeliveryAddressLine2,
		PostalAddressLine1,
		PostalAddressLine2
      )) AS unpt;

/*
3. В таблице стран (Application.Countries) есть поля с цифровым кодом страны и с буквенным.
Сделайте выборку ИД страны, названия и ее кода так, 
чтобы в поле с кодом был либо цифровой либо буквенный код.

Пример результата:
--------------------------------
CountryId | CountryName | Code
----------+-------------+-------
1         | Afghanistan | AFG
1         | Afghanistan | 4
3         | Albania     | ALB
3         | Albania     | 8
----------+-------------+-------
*/

SELECT 
	CountryID,
	CountryName,
	Code
FROM (
SELECT 
	CountryID,
	CountryName,
	IsoAlpha3Code,
	CAST(IsoNumericCode AS NVARCHAR(3)) AS IsoNumerCode
FROM Application.Countries) AS Country
UNPIVOT(Code FOR C IN (
	IsoAlpha3Code,
	IsoNumerCode)) AS unpt;

/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В реультатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/
SELECT
	c.CustomerID,
	c.CustomerName,
	StockItem.*
FROM Sales.Customers c
CROSS APPLY (
	SELECT TOP 2 
		StockItemID,
		MAX(UnitPrice) AS UnitPrice,
		MAX(InvoiceDate) AS InvoiceDate
	FROM Sales.Invoices i
		JOIN Sales.InvoiceLines l ON i.InvoiceID=l.InvoiceID
	WHERE c.CustomerID=i.CustomerID
	GROUP BY StockItemID 
	ORDER BY UnitPrice DESC) AS StockItem
ORDER BY c.CustomerID;

