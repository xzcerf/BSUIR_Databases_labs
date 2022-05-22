--lab5

CREATE DATABASE Ñêëàä_118    -- Âìåñòî ÕÕÕ ïîäñòàâüòå ñâîþ êîìáèíàöèþ öèôð
 ON PRIMARY                   -- Ïóòü D:\Work\X7230XXX\ ê ôàéëàì
   ( NAME = Ñêëàä_data,       -- áàçû äàííûõ óæå äîëæåí ñóùåñòâîâàòü
     FILENAME = 'E:\SQL\4\Ñêëàä_118__data.mdf',
     SIZE = 5MB, 
     MAXSIZE = 75MB,
     FILEGROWTH = 3MB ),
 FILEGROUP Secondary
   ( NAME = Ñêëàä2_data,
     FILENAME = 'E:\SQL\4\Ñêëàä_118__data2.ndf',
     SIZE = 3MB, 
     MAXSIZE = 50MB,
     FILEGROWTH = 15% ),
   ( NAME = Ñêëàä3_data,
     FILENAME = 'E:\SQL\4\Ñêëàä_118__data3.ndf',
     SIZE = 4MB, 
     FILEGROWTH = 4MB )
 LOG ON
   ( NAME = Ñêëàä_log,
     FILENAME = 'E:\SQL\4\Ñêëàä_118__log.ldf',
     SIZE = 1MB,
     MAXSIZE = 10MB,
     FILEGROWTH = 20% ),
   ( NAME = Ñêëàä2_log,
     FILENAME = 'E:\SQL\4\Ñêëàä_118__log2.ldf',
     SIZE = 512KB,
     MAXSIZE = 15MB,
     FILEGROWTH = 10% )
 GO  

 USE Ñêëàä_118
 GO

 CREATE RULE Logical_rule AS @value IN ('Íåò', 'Äà')
 GO

 CREATE DEFAULT Logical_default AS 'Íåò'
 GO

 EXEC sp_addtype Logical, 'char(3)', 'NOT NULL'
 GO

 EXEC sp_bindrule 'Logical_rule', 'Logical'
 GO

 /* Ðåãèîí */
 CREATE TABLE Ðåãèîí (				/* ïåðâàÿ êîìàíäà ïàêåòà */
   ÊîäÐåãèîíà	INT  PRIMARY KEY,
   Ñòðàíà		VARCHAR(20)  DEFAULT 'Áåëàðóñü'  NOT NULL,
   Îáëàñòü	VARCHAR(20)  NOT NULL,
   Ãîðîä		VARCHAR(20)  NOT NULL,
   Àäðåñ		VARCHAR(50)  NOT NULL,
   Òåëåôîí	CHAR(15)  NULL,
   Ôàêñ		CHAR(15)  NOT NULL  CONSTRAINT CIX_Ðåãèîí2
     UNIQUE  ON Secondary,
   CONSTRAINT CIX_Ðåãèîí  UNIQUE (Ñòðàíà, Îáëàñòü, Ãîðîä, Àäðåñ)
     ON Secondary
 )

  /* Ïîñòàâùèê */
 CREATE TABLE Ïîñòàâùèê (			/* âòîðàÿ êîìàíäà ïàêåòà */
   ÊîäÏîñòàâùèêà	INT  PRIMARY KEY,
   ÈìÿÏîñòàâùèêà	VARCHAR(40)  NOT NULL,
   ÓñëîâèÿÎïëàòû	VARCHAR(30)  DEFAULT 'Ïðåäîïëàòà'  NULL,
   ÊîäÐåãèîíà		INT  NULL,
   Çàìåòêè		VARCHAR(MAX)  NULL,
   CONSTRAINT  FK_Ïîñòàâùèê_Ðåãèîí  FOREIGN KEY (ÊîäÐåãèîíà)
     REFERENCES  Ðåãèîí  ON UPDATE CASCADE
 )

  /* Êëèåíò */
 CREATE TABLE Êëèåíò (				/* òðåòüÿ êîìàíäà ïàêåòà */
   ÊîäÊëèåíòà	 	INT  IDENTITY(1,1)  PRIMARY KEY,
   ÈìÿÊëèåíòà		VARCHAR(40)  NOT NULL,
   ÔÈÎÐóêîâîäèòåëÿ	VARCHAR(60)  NULL,
   ÊîäÐåãèîíà 		INT  NULL,
   CONSTRAINT  FK_Êëèåíò_Ðåãèîí  FOREIGN KEY (ÊîäÐåãèîíà)
     REFERENCES  Ðåãèîí  ON UPDATE CASCADE
 )

  /* Âàëþòà */
 CREATE TABLE Âàëþòà (				/* ÷åòâåðòàÿ êîìàíäà ïàêåòà */
   ÊîäÂàëþòû		CHAR(3)  PRIMARY KEY,
   ÈìÿÂàëþòû		VARCHAR(30)  NOT NULL,
   ØàãÎêðóãëåíèÿ 	NUMERIC(10, 4)  DEFAULT 0.01  NULL
     CHECK (ØàãÎêðóãëåíèÿ IN (50, 1, 0.01)),
   ÊóðñÂàëþòû  	SMALLMONEY  NOT NULL  CHECK (ÊóðñÂàëþòû > 0)
 )

  /* Òîâàð */
 CREATE TABLE Òîâàð (				/* ïÿòàÿ êîìàíäà ïàêåòà */
   ÊîäÒîâàðà		INT  PRIMARY KEY,
   Íàèìåíîâàíèå	VARCHAR(50)  NOT NULL,
   ÅäèíèöàÈçì  	CHAR(10)  DEFAULT 'øòóêà'  NULL,
   Öåíà			MONEY  NULL  CHECK (Öåíà > 0),
   ÊîäÂàëþòû		CHAR(3)  DEFAULT 'BYR'  NULL,
   Ðàñôàñîâàí		LOGICAL  NOT NULL,
   CONSTRAINT  FK_Òîâàð_Âàëþòà  FOREIGN KEY (ÊîäÂàëþòû)
     REFERENCES  Âàëþòà  ON UPDATE CASCADE
 )

  /* Çàêàç */
 CREATE TABLE Çàêàç (				/* øåñòàÿ êîìàíäà ïàêåòà */
   ÊîäÇàêàçà		INT  IDENTITY(1,1)  NOT NULL,
   ÊîäÊëèåíòà	 	INT  NOT NULL,
   ÊîäÒîâàðà   	INT  NOT NULL,
   Êîëè÷åñòâî		NUMERIC(12, 3)  NULL  CHECK (Êîëè÷åñòâî > 0),
   ÄàòàÇàêàçà	 	DATETIME  DEFAULT getdate()  NULL,
   ÑðîêÏîñòàâêè	DATETIME  DEFAULT getdate() + 14  NULL,
   ÊîäÏîñòàâùèêà	INT  NULL,  					
   PRIMARY KEY (ÊîäÇàêàçà, ÊîäÊëèåíòà, ÊîäÒîâàðà),
   CONSTRAINT  FK_Çàêàç_Òîâàð  FOREIGN KEY (ÊîäÒîâàðà)  
     REFERENCES  Òîâàð  ON UPDATE CASCADE ON DELETE CASCADE,
   CONSTRAINT  FK_Çàêàç_Êëèåíò  FOREIGN KEY (ÊîäÊëèåíòà)
     REFERENCES  Êëèåíò  ON UPDATE CASCADE ON DELETE CASCADE,
   CONSTRAINT  FK_Çàêàç_Ïîñòàâùèê  FOREIGN KEY (ÊîäÏîñòàâùèêà)
     REFERENCES  Ïîñòàâùèê
 )
 GO

 CREATE UNIQUE INDEX  UIX_Ïîñòàâùèê  ON Ïîñòàâùèê (ÈìÿÏîñòàâùèêà)
   ON Secondary
 CREATE UNIQUE INDEX  UIX_Êëèåíò  ON Êëèåíò (ÈìÿÊëèåíòà)
   ON Secondary
 CREATE UNIQUE INDEX  UIX_Âàëþòà  ON Âàëþòà (ÈìÿÂàëþòû)
   ON Secondary
 CREATE UNIQUE INDEX  UIX_Òîâàð  ON Òîâàð (Íàèìåíîâàíèå)
   ON Secondary
 CREATE INDEX  IX_Ðåãèîí  ON Ðåãèîí (Ñòðàíà, Ãîðîä)  ON Secondary
 CREATE INDEX  IX_Òîâàð  ON Òîâàð (ÅäèíèöàÈçì, Íàèìåíîâàíèå)
   ON Secondary
 CREATE INDEX  IX_Çàêàç  ON Çàêàç (ÄàòàÇàêàçà)  ON Secondary
 GO

 INSERT INTO Ðåãèîí
 VALUES (101, 'Ðîññèÿ', 'Ìîñêîâñêàÿ', 'Êîðîëåâ', 'óë.Ìèðà, 15',
   '387-23-04', '387-23-05')

 INSERT INTO Ðåãèîí (ÊîäÐåãèîíà, Îáëàñòü, Ãîðîä, Àäðåñ, Ôàêñ)
 VALUES (201, '', 'Ìèíñê', 'óë.Ãèêàëî, 9', '278-83-88')	

 INSERT INTO Ðåãèîí (ÊîäÐåãèîíà, Îáëàñòü, Ãîðîä, Àäðåñ, Ôàêñ)
 VALUES (202, 'Ìèíñêàÿ', 'Âîëîæèí', 'óë.Ñåðîâà, 11', '48-37-92')

 INSERT INTO Ðåãèîí (ÊîäÐåãèîíà, Îáëàñòü, Ãîðîä, Àäðåñ, Òåëåôîí,
   Ôàêñ)
 VALUES (203, '', 'Ìèíñê', 'óë.Êèðîâà, 24', '269-13-76',
   '269-13-77')	

 INSERT INTO Ðåãèîí (ÊîäÐåãèîíà, Îáëàñòü, Ãîðîä, Àäðåñ, Ôàêñ)
 VALUES (204, 'Âèòåáñêàÿ', 'Ïîëîöê', 'óë.Ëåñíàÿ, 6', '48-24-12')

 INSERT INTO Ðåãèîí 
 VALUES (301, 'Óêðàèíà', 'Êðûìñêàÿ', 'Àëóøòà', 'óë.Ôðàíêî, 24',
   NULL, '46-49-16')	
 GO

 INSERT INTO Ïîñòàâùèê (ÊîäÏîñòàâùèêà, ÈìÿÏîñòàâùèêà, ÊîäÐåãèîíà)
