# ============================================================
# IOWA JURY POOL REPRESENTATIVENESS ANALYSIS
# ============================================================

# Load the packages used for data cleaning and analysis
library(tidyverse)


# ============================================================
# 1. PREPARE THE OVERALL JURY POOL DATA
# ============================================================

# Create a cleaned working dataset from the imported data.
#
# Important:
# court_number is kept as a character variable because court
# numbers may contain leading zeros.
#
# Only the "Overall Pool" dataset is used in this analysis.

overall_pool <- main_analytics_view %>%
  filter(dataset == "Overall Pool") %>%
  select(-result_status) %>%
  mutate(
    court_number = as.character(court_number)
  ) %>%
  rename(
    adjusted_total = adj_total,
    jury_pool_pct = jury_pct,
    county_population_pct = census_pct,
    representation_gap = pt_diff
  )

# Check the cleaned dataset
names(overall_pool)
glimpse(overall_pool)

# Confirm the race categories included in the analysis
unique(overall_pool$race)

# Confirm the number of distinct courts
#
# This should count Lee County's two courts separately because
# each court has a different court_number.

overall_pool %>%
  distinct(court_number, county_name) %>%
  arrange(county_name, court_number)


# ============================================================
# NOTE REGARDING MULTIRACIAL OBSERVATIONS
# ============================================================

# The multiracial category was intentionally excluded from the
# primary dataset. The panel data separated multiracial jurors
# into multiple race combinations rather than one consistent
# multiracial category.
#
# Therefore, the primary analysis includes these six categories:
# White
# Black/African American
# Hispanic/Latino/Spanish Origins
# Asian
# American Indian/Alaskan Native
# Native Hawaiian/Pacific Islander


# ============================================================
# 2. CREATE RACE-SPECIFIC DATASETS
# ============================================================

white_pool <- overall_pool %>%
  filter(race == "White")

black_pool <- overall_pool %>%
  filter(race == "Black/African American")

hispanic_pool <- overall_pool %>%
  filter(race == "Hispanic/Latino/Spanish Origins")

asian_pool <- overall_pool %>%
  filter(race == "Asian")

aian_pool <- overall_pool %>%
  filter(race == "American Indian/Alaskan Native")

nhpi_pool <- overall_pool %>%
  filter(race == "Native Hawaiian/Pacific Islander")

# Check the number of observations in each dataset
nrow(white_pool)
nrow(black_pool)
nrow(hispanic_pool)
nrow(asian_pool)
nrow(aian_pool)
nrow(nhpi_pool)
# ============================================================
# 3. OVERALL DESCRIPTIVE STATISTICS
# ============================================================

# A positive representation gap means the group made up a
# larger percentage of the jury pool than of the county.
#
# A negative representation gap means the group made up a
# smaller percentage of the jury pool than of the county.

summary(overall_pool$representation_gap)

mean(overall_pool$representation_gap, na.rm = TRUE)
median(overall_pool$representation_gap, na.rm = TRUE)
sd(overall_pool$representation_gap, na.rm = TRUE)
min(overall_pool$representation_gap, na.rm = TRUE)
max(overall_pool$representation_gap, na.rm = TRUE)
range(overall_pool$representation_gap, na.rm = TRUE)

# Review jury pool sizes and jury counts
summary(overall_pool$adjusted_total)
summary(overall_pool$jury_count)
# ============================================================
# 4. DESCRIPTIVE STATISTICS BY RACE
# ============================================================

race_summary <- overall_pool %>%
  group_by(race) %>%
  summarize(
    mean_gap = mean(representation_gap, na.rm = TRUE),
    median_gap = median(representation_gap, na.rm = TRUE),
    sd_gap = sd(representation_gap, na.rm = TRUE),
    min_gap = min(representation_gap, na.rm = TRUE),
    max_gap = max(representation_gap, na.rm = TRUE),
    observations = n(),
    .groups = "drop"
  ) %>%
  arrange(mean_gap)

View(race_summary)
# ============================================================
# 5. LARGEST REPRESENTATION GAPS
# ============================================================

# Largest gaps in either direction
largest_gaps <- overall_pool %>%
  arrange(desc(abs(representation_gap))) %>%
  select(
    court_number,
    county_name,
    race,
    jury_pool_pct,
    county_population_pct,
    representation_gap
  )

View(largest_gaps)

# Most negative gaps: underrepresentation
most_underrepresented <- overall_pool %>%
  arrange(representation_gap) %>%
  select(
    court_number,
    county_name,
    race,
    jury_pool_pct,
    county_population_pct,
    representation_gap
  )

