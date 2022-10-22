/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "10 - Операторы изменения данных".

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
1. Довставлять в базу пять записей используя insert в таблицу Customers или Suppliers 
*/

INSERT INTO Sales.Customers 
		([CustomerName]
      ,[BillToCustomerID]
      ,[CustomerCategoryID]
      ,[BuyingGroupID]
      ,[PrimaryContactPersonID]
      ,[AlternateContactPersonID]
      ,[DeliveryMethodID]
      ,[DeliveryCityID]
      ,[PostalCityID]
      ,[CreditLimit]
      ,[AccountOpenedDate]
      ,[StandardDiscountPercentage]
      ,[IsStatementSent]
      ,[IsOnCreditHold]
      ,[PaymentDays]
      ,[PhoneNumber]
      ,[FaxNumber]
      ,[DeliveryRun]
      ,[RunPosition]
      ,[WebsiteURL]
      ,[DeliveryAddressLine1]
      ,[DeliveryAddressLine2]
      ,[DeliveryPostalCode]
      ,[DeliveryLocation]
      ,[PostalAddressLine1]
      ,[PostalAddressLine2]
      ,[PostalPostalCode]
      ,[LastEditedBy])
SELECT 
	REPLACE([CustomerName], 'Toys','Kiss')
      ,[BillToCustomerID]
      ,[CustomerCategoryID]
      ,[BuyingGroupID]
      ,[PrimaryContactPersonID]
      ,[AlternateContactPersonID]
      ,[DeliveryMethodID]
      ,[DeliveryCityID]
      ,[PostalCityID]
      ,[CreditLimit]
      ,[AccountOpenedDate]
      ,[StandardDiscountPercentage]
      ,[IsStatementSent]
      ,[IsOnCreditHold]
      ,[PaymentDays]
      ,[PhoneNumber]
      ,[FaxNumber]
      ,[DeliveryRun]
      ,[RunPosition]
      ,[WebsiteURL]
      ,[DeliveryAddressLine1]
      ,[DeliveryAddressLine2]
      ,[DeliveryPostalCode]
      ,[DeliveryLocation]
      ,[PostalAddressLine1]
      ,[PostalAddressLine2]
      ,[PostalPostalCode]
      ,[LastEditedBy]
FROM Sales.Customers
WHERE CustomerName like 'Wingtip%City%';

/*
2. Удалите одну запись из Customers, которая была вами добавлена
*/

; WITH DEL AS (
SELECT TOP 1 * FROM Sales.Customers
WHERE CustomerName like '%Kiss%')
DELETE FROM DEL;

/*
3. Изменить одну запись, из добавленных через UPDATE
*/

UPDATE C
SET 
	WebsiteURL='http://www.yandex.ru'
OUTPUT inserted.WebsiteURL AS New_WebsiteURL, deleted.WebsiteURL AS Old_WebsiteURL
FROM Sales.Customers AS C
	JOIN
	(SELECT TOP 1 CustomerID 
	FROM Sales.Customers
	WHERE CustomerName like '%Kiss%') AS I
		ON C.CustomerID=I.CustomerID;
/*
4. Написать MERGE, который вставит вставит запись в клиенты, если ее там нет, и изменит если она уже есть
*/