VALUES (123, 'ÇÀÎ Ìàãèñòðàëü', 101)
INSERT INTO Ïîñòàâùèê (ÊîäÏîñòàâùèêà, ÈìÿÏîñòàâùèêà, ÊîäÐåãèîíà)
VALUES (345, 'ÇÀÎ Áåëëèôòìàø', 202)
INSERT INTO Ïîñòàâùèê
VALUES (987, 'ÎÎÎ ”Áåëöâåòìåò”', 'Îòñðî÷êà', 204,
'Ïîñòîÿííûé ïîñòàâùèê')
INSERT INTO Ïîñòàâùèê (ÊîäÏîñòàâùèêà, ÈìÿÏîñòàâùèêà, ÊîäÐåãèîíà)
VALUES (789, 'ÈÏ Çåëåíêî Â. ß.', 301)
INSERT INTO Ïîñòàâùèê
VALUES (567, 'ÑÏ ”Ïîëèõèì”', 'Ïî ôàêòó îòãðóçêè', 203,
'Ïîñòîÿííûé ïîñòàâùèê')
GO

INSERT INTO Êëèåíò
VALUES ('ÃÏ ”Âåðàñ”', 'Ïðîêóøåâ Ñòàíèñëàâ Èãîðåâè÷', 202)
INSERT INTO Êëèåíò (ÈìÿÊëèåíòà, ÔÈÎÐóêîâîäèòåëÿ)
VALUES ('×Ï ”ßêîðü”', 'ßñíþê Â. À.')
INSERT INTO Êëèåíò
VALUES ('ÎÎÎ ”Öâåòíîé”', 'Ìóçû÷åíêî Ä. Ì.', 203)
INSERT INTO Êëèåíò
VALUES ('ÎÀÎ ”Þðìåãà”', 'Âèøíåâñêèé Þ. Ð.', 301)
INSERT INTO Êëèåíò (ÈìÿÊëèåíòà, ÔÈÎÐóêîâîäèòåëÿ)
VALUES ('ÈÏ ”Òåìï”', 'Âàñüêî Ãðèãîðèé Òåðåíòüåâè÷')
GO

