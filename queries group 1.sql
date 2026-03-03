-- S M Naimul Hassan
-- 10684008
-- Md Tanjin Ridwan 
-- 10696342


-- Query 1 – Popular Plan Details
-- This query help to display the top 3 most popular internet plans based on the number of coustomers subscribed.
-- Also it shows the plan detalis such as quota, speed, tyoe, and cost.

USE teranet;
GO

SELECT TOP 3 
-- CONCAT combines multiple fields and text into one descriptive sentence.
    CONCAT(
        pv.plan_name, ' (', COUNT(c.customer_id), ' customers) is a ', pv.quota, 'GB, ', pv.download_speed, 'Mbps down, ', pv.upload_speed, 'Mbps up ',pv.type_name, 
        ' plan costing $', pv.cost, '.') AS [Popular Plan Details]
FROM planView AS pv
JOIN customer AS c 
    ON pv.plan_id = c.plan_id     --join plans with customers to count the subscribers.
GROUP BY 
    pv.plan_name, pv.quota, pv.download_speed, pv.upload_speed, pv.type_name, pv.cost
ORDER BY COUNT(c.customer_id) DESC; -- sort to find top 3 plans with most customers.


--Qurey 02
-- List all plans under $70, with at least 500Gb data, excluding the wireless types.

SELECT 
    pv.plan_id, pv.plan_name, pv.cost, pv.quota, pv.download_speed, pv.upload_speed, pv.type_name

FROM planView AS pv
WHERE 
    pv.cost < 70 --To find the plans which is under $70.
    AND pv.quota >= 500
    AND pv.type_name <> 'Wireless'
ORDER BY pv.cost; --To show the cheapest plan first.


--Qurey 03
-- Identify inconsistencies between job status and resolver detailes.

SELECT 
    jv.job_id, jv.status_name, jv.resolve_date,jv.resolver_name AS [Resolving Staff]

FROM Job_View AS jv
WHERE 
    (
	-- If the job is marked as Resolved (as status_id = 4), but resolver or date is missing.
        (jv.status_id = 4 AND (jv.resolver_id IS NULL OR jv.resolve_date IS NULL))
    )
    OR
    (
	--If job is Not resolved but has resolver/date filled in data.
        (jv.status_id <> 4 AND (jv.resolver_id IS NOT NULL OR jv.resolve_date IS NOT NULL))
    )
ORDER BY jv.job_id;


-- Query 4 – Speed Issues
--Display all the support jobs that mention any speed or slow issues.
USE teranet;
GO

SELECT
    sj.job_id,
    sj.problem_summary           AS summary,
    sj.job_datetime              AS lodge_date,
	-- Combine the download/upload speed for easy comparison.
    CONCAT(p.max_download_speed, ':', p.max_upload_speed) AS plan_speed,
    p.shaped_download_speed      AS shaped_speed,
    t.type_name
FROM supportJob AS sj
INNER JOIN customer    AS c ON sj.customer_id = c.customer_id
INNER JOIN internetPlan AS p ON c.plan_id = p.plan_id
INNER JOIN accessType   AS t ON p.type_id = t.type_id
WHERE sj.problem_summary LIKE '%speed%' -- Search the jobs summary and find where is mentioning the speed.
   OR sj.problem_summary LIKE '%slow%' -- or the slow word
ORDER BY sj.job_datetime DESC;


--Query 5
-- summarize the total number of customers, total revenue, average payment, and most recent payment per plan.
USE teranet;
GO

SELECT
    p.plan_id,
    p.plan_name,
    p.monthly_cost AS monthly_cost,
    COUNT(DISTINCT c.customer_id) AS total_customers,
    SUM(pay.amount) AS total_revenue, -- Sum the payment and make the total money received.
    AVG(pay.amount) AS average_payment, -- Calculate the average payment per customer.
    MAX(pay.payment_date) AS latest_payment_date -- Find the date of last payment.
FROM internetPlan AS p LEFT JOIN customer AS c
    ON p.plan_id = c.plan_id
    LEFT JOIN payment AS pay
    ON p.plan_id = pay.plan_id
GROUP BY p.plan_id, p.plan_name, p.monthly_cost
ORDER BY total_revenue DESC;


