-- 
-- Oil & Gas SQL Server Security Demo 
-- by Jamey Johnston, @STATCowboy, http://www.jameyjohnston.com
-- 10/03/2022
-- 
-- No Warranty, use at your own risk, not affliated with where I work.
-- 

-- 
-- Create Users in Database using SEC_ORG_USER_BASE table
-- 



DECLARE user_cursor CURSOR
   FOR
   SELECT userid from [SEC_ORG_USER_BASE];
OPEN user_cursor;
DECLARE @username varchar(12);
FETCH NEXT FROM user_cursor INTO @username;
WHILE (@@FETCH_STATUS <> -1)
BEGIN;
   EXECUTE ('create user [' + @username + '] WITHOUT LOGIN;');
   EXECUTE ('ALTER ROLE [db_datareader] ADD MEMBER [' + @username + '];');
   FETCH NEXT FROM user_cursor INTO @username;
END;
PRINT 'The users have been created.';
CLOSE user_cursor;
DEALLOCATE user_cursor;
GO


-- 
-- Create Procedure to Refresh Security Table
-- 

create procedure Refresh_Security_Tables
as

BEGIN

     delete dbo.SEC_ORG_USER_BASE_MAP;
     
     with emp as
     (
       select 
      e.EMPLID,
      e.USERID,
      e.NAME,
      e.ORG_UNIT_ID,
      null ParentOrgId,
      e.MGRID SupervisorId,
      e.ORG_UNIT_NAME Position
        from SEC_ORG_USER_BASE e
        -- where e.EMPLID > '0'
     ), sec_grp_app_map as
     (
       SELECT 
            OU
       FROM SEC_ASSET_MAP
     ), rq as
     (
      select emp.emplid, emp.userid, emp.name, emp.is_employee, emp.org_unit_id, 
	         emp.org_unit_name, 1 level, 
			 case when exists (select * from sec_grp_app_map where OU = emp.ORG_UNIT_ID) 
			 then emp.ORG_UNIT_ID else null end SECURITY_CLEARANCE,
     		cast(emp.ORG_UNIT_ID as varchar(max)) as ORG_UNIT_ID_PATH,
     		cast(emp.ORG_UNIT_NAME as varchar(max)) as ORG_UNIT_NAME_PATH
      from dbo.SEC_ORG_USER_BASE emp
      where (mgrid is null or mgrid = 0)
      union all
      select emp.emplid, emp.userid, emp.name, emp.is_employee, emp.org_unit_id, 
	         emp.org_unit_name, rq.level + 1 level, 
			case when exists (select * from sec_grp_app_map where OU = emp.ORG_UNIT_ID) 
			     then emp.ORG_UNIT_ID else rq.SECURITY_CLEARANCE end SECURITY_CLEARANCE, 
     		case when emp.org_unit_id <> rq.org_unit_id 
			   then cast(rq.ORG_UNIT_ID_PATH + '|' + cast(emp.ORG_UNIT_ID as varchar(6)) as varchar(max)) else cast(rq.ORG_UNIT_ID_PATH as varchar(max)) end, 
     		case when emp.ORG_UNIT_NAME <> rq.ORG_UNIT_NAME 
			   then cast(rq.ORG_UNIT_NAME_PATH + '|' + emp.ORG_UNIT_NAME as varchar(max)) else cast(rq.ORG_UNIT_NAME_PATH as varchar(max)) end
      from rq 
      join dbo.SEC_ORG_USER_BASE emp 
      on rq.emplid = emp.mgrid
     )
     insert into dbo.SEC_ORG_USER_BASE_MAP
     select * 
     from rq;
     
     -- 
     
     DELETE [SEC_USER_MAP];

     
     INSERT INTO [SEC_USER_MAP]
     SELECT SOUMB.USERID, SGAM.[HIERARCHY_NODE], SGAM.[HIERARCHY_VALUE]
       FROM [SEC_ORG_USER_BASE_MAP] SOUMB
         JOIN [SEC_ASSET_MAP] SGAM
     	  ON SOUMB.SECURITY_CLEARANCE = SGAM.OU
       WHERE 
       (SOUMB.USERID IN 
          (SELECT name
             FROM sys.database_principals
             WHERE type in ('U','S')
     	AND
     	SOUMB.USERID NOT IN
     	(SELECT USERID FROM [SEC_USER_EXCEPTIONS] WHERE HIERARCHY_NODE = 'ALL')))
     UNION ALL
     SELECT * from [SEC_USER_EXCEPTIONS] WHERE HIERARCHY_NODE = 'ALL';
     
