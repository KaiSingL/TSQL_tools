select distinct name, rows count from sys.partitions p, sys.tables t, INFORMATION_SCHEMA.TABLES i where t.object_id=p.object_id and i.TABLE_NAME=t.name and TABLE_CATALOG='DATABASE' AND i.TABLE_SCHEMA='dbo' and i.TABLE_TYPE='BASE TABLE' 
) order by t.name
