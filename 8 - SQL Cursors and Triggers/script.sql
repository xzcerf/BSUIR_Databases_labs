--lab8

USE Склад_118
GO


/***********************************************************************
1. Создайте для таблицы Заказ триггер tr_Set_СрокПоставки, с помощью которого в этой таблице будет автоматически устанавливаться
значение поля СрокПоставки при вставке новой записи и при обновлении поля ДатаЗаказа следующим образом:
	- если цена товара определена в белорусских рублях, то срок поставки равен дате заказа плюс 3 дня;
	- если цена товара определена в российских рублях или украинских гривнах, то срок поставки равен дате заказа плюс 7 дней;
	- если цена товара определена в долларах США или евро, то срок поставки равен дате заказа плюс 10 дней;
	- если цена товара определена в валюте, отличной от указанных выше валют, то срок поставки равен дате заказа плюс 14 дней.  
***********************************************************************/
CREATE TRIGGER tr_Set_СрокПоставки
ON Заказ
FOR UPDATE, INSERT
AS
BEGIN
	IF (UPDATE(ДатаЗаказа) AND EXISTS(SELECT * FROM inserted) and EXISTS (SELECT * FROM deleted)) OR
	(EXISTS(SELECT * from inserted) and NOT EXISTS (SELECT * FROM deleted))
	BEGIN
		DECLARE @OrderCode INT
		DECLARE @ClientCode INT
		DECLARE @ProductCode INT
		DECLARE @Amount NUMERIC(12, 3)
		DECLARE @OrderDate DATETIME
		DECLARE @SupplyDate DATETIME
		DECLARE @SupplierCode INT
		
		DECLARE myCursor CURSOR LOCAL STATIC FOR SELECT * FROM inserted
				
		OPEN myCursor

		FETCH FIRST FROM myCursor INTO @OrderCode, 
		@ClientCode, @ProductCode,
		@Amount, @OrderDate,
		@SupplyDate, @SupplierCode

		WHILE @@FETCH_STATUS = 0
		BEGIN	
			DECLARE @CurrencyCode char(3)
			SELECT @CurrencyCode = Товар.КодВалюты
			FROM Заказ
			INNER JOIN Товар ON Заказ.КодТовара = Товар.КодТовара
			WHERE Заказ.КодЗаказа = @OrderCode
			
			IF @CurrencyCode = 'BYR'
				UPDATE Заказ
				SET СрокПоставки = ДатаЗаказа + 3
				WHERE @OrderCode = КодЗаказа	
			ELSE
			BEGIN
				IF @CurrencyCode = 'RYB' OR @CurrencyCode = 'GRV'
					UPDATE Заказ
					SET СрокПоставки = ДатаЗаказа + 7
					WHERE @OrderCode = КодЗаказа	
				ELSE
				BEGIN
					IF @CurrencyCode = 'USD' OR @CurrencyCode = 'EUR'
						UPDATE Заказ
						SET СрокПоставки = ДатаЗаказа + 10
						WHERE @OrderCode = КодЗаказа	
					ELSE
						UPDATE Заказ
						SET СрокПоставки = ДатаЗаказа + 14
						WHERE @OrderCode = КодЗаказа
				END
			END 
			FETCH NEXT FROM myCursor INTO @OrderCode, @ClientCode, @ProductCode,
			@Amount, @OrderDate,
			@SupplyDate, @SupplierCode 
		END

		CLOSE myCursor
		DEALLOCATE myCursor
	END
END
GO


SELECT * FROM Заказ
INSERT INTO Заказ
 VALUES (1, 222, 10, DEFAULT, '12.10.15', 345)
SELECT * FROM Заказ
GO


SELECT * FROM Заказ
UPDATE Заказ
SET ДатаЗаказа = '01.01.2011'
WHERE КодКлиента = 1
SELECT * FROM Заказ
GO

/***********************************************************************
2. Добавьте в базу данных новую таблицу Отпуск, которая снабжена связью типа «один к одному» с таблицей Товар:
***********************************************************************/


