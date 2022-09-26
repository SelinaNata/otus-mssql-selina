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

select StockItemID, StockItemName 
from Warehouse.StockItems
where StockItemName like '%urgent%' or StockItemName like 'Animal%'

/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

select s.SupplierID, s.SupplierName
from Purchasing.Suppliers s
left join Purchasing.PurchaseOrders o on o.SupplierID=s.SupplierID
where o.SupplierID is null

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

select OrderID, OrderD, MonthN, Qv, PartYear, CustomerName from (
select o.OrderID OrderID, format(o.OrderDate, 'dd.MM.yyyy') OrderD, format(o.OrderDate, 'MMMM') MonthN, datepart(Q,o.OrderDate) Qv, ((datepart(mm,o.OrderDate)-1)/4)+1 PartYear, c.CustomerName CustomerName, o.OrderDate OrderDate
from Sales.Orders o
left join Sales.OrderLines l on l.OrderID=o.OrderID
left join Sales.Customers c on c.CustomerID=o.CustomerID
where (l.UnitPrice>100 or l.Quantity>20) and o.PickingCompletedWhen is not null) a
group by OrderID, OrderD, MonthN, Qv, PartYear, CustomerName, OrderDate
order by Qv, PartYear, OrderDate

select OrderID, OrderD, MonthN, Qv, PartYear, CustomerName from (
select o.OrderID OrderID, format(o.OrderDate, 'dd.MM.yyyy') OrderD, format(o.OrderDate, 'MMMM') MonthN, datepart(Q,o.OrderDate) Qv, ((datepart(mm,o.OrderDate)-1)/4)+1 PartYear, c.CustomerName CustomerName, o.OrderDate OrderDate
from Sales.Orders o
left join Sales.OrderLines l on l.OrderID=o.OrderID
left join Sales.Customers c on c.CustomerID=o.CustomerID
where (l.UnitPrice>100 or l.Quantity>20) and o.PickingCompletedWhen is not null) a
group by OrderID, OrderD, MonthN, Qv, PartYear, CustomerName, OrderDate
order by Qv, PartYear, OrderDate offset 1000 row fetch first 100 rows only


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

select distinct d.DeliveryMethodName, o.ExpectedDeliveryDate, s.SupplierName, p.FullName
from Purchasing.PurchaseOrders o 
join Purchasing.Suppliers s on o.SupplierID=s.SupplierID
join Application.DeliveryMethods d on d.DeliveryMethodID=o.DeliveryMethodID
join Application.People p on p.PersonID=o.ContactPersonID
where o.ExpectedDeliveryDate between '20130101' and '20130131'
and d.DeliveryMethodName in ('Air Freight', 'Refrigerated Air Freight')
and IsOrderFinalized=1
order by d.DeliveryMethodName, o.ExpectedDeliveryDate, s.SupplierName, p.FullName

/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

select top 10 o.OrderID, c.CustomerName, p.FullName
from Sales.Orders o
join Sales.Customers c on o.CustomerID=c.CustomerID
join Application.People p on o.SalespersonPersonID=p.PersonID
order by o.OrderDate desc

/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

select distinct c.CustomerID, c.CustomerName, c.PhoneNumber
from Sales.Orders o
join Sales.OrderLines l on l.OrderID=o.OrderID
join Sales.Customers c on c.CustomerID=o.CustomerID
join Warehouse.StockItems s on s.StockItemID=l.StockItemID
where s.StockItemName='Chocolate frogs 250g'
order by c.CustomerID
