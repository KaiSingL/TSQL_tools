

-- This get all create table sql
DECLARE namelist CURSOR
    FOR select distinct name from sys.partitions p, sys.tables as t, INFORMATION_SCHEMA.TABLES as i 
		where t.object_id=p.object_id and i.TABLE_NAME=t.name and TABLE_CATALOG='RTPCS' AND i.TABLE_SCHEMA='dbo' and i.TABLE_TYPE='BASE TABLE'  order by t.name;
DECLARE @sql NVARCHAR(MAX), @cols NVARCHAR(MAX) = N'', @tname NVARCHAR(MAX), @code NVARCHAR(MAX)=N'', @uk NVARCHAR(MAX) = N'', @pk NVarchar(max) = N'';
open namelist;
FETCH NEXT FROM namelist into @tname;
WHILE @@FETCH_STATUS = 0  
	BEGIN
		SELECT @cols += N',[' + name + '] ' + system_type_name + ' ' + REPLACE(REPLACE(is_nullable,'1','NULL'),'0','NOT NULL') + char(10)
			FROM sys.dm_exec_describe_first_result_set(N'SELECT * FROM ' + @tname, NULL, 1);
		SET @cols = STUFF(@cols, 1, 1, N' ');
		SET @sql = char(10) + N'CREATE TABLE [' + @tname + '] (' + char(10) + @cols;
		SELECT distinct @pk += N',[' + cc.COLUMN_NAME + '] ' + replace(replace(ic.is_descending_key,'1','DESC'),'0','ASC') + CHAR(10)
			from  INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE as cc, sys.index_columns ic where CONSTRAINT_NAME like '%$PK' and cc.TABLE_CATALOG='RTPCS' and COL_NAME(ic.object_id, ic.column_id)=cc.COLUMN_NAME and  cc.TABLE_NAME=@tname;
		set @pk = STUFF(@pk, 1, 1, N' ');
		set @sql = concat(@sql, N',CONSTRAINT ['+@tname+'$PK] PRIMARY KEY CLUSTERED ' + CHAR(10) + '(' +CHAR(10)+ @pk + ')' + char(10));
		SELECT @uk += N',[' + COLUMN_NAME +']' + CHAR(10)
			FROM INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where CONSTRAINT_NAME like '%$UK' and TABLE_NAME=@tname;
		set @uk = STUFF(@uk, 1, 1, N' ');
		set  @sql = concat(@sql,  N',CONSTRAINT ['+@tname+'$UK] UNIQUE NONCLUSTERED'+CHAR(10) + '(' + CHAR(10) + @uk + ')' + char(10));
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
,CONSTRAINT [CHINA_DRIVER$PK] PRIMARY KEY CLUSTERED 
(
 [ST_ID] ASC
)
,CONSTRAINT [CHINA_DRIVER$UK] UNIQUE NONCLUSTERED
(
 [APP_DT]
,[TFORM_NUM]
)
);

 */
