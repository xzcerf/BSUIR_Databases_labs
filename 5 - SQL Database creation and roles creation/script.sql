--lab5

CREATE DATABASE Склад_118    -- Вместо ХХХ подставьте свою комбинацию цифр
 ON PRIMARY                   -- Путь D:\Work\X7230XXX\ к файлам
   ( NAME = Склад_data,       -- базы данных уже должен существовать
     FILENAME = 'E:\SQL\4\Склад_118__data.mdf',
     SIZE = 5MB, 
     MAXSIZE = 75MB,
     FILEGROWTH = 3MB ),
 FILEGROUP Secondary
   ( NAME = Склад2_data,
     FILENAME = 'E:\SQL\4\Склад_118__data2.ndf',
     SIZE = 3MB, 
     MAXSIZE = 50MB,
     FILEGROWTH = 15% ),
   ( NAME = Склад3_data,
     FILENAME = 'E:\SQL\4\Склад_118__data3.ndf',
     SIZE = 4MB, 
     FILEGROWTH = 4MB )
 LOG ON
   ( NAME = Склад_log,
     FILENAME = 'E:\SQL\4\Склад_118__log.ldf',
     SIZE = 1MB,
     MAXSIZE = 10MB,
     FILEGROWTH = 20% ),
   ( NAME = Склад2_log,
     FILENAME = 'E:\SQL\4\Склад_118__log2.ldf',
     SIZE = 512KB,
     MAXSIZE = 15MB,
     FILEGROWTH = 10% )
 GO  

 USE Склад_118
 GO

 CREATE RULE Logical_rule AS @value IN ('Нет', 'Да')
 GO

 CREATE DEFAULT Logical_default AS 'Нет'
 GO

 EXEC sp_addtype Logical, 'char(3)', 'NOT NULL'
 GO

 EXEC sp_bindrule 'Logical_rule', 'Logical'
 GO

 /* Регион */
 CREATE TABLE Регион (				/* первая команда пакета */
   КодРегиона	INT  PRIMARY KEY,
   Страна		VARCHAR(20)  DEFAULT 'Беларусь'  NOT NULL,
   Область	VARCHAR(20)  NOT NULL,
   Город		VARCHAR(20)  NOT NULL,
   Адрес		VARCHAR(50)  NOT NULL,
   Телефон	CHAR(15)  NULL,
   Факс		CHAR(15)  NOT NULL  CONSTRAINT CIX_Регион2
     UNIQUE  ON Secondary,
   CONSTRAINT CIX_Регион  UNIQUE (Страна, Область, Город, Адрес)
     ON Secondary
 )

  /* Поставщик */
 CREATE TABLE Поставщик (			/* вторая команда пакета */
   КодПоставщика	INT  PRIMARY KEY,
   ИмяПоставщика	VARCHAR(40)  NOT NULL,
   УсловияОплаты	VARCHAR(30)  DEFAULT 'Предоплата'  NULL,
   КодРегиона		INT  NULL,
   Заметки		VARCHAR(MAX)  NULL,
   CONSTRAINT  FK_Поставщик_Регион  FOREIGN KEY (КодРегиона)
     REFERENCES  Регион  ON UPDATE CASCADE
 )

  /* Клиент */
 CREATE TABLE Клиент (				/* третья команда пакета */
   КодКлиента	 	INT  IDENTITY(1,1)  PRIMARY KEY,
   ИмяКлиента		VARCHAR(40)  NOT NULL,
   ФИОРуководителя	VARCHAR(60)  NULL,
   КодРегиона 		INT  NULL,
   CONSTRAINT  FK_Клиент_Регион  FOREIGN KEY (КодРегиона)
     REFERENCES  Регион  ON UPDATE CASCADE
 )

  /* Валюта */
 CREATE TABLE Валюта (				/* четвертая команда пакета */
   КодВалюты		CHAR(3)  PRIMARY KEY,
   ИмяВалюты		VARCHAR(30)  NOT NULL,
   ШагОкругления 	NUMERIC(10, 4)  DEFAULT 0.01  NULL
     CHECK (ШагОкругления IN (50, 1, 0.01)),
   КурсВалюты  	SMALLMONEY  NOT NULL  CHECK (КурсВалюты > 0)
 )

  /* Товар */
 CREATE TABLE Товар (				/* пятая команда пакета */
   КодТовара		INT  PRIMARY KEY,
   Наименование	VARCHAR(50)  NOT NULL,
   ЕдиницаИзм  	CHAR(10)  DEFAULT 'штука'  NULL,
   Цена			MONEY  NULL  CHECK (Цена > 0),
   КодВалюты		CHAR(3)  DEFAULT 'BYR'  NULL,
   Расфасован		LOGICAL  NOT NULL,
   CONSTRAINT  FK_Товар_Валюта  FOREIGN KEY (КодВалюты)
     REFERENCES  Валюта  ON UPDATE CASCADE
 )

  /* Заказ */
 CREATE TABLE Заказ (				/* шестая команда пакета */
   КодЗаказа		INT  IDENTITY(1,1)  NOT NULL,
   КодКлиента	 	INT  NOT NULL,
   КодТовара   	INT  NOT NULL,
   Количество		NUMERIC(12, 3)  NULL  CHECK (Количество > 0),
   ДатаЗаказа	 	DATETIME  DEFAULT getdate()  NULL,
   СрокПоставки	DATETIME  DEFAULT getdate() + 14  NULL,
   КодПоставщика	INT  NULL,  					
   PRIMARY KEY (КодЗаказа, КодКлиента, КодТовара),
   CONSTRAINT  FK_Заказ_Товар  FOREIGN KEY (КодТовара)  
     REFERENCES  Товар  ON UPDATE CASCADE ON DELETE CASCADE,
   CONSTRAINT  FK_Заказ_Клиент  FOREIGN KEY (КодКлиента)
     REFERENCES  Клиент  ON UPDATE CASCADE ON DELETE CASCADE,
   CONSTRAINT  FK_Заказ_Поставщик  FOREIGN KEY (КодПоставщика)
     REFERENCES  Поставщик
 )
 GO

 CREATE UNIQUE INDEX  UIX_Поставщик  ON Поставщик (ИмяПоставщика)
   ON Secondary
 CREATE UNIQUE INDEX  UIX_Клиент  ON Клиент (ИмяКлиента)
   ON Secondary
 CREATE UNIQUE INDEX  UIX_Валюта  ON Валюта (ИмяВалюты)
   ON Secondary
 CREATE UNIQUE INDEX  UIX_Товар  ON Товар (Наименование)
   ON Secondary
 CREATE INDEX  IX_Регион  ON Регион (Страна, Город)  ON Secondary
 CREATE INDEX  IX_Товар  ON Товар (ЕдиницаИзм, Наименование)
   ON Secondary
 CREATE INDEX  IX_Заказ  ON Заказ (ДатаЗаказа)  ON Secondary
 GO

 INSERT INTO Регион
 VALUES (101, 'Россия', 'Московская', 'Королев', 'ул.Мира, 15',
   '387-23-04', '387-23-05')

 INSERT INTO Регион (КодРегиона, Область, Город, Адрес, Факс)
 VALUES (201, '', 'Минск', 'ул.Гикало, 9', '278-83-88')	

 INSERT INTO Регион (КодРегиона, Область, Город, Адрес, Факс)
 VALUES (202, 'Минская', 'Воложин', 'ул.Серова, 11', '48-37-92')

 INSERT INTO Регион (КодРегиона, Область, Город, Адрес, Телефон,
   Факс)
 VALUES (203, '', 'Минск', 'ул.Кирова, 24', '269-13-76',
   '269-13-77')	

 INSERT INTO Регион (КодРегиона, Область, Город, Адрес, Факс)
 VALUES (204, 'Витебская', 'Полоцк', 'ул.Лесная, 6', '48-24-12')

 INSERT INTO Регион 
 VALUES (301, 'Украина', 'Крымская', 'Алушта', 'ул.Франко, 24',
   NULL, '46-49-16')	
 GO

 INSERT INTO Поставщик (КодПоставщика, ИмяПоставщика, КодРегиона)
