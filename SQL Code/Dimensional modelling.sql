-- Dimensional modelling schema,

CREATE TABLE Location_dim (
  Location_id SERIAL PRIMARY KEY,
  city varchar(255),
  state varchar(255),
  country varchar(255)
);

insert into location_dim(city,state,country)
select c.city,s.state,cn.country from address a 
join city c on a.city_id = c.city_id
join state s on s.state_id = a.state_id
join country cn on cn.country_id = a.country_id

CREATE TABLE company_dim (
  company_id SERIAL PRIMARY KEY,
  company_name varchar(255)
);

CREATE TABLE date_dim (
    date_id SERIAL PRIMARY KEY,
    date TIMESTAMP,
    day VARCHAR(10),
    month VARCHAR(10),
    year INT
);

INSERT INTO date_dim(date, day, month, year)
SELECT
    DISTINCT posted_date as date,
    TO_CHAR(posted_date, 'Day') AS day,
    TO_CHAR(posted_date, 'Month') AS month,
    EXTRACT(YEAR FROM posted_date) AS year
FROM job;


CREATE TABLE Company_growth_fact(
  Company_growth_id SERIAL PRIMARY KEY,
  Company_id INT NOT NULL,
  Location_id INT NOT NULL,
  job_growth_percentage numeric,
  current_job_openings int,
  previous_job_openings int,
  FOREIGN KEY (Company_id) REFERENCES  Company_dim(Company_id),
  FOREIGN KEY (Location_id) REFERENCES Location_dim(Location_id)
);

WITH job_listings_by_period AS (
  SELECT
    cb.company_id, cb.address_id,EXTRACT(MONTH FROM posted_date) AS month,
    EXTRACT(YEAR FROM posted_date) AS year, COUNT(*) AS job_count
  FROM
    job j
	join company_branch cb on j.company_branch_id = cb.company_branch_id
  GROUP BY
    cb.company_id,
	cb.address_id,
    EXTRACT(MONTH FROM posted_date),
    EXTRACT(YEAR FROM posted_date)
),
job_growth AS (
  SELECT
    current_period.company_id,
	current_period.address_id,
    current_period.year,
    current_period.month,
    current_period.job_count AS current_job_openings,
    previous_period.job_count AS previous_job_openings,
    ((current_period.job_count - previous_period.job_count) * 1.0 / previous_period.job_count) * 100 AS job_growth_percentage
  FROM
    job_listings_by_period AS current_period
  JOIN
    job_listings_by_period AS previous_period ON (
      (current_period.company_id = previous_period.company_id) AND
	  (current_period.address_id = previous_period.address_id) AND
      (current_period.year - 1 = previous_period.year OR
      (current_period.year = previous_period.year AND current_period.month - 1 = previous_period.month))
    )
)
insert into company_growth_fact(Company_id,Location_id,year,month,
job_growth_percentage,current_job_openings,previous_job_openings)
SELECT
  cd.company_id,
  ld.location_id,
  year,
  month,
  round(job_growth_percentage) as job_growth_percentage,
  current_job_openings,
  previous_job_openings
FROM
  job_growth j
  join company_dim cd on cd.company_id = j.company_id 
  join location_dim ld on ld.location_id = j.address_id
ORDER BY
  job_growth_percentage DESC;


CREATE TABLE Education_dim (
  education_id SERIAL PRIMARY KEY,
  degree varchar(25),
  field varchar(100)
);

INSERT INTO education_dim(degree, field)
SELECT d.degree,f.field from 
education e join education_degree d on d.degree_id = e.degree_id
join education_field f on f.field_id = e.field_id

CREATE TABLE job_title_dim (
  job_title_id SERIAL PRIMARY KEY,
  job_title varchar(100)
);

INSERT INTO job_title_dim(job_title)
select job_title from job_title

