--Creating views to summarize major details between the steps of the process

--Displaying state pool data by race% of the total
DROP VIEW analytics.spr_jury_pct; (in case you need to edit/recreate)

CREATE TABLE analytics.spr_jury_pct AS
SELECT
    court_number,
    court_name,
    adj_total,
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
    ROUND((100.0 * white) / adj_total, 2) AS jp_white,
    ROUND((100.0 * black_african_american) / adj_total, 2) AS jp_black,
    ROUND((100.0 * hispanic_latino_spanish_origins) / adj_total, 2) AS jp_hisp,
    ROUND((100.0 * asian) / adj_total, 2) AS jp_asian,
    ROUND((100.0 * american_indian_alaskan_native) / adj_total, 2) AS jp_aian,
    ROUND((100.0 * multi_race) / adj_total, 2) AS jp_mr,
    ROUND((100.0 * native_hawaiian_pacific_islander) / adj_total, 2) AS jp_nhpi,
    ROUND((100.0 * other) / adj_total, 2) AS jp_other,
    ROUND((100.0 * unknown) / adj_total, 2) AS jp_unk
FROM staging.state_pool_race;

--Presenting criminal panel data as race% of the total(counties with reported totals of 0 omitted)
DROP VIEW analytics.scp_pct;
CREATE VIEW analytics.scp_pct AS
SELECT
    court_number,
    court_name,
    adj_total,
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
    ROUND((100.0 * white) / NULLIF(adj_total, 0), 2) AS cp_white,
    ROUND((100.0 * black_african_american) / NULLIF(adj_total, 0), 2) AS cp_black,
    ROUND((100.0 * hispanic_latino_spanish_origins) / NULLIF(adj_total, 0), 2) AS cp_hisp,
    ROUND((100.0 * asian) / NULLIF(adj_total, 0), 2) AS cp_asian,
    ROUND((100.0 * american_indian_alaskan_native) / NULLIF(adj_total, 0), 2) AS cp_aian,
    ROUND((100.0 * multi_race) / NULLIF(adj_total, 0), 2) AS cp_mr,
    ROUND((100.0 * native_hawaiian_pacific_islander) / NULLIF(adj_total, 0), 2) AS cp_nhpi,
    ROUND((100.0 * other) / NULLIF(adj_total, 0), 2) AS cp_other,
    ROUND((100.0 * unknown) / NULLIF(adj_total, 0), 2) AS cp_unk
FROM staging.state_crim_panel_race
WHERE adj_total > 0;


--Comparing total jury pool percentages vs census percentages of each race
DROP VIEW jury_vs_census; (in case you need to edit/recreate)

CREATE VIEW jury_vs_census AS
SELECT
    cl.court_number,
    cl.county_name,
    cl.court_display_name,
    sp.adj_total,
    sp.american_indian_alaskan_native,
    sp.asian,
    sp.black_african_american,
    sp.hispanic_latino_spanish_origins,
    sp.multi_race,
    sp.native_hawaiian_pacific_islander,
    sp.not_provided,
    sp.other,
    sp.unknown,
    sp.white,
    sp.hlso_ethnicity,
    sp.total,

    sp.jp_white AS pool_pct_white,
    cr.white_alone_nhl_pct AS census_pct_white,

    sp.jp_black AS pool_pct_black,
    cr.black_alone_pct AS census_pct_black,

    sp.jp_hisp AS jury_pct_hisp,
    cr.hisp_latino_pct AS census_pct_hisp,

    sp.jp_mr AS jury_pct_mr,
    cr.multi_race_pct AS census_pct_mr,

    sp.jp_asian AS jury_pct_asian,
    cr.asian_alone_pct AS census_pct_asian,

    sp.jp_aian AS jury_pct_aian,
    cr.ai_native_alone_pct AS census_pct_aian,

    sp.jp_nhpi AS jury_pct_nhpi,
    cr.nh_pacific_isl_alone_pct AS census_pct_nhpi

FROM analytics.spr_pct sp
JOIN staging.county_lookup cl
    ON sp.court_number = cl.court_number
JOIN staging.census_race cr
    ON cl.county_name = cr.county_name;

--Creating view of percentage of criminal panel in each county by race compared to census percentages

