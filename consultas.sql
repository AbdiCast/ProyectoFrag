
/*
 * Determinar el total de las ventas de los productos con la categoría que se provea
 * de argumento de entrada en la consulta,para cada uno de los territorios registrados
 * en la base de datos.
 * */

CREATE PROCEDURE sp_totalVentas @p_categoryID int
as
begin 
	SELECT
	soh.TerritoryID,
	SUM(T.lineTotal) as total_Ventas
FROM
	AdventureWorks2019.Sales.SalesOrderHeader soh
inner join
    (
	SELECT
		SalesOrderID,
		productId,
		orderqty,
		lineTotal
	FROM
		AdventureWorks2019.Sales.SalesOrderDetail sod
	WHERE
		ProductID in(
		SELECT
			productID
		FROM
			AdventureWorks2019.Production.Product
		WHERE
			ProductSubcategoryID in(
			SELECT
				productSubcategoryId
			FROM
				AdventureWorks2019.Production.ProductSubcategory
			WHERE
				ProductCategoryID in(
				SELECT
					productCategoryID
				FROM
					AdventureWorks2019.Production.ProductCategory
				WHERE
					ProductCategoryID = @p_categoryID
   				)
   			)
)) as T
    on
	soh.SalesOrderID = T.SalesOrderID
GROUP by
	soh.TerritoryId
ORDER by
	total_Ventas DESC
end

/*
 * Determinar el producto más solicitado para la región (atributo group de 
 * salesterritory)“Noth America”y en que territorio de la región tiene mayor
 * demanda.
 * Quitando el Top 1, da la lista de todos los productos
 * */

CREATE PROCEDURE sp_productoSolicitado @p_groupT nvarchar(50)  
AS
BEGIN 
	SELECT TOP 1 SUM(T.lineTotal) as total_ventas, p.Name as Nombre, p.ProductID
FROM
	AdventureWorks2019.Production.Product p
inner join(
	SELECT
		ProductID,
		lineTotal
	FROM
		AdventureWorks2019.Sales.SalesOrderDetail sod
	WHERE
		SalesOrderID in(
		SELECT
			SalesOrderID
		FROM
			AdventureWorks2019.Sales.SalesOrderHeader soh
		WHERE
			TerritoryID in(
			SELECT
				TerritoryID
			FROM
				AdventureWorks2019.Sales.SalesTerritory st
			WHERE
				[Group] = @p_groupT
			)
		)
	) as T
	on
	p.ProductID = T.ProductID
GROUP BY
	p.Name,
	p.ProductID
ORDER by
	total_ventas DESC
END 

/*
	 * Actualizar el stock disponible en un 5% de los productos de la categoría que se 
	 * provea como argumento de entrada en una localidad que se provea como entrada en 
	 * la instrucción de actualización..
	 * 
	 * NOTA: De momento solo consulta el producto con stock, dependiendo la localidad 
	 * */


/*
	 * Determinar si hay clientes que realizan ordenes en territorios diferentes al que se encuentran. 
	 * */

CREATE PROCEDURE sp_CustomerDiferrentOrder  
AS 
SELECT
	c.TerritoryID as Territorio_Cliente,
	soh.TerritoryID as Territorio_Orden
FROM
	AdventureWorks2019.Sales.Customer c
inner join 
	AdventureWorks2019.Sales.SalesOrderHeader soh 
	on
	c.CustomerID != soh.CustomerID
GROUP by
	c.TerritoryID,
	soh.TerritoryID 

/*
	 * Actualizar  la  cantidad  de  productos  de  una  orden que  se provea  como argumento en la 
	 * instrucción de actualización.
	 * NOTA: Lista la cantidad de productos, nombre y el ID de la Orden de venta
	 * */

CREATE PROCEDURE sp_OrderQtyUpdate @p_SalesOrderID int,
@p_OrderQty int
AS
BEGIN
	IF EXISTS (
	SELECT
		sod.OrderQty as Cantidad_Productos,
		p.Name as Nombre_Producto,
		sod.SalesOrderID
	FROM
		AdventureWorks2019.Sales.SalesOrderDetail sod
	inner join AdventureWorks2019.Production.Product p 
	on
		sod.ProductID = p.ProductID
		and sod.SalesOrderID = @p_SalesOrderID
	) 
		update AdventureWorks2019.Sales.SalesOrderDetail set OrderQty = @p_OrderQty where SalesOrderID = @p_SalesOrderID
ELSE 
	PRINT 'No se pudo actualizar'
END
	

/*
	 * Actualizar el método de envío de una orden que se reciba como argumento en la instrucción de actualización.
	 * NOTA: Lista todas las ordenenes dependiendo el metodo de envio
	 * */	
	
CREATE PROCEDURE sp_shipMethodUpdate @p_SalesOrderID int,
@p_ShipMethodID int
AS
BEGIN 
	IF EXISTS (
	SELECT
		sm.Name as Metodo_Envio,
		sm.ShipMethodID as ID_Metodo,
		soh.ShipMethodID as ID_Metodo_Seleccionado,
		soh.SalesOrderID
	FROM
		AdventureWorks2019.Sales.SalesOrderHeader soh
	inner join AdventureWorks2019.Purchasing.ShipMethod sm 
	on
		soh.ShipMethodID = sm.ShipMethodID
	where
		soh.SalesOrderID = @p_SalesOrderID
	)
	UPDATE AdventureWorks2019.Sales.SalesOrderHeader set ShipMethodID = @p_ShipMethodID WHERE SalesOrderID = @p_SalesOrderID
	ELSE 
		PRINT 'No se pudo actualizar'
END

/*
	 * Actualizar el correo electrónico de una cliente que se reciba como argumento en la instrucción de actualización.
	 * NOTA: Lista a la persona y su correElectronico, parametrizar por correo electronico, en lugar de BusinessEntityID
	 * */

ALTER PROCEDURE sp_emailAddressUpdate @p_EmailAddressOld nvarchar(50),@p_EmailAddressNew nvarchar(50)
AS 
BEGIN 
	IF EXISTS (
		SELECT p.FirstName as Nombre, ea.EmailAddress as Email
	FROM AdventureWorks2019.Person.Person p 
	inner join AdventureWorks2019.Person.EmailAddress ea 
	on p.BusinessEntityID = ea.BusinessEntityID 
	where ea.EmailAddress = @p_EmailAddressOld
	)
	UPDATE AdventureWorks2019.Person.EmailAddress set EmailAddress = @p_EmailAddressNew WHERE EmailAddressID = @p_EmailAddressOld
	ELSE 
		PRINT 'No se pudo actualizar'
	
END


	
	
	
	
