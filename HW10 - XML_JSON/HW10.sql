/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "08 - Выборки из XML и JSON полей".

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
Примечания к заданиям 1, 2:
* Если с выгрузкой в файл будут проблемы, то можно сделать просто SELECT c результатом в виде XML. 
* Если у вас в проекте предусмотрен экспорт/импорт в XML, то можете взять свой XML и свои таблицы.
* Если с этим XML вам будет скучно, то можете взять любые открытые данные и импортировать их в таблицы (например, с https://data.gov.ru).
* Пример экспорта/импорта в файл https://docs.microsoft.com/en-us/sql/relational-databases/import-export/examples-of-bulk-import-and-export-of-xml-documents-sql-server
*/


/*
1. В личном кабинете есть файл StockItems.xml.
Это данные из таблицы Warehouse.StockItems.
Преобразовать эти данные в плоскую таблицу с полями, аналогичными Warehouse.StockItems.
Поля: StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice 

Загрузить эти данные в таблицу Warehouse.StockItems: 
существующие записи в таблице обновить, отсутствующие добавить (сопоставлять записи по полю StockItemName). 

Сделать два варианта: с помощью OPENXML и через XQuery.
*/

DECLARE @x as xml

SELECT @x = (SELECT * 
FROM OPENROWSET
(BULK 'D:\1\StockItems.xml',
SINGLE_CLOB) 
as data)

DECLARE @hdoc int
EXEC sp_xml_preparedocument @hdoc OUTPUT, @x

MERGE Warehouse.StockItems AS tg
USING (
SELECT * 
FROM OPENXML(@hdoc, N'/StockItems/Item')
WITH (
	[StockItemName] [nvarchar](100) '@Name',
	[SupplierID] [int] 'SupplierID',
	[UnitPackageID] [int] 'Package/UnitPackageID',
	[OuterPackageID] [int] 'Package/OuterPackageID',
	[QuantityPerOuter] [int] 'Package/QuantityPerOuter',
	[TypicalWeightPerUnit] [decimal](18, 3) 'Package/TypicalWeightPerUnit',
	[LeadTimeDays] [int] 'LeadTimeDays',
	[IsChillerStock] [bit] 'IsChillerStock',
	[TaxRate] [decimal](18, 3) 'TaxRate',
	[UnitPrice] [decimal](18, 2) 'UnitPrice')) AS sr
ON (tg.StockItemName = sr.StockItemName)
WHEN MATCHED
THEN UPDATE SET 
				SupplierID=sr.SupplierID,
				UnitPackageID=sr.UnitPackageID,
				OuterPackageID=sr.OuterPackageID,
				QuantityPerOuter=sr.QuantityPerOuter,
				TypicalWeightPerUnit=sr.TypicalWeightPerUnit,
				LeadTimeDays=sr.LeadTimeDays,
				IsChillerStock=sr.IsChillerStock,
				TaxRate=sr.TaxRate,
				UnitPrice=sr.UnitPrice
				
WHEN NOT MATCHED
THEN INSERT
				(StockItemName,
				SupplierID,
				UnitPackageID,
				OuterPackageID,
				QuantityPerOuter,
				TypicalWeightPerUnit,
				LeadTimeDays,
				IsChillerStock,
				TaxRate,
				UnitPrice,
				LastEditedBy)
VALUES		
				(sr.StockItemName,
				sr.SupplierID,
				sr.UnitPackageID,
				sr.OuterPackageID,
				sr.QuantityPerOuter,
				sr.TypicalWeightPerUnit,
				sr.LeadTimeDays,
				sr.IsChillerStock,
				sr.TaxRate,
				sr.UnitPrice,
				1)
		OUTPUT inserted.*,  $action, deleted.*;

EXEC sp_xml_removedocument @hdoc
-------------------------------
-------------------------------
MERGE Warehouse.StockItems AS tg
USING (
SELECT ltrim(t.Item.value('(@Name)[1]', 'nvarchar(100)')) AS StockItemName,
	t.Item.value('(SupplierID)[1]', 'int') AS SupplierID,
	t.Item.value('(Package/UnitPackageID)[1]', 'int') AS UnitPackageID,
	t.Item.value('(Package/OuterPackageID)[1]', 'int') AS OuterPackageID,
	t.Item.value('(Package/QuantityPerOuter)[1]', 'int') AS QuantityPerOuter,
	t.Item.value('(Package/TypicalWeightPerUnit)[1]', 'decimal(18, 3)') AS TypicalWeightPerUnit,
	t.Item.value('(LeadTimeDays)[1]', 'int') AS LeadTimeDays,
	t.Item.value('(IsChillerStock)[1]', 'bit') AS IsChillerStock,
	t.Item.value('(TaxRate)[1]', 'decimal(18, 3)') AS TaxRate,
	t.Item.value('(UnitPrice)[1]', 'decimal(18, 2)') AS UnitPrice
FROM @x.nodes('/StockItems/Item') AS t(Item)) AS sr
ON (tg.StockItemName = sr.StockItemName)
WHEN MATCHED
THEN UPDATE SET 
				SupplierID=sr.SupplierID,
				UnitPackageID=sr.UnitPackageID,
				OuterPackageID=sr.OuterPackageID,
				QuantityPerOuter=sr.QuantityPerOuter,
				TypicalWeightPerUnit=sr.TypicalWeightPerUnit,
				LeadTimeDays=sr.LeadTimeDays,
				IsChillerStock=sr.IsChillerStock,
				TaxRate=sr.TaxRate,
				UnitPrice=sr.UnitPrice
				
WHEN NOT MATCHED
THEN INSERT
				(StockItemName,
				SupplierID,
				UnitPackageID,
				OuterPackageID,
				QuantityPerOuter,
				TypicalWeightPerUnit,
				LeadTimeDays,
				IsChillerStock,
				TaxRate,
				UnitPrice,
				LastEditedBy)
VALUES		
				(sr.StockItemName,
				sr.SupplierID,
				sr.UnitPackageID,
				sr.OuterPackageID,
				sr.QuantityPerOuter,
				sr.TypicalWeightPerUnit,
				sr.LeadTimeDays,
				sr.IsChillerStock,
				sr.TaxRate,
				sr.UnitPrice,
				1)
		OUTPUT inserted.*,  $action, deleted.*;

/*
2. Выгрузить данные из таблицы StockItems в такой же xml-файл, как StockItems.xml
*/
DROP TABLE IF EXISTS WideWorldImporters.dbo.Tbl;
SELECT 
	--StockItemName AS [@Name],
	SupplierID AS [SupplierID],
	UnitPackageID AS [Package/UnitPackageID],
	OuterPackageID AS [Package/OuterPackageID],
	QuantityPerOuter AS [Package/QuantityPerOuter],
	TypicalWeightPerUnit AS [Package/TypicalWeightPerUnit],
	LeadTimeDays AS [LeadTimeDays],
	IsChillerStock AS [IsChillerStock],
	TaxRate AS [TaxRate],
	UnitPrice AS [UnitPrice]
INTO WideWorldImporters.dbo.Tbl
FROM WideWorldImporters.Warehouse.StockItems;

DECLARE @cmd varchar(4000) = 'bcp "SELECT * FROM WideWorldImporters.dbo.Tbl FOR XML PATH(''Item''), ROOT(''StockItems'')" queryout "D:\1\StockItems2.xml" -r -T -w -x -S ' + @@SERVERNAME;
EXEC master..xp_cmdshell @cmd;

/*
3. В таблице Warehouse.StockItems в колонке CustomFields есть данные в JSON.
Написать SELECT для вывода:
- StockItemID
- StockItemName
- CountryOfManufacture (из CustomFields)
- FirstTag (из поля CustomFields, первое значение из массива Tags)
*/

SELECT 
	StockItemID, 
	StockItemName,
	JSON_VALUE(CustomFields, '$.CountryOfManufacture') AS CountryOfManufacture,
	JSON_VALUE(CustomFields, '$.Tags[0]') AS FirstTag
FROM Warehouse.StockItems;
/*
4. Найти в StockItems строки, где есть тэг "Vintage".
Вывести: 
- StockItemID
- StockItemName
- (опционально) все теги (из CustomFields) через запятую в одном поле

Тэги искать в поле CustomFields, а не в Tags.
Запрос написать через функции работы с JSON.
Для поиска использовать равенство, использовать LIKE запрещено.

Должно быть в таком виде:
... where ... = 'Vintage'

Так принято не будет:
... where ... Tags like '%Vintage%'
... where ... CustomFields like '%Vintage%' 
*/

SELECT 
	StockItemID, 
	StockItemName,
	STRING_AGG(CustomFieldsTags.Value,', ') AS Tags
FROM Warehouse.StockItems
OUTER APPLY OPENJSON(CustomFields, '$.Tags') AS CustomFieldsTagsVintage
OUTER APPLY OPENJSON(CustomFields, '$.Tags') AS CustomFieldsTags
WHERE CustomFieldsTagsVintage.Value='Vintage'
GROUP BY StockItemID, StockItemName;
----------------------------------------
SELECT 
	StockItemID, 
	StockItemName,
	STUFF((SELECT ', ' + CustomFieldsTags.Value 
		FROM OPENJSON(CustomFields, '$.Tags') AS CustomFieldsTags
		for xml path('')), 1, 2, '') AS Tags 
FROM Warehouse.StockItems AS s
OUTER APPLY OPENJSON(CustomFields, '$.Tags') AS CustomFieldsTagsVintage
WHERE CustomFieldsTagsVintage.Value='Vintage';