CREATE TABLE Отпуск (
   КодТовара INT  PRIMARY KEY,
   Наименование	VARCHAR(50)  NOT NULL,
   ВсегоЗаказано	NUMERIC(12, 3)  NULL,
   CONSTRAINT  FK_Отпуск_Товар  FOREIGN KEY (КодТовара)
	 REFERENCES Товар ON UPDATE CASCADE
 )
 GO
 
/***********************************************************************
Создайте для таблицы Заказ триггер tr_Кол _ЗаказанногоТовара, с помощью которого в таблице 
Отпуск будет автоматически обновляться  информация о суммарном количестве заказанного товара. 
Триггер должен срабатывать при операциях вставки и удаления строк в таблице Заказ, а также при обновлении в ней поля Количество. 
Если в таблице Отпуск еще нет строки, подлежащей корректировке (а так вначале и будет), 
то должна быть выполнена операция вставки новой строки, в которой в поле ВсегоЗаказано записывается суммарное количество заказанного товара,
подсчитанное на основе всех строк таблицы Заказ, связанных с данным товаром.
***********************************************************************/

CREATE  TRIGGER tr_Кол_ЗаказанногоТовара
ON Заказ
FOR DELETE, INSERT, UPDATE
AS
BEGIN 
	DECLARE @OrderCode INT
	DECLARE @ClientCode INT
	DECLARE @ProductCode INT
	DECLARE @Amount NUMERIC(12, 3)
	DECLARE @OrderDate DATETIME
	DECLARE @SupplyDate DATETIME
	DECLARE @SupplierCode INT
	DECLARE @ProductName VARCHAR(50)
	DECLARE @TotalOrder INT
		
	IF (UPDATE(Количество) AND EXISTS(SELECT * from inserted) AND EXISTS (SELECT * from deleted))
	BEGIN 
		PRINT 'UPDATE'
		DECLARE myCursor1 CURSOR LOCAL STATIC FOR SELECT * FROM inserted  
		OPEN myCursor1

		FETCH FIRST FROM myCursor1 INTO @OrderCode, 
		@ClientCode, @ProductCode,
		@Amount, @OrderDate,
		@SupplyDate, @SupplierCode 

		WHILE @@FETCH_STATUS = 0
		BEGIN
			SET @TotalOrder = 0
			SELECT @ProductName = Товар.Наименование
			FROM Товар
			WHERE @ProductCode = Товар.КодТовара

			SELECT @TotalOrder = SUM(Количество)
			FROM Заказ 
			WHERE @ProductCode = КодТовара
			IF NOT EXISTS (SELECT * FROM Отпуск WHERE @ProductCode = Отпуск.КодТовара)	
			BEGIN	
				INSERT INTO Отпуск
				VALUES(@ProductCode, @ProductName, @TotalOrder)	
			END 
			ELSE 
			BEGIN
				UPDATE Отпуск
				SET ВсегоЗаказано = @TotalOrder
				WHERE @ProductCode = КодТовара
			END
			FETCH NEXT FROM myCursor1 INTO @OrderCode,
			@ClientCode, @ProductCode,
			@Amount, @OrderDate,
			@SupplyDate, @SupplierCode 
		END

		CLOSE myCursor1
		DEALLOCATE myCursor1
	END
	
	IF  EXISTS(SELECT * from inserted) and NOT EXISTS (SELECT * from deleted)
	BEGIN 
		PRINT 'INSERT'
		DECLARE myCursor1 CURSOR LOCAL STATIC FOR SELECT * FROM inserted  
		OPEN myCursor1

		FETCH FIRST FROM myCursor1 INTO @OrderCode,
		@ClientCode, @ProductCode,
		@Amount, @OrderDate,
		@SupplyDate, @SupplierCode

		WHILE @@FETCH_STATUS = 0
		BEGIN
			IF NOT EXISTS(SELECT * FROM Отпуск WHERE @ProductCode = Отпуск.КодТовара)  	
			BEGIN	
				SET @TotalOrder = 0
				SELECT @ProductName = Товар.Наименование
				FROM Товар
				WHERE @ProductCode = Товар.КодТовара
				
				
				SELECT @TotalOrder = SUM(Количество)
				FROM Заказ  
				WHERE @ProductCode = КодТовара

				INSERT INTO Отпуск
				VALUES(@ProductCode, @ProductName, @TotalOrder)	
			END 
			ELSE 
			BEGIN
				SELECT @TotalOrder = Отпуск.ВсегоЗаказано + @Amount , @ProductCode = Отпуск.КодТовара
				FROM Отпуск
				WHERE @ProductCode = Отпуск.КодТовара

				UPDATE Отпуск
				SET ВсегоЗаказано = @TotalOrder
				WHERE @ProductCode = КодТовара
			END
			FETCH NEXT FROM myCursor1 INTO @OrderCode,
			@ClientCode, @ProductCode,
			@Amount, @OrderDate,
			@SupplyDate, @SupplierCode 
		END

		CLOSE myCursor1
		DEALLOCATE myCursor1
	END
	
	IF NOT EXISTS(SELECT * from inserted) and EXISTS (SELECT * from deleted)
	BEGIN 
		PRINT 'DELETE'
		DECLARE myCursor1 CURSOR LOCAL STATIC FOR SELECT * FROM deleted  
		OPEN myCursor1

		FETCH FIRST FROM myCursor1 INTO @OrderCode,
		@ClientCode, @ProductCode,
		@Amount, @OrderDate,
		@SupplyDate, @SupplierCode 

		WHILE @@FETCH_STATUS = 0
		BEGIN
			IF NOT EXISTS(SELECT * FROM Отпуск WHERE @ProductCode = Отпуск.КодТовара)  	
			BEGIN	
				SET @TotalOrder = 0
				SELECT @ProductName = Товар.Наименование
				FROM Товар
				WHERE @ProductCode = Товар.КодТовара

				SELECT @TotalOrder = SUM(Количество)
				FROM Заказ  
				WHERE @ProductCode = КодТовара
				
				IF @TotalOrder IS NULL
					SET @TotalOrder = 0

				INSERT INTO Отпуск
				VALUES(@ProductCode, @ProductName, @TotalOrder)	
			END 
			ELSE 
			BEGIN
				SELECT @TotalOrder = Отпуск.ВсегоЗаказано , @ProductCode = Отпуск.КодТовара
				FROM Отпуск
				WHERE @ProductCode = Отпуск.КодТовара
				IF(@TotalOrder > 0)
					SET @TotalOrder = @TotalOrder - @Amount
				UPDATE Отпуск
				SET Отпуск.ВсегоЗаказано = @TotalOrder
				WHERE @ProductCode = КодТовара
			END
			FETCH NEXT FROM myCursor1 INTO @OrderCode,
			@ClientCode, @ProductCode,
			@Amount, @OrderDate,
			@SupplyDate, @SupplierCode 
		END

		CLOSE myCursor1
		DEALLOCATE myCursor1
	END
