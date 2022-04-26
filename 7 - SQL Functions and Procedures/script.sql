﻿--lab7

USE Склад_118
GO

-------------------------------------------------------------------------
--                     Работа с процедурами                            --
-------------------------------------------------------------------------

/***********************************************************************
1. Создайте хранимую процедуру pr_КолебанияСпросаТоваров, которая решает  рассмотренную выше (см. раздел I) задачу определения наименования товара, 
по которому был наибольший или наименьший спрос за последние N дней. Эта процедура должна иметь два входных параметра (@Интервал, @ТипРезультата)
и два выходных параметра (@Имя, @Итог). Если значение входного параметра @ТипРезультата равно 1, находится товар наибольшего спроса. 
Если же значение параметра равно 2 – находится товар наименьшего спроса.
***********************************************************************/

CREATE PROCEDURE pr_КолебанияСпросаТовара --Создание процедуры 
	@Интервал INT, 
	@ТипРезультата INT,
	@Имя VARCHAR(50) OUTPUT,
	@Итог INT OUTPUT
AS
BEGIN
/*
Объявляем локальную переменную Code, в которой сохраним код наиболее или наименее популярного товара  
*/
DECLARE @Code INT  --Cоздаём переменные, используя команду объявления переменных DECLARE  { @local_variable  data_type } 
	/*
	Поиск самого популярного товара
	*/
	IF @ТипРезультата = 1
		/*
		Для присвоения значения переменным можно использовать команды SET (одно значение) и SELECT (много значений через запятую)
		*/
		SELECT @Code = Заказ.КодТовара, @Итог = SUM(Заказ.Количество)
		FROM Заказ
		WHERE Заказ.ДатаЗаказа BETWEEN GetDate() - @Интервал AND GetDate() --Выбираем те товары, которые были заказаны за последние N дней, указав условие
		GROUP BY Заказ.КодТовара
		ORDER BY SUM(Заказ.Количество) ASC
		/*
		Группируем записи по коду товара и для этих групп будет рассчитываться агрегированное значение, 
		общее количество заказов, с помощью встроенной функции SUM по полю Заказю.Количество.
		Результирующий набор будет сортироваться по возрастанию, а т.к. в переменные сохраняться 
		данные последней строки, то мы получим наибольшее значение
		*/
	ELSE IF @ТипРезультата = 2
		/* 
		Поиск самого непопулярного товара.
		*/
		SELECT @Code = Заказ.КодТовара, @Итог = SUM(Заказ.Количество)
		FROM Заказ
		WHERE ДатаЗаказа BETWEEN (GetDate() - @Интервал) AND GetDate()
		GROUP BY Заказ.КодТовара
		ORDER BY SUM(Заказ.Количество) DESC --То же самое, но сортировка идёт по убыванию и сохранятся наименьшие значения
	/*
	Получение названия товара по коду товара из таблицы
	*/
	SELECT @Имя = Товар.Наименование
	FROM Товар
	WHERE КодТовара = @Code
END	
GO

/*
Процедуры вызываются командой EXEC[UTE], после названия процедуоы указываются выходные (OUTPUT) переменные
*/ 
DECLARE @Имя VARCHAR(50), @Итог INT
EXEC pr_КолебанияСпросаТовара 1000, 2, @Имя OUTPUT, @Итог OUTPUT 
/*
Вывод значений переменных для проверки
*/
SELECT @Имя AS [Product Code], @Итог AS [Result]
GO

/***********************************************************************
2. Создайте хранимую процедуру pr_КлиентПоставщик_СтранаИнтервал, которая подсчитывает, 
сколько различных клиентов и различных поставщиков из указанной страны фигурирует в таблице Заказ, 
причем анализируются только те заказы, в которых значение поля Дата заказа попадает в указанный интервал дат. 
Эта процедура должна иметь три входных параметра (@Страна, @НачалоИнтервала, @КонецИнтервала) и два выходных параметра (@ЧислоКлиентов, @ЧислоПоставщиков). 
Если же значение параметра @Страна не будет указано (т.е. будет равно NULL), 
то подсчет клиентов и поставщиков должен вестись независимо от их национальной принадлежности.
***********************************************************************/

