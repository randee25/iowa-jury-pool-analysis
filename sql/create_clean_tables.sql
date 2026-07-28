--Creating staging tables with standardized values, ready for analysis
CREATE TABLE staging.state_pool_race AS
SELECT
    LEFT(cd_court_name, 3) AS court_number,
    TRIM(SUBSTRING(cd_court_name FROM 5)) AS court_name,
    american_indian_alaskan_native,
    asian,
    black_african_american,
    hispanic_latino_spanish_origins,
    multi_race,
    native_hawaiian_pacific_islander,
    not_provided,
    other,
    unknown,
    white,
    hlso_ethnicity,
    total,
    total-not_provided AS adj_total
FROM raw.state_pool_race;


CREATE TABLE staging.pool_mr_breakdown AS
SELECT
    LEFT(cd_court_name, 3) AS court_number,
    TRIM(SUBSTRING(cd_court_name FROM 5)) AS court_name,
    multi_race_breakout,
    multi_race_count,
    hlso_ethnicity_count
FROM raw.pool_mr_breakdown;

DROP TABLE IF EXISTS staging.state_crim_panel_race;

CREATE TABLE staging.state_crim_panel_race AS
SELECT
    LEFT(cd_court_name, 3) AS court_number,
    TRIM(SUBSTRING(cd_court_name FROM 5)) || ' County District Court' AS court_name,
    american_indian_alaskan_native,
    asian,
    black_african_american,
    hispanic_latino_spanish_origins,
    multi_race,
    native_hawaiian_pacific_islander,
    not_provided,
    other,
    unknown,
    white,
    hlso_ethnicity,
    total,
    total-not_provided AS adj_total
FROM raw.state_crim_panel_race;

CREATE TABLE staging.crim_panel_mr_breakdown AS
SELECT
    LEFT(cd_county, 3) AS court_number,
    TRIM(SUBSTRING(cd_county FROM 5)) || ' County District Court' AS court_name,
    multi_race_breakout,
    multi_race_count,
    hlso_ethnicity_count
FROM raw.crim_panel_mr_breakdown;



CREATE TABLE staging.crim_empanelment_data AS
SELECT
    LEFT(cd_county, 3) AS court_number,
    TRIM(SUBSTRING(cd_county FROM 5)) || ' County District Court' AS court_name,
    result_status,
    race,
    ethnicity,
    total
FROM raw.crim_empanelment_data;

CREATE TABLE staging.census_race AS
SELECT
    REPLACE(county, ' County, Iowa', '') AS county_name,
    black_alone_pct,
    ai_native_alone_pct,
    asian_alone_pct,
    nh_pacific_isl_alone_pct,
    other_alone_pct,
    multi_race_pct,
    white_alone_nhl_pct,
    hisp_latino_pct
FROM raw.census_race;




--Verifying all rows updated correctly
SELECT *
FROM staging.state_pool_race;

SELECT *
FROM staging.pool_mr_breakdown;

SELECT *
FROM staging.state_crim_panel_race;

SELECT *
FROM staging.crim_empanelment_data;

SELECT *
FROM staging.crim_panel_mr_breakdown;

SELECT *
FROM staging.census_race;
