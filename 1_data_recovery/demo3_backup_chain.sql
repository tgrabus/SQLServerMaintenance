USE msdb;  
GO 
--backup msdb before
DECLARE @dateStr VARCHAR(20);
SELECT @dateStr = CONVERT(VARCHAR, GETDATE());
EXEC sp_delete_backuphistory @dateStr;
GO

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
    c1 int IDENTITY,
    c2 char(8000)
);

CREATE CLUSTERED INDEX BigRows_CL
ON BigRows(c1);
GO

INSERT INTO BigRows VALUES ('Initial Data');
GO

-- really puts database in full recovery model 
BACKUP DATABASE Demo 
TO DISK = N'E:\MSSQL\BACKUP\Demo_FULL_00.bak'
WITH INIT, STATS, NAME = 'Demo_FULL_00';
GO

-- create first log backup and start log backup chain
BACKUP LOG Demo
TO DISK = N'E:\MSSQL\BACKUP\Demo_LOG_00.trn'
WITH INIT, NAME = 'Demo_LOG_00';
GO

SET NOCOUNT ON;
DECLARE @count INT = 1;
DECLARE @logBackupName NVARCHAR(20)
DECLARE @logBackupPath NVARCHAR(255)
DECLARE @diffBackupName NVARCHAR(20)
DECLARE @diffBackupPath NVARCHAR(255)

WHILE @count < 24
BEGIN
    INSERT INTO BigRows VALUES ('Transaction ' + CAST(@count AS CHAR(3)));

    SET @logBackupName = N'Demo_LOG_' + FORMAT(@count, '0#');
    SET @logBackupPath = REPLACE(N'E:\MSSQL\BACKUP\FILENAME.trn', 'FILENAME', @logBackupName); 
    BACKUP LOG Demo
    TO DISK = @logBackupPath
    WITH INIT, NAME = @logBackupName

    IF @count % 6 = 0
    BEGIN
	   SET @diffBackupName = N'Demo_DIFF_' + FORMAT(@count, '0#');
	   SET @diffBackupPath = REPLACE(N'E:\MSSQL\BACKUP\FILENAME.bak', 'FILENAME', @diffBackupName); 
	   BACKUP DATABASE Demo 
	   TO DISK = @diffBackupPath
	   WITH INIT, STATS, DIFFERENTIAL, NAME = @diffBackupName;
    END

    SET @count = @count + 1;

    WAITFOR DELAY '00:00:01';
END
GO

SET NOCOUNT OFF;
SELECT * FROM dbo.BigRows;
GO

SELECT bs.backup_start_date,
	  bs.name,
       CASE bs.type
           WHEN N'D' THEN N'Full'
           WHEN N'I' THEN N'Diff'
           WHEN N'L' THEN N'Log'
           ELSE N'Unknown'
       END AS N'Type',
       bs.position,
       bs.first_lsn,
       bs.last_lsn,
	  bs.checkpoint_lsn,
	  bs.database_backup_lsn,
	  bs.first_recovery_fork_guid,
	  bs.last_recovery_fork_guid,
	  bs.fork_point_lsn,
	  bs.differential_base_lsn,
	  bs.differential_base_guid,	  
       bs.backup_finish_date
FROM msdb.dbo.backupset AS bs
     JOIN msdb.dbo.backupmediafamily AS bmf ON bs.media_set_id = bmf.media_set_id
WHERE bs.database_name = N'Demo'
ORDER BY 1 ASC;
GO

USE master;
ALTER DATABASE Demo
SET OFFLINE WITH ROLLBACK IMMEDIATE
GO

-- restore from FULL backup
RESTORE DATABASE Demo 
FROM DISK = N'E:\MSSQL\BACKUP\Demo_FULL_00.bak' 
WITH NORECOVERY, REPLACE;
GO

-- restore from any DIFFERENTIAL backup
RESTORE DATABASE Demo 
FROM DISK = N'E:\MSSQL\BACKUP\Demo_DIFF_18.bak' 
WITH NORECOVERY;
GO

-- try restore too early LOG backup
RESTORE LOG Demo 
FROM DISK = N'E:\MSSQL\BACKUP\Demo_LOG_18.trn'
WITH NORECOVERY ;
GO

-- try restore too recent LOG backup
RESTORE LOG Demo 
FROM DISK = N'E:\MSSQL\BACKUP\Demo_LOG_20.trn'
WITH NORECOVERY ;
GO

-- restore from right LOG backup
RESTORE LOG Demo 
FROM DISK = N'E:\MSSQL\BACKUP\Demo_LOG_19.trn'
WITH NORECOVERY ;
GO

-- Start new Recovery Path
RESTORE DATABASE Demo
WITH RECOVERY;
GO

USE Demo;
SELECT * FROM dbo.BigRows;
GO

INSERT INTO BigRows VALUES ('Transaction 1 from new Path');
INSERT INTO BigRows VALUES ('Transaction 2 from new Path');

BACKUP LOG Demo
TO DISK = N'E:\MSSQL\BACKUP\Demo_LOG_20_Path2.trn'
WITH INIT, NAME = N'Demo_LOG_20_Path2';
GO

