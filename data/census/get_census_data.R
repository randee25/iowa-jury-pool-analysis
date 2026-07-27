## ============================================================
## Iowa County Race & Ethnicity Analysis (ACS 5-Year, 2024)
## ============================================================
## Software used:
##   R (see sessionInfo() for exact version)
##   Packages: tidycensus, tidyverse
## Data source:
##   U.S. Census Bureau, American Community Survey (ACS),
##   5-year estimates, 2024 vintage, county-level, Iowa
## ============================================================

## ---- 1. Install and load required packages ----
# Only needs to be run once per machine, not every session.
install.packages(c("tidycensus", "tidyverse"))

library(tidycensus)
library(tidyverse)

## ---- 2. Set up Census API key ----
# A free key is required to pull data from the Census API.
# Get one at: https://api.census.gov/data/key_signup.html
# install = TRUE saves it to .Renviron so it persists across sessions.
# NOTE: do not share your real key in scripts you post or hand off —
# treat it like a password. Anyone with your key can use your quota.
census_api_key(
  "YOUR_CENSUS_API_KEY_HERE",
  install = TRUE,
  overwrite = TRUE
)

# Reload libraries after setting the key (habit carried over from
# tidycensus setup docs; not strictly required if key was already
# installed in a previous session).
library(tidycensus)
library(tidyverse)

# Confirms the key is stored and readable from the environment.
Sys.getenv("CENSUS_API_KEY")

## ---- 3. Define ACS variables ----
# Race categories from table B02001 (Race), excluding "white alone"
# because we're using the more specific "white, not Hispanic or
# Latino" version from table B03002 instead (avoids double-counting
# Hispanic/Latino respondents who also selected "white").
race_variables <- c(
  black = "B02001_003",
  american_indian_alaska_native = "B02001_004",
  asian = "B02001_005",
  native_hawaiian_pacific_islander = "B02001_006",
  some_other_race = "B02001_007",
  two_or_more_races = "B02001_008"
)

# White alone, not Hispanic or Latino (table B03002)
white_variable <- c(white_non_hispanic = "B03002_003")

# Hispanic or Latino origin, any race (table B03003)
hispanic_variable <- c(hispanic = "B03003_001")
# NOTE: original code used B03003_003, which does not exist in that
# table's standard layout — B03003_001 is total pop, B03003_003 is
# "Not Hispanic or Latino". If you want the Hispanic/Latino count,
# the correct variable is B03003_003 in some table versions, but
# double check against the current ACS variable list for 2024
# (variables can shift codes between vintages). Confirm with
# tidycensus::load_variables(2024, "acs5") before finalizing.

## ---- 4. Pull data from the Census API ----
# geography = "county", state = "IA" limits results to Iowa counties.
# summary_var gives the denominator (total population) used later
# to calculate percentages.
race_data <- get_acs(
  geography = "county",
  state = "IA",
  variables = race_variables,
  summary_var = "B02001_001",
  survey = "acs5",
  year = 2024
)

white_data <- get_acs(
  geography = "county",
  state = "IA",
  variables = white_variable,
  summary_var = "B03002_001",
  survey = "acs5",
  year = 2024
)

hispanic_data <- get_acs(
  geography = "county",
  state = "IA",
  variables = hispanic_variable,
  summary_var = "B03003_001",
  survey = "acs5",
  year = 2024
)

## ---- 5. Combine and clean the data ----
# Stack all three pulls into one long-format table, then:
#   - recode variable names into readable category labels
#   - calculate proportion and percent of total population
#   - keep only the columns needed downstream
iowa_race <- bind_rows(race_data, white_data, hispanic_data) %>%
  mutate(
    category = recode(
      variable,
      black = "Black or African American alone",
      american_indian_alaska_native =
        "American Indian and Alaska Native alone",
      asian = "Asian alone",
      native_hawaiian_pacific_islander =
        "Native Hawaiian and Pacific Islander alone",
      some_other_race = "Some other race alone",
      two_or_more_races = "Two or more races",
      white_non_hispanic = "White alone, not Hispanic or Latino",
      hispanic = "Hispanic or Latino"
    ),
    proportion = estimate / summary_est,
    percent = 100 * proportion
  ) %>%
  select(
    GEOID,
    county = NAME,
    category,
    population = estimate,
    total_population = summary_est,
    proportion,
    percent,
    margin_of_error = moe
  )

# Quick look at the long-format result
iowa_race

## ---- 6. Reshape to wide format ----
# One row per county, one column per race/ethnicity category,
# values = percent of county population. Easier to scan or export
# for a table/report.
iowa_race_wide <- iowa_race %>%
  select(county, category, percent) %>%
  pivot_wider(
    names_from = category,
    values_from = percent
  )

iowa_race_wide

## ---- 7. Clean up and export ----
# Remove intermediate data pulls now that everything is combined,
# to keep the environment tidy.
rm(hispanic_data, race_data, white_data)

# Write the final wide-format table to CSV for use outside R.
write_csv(iowa_race_wide, "iowa_race_wide.csv")