END
GO

SELECT * FROM Заказ
INSERT INTO Заказ		
VALUES (1, 111, 225, DEFAULT, DEFAULT, NULL)   
SELECT * FROM Заказ
SELECT * FROM Отпуск
GO

SELECT * FROM Заказ
DELETE Заказ
WHERE КодТовара = 222
SELECT * FROM Заказ
SELECT * FROM Отпуск
GO

SELECT * FROM Заказ
UPDATE Заказ
SET Количество = 10
WHERE   КодКлиента = 1
SELECT * FROM Заказ
SELECT * FROM Отпуск
GO

/***********************************************************************
3. Создайте хранимую процедуру pr_Стоимость_ВалютаИнтервал для решения более общей задачи по сравнению с задачей, 
рассмотренной в разделе I, а именно: необходимо подсчитать суммарную стоимость всех товаров, 
заказанных в течение указанного интервала времени, однако не в национальной валюте, а в валюте, 
указанной пользователем (в частности, может быть указана и национальная валюта). 
Эта процедура должна иметь три входных параметра (@КодВалюты, @НачалоИнтервала, @КонецИнтервала) и один выходной параметр (@Стоимость).
***********************************************************************/

CREATE PROCEDURE pr_Стоимость_ВалютаИнтервал
@IntervalStart DATETIME, 
@IntervalEnd DATETIME,
@CurrencyCode CHAR(3),
@TotalPrice MONEY OUTPUT
AS
BEGIN
	IF @IntervalStart IS NULL
		SET @IntervalStart = getdate() - 365

	IF @IntervalEnd IS NULL 
		SET @IntervalEnd = getdate()

	SET @TotalPrice = 0

	DECLARE @OrderPrice MONEY

	DECLARE myCursor CURSOR LOCAL STATIC FOR 
		SELECT Заказ.Количество * Товар.Цена
		FROM Заказ  
		INNER JOIN Товар ON Заказ.КодТовара = Товар.КодТовара
		WHERE Заказ.ДатаЗаказа BETWEEN @IntervalStart AND
		@IntervalEnd AND Товар.КодВалюты = @CurrencyCode
	OPEN myCursor

	FETCH FIRST FROM myCursor INTO @OrderPrice
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @TotalPrice = @TotalPrice + @OrderPrice
		FETCH NEXT FROM myCursor INTO @OrderPrice
	END
	CLOSE myCursor
	DEALLOCATE myCursor
