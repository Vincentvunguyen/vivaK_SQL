USE hr;

# CHECK IF THERE IS ANY NULL/missing values OR DUPLICTE employee_id
SELECT * FROM employees
WHERE employee_id IS NULL OR employee_id = '' OR email IS NULL OR email = ''
	OR phone_number ='' OR phone_number IS NULL OR job_id IS NULL OR job_id = ''
    OR salary IS NULL OR salary = '' OR hire_date IS NULL OR hire_date = '';
-- There are some missing values in salary and phone_number column

# CHECK IF THERE IS ANY DUPLICTE employee_id
SELECT employee_id, COUNT(employee_id) as count
FROM employees
GROUP BY employee_id
HAVING count > 1;
-- There is no null or duplicate employee_id, asume that there is no employee more than 1 employee_id

# Check number of employees with salary = 0
SELECT count(employee_id)
FROM employees
WHERE salary = 0;

# Check if ANY NULL in dependent
SELECT employee_id, first_name, last_name
FROM dependent
WHERE employee_id = '' OR employee_id IS NULL;
-- There is no missing employee_value in dependent tab

# Check if any DUPLICATES in dependent
SELECT dependent_id, COUNT(dependent_id) as count
FROM dependent
GROUP BY dependent_id
HAVING count > 1;
-- There is a lot of duplicate in dependent_id 

# Compare table dependents and employees
SELECT COUNT(DISTINCT employee_id) FROM dependent
	WHERE employee_id NOT IN (SELECT employee_id FROM employees);
    
-- There are 62 employee_id in dependent dont have records in employees table, 
-- they will be considered as ex_employees

-- HANDLE NULL VALUES IN LOCATION TABLE
UPDATE locations
SET state_province = 'London'
WHERE state_province IS NULL;

UPDATE locations
SET postal_code = 'LD1 01A'
WHERE postal_code IS NULL;

-- IDENTIFY THE RIGHT LOCATION FOR EMPLOYEES
-- Data designer made an error and called the “location_id” column in employees data “department_id”.
-- We dont know which department_id belong to location_id
-- But in the each location table, there are some employees name, 
-- Solution: match those employees name in location table to the name in employees => match the “location_id” and “department_id”

-- Create Full_Name column and Insert values
ALTER TABLE employees
	ADD COLUMN Full_Name VARCHAR(255);
UPDATE employees AS e1
	JOIN employees AS e2 ON e1.employee_id = e2.employee_id
	SET e1.Full_Name = CONCAT(e2.first_name, ' ', e2.last_name);

-- CREATE location_id and INSERT values
ALTER TABLE employees
	ADD COLUMN location_id INT;

-- Identify the location_id and  department_id by filling some sample employees in each location
UPDATE employees AS e
	SET location_id = 
		(CASE WHEN e.Full_Name IN (SELECT `Full Name` FROM location_1400_ho) THEN 1400
			WHEN e.Full_Name IN (SELECT `Full Name` FROM location_1500) THEN 1500
            WHEN e.Full_Name IN (SELECT `Full Name` FROM location_1700) THEN 1700
            WHEN e.Full_Name IN (SELECT `Full Name` FROM location_1800) THEN 1800
            WHEN e.Full_Name IN (SELECT `Full Name` FROM location_1900) THEN 1900
            WHEN e.Full_Name IN (SELECT `Full Name` FROM location_2500) THEN 2500
            WHEN e.Full_Name IN (SELECT `Full Name` FROM location_2700) THEN 2700
            ELSE NULL
            END);
            
-- It is able to identify that department_id 1 = location_id 1400, department_id 2 = location_id 1500,...
SELECT DISTINCT department_id, location_id
	FROM employees;
    
-- Update location_id for the rest of employees
UPDATE employees AS e
	SET location_id = 
		(CASE WHEN department_id = 1 THEN 1400
			WHEN department_id = 2 THEN 1500
            WHEN department_id = 3 THEN 1700
            WHEN department_id = 4 THEN 1800
            WHEN department_id = 5 THEN 1900
            WHEN  department_id = 6 THEN 2500
            WHEN  department_id = 7 THEN 2700
            ELSE NULL
            END);
            