View(most_underrepresented)

# Most positive gaps: overrepresentation
most_overrepresented <- overall_pool %>%
  arrange(desc(representation_gap)) %>%
  select(
    court_number,
    county_name,
    race,
    jury_pool_pct,
    county_population_pct,
    representation_gap
  )

View(most_overrepresented)


# ============================================================
# 6. MEAN ABSOLUTE ERROR
# ============================================================

# MAE gives the average size of the representation gap,
# regardless of whether the gap is positive or negative.

mae <- mean(
  abs(overall_pool$representation_gap),
  na.rm = TRUE
)

mae
# ============================================================
# 7. CORRELATION
# ============================================================

# Pearson's correlation measures the strength of the linear
# relationship between jury pool percentages and county
# population percentages.

correlation_result <- cor(
  overall_pool$jury_pool_pct,
  overall_pool$county_population_pct,
  use = "complete.obs",
  method = "pearson"
)

correlation_result


# ============================================================
# 8. ONE-SAMPLE T-TESTS
# ============================================================

# Each test examines whether the average representation gap
# differs significantly from zero.

overall_test <- t.test(
  overall_pool$representation_gap,
  mu = 0
)

white_test <- t.test(
  white_pool$representation_gap,
  mu = 0
)

black_test <- t.test(
  black_pool$representation_gap,
  mu = 0
)

hispanic_test <- t.test(
  hispanic_pool$representation_gap,
  mu = 0
)

asian_test <- t.test(
  asian_pool$representation_gap,
  mu = 0
)

aian_test <- t.test(
  aian_pool$representation_gap,
  mu = 0
)

nhpi_test <- t.test(
  nhpi_pool$representation_gap,
  mu = 0
)

# Display the individual test results
overall_test
white_test
black_test
hispanic_test
asian_test
aian_test
nhpi_test
# ============================================================
# 9. CREATE EXPECTED COUNTS FOR CHI-SQUARE ANALYSES
# ============================================================

# The expected count estimates how many jurors from each racial
# group would be expected if the jury pool exactly matched the
# county's racial composition.

chi_data <- overall_pool %>%
  mutate(
    expected_count =
      adjusted_total * county_population_pct / 100
  )

View(chi_data)


# ============================================================
# 10. OPTIONAL EXAMPLE: ADAIR COUNTY
# ============================================================

# Because Adair County has only one court, filtering by county
# name is sufficient for this single example.

adair_data <- chi_data %>%
  filter(county_name == "Adair")

adair_test <- chisq.test(
  x = adair_data$jury_count,
  p = adair_data$expected_count /
    sum(adair_data$expected_count)
)

adair_test
# ============================================================
# 11. CHI-SQUARE ANALYSIS 1
# COMBINED RACE CATEGORIES FOR ALL COURTS
# ============================================================

# To improve expected counts, the six race categories are
# combined into four:
#
# White
# Black
# Hispanic
# Other
#
# Asian, AIAN, and NHPI observations are included in "Other."

combined_all <- chi_data %>%
  mutate(
    race_group = case_when(
      race == "White" ~ "White",
      race == "Black/African American" ~ "Black",
      race == "Hispanic/Latino/Spanish Origins" ~ "Hispanic",
      TRUE ~ "Other"
    )
  ) %>%
  group_by(
    court_number,
    county_name,
    race_group
  ) %>%
  summarize(
    observed = sum(jury_count, na.rm = TRUE),
    expected = sum(expected_count, na.rm = TRUE),
    .groups = "drop"
  )

# Check the combined data
View(combined_all)
# ============================================================
# 12. CHECK CHI-SQUARE ASSUMPTIONS FOR COMBINED CATEGORIES
# ============================================================

# This table shows the smallest expected count for each court.
# Lee County's two courts remain separate because court_number
# is included in the grouping.

combined_assumption_check <- combined_all %>%
  group_by(court_number, county_name) %>%
  summarize(
    minimum_expected = min(expected, na.rm = TRUE),
    number_below_5 = sum(expected < 5),
    percent_below_5 = mean(expected < 5) * 100,
    .groups = "drop"
  ) %>%
  arrange(desc(minimum_expected))

View(combined_assumption_check)
# ============================================================
# 13. RUN COMBINED-CATEGORY CHI-SQUARE TESTS
# ============================================================

# R will still calculate a result when an expected count is
# small, but it may produce a warning that the chi-square
# approximation could be incorrect.

