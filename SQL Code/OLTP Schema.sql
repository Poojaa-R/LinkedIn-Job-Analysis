-- Normalised schema

CREATE TABLE employment_type (
  employment_type_id SERIAL PRIMARY KEY,
  employment_type VARCHAR(50),
);

INSERT INTO employment_type (employment_type)
SELECT employment_type
FROM (
  SELECT employment_type as employment_type FROM stg_job_listings_da
  UNION
  SELECT employment_type as employment_type FROM stg_job_listings
) AS der;

CREATE TABLE experience_level (
  experience_level_id SERIAL PRIMARY KEY,
  experience_level VARCHAR(255),
);

INSERT INTO experience_level (experience_level)
SELECT experience_level
FROM (
  SELECT seniority_level as experience_level FROM stg_job_listings_da
  UNION
  SELECT seniority_level as experience_level FROM stg_job_listings
) AS der;


INSERT INTO state (state)
SELECT DISTINCT state
FROM (
  SELECT state FROM stg_job_listings_da
  UNION
  SELECT state FROM stg_job_listings
  UNION
  SELECT state FROM stg_profileinfo
) AS der;


CREATE TABLE state (
  state_id SERIAL PRIMARY KEY,
  state VARCHAR(255),
);

CREATE TABLE experience_level (
  experience_level_id SERIAL PRIMARY KEY,
  experience_level VARCHAR(255),
  last_modifiedon TIMESTAMP,
  createdon TIMESTAMP,
  expiredon TIMESTAMP DEFAULT '1990-01-01 00:00:00'
);


INSERT INTO experience_level (experience_level)
SELECT seniority_level
FROM (
  SELECT seniority_level FROM stg_job_listings_da
  UNION
  SELECT seniority_level FROM stg_job_listings
) AS der;


CREATE TABLE location_type (
  location_type_id SERIAL PRIMARY KEY,
  location_type VARCHAR(255)
);

INSERT INTO location_type (location_type)
SELECT DISTINCT onsite_remote from stg_job_listings_da


INSERT INTO state (state)
SELECT state
FROM (
  SELECT state as state FROM stg_job_listings_da
  UNION
  SELECT state as state FROM stg_job_listings
  UNION
  SELECT state as state FROM stg_profileinfo
) AS der;



CREATE TABLE country (
  country_id SERIAL PRIMARY KEY,
  country VARCHAR(255),
);

INSERT INTO country (country)
SELECT country
FROM (
  SELECT country as country FROM stg_job_listings_da
  UNION
  SELECT country as country FROM stg_job_listings
  UNION
  SELECT country as country FROM stg_profileinfo
) AS der;

CREATE TABLE job_title (
  job_title_id SERIAL PRIMARY KEY,
  job_title VARCHAR(255),
);

INSERT INTO job_title (job_title)
SELECT job_title
FROM (
  SELECT title as job_title FROM stg_job_listings_da
  UNION
  SELECT title as job_title FROM stg_job_listings
  UNION
  SELECT job_title as job_title FROM stg_profileinfo
) AS der;

CREATE TABLE salary_type (
  salary_type_id SERIAL PRIMARY KEY,
  salary_type VARCHAR(255),
);

INSERT INTO salary_type (salary_type)
SELECT salary_type
FROM (
  SELECT salary_type as salary_type FROM stg_job_listings_da
  UNION
  SELECT salary_type as salary_type FROM stg_job_listings
) AS der;


CREATE TABLE city (
  city_id SERIAL PRIMARY KEY,
  city VARCHAR(255),
);

INSERT INTO city (city)
SELECT city
FROM (
  SELECT city FROM stg_job_listings_da
  UNION
  SELECT city FROM stg_job_listings
  UNION
  SELECT city FROM stg_profileinfo
) AS der;

CREATE TABLE address (
  address_id SERIAL PRIMARY KEY,
  state_id INT NOT NULL,
  city_id INT NOT NULL,
  country_id INT NOT NULL,
  FOREIGN KEY (state_id) REFERENCES state(state_id),
  FOREIGN KEY (city_id) REFERENCES city(city_id),
  FOREIGN KEY (country_id) REFERENCES country(country_id)
);

INSERT INTO address(state_id, city_id,country_id)
SELECT 
  (SELECT state_id FROM state WHERE state = s.state),
  (SELECT city_id FROM city WHERE city = s.city),
  (SELECT country_id FROM country WHERE country = s.country)
  FROM 
  (
  SELECT state, city ,country FROM stg_profileinfo
  UNION
  SELECT state, city ,country FROM stg_job_listings
  UNION
  SELECT state, city ,country FROM stg_job_listings_da
  ) AS s;

CREATE TABLE company (
  company_id SERIAL PRIMARY KEY,
  company_name VARCHAR(255),
);