-- HANDLE MISSING VALUES IN Manager_id column
ALTER TABLE employees
	ADD temp_report_to INT;

UPDATE IGNORE employees e
	JOIN orgstructure_v2 o ON e.job_id = o.ï»¿job_id
    SET e.temp_report_to = o.Reports_to;
    
-- UPDATE manager_id INTO employees
UPDATE employees e1
	JOIN employees e2 ON (e1.temp_report_to = e2.job_id AND e1.location_id = e2.location_id)
	SET e1.manager_id = e2.employee_id;
-- There is still some missing in manager_id for employees, 
-- which have job_id in (1,2,3) since there is only 1 job_id =1, and this job_id exist only in location 1400
-- UPDATE the missing values 

UPDATE employees 
	SET manager_id = 100
    WHERE manager_id IS NULL AND employee_id != 100;
    
-- HANDLING department_id
SELECT ï»¿department_id, department_name, GROUP_CONCAT(o.ï»¿job_id SEPARATOR ', ') FROM hr.departments
	LEFT JOIN orgstructure_v2 o USING (department_name)
    GROUP BY ï»¿department_id, department_name;

UPDATE employees e
	JOIN orgstructure_v2 o ON e.job_id = o.ï»¿job_id
    JOIN departments d ON d.department_name = o.department_name
    SET e.department_id = d.ï»¿department_id;
        
### UPDATE SALARY
# The employees, with salary = 0, will receive salary = average salary of all the employees 
# who have the same job_id and work in the same location.
UPDATE employees e1
	JOIN (SELECT e2.job_id, e2.location_id, AVG(e2.salary) as avg_salary
			FROM employees e2
            WHERE e2.salary > 0 # filter out salary = 0
			GROUP BY e2.job_id, e2.location_id) temp1
	ON e1.job_id = temp1.job_id AND e1.location_id = temp1.location_id
	SET e1.salary = temp1.avg_salary
    WHERE salary = 0;

# If there is no other employee in the same location have same job_id, 
# the salary = average salary of the job_id within the company.
UPDATE employees e1
	JOIN (SELECT e2.job_id, AVG(e2.salary) as avg_salary
			FROM employees e2
            WHERE e2.salary > 0 # filter out salary = 0
			GROUP BY e2.job_id) temp2
	ON e1.job_id = temp2.job_id 
	SET e1.salary = temp2.avg_salary
    WHERE salary = 0;

# Double check if there is any salary = 0
SELECT job_id, count(employee_id)
FROM employees
WHERE salary = 0
Group by job_id;

-- Modify the format of phone number to '+000-000-000-0000'

UPDATE employees
	SET phone_number = REPLACE(phone_number, '.', '-'); # Replace '.' by '-'
    
UPDATE employees
	SET phone_number = (
		CASE WHEN location_id IN (SELECT location_id FROM locations WHERE country_id = 'US') 
				THEN CONCAT('+001-',phone_number) # country code of US 
			WHEN location_id IN (SELECT location_id FROM locations WHERE country_id = 'CA') 
				THEN CONCAT('+002-',phone_number) # country code of Canada
			WHEN location_id IN (SELECT location_id FROM locations WHERE country_id = 'UK') 
				THEN CONCAT('+003-',phone_number) # Country code of UK
            ELSE CONCAT('+004-',phone_number) # country code of Denmark
			END);

-- MODIFY TYPE FOR VALUES
ALTER TABLE employees
	MODIFY salary DOUBLE(10,2),
    MODIFY hire_date DATE;
    
############################### CREATE FINAL DATABASE #######################################
CREATE SCHEMA IF NOT EXISTS vivak_data;

USE vivak_Data;