-- look into backup headers
RESTORE HEADERONLY FROM DISK = N'E:\MSSQL\BACKUP\Demo_FULL_00.bak'
RESTORE HEADERONLY FROM DISK = N'E:\MSSQL\BACKUP\Demo_DIFF_18.bak'
RESTORE HEADERONLY FROM DISK = N'E:\MSSQL\BACKUP\Demo_LOG_19.trn'
RESTORE HEADERONLY FROM DISK = N'E:\MSSQL\BACKUP\Demo_LOG_20.trn' 
RESTORE HEADERONLY FROM DISK = N'E:\MSSQL\BACKUP\Demo_LOG_20_Path2.trn'

USE master;
ALTER DATABASE Demo
SET OFFLINE WITH ROLLBACK IMMEDIATE
GO

-- restore from FULL backup
RESTORE DATABASE Demo 
FROM DISK = N'E:\MSSQL\BACKUP\Demo_FULL_00.bak' 
WITH NORECOVERY, REPLACE;
GO

-- restore from any DIFFERENTIAL backup
RESTORE DATABASE Demo 
FROM DISK = N'E:\MSSQL\BACKUP\Demo_DIFF_18.bak'
WITH NORECOVERY;
GO

RESTORE LOG Demo 
FROM DISK = N'E:\MSSQL\BACKUP\Demo_LOG_19.trn'
WITH NORECOVERY ;
GO

-- decide which path to follow 
RESTORE LOG Demo 
FROM DISK = N'E:\MSSQL\BACKUP\Demo_LOG_20.trn'
WITH NORECOVERY ;
GO

RESTORE LOG Demo 
FROM DISK = N'E:\MSSQL\BACKUP\Demo_LOG_20_Path2.trn'
WITH NORECOVERY;
GO

-- try to restore log backup from path 1
RESTORE LOG Demo 
FROM DISK = N'E:\MSSQL\BACKUP\Demo_LOG_21.trn'
WITH NORECOVERY;
GO

RESTORE DATABASE Demo
WITH RECOVERY;
GO

USE Demo;
SELECT * FROM dbo.BigRows;
GO

/*Remember to backup msdb beacuse if it is lost you won't be able to look into backup history*/

-- find out what is the log backup sequence
RESTORE HEADERONLY FROM DISK = N'E:\MSSQL\BACKUP\Demo_FULL_00.bak'
RESTORE HEADERONLY FROM DISK = N'E:\MSSQL\BACKUP\Demo_LOG_00.trn'
RESTORE HEADERONLY FROM DISK = N'E:\MSSQL\BACKUP\Demo_LOG_01.trn' 
RESTORE HEADERONLY FROM DISK = N'E:\MSSQL\BACKUP\Demo_LOG_02.trn' 
RESTORE HEADERONLY FROM DISK = N'E:\MSSQL\BACKUP\Demo_LOG_03.trn' 
RESTORE HEADERONLY FROM DISK = N'E:\MSSQL\BACKUP\Demo_LOG_04.trn' 
RESTORE HEADERONLY FROM DISK = N'E:\MSSQL\BACKUP\Demo_LOG_05.trn'
RESTORE HEADERONLY FROM DISK = N'E:\MSSQL\BACKUP\Demo_LOG_06.trn'
RESTORE HEADERONLY FROM DISK = N'E:\MSSQL\BACKUP\Demo_DIFF_06.bak'
RESTORE HEADERONLY FROM DISK = N'E:\MSSQL\BACKUP\Demo_LOG_07.trn' 
RESTORE HEADERONLY FROM DISK = N'E:\MSSQL\BACKUP\Demo_LOG_08.trn' 
RESTORE HEADERONLY FROM DISK = N'E:\MSSQL\BACKUP\Demo_LOG_09.trn'
RESTORE HEADERONLY FROM DISK = N'E:\MSSQL\BACKUP\Demo_LOG_10.trn'
RESTORE HEADERONLY FROM DISK = N'E:\MSSQL\BACKUP\Demo_LOG_11.trn' 
RESTORE HEADERONLY FROM DISK = N'E:\MSSQL\BACKUP\Demo_LOG_12.trn' 
RESTORE HEADERONLY FROM DISK = N'E:\MSSQL\BACKUP\Demo_DIFF_12.bak'
RESTORE HEADERONLY FROM DISK = N'E:\MSSQL\BACKUP\Demo_LOG_13.trn'
RESTORE HEADERONLY FROM DISK = N'E:\MSSQL\BACKUP\Demo_LOG_14.trn'
RESTORE HEADERONLY FROM DISK = N'E:\MSSQL\BACKUP\Demo_LOG_15.trn'
RESTORE HEADERONLY FROM DISK = N'E:\MSSQL\BACKUP\Demo_LOG_16.trn'
RESTORE HEADERONLY FROM DISK = N'E:\MSSQL\BACKUP\Demo_LOG_17.trn'
RESTORE HEADERONLY FROM DISK = N'E:\MSSQL\BACKUP\Demo_LOG_18.trn'
RESTORE HEADERONLY FROM DISK = N'E:\MSSQL\BACKUP\Demo_DIFF_18.bak'
RESTORE HEADERONLY FROM DISK = N'E:\MSSQL\BACKUP\Demo_LOG_19.trn'
RESTORE HEADERONLY FROM DISK = N'E:\MSSQL\BACKUP\Demo_LOG_20.trn'
RESTORE HEADERONLY FROM DISK = N'E:\MSSQL\BACKUP\Demo_LOG_21.trn'
RESTORE HEADERONLY FROM DISK = N'E:\MSSQL\BACKUP\Demo_LOG_22.trn'
RESTORE HEADERONLY FROM DISK = N'E:\MSSQL\BACKUP\Demo_LOG_23.trn'
GO