INSERT INTO Âàëþòà
 VALUES ('BYR', 'Áåëîðóññêèå ðóáëè', 1, 1)

 INSERT INTO Âàëþòà (ÊîäÂàëþòû, ÈìÿÂàëþòû, ÊóðñÂàëþòû)
 VALUES ('RUR', 'Ðîññèéñêèå ðóáëè', 276)

 INSERT INTO Âàëþòà (ÊîäÂàëþòû, ÈìÿÂàëþòû, ÊóðñÂàëþòû)
 VALUES ('USD', 'Äîëëàðû ÑØÀ', 9160)

 INSERT INTO Âàëþòà (ÊîäÂàëþòû, ÈìÿÂàëþòû, ÊóðñÂàëþòû)
 VALUES ('EUR', 'Åâðî', 12450)
 GO

 INSERT INTO Òîâàð
VALUES (111, 'Ìîíèòîð 21 äþéì', 'øòóêà', 320, 'USD', 'Íåò')
INSERT INTO Òîâàð
VALUES (222, 'Ìûøü áåñïðîâîäíàÿ Canyon', 'øòóêà', 5, 'EUR', 'Íåò')
INSERT INTO Òîâàð
VALUES (333, 'Çàðÿäíîå óñòðîéñòâî Lenovo', 'øòóêà', 35, 'BYR', 'Äà')
INSERT INTO Òîâàð (ÊîäÒîâàðà, Íàèìåíîâàíèå, Öåíà, Ðàñôàñîâàí)
VALUES (444, 'Ìîíîáëîê Asus', 1200, 'Íåò')
INSERT INTO Òîâàð (ÊîäÒîâàðà, Íàèìåíîâàíèå, Öåíà, Ðàñôàñîâàí)
VALUES (555, 'Âèí÷åñòåð HDD 120GB', 285000, 'Äà')
GO

