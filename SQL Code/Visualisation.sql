-- Visualisation,

CREATE MATERIALIZED VIEW company_growth_mv AS
SELECT
  cg.company_growth_id,
  cd.company_name,
  ld.city,
  ld.state,
  ld.country,
  cg.year,
  month,
  cg.job_growth_percentage,
  cg.current_job_openings,
  cg.previous_job_openings
FROM
  company_growth_fact cg
  JOIN company_dim cd ON cg.company_id = cd.company_id
  JOIN location_dim ld ON ld.location_id = cg.location_id;

CREATE MATERIALIZED VIEW job_title_analysis AS
SELECT
  job_title,
  city,
  state,
  country,
  degree,
  field,
  preferred_experience_level,
  years_experience_required,
  average_minimum_salary,
  average_maximum_salary,
  minimum_salary,
  maximum_salary,
  location_type,
  employment_type,
  total_job_postings
FROM
  job_title_analysis_fact jt
  JOIN job_title_dim jd ON jd.job_title_id = jt.job_title_id
  JOIN location_dim ld ON ld.location_id = jt.location_id
  JOIN education_dim e ON e.education_id = jt.education_id
  JOIN location_type lt ON jt.preferred_location_type::integer = lt.location_type_id
  JOIN employment_type et ON jt.preferred_employment_type::integer = et.employment_type_id;

-- Visualisation,

CREATE MATERIALIZED VIEW company_growth_mv AS
SELECT
  cg.company_growth_id,
  cd.company_name,
  ld.city,
  ld.state,
  ld.country,
  cg.year,
  month,
  cg.job_growth_percentage,
  cg.current_job_openings,
  cg.previous_job_openings
FROM
  company_growth_fact cg
  JOIN company_dim cd ON cg.company_id = cd.company_id
  JOIN location_dim ld ON ld.location_id = cg.location_id;


CREATE MATERIALIZED VIEW job_title_analysis AS
SELECT
  job_title,
  city,
  state,
  country,
  degree,
  field,
  preferred_experience_level,
  years_experience_required,
  average_minimum_salary,
  average_maximum_salary,
  minimum_salary,
  maximum_salary,
  location_type,
  employment_type,
  total_job_postings
FROM
  job_title_analysis_fact jt
  JOIN job_title_dim jd ON jd.job_title_id = jt.job_title_id
  JOIN location_dim ld ON ld.location_id = jt.location_id
  JOIN education_dim e ON e.education_id = jt.education_id
  JOIN location_type lt ON jt.preferred_location_type::integer = lt.location_type_id
  JOIN employment_type et ON jt.preferred_employment_type::integer = et.employment_type_id;