CREATE TABLE job_title_analysis_fact (
  job_title_analysis_id SERIAL PRIMARY KEY,
  Job_title_id INT NOT NULL,
  Location_id INT NOT NULL,
  education_id INT NOT NULL,
  preferred_experience_level varchar(50),
  years_experience_required int,
  average_minimum_salary int,
  average_maximum_salary int,
  minimum_salary int,
  maximum_salary int,
  preferred_location_type varchar(50),
  preferred_employment_type varchar(50),
  total_job_postings int,
  FOREIGN KEY (Job_title_id) REFERENCES  Job_title_dim(Job_title_id),
  FOREIGN KEY (Location_id) REFERENCES Location_dim(Location_id),
  FOREIGN KEY (education_id) REFERENCES education_dim(education_id)
);

WITH degree_cte AS (
    SELECT job_title_id,address_id,education_id,COUNT(education_id) AS degree_count
    FROM job j
    JOIN company_branch cb ON cb.company_branch_id = j.company_branch_id
    GROUP BY
        job_title_id, address_id, education_id
),
experience_level_cte AS (
    SELECT job_title_id,address_id,experience_level_id,COUNT(experience_level_id) AS experience_count
    FROM job j
    JOIN company_branch cb ON cb.company_branch_id = j.company_branch_id
    GROUP BY
        job_title_id, address_id, experience_level_id
),
location_type_cte AS (
    SELECT job_title_id,address_id,location_type_id,COUNT(location_type_id) AS location_count
    FROM job j
    JOIN company_branch cb ON cb.company_branch_id = j.company_branch_id
    GROUP BY
        job_title_id, address_id, location_type_id
),
employment_type_cte AS (
    SELECT job_title_id,address_id,employment_type_id,COUNT(employment_type_id) AS employment_count
    FROM job j
    JOIN company_branch cb ON cb.company_branch_id = j.company_branch_id
    GROUP BY
        job_title_id, address_id, employment_type_id
),
preferred_degree AS (
    SELECT job_title_id,address_id,education_id,
    ROW_NUMBER() OVER(PARTITION BY job_title_id, address_id ORDER BY degree_count DESC) AS degree_rank
    FROM degree_cte
),
preferred_experience_level AS (
    SELECT job_title_id,address_id,experience_level_id,
    ROW_NUMBER() OVER(PARTITION BY job_title_id, address_id ORDER BY experience_count DESC) AS experience_rank
    FROM experience_level_cte
),
preferred_location_type AS (
    SELECT job_title_id,address_id,location_type_id,
    ROW_NUMBER() OVER(PARTITION BY job_title_id, address_id ORDER BY location_count DESC) AS location_rank
    FROM location_type_cte
),
preferred_employment_type AS (
    SELECT job_title_id,address_id,employment_type_id,
    ROW_NUMBER() OVER(PARTITION BY job_title_id, address_id ORDER BY employment_count DESC) AS employment_rank
    FROM employment_type_cte
)
insert into job_title_analysis_fact(Job_title_id,Location_id,education_id,preferred_experience_level,
years_experience_required,average_minimum_salary,average_maximum_salary,minimum_salary,maximum_salary,
preferred_location_type,preferred_employment_type,total_job_postings)
SELECT 
    j.job_title_id,
    cb.address_id,
    pd.education_id AS preferred_field,
	el.experience_level AS preferred_experience_level,
	round(AVG(j.months_experience)/12) AS years_experience_required,
	round(AVG(j.salary_min)) AS avg_salary_min,
    round(AVG(j.salary_max)) AS avg_salary_max,
	round(MIN(j.salary_min)) AS salary_min,
    round(MAX(j.salary_max)) AS salary_max,
    plt.location_type_id AS preferred_location_type,
    pet.employment_type_id AS preferred_employment_type,
    COUNT(*) AS total_job_postings
FROM
    job j
JOIN
    company_branch cb ON cb.company_branch_id = j.company_branch_id
JOIN
    experience_level el on el.experience_level_id = j.experience_level_id
JOIN
    preferred_degree pd ON j.job_title_id = pd.job_title_id AND cb.address_id = pd.address_id AND pd.degree_rank = 1
