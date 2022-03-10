-- 
-- Simple RLS Demo of Well Header Data 
-- by Jamey Johnston, @STATCowboy, http://www.jameyjohnston.com
-- 10/03/2022
-- 
--
-- Adopted from Row-Level Security (Azure SQL Database)
-- https://msdn.microsoft.com/en-us/library/dn765131.aspx
-- 

-- 
-- For Synapase create DB in Portal to test Script.
-- 


-- 
-- Setup Users for Testing
--
CREATE USER VP_US WITHOUT LOGIN;
CREATE USER NORTHERN_US WITHOUT LOGIN;
CREATE USER SOUTHERN_US WITHOUT LOGIN;
GO

-- 
-- Setup Table
--
CREATE TABLE Well_Header
(
    [WELL_ID] [int] NOT NULL,
	[REGION] [varchar](100) NULL,
	[WELL_NAME] [varchar](100) NULL,
	[PROD_YEAR] [varchar](4) NULL
);
GO

-- 
-- Insert Data into Table
-- 
INSERT Well_Header VALUES 
(1, 'NORTHERN_US', 'Well 1', '2011');
INSERT Well_Header VALUES 
(2, 'SOUTHERN_US', 'Well 2', '2003');
INSERT Well_Header VALUES 
(3, 'NORTHERN_US', 'Well 3', '2005');
INSERT Well_Header VALUES 
(4, 'NORTHERN_US', 'Well 4', '2012'); 
INSERT Well_Header VALUES 
(5, 'SOUTHERN_US', 'Well 5', '2009');
GO

--
-- View the Data
--  
SELECT * FROM Well_Header;
GO

-- 
-- Grants
-- 
GRANT SELECT ON Well_Header TO VP_US;
GRANT SELECT ON Well_Header TO NORTHERN_US;
GRANT SELECT ON Well_Header TO SOUTHERN_US;
GO

-- 
-- Create Schema and RLS Function
-- 
CREATE SCHEMA RLS;
GO

CREATE FUNCTION RLS.fn_RLSpredicate(@Region AS sysname)
    RETURNS TABLE
WITH SCHEMABINDING
AS
    RETURN SELECT 1 AS fn_RLSpredicate_result 
WHERE USER_NAME() = 'VP_US' or @Region = USER_NAME();
GO

-- 
-- Create RLS Policy
-- 
CREATE SECURITY POLICY Well_HeaderFilter
ADD FILTER PREDICATE RLS.fn_RLSpredicate(Region) 
ON dbo.Well_Header
WITH (STATE = ON);
GO

-- 
-- Create Test Cases
-- 
EXECUTE AS USER = 'NORTHERN_US';
SELECT 'Northern US', * FROM Well_Header; 
REVERT;

EXECUTE AS USER = 'SOUTHERN_US';
SELECT 'Southern US', * FROM Well_Header; 
REVERT;

EXECUTE AS USER = 'VP_US';
SELECT 'VP US', * FROM Well_Header; 
REVERT;
GO

