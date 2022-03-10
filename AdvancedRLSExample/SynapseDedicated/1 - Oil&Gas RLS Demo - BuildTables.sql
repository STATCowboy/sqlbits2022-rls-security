-- 
-- Oil & Gas SQL Server Security Demo 
-- by Jamey Johnston, @STATCowboy, http://www.jameyjohnston.com
-- 10/03/2022
-- 
-- No Warranty, use at your own risk, not affliated with where I work.
-- 


-- 
-- Create SQL Dedicated Pool in Synapse Studio
-- 
-- 


--
-- Create Master Well Table
--

CREATE TABLE [WELL_MASTER](
	[WELL_ID] [int] NOT NULL,
	[WELL_NAME] [varchar](100) NULL,
	[DIVISION] [varchar](100) NULL,
	[REGION] [varchar](100) NULL,
	[ASSET_GROUP] [varchar](100) NULL,
	[ASSET_TEAM] [varchar](100) NULL,
	[PROD_YEAR] [varchar](4) NULL,
	[TVD] [float] NULL
)

GO


-- 
-- Create Well Daily Production Table
-- 

CREATE TABLE [WELL_DAILY_PROD](
	[WELL_ID] [int] NOT NULL,
	[DTE] [datetime2](7) NOT NULL,
	[OIL] [float] NULL,
	[GAS] [float] NULL,
	[NGL] [float] NULL
)

GO



--
-- Well Downtime Reason Code
--

CREATE TABLE [WELL_REASON_CODE](
	[REASON_CODE] [int] NOT NULL,
	[REASON] [varchar] (50) NOT NULL
)

GO



-- 
-- Create Well Downtime Table
-- 

CREATE TABLE [WELL_DOWNTIME](
	[WELL_ID] [int] NOT NULL,
	[DTE] [datetime2](7) NOT NULL, 
	[REASON_CODE] [int] NOT NULL,
	[HOURS] [int] NOT NULL
)

GO



-- 
-- Asset Hierarchy Table
-- 

CREATE TABLE [ASSET_HIERARCHY](
	[ID] [int] NOT NULL,
	[DIVISION] [varchar](100) NOT NULL,
	[REGION] [varchar](100) NOT NULL,
	[ASSET_GROUP] [varchar](100) NOT NULL,
	[ASSET_TEAM] [varchar](100) NOT NULL
)
GO

-- 
-- Security Table for Asset Map entries to Org Unit IDs
-- 

CREATE TABLE [SEC_ASSET_MAP](
	[OU] [varchar](64) NULL,
	[HIERARCHY_NODE] [varchar](64) NULL,
	[HIERARCHY_VALUE] [varchar](64) NULL
)
GO


-- 
-- Security Table for User Map access based on Asset Hierarchy
-- 

CREATE TABLE [SEC_USER_MAP](
	[USERID] [varchar](64) NULL,
	[HIERARCHY_NODE] [varchar](64) NULL,
	[HIERARCHY_VALUE] [varchar](64) NULL
)
GO


-- 
-- Security Table Loaded with Employee Data
-- 

CREATE TABLE [SEC_ORG_USER_BASE](
	[EMPLID] [int] NOT NULL,
	[USERID] [varchar](12) NULL,
	[NAME] [varchar](50) NULL,
	[IS_EMPLOYEE] [varchar](1) NULL,
	[ORG_UNIT_ID] [int] NULL,
	[ORG_UNIT_NAME] [varchar](100) NULL,
	[MGRID] [int] NULL
)
GO


-- 
-- Security Table generated from SEC_ORG_USER_BASE and SEC_ASSET_MAP to map 
-- User's Security Level based on Organization Hiearchy and Entries in SEC_ASSET_MAP 
-- 

CREATE TABLE [SEC_ORG_USER_BASE_MAP](
	[EMPLID] [int] NOT NULL,
	[USERID] [varchar](12) NULL,
	[NAME] [varchar](50) NULL,
	[IS_EMPLOYEE] [varchar](1) NULL,
	[ORG_UNIT_ID] [int] NULL,
	[ORG_UNIT_NAME] [varchar](100) NULL,
	[LVL] [int] NULL,
	[SECURITY_CLEARANCE] [varchar](128) NULL,
	[ORG_UNIT_ID_PATH] [varchar](4000) NULL,
	[ORG_UNIT_NAME_PATH] [varchar](4000) NULL
)
GO


-- 
-- Security Table to map User Exceptions to the Security
-- 

CREATE TABLE [SEC_USER_EXCEPTIONS](
	[USERID] [varchar](64) NULL,
	[HIERARCHY_NODE] [varchar](64) NULL,
	[HIERARCHY_VALUE] [varchar](64) NULL
)
GO

