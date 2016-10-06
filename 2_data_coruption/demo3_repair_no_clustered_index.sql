USE master;
GO

IF DATABASEPROPERTYEX(N'Demo', N'Version') > 0
    BEGIN
        ALTER DATABASE Demo SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
        DROP DATABASE Demo;
    END;
GO

CREATE DATABASE Demo 
ON PRIMARY (
	NAME = N'Demo_data',
	FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\Demo_data.mdf'
)
LOG ON (
	NAME = N'Demo_log',
	FILENAME =  N'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\Demo_log.ldf',
	SIZE = 5MB,
	FILEGROWTH = 1MB
);
GO

USE Demo;

CREATE TABLE People (
    c1 int IDENTITY,
    name char(500),
);

CREATE NONCLUSTERED INDEX NCL_name ON People(name);
GO

INSERT INTO dbo.People
SELECT CONVERT(char(500), NEWID())
GO 100

USE master;
GO

-- Corrupt NCL_name index --
DBCC IND('Demo', 'dbo.People', 2) -- find index root page id;
GO

ALTER DATABASE Demo SET SINGLE_USER WITH ROLLBACK IMMEDIATE
DBCC WRITEPAGE(N'Demo', 1, 142, 0, 2, 0x0000, 1);
ALTER DATABASE Demo SET MULTI_USER WITH ROLLBACK IMMEDIATE
GO

SELECT name
FROM Demo.dbo.People WITH(2) WHERE name = 'NIE MA TAKIEGO';

DBCC CHECKDB('Demo') WITH NO_INFOMSGS;
DBCC CHECKDB('Demo') WITH NO_INFOMSGS, TABLERESULTS;

USE Demo
GO

-- Rebuild operation reads from old index
ALTER INDEX NCL_name ON People REBUILD;
GO

-- Need to disable before rebuild
ALTER INDEX NCL_name ON People DISABLE;
ALTER INDEX NCL_name ON People REBUILD;
GO

-- Do it in transaction to prevent constraint problems due to inserts from another transactions
BEGIN TRAN
ALTER INDEX NCL_name ON People DISABLE;
ALTER INDEX NCL_name ON People REBUILD;
COMMIT TRAN

-- Check if any problems exist
DBCC CHECKDB('Demo') WITH NO_INFOMSGS;