SET DATEFORMAT dmy

INSERT INTO Çàêàç
VALUES (3, 111, 8, '04/09/19', '14/09/19', 567)
INSERT INTO Çàêàç
VALUES (2, 222, 10, '04/01/20', '14/01/20', 987)
INSERT INTO Çàêàç
VALUES (5, 333, 15, '22/02/20', '28/02/20', 789)
INSERT INTO Çàêàç
VALUES (4, 444, 20, '05/04/2020', '20/04/2020', 345)
INSERT INTO Çàêàç (ÊîäÊëèåíòà, ÊîäÒîâàðà, Êîëè÷åñòâî)
VALUES (1, 555, 25)
GO

 CREATE VIEW Çàïðîñ1 AS
   SELECT TOP 100 PERCENT Òîâàð.Íàèìåíîâàíèå, Çàêàç.Êîëè÷åñòâî, 
     Òîâàð.ÅäèíèöàÈçì, Ïîñòàâùèê.ÈìÿÏîñòàâùèêà
   FROM Çàêàç 
     INNER JOIN Ïîñòàâùèê 
       ON Çàêàç.ÊîäÏîñòàâùèêà = Ïîñòàâùèê.ÊîäÏîñòàâùèêà 
     INNER JOIN Òîâàð 
       ON Çàêàç.ÊîäÒîâàðà = Òîâàð.ÊîäÒîâàðà
   ORDER BY Òîâàð.Íàèìåíîâàíèå, Çàêàç.Êîëè÷åñòâî DESC 
 GO

