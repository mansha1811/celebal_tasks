--1. Create the Employee_Hierarchy table:
CREATE TABLE Employee_Hierarchy (
    EMPLOYEEID VARCHAR(20),
    REPORTINGTO NVARCHAR(MAX),
    EMAILID NVARCHAR(MAX),
    LEVEL INT,
    FIRSTNAME NVARCHAR(MAX),
    LASTNAME NVARCHAR(MAX)
);

--2. Create the stored procedure SP_hierarchy:
CREATE PROCEDURE SP_hierarchy
AS
BEGIN
    TRUNCATE TABLE Employee_Hierarchy;

    WITH EmployeeCTE AS (
        SELECT 
            EmployeeID,
            ReportingTo,
            EmailID,
            1 AS Level
        FROM 
            EMPLOYEE_MASTER
        WHERE 
            ReportingTo IS NULL

        UNION ALL
        SELECT 
            em.EmployeeID,
            em.ReportingTo,
            em.EmailID,
            cte.Level + 1 AS Level
        FROM 
            EMPLOYEE_MASTER em
        INNER JOIN 
            EmployeeCTE cte
        ON 
            em.ReportingTo = cte.EmployeeID
    )

    INSERT INTO Employee_Hierarchy (EMPLOYEEID, REPORTINGTO, EMAILID, LEVEL, FIRSTNAME, LASTNAME)
    SELECT 
        EmployeeID,
        ReportingTo,
        EmailID,
        Level,
        LEFT(EmailID, CHARINDEX('@', EmailID) - 1) AS FirstName,
        RIGHT(LEFT(EmailID, CHARINDEX('.', EmailID, CHARINDEX('@', EmailID)) - 1), 
              LEN(LEFT(EmailID, CHARINDEX('.', EmailID, CHARINDEX('@', EmailID)) - 1)) - CHARINDEX('@', EmailID)) AS LastName
    FROM 
        EmployeeCTE;
END;