DROP VIEW panel_vs_census;
CREATE VIEW panel_vs_census AS
SELECT
    cl.court_number,
    cl.county_name,
    cl.court_display_name,
    cp.adj_total,
    cp.american_indian_alaskan_native,
    cp.asian,
    cp.black_african_american,
    cp.hispanic_latino_spanish_origins,
    cp.multi_race,
    cp.native_hawaiian_pacific_islander,
    cp.not_provided,
    cp.other,
    cp.unknown,
    cp.white,
    cp.hlso_ethnicity,
    cp.total,

    cp.cp_white AS panel_pct_white,
    cr.white_alone_nhl_pct AS census_pct_white,

    cp.cp_black AS panel_pct_black,
    cr.black_alone_pct AS census_pct_black,

    cp.cp_hisp AS panel_pct_hisp,
    cr.hisp_latino_pct AS census_pct_hisp,

    cp.cp_mr AS panel_pct_mr,
    cr.multi_race_pct AS census_pct_mr,

    cp.cp_asian AS panel_pct_asian,
    cr.asian_alone_pct AS census_pct_asian,

    cp.cp_aian AS panel_pct_aian,
    cr.ai_native_alone_pct AS census_pct_aian,

    cp.cp_nhpi AS panel_pct_nhpi,
    cr.nh_pacific_isl_alone_pct AS census_pct_nhpi

FROM analytics.scp_pct cp
JOIN staging.county_lookup cl ON cp.court_number = cl.court_number
JOIN staging.census_race cr ON cl.county_name = cr.county_name;

--Creating view comparing final empanelment percentages to census percentages
CREATE VIEW analytics.empanelment_vs_census AS
SELECT
    cl.court_number,
    cl.county_name,
    cl.court_display_name,
    e.result_status,
    e.emp_total,
    

    e.white,
    e.black_african_american,
    e.hlso_race,
    e.asian,
    e.american_indian_alaskan_native,
    e.native_hawaiian_pacific_islander,

    ROUND((100.0 * e.white) / NULLIF(emp_total, 0), 2) AS emp_white_pct,
    cr.white_alone_nhl_pct AS census_pct_white,

    ROUND((100.0 * e.black_african_american) / NULLIF(emp_total, 0), 2) AS emp_black_pct,
    cr.black_alone_pct AS census_pct_black,

    ROUND((100.0 * e.hlso_race) / NULLIF(emp_total, 0), 2) AS emp_hisp_pct,
    cr.hisp_latino_pct AS census_pct_hisp,

    ROUND((100.0 * e.asian) / NULLIF(emp_total, 0), 2) AS emp_asian_pct,
    cr.asian_alone_pct AS census_pct_asian,

    ROUND((100.0 * e.american_indian_alaskan_native) / NULLIF(emp_total, 0), 2) AS emp_aian_pct,
    cr.ai_native_alone_pct AS census_pct_aian,

    ROUND((100.0 * e.native_hawaiian_pacific_islander) / NULLIF(emp_total, 0), 2) AS emp_nhpi_pct,
    cr.nh_pacific_isl_alone_pct AS census_pct_nhpi


FROM staging.crim_empanelment_race e
JOIN staging.county_lookup cl ON e.court_number = cl.court_number
JOIN staging.census_race cr ON cr.county_name = cl.county_name;




CREATE VIEW tidy_race_stats AS
SELECT
    court_number,
    county_name,
    'Overall Pool' AS dataset,
    NULL AS result_status,
    'White' as race,
    adj_total,
    white AS jury_count,
    pool_pct_white AS jury_pct,
    census_pct_white AS census_pct,
    pool_pct_white - census_pct_white AS pt_diff
FROM analytics.census_vs_jury

UNION ALL

SELECT
    court_number,
    county_name,
    'Overall Pool',
    NULL,
    'Black/African American',
    adj_total,
    black_african_american,
    pool_pct_black,
    census_pct_black,
    pool_pct_black - census_pct_black
FROM analytics.census_vs_jury


UNION ALL

SELECT
    court_number,
    county_name,
    'Overall Pool',
    NULL,
    'Hispanic/Latino/Spanish Origins',
    adj_total,
    hispanic_latino_spanish_origins,
    jury_pct_hisp,
    census_pct_hisp,
    jury_pct_hisp - census_pct_hisp
FROM analytics.census_vs_jury

UNION ALL


SELECT
    court_number,
    county_name,
    'Overall Pool',
    NULL,
    'Asian',
    adj_total,
    asian,
    jury_pct_asian,
    census_pct_asian,
    jury_pct_asian - census_pct_asian
FROM analytics.census_vs_jury


UNION ALL

SELECT
    court_number,
    county_name,
    'Overall Pool',
    NULL,
    'American Indian/Alaskan Native',
    adj_total,
    american_indian_alaskan_native,
    jury_pct_aian,
    census_pct_aian,
    jury_pct_aian - census_pct_aian
FROM analytics.census_vs_jury


UNION ALL

SELECT
    court_number,
    county_name,
    'Overall Pool',
    NULL,
    'Native Hawaiian/Pacific Islander',
    adj_total,
    native_hawaiian_pacific_islander,
    jury_pct_nhpi,
    census_pct_nhpi,
    jury_pct_nhpi - census_pct_nhpi
FROM analytics.census_vs_jury


UNION ALL


SELECT
    court_number,
    county_name,
    'Criminal Panel',
    NULL,
    'White',
    adj_total,
    white,
    panel_pct_white,
    census_pct_white,
    panel_pct_white - census_pct_white 