CREATE PROCEDURE pr_КлиентПоставщик_СтранаИнтервал 
	@Страна VARCHAR(20) = NULL,		-- … = NULL - это значение по умолчанию
	@НачалоИнтервала DATETIME = NULL,
	@КонецИнтервала DATETIME = NULL,
	@ЧислоКлиентов INT OUTPUT,
	@ЧислоПоставщиков INT OUTPUT
AS
BEGIN
	/*
	Если страна не указана
	*/
	IF @Страна IS NULL
		BEGIN
		/*
		С помощью DISTINCT получаем список неповторяющихся записей по полю кода клиента и кода поставщика, удовлетворяющих условию по дате заказа. 
		Количество считается при помощи COUNT 
		*/
		SELECT @ЧислоКлиентов = COUNT(DISTINCT Заказ.КодКлиента), @ЧислоПоставщиков = COUNT(DISTINCT Заказ.КодПоставщика)
		FROM Заказ
		INNER JOIN Клиент ON Заказ.КодКлиента = Клиент.КодКлиента
		INNER JOIN Поставщик ON Заказ.КодПоставщика = Поставщик.КодПоставщика
		WHERE Заказ.ДатаЗаказа BETWEEN @НачалоИнтервала AND @КонецИнтервала
		END
	ELSE 
		BEGIN
		/* 
		Поиск уникальных клиентов и поставщиков (аналогично предыдущему, но с добавлением проверки на принадлженость клиента и поставщика к указанной стране 
		*/
		SELECT @ЧислоКлиентов = COUNT(DISTINCT Заказ.КодКлиента)
		FROM Заказ
		INNER JOIN Клиент ON Заказ.КодКлиента = Клиент.КодКлиента
		INNER JOIN Регион ON Клиент.КодРегиона = Регион.КодРегиона
		INNER JOIN Поставщик ON Заказ.КодПоставщика = Поставщик.КодПоставщика
		WHERE Регион.Страна = @Страна AND Заказ.ДатаЗаказа BETWEEN @НачалоИнтервала AND @КонецИнтервала

		SELECT @ЧислоПоставщиков = COUNT(DISTINCT Заказ.КодПоставщика)
		FROM Заказ
		INNER JOIN Клиент ON Заказ.КодКлиента = Клиент.КодКлиента
		INNER JOIN Поставщик ON Заказ.КодПоставщика = Поставщик.КодПоставщика
		INNER JOIN Регион ON Поставщик.КодРегиона = Регион.КодРегиона
		WHERE Регион.Страна = @Страна AND Заказ.ДатаЗаказа BETWEEN @НачалоИнтервала AND @КонецИнтервала
		END
END	
GO

DECLARE @IB DATETIME, @IE DATETIME, @ЧислоКлиентов INT, @ЧислоПоставщиков INT
SET @IB = DATEADD(year, -4, getdate())
SET @IE = getDate()
EXEC pr_КлиентПоставщик_СтранаИнтервал /*NULL 'Украина' 'Россия' 'Беларусь'*/'Беларусь', @IB, @IE, @ЧислоКлиентов OUTPUT, @ЧислоПоставщиков OUTPUT
SELECT @ЧислоКлиентов AS [Number of clients], @ЧислоПоставщиков AS [Number of providers]
GO 

/***********************************************************************
3. Создайте хранимую процедуру pr_Товар_СтранаВалютаИнтервал, которая подсчитывает, 
сколько различных товаров в конкретной валюте было заказано клиентами из указанной страны, 
причем анализируются только те заказы, в которых значение поля Дата заказа попадает в заданный интервал дат.
Эта процедура должна иметь четыре входных параметра (@Страна, @Валюта, @НачалоИнтервала, @КонецИнтервала) 
и один выходной параметр (@ЧислоТоваров). При этом расширьте возможности процедуры следующим образом: 
-  если значение параметра @Страна не будет указано (т.е. будет равно NULL), то подсчет товаров должен вестись независимо от национальной принадлежности клиента;
-  если значение параметра @Валюта не будет указано (т.е. будет равно NULL), то подсчет товаров должен вестись применительно к национальной валюте (код валюты – BYR).
***********************************************************************/

