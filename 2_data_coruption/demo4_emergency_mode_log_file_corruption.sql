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
GO

CREATE TABLE People (
    [FirstName] varchar(20),
    [LastName] varchar(20),
    [Money] INT
);
GO

INSERT People VALUES ('Jan', 'Kowal', 1000);
INSERT People VALUES ('Julia', 'Kowal', 2000);
GO

-- start transaction
BEGIN TRAN;
UPDATE [dbo].[People] SET [Money] = 10000;
GO

-- save data to disk without commit
CHECKPOINT;
GO

-- quit instance
SHUTDOWN WITH NOWAIT;

-- 
-- use HEX editor to corrupt log file
--

USE master;
GO

-- show database status
SELECT DATABASEPROPERTYEX('Demo', 'Status');
GO

-- try show problems
DBCC CHECKDB('Demo') WITH NO_INFOMSGS;

-- ommit recovery step
ALTER DATABASE [Demo] SET EMERGENCY;

--
-- *before running repair export all available data if possible
--
-- show corrupted data
SELECT * FROM [Demo].[dbo].[People];

ALTER DATABASE [Demo] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
DBCC CHECKDB('Demo', REPAIR_ALLOW_DATA_LOSS) WITH NO_INFOMSGS;
DBCC CHECKDB('Demo') WITH NO_INFOMSGS;
ALTER DATABASE [Demo] SET MULTI_USER WITH ROLLBACK IMMEDIATE;

SELECT DATABASEPROPERTYEX('Demo', 'Status');
GO

USE Demo;
GO

-- show data after repair
SELECT * FROM [Demo].[dbo].[People]
GO