INSERT INTO company (company_name)
SELECT company_name
FROM (
  SELECT company as company_name FROM stg_job_listings_da
  UNION
  SELECT company as company_name FROM stg_job_listings
  UNION
  SELECT company_name as company_name FROM stg_profileinfo
) AS der;


CREATE TABLE company_branch (
    company_branch_id SERIAL PRIMARY KEY,
    company_id INT,
    address_id INT,
  FOREIGN KEY (company_id) REFERENCES company(company_id),
  FOREIGN KEY (address_id) REFERENCES address(address_id)
);

WITH companies AS (
  SELECT company_name AS company_name, city, state, country
  FROM stg_profileinfo
  UNION
  SELECT company AS company_name, city, state, country
  FROM stg_job_listings
  UNION
  SELECT company AS company_name, city, state, country
  FROM stg_job_listings_da
)
INSERT INTO company_branch(company_id,address_id)
SELECT c.company_id, a.address_id
FROM companies s
INNER JOIN city ci ON s.city = ci.city
INNER JOIN state st ON s.state = st.state
INNER JOIN country co ON s.country = co.country
INNER JOIN address a ON ci.city_id = a.city_id AND st.state_id = a.state_id AND co.country_id = a.country_id
INNER JOIN company c ON s.company_name  = c.company_name

CREATE TABLE Member (
    Member_id INT PRIMARY KEY,
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    account_created_date VARCHAR(255),
    account_created_time VARCHAR(255),
    shared_connections INT,
    last_modifiedon TIMESTAMP,
    createdon TIMESTAMP,
    expiredon TIMESTAMP DEFAULT '1990-01-01 00:00:00'
);

INSERT INTO Member (member_id,first_name,last_name,account_created_date,account_created_time,shared_connections)
SELECT *
FROM (
  SELECT stg_profile_id,first_name,last_name,created_date as account_created_date,
	created_time as account_created_time,shared_connections FROM stg_profileinfo
) AS der;


CREATE TABLE Education 
(
    education_id SERIAL PRIMARY KEY,
    degree_id INT not null,
    field_id INT not null,
	FOREIGN KEY (degree_id) REFERENCES education_degree(degree_id),
	FOREIGN KEY (field_id) REFERENCES education_field(field_id)
);

SELECT t.degree_id, t.field_id
FROM (
    SELECT d.degree_id, f.field_id
    FROM stg_profileinfo s
    JOIN education_field f ON s.field = f.field
    JOIN education_degree d ON d.degree = s.degree_1
    UNION
    SELECT d.degree_id, f.field_id
    FROM stg_profileinfo s
    JOIN education_field f ON s.field = f.field
    JOIN education_degree d ON d.degree = s.degree_2
    UNION
    SELECT d.degree_id, f.field_id
    FROM stg_job_listings s
    JOIN education_field f ON s.field = f.field
    JOIN education_degree d ON d.degree = s.education
) AS t;

CREATE TABLE Member_education (
  Member_education_id SERIAL PRIMARY KEY,
  Member_id INT NOT NULL,
  Education_id INT NOT NULL,
  school_id INT NOT NULL,
  education_start_year VARCHAR(50),
  education_end_year VARCHAR(50),
  last_modifiedon TIMESTAMP,
  createdon TIMESTAMP,
  expiredon TIMESTAMP DEFAULT '1990-01-01 00:00:00',
  FOREIGN KEY (school_id) REFERENCES school(school_id),
  FOREIGN KEY (Member_id) REFERENCES Member(Member_id),
  FOREIGN KEY (Education_id) REFERENCES Education(Education_id)
);

WITH education_cte AS (
  SELECT 
    m.member_id, 
    d.degree_id, 
    f.field_id, 
    sc.school_id,
    s.education_start,
    s.education_end
  FROM stg_profileinfo s
  JOIN member m ON s.stg_profile_id = m.member_id
  JOIN education_degree d ON s.degree_1 = d.degree
  JOIN education_field f ON s.field = f.field
  JOIN school sc ON s.school = sc.school
UNION
 SELECT 
    m.member_id, 
    d.degree_id, 
    f.field_id, 
    sc.school_id,
    s.education_start,
    s.education_end
  FROM stg_profileinfo s
  JOIN member m ON s.stg_profile_id = m.member_id
  JOIN education_degree d ON s.degree_2 = d.degree
  JOIN education_field f ON s.field = f.field
  JOIN school sc ON s.school = sc.school
)
insert into member_education(member_id,education_id,school_id,education_start_year,education_end_year)
SELECT 
  ec.member_id,
  e.education_id,
  ec.school_id,
  ec.education_start AS education_start_year,
  ec.education_end AS education_end_year 
FROM education_cte ec
JOIN education e ON ec.degree_id = e.degree_id AND ec.field_id = e.field_id;


CREATE TABLE Education_degree (
    degree_id SERIAL PRIMARY KEY,
    degree VARCHAR(255),
);

