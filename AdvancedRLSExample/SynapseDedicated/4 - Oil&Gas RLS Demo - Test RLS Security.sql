-- 
-- Oil & Gas SQL Server Security Demo 
-- by Jamey Johnston, @STATCowboy, http://www.jameyjohnston.com
-- 10/03/2022
-- 
-- No Warranty, use at your own risk, not affliated with where I work.
-- 

USE sqlbits2022
go

--
-- Test Queries at Different Levels in the Asset Hierarchy in the Well Master Table
-- 

EXECUTE ('SELECT distinct division, region, asset_group, asset_team FROM [WELL_MASTER]') AS USER ='dcampos';  -- ALL Privs
go

EXECUTE ('SELECT distinct division, region, asset_group, asset_team FROM [WELL_MASTER]') AS USER ='hjames';  -- DIVISION Privs
go

EXECUTE ('SELECT distinct division, region, asset_group, asset_team FROM [WELL_MASTER]') AS USER ='rgaines' -- REGION Privs
go

EXECUTE ('SELECT distinct division, region, asset_group, asset_team FROM [WELL_MASTER]') AS USER ='sjohns' -- ASSET_GROUP Privs
go

EXECUTE ('SELECT distinct division, region, asset_group, asset_team FROM [WELL_MASTER]') AS USER ='imoody' -- ASSET_TEAM Privs
go

EXECUTE ('SELECT distinct division, region, asset_group, asset_team FROM [WELL_MASTER]') AS USER ='sbird' -- EXCEPTION Privs
go

EXECUTE ('SELECT distinct division, region, asset_group, asset_team FROM [WELL_MASTER]') AS USER ='ecross' -- NO Privs
go

-- Grant DB Writer to a few users to tests RLS DML Triggers
ALTER ROLE [db_datawriter] ADD MEMBER [dcampos];
ALTER ROLE [db_datawriter] ADD MEMBER [ivang];
ALTER ROLE [db_datawriter] ADD MEMBER [kmburu];
ALTER ROLE [db_datawriter] ADD MEMBER [rgaines];

