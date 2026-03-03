-- S M Naimul Hassan
-- 10684008
-- Md Tanjin Ridwan 
-- 10696342


IF DB_ID('teranet') IS NOT NULL         --Condition for checking if "teranet" database already exists 
	BEGIN
		PRINT 'Database exists - dropping.';
		
		USE master;		
		ALTER DATABASE teranet SET SINGLE_USER WITH ROLLBACK IMMEDIATE;  --Set to SINGLE_USER mode to terminate active connections
		
		DROP DATABASE teranet;  --Drop the database safely
	END

GO

PRINT 'Creating database.';

CREATE DATABASE teranet;     --Creates an empty database "teranet"

GO

USE teranet;    --Switch to the new database "teranet"

GO


--Create table for storing types of internet connections
PRINT 'Creating accessType table.'

CREATE TABLE accessType
( type_id    TINYINT NOT NULL IDENTITY,  --Auto increments type_id (IDENTITY) as integer
  type_name  VARCHAR(25) NOT NULL,       --Creates column that stores type name as variable of max 25 characters, must have value (NOT NULL)
  max_speed  SMALLINT NOT NULL,          --Column stores maximum speed of internet type as integer

  CONSTRAINT acctyp_pk PRIMARY KEY (type_id),  --Constraint that selects type_id as Primary key
  CONSTRAINT acctyp_uk UNIQUE (type_name)      -- Constraint that ensures each type name is unique
);

--Create table for storing details about available internet plans
PRINT 'Creating internetPlan table.'

CREATE TABLE internetPlan
( plan_id               INT NOT NULL IDENTITY,
  plan_name             VARCHAR(25) NOT NULL,
  monthly_cost          SMALLMONEY NOT NULL,
  monthly_quota_gb      SMALLINT NULL,
  max_download_speed    SMALLINT NULL,
  max_upload_speed      SMALLINT NULL,
  shaped_download_speed SMALLINT NULL,
  type_id               TINYINT NOT NULL,  --Foreign key

  CONSTRAINT  plan_pk PRIMARY KEY (plan_id),  --Constraint that selects plan_id as Primary key
  CONSTRAINT  plan_uk UNIQUE (plan_name),     --Plan name must be unique
  CONSTRAINT  plan_acctyp_fk FOREIGN KEY (type_id) REFERENCES accessType(type_id),      --Constraint that references type_id from accessType table
  CONSTRAINT  plan_speed_chk CHECK(shaped_download_speed IS NULL OR max_download_speed IS NULL OR shaped_download_speed <= max_download_speed)  --Constraint checks Shaped speed cannot exceed max download speed
);

--Create table for storing customer account and contact information
PRINT 'Creating customer table.'

CREATE TABLE customer
( customer_id INT NOT NULL IDENTITY,
  username    VARCHAR(25) NOT NULL,
  first_name  VARCHAR(25) NOT NULL,
  last_name   VARCHAR(25) NOT NULL,
  email       VARCHAR(25) NOT NULL,
  password    VARCHAR(256) NOT NULL,  --Column contains password hash
  address     VARCHAR(100) NULL,
  phone       VARCHAR(20) NULL,
  plan_id     INT NOT NULL,    --Foreign key

  CONSTRAINT cust_pk PRIMARY KEY (customer_id),  --Constraint that selects customer_id as Primary key
  CONSTRAINT cust_user_uk UNIQUE (username),
  CONSTRAINT cust_mail_uk UNIQUE (email),
  CONSTRAINT cust_plan_fk FOREIGN KEY (plan_id) REFERENCES internetPlan(plan_id)  --Constraint that references plan_id from internetPlan table
);

--Create table that records customer payments for their plans
PRINT 'Creating payment table.'

CREATE TABLE payment
( payment_id     SMALLINT NOT NULL IDENTITY,
  payment_date   SMALLDATETIME NOT NULL,
  amount         DECIMAL(10, 2) NOT NULL,
  payment_method VARCHAR(25) NOT NULL,
  billing_period CHAR(7) NOT NULL CHECK(billing_period LIKE '[0-9][0-9][0-9][0-9]-[0-1][0-9]'),  --Check that the Billing period is in the YYYY-MM format
  customer_id    INT NOT NULL,  --Foreign key
  plan_id        INT NOT NULL,  --Foreign key

  CONSTRAINT pay_pk PRIMARY KEY (payment_id),  --Constraint that selects payment_id as Primary key
  CONSTRAINT pay_cust_fk FOREIGN KEY (customer_id) REFERENCES customer(customer_id),  --Constraint that references customer_id from customer table
  CONSTRAINT pay_plan_fk FOREIGN KEY (plan_id) REFERENCES internetPlan(plan_id)  --Constraint that references plan_id from internetPlan table
);

