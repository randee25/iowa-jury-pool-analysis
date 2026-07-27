install.packages(c("tidycensus", "tidyverse"))
library(tidycensus)
library(tidyverse)
census_api_key(
  "849058f8ba49c7d1133bf4da85aaadfa54effd33",
  install = TRUE,
  overwrite = TRUE)
library(tidycensus)
library(tidyverse)
Sys.getenv("CENSUS_API_KEY")
# Race categories (excluding white, since we're using the non-Hispanic version instead)
race_variables <- c(
  black = "B02001_003",
  american_indian_alaska_native = "B02001_004",
  asian = "B02001_005",
  native_hawaiian_pacific_islander = "B02001_006",
  some_other_race = "B02001_007",
  two_or_more_races = "B02001_008"
)

# White alone, not Hispanic or Latino
white_variable <- c(white_non_hispanic = "B03002_003")

# Hispanic or Latino origin
hispanic_variable <- c(hispanic = "B03003_003")
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
iowa_race
iowa_race_wide <- iowa_race %>%
  select(county, category, percent) %>%
  pivot_wider(
    names_from = category,
    values_from = percent
  )

iowa_race_wide
rm(hispanic_data, race_data, white_data)
write_csv(iowa_race_wide, "iowa_race_wide.csv")
