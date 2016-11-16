-- Examples use AdventureWorks2012 database (https://msftdbprodsamples.codeplex.com/releases/view/93587)

-- Show available statistics including columns for table
EXEC SP_HELPSTATS @OBJNAME = 'Person.Person', @RESULTS = 'ALL'; 

-- Display statistics
DBCC SHOW_STATISTICS ('Person.Person', IX_Person_LastName_FirstName_MiddleName);
GO

-- Density examples
DBCC SHOW_STATISTICS ('Person.Person', IX_Person_LastName_FirstName_MiddleName)
WITH DENSITY_VECTOR;
GO

SELECT 1 / CAST(COUNT(*) AS FLOAT)
FROM (SELECT DISTINCT LastName FROM Person.Person) AS A

SELECT 1 / CAST(COUNT(*) AS FLOAT)
FROM (SELECT DISTINCT LastName, FirstName FROM Person.Person) AS A

SELECT 1 / CAST(COUNT(*) AS FLOAT)
FROM (SELECT DISTINCT LastName, FirstName, MiddleName FROM Person.Person) AS A

-- CASE 1. Equality with known value (step in histogram)
SELECT *
FROM Person.Person 
WHERE LastName = 'Flores'
GO

-- CASE 2. Equality with known value (no step in histogram)
SELECT *
FROM Person.Person 
WHERE LastName = 'Ferrier'
GO

-- CASE 3. Equality with unknown value (density vector)
DECLARE @lastName NVARCHAR(50) = 'Flores';

SELECT *
FROM Person.Person 
WHERE LastName = @lastName
GO

-- CASE 4. Inequality with known value (histogram)
SELECT *
FROM Person.Person 
WHERE LastName > 'Bryant' AND LastName < 'Campbell'
GO

-- CASE 5. Inequality with unknown value (Rule based estimation - x * 9%)
DECLARE @lastName1 NVARCHAR(50) = 'Bryant'
DECLARE @lastName2 NVARCHAR(50) = 'Campbell'

SELECT *
FROM Person.Person 
WHERE LastName > @lastName1 AND LastName < @lastName2
GO

-- CASE 6. Inequality with unknown value (Rule based estimation - x * 30%)
DECLARE @lastName NVARCHAR(50) = 'Alexander'

SELECT *
FROM Person.Person 
WHERE LastName < @lastName

SELECT *
FROM Person.Person 
WHERE LastName < 'Alexander'

-- CASE 7. Equality with no stats  (Rule based estimation - x ^ 0.75)
-- Lack of statistics for FirstName column, engine will create one automatically if AUTO_CREATE_STATISTICS option is true
SELECT *
FROM Person.Person 
WHERE FirstName = 'Megan'

-- Turn off statistics auto creation
ALTER DATABASE AdventureWorks2012 SET AUTO_CREATE_STATISTICS OFF
-- Drop active statistics for FirstName column
DROP STATISTICS <PUT_STATISTICS_FULL_NAME_HERE>

SELECT *
FROM Person.Person 
WHERE FirstName = 'Megan'

ALTER DATABASE AdventureWorks2012 SET AUTO_CREATE_STATISTICS ON