END
GO

DECLARE @Cost MONEY, @CurrencyCode CHAR(3)
SET @CurrencyCode = 'USD'
EXEC pr_Стоимость_ВалютаИнтервал NULL, NULL, @CurrencyCode, @Cost OUTPUT
SELECT getdate() - 365 AS [Начало интервала], getdate() AS [Конец интервала],
@Cost AS [Стоимость заказов], @CurrencyCode AS [CurrencyCode]
GO

DECLARE @BeginDate DATETIME, @EndDate DATETIME, @Cost MONEY, @CurrencyCode CHAR(3)
SET DATEFORMAT dmy
SET @BeginDate = '10.04.2000'
SET @EndDate = '30.12.2022'
DECLARE @CostCurrency MONEY, @CostCurrencyCode CHAR(3)
SET @CurrencyCode = 'BYR'
EXEC pr_Стоимость_ВалютаИнтервал @BeginDate, @EndDate,@CurrencyCode, @Cost OUTPUT
SELECT @BeginDate AS [Начало интервала], @EndDate AS [Конец интервала],
@Cost AS [Стоимость заказов], @CurrencyCode AS [CurrencyCode]
GO
 
/***********************************************************************
4. Добавьте в таблицу Регион две новые строки, используя следующие команды:
***********************************************************************/
 
INSERT INTO Регион 
VALUES (999, 'Russia', '', 'Moskou', 'pr. Kalinina, 50', '339-62- 10', '(095) 339-62-11')

INSERT INTO Регион 
VALUES (1278, 'Lithuania', '', 'Vilnus', 'yl. Cherlenisa, 19', NULL, '(055) 33-27-75')	
GO

/***********************************************************************
Разработайте программный код (не обязательно в виде хранимой процедуры), который формирует таблицу следующего вида:
	-Страна	
	-Число клиентов	
	-Число поставщиков

При этом используйте созданную при выполнении предыдущей лабораторной работы хранимую процедуру pr_КлиентПоставщик_СтранаИнтервал, 
которая подсчитывает, сколько различных клиентов и поставщиков из указанной страны фигурирует в таблице Заказ (за указанный интервал времени).
Эта хранимая процедура должна применяться для формирования каждой строки в указанной выше таблице. 
Число строк этой таблицы должно равняться числу различных стран, фигурирующих в таблице Регион.
***********************************************************************/