VALUES (123, 'ЗАО Магистраль', 101)
INSERT INTO Поставщик (КодПоставщика, ИмяПоставщика, КодРегиона)
VALUES (345, 'ЗАО Беллифтмаш', 202)
INSERT INTO Поставщик
VALUES (987, 'ООО ”Белцветмет”', 'Отсрочка', 204,
'Постоянный поставщик')
INSERT INTO Поставщик (КодПоставщика, ИмяПоставщика, КодРегиона)
VALUES (789, 'ИП Зеленко В. Я.', 301)
INSERT INTO Поставщик
VALUES (567, 'СП ”Полихим”', 'По факту отгрузки', 203,
'Постоянный поставщик')
GO

INSERT INTO Клиент
VALUES ('ГП ”Верас”', 'Прокушев Станислав Игоревич', 202)
INSERT INTO Клиент (ИмяКлиента, ФИОРуководителя)
VALUES ('ЧП ”Якорь”', 'Яснюк В. А.')
INSERT INTO Клиент
VALUES ('ООО ”Цветной”', 'Музыченко Д. М.', 203)
INSERT INTO Клиент
VALUES ('ОАО ”Юрмега”', 'Вишневский Ю. Р.', 301)
INSERT INTO Клиент (ИмяКлиента, ФИОРуководителя)
VALUES ('ИП ”Темп”', 'Васько Григорий Терентьевич')
GO

