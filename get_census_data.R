install.packages(c("tidycensus", "tidyverse"))

library(tidycensus)
library(tidyverse)


census_api_key(
  "YOUR_CENSUS_API_KEY", #you need to go get this at https://api.census.gov/data/key_signup.html
  install = TRUE,
  overwrite = TRUE
)

race_variables <- c(
  total = "B02001_001",
  white = "B02001_002",
  black = "B02001_003",
  american_indian_alaska_native = "B02001_004",
  asian = "B02001_005",
  native_hawaiian_pacific_islander = "B02001_006",
  some_other_race = "B02001_007",
  two_or_more_races = "B02001_008"
)

iowa_race <- get_acs(
  geography = "county",
  state = "IA",
  variables = race_variables,
  summary_var = "B02001_001",
  survey = "acs5",
  year = 2024
) %>%
  filter(variable != "total") %>%
  mutate(
    race = recode(
      variable,
      white = "White alone",
      black = "Black or African American alone",
      american_indian_alaska_native =
        "American Indian and Alaska Native alone",
      asian = "Asian alone",
      native_hawaiian_pacific_islander =
        "Native Hawaiian and Pacific Islander alone",
      some_other_race = "Some other race alone",
      two_or_more_races = "Two or more races"
    ),
    proportion = estimate / summary_est,
    percent = 100 * proportion
  ) %>%
  select(
    GEOID,
    county = NAME,
    race,
    population = estimate,
    total_population = summary_est,
    proportion,
    percent,
    margin_of_error = moe
  )

iowa_race


#if you want it in a wide format (and you may...)

iowa_race_wide <- iowa_race %>%
  select(county, race, percent) %>%
  pivot_wider(
    names_from = race,
    values_from = percent
  )

iowa_race_wide