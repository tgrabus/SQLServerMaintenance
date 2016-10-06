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
	FILENAME = N'E:\MSSQL\DATA\Demo_data.mdf'
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

ALTER DATABASE Demo SET RECOVERY FULL;
GO

CREATE TABLE BigRows (
    c1 INT IDENTITY,
    c2 CHAR (8000)
);

CREATE CLUSTERED INDEX BigRows_CL
ON BigRows(c1);
GO

INSERT INTO BigRows VALUES ('Transaction 1');

-- really puts database in full recovery model 
BACKUP DATABASE Demo 
TO DISK = N'E:\MSSQL\BACKUP\Demo_FULL_00_00.bak'
WITH INIT, STATS;

-- init log backup chain
BACKUP LOG Demo
TO DISK = N'E:\MSSQL\BACKUP\Demo_LOG_00_00.trn'
WITH INIT;

--they wont be written on the disk
INSERT INTO BigRows VALUES ('Transaction 2');
INSERT INTO BigRows VALUES ('Transaction 3');

--simulate disaster
USE master;
SHUTDOWN WITH NOWAIT;
GO

USE Demo;
USE master;

-- the full backup does not contain the most recent transactions
-- so we need tail of the log backup
BACKUP LOG Demo
TO DISK = N'E:\MSSQL\BACKUP\Demo_LOG_tail.trn'
WITH INIT

-- use the special syntax
BACKUP LOG Demo
TO DISK = N'E:\MSSQL\BACKUP\Demo_LOG_tail.trn'
WITH INIT, NO_TRUNCATE

--then start restore from full backup
RESTORE DATABASE Demo
FROM DISK = N'E:\MSSQL\BACKUP\Demo_FULL_00_00.bak'
WITH REPLACE, NORECOVERY;

--restore any diff and log backups if any
RESTORE LOG Demo
FROM DISK = N'E:\MSSQL\BACKUP\Demo_LOG_00_00.trn'
WITH NORECOVERY;

--finally restore tail of the log backup so no data loss
RESTORE LOG Demo
FROM DISK = N'E:\MSSQL\BACKUP\Demo_LOG_tail.trn'
WITH NORECOVERY;

-- finally we allow to do undo on all uncommitted transactions and bring database back to online
RESTORE DATABASE Demo
WITH RECOVERY;

USE Demo;
SELECT * FROM BigRows;