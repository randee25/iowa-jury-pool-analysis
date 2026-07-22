DROP TABLE IF EXISTS raw.state_pool_race;
--Creating tables for raw unedited dataset
CREATE TABLE raw.state_pool_race(
   cd_court_name VARCHAR(100),
   american_indian_alaskan_native INTEGER,
   asian INTEGER,
   black_african_american INTEGER,
   hispanic_latino_spanish_origins INTEGER,
   multi_race INTEGER,
   native_hawaiian_pacific_islander INTEGER,
   not_provided INTEGER,
   other INTEGER,
   unknown INTEGER,
   white INTEGER,
   hlso_ethnicity INTEGER,
   total INTEGER 
);

CREATE TABLE raw.pool_mr_breakdown(
    cd_court_name VARCHAR(100),
    multi_race_breakout TEXT,
    multi_race_count INTEGER,
    hlso_ethnicity_count INTEGER
);

CREATE TABLE raw.state_crim_panel_race(
   cd_court_name VARCHAR(100),
   american_indian_alaskan_native INTEGER,
   asian INTEGER,
   black_african_american INTEGER,
   hispanic_latino_spanish_origins INTEGER,
   multi_race INTEGER,
   native_hawaiian_pacific_islander INTEGER,
   not_provided INTEGER,
   other INTEGER,
   unknown INTEGER,
   white INTEGER,
   total INTEGER,
   hlso_ethnicity INTEGER
);

CREATE TABLE raw.crim_panel_mr_breakdown(
    cd_county VARCHAR(100),
    multi_race_breakout TEXT,
    multi_race_count INTEGER,
    hlso_ethnicity_count INTEGER
);

CREATE TABLE raw.crim_empanelment_data(
    cd_county VARCHAR(100),
    result_status TEXT,
    race TEXT,
    total INTEGER,
    ethnicity TEXT
);