DROP TABLE IF EXISTS regions;
CREATE TABLE IF NOT EXISTS regions (
	region_id INT NOT NULL,
    region_name VARCHAR(150),
    
     CONSTRAINT rg_pk PRIMARY KEY (region_id)
 );
 
 DROP TABLE IF EXISTS countries;
 CREATE TABLE IF NOT EXISTS countries (
	country_id VARCHAR(2),
    country_name VARCHAR(150),
    region_id INT,
    
    CONSTRAINT ct_pk PRIMARY KEY (country_id),
    CONSTRAINT rg_fk FOREIGN KEY(region_id)
		REFERENCES regions (region_id)
        ON UPDATE CASCADE 
		ON DELETE SET NULL
 );
 
DROP TABLE IF EXISTS locations;
 CREATE TABLE IF NOT EXISTS locations(
	location_code INT,
    address VARCHAR(255) NOT NULL,
    postal_code VARCHAR(12),
    city VARCHAR (150),
    state_province VARCHAR(255),
    country_id VARCHAR(2),
    
    CONSTRAINT lc_pk PRIMARY KEY (location_code),
	CONSTRAINT ct_fk FOREIGN KEY(country_id)
		REFERENCES countries (country_id)
        ON UPDATE CASCADE 
		ON DELETE SET NULL
    );

DROP TABLE IF EXISTS departments;
CREATE TABLE IF NOT EXISTS departments(
	department_id INT,
    department_name VARCHAR(150),
    
    CONSTRAINT dp_pk PRIMARY KEY (department_id)
    );

DROP TABLE IF EXISTS org_structure;
CREATE TABLE IF NOT EXISTS org_structure (
	job_id INT,
    job_title VARCHAR(150),
    min_salary DOUBLE(12,2),
    max_salary DOUBLE(12,2),
    department_id INT,
    department_name VARCHAR(150),
    report_to INT DEFAULT NULL,
    
    CONSTRAINT rg_pk PRIMARY KEY (job_id),
    CONSTRAINT dp_fk FOREIGN KEY(department_id)
		REFERENCES departments (department_id)
        ON UPDATE CASCADE 
		ON DELETE SET NULL 
    );

DROP TABLE IF EXISTS employees;
CREATE TABLE IF NOT EXISTS employees (
	employee_id INT AUTO_INCREMENT, 
	first_name VARCHAR(150) NOT NULL,
    last_name VARCHAR(150) NOT NULL,    
	email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(17) UNIQUE DEFAULT NULL,
	job_id INT NOT NULL,
	salary DOUBLE (12,2),
    manager_id INT,
	department_id INT,     
	hire_date DATE,
    experience_at_VivaK_in_month INT,
    last_performent_rating DECIMAL(3,2),
    salary_after_increment DOUBLE (12,2),
    annual_dependent_benefit DOUBLE(12,2) DEFAULT 0, # If an employee doesn't have any dependent, the benefit is 0
    location_code INT(4) NOT NULL,
	
	CONSTRAINT emp_pk PRIMARY KEY (employee_id),
    CONSTRAINT lc_fk FOREIGN KEY(location_code)
		REFERENCES locations(location_code)
        ON UPDATE CASCADE 
		ON DELETE CASCADE,
	CONSTRAINT jb_fk FOREIGN KEY(job_id)
		REFERENCES org_structure(job_id)
        ON UPDATE CASCADE 
		ON DELETE CASCADE
);

DROP TABLE IF EXISTS dependents;
 CREATE TABLE IF NOT EXISTS dependents(
	dependent_id INT AUTO_INCREMENT,
    first_name VARCHAR(150) NOT NULL,
    last_name VARCHAR(150) NOT NULL,
    relationship VARCHAR(150) NOT NULL,
    employee_id INT,
    
    CONSTRAINT dp_pk PRIMARY KEY (dependent_id),
    CONSTRAINT emp_dp_fk FOREIGN KEY (employee_id)
		REFERENCES employees (employee_id)
		ON UPDATE CASCADE # if we change the ID of an employee, it will be updated too
		ON DELETE CASCADE # if an employee no longer work at the company, the dependent also be deleted
        );

USE vivak_data;

########################### INSERT VALUES TO THE FINAL DATABASE ######################################
INSERT INTO regions(region_id, region_name)
	SELECT region_id, region_name
    FROM hr.regions;
    
