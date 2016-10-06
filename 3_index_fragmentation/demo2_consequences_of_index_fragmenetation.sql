USE [master];
GO
IF DATABASEPROPERTYEX(N'Company', N'Version') > 0
    BEGIN
        ALTER DATABASE [Company] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
        DROP DATABASE [Company];
    END;
GO
CREATE DATABASE [Company];
GO
USE [Company];
GO

CREATE TABLE [BadKeyTable] (
    [c1] UNIQUEIDENTIFIER DEFAULT NEWID() ROWGUIDCOL,
    [c2] DATETIME DEFAULT GETDATE(),
    [c3] CHAR(400) DEFAULT 'a',
    [c4] VARCHAR(MAX) DEFAULT 'b'
);
GO

CREATE CLUSTERED INDEX [BadKeyTable_CL] ON [BadKeyTable]([c1]);
CREATE NONCLUSTERED INDEX [BadKeyTable_NCL] ON [BadKeyTable]([c2]);
GO

CREATE TABLE [BetterKeyTable] (
    [c1] UNIQUEIDENTIFIER DEFAULT NEWSEQUENTIALID() ROWGUIDCOL ,
    [c2] DATETIME DEFAULT GETDATE() ,
    [c3] CHAR(400) DEFAULT 'a' ,
    [c4] VARCHAR(MAX) DEFAULT 'b'
);
GO
CREATE CLUSTERED INDEX [BetterKeyTable_CL] ON [BetterKeyTable]([c1]);
CREATE NONCLUSTERED INDEX [BetterKeyTable_NCL] ON [BetterKeyTable]([c2]);
GO

SET NOCOUNT ON;
DECLARE @a INT;
SELECT @a = 0;
WHILE(@a < 250000)
    BEGIN
        INSERT INTO [BetterKeyTable]
        DEFAULT VALUES;
        SELECT @a = @a + 1;
    END;
GO

DECLARE @a INT;
SELECT @a = 0;
WHILE(@a < 250000)
    BEGIN
        INSERT INTO [BadKeyTable]
        DEFAULT VALUES;
        SELECT @a = @a + 1;
    END;
SET NOCOUNT OFF;
GO

USE [Company];
GO

-- CASE 1 How much memory is used

SELECT *
FROM sys.dm_os_buffer_descriptors AS descr;
GO

SELECT 
    COUNT(*) * 8 / 1024 AS [MBUsed],
    SUM(descr.free_space_in_bytes) / (1024 * 1024) AS [MBEmpty]
FROM 
    sys.dm_os_buffer_descriptors AS descr;
GO

SELECT 
    DB_NAME(descr.database_id) AS [DbName],
    COUNT(*) * 8 / 1024 AS [MBUsed],
    SUM(descr.free_space_in_bytes) / (1024 * 1024) AS [MBEmpty]
FROM 
    sys.dm_os_buffer_descriptors descr
WHERE 
    descr.database_id = DB_ID(N'Company')
GROUP BY 
    descr.database_id;
GO

SELECT 
    s.name 'Schema',
    o.name 'Object',
    i.index_id 'Index ID',
    i.name 'Index',
    i.type_desc 'Index Type',
    (DPCount + CPCount) * 8 / 1024 'Total MB',
    (DPFreeSpace + CPFreeSpace) / 1024 / 1024 'Free Space MB'
FROM
(
    SELECT allocation_unit_id,
           SUM(CASE
                   WHEN([is_modified] = 1)
                   THEN 1
                   ELSE 0
               END) 'DPCount',
           SUM(CASE
                   WHEN([is_modified] = 1)
                   THEN 0
                   ELSE 1
               END) 'CPCount',
           SUM(CASE
                   WHEN([is_modified] = 1)
                   THEN CAST(free_space_in_bytes AS BIGINT)
                   ELSE 0
               END) 'DPFreeSpace',
           SUM(CASE
                   WHEN([is_modified] = 1)
                   THEN 0
                   ELSE CAST(free_space_in_bytes AS BIGINT)
               END) 'CPFreeSpace'
    FROM sys.dm_os_buffer_descriptors
    WHERE database_id = DB_ID(N'Company')
    GROUP BY allocation_unit_id
) buffers
INNER JOIN sys.allocation_units au ON buffers.allocation_unit_id = au.allocation_unit_id
INNER JOIN sys.partitions p ON p.partition_id = au.container_id
INNER JOIN sys.indexes i ON i.index_id = p.index_id
                            AND i.object_id = p.object_id
INNER JOIN sys.objects o ON o.object_id = i.object_id
INNER JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE o.is_ms_shipped = 0;
GO

-- CASE 2 How many disk reads
--DBCC DROPCLEANBUFFERS;
SET STATISTICS IO ON;
SELECT COUNT(*) FROM [BadKeyTable];
SELECT COUNT(*) FROM [BetterKeyTable];
SET STATISTICS IO OFF;
GO