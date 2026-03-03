-- S M Naimul Hassan
-- 10684008
-- Md Tanjin Ridwan 
-- 10696342


USE teranet;
GO

--VIEW 1: planView
--Provides a combined view of internet plans and their access types

IF OBJECT_ID('planView', 'V') IS NOT NULL  --Condition checks if view "planView" already exists
    DROP VIEW planView;  --If it already exists, drops the view
GO

--Create a new view named 'planView'
CREATE VIEW planView AS
SELECT
    p.plan_id,                                --Unique ID of the internet plan
    p.plan_name,
    p.monthly_cost AS cost,                   --Monthly cost of plan
    p.monthly_quota_gb AS quota,              --Monthly data limit in GB
    p.max_download_speed AS download_speed,
    p.max_upload_speed AS upload_speed,
    p.shaped_download_speed AS shaped_speed,  --Reduced speed after quota is used
    p.type_id,
    t.type_name,
    t.max_speed
FROM internetPlan AS p
INNER JOIN accessType AS t                   --JOIN combines data from two tables (internetPlan, accessType)
  ON p.type_id = t.type_id;                   --Join condition between a Primary key and Foreign key (type_id)


GO

--VIEW 2: Job_View
--Displays all customer support jobs along with details about the customer, assigned staff, resolver, and job status

IF OBJECT_ID('jobView', 'V') IS NOT NULL  --Condition checks if view "jobView" already exists
    DROP VIEW Job_View;  --If it already exists, drops the view
GO

--Create a new view named 'Job_View'
CREATE VIEW Job_View AS
SELECT
    sj.job_id,
    sj.problem_summary AS summary,
    c.username AS username,
    c.first_name + ' ' + c.last_name AS customer_name,    --Full customer name
    sj.job_datetime AS lodged_date,                       --Date and time job was lodged
    sj.staff_id AS lodger_id,
    s1.first_name + ' ' + s1.last_name AS lodger_name,    --Full name of the staff who lodged the job
    sj.resolution_datetime AS resolve_date,               --Date and time issue was resolved
    sj.resolved_ByStaff_id AS resolver_id,
    s2.first_name + ' ' + s2.last_name AS resolver_name,  --Full name of the resolver staff
    js.status_id,
    js.status_name
FROM
    supportJob AS sj
    INNER JOIN customer AS c                                 --JOIN combines data from two tables (supportJob, customer)
        ON sj.customer_id = c.customer_id
    INNER JOIN staff AS s1                                   --Combines data from staff table, join condition staff_id
        ON sj.staff_id = s1.staff_id
    LEFT OUTER JOIN staff AS s2                              --Combines data from staff table, join condition resolved_ByStaff_id
        ON sj.resolved_ByStaff_id = s2.staff_id
    INNER JOIN jobStatus AS js                               --Combines data from jobStatus table
        ON sj.status_id = js.status_id;