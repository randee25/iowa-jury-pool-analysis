--Creating staging tables with standardized values, ready for analysis. Names correspond to tabs of the Excel spreadsheet.

--Overall state jury pool by race
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

--State pool with multiracia data for context within race
CREATE TABLE staging.pool_mr_breakdown AS
SELECT
    LEFT(cd_court_name, 3) AS court_number,
    TRIM(SUBSTRING(cd_court_name FROM 5)) AS court_name,
    multi_race_breakout,
    multi_race_count,
    hlso_ethnicity_count
FROM raw.pool_mr_breakdown;


--State jury panel for criminal cases only, showing the next step in the process
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

--Multiracial data for context of the criminal panel
CREATE TABLE staging.crim_panel_mr_breakdown AS
SELECT
    LEFT(cd_county, 3) AS court_number,
    TRIM(SUBSTRING(cd_county FROM 5)) || ' County District Court' AS court_name,
    multi_race_breakout,
    multi_race_count,
    hlso_ethnicity_count
FROM raw.crim_panel_mr_breakdown;


--Final empanelment data showing results of different jurors of different races in each county
CREATE TABLE staging.crim_empanelment_data AS
SELECT
    LEFT(cd_county, 3) AS court_number,
    TRIM(SUBSTRING(cd_county FROM 5)) || ' County District Court' AS court_name,
    result_status,
    race,
    ethnicity,
    total
FROM raw.crim_empanelment_data;

--Census data showing percentage of the population by race
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


--Empanelment data aggregated to show the different results(not used, juror, peremptory strike, etc.) split up by race
DROP TABLE staging.crim_empanelment_race;
CREATE TABLE staging.crim_empanelment_race AS
SELECT
    court_number,
    court_name,
    result_status,
    SUM(CASE WHEN TRIM(race) = 'White' THEN total ELSE 0 END) AS white,
    SUM(CASE WHEN TRIM(race) = 'Black/African American' THEN total ELSE 0 END) AS black_african_american,
    SUM(CASE WHEN TRIM(race) = 'Hispanic/Latino/Spanish Origins' THEN total ELSE 0 END) AS hlso_race,
    SUM(CASE WHEN TRIM(ethnicity) = 'Hispanic/Latinx/Spanish Origins' THEN total ELSE 0 END) AS hlso_ethnicity,
    SUM(CASE WHEN TRIM(race) = 'Asian' THEN total ELSE 0 END) AS asian,
    SUM(CASE WHEN TRIM(race) = 'American Indian/Alaskan Native ' THEN total ELSE 0 END) AS american_indian_alaskan_native,
    SUM(CASE WHEN TRIM(race) = 'Multi Race Black/African American, White' THEN total ELSE 0 END) AS mr_bw,
    SUM(CASE WHEN TRIM(race) = 'Multi Race Other, White' THEN total ELSE 0 END) AS mr_ow,
    SUM(CASE WHEN TRIM(race) = 'Multi Race Asian, White' THEN total ELSE 0 END) AS mr_aw,
    SUM(CASE WHEN TRIM(race) = 'Multi Race Unknown' THEN total ELSE 0 END) AS mr_unk,
    SUM(CASE WHEN TRIM(race) = 'Unknown' THEN total ELSE 0 END) AS unknown,
    SUM(CASE WHEN TRIM(race) = 'Other' THEN total ELSE 0 END) AS other
FROM staging.crim_empanelment_data
GROUP BY court_number,
court_name,
result_status
ORDER BY court_number ASC;




--Verifying all rows updated correctly by selecting full table data
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

SELECT *
FROM staging.crim_empanelment_race;