FROM analytics.panel_vs_census

UNION ALL

SELECT
    court_number,
    county_name,
    'Criminal Panel',
    NULL,
    'Black/African American',
    adj_total,
    black_african_american,
    panel_pct_black,
    census_pct_black,
    panel_pct_black - census_pct_black
FROM analytics.panel_vs_census


UNION ALL

SELECT
    court_number,
    county_name,
    'Criminal Panel',
    NULL,
    'Hispanic/Latino/Spanish Origins',
    adj_total,
    hispanic_latino_spanish_origins,
    panel_pct_hisp,
    census_pct_hisp,
    panel_pct_hisp - census_pct_hisp
FROM analytics.panel_vs_census

UNION ALL


SELECT
    court_number,
    county_name,
    'Criminal Panel',
    NULL,
    'Asian',
    adj_total,
    asian,
    panel_pct_asian,
    census_pct_asian,
    panel_pct_asian - census_pct_asian
FROM analytics.panel_vs_census


UNION ALL

SELECT
    court_number,
    county_name,
    'Criminal Panel',
    NULL,
    'American Indian/Alaskan Native',
    adj_total,
    american_indian_alaskan_native,
    panel_pct_aian,
    census_pct_aian,
    panel_pct_aian - census_pct_aian
FROM analytics.panel_vs_census


UNION ALL

SELECT
    court_number,
    county_name,
    'Criminal Panel',
    NULL,
    'Native Hawaiian/Pacific Islander',
    adj_total,
    native_hawaiian_pacific_islander,
    panel_pct_nhpi,
    census_pct_nhpi,
    panel_pct_nhpi - census_pct_nhpi
FROM analytics.panel_vs_census


UNION ALL

SELECT
    court_number,
    county_name,
    'Empanelment' AS dataset,
    result_status,
    'White',
    emp_total,
    white,
    emp_white_pct,
    census_pct_white,
    emp_white_pct - census_pct_white AS pt_diff
FROM analytics.empanelment_vs_census

UNION ALL

SELECT
    court_number,
    county_name,
    'Empanelment',
    result_status,
    'Black/African American',
    emp_total,
    black_african_american,
    emp_black_pct,
    census_pct_black,
   emp_black_pct - census_pct_black
FROM analytics.empanelment_vs_census


UNION ALL

SELECT
    court_number,
    county_name,
    'Empanelment',
    result_status,
    'Hispanic/Latino/Spanish Origins',
    emp_total,
    hlso_race,
    emp_hisp_pct,
    census_pct_hisp,
    emp_hisp_pct - census_pct_hisp
FROM analytics.empanelment_vs_census

UNION ALL


SELECT
    court_number,
    county_name,
    'Empanelment',
    result_status,
    'Asian',
    emp_total,
    asian,
    emp_asian_pct,
    census_pct_asian,
    emp_asian_pct - census_pct_asian
FROM analytics.empanelment_vs_census


UNION ALL

SELECT
    court_number,
    county_name,
    'Empanelment',
    result_status,
    'American Indian/Alaskan Native',
    emp_total,
    american_indian_alaskan_native,
    emp_aian_pct,
    census_pct_aian,
    emp_aian_pct - census_pct_aian
FROM analytics.empanelment_vs_census


UNION ALL

SELECT
    court_number,
    county_name,
    'Empanelment',
    result_status,
    'Native Hawaiian/Pacific Islander',
    emp_total,
    native_hawaiian_pacific_islander,
    emp_nhpi_pct,
    census_pct_nhpi,
    emp_nhpi_pct - census_pct_nhpi
FROM analytics.empanelment_vs_census;







--Testing views to see values
SELECT * 
FROM analytics.spr_jury_pct;

SELECT *
FROM analytics.scp_pct;

SELECT *
FROM tidy_race_stats

ORDER BY county_name;

--Turning the views to tables to export
DROP TABLE analytics.spr_pct;

CREATE TABLE analytics.spr_pct AS
SELECT * 
FROM analytics.spr_jury_pct;


CREATE TABLE analytics.scp_pct_ AS
SELECT *
FROM analytics.scp_pct;

DROP TABLE analytics.census_vs_jury;

CREATE TABLE analytics.census_vs_jury AS
SELECT *
FROM analytics.jury_vs_census;

CREATE TABLE main_analytics_view AS
SELECT *
FROM tidy_race_stats

ORDER BY county_name;


--One More check to see that the final tables are correct

SELECT *
FROM analytics.spr_pct;

SELECT *
FROM analytics.scp_pct_;

SELECT *
FROM analytics.census_vs_jury;

SELECT *
FROM analytics.panel_vs_census;

SELECT *
FROM analytics.empanelment_vs_census;

SELECT *
FROM main_analytics_view;