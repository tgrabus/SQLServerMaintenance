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

CREATE TABLE BigRows (
    c1 INT IDENTITY,
    c2 CHAR (7000) DEFAULT 'a'
);

CREATE CLUSTERED INDEX BigRows_CL
ON BigRows(c1);
GO

INSERT INTO BigRows DEFAULT VALUES;
GO 100
 
-- Take backups --
BACKUP DATABASE Demo 
TO DISK = N'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\BACKUP\Demo_FULL.bak'
WITH INIT;

BACKUP DATABASE Demo 
TO DISK = N'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\BACKUP\Demo_FULL_WITH_CHECKSUM.bak'
WITH INIT, CHECKSUM;
GO

-- Backup corruption --
DBCC TRACEON(3604);
DBCC IND('Demo', 'BigRows', 1);
DBCC PAGE('Demo', 1, 250, 3);
GO

--
-- Use HXD to corrupt backups
--

-- Verify without check 
RESTORE VERIFYONLY
FROM DISK = N'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\BACKUP\Demo_FULL.bak';

-- Verify with check
RESTORE VERIFYONLY
FROM DISK = N'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\BACKUP\Demo_FULL_WITH_CHECKSUM.bak';