INSERT INTO Валюта
 VALUES ('BYR', 'Белорусские рубли', 1, 1)

 INSERT INTO Валюта (КодВалюты, ИмяВалюты, КурсВалюты)
 VALUES ('RUR', 'Российские рубли', 276)

 INSERT INTO Валюта (КодВалюты, ИмяВалюты, КурсВалюты)
 VALUES ('USD', 'Доллары США', 9160)

 INSERT INTO Валюта (КодВалюты, ИмяВалюты, КурсВалюты)
 VALUES ('EUR', 'Евро', 12450)
 GO

 INSERT INTO Товар
VALUES (111, 'Монитор 21 дюйм', 'штука', 320, 'USD', 'Нет')
INSERT INTO Товар
VALUES (222, 'Мышь беспроводная Canyon', 'штука', 5, 'EUR', 'Нет')
INSERT INTO Товар
VALUES (333, 'Зарядное устройство Lenovo', 'штука', 35, 'BYR', 'Да')
INSERT INTO Товар (КодТовара, Наименование, Цена, Расфасован)
VALUES (444, 'Моноблок Asus', 1200, 'Нет')
INSERT INTO Товар (КодТовара, Наименование, Цена, Расфасован)
VALUES (555, 'Винчестер HDD 120GB', 285000, 'Да')
GO

SET DATEFORMAT dmy

INSERT INTO Заказ
VALUES (3, 111, 8, '04/09/19', '14/09/19', 567)
INSERT INTO Заказ
VALUES (2, 222, 10, '04/01/20', '14/01/20', 987)
INSERT INTO Заказ
VALUES (5, 333, 15, '22/02/20', '28/02/20', 789)
INSERT INTO Заказ
VALUES (4, 444, 20, '05/04/2020', '20/04/2020', 345)
INSERT INTO Заказ (КодКлиента, КодТовара, Количество)
VALUES (1, 555, 25)
GO

 CREATE VIEW Запрос1 AS
   SELECT TOP 100 PERCENT Товар.Наименование, Заказ.Количество, 
     Товар.ЕдиницаИзм, Поставщик.ИмяПоставщика
   FROM Заказ 
     INNER JOIN Поставщик 
       ON Заказ.КодПоставщика = Поставщик.КодПоставщика 
     INNER JOIN Товар 
       ON Заказ.КодТовара = Товар.КодТовара
   ORDER BY Товар.Наименование, Заказ.Количество DESC 
 GO

EXEC sp_addlogin 'sql1', '1111', 'Склад_118';
EXEC sp_addlogin 'sql2', '1111', 'Склад_118';
EXEC sp_addlogin 'sql3', '1111', 'Склад_118';
EXEC sp_addlogin 'sql4', '1111', 'Склад_118';
GO

EXEC sp_addsrvrolemember 'sql1', 'dbcreator'
GO

EXEC sp_grantdbaccess 'sql1', 'login1'
EXEC sp_grantdbaccess 'sql2', 'login2'
EXEC sp_grantdbaccess 'sql3', 'login3'
EXEC sp_grantdbaccess 'sql4', 'login4'
GO

EXEC sp_addrole 'Гл.бухгалтер', 'login1'
EXEC sp_addrole 'Бухгалтера', 'login1'
EXEC sp_addrole 'Экономисты', 'login1'
GO

EXEC sp_addrolemember 'db_accessadmin', 'login1'
EXEC sp_addrolemember 'Гл.бухгалтер', 'login1'
EXEC sp_addrolemember 'Бухгалтера', 'login2'
EXEC sp_addrolemember 'Бухгалтера', 'login3'
EXEC sp_addrolemember 'Бухгалтера', 'Гл.бухгалтер'
EXEC sp_addrolemember 'Экономисты', 'login4'
EXEC sp_addrolemember 'Экономисты', 'Гл.бухгалтер'
GO

GRANT SELECT, INSERT, UPDATE, DELETE
 ON Валюта TO [Гл.бухгалтер] WITH GRANT OPTION

 GRANT UPDATE
 ON Заказ TO [Гл.бухгалтер] WITH GRANT OPTION

 GRANT SELECT
 ON Запрос1 TO [Гл.бухгалтер] WITH GRANT OPTION

 GRANT UPDATE, DELETE
 ON Клиент TO [Гл.бухгалтер] WITH GRANT OPTION

 GRANT UPDATE, DELETE
 ON Поставщик TO [Гл.бухгалтер] WITH GRANT OPTION

 GRANT UPDATE, DELETE
 ON Товар TO [Гл.бухгалтер] WITH GRANT OPTION

 GRANT SELECT, INSERT
 ON Заказ TO Бухгалтера

 GRANT SELECT, INSERT
 ON Клиент TO Бухгалтера

 GRANT SELECT, INSERT
 ON Поставщик TO Экономисты

 GRANT SELECT, INSERT
 ON Товар TO Экономисты

 GRANT SELECT, INSERT, UPDATE, DELETE
 ON Регион TO public
 GO

 DENY UPDATE
 ON Заказ (ДатаЗаказа, СрокПоставки) TO [Гл.бухгалтер] CASCADE 
 GO