CREATE PROCEDURE pr_Товар_СтранаВалютаИнтервал
	@Страна VARCHAR(20) = NULL,
	@Валюта char(3) = NULL,
	@НачалоИнтервала DATETIME,
	@КонецИнтервала DATETIME,
	@ЧислоТоваров INT OUTPUT
AS
BEGIN
	/* 
	Из-за большого количества условий на входне параметры, создана временная таблица, 
	для промежуточных данных, а по конечным данным будет рассчитан результат 
	*/
	DECLARE @tempTable TABLE (
		КодТовара INT,
		КодКлиента INT,
		Страна varchar(20),
		КодВалюты char(3))
	/* 
	Добавление данных с проверкой начальных условий по дате заказа 
	*/
	SELECT * FROM Заказ
	INSERT @tempTable (КодТовара, КодКлиента, КодВалюты, Страна)
		SELECT Заказ.КодТовара, Заказ.КодКлиента, Товар.КодВалюты, Регион.Страна
		FROM Заказ
		INNER JOIN Товар ON Заказ.КодТовара = Товар.КодТовара
		INNER JOIN Клиент ON Заказ.КодКлиента = Клиент.КодКлиента
		INNER JOIN Регион ON Клиент.КодРегиона = Регион.КодРегиона
		WHERE Заказ.ДатаЗаказа BETWEEN @НачалоИнтервала AND @КонецИнтервала
	SELECT * FROM @tempTable
	--Проверка параметра Страна
	IF @Страна IS NOT NULL
		--Удаление строк, не подходящих по принадлежности клиента к заданной стране
		DELETE 
		FROM @tempTable
		WHERE Страна != @Страна
	--Проверка параметра Валюта
	SELECT * FROM @tempTable
	IF @Валюта IS NOT NULL
		--Удаление строк, не подходящих по совпадению валюты цены товара с заданной валютой
		DELETE 
		FROM @tempTable
		WHERE КодВалюты != @Валюта
	--Рассчет кол-ва уникальных товаров, удовлетворяющих условиям		
	SELECT @ЧислоТоваров = COUNT(DISTINCT КодТовара)
	FROM @tempTable
	SELECT * FROM @tempTable
END
GO


DECLARE @IB DATETIME, @IE DATETIME, @ЧислоТоваров INT
SET @IB = DATEADD(year, -4, getdate())
SET @IE = getDate()
EXEC pr_Товар_СтранаВалютаИнтервал 'Беларусь', 'USD', @IB, @IE, @ЧислоТоваров OUTPUT
SELECT @ЧислоТоваров AS [Number of products]
GO


-------------------------------------------------------------------------
--                     Работа с функциями                              --
-------------------------------------------------------------------------

/***********************************************************************
4. Создайте пользовательскую функцию fn_getЧислоДней_вМесяце типа Scalar, которая для конкретной даты возвращает число дней в месяце,
который  определяется этой датой (високосность года не учитывается). Эта функция должна иметь один входной параметр (@Дата).
***********************************************************************/

CREATE FUNCTION fn_getЧислоДней_вМесяце (@Дата VARCHAR(9))
/*
Функции типа Scalar являются наиболее привычными и возвращают скалярное значение любого из типов данных, 
поддерживаемых сервером, за исключением text, ntext, image, timestamp, table и cursor. 
*/
RETURNS INT -- возвращает целое число
BEGIN
	RETURN day(EOMONTH(@Дата,0))
END
GO  

DECLARE @Дата VARCHAR(9)
SET @Дата = '4/11/2022' /*mm/dd/yyyy*/
SELECT dbo.fn_getЧислоДней_вМесяце(@Дата) AS [Days in month]
GO

