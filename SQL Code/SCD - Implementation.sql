--SCD Implementation,

CREATE OR REPLACE FUNCTION refresh_job_dim() RETURNS TRIGGER AS $$
BEGIN
    -- Create a temporary table with the new data
    CREATE TEMPORARY TABLE new_data AS (
        SELECT j.job_id, jt.job_title, c.company_name, e.experience_level, 
               j.months_experience AS months_experience_required,
               s.salary_type, j.salary_min AS minimum_pay, j.salary_max AS maximum_pay, lt.location_type,
               NOW() AS last_modifiedon, NOW() AS createdon
        FROM job j
        JOIN job_title jt ON j.job_title_id = jt.job_title_id
        JOIN company_branch cb ON cb.company_branch_id = j.company_branch_id
        JOIN company c ON c.company_id = cb.company_id
        JOIN experience_level e ON e.experience_level_id = j.experience_level_id
        JOIN salary_type s ON s.salary_type_id = j.salary_type_id
        JOIN location_type lt ON lt.location_type_id = j.location_type_id
    );

    -- Perform the MERGE operation
    MERGE INTO job_dim AS jd
    USING new_data AS nd ON (jd.job_id = nd.job_id)
    WHEN MATCHED AND (
            jd.job_title <> nd.job_title
         OR jd.company_name <> nd.company_name
         OR jd.experience_level <> nd.experience_level
         OR jd.months_experience_required <> nd.months_experience_required
         OR jd.salary_type <> nd.salary_type
         OR jd.minimum_pay <> nd.minimum_pay
         OR jd.maximum_pay <> nd.maximum_pay
         OR jd.location_type <> nd.location_type
    ) THEN
        UPDATE SET current_flag = 'N', last_modifiedon = NOW()
    WHEN NOT MATCHED THEN
        INSERT (job_id, job_title, company_name, experience_level, months_experience_required,
                salary_type, minimum_pay, maximum_pay, location_type, 
                last_modifiedon, createdon)
        VALUES (nd.job_id, nd.job_title, nd.company_name, nd.experience_level, nd.months_experience_required,
                nd.salary_type, nd.minimum_pay, nd.maximum_pay, nd.location_type, 
                nd.last_modifiedon, nd.createdon);

    -- Insert the updated rows as new rows with current_flag = 'Y'
    INSERT INTO job_dim (job_id, job_title, company_name, experience_level, months_experience_required,
                         salary_type, minimum_pay, maximum_pay, location_type, 
                         last_modifiedon, createdon, current_flag)
    SELECT nd.job_id, nd.job_title, nd.company_name, nd.experience_level, nd.months_experience_required,
           nd.salary_type, nd.minimum_pay, nd.maximum_pay, nd.location_type, 
           nd.last_modifiedon, nd.createdon, 'Y'
    FROM new_data AS nd
    JOIN job_dim AS jd ON jd.job_id = nd.job_id
    WHERE jd.current_flag = 'N';

    -- Set current_flag to 'N' and expiredon to NOW() for the records deleted in the source table
    UPDATE job_dim
    SET current_flag = 'N', expiredon = NOW()
    WHERE current_flag = 'Y' 
      AND NOT EXISTS (
        SELECT 1
        FROM new_data
        WHERE job_dim.job_id = new_data.job_id
      );

    -- Drop the temporary table
    DROP TABLE new_data;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger to perform Slowly Chaging Dimension 2,

CREATE TRIGGER job_dim_refresh_trigger
AFTER INSERT OR UPDATE OR DELETE ON job
FOR EACH ROW
EXECUTE FUNCTION refresh_job_dim();