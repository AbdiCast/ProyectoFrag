
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


/*Ejercicio 5-c
Actualizar el stock disponible en un 5% de los productos de la categoría que se 
provea como argumento de entrada en una localidad que se provea como 
entrada en la instrucción de actualización.*/
CREATE OR ALTER PROCEDURE ActuStock @CAT nvarchar(25) AS
BEGIN 
DECLARE @PID int;
set @PID = (SELECT ProductID FROM [LINKED-PRODUCTION].productionAW.Production.ProductInventory PRID WHERE
PRID.LocationID in(SELECT ProductID FROM [LINKED-PRODUCTION].productionAW.Production.ProductSubcategory WHERE ProductCategoryID = @CAT));
update [LINKED-PRODUCTION].productionAW.Production.ProductInventory set Quantity = Quantity*1.05 WHERE ProductID = @PID;
END



/*Ejercicio 5-d
Determinar si hay clientes que realizan ordenes en territorios diferentes al que 
se encuentran.*/
CREATE OR ALTER PROCEDURE DiferentesTerritorios AS
BEGIN
SELECT SACU.TerritoryID as TerritorioC, SAOH.TerritoryID as TerritorioO, SATE.[Name] as Territorio
FROM [LINKED-SALES].salesAW.Sales.Customer SACU
INNER JOIN [LINKED-SALES].salesAW.Sales.SalesOrderHeader SAOH ON SACU.AccountNumber != SAOH.AccountNumber
INNER JOIN [LINKED-SALES].salesAW.Sales.SalesTerritory SATE ON SACU.TerritoryID = SAOH.TerritoryID
GROUP BY SACU.TerritoryID, SAOH.TerritoryID, SATE.[Name]
END




/*Ejercicio 5-e
Actualiza la cantidad de productos de una orden que se provea como argumeto en la instrucción de actualización.
			select * from sales.SalesOrderDetail
			exec sp_OrderQtyUpdate 43659,  4
cantidadDeProductos, orden*/
 

create PROCEDURE sp_OrderQtyUpdate @p_SalesOrderID int, @p_OrderQty int
AS
BEGIN
	IF EXISTS (--cantidadDeProductos, producto, orden
		SELECT sod.OrderQty as Cantidad_Productos, p.[Name] as Nombre_Producto, sod.SalesOrderID 
		FROM AdventureWorks2019_1.Sales.SalesOrderDetail sod
		inner join 
		AdventureWorks2019_1.Production.Product p 
		on
		sod.ProductID = p.ProductID and 
		sod.SalesOrderID = @p_SalesOrderID
		) 
			update AdventureWorks2019_1.Sales.SalesOrderDetail set OrderQty = @p_OrderQty where SalesOrderID = @p_SalesOrderID
	ELSE 
		PRINT 'No se pudo actualizar'
END
	

/*Ejercicio 5-f
	 * Actualizar el método de envío de una orden que se reciba como argumento en la instrucción de actualización.
	 * NOTA: Lista todas las ordenenes dependiendo el metodo de envio

	 Actualizar
	 metodoDeEnvio, orden: listar las ordenes del metodo de envio
	 * */	
	
create PROCEDURE sp_shipMethodUpdate @p_SalesOrderID int, @p_ShipMethodID int
AS
BEGIN 
	IF EXISTS (-- metodoDeEnvio, orden
		SELECT sm.[Name] as Metodo_Envio, sm.ShipMethodID as ID_Metodo, soh.ShipMethodID as ID_Metodo_Seleccionado, soh.SalesOrderID
		FROM
			AdventureWorks2019_1.Sales.SalesOrderHeader soh
		inner join 
		AdventureWorks2019_1.Purchasing.ShipMethod sm 
		on
		soh.ShipMethodID = sm.ShipMethodID
		where soh.SalesOrderID = @p_SalesOrderID
	)
	UPDATE AdventureWorks2019_1.Sales.SalesOrderHeader set ShipMethodID = @p_ShipMethodID WHERE SalesOrderID = @p_SalesOrderID
	ELSE 
		PRINT 'No se pudo actualizar'
END

/*Ejercicio 5-g
	 * Actualizar el correo electrónico de una cliente que se reciba como argumento en la instrucción de actualización.
	 * NOTA: Lista a la persona y su correElectronico, parametrizar por correo electronico, en lugar de BusinessEntityID

	 actualiza: correoDeCliente
	 * */

create PROCEDURE sp_emailAddressUpdate @p_EmailAddressOld nvarchar(50),@p_EmailAddressNew nvarchar(50)
AS 
BEGIN 
	IF EXISTS (
		SELECT p.FirstName as Nombre, ea.EmailAddress as Email
		FROM AdventureWorks2019_1.Person.Person p 
		inner join 
		AdventureWorks2019_1.Person.EmailAddress ea 
		on 
		p.BusinessEntityID = ea.BusinessEntityID 
	where ea.EmailAddress = @p_EmailAddressOld
	)
	UPDATE AdventureWorks2019_1.Person.EmailAddress set EmailAddress = @p_EmailAddressNew WHERE EmailAddressID = @p_EmailAddressOld
	ELSE 
		PRINT 'No se pudo actualizar'
	
END


	
	
	
	