/***********************************************************************
5. Создайте пользовательскую функцию fn_getФИО_вФормате типа Scalar, которая на основе текстовой строки, содержащей фамилию,
имя и отчество, формирует текстовую строку в одном из следующих форматов:
1) исходная строка переводится в верхний регистр;
2) исходная строка переводится в нижний регистр;
3) на верхнем регистре должны быть только первые буквы слов;
4) выводится только фамилия, а имя и отчество заменяются их первыми буквами с точкой.
Эта функция должна иметь два входных параметра (@ФИО, @Формат).
Усложненный вариант. Расширьте возможности функции таким образом, чтобы была допустима исходная строка (задаваемая параметром @ФИО),
содержащая не один, а несколько пробелов между фамилией и именем или между именем и отчеством, а также допускающая наличие лидирующих пробелов перед фамилией.
***********************************************************************/

CREATE FUNCTION fn_getFIO_in_format (@ФИО VARCHAR(50), @Формат INT)

RETURNS  VARCHAR(50) 
BEGIN
	DECLARE @res VARCHAR(50)
	SET @res = ''
	SET @ФИО =  TRIM(' ' FROM @ФИО) --обрезать в начале и конце
	SET @res = REPLACE(REPLACE(REPLACE(@ФИО, ' ', '<>'), '><', ''), '<>', ' '); -- пробелы заменить на скобки 
	IF  @Формат = 1
	BEGIN
		SET @res = UPPER(@ФИО)
	END
	IF @Формат = 2
	BEGIN
		SET @res = LOWER(@ФИО)
	END
	IF @Формат = 3
	BEGIN
		SET @ФИО = LOWER(@ФИО)
		DECLARE @index INT
		SET @index = 1
		WHILE (@index <= LEN(@ФИО))
		BEGIN
			/*
			Если, текущая буква первая в слове, то записываем в результат эту букву в верхнем регистре. 
			Функция SUBSTRING() выбирает из строки n символов (например, 1), начиная с символа, стоящем на позиции (например, @index)
			*/
			IF(@index = 1 OR (SUBSTRING(@ФИО, @index - 1, 1) = ' ' AND SUBSTRING(@ФИО, @index, 1) != ' '))
				SET @res = @res + UPPER(SUBSTRING(@ФИО, @index, 1))
			ELSE
				SET @res = @res + SUBSTRING(@ФИО, @index, 1)  --Другие символы остаются без изменений
			SET @index = @index + 1
		END
	END
	/*
	Формат с инициалами
	*/
	IF @Формат = 4
	BEGIN
		DECLARE @i INT
		SET @i = 1
		
		WHILE (SUBSTRING(@ФИО, @i, 1) = ' ') --Определение начала первого слова
			SET @i = @i + 1
		
		SET @res = @res + SUBSTRING(@ФИО, @i, CHARINDEX(' ', @ФИО, @i)) --Используя CHARINDEX() поиск пробела после первого слова в @ФИО, начиная с позиции i
		SET @i = CHARINDEX(' ', @ФИО, @i)
		
		WHILE (@i <= LEN(@ФИО) AND @i != 0) --Из оставшейся строки и запись только первых букв следующих слов с точкой
			BEGIN
			IF(SUBSTRING(@ФИО, @i, 1) = ' ')
				SET @i = @i + 1 
			ELSE
				BEGIN
				SET @res = @res + SUBSTRING(@ФИО, @i - 1, 2) + '.'
				SET @i = CHARINDEX(' ', @ФИО, @i)
				END
			END
	END
	RETURN @res
END
GO

DECLARE @FIO VARCHAR(50)
SET @FIO = '           Невейков     Андрей  Сергеевич'
SELECT @FIO AS [Before], dbo.fn_getFIO_in_format(@FIO, 5) AS [After]
GO

/***********************************************************************
6. Создайте пользовательскую функцию fn_getGroup_НаименованиеВалюта типа Inline Table-valued, которая возвращает таблицу со следующими столбцами:
	- Наименование товара	
	- Имя валюты	
	- Заказанное кол-во	
	- Стоимость в валюте	
	- Стоимость в национальной валюте

Эта таблица должна отражать результат группировки данных по полям Наименование и ИмяВалюты. 
Для каждой такой группы подсчитывается итоговое количество заказанного товара и итоговая стоимость в валюте и в национальной валюте.
Пользовательская функция fn_getGroup_НаименованиеВалюта должна иметь два входных параметра (@НачалоИнтервала, @КонецИнтервала), 
поэтому при формировании результирующей таблицы необходимо учитывать только те строки из таблицы Заказ, 
в которых значение поля Дата заказа попадает в указанный параметрами интервал дат.
***********************************************************************/