EXEC sp_addlogin 'sql1', '1111', 'Ñêëàä_118';
EXEC sp_addlogin 'sql2', '1111', 'Ñêëàä_118';
EXEC sp_addlogin 'sql3', '1111', 'Ñêëàä_118';
EXEC sp_addlogin 'sql4', '1111', 'Ñêëàä_118';
GO

EXEC sp_addsrvrolemember 'sql1', 'dbcreator'
GO

EXEC sp_grantdbaccess 'sql1', 'login1'
EXEC sp_grantdbaccess 'sql2', 'login2'
EXEC sp_grantdbaccess 'sql3', 'login3'
EXEC sp_grantdbaccess 'sql4', 'login4'
GO

EXEC sp_addrole 'Ãë.áóõãàëòåð', 'login1'
EXEC sp_addrole 'Áóõãàëòåðà', 'login1'
EXEC sp_addrole 'Ýêîíîìèñòû', 'login1'
GO

EXEC sp_addrolemember 'db_accessadmin', 'login1'
EXEC sp_addrolemember 'Ãë.áóõãàëòåð', 'login1'
EXEC sp_addrolemember 'Áóõãàëòåðà', 'login2'
EXEC sp_addrolemember 'Áóõãàëòåðà', 'login3'
EXEC sp_addrolemember 'Áóõãàëòåðà', 'Ãë.áóõãàëòåð'
EXEC sp_addrolemember 'Ýêîíîìèñòû', 'login4'
EXEC sp_addrolemember 'Ýêîíîìèñòû', 'Ãë.áóõãàëòåð'
GO

GRANT SELECT, INSERT, UPDATE, DELETE
 ON Âàëþòà TO [Ãë.áóõãàëòåð] WITH GRANT OPTION

 GRANT UPDATE
 ON Çàêàç TO [Ãë.áóõãàëòåð] WITH GRANT OPTION

 GRANT SELECT
 ON Çàïðîñ1 TO [Ãë.áóõãàëòåð] WITH GRANT OPTION

 GRANT UPDATE, DELETE
 ON Êëèåíò TO [Ãë.áóõãàëòåð] WITH GRANT OPTION

 GRANT UPDATE, DELETE
 ON Ïîñòàâùèê TO [Ãë.áóõãàëòåð] WITH GRANT OPTION

 GRANT UPDATE, DELETE
 ON Òîâàð TO [Ãë.áóõãàëòåð] WITH GRANT OPTION

 GRANT SELECT, INSERT
 ON Çàêàç TO Áóõãàëòåðà

 GRANT SELECT, INSERT
 ON Êëèåíò TO Áóõãàëòåðà

 GRANT SELECT, INSERT
 ON Ïîñòàâùèê TO Ýêîíîìèñòû

 GRANT SELECT, INSERT
 ON Òîâàð TO Ýêîíîìèñòû


 GRANT SELECT, INSERT, UPDATE, DELETE
 ON Ðåãèîí TO public
 GO

 DENY UPDATE
 ON Çàêàç (ÄàòàÇàêàçà, ÑðîêÏîñòàâêè) TO [Ãë.áóõãàëòåð] CASCADE 
 GO



