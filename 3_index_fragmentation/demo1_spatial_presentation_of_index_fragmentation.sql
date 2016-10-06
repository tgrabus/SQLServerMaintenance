USE [master];
GO

IF DATABASEPROPERTYEX(N'Vizualize', N'Version') > 0
    BEGIN
        ALTER DATABASE [Vizualize] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
        DROP DATABASE [Vizualize];
    END;
GO

CREATE DATABASE [Vizualize];
GO

USE [Vizualize];
GO

CREATE TABLE Points (
    X INT NOT NULL,
    Value CHAR(4000) DEFAULT REPLICATE('abcd', 1000)
);
GO

CREATE CLUSTERED INDEX CL_X ON Points(X);
GO

DECLARE @C1 AS CURSOR,
        @X  AS INT
SET @C1 = CURSOR FAST_FORWARD
FOR SELECT number
    FROM   master..spt_values
    WHERE  type = 'P'
           AND number BETWEEN 1 AND 100
    ORDER  BY CRYPT_GEN_RANDOM(3)

OPEN @C1;
FETCH NEXT FROM @C1 INTO @X;
WHILE @@FETCH_STATUS = 0
  BEGIN
      INSERT INTO Points (X)
      VALUES        (@X);

      FETCH NEXT FROM @C1 INTO @X;
END
GO

SELECT page_id AS 'Page ID',
       X AS 'Cluster Key',
       geometry::Point(page_id, X, 0).STBuffer(2) as 'Spatial'
FROM   Points
       CROSS APPLY sys.fn_PhysLocCracker( %% physloc %% )
ORDER  BY page_id;
GO

ALTER INDEX CL_X ON Points REBUILD;
GO

SELECT page_id AS 'Page ID',
       X AS 'Cluster Key',
       geometry::Point(page_id, X, 0).STBuffer(2) as 'Spatial'
FROM   Points
       CROSS APPLY sys.fn_PhysLocCracker( %% physloc %% )
ORDER  BY page_id;
GO