CREATE FUNCTION fn_getGroup_НаименованиеВалюта
	(@НачалоИнтервала DATETIME,
	 @КонецИнтервала DATETIME)
RETURNS TABLE
AS RETURN
	/*Выборка данных для таблицы, которая будет возвращена функцией*/
	SELECT Товар.Наименование, Товар.КодВалюты, SUM(Заказ.Количество) AS [Number of orders], --Указываем столбцы результирующей таблицы
	SUM(Заказ.Количество)*Товар.Цена AS [General Price], 
	SUM(Заказ.Количество)*Товар.Цена*Валюта.КурсВалюты AS [General Price in BYR]
	FROM Заказ
	/*
	Суммарное кол-во заказов расчитано для группы товаров с одинаковым наименованием т.к. группировка товаров происходит по наименованию.
	Аналогично рассчитывется общая стоимость
	*/
	INNER JOIN Товар ON Заказ.КодТовара = Товар.КодТовара
	INNER JOIN Валюта ON Товар.КодВалюты = Валюта.КодВалюты
	WHERE Заказ.ДатаЗаказа BETWEEN @НачалоИнтервала AND @КонецИнтервала
	GROUP BY Товар.Наименование, Товар.КодВалюты, Товар.Цена, Валюта.КурсВалюты
GO

SELECT * FROM fn_getGroup_НаименованиеВалюта(getDate() - 1000, getDate() + 5)

GO

/***********************************************************************
7. Создайте пользовательскую функцию fn_getTable_СтоимостьНВ типа Multi-statement Table-valued, которая возвращает таблицу со следующими столбцами:
Номер	Дата заказа	Имя клиента	Наименование товара	Количество	Цена в НВ	Стоимость в НВ
***********************************************************************/

CREATE FUNCTION  fn_getTable_СтоимостьНВ()
/*
Функция вернёт таблицу newTable c указанными полями
*/
RETURNS @НоваяТаблица TABLE (
	Number INT IDENTITY(1,1) PRIMARY KEY,
	ДатаЗаказа DATETIME NULL,
	Клиент NVARCHAR(40),
	Товар VARCHAR(50),
	Количество numeric(12, 3),
	ЦенаНВ MONEY,
	СтоимостьНВ MONEY)
BEGIN
	/*
	Заполнение новой таблицы первоначальными данными
	*/
	INSERT @НоваяТаблица (ДатаЗаказа, Клиент, Товар, Количество, ЦенаНВ, СтоимостьНВ)
		SELECT Заказ.ДатаЗаказа, Клиент.ИмяКлиента, 
		Товар.Наименование, Заказ.Количество, 
		Товар.Цена * Валюта.КурсВалюты,
		Товар.Цена * Валюта.КурсВалюты * Количество
		FROM Заказ
		INNER JOIN Товар ON Заказ.КодТовара = Товар.КодТовара
		INNER JOIN Клиент ON Заказ.КодКлиента = Клиент.КодКлиента
		INNER JOIN Валюта ON Товар.КодВалюты = Валюта.КодВалюты
		
		DECLARE @СрСтоимость MONEY --Объявление переменнной, в которой записана средняя стоимость заказов
		/*
		Рассчет средней стоимоти заказов, рассчитав среднее значение даных в поле СтоимостьНВ из новой таблицы
		*/
		SELECT @СрСтоимость = AVG(СтоимостьНВ)
		FROM @НоваяТаблица
		/*
		Удаление из таблицы заказы, стоимость которых ниже средней
		*/
		DELETE FROM @НоваяТаблица
		WHERE (СтоимостьНВ < @СрСтоимость)

		RETURN 
END

GO 

SELECT * FROM fn_getTable_СтоимостьНВ()
GO