--Query 6
-- Show the staff notes longer then the average not length, including word count and staff name.
USE teranet;
GO

SELECT 
    n.note_id,
    n.note_DateTime AS note_date,
    n.note_content AS note_text,
    LEN(n.note_content) AS note_length,
    s.first_name + ' ' + s.last_name AS staff_name
FROM note AS n INNER JOIN staff AS s
    ON n.staff_id = s.staff_id
WHERE LEN(n.note_content) > (SELECT AVG(LEN(note_content)) 
                             FROM note) --compare to the averager note length.
ORDER BY note_length DESC;


--Query 7
-- List staff alongside their mentor, showing mismatches such as mentors hired later than their mantees or satff
-- with less experience than expected for their level.
USE teranet;
GO

SELECT
    s.first_name + ' ' + s.last_name      AS staff_name,
    s.hire_date                           AS staff_hire_date,
    sl.level_name                         AS staff_level_name,
    m.first_name + ' ' + m.last_name      AS mentor_name,
    m.hire_date                           AS mentor_hire_date
FROM staff AS s INNER JOIN staffLevel AS sl
    ON s.level_id = sl.level_id
    LEFT  JOIN staff AS m
    ON s.mentor_id = m.staff_id

WHERE (m.hire_date > s.hire_date) -- mentor hired after mentee
       OR (DATEDIFF(YEAR, s.hire_date, CURRENT_TIMESTAMP) < sl.expected_experience) --Staff lacks requrired experience.
ORDER BY staff_name;


--Query 8
-- Show the resolved jobs that took at least 1 hour, were handled by different staff, and have at least 2 notes.
USE teranet;
GO

SELECT
    j.job_id,
    j.summary,
    j.lodged_date,
    j.lodger_name,
    j.resolver_name,
    DATEDIFF(HOUR, j.lodged_date, j.resolve_date) AS duration, -- calculate resolution duration.
    n.num_notes
FROM Job_View AS j
INNER JOIN (
    SELECT job_id, COUNT(*) AS num_notes   -- count number of notes writtens per job.
    FROM note
    GROUP BY job_id
) AS n
    ON n.job_id = j.job_id
WHERE
      j.resolve_date IS NOT NULL
  AND DATEDIFF(HOUR, j.lodged_date, j.resolve_date) >= 1   --Select jobs with 2 hr+ duration, 2+ notes and where lodger != resolver.
  AND j.resolver_id IS NOT NULL
  AND j.lodger_id <> j.resolver_id
  AND n.num_notes >= 2
ORDER BY j.lodged_date DESC;


--Query 9
-- Display staff activity statistics including number of job lodged, resolved, and not written.
USE teranet;
GO

SELECT
    s.staff_id,
    s.first_name + ' ' + s.last_name      AS staff_name,
    sl.level_name,
    ISNULL(jl.jobs_lodged, 0)    AS jobs_lodged, -- Replace the NULL with 0 if no jobs lodged.
    ISNULL(jr.jobs_resolved, 0)  AS jobs_resolved, -- Replace the NULL with 0 if no jobs resolved.
    ISNULL(nw.notes_written, 0)  AS notes_written -- Replace the NULL with 0 if no note written.
FROM staff AS s
INNER JOIN staffLevel AS sl
    ON s.level_id = sl.level_id
LEFT JOIN (
    SELECT staff_id, COUNT(*) AS jobs_lodged  -- This subquery counts how many jobs each staff lodged.
    FROM supportJob
    GROUP BY staff_id
) AS jl
    ON jl.staff_id = s.staff_id
LEFT JOIN (
    SELECT resolved_ByStaff_id AS staff_id, COUNT(*) AS jobs_resolved  -- This subquery counts how many jobs each staff resolved.
    FROM supportJob
    WHERE resolved_ByStaff_id IS NOT NULL
    GROUP BY resolved_ByStaff_id
) AS jr
    ON jr.staff_id = s.staff_id
LEFT JOIN (
    SELECT staff_id, COUNT(*) AS notes_written  -- This subquery counts how many notes each staff wrote.
    FROM note
    GROUP BY staff_id
) AS nw
    ON nw.staff_id = s.staff_id
ORDER BY
    sl.level_name, --Order by staff ievel first
    jobs_resolved DESC; -- then order by jobs resolved.