--Create table that stores level details of staff
PRINT 'Creating staffLevel table.'

CREATE TABLE staffLevel
( level_id            INT NOT NULL IDENTITY CONSTRAINT lvl_pk PRIMARY KEY,  --Auto increments level_id and selects as Primary key
  level_name          VARCHAR(25) NOT NULL UNIQUE,
  expected_experience INT NULL,
  hourly_payrate      DECIMAl(10,2) NULL  --Column contains a number of max 10 digits, with 2 of them being to the right of the decimal point, empty by default (NULL)
);

--Create table that stores information about staff members and their mentors
PRINT 'Creating staff table.'

CREATE TABLE staff
( staff_id  INT NOT NULL IDENTITY CONSTRAINT staff_pk PRIMARY KEY,  --Auto increments staff_id and selects as Primary key
 first_name VARCHAR(25) NOT NULL,
 last_name  VARCHAR(25) NOT NULL,
 phone      VARCHAR(20) NULL,
 hire_date  SMALLDATETIME NOT NULL,
 mentor_id  INT NULL,      --Self-referencing Foreign key
 level_id   INT NOT NULL,  --Foreign key

 CONSTRAINT hire_date_check CHECK(hire_date <= CURRENT_TIMESTAMP),  --Checks Hire date cannot be later than current datetime
 CONSTRAINT mentor_fk FOREIGN KEY (mentor_id) REFERENCES staff(staff_id),  --References staff_id from staff table
 CONSTRAINT staff_lvl_fk FOREIGN KEY (level_id) REFERENCES staffLevel(level_id),  --References level_id from staffLevel table
 CONSTRAINT mentor_staff_chk CHECK(mentor_id IS NULL OR mentor_id <> staff_id)  --Checks one cannot mentor oneself
);

--Create table that stores possible job statuses (Unresolved, Pending, Resolved)
PRINT 'Creating jobStatus table.'

CREATE TABLE jobStatus
( status_id     INT NOT NULL IDENTITY CONSTRAINT status_pk PRIMARY KEY,  --status_id as Primary key
  status_name   VARCHAR (30) NOT NULL UNIQUE,
);

--Create table that records customer support jobs/tickets raised
PRINT 'Creating support job table.'

CREATE TABLE supportJob
( job_id     INT NOT NULL IDENTITY,
  customer_id INT NOT NULL,
  staff_id INT NOT NULL,
  job_datetime  SMALLDATETIME NOT NULL,  --Column stores when job was lodged in YYYY-MM-DD HH:mm:ss format
  problem_summary VARCHAR (50) NOT NULL,
  resolution_DATETIME SMALLDATETIME NULL,  --Column stores when job was resolved in YYYY-MM-DD HH:mm:ss format
  resolved_ByStaff_id INT NULL,          --ID of staff who resolved the job
  status_id INT NOT NULL DEFAULT 1,      --Foreign key, status ID of job, set to 1 (Unresolved) by default
 

  CONSTRAINT sup_job_pk PRIMARY KEY (job_id),
  CONSTRAINT sup_resol_fk FOREIGN KEY (resolved_ByStaff_id) REFERENCES staff(staff_id),  --References staff_id from staff table
  CONSTRAINT sup_stat_id_fk FOREIGN KEY (status_id) REFERENCES jobStatus(status_id),  --References status_id from jobStatus table
  CONSTRAINT sup_resol_chk CHECK(resolution_DATETIME > job_datetime)    --Checks job resolution datetime cannot be before job lodge datetime
);

--Create table that stores staff notes written for each support job
PRINT 'Creating note table.'

CREATE TABLE note
( note_id       INT NOT NULL IDENTITY,
  note_DateTime SMALLDATETIME NOT NULL,
  note_content  VARCHAR(200),
  job_id        INT NOT NULL,  --Foreign key
  staff_id      INT NOT NULL,  --Foreign key

  CONSTRAINT note_pk PRIMARY KEY (note_id),
  CONSTRAINT note_job_fk FOREIGN KEY (job_id) REFERENCES supportJob(job_id),  --References job_id from supportJob table
  CONSTRAINT note_staff_fk FOREIGN KEY (staff_id) REFERENCES staff(staff_id)  --References staff_id from staff table
);