INSERT INTO Education_degree (degree)
select degree from( SELECT s.degree_1 as degree
	FROM stg_profileinfo s
	UNION
	SELECT s.degree_2 as degree
	FROM stg_profileinfo s
	UNION
	SELECT education as degree 
	from stg_job_listings
) as der

CREATE TABLE school
(
    school_id SERIAL PRIMARY KEY,
    school varchar(255)
);
INSERT INTO school (school)
select distinct school from(
    SELECT school as school
	FROM stg_profileinfo 
) as der

CREATE TABLE job (
  job_id SERIAL PRIMARY KEY,
  company_branch_id INT NOT NULL,
  job_title_id INT NOT NULL,
  experience_level_id INT NOT NULL,
  employment_type_id INT NOT NULL,
  education_id INT NOT NULL,
  location_type_id INT NOT NULL,
  months_experience INT NOT NULL,
  posted_date TIMESTAMP,
  salary_min numeric,
  salary_max numeric,
  salary_type_id INT NOT NULL,
  last_modifiedon TIMESTAMP,
  createdon TIMESTAMP,
  expiredon TIMESTAMP DEFAULT '1990-01-01 00:00:00',
  FOREIGN KEY (company_branch_id) REFERENCES company_branch(company_branch_id),
  FOREIGN KEY (job_title_id) REFERENCES job_title(job_title_id),
  FOREIGN KEY (experience_level_id) REFERENCES experience_level(experience_level_id),
  FOREIGN KEY (employment_type_id) REFERENCES employment_type(employment_type_id),
  FOREIGN KEY (education_id) REFERENCES education(education_id),
  FOREIGN KEY (location_type_id) REFERENCES location_type(location_type_id),
  FOREIGN KEY (salary_type_id) REFERENCES salary_type(salary_type_id)
);

insert into job(company_branch_id,job_title_id,experience_level_id,employment_type_id,
education_id,location_type_id,months_experience,posted_date,salary_min,
salary_max,salary_type_id)
SELECT der.company_branch_id, j.job_title_id, exp.experience_level_id,
emp.employment_type_id, edu.education_id,lt.location_type_id,
der.months_experience, der.posted_date, der.salary_min, der.salary_max,st.salary_type_id
FROM (
    SELECT cb.company_branch_id, s.title, s.employment_type, s.seniority_level, s.salary_type,
    months_experience, date as posted_date, salary_min, salary_max, field, education, location_type
    FROM (
		(select employment_type, seniority_level, company, date, education, months_experience,
		 title, city, state, country, salary_min, salary_max, salary_type, field, 'Unknown' as location_type
		 from stg_job_listings)  union (select employment_type, seniority_level, company, 
		 CAST(posted_date AS TIMESTAMP) as date, 'Unknown' as education,
		0 as months_experience,title,city, state, country,salary_min, salary_max, salary_type,
		'Unknown' as field,
		 onsite_remote as location_type
		 from stg_job_listings_da)
		 )s
    JOIN company c ON c.company_name = s.company
    JOIN company_branch cb ON cb.company_id = c.company_id
    JOIN address a ON cb.address_id = a.address_id
    AND a.city_id IN (
        SELECT ct.city_id
        FROM city ct
        WHERE ct.city = s.city
    ) AND a.state_id IN (
        SELECT st.state_id
        FROM state st
        WHERE st.state = s.state
    ) AND a.country_id IN (
        SELECT ctr.country_id
        FROM country ctr
        WHERE ctr.country = s.country
    )
) AS der
JOIN job_title j ON der.title = j.job_title
JOIN employment_type emp ON der.employment_type = emp.employment_type
JOIN experience_level exp ON exp.experience_level = der.seniority_level
JOIN education edu ON edu.degree_id = 
(SELECT degree_id FROM education_degree WHERE degree = der.education)
AND edu.field_id = (SELECT field_id FROM education_field WHERE field = der.field)
JOIN location_type lt on lt.location_type = der.location_type
JOIN salary_type st on st.salary_type = der.salary_type;

CREATE TABLE Member_job (
  Member_job_id SERIAL PRIMARY KEY,
  Member_id INT NOT NULL,
  job_title_id INT NOT NULL,
 Company_id INT NOT NULL,
  start_year varchar(5),
  month VARCHAR(25),
  current_position varchar(10),
  last_modifiedon TIMESTAMP,
  createdon TIMESTAMP,
  expiredon TIMESTAMP DEFAULT '1990-01-01 00:00:00',
  FOREIGN KEY (Member_id) REFERENCES Member(Member_id),
  FOREIGN KEY (Company_id) REFERENCES Company(Company_id),
  FOREIGN KEY (job_title_id) REFERENCES job_title(job_title_id)
);

insert into member_job(member_id, job_title_id,start_year,month,current_position)
select member_id,j.job_title_id,year_started as start_year, month_started as month,
current_position
from stg_profileinfo s join
member m on m.member_id = s.stg_profile_id 
join job_title j on j.job_title = s.job_title