CREATE FUNCTION pr_КлиентПоставщик_СтранаИнтервал
(@IntervalStart datetime,
@IntervalEnd datetime)
RETURNS @Amount TABLE
 (
	Country varchar(20),
	ClientAmount INT,
	SupplierAmount INT
)
AS
BEGIN
	DECLARE @Country varchar(20)
	DECLARE @ClientAmount INT
	DECLARE @SupplierAmount INT

	DECLARE myCursor CURSOR LOCAL STATIC FOR 	
		SELECT Страна
		FROM Регион 
		GROUP BY Страна
	OPEN myCursor

	FETCH FIRST FROM myCursor INTO @Country
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @SupplierAmount = 0
		SELECT @SupplierAmount = @SupplierAmount + 1
		FROM Регион
		INNER JOIN Поставщик ON Поставщик.КодРегиона = Регион.КодРегиона 
		INNER JOIN Заказ ON Заказ.КодПоставщика = Поставщик.КодПоставщика 
		WHERE @Country = Страна AND Заказ.ДатаЗаказа
		BETWEEN @IntervalStart AND @IntervalEnd
		GROUP BY Поставщик.ИмяПоставщика
		
		SET @ClientAmount = 0
		SELECT @ClientAmount = @ClientAmount + 1
		FROM Регион
		INNER JOIN Клиент ON Клиент.КодРегиона = Регион.КодРегиона 
		INNER JOIN Заказ ON Заказ.КодКлиента = Клиент.КодКлиента 
		WHERE @Country = Страна AND Заказ.ДатаЗаказа 
		BETWEEN @IntervalStart AND @IntervalEnd
		GROUP BY Клиент.ИмяКлиента

		INSERT INTO @Amount
		VALUES(@Country, @ClientAmount, @SupplierAmount)
		FETCH NEXT FROM myCursor INTO @Country
	END

	CLOSE myCursor
	DEALLOCATE myCursor
	RETURN
END
GO

SELECT * FROM pr_КлиентПоставщик_СтранаИнтервал ('2011-09-04 00:00:00.000', '2022-12-12 00:00:00.000')
GO

/***********************************************************************
5. Создайте таблицу Протокол со структурой, приведенной ниже, в которой должны автоматически фиксироваться все действия, 
вызванные вставкой, обновлением или удалением данных в таблице Товар. Каждая команда, изменяющая содержимое таблицы Товар, 
должна быть отражена отдельной строкой в таблице Протокол.
	-Номер	
	-ДатаВремя	
	-Пользователь	
	-Действие	
	-ЧислоСтрок

Здесь столбец Номер является автоинкрементным первичным ключом. В столбце Действие указывается одна из трех
возможных операций с данными: «Вставка», «Обновление», «Удаление». Столбец ЧислоСтрок будет содержать данные о числе вставленных, 
либо обновленных, либо удаленных строк в таблице Товар.
Усложненный вариант. Таблица Протокол должна включать в себя еще один столбец КодыТоваров,
в котором указываются коды товаров, фигурирующие во вставленных, обновленных или удаленных строках.
***********************************************************************/

CREATE TABLE Протокол (				
	[Номер] INT IDENTITY(1,1) PRIMARY KEY,
	[ДатаВремя] DATETIME DEFAULT getdate() NOT NULL,
	[Пользователь]	VARCHAR(60) DEFAULT SYSTEM_USER  NOT NULL,
	[Действие] VARCHAR(30) NOT NULL
	CHECK ([Действие] IN ('Insert', 'Delete', 'Update')),
	[ЧислоСтрок] INT NOT NULL,
	[КодыТоваров] VARCHAR(60) NOT NULL
)
GO

