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

SELECT *
FROM sys.dm_db_index_physical_stats(DB_ID(N'Company'), NULL, NULL, NULL, N'DETAILED');

SELECT *
FROM sys.dm_db_index_physical_stats(DB_ID(N'Company'), NULL, NULL, NULL, N'SAMPLED');

SELECT *
FROM sys.dm_db_index_physical_stats(DB_ID(N'Company'), NULL, NULL, NULL, N'LIMITED');

SELECT OBJECT_NAME(ips.object_id) AS 'Object name',
       si.name AS 'Index name',
       ROUND(ips.avg_fragmentation_in_percent, 2) AS 'Fragmentation',
       ips.page_count AS 'Pages',
       ips.avg_page_space_used_in_percent AS 'Page density'
FROM sys.dm_db_index_physical_stats(DB_ID(N'Company'), NULL, NULL, NULL, N'DETAILED') AS ips
     CROSS APPLY sys.indexes AS si
WHERE si.object_id = ips.object_id
      AND si.index_id = ips.index_id
      AND ips.index_level = 0
      AND ips.alloc_unit_type_desc = N'IN_ROW_DATA';