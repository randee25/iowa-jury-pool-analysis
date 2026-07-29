CREATE TABLE staging.county_lookup AS
SELECT
    LEFT(cd_court_name, 3) AS court_number,
    TRIM(SUBSTRING(cd_court_name FROM 5)) AS county_name,
    TRIM(SUBSTRING(cd_court_name FROM 5)) || ' County District Court' AS court_display_name
FROM raw.state_crim_panel_race;

SELECT *
FROM staging.county_lookup;