CREATE TRIGGER tr_Product_Protocol
ON Товар
FOR UPDATE, DELETE, INSERT AS
BEGIN
	DECLARE @CountRecords INT
	DECLARE @ProductCodes VARCHAR(60)
	DECLARE @ProductCode INT
	SET @ProductCodes = ''

	IF EXISTS(SELECT * from inserted) AND EXISTS (SELECT * from deleted)
	BEGIN
		DECLARE myCursor CURSOR LOCAL STATIC FOR 
			SELECT КодТовара
			FROM inserted
		OPEN myCursor

		FETCH FIRST FROM myCursor INTO @ProductCode
		WHILE @@FETCH_STATUS = 0
		BEGIN
			SET @ProductCodes =  @ProductCodes + CONVERT(varchar(10), @ProductCode) + '; ' 
			FETCH NEXT FROM myCursor INTO @ProductCode
		END

		CLOSE myCursor
		DEALLOCATE myCursor

		SELECT @CountRecords = COUNT(*)
		FROM inserted
		INSERT INTO Протокол
			Values(DEFAULT, DEFAULT, 'Update', @CountRecords, @ProductCodes)
	END
	
	IF EXISTS(SELECT * from inserted) AND NOT EXISTS (SELECT * from deleted)
	BEGIN
		DECLARE myCursor CURSOR LOCAL STATIC FOR 
			SELECT КодТовара
			FROM inserted
		OPEN myCursor

		FETCH FIRST FROM myCursor INTO @ProductCode
		WHILE @@FETCH_STATUS = 0
		BEGIN
			SET @ProductCodes = @ProductCodes + CONVERT(varchar(10), @ProductCode) + '; ' 
			FETCH NEXT FROM myCursor INTO @ProductCode
		END

		CLOSE myCursor
		DEALLOCATE myCursor

		SELECT @CountRecords = COUNT(*)
		FROM inserted
		INSERT INTO Протокол
			Values(DEFAULT, DEFAULT, 'Insert', @CountRecords, @ProductCodes )
	END

	IF NOT EXISTS(SELECT * from inserted) AND EXISTS (SELECT * from deleted)
	BEGIN
		DECLARE myCursor CURSOR LOCAL STATIC FOR 
			SELECT КодТовара
			FROM deleted
		OPEN myCursor

		FETCH FIRST FROM myCursor INTO @ProductCode
		WHILE @@FETCH_STATUS = 0
		BEGIN
			SET @ProductCodes =  @ProductCodes + CONVERT(varchar(10), @ProductCode) + '; ' 
			FETCH NEXT FROM myCursor INTO @ProductCode
		END

		CLOSE myCursor
		DEALLOCATE myCursor

		SELECT @CountRecords = COUNT(*)
		FROM deleted
		INSERT INTO Протокол
		Values(DEFAULT, DEFAULT, 'Delete', @CountRecords, @ProductCodes)
	END
END
GO

SELECT * FROM Протокол
SELECT * FROM Товар

INSERT INTO Товар
VALUES (1110, 'Проверочный товар 1', 'штукав', 20, 'USD', 'Нет'),
(1111, 'Проверочный товар 2', 'штукав', 20, 'USD', 'Нет')

SELECT * FROM Протокол
SELECT * FROM Товар
GO
    
UPDATE Товар
SET Цена = 100
WHERE ЕдиницаИзм = 'штукав'

SELECT * FROM Протокол
SELECT * FROM Товар
GO

DELETE Товар
WHERE Наименование = 'Проверочный товар 1'

SELECT * FROM Протокол
SELECT * FROM Товар
GO

/***********************************************************************
6. Доведите до завершения рассмотренную выше в виде примера задачу корректировки значений полей
Стоимость и СтоимостьНВ в таблице Заказ. Значения этих полей должны автоматически обновляться не только
при изменении цены товара (как было реализовано в примере), но и при изменении количества заказанного товара,
а также вставке новых строк в таблицу Заказ. Кроме того, значение столбца СтоимостьНВ должно
автоматически обновляться также при изменении курса соответствующей валюты.
***********************************************************************/

ALTER TABLE Заказ ADD Стоимость MONEY NULL
ALTER TABLE Заказ ADD СтоимостьНВ MONEY NULL
GO

