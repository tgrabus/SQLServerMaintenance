USE [Company];
GO

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

ALTER INDEX BadKeyTable_CL ON BadKeyTable REBUILD WITH(FILLFACTOR = 70);
GO

ALTER INDEX BadKeyTable_NCL ON BadKeyTable REORGANIZE;
GO