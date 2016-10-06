USE master;
GO

--enable trace flag for undocumented dbcc output
DBCC TRACEON(3604);
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

CREATE UNIQUE CLUSTERED INDEX BigRows_CL
ON BigRows(c1);
GO

-- really puts database in full recovery model 
BACKUP DATABASE Demo 
TO DISK = N'E:\MSSQL\BACKUP\Demo_FULL_00_00.bak'
WITH INIT, STATS;
GO

BEGIN TRAN
DECLARE @counter INT = 1
WHILE @counter < 11
BEGIN
    INSERT INTO BigRows VALUES ('Transaction ' + CAST(@counter AS CHAR(2)));
    SET @counter = @counter + 1
END
COMMIT TRAN
GO

SELECT * 
FROM sys.fn_dblog(NULL, NULL) fd
WHERE fd.[Transaction Name] = N'user_transaction'
GO

SELECT * /*Page ID*/ 
FROM sys.fn_dblog(NULL, NULL) fd
WHERE fd.[Transaction ID] = N'0000:0000034a'
GO

DBCC IND (N'Demo', N'BigRows', 1);
GO

-- check LSN before modification
DBCC PAGE (N'Demo', 1, 145, 3); -- LSN 34:472:87
GO

UPDATE BigRows SET BigRows.c2 = 'NOPE';
GO

-- check LSN after modification
DBCC PAGE (N'Demo', 1, 145, 3); -- LSN 34:672:4
GO

SELECT * 
FROM sys.fn_dblog(NULL, NULL) fd
WHERE fd.[Transaction Name] = N'UPDATE'
GO

SELECT * 
FROM sys.fn_dblog(NULL, NULL) fd
WHERE fd.[Transaction ID] = N'0000:00000358'
GO

SELECT CONVERT(INT, 0x0000008e)
GO