CREATE TRIGGER tr_Товар_Цена
ON Товар 
FOR UPDATE AS
BEGIN
	IF UPDATE(Цена) 
    BEGIN
		DECLARE @ProductCode INT
		DECLARE @Price MONEY
		DECLARE @PriceNC MONEY

		DECLARE myCursor CURSOR LOCAL STATIC FOR 
			SELECT inserted.КодТовара, inserted.Цена,
			inserted.Цена * Валюта.КурсВалюты
        FROM inserted 
		INNER JOIN Валюта ON inserted.КодВалюты = Валюта.КодВалюты	
		OPEN myCursor

		FETCH FIRST FROM myCursor INTO @ProductCode, @Price, @PriceNC
		WHILE @@FETCH_STATUS = 0
		BEGIN
			UPDATE Заказ
			SET Стоимость = Количество * @Price, СтоимостьНВ = Количество * @PriceNC
			WHERE КодТовара = @ProductCode

			FETCH NEXT FROM myCursor INTO @ProductCode, @Price, @PriceNC 
        END

		CLOSE myCursor
		DEALLOCATE myCursor
	END
END
GO

SELECT * FROM Товар
SELECT * FROM Заказ

UPDATE Товар
SET Цена = 100.0
WHERE ЕдиницаИзм = 'штука'

SELECT * FROM Товар
SELECT * FROM Заказ
GO

CREATE TRIGGER tr_Заказ_Цена
ON Заказ 
FOR UPDATE, INSERT AS
BEGIN
	IF UPDATE(Количество) OR (EXISTS(SELECT * from inserted) and NOT EXISTS (SELECT * from deleted))
	BEGIN
		DECLARE @OrderCode INT
		DECLARE @Price MONEY
		DECLARE @PriceNC MONEY

		DECLARE myCursor CURSOR LOCAL STATIC FOR 
			SELECT inserted.КодЗаказа, Товар.Цена, Товар.Цена * Валюта.КурсВалюты
        FROM inserted 
		INNER JOIN Товар ON inserted.КодТовара = Товар.КодТовара
		INNER JOIN Валюта ON Товар.КодВалюты = Валюта.КодВалюты	
		OPEN myCursor

		FETCH FIRST FROM myCursor INTO @OrderCode, @Price, @PriceNC 
		WHILE @@FETCH_STATUS = 0
		BEGIN
			UPDATE Заказ
			SET Стоимость = Количество * @Price, 
            СтоимостьНВ = Количество * @PriceNC
			WHERE КодЗаказа = @OrderCode

			FETCH NEXT FROM myCursor INTO @OrderCode, @Price, @PriceNC 
		END

		CLOSE myCursor
		DEALLOCATE myCursor
	END
END
GO

/*Удалить все тригеры из Заказа, т.к. в них берутся строки по * и будут ошибки!!!*/
SELECT * FROM Заказ
INSERT INTO Заказ
VALUES (1, 222, 10, '02.10.15', '12.10.15', 345, NULL, NULL)
SELECT * FROM Заказ
GO
	
UPDATE Заказ
SET Количество = 15
WHERE КодКлиента = 1
SELECT * FROM Заказ
GO

CREATE TRIGGER tr_Валюта_Цена
ON Валюта 
FOR UPDATE AS
BEGIN
	IF UPDATE(КурсВалюты) 
	BEGIN
		DECLARE @ProductCode INT
		DECLARE @Price MONEY
		DECLARE @PriceNC MONEY

		DECLARE myCursor CURSOR LOCAL STATIC FOR 
			SELECT Товар.КодТовара, Товар.Цена, Товар.Цена * inserted.КурсВалюты
		FROM inserted
		INNER JOIN Товар ON Товар.КодВалюты = inserted.КодВалюты
		OPEN myCursor

		FETCH FIRST FROM myCursor INTO @ProductCode, @Price, @PriceNC 
		WHILE @@FETCH_STATUS = 0
        BEGIN
			UPDATE Заказ
			SET Стоимость = Количество * @Price, СтоимостьНВ = Количество * @PriceNC
			WHERE КодТовара = @ProductCode

			FETCH NEXT FROM myCursor INTO @ProductCode, @Price, @PriceNC 
		END

		CLOSE myCursor
		DEALLOCATE myCursor
	END
END
GO

SELECT * FROM Валюта
SELECT * FROM Заказ

UPDATE Валюта
SET КурсВалюты = 10
WHERE КодВалюты = 'BYR'

SELECT * FROM Валюта
SELECT * FROM Заказ
GO