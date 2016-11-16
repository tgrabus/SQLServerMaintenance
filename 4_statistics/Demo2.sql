-- Examples use AdventureWorks2012 database (https://msftdbprodsamples.codeplex.com/releases/view/93587)

-- Show details about available statistics for table
SELECT
    OBJECT_NAME([SP].[object_id])	 'Table',
    [SP].[stats_id]				 'Statistic ID',
    [S].[name]					 'Statistic',
    [S].[auto_created]			 'AutoCreated',
    [S].[user_created]			 'UserCreated',
    [S].[no_recompute]			 'NoRecompute',
    [SP].[last_updated]			 'Last Updated',
    [SP].[rows]				 'Rows',
    [SP].[rows_sampled]			 'RowsSampled',
    [SP].[modification_counter]	 'Modifications'
FROM 
    [SYS].[STATS]  [S]
    OUTER APPLY SYS.DM_DB_STATS_PROPERTIES ([S].[object_id],[S].[stats_id]) AS [SP]
WHERE [S].[object_id] = OBJECT_ID('Person.Person');

GO

DBCC SHOW_STATISTICS ('Person.Person', IX_Person_LastName_FirstName_MiddleName);
GO

SELECT *
FROM Person.Person
WHERE LastName = 'Diaz'

SET NOCOUNT ON
GO

INSERT INTO [Person].[BusinessEntity] DEFAULT VALUES;
INSERT INTO Person.Person 
		 ([BusinessEntityID]
           ,[PersonType]
           ,[NameStyle]
           ,[Title]
           ,[FirstName]
           ,[MiddleName]
           ,[LastName]
           ,[Suffix]
           ,[EmailPromotion])
SELECT SCOPE_IDENTITY(), P.PersonType, P.NameStyle, P.Title, P.FirstName, P.MiddleName, P.LastName, P.Suffix, P.EmailPromotion 
FROM Person.Person P WHERE BusinessEntityID = 6782
GO 1 -- insert 20% of table size

SET NOCOUNT OFF
GO

SET STATISTICS IO ON
SET STATISTICS TIME ON

SELECT *
FROM Person.Person
WHERE LastName = 'Diaz'

SET STATISTICS IO OFF
SET STATISTICS TIME OFF
GO

DBCC SHOW_STATISTICS ('Person.Person', IX_Person_LastName_FirstName_MiddleName);
GO

UPDATE STATISTICS Person.Person IX_Person_LastName_FirstName_MiddleName WITH FULLSCAN
GO

DBCC SHOW_STATISTICS ('Person.Person', IX_Person_LastName_FirstName_MiddleName);
GO

CHECKPOINT
DBCC DROPCLEANBUFFERS
DBCC FREEPROCCACHE
GO

SET STATISTICS IO ON
SET STATISTICS TIME ON

SELECT *
FROM Person.Person
WHERE LastName = 'Diaz'

SELECT *
FROM Person.Person
WITH (INDEX(IX_Person_LastName_FirstName_MiddleName))
WHERE LastName = 'Diaz'

SET STATISTICS IO OFF
SET STATISTICS TIME OFF
GO