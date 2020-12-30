

-- This get all create table sql
DECLARE namelist CURSOR
    FOR select distinct name from sys.partitions p, sys.tables t, INFORMATION_SCHEMA.TABLES i 
		where t.object_id=p.object_id and i.TABLE_NAME=t.name and TABLE_CATALOG='RTPCS' AND i.TABLE_SCHEMA='dbo' and i.TABLE_TYPE='BASE TABLE'  order by t.name;
DECLARE @sql NVARCHAR(MAX), @cols NVARCHAR(MAX) = N'', @tname NVARCHAR(MAX), @code NVARCHAR(MAX)=N'', @uk NVARCHAR(MAX) = N'', @pk NVarchar(max) = N'';
open namelist;
FETCH NEXT FROM namelist into @tname;
WHILE @@FETCH_STATUS = 0  
	BEGIN
		SELECT @cols += N',[' + name + '] ' + system_type_name + ' ' + REPLACE(REPLACE(is_nullable,'1','NULL'),'0','NOT NULL') +char(10)
			FROM sys.dm_exec_describe_first_result_set(N'SELECT * FROM '+ @tname, NULL, 1);
		SET @cols = STUFF(@cols, 1, 1, N'');
		SET @sql = char(10) + N'CREATE TABLE [' + @tname + '] ('+char(10)+ @cols;
		SELECT @pk += N',' + COLUMN_NAME
			FROM INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where CONSTRAINT_NAME like '%$PK' and TABLE_NAME=@tname;
		set @pk = STUFF(@pk, 1, 1, N'');
		set @sql = concat(@sql, N',CONSTRAINT ['+@tname+'$PK] primary key (' + @pk + ')' + char(10));
		SELECT @uk += N',' + COLUMN_NAME
			FROM INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where CONSTRAINT_NAME like '%$UK' and TABLE_NAME=@tname;
		set @uk = STUFF(@uk, 1, 1, N'');
		set  @sql = concat(@sql,  N',CONSTRAINT ['+@tname+'$UK] unique (' + @uk + ')' + char(10));
		set @sql = concat(@sql, ');');
		PRINT @sql;
		set @cols = N'';
		set @pk = N'';
		set @uk = N'';
		FETCH NEXT FROM namelist into @tname;
		END;
 close namelist;
 deallocate namelist;
 
 /*
 This is an example of the output:
 
 CREATE TABLE [CHINA_DRIVER] (
[ST_ID] nvarchar(9) NOT NULL
,[TFORM_NUM] nvarchar(8) NOT NULL
,[APP_DT] datetime NOT NULL
,[CAND_ID] nvarchar(30) NULL
,[REMARKS] nvarchar(4000) NULL
,[LST_MOD_BY] nvarchar(15) NOT NULL
,[LST_MOD_DT] datetime NOT NULL
,[CREATE_BY] nvarchar(15) NOT NULL
,[CREATE_DT] datetime NOT NULL
,CONSTRAINT [CHINA_DRIVER$PK] primary key (ST_ID)
,CONSTRAINT [CHINA_DRIVER$UK] unique (APP_DT,TFORM_NUM)
);

 */
