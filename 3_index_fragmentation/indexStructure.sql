use [master];
go

if DATABASEPROPERTYEX(N'Company', N'Version') > 0
begin
	alter database [Company] set single_user
		with rollback immediate;
	drop database [Company]
end
go

create database [Company];
go

use [Company];
go

create table [Random] (
	[intCol]	int,
	[charCol]	char(4000)
);

insert into [Random] values (1, REPLICATE('Row1', 1000));
go
insert into [Random] values (3, REPLICATE('Row3', 1000));
go
insert into [Random] values (5, REPLICATE('Row5', 1000));
go
insert into [Random] values (7, REPLICATE('Row7', 1000));
go
insert into [Random] values (9, REPLICATE('Row9', 1000));
go
insert into [Random] values (11, REPLICATE('Row11', 800));
go
insert into [Random] values (13, REPLICATE('Row13', 800));
go
insert into [Random] values (15, REPLICATE('Row15', 800));
go
insert into [Random] values (17, REPLICATE('Row17', 800));
go
insert into [Random] values (19, REPLICATE('Row19', 800));
go
insert into [Random] values (21, REPLICATE('Row21', 800));
go
insert into [Random] values (23, REPLICATE('Row23', 800));
go

--add clustered index
create unique clustered index [Random_CL] on [Random] ([intCol]);
go

--enable trace flag for undocumented dbcc output
dbcc TRACEON(3604);
go

-- undocumented command to list pages
dbcc SEMETADATA(N'Random');
go

-- list all the pages that are allocated to an index
dbcc IND (N'Company', N'Random', 1);
go

--dump the root page
dbcc PAGE (N'Company', 1, 400, 3);
go

SELECT * 
FROM Random 
CROSS APPLY sys.fn_PhysLocCracker(%%physloc%%);

--pick a page with a contiguous next page
dbcc PAGE (N'Company', 1, 15304, 3);
go

--cause fragmentation
insert into [Random] values (14, REPLICATE('Row14', 800));
go





