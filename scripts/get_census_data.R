## ============================================================
## Iowa County Race & Ethnicity Analysis
## U.S. Citizens Age 18+ (ACS 5-Year, 2024)
## ============================================================
## Software used:
##   R version 4.5.1
##   Packages: tidycensus, tidyverse
##
## Data source:
##   U.S. Census Bureau, American Community Survey (ACS),
##   2024 5-year estimates, county-level, Iowa
##
## Comparison population:
##   U.S. citizens age 18 and older
##
## ACS tables:
##   B05003  - Total population by age, nativity, citizenship
##   B05003B - Black or African American alone
##   B05003C - American Indian and Alaska Native alone
##   B05003D - Asian alone
##   B05003E - Native Hawaiian and Other Pacific Islander alone
##   B05003G - Two or more races
##   B05003H - White alone, not Hispanic or Latino
##   B05003I - Hispanic or Latino
## ============================================================


## ---- 1. Load required packages ----

library(tidycensus)
library(tidyverse)


## ---- 2. Census API key ----
# A free Census API key is required.
#
# Obtain a key at:
# https://api.census.gov/data/key_signup.html
# Example one-time setup in the R Console:
# census_api_key(
#   "YOUR_ACTUAL_API_KEY",
#   install = TRUE,
#   overwrite = TRUE
# )
#
# Restart R after installing the key.


## ---- 3. Helper function for U.S. citizens age 18+ ----

# Each B05003 race/ethnicity table separates adults by:
#   - sex
#   - age
#   - nativity
#   - citizenship
#
# U.S. citizens age 18+ are calculated as:
#
#   Male 18+ Native
# + Male 18+ Foreign-born, Naturalized U.S. Citizen
# + Female 18+ Native
# + Female 18+ Foreign-born, Naturalized U.S. Citizen
#
# Corresponding variable suffixes:
#   _009 = Male 18+, Native
#   _011 = Male 18+, Naturalized U.S. citizen
#   _020 = Female 18+, Native
#   _022 = Female 18+, Naturalized U.S. citizen

get_citizen18 <- function(table_prefix, category_name) {

  variables <- c(
    male_native =
      paste0(table_prefix, "_009"),

    male_naturalized =
      paste0(table_prefix, "_011"),

    female_native =
      paste0(table_prefix, "_020"),

    female_naturalized =
      paste0(table_prefix, "_022")
  )

  get_acs(
    geography = "county",
    state = "IA",
    variables = variables,
    survey = "acs5",
    year = 2024
  ) %>%
    group_by(GEOID, NAME) %>%
    summarise(
      citizen_18_population = sum(estimate, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    mutate(
      category = category_name
    )
}


## ---- 4. Pull total U.S. citizen population age 18+ ----

# Plain B05003 contains the total population regardless of
# race or ethnicity. The same four adult-citizen cells are
# summed to create the denominator used for all percentages.

total_citizen18 <- get_citizen18(
  "B05003",
  "Total U.S. citizens age 18+"
) %>%
  transmute(
    GEOID,
    county = NAME,
    total_citizen_18 = citizen_18_population
  )


## ---- 5. Pull U.S. citizen age 18+ population by group ----

black <- get_citizen18(
  "B05003B",
  "Black or African American alone"
)

american_indian_alaska_native <- get_citizen18(
  "B05003C",
  "American Indian and Alaska Native alone"
)

asian <- get_citizen18(
  "B05003D",
  "Asian alone"
)

native_hawaiian_pacific_islander <- get_citizen18(
  "B05003E",
  "Native Hawaiian and Pacific Islander alone"
)

multiracial <- get_citizen18(
  "B05003G",
  "Two or more races"
)

white_non_hispanic <- get_citizen18(
  "B05003H",
  "White alone, not Hispanic or Latino"
)

hispanic <- get_citizen18(
  "B05003I",
  "Hispanic or Latino"
)


## ---- 6. Combine and calculate county percentages ----

iowa_citizen18 <- bind_rows(
  black,
  american_indian_alaska_native,
  asian,
  native_hawaiian_pacific_islander,
  multiracial,
  white_non_hispanic,
  hispanic
) %>%
  left_join(
    total_citizen18,
    by = "GEOID"
  ) %>%
  mutate(
    proportion =
      citizen_18_population / total_citizen_18,

    percent =
      100 * proportion
  ) %>%
  select(
    GEOID,
    county = NAME,
    category,
    population = citizen_18_population,
    total_population = total_citizen_18,
    proportion,
    percent
  )


## ---- 7. Validate long-format dataset ----

# Expected:
# 99 Iowa counties x 7 demographic groups = 693 rows
stopifnot(nrow(iowa_citizen18) == 693)

# Confirm 99 unique counties
stopifnot(n_distinct(iowa_citizen18$GEOID) == 99)

# Review demographic categories
sort(unique(iowa_citizen18$category))

# Check for missing values
iowa_citizen18 %>%
  filter(
    is.na(population) |
      is.na(total_population) |
      is.na(percent)
  )


## ---- 8. Create standardized Census table ----

# County and race labels are standardized to match the jury dataset.

census_counts <- iowa_citizen18 %>%
  transmute(
    county_name =
      str_remove(county, " County, Iowa$"),

    race = recode(
      category,

      "Asian alone" =
        "Asian",

      "Native Hawaiian and Pacific Islander alone" =
        "Native Hawaiian/Pacific Islander",

      "White alone, not Hispanic or Latino" =
        "White",

      "American Indian and Alaska Native alone" =
        "American Indian/Alaskan Native",

      "Black or African American alone" =
        "Black/African American",

      "Two or more races" =
        "Multiracial",

      "Hispanic or Latino" =
        "HLSO"
    ),

    census_count =
      round(population),

    census_total =
      round(total_population),

    census_pct =
      percent
  )


## ---- 9. Validate standardized dataset ----

# Expected: 693 county-race combinations
stopifnot(nrow(census_counts) == 693)

# Confirm all race labels
sort(unique(census_counts$race))

# Verify that each county-race combination appears once
duplicates <- census_counts %>%
  count(county_name, race) %>%
  filter(n > 1)

stopifnot(nrow(duplicates) == 0)

# Check for missing values
missing_values <- census_counts %>%
  filter(
    is.na(census_count) |
      is.na(census_total) |
      is.na(census_pct)
  )

stopifnot(nrow(missing_values) == 0)


## ---- 10. Export standardized Census dataset ----

write_csv(
  census_counts,
  "census_citizen18_standardized.csv"
)


## ---- 11. Create wide-format Census table ----

# One row per county with one percentage column per
# race/ethnicity category.

iowa_citizen18_wide <- iowa_citizen18 %>%
  select(
    county,
    category,
    percent
  ) %>%
  pivot_wider(
    names_from = category,
    values_from = percent
  )


## ---- 12. Export wide-format dataset ----

write_csv(
  iowa_citizen18_wide,
  "iowa_citizen18_wide.csv"
)
