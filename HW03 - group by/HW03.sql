/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, GROUP BY, HAVING".

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
1. Посчитать среднюю цену товара, общую сумму продажи по месяцам.
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Средняя цена за месяц по всем товарам
* Общая сумма продаж за месяц

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

select year(i.[InvoiceDate]) as InvoicesYear
	, month(i.[InvoiceDate]) as InvoicesMonth
	, avg(l.[UnitPrice]) as InvoicesAveragePrice
	, sum(l.[ExtendedPrice]) as InvoicesAmount
from [Sales].[Invoices] i 
	join [Sales].[InvoiceLines] l on i.InvoiceID=l.InvoiceId
group by year(i.[InvoiceDate]), month(i.[InvoiceDate])
order by InvoicesYear, InvoicesMonth


/*
2. Отобразить все месяцы, где общая сумма продаж превысила 4 600 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

select year(i.[InvoiceDate]) as InvoicesYear
	, month(i.[InvoiceDate]) as InvoicesMonth
	, sum(l.[ExtendedPrice]) as InvoicesAmount
from [Sales].[Invoices] i 
	join [Sales].[InvoiceLines] l on i.InvoiceID=l.InvoiceId
group by year(i.[InvoiceDate]), month(i.[InvoiceDate])
having sum(l.[ExtendedPrice])>4600000
order by InvoicesYear, InvoicesMonth

/*
3. Вывести сумму продаж, дату первой продажи
и количество проданного по месяцам, по товарам,
продажи которых менее 50 ед в месяц.
Группировка должна быть по году,  месяцу, товару.

Вывести:
* Год продажи
* Месяц продажи
* Наименование товара
* Сумма продаж
* Дата первой продажи
* Количество проданного

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

select year(i.[InvoiceDate]) as InvoicesYear
	, month(i.[InvoiceDate]) as InvoicesMonth
	, s.[StockItemName] as StockItemName
	, sum(l.[ExtendedPrice]) as InvoicesAmount
	, min(i.[InvoiceDate]) as InvoicesMinDate
	, sum(l.[Quantity]) as InvoicesQuantity
from [Sales].[Invoices] i 
	join [Sales].[InvoiceLines] l on i.InvoiceID=l.InvoiceId
	join [Warehouse].[StockItems] s on l.[StockItemID]=s.[StockItemID]
group by year(i.[InvoiceDate]), month(i.[InvoiceDate]), s.[StockItemName]
having sum(l.[Quantity])<50
order by InvoicesYear, InvoicesMonth, StockItemName

-- ---------------------------------------------------------------------------
-- Опционально
-- ---------------------------------------------------------------------------
/*
Написать запросы 2-3 так, чтобы если в каком-то месяце не было продаж,
то этот месяц также отображался бы в результатах, но там были нули.
*/
-- 3-ий запрос с месяцами, где не было продаж
select InvoicesYearCalendar
	, InvoicesMonthCalendar
	, StockItemName
	, isnull(InvoicesAmount,0)
	, InvoicesMinDate
	, isnull(InvoicesQuantity,0)
from (values(2013, 1),(2013, 2),(2013, 3),(2013, 4),(2013, 5),(2013, 6),(2013, 7),(2013, 8),(2013, 9),(2013, 10),(2013, 11),(2013, 12)) as tbl1 (InvoicesYearCalendar, InvoicesMonthCalendar)
left join (
select year(i.[InvoiceDate]) as InvoicesYear
	, month(i.[InvoiceDate]) as InvoicesMonth
	, s.[StockItemName] as StockItemName
	, sum(l.[ExtendedPrice]) as InvoicesAmount
	, min(i.[InvoiceDate]) as InvoicesMinDate
	, sum(l.[Quantity]) as InvoicesQuantity
from [Sales].[Invoices] i 
	join [Sales].[InvoiceLines] l on i.InvoiceID=l.InvoiceId
	join [Warehouse].[StockItems] s on l.[StockItemID]=s.[StockItemID]
group by year(i.[InvoiceDate]), month(i.[InvoiceDate]), s.[StockItemName]
having sum(l.[Quantity])<50
) a on a.InvoicesMonth=tbl1.InvoicesMonthCalendar and a.InvoicesYear=tbl1.InvoicesYearCalendar
order by tbl1.InvoicesYearCalendar, tbl1.InvoicesMonthCalendar, StockItemName


-- 2-ой запрос с месяцами, где не было продаж
select InvoicesYearCalendar
	, InvoicesMonthCalendar
	, isnull(InvoicesAmount,0) as InvoicesAmount 
from  
	(select year([InvoiceDate]) as InvoicesYearCalendar, cast(MonthCalendar.Value as int) as InvoicesMonthCalendar from [Sales].[Invoices] 
	cross apply string_split ('1 2 3 4 5 6 7 8 9 10 11 12', ' ') MonthCalendar
	group by year([InvoiceDate]), MonthCalendar.Value) b
left join 
	(select year(i.[InvoiceDate]) as InvoicesYear
		, month(i.[InvoiceDate]) as InvoicesMonth
		, sum(l.[ExtendedPrice]) as InvoicesAmount
	from [Sales].[Invoices] i 
	join [Sales].[InvoiceLines] l on i.InvoiceID=l.InvoiceId
	group by year(i.[InvoiceDate]), month(i.[InvoiceDate])
	having sum(l.[ExtendedPrice])>4600000) a on a.InvoicesMonth=InvoicesMonthCalendar and a.InvoicesYear=InvoicesYearCalendar
	order by InvoicesYearCalendar, InvoicesMonthCalendar