--Insert required data into the empty tables
PRINT 'Populating accessType table.'

INSERT INTO accessType (type_name, max_speed)
VALUES	('ADSL', 24),
		('Fibre', 1000),
		('Wireless', 150);

PRINT 'Populating internetPlan table.'

INSERT INTO internetPlan (plan_name, monthly_cost, monthly_quota_gb, max_download_speed, max_upload_speed, shaped_download_speed, type_id)
VALUES	('Budget Broadband', 29.95, 250, 24, 5, 24, 1),
		('NBN Lite', 49.95, 500, 50, 5, 25, 2),
		('NBN Max', 69.95, 1500, 100, 20, 50, 2),
		('Freedom Lite', 59.95, 500, 50, 5, 25, 3),
		('Freedom Ultra', 109.95, 1000, 150, 20, 50, 3);


PRINT ' Populating customer table.'

INSERT INTO customer (username, first_name, last_name, email, password, address, phone, plan_id)
VALUES ('john123', 'John', 'Smith', 'john.smith@email.com', '2b91b3b37500865167583515e55edc00', '10 Main St, Perth WA', '0412000111', 1),
       ('amy99', 'Amy', 'Lee', 'amy.lee@email.com', 'd3b8cc3a9b4a1d8f66d99f3d373eb23f','45 King Rd, Perth WA', '0412000222', 2),
	   ('mark77', 'Mark', 'Taylor', 'mark.taylor@email.com', 'd7eb0b1e6f73d70f2fd8a37b9d437a73', '75 Swan Ave, Perth WA', '0412000333', 3),
	   ('sara88', 'Sara', 'Ahmed', 'sara.ahmed@email.com', 'df4b7a89137d154021b3c6f6f3444f89','12 Lake St, Perth WA', '0412000444', 4),
	   ('liam55', 'Liam', 'Brown', 'liam.brown@email.com', 'cb76378869ffb876f64b2a6d7adbc5db','9 Hill Rd, Perth WA', '0412000555', 2),
	   ('emily01', 'Emily', 'Jones', 'emily.jones@email.com', '4b8e58e2e1fba8d26e03f999c53d80d8', '120 River Dr, Perth WA', '0412000666', 1),
	   ('noah24', 'Noah', 'Wilson', 'noah.wilson@email.com', '8a3a3afae1b07bfe86c53bb4344d0460', '34 Ocean Blvd, Perth WA', '0412000777', 2),
	   ('chloe77', 'Chloe', 'Nguyen', 'chloe.nguyen@email.com', 'ef5eb1a22b785b3af31e246735f9dc8c', '87 Park Ln, Perth WA', '0412000888', 4),
	   ('oliver89', 'Oliver', 'Clark', 'oliver.clark@email.com', '42c01e53d6a8a64f868be1d72cbf37d2', '56 Grove St, Perth WA', '0412000999', 3),
	   ('mia42', 'Mia', 'Patel', 'mia.patel@email.com', '0f20d8d6f33cf221543e878e7b3ed52c','23 Forest Rd, Perth WA', '0412000100', 3),
	   ('grace99', 'Grace', 'Parker', 'grace.parker@email.com', 'ac59dfcb6fc3ccf32e6b153dc2a964a5', '88 Rosewood Ave, Perth WA', '0413000112', 3);


PRINT 'Populating payment table.'

INSERT INTO payment (payment_date, amount, payment_method, billing_period, customer_id, plan_id)
VALUES ('2025-10-01', 89.99, 'Credit Card', '2025-10', 1, 1),
       ('2025-10-02', 59.99, 'PayPal', '2025-10', 2, 2),
	   ('2025-10-03', 39.99, 'Direct Debit', '2025-10', 3, 3),
	   ('2025-10-04', 49.99, 'Credit Card', '2025-10', 4, 4),
	   ('2025-10-05', 89.99, 'Credit Card', '2025-10', 5, 1),
	   ('2025-10-06', 59.99, 'Bank Transfer', '2025-10', 6, 2),
	   ('2025-10-07', 39.99, 'PayPal', '2025-10', 7, 3),
	   ('2025-10-08', 49.99, 'Credit Card', '2025-10', 8, 4),
	   ('2025-10-09', 89.99, 'Direct Debit', '2025-10', 9, 1),
	   ('2025-10-10', 59.99, 'Credit Card', '2025-10', 10, 2);



PRINT 'Populating staffLevel table.'