combined_results <- combined_all %>%
  group_by(court_number, county_name) %>%
  group_modify(~{
    test <- suppressWarnings(
      chisq.test(
        x = .x$observed,
        p = .x$expected / sum(.x$expected)
      )
    )
    
    tibble(
      chi_square = as.numeric(test$statistic),
      degrees_freedom = as.numeric(test$parameter),
      p_value = test$p.value
    )
  }) %>%
  ungroup() %>%
  left_join(
    combined_assumption_check,
    by = c("court_number", "county_name")
  ) %>%
  mutate(
    significant_05 = p_value < 0.05,
    assumption_flag = case_when(
      minimum_expected < 1 ~
        "Expected count below 1",
      percent_below_5 > 20 ~
        "More than 20% below 5",
      TRUE ~
        "Guideline satisfied"
    )
  ) %>%
  arrange(p_value)

View(combined_results)


# ============================================================
# 14. SUMMARIZE THE COMBINED-CATEGORY RESULTS
# ============================================================

combined_results_summary <- combined_results %>%
  summarize(
    total_courts = n(),
    significant_courts = sum(significant_05, na.rm = TRUE),
    percent_significant =
      mean(significant_05, na.rm = TRUE) * 100,
    courts_meeting_guideline =
      sum(assumption_flag == "Guideline satisfied"),
    courts_with_assumption_warning =
      sum(assumption_flag != "Guideline satisfied")
  )

combined_results_summary

# View only statistically significant courts
significant_combined_results <- combined_results %>%
  filter(significant_05) %>%
  arrange(p_value)

View(significant_combined_results)

# View the ten largest chi-square statistics
largest_combined_chi_square <- combined_results %>%
  arrange(desc(chi_square)) %>%
  slice_head(n = 10)

View(largest_combined_chi_square)
# ============================================================
# 15. CHI-SQUARE ANALYSIS 2
# ALL SIX RACE CATEGORIES FOR ELIGIBLE COURTS
# ============================================================

# For this analysis, all six race categories are retained.
#
# The minimum expected count is calculated separately for each
# court. Courts with a minimum expected count of at least 5 are
# included.
#
# This is not necessarily the same as selecting the ten most
# populous counties. It selects courts based on whether their
# expected race counts are sufficiently large.

full_assumption_check <- chi_data %>%
  group_by(court_number, county_name) %>%
  summarize(
    minimum_expected = min(expected_count, na.rm = TRUE),
    number_below_5 = sum(expected_count < 5),
    percent_below_5 =
      mean(expected_count < 5) * 100,
    .groups = "drop"
  ) %>%
  arrange(desc(minimum_expected))

View(full_assumption_check)

# Keep courts where every expected count is at least 5
eligible_full_race_courts <- full_assumption_check %>%
  filter(minimum_expected >= 5)

View(eligible_full_race_courts)

# Filter the six-category data to those eligible courts
full_race_data <- chi_data %>%
  semi_join(
    eligible_full_race_courts,
    by = c("court_number", "county_name")
  )
# ============================================================
# 16. RUN SIX-CATEGORY CHI-SQUARE TESTS
# ============================================================

full_race_results <- full_race_data %>%
  group_by(court_number, county_name) %>%
  group_modify(~{
    test <- chisq.test(
      x = .x$jury_count,
      p = .x$expected_count /
        sum(.x$expected_count)
    )
    
    tibble(
      chi_square = as.numeric(test$statistic),
      degrees_freedom = as.numeric(test$parameter),
      p_value = test$p.value
    )
  }) %>%
  ungroup() %>%
  mutate(
    significant_05 = p_value < 0.05
  ) %>%
  arrange(p_value)

View(full_race_results)
# ============================================================
# 17. SUMMARIZE THE SIX-CATEGORY RESULTS
# ============================================================

full_race_results_summary <- full_race_results %>%
  summarize(
    total_eligible_courts = n(),
    significant_courts =
      sum(significant_05, na.rm = TRUE),
    percent_significant =
      mean(significant_05, na.rm = TRUE) * 100
  )

full_race_results_summary
# ============================================================
# 18. EXPORT FINAL DATASETS FOR TABLEAU
# ============================================================

# Save the cleaned county-level dataset so it can be imported
# directly into Tableau for histograms, scatter plots, and
# county-level analyses.
write.csv(
  overall_pool,
  "overall_pool_final.csv",
  row.names = FALSE
)
# Save the race-level summary statistics table for use in
# bar charts and summary visualizations.
write.csv(
  race_summary,
  "race_summary.csv",
  row.names = FALSE
)