USE master;
GO

IF DATABASEPROPERTYEX(N'Demo', N'Version') > 0
    BEGIN
        ALTER DATABASE Demo SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
        DROP DATABASE Demo;
    END;
GO

EXEC sys.sp_cycle_errorlog;
--xp_readerrorlog 0, 1;
GO

CREATE DATABASE Demo 
ON PRIMARY (
	NAME = N'Demo_data',
	FILENAME = N'E:\MSSQL\DATA\Demo_data.mdf',
	SIZE = 5MB,
	FILEGROWTH = 1MB
)
LOG ON (
	NAME = N'Demo_log',
	FILENAME =  N'E:\MSSQL\DATA\Demo_log.ldf',
	SIZE = 5MB,
	FILEGROWTH = 1MB
);
GO

USE Demo;
GO

DBCC LogInfo

CREATE TABLE BigRows (
    c1 INT NOT NULL IDENTITY,
    c2 CHAR(8000)
);
GO
-- by default db is set to full recovery but full backup has not been taken yet so that means db works under Simple recovery
--ALTER DATABASE Demo SET RECOVERY SIMPLE;
--GO

--set monitoring using perf counters
SET NOCOUNT ON
WHILE 1 = 1
BEGIN
    INSERT INTO dbo.BigRows DEFAULT VALUES
    WAITFOR DELAY '00:00:00:100'
END
GO

DBCC SQLPERF (LOGSPACE);
GO

-- for full recovery
--ALTER DATABASE Demo SET RECOVERY FULL;
--GO

-- that full backup really starts full recovery
BACKUP DATABASE Demo 
TO DISK = N'E:\MSSQL\BACKUP\Demo_FULL_00_00.bak'
WITH INIT, STATS;
GO

WHILE 1 = 1
BEGIN
    INSERT INTO dbo.BigRows DEFAULT VALUES
    WAITFOR DELAY '00:00:00:100'
END
GO

DBCC SQLPERF (LOGSPACE);
DBCC LogInfo;
GO