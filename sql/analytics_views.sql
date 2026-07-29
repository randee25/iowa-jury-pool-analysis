--Creating views to summarize major details between the steps of the process

--Displaying state pool data by race% of the total
DROP VIEW jury_pct;
CREATE VIEW analytics.spr_jury_pct AS
SELECT
    court_number,
    court_name,
    adj_total,
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
CREATE VIEW jury_vs_census AS
SELECT
    cl.court_number,
    cl.county_name,
    cl.court_display_name,

    sp.jp_white AS pool_pct_white,
    cr.white_alone_nhl_pct AS census_pct_white,

    sp.jp_black AS pool_pct_black,
    cr.black_alone_pct AS census_pct_black,

    sp.jp_hisp AS jury_pct_hisp,
    cr.hisp_latino_pct AS census_pct_hisp,

    sp.jp_mr AS jury_pct_mr,
    cr.multi_race_pct AS census_pct_mr

FROM analytics.spr_pct sp
JOIN staging.county_lookup cl
    ON sp.court_number = cl.court_number
JOIN staging.census_race cr
    ON cl.county_name = cr.county_name;










SELECT * 
FROM analytics.spr_jury_pct;

SELECT *
FROM analytics.scp_pct;

--Turning the views to tables to export
CREATE TABLE analytics.spr_pct AS
SELECT * 
FROM analytics.spr_jury_pct;


CREATE TABLE analytics.scp_pct_ AS
SELECT *
FROM analytics.scp_pct;

CREATE TABLE analytics.census_vs_jury AS
SELECT *
FROM analytics.jury_vs_census;


--One More check to see that the final tables are correct

SELECT *
FROM analytics.spr_pct;

SELECT *
FROM analytics.scp_pct_;

SELECT *
FROM analytics.census_vs_jury;