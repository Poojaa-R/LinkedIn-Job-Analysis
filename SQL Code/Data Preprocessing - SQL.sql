--Data preprocessing in SQL,

UPDATE stg_job_listings_da SET state = COALESCE(state, 'Unknown');
UPDATE stg_job_listings SET state = COALESCE(state, 'Unknown');
UPDATE stg_profileinfo SET state = COALESCE(state, 'Unknown');


UPDATE stg_job_listings SET city = COALESCE(city, 'Unknown');
UPDATE stg_job_listings_da SET city = COALESCE(city, 'Unknown');
UPDATE stg_profileinfo SET city = COALESCE(city, 'Unknown');


--Cleaning address field

update stg_job_listings set city = split_part(city, '-', 1) 
where city like '%-%';

update stg_job_listings_da set city = split_part(city, '-', 1) 
where city like '%-%';

update stg_profileinfo set city = split_part(city, '-', 1) 
where city like '%-%';

UPDATE stg_job_listings
SET city = replace(city, 'Metropolitan Area', '')
WHERE city LIKE '%Metropolitan Area%';

-- Update the stg_job_listings_da table
UPDATE stg_job_listings_da
SET city = replace(city, 'Metropolitan Area', '')
WHERE city LIKE '%Metropolitan Area%';

-- Update the stg_profileinfo table
UPDATE stg_profileinfo
SET city = replace(city, 'Metropolitan Area', '')
WHERE city LIKE '%Metropolitan Area%';

-- Update the stg_job_listings table
UPDATE stg_job_listings
SET city = replace(city, 'City', '')
WHERE city LIKE '%City%';

-- Update the stg_job_listings_da table
UPDATE stg_job_listings_da
SET city = replace(city, 'City', '')
WHERE city LIKE '%City%';

-- Update the stg_profileinfo table
UPDATE stg_profileinfo
SET city = replace(city, 'City', '')
WHERE city LIKE '%City%';

UPDATE stg_job_listings_da
SET city = REPLACE(city, 'Metro', '')
WHERE city LIKE '%Metro%';

UPDATE stg_job_listings
SET city = REPLACE(city, ' Area', '')
WHERE city LIKE '% Area%';

UPDATE stg_job_listings
SET city = REPLACE(city, 'County', '')
WHERE city LIKE '%County%';

--Removing white spaces from the staging table,

UPDATE stg_job_listings_da SET
    title = TRIM(title),
	company = TRIM(company),
	onsite_remote = TRIM(onsite_remote),
	seniority_level = TRIM(seniority_level),
	employment_type = TRIM(employment_type),
	job_function = TRIM(job_function),
	salary_type = TRIM(salary_type),
	city = TRIM(city),
	state = TRIM(state),
	country = TRIM(country)

UPDATE stg_job_listings SET
	employment_type = TRIM(employment_type),
	job_function = TRIM(job_function),
	seniority_level = TRIM(seniority_level),
	company = TRIM(company),
	education = TRIM(company),
    title = TRIM(title),
	salary_type = TRIM(salary_type),
	city = TRIM(city),
	state = TRIM(state),
	country = TRIM(country)

UPDATE stg_profileinfo SET
	first_name = TRIM(first_name),
	last_name = TRIM(last_name),
	full_name = TRIM(full_name),
	job_title = TRIM(job_title),
	company_name = TRIM(company_name),
            new_job = TRIM(new_job),
	year_started = TRIM(year_started),
	school = TRIM(school),
	education_start = TRIM(education_end),
	field = TRIM(field),
	domain = TRIM(domain),
	created_date = TRIM(created_date),
	city = TRIM(city),
	state = TRIM(state),
	country = TRIM(country),
	degree_1 = TRIM(degree_1),
	degree_2 = TRIM(degree_2)