MERGE Sales.Customers AS tg
USING (SELECT TOP 1  
		 [CustomerName]
		,[BillToCustomerID]
		,[CustomerCategoryID]
		,[BuyingGroupID]
		,[PrimaryContactPersonID]
		,[AlternateContactPersonID]
		,[DeliveryMethodID]
		,[DeliveryCityID]
		,[PostalCityID]
		,[CreditLimit]
		,[AccountOpenedDate]
		,[StandardDiscountPercentage]
		,[IsStatementSent]
		,[IsOnCreditHold]
		,[PaymentDays]
		,[PhoneNumber]
		,[FaxNumber]
		,[DeliveryRun]
		,[RunPosition]
		,'http://www.otus.ru' AS [WebsiteURL]
		,[DeliveryAddressLine1]
		,[DeliveryAddressLine2]
		,[DeliveryPostalCode]
		,[PostalAddressLine1]
		,[PostalAddressLine2]
		,[PostalPostalCode]
		,[LastEditedBy]
		FROM Sales.Customers
		WHERE CustomerName like '%Kiss%'
	UNION
		SELECT TOP 1 
		REPLACE([CustomerName], 'Kiss','Love') AS CustomerName
		,[BillToCustomerID]
		,[CustomerCategoryID]
		,[BuyingGroupID]
		,[PrimaryContactPersonID]
		,[AlternateContactPersonID]
		,[DeliveryMethodID]
		,[DeliveryCityID]
		,[PostalCityID]
		,[CreditLimit]
		,[AccountOpenedDate]
		,[StandardDiscountPercentage]
		,[IsStatementSent]
		,[IsOnCreditHold]
		,[PaymentDays]
		,[PhoneNumber]
		,[FaxNumber]
		,[DeliveryRun]
		,[RunPosition]
		,[WebsiteURL]
		,[DeliveryAddressLine1]
		,[DeliveryAddressLine2]
		,[DeliveryPostalCode]
		,[PostalAddressLine1]
		,[PostalAddressLine2]
		,[PostalPostalCode]
		,[LastEditedBy]
FROM Sales.Customers
WHERE CustomerName like '%Kiss%') AS sr
ON 
(tg.CustomerName=sr.CustomerName)
WHEN MATCHED 
THEN UPDATE SET 
		WebsiteURL=sr.WebsiteURL
WHEN NOT MATCHED
THEN INSERT 
		([CustomerName]
		,[BillToCustomerID]
		,[CustomerCategoryID]
		,[BuyingGroupID]
		,[PrimaryContactPersonID]
		,[AlternateContactPersonID]
		,[DeliveryMethodID]
		,[DeliveryCityID]
		,[PostalCityID]
		,[CreditLimit]
		,[AccountOpenedDate]
		,[StandardDiscountPercentage]
		,[IsStatementSent]
		,[IsOnCreditHold]
		,[PaymentDays]
		,[PhoneNumber]
		,[FaxNumber]
		,[DeliveryRun]
		,[RunPosition]
		,[WebsiteURL]
		,[DeliveryAddressLine1]
		,[DeliveryAddressLine2]
		,[DeliveryPostalCode]
		,[PostalAddressLine1]
		,[PostalAddressLine2]
		,[PostalPostalCode]
		,[LastEditedBy])
VALUES 
		([CustomerName]
		,[BillToCustomerID]
		,[CustomerCategoryID]
		,[BuyingGroupID]
		,[PrimaryContactPersonID]
		,[AlternateContactPersonID]
		,[DeliveryMethodID]
		,[DeliveryCityID]
		,[PostalCityID]
		,[CreditLimit]
		,[AccountOpenedDate]
		,[StandardDiscountPercentage]
		,[IsStatementSent]
		,[IsOnCreditHold]
		,[PaymentDays]
		,[PhoneNumber]
		,[FaxNumber]
		,[DeliveryRun]
		,[RunPosition]
		,[WebsiteURL]
		,[DeliveryAddressLine1]
		,[DeliveryAddressLine2]
		,[DeliveryPostalCode]
		,[PostalAddressLine1]
		,[PostalAddressLine2]
		,[PostalPostalCode]
		,[LastEditedBy])
OUTPUT inserted.*,  $action, deleted.*;


/*
5. Напишите запрос, который выгрузит данные через bcp out и загрузить через bulk insert
*/

EXEC sp_configure 'show advanced option', 1;
GO
RECONFIGURE;
GO
EXEC sp_configure 'xp_cmdshell', 1;
GO
RECONFIGURE;
GO
SELECT @@SERVERNAME;

EXEC ..xp_cmdshell 'bcp "[WideWorldImporters].[Purchasing].[PurchaseOrders]" out "D:\1\PurchaseOrders.txt" -T -w -t"razd&1&" -S LAPTOP-2N41EGON\MSSQLTR'

SELECT *
INTO Purchasing.PurchaseOrdersDemoBulk 
FROM Purchasing.PurchaseOrders
WHERE 1=2;

BULK INSERT [WideWorldImporters].[Purchasing].[PurchaseOrdersDemoBulk]
			FROM "D:\1\PurchaseOrders.txt"
			WITH (
				DATAFILETYPE='widechar',
				FIELDTERMINATOR='razd&1&',
				ROWTERMINATOR='\n',
				KEEPNULLS,
				TABLOCK
				);