INSERT INTO countries(country_id, country_name, region_id)
	SELECT country_id, country_name, region_id
    FROM hr.countries;
    
INSERT INTO locations(location_code,address,postal_code,city,state_province,country_id)
	SELECT location_id,street_address,postal_code,city,state_province,country_id
    FROM hr.locations;
    
INSERT INTO departments(department_id,department_name)
	SELECT ï»¿department_id, department_name
    FROM hr.departments;
    
INSERT IGNORE INTO org_structure(job_id,job_title,min_salary,max_salary,department_id,department_name,report_to)
	SELECT os.ï»¿job_id,os.job_title,os.min_salary,os.max_salary,
		dp.ï»¿department_id,os.department_name,os.Reports_to
    FROM hr.orgstructure_v2 os
    JOIN hr.departments dp USING(department_name);
    
INSERT IGNORE INTO employees(employee_id, first_name, last_name, email, phone, job_id, salary,
						manager_id, department_id, hire_date, location_code)
	SELECT employee_id, first_name, last_name, email, phone_number, job_id, salary, manager_id,
			department_id, hire_date, location_id
	FROM hr.employees;

INSERT INTO dependents(first_name,last_name,relationship,employee_id)
	SELECT d.first_name,d.last_name,d.relationship,d.employee_id
    FROM hr.dependent d
    WHERE d.employee_id IN (SELECT e.employee_id FROM vivak_data.employees e);
-- The AUTO_INCREMENT will create new IDs for all the dependents, there will be no duplicated dependent_id

### CALCULATION AND UPDATE VALUES
UPDATE employees
	SET experience_at_VivaK_in_month = TIMESTAMPDIFF(MONTH, hire_date, CURDATE());
    
# last_performent_rating: Generate a random performance rating figure (a decimal number with two decimal points between 0 and 10) 
# for each employee and update the column.
UPDATE employees
	SET last_performent_rating = ROUND(RAND(),2);

# salary_after_increment: calculate the salary after the performance appraisal 
# and update the column by using the following formulas:
UPDATE employees
	SET salary_after_increment = 
		salary * (1+(0.01*experience_at_VivaK_in_month)+(CASE
        WHEN last_performent_rating >=0.9 THEN 0.15
        WHEN last_performent_rating >=0.8 THEN 0.12
        WHEN last_performent_rating >=0.7 THEN 0.10
        WHEN last_performent_rating >=0.6 THEN 0.08
        WHEN last_performent_rating >=0.5 THEN 0.05
        ELSE 0.02 END)
        );
        
-- Adjust any salary_after_increment > max_salary to = max_salary, by creating a temporary max_salary column
ALTER TABLE employees
	ADD COLUMN max_salary DOUBLE(12,2);

UPDATE employees e
	JOIN org_structure o USING (job_id)
	SET e.max_salary = o.max_salary;
    
UPDATE employees
	SET salary_after_increment = (CASE
    WHEN salary_after_increment > max_salary THEN max_salary
    ELSE salary_after_increment END);
    
ALTER TABLE employees
	DROP max_salary; -- drop temporary column
    
### Update annual_dependent_benefit
UPDATE employees e
	SET annual_dependent_benefit = 12*e.salary 
    * (SELECT COUNT(d.dependent_id) as num FROM dependents d WHERE d.employee_id = e.employee_id) 
    # count number of dependent for each employee
    * (CASE WHEN e.job_id IN (SELECT job_id FROM org_structure WHERE job_title LIKE '%President') THEN 0.2 # Job_id of Executive are 1,2,3
        WHEN e.job_id IN (SELECT job_id FROM org_structure WHERE job_title LIKE '%Manager%') THEN 0.15 # Job_id of Managers are from 4 to 13
        ELSE 0.05 END);

# Replace employee email addressed to ‘<emailID>@vivaK.com’.
# emailID is the part of the current employee email before the @ sign.
UPDATE employees
SET email = CONCAT(SUBSTRING_INDEX(email, '@', 1), '@vivaK.com')
WHERE email LIKE '%@%';

SELECT * FROM vivak_data.employees;



    
    
    
    
    
    