INSERT INTO staffLevel (level_name, expected_experience, hourly_payrate)
VALUES	('Level 1 (Junior Support)', 0, 23.50),
		('Level 2 (Senior Support)', 1, 27.50),
		('Level 3 (Expert Support)', 3, 34.50);



PRINT 'Populating staff table.'

INSERT INTO staff (first_name, last_name, phone, hire_date, mentor_id, level_id)
VALUES ('Emma', 'Johnson', '0413000111', '2020-01-15', NULL, 3),
       ('David', 'Brown', '0413000222', '2021-03-20', NULL, 3),
       ('Sophia', 'Wilson', '0413000333', '2022-05-10', 1, 2),
       ('Liam', 'Miller', '0413000444', '2023-02-18', 2, 2),
	   ('Olivia', 'Davis', '0413000555', '2022-06-25', NULL, 3),
	   ('Noah', 'Taylor', '0413000666', '2022-01-09', NULL, 3),
	   ('Ava', 'Anderson', '0413000777', '2024-03-12', 3, 2),
	   ('Ethan', 'Thomas', '0413000888', '2024-05-22', 4, 2),
	   ('Mia', 'Jackson', '0413000999', '2024-08-05', 5, 1),
	   ('Lucas', 'White', '0413000100', '2024-09-15', 6, 1),
	   ('Jared', 'Dins', '0416786458', '2024-04-15', 10, 1),
	   ('Robin', 'Hael', '0418050124', '2025-03-24', NULL, 2);


PRINT 'Populating jobStatus table.'

INSERT INTO jobStatus (status_name)
VALUES	('Unresolved'),
		('Pending (Customer)'),
		('Pending (External)'),
		('Resolved');



PRINT 'Populating supportJob table.'

INSERT INTO supportJob (customer_id, staff_id, job_datetime, problem_summary, resolution_datetime, resolved_ByStaff_id, status_id)
VALUES (1, 3, '2025-10-01 09:15', 'Internet connection dropping frequently.', '2025-10-01 14:00', 4, 4),
       (2, 4, '2025-10-02 10:00', 'Slow upload speed reported by customer.', NULL, NULL, 1),
       (3, 5, '2025-10-02 11:30', 'Customer cannot log into account portal.', '2025-10-02 13:00', 5, 4),
       (4, 6, '2025-10-03 08:45', 'Frequent disconnections since storm.', NULL, NULL, 2),
       (5, 7, '2025-10-03 15:20', 'Billing error – charged twice for same month.', NULL, NULL, 3),
       (6, 8, '2025-10-04 09:00', 'Router replacement request.', '2025-10-04 12:30', 8, 4),
       (7, 9, '2025-10-05 10:45', 'Speed not matching plan specification.', NULL, NULL, 1),
       (8, 10, '2025-10-06 11:15', 'Unable to reset password via website.', '2025-10-06 13:15', 6, 4),
       (9, 4, '2025-10-05 14:25', 'Dropouts every evening around 7 PM.', '2025-10-06 12:35' , 10, 2),
       (10, 5, '2025-10-08 16:40', 'Customer modem light blinking red.', NULL, NULL, 1),
	   (11, 9, '2025-10-09 11:15', 'Wi-Fi signal dropouts at customer home router.', NULL, NULL, 4);

PRINT 'Populating note table.'

INSERT INTO note (note_DateTime, note_content, job_id, staff_id)
VALUES ('2025-10-01 10:05', 'Explained how to reboot modem and check cables.',                          1, 3),
       ('2025-10-01 10:40', 'Customer reports intermittent dropouts; advised isolation test.',          1, 3),
	   ('2025-10-01 11:00', 'Advised to replace line splitter; awaiting confirmation.',                 1, 3),
	   ('2025-10-06 11:20', 'Guided customer through password reset process.',                          8, 10),
	   ('2025-10-06 12:10', 'Customer confirmed successful login; monitoring.',                         8, 10),
       ('2025-10-03 09:00', 'Ticket pending customer to provide modem logs; follow-up in 48 hours.',    4, 6),
       ('2025-10-03 15:30', 'Raised with billing to reverse duplicated charge for October invoice.',    5, 7),
       ('2025-10-04 10:00', 'Replaced router; post-change speed test within plan spec; closing soon.',  6, 8),
	   ('2025-10-05 15:00', 'Customer reports evening dropouts; advised to check for interference sources.', 9, 4),
       ('2025-10-06 11:50', 'Confirmed issue persists; escalated to senior technician for line inspection.', 9, 10);