JOIN
    preferred_experience_level pel ON j.job_title_id = pel.job_title_id AND cb.address_id = pel.address_id AND pel.experience_rank = 1
JOIN
    preferred_location_type plt ON j.job_title_id = plt.job_title_id AND cb.address_id = plt.address_id AND plt.location_rank = 1
JOIN
    preferred_employment_type pet ON j.job_title_id = pet.job_title_id AND cb.address_id = pet.address_id AND pet.employment_rank = 1
GROUP BY
    j.job_title_id, cb.address_id, pd.education_id, el.experience_level, plt.location_type_id, pet.employment_type_id;

CREATE TABLE Member_dim (
  Member_id SERIAL PRIMARY KEY,
  first_name varchar(50),
  last_name varchar(50),
  account_created_date date,
  account_created_time time
);

CREATE TABLE Employee_fact (
  Employee_id serial Primary Key,
  Member_id int not null,
  Company_id int not null,
  Job_title_id int not null,
  year_started int,
  month_started varchar(25),
  current_job varchar(25)
);

INSERT INTO employee_fact (member_id, company_id, job_title_id, year_started, month_started, current_job)
SELECT
    member_id,
    company_id,
    job_title_id,
    CAST(start_year AS INTEGER),
    month,
    current_position
FROM member_job;

CREATE TABLE job_dim 
(
    dim_job_id SERIAL PRIMARY KEY,
    job_id INT,
    job_title VARCHAR(100),
    company_name VARCHAR(100),
    experience_level VARCHAR(50),
    months_experience_required numeric,
    salary_type VARCHAR(25),
    minimum_pay NUMERIC,
    maximum_pay NUMERIC,
    location_type varchar(50),
    current_flag varchar(2) default 'Y',
    last_modifiedon TIMESTAMP,
    createdon TIMESTAMP,
    expiredon TIMESTAMP DEFAULT '1990-01-01 00:00:00'
);

insert into job_dim(job_id,job_title,company_name,experience_level,salary_type,minimum_pay,
maximum_pay)
select job_id,jt.job_title,c.company_name,e.experience_level,s.salary_type,j.salary_min,
j.salary_max
from job j
join job_title jt on j.job_title_id = jt.job_title_id
join company_branch cb on cb.company_branch_id = j.company_branch_id
join company c on c.company_id = cb.company_id
join experience_level e on e.experience_level_id = j.experience_level_id
join salary_type s on s.salary_type_id = j.salary_type_id

CREATE TABLE job_attributes_fact(
  job_attributes_id SERIAL PRIMARY KEY,
  dim_job_id INT NOT NULL,
  Location_id INT NOT NULL,
  date_id INT NOT NULL,
  Company_id INT NOT NULL,
  years_experience_required numeric,
  experience_level varchar(50),
  degree varchar(50),
  field varchar(50),
  Minimum_salary int,
  Maximum_salary int,
  FOREIGN KEY (Company_id) REFERENCES  Company_dim(Company_id),
  FOREIGN KEY (Location_id) REFERENCES Location_dim(Location_id),
  FOREIGN KEY (dim_job_id) REFERENCES  job_dim(dim_job_id),
  FOREIGN KEY (date_id) REFERENCES  date_dim(date_id)
);

insert into job_attributes_fact(dim_job_id,location_id,date_id,Company_id,years_experience_required,
experience_level,degree,field, Minimum_salary,Maximum_salary)
select dim_job_id,l.location_id,d.date_id,c.company_id,round(months_experience_required/12) as years_experience_required,experience_level,
e.degree,e.field,j.salary_min,j.salary_max
from job_dim jd
join job j on jd.job_id=j.job_id
join company_branch cb on cb.company_branch_id = j.company_branch_id
join company_dim c on c.company_id = cb.company_id
join location_dim l on l.location_id = cb.address_id
join education_dim e on e.education_id = j.education_id
join date_dim d on d.date = j.posted_date