end;
go


--
-- Execute Refresh_Security_Tables Procedure to Load Security Tables
-- 

execute Refresh_Security_Tables;
go


-- 
-- WELL Policies
-- 

CREATE SCHEMA RLS;
GO

CREATE FUNCTION [rls].[fn_WELL_SecPred](@wid int)
    RETURNS TABLE 
	WITH SCHEMABINDING
AS
    return SELECT 1 as [fn_WELL_SecPred_Result]  
		WHERE 
		(
          (@wid in 
			   (select WELL_ID from dbo.WELL_MASTER where DIVISION in (select HIERARCHY_VALUE from dbo.SEC_USER_MAP 
			            where USERID = USER_NAME() and HIERARCHY_NODE = 'DIVISION'))
			   OR
			@wid in    
			   (select WELL_ID from dbo.WELL_MASTER where REGION in (select HIERARCHY_VALUE from dbo.SEC_USER_MAP 
			            where USERID = USER_NAME() and HIERARCHY_NODE = 'REGION'))
			OR
			@wid in    
			   (select WELL_ID from dbo.WELL_MASTER where ASSET_GROUP in (select HIERARCHY_VALUE from dbo.SEC_USER_MAP 
			            where USERID = USER_NAME() and HIERARCHY_NODE = 'ASSET_GROUP'))
			OR
			@wid in    
			   (select WELL_ID from dbo.WELL_MASTER where ASSET_TEAM in (select HIERARCHY_VALUE from dbo.SEC_USER_MAP 
			            where USERID = USER_NAME() and HIERARCHY_NODE = 'ASSET_TEAM'))
			OR
			@wid in    
			   (select WELL_ID from dbo.WELL_MASTER where 'ALL' in (select HIERARCHY_VALUE from dbo.SEC_USER_MAP 
			            where USERID = USER_NAME()))
		)
	  )
go


-- 
-- Block Predicate on WELL_MASTER
-- 

-- Create a New Function to only Allow Authorized Well creation users (via Exception table)
-- access to Add new Wells to WELL_MASTER

CREATE FUNCTION [rls].[fn_WELLMaster_SecBlockPred]()
    RETURNS TABLE 
	WITH SCHEMABINDING
AS
    return SELECT 1 as [fn_WELLMaster_SecBlockPred] 
	    WHERE
		(
		    'WELLAUTH' in (select HIERARCHY_VALUE from dbo.SEC_USER_EXCEPTIONS 
			            where USERID = USER_NAME())
		)
go


-- Create & enable the Security policy on top of WELL tables
create SECURITY POLICY [rls].[WELL_SecPol] 
  ADD FILTER PREDICATE [rls].[fn_WELL_SecPred]([WELL_ID]) on [dbo].[WELL_MASTER],
  -- ADD BLOCK PREDICATE [rls].[fn_WELLMaster_SecBlockPred]() ON [dbo].[WELL_MASTER] AFTER INSERT, -- Does not work in Synapase
  -- ADD BLOCK PREDICATE [rls].[fn_WELL_SecPred]([WELL_ID]) ON [dbo].[WELL_MASTER] AFTER UPDATE, -- Does not work in Synapase
  ADD FILTER PREDICATE [rls].[fn_WELL_SecPred]([WELL_ID]) on [dbo].[WELL_DAILY_PROD],
  ADD FILTER PREDICATE [rls].[fn_WELL_SecPred]([WELL_ID]) on [dbo].[WELL_DOWNTIME]
go