-- Test After Insert Block on WELL_MASTER
EXECUTE ('insert into WELL_MASTER([WELL_ID], [WELL_NAME], [DIVISION], [REGION], [ASSET_GROUP], [ASSET_TEAM], [PROD_YEAR], [TVD]) 
          values (1001, ''WELL #1001'', ''US'', ''NORTHERN US'', ''PRB'', ''PRB OPERATED'', 2008, 5345)') AS USER ='dcampos';  -- CEO - NO Privs
go

EXECUTE ('insert into WELL_MASTER([WELL_ID], [WELL_NAME], [DIVISION], [REGION], [ASSET_GROUP], [ASSET_TEAM], [PROD_YEAR], [TVD]) 
          values (1002, ''WELL #1002'', ''INTERNATIONAL'', ''KENYA'', ''KENYA'', ''KENYA'', 2008, 5345)') AS USER ='ivang';  -- Yes to Insert
go

EXECUTE ('insert into WELL_MASTER([WELL_ID], [WELL_NAME], [DIVISION], [REGION], [ASSET_GROUP], [ASSET_TEAM], [PROD_YEAR], [TVD]) 
          values (1003, ''WELL #1003'', ''US'', ''SOUTHERN US'', ''GULF OF MEXICO'', ''TX GULF'', 2008, 5345)') AS USER ='kmburu';  -- Yes to Insert
go



-- Test After Update Block
-- (You will not be able to change the DIV/REG/AG/AT to a region where you do not have privs).
-- 
EXECUTE ('update WELL_MASTER set [DIVISION] = ''INTERNATIONAL'', [REGION] = ''KENYA'', 
                                 [ASSET_GROUP] = ''KENYA'', [ASSET_TEAM] = ''KENYA''
		  where [WELL_ID] = 1002') AS USER ='dcampos';  -- ALL Privs so will Succeed
go

EXECUTE ('update WELL_MASTER set [DIVISION] = ''INTERNATIONAL'', [REGION] = ''KENYA'', 
                                 [ASSET_GROUP] = ''KENYA'', [ASSET_TEAM] = ''KENYA''
		  where [WELL_ID] = 1003') AS USER ='rgaines';  -- No Privs to Intl, so 0 rows affected (cannot update what you cannot see)
go

EXECUTE ('update WELL_MASTER set [DIVISION] = ''INTERNATIONAL'', [REGION] = ''KENYA'', 
                                 [ASSET_GROUP] = ''KENYA'', [ASSET_TEAM] = ''KENYA''
		  where [WELL_ID] = 2') AS USER ='rgaines';  -- No Privs to Intl, so will Fail (cannot update a visible row to now violate your Privs)
go


-- 
-- Add another Hierarchy Node to the Security Model from a lower level in the Asset Hierarchy, Update the Security Tables (using proc) and Re-Run Above
-- 

insert into [SEC_ASSET_MAP] values (100018, 'ASSET_GROUP', 'GULF OF MEXICO');
execute Refresh_Security_Tables;
go

EXECUTE ('SELECT distinct division, region, asset_group, asset_team FROM [WELL_MASTER]') AS USER ='rgaines' -- REGION Privs
go



--
-- Test Queries at Different Levels in the Asset Hierarchy in the Well Daily Production Table
-- 

EXECUTE ('SELECT count(distinct WELL_ID) FROM [WELL_DAILY_PROD]') AS USER ='dcampos';  -- ALL Privs
go

EXECUTE ('SELECT * FROM [WELL_DAILY_PROD] where well_id = 999') AS USER ='dcampos';  -- ALL Privs
go

EXECUTE ('SELECT count(distinct WELL_ID) FROM [WELL_DAILY_PROD]') AS USER ='hjames';  -- DIVISION Privs
go

EXECUTE ('SELECT count(distinct WELL_ID) FROM [WELL_DAILY_PROD]') AS USER ='rgaines' -- REGION Privs
go

EXECUTE ('SELECT count(distinct WELL_ID) FROM [WELL_DAILY_PROD]') AS USER ='sjohns' -- ASSET_GROUP Privs
go

EXECUTE ('SELECT count(distinct WELL_ID) FROM [WELL_DAILY_PROD]') AS USER ='imoody' -- ASSET_TEAM Privs
go

EXECUTE ('SELECT count(distinct WELL_ID) FROM [WELL_DAILY_PROD]') AS USER ='sbird' -- EXCEPTION Privs
go

EXECUTE ('SELECT count(distinct WELL_ID) FROM [WELL_DAILY_PROD]') AS USER ='ecross' -- NO Privs
go


--
-- Test Queries at Different Levels in the Asset Hierarchy in the Well Downtime Table
-- 

EXECUTE ('SELECT count(distinct WELL_ID) FROM [WELL_DOWNTIME]') AS USER ='dcampos';  -- ALL Privs
go

EXECUTE ('SELECT count(distinct WELL_ID) FROM [WELL_DOWNTIME]') AS USER ='hjames';  -- DIVISION Privs
go

EXECUTE ('SELECT count(distinct WELL_ID) FROM [WELL_DOWNTIME]') AS USER ='rgaines' -- REGION Privs
go

EXECUTE ('SELECT count(distinct WELL_ID) FROM [WELL_DOWNTIME]') AS USER ='sjohns' -- ASSET_GROUP Privs
go

EXECUTE ('SELECT count(distinct WELL_ID) FROM [WELL_DOWNTIME]') AS USER ='imoody' -- ASSET_TEAM Privs
go

EXECUTE ('SELECT count(distinct WELL_ID) FROM [WELL_DOWNTIME]') AS USER ='sbird' -- EXCEPTION Privs
go

EXECUTE ('SELECT count(distinct WELL_ID) FROM [WELL_DOWNTIME]') AS USER ='ecross' -- NO Privs
go

