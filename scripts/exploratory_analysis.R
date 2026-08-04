# ============================================================
# IOWA JURY POOL REPRESENTATIVENESS ANALYSIS
# ============================================================
#
# Purpose:
# Compare the racial and ethnic composition of Iowa county-level
# jury pools with county demographic estimates.
#
# Primary analyses:
#   1. Descriptive statistics
#   2. Representation-gap analysis
#   3. Mean absolute error
#   4. Pearson correlation
#   5. One-sample t-tests and 95% confidence intervals
#   6. Binomial standard-deviation analysis
#
# Data source:
#   main_analytics_view
#
# Required package:
#   tidyverse
# ============================================================


# ============================================================
# 1. LOAD REQUIRED PACKAGES
# ============================================================

library(tidyverse)


# ============================================================
# 2. PREPARE THE OVERALL JURY POOL DATA
# ============================================================

# Create a cleaned working dataset from the imported data.
#
# court_number is stored as a character variable because court
# identifiers may contain leading zeros.
#
# Only records from the overall jury pool are included.

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


# ============================================================
# 3. INITIAL DATA CHECKS
# ============================================================

# Review the structure and column names of the cleaned dataset.

names(overall_pool)
glimpse(overall_pool)

# Confirm the demographic categories included in the analysis.

unique(overall_pool$race)

# Display the distinct courts.
#
# Iowa has 99 counties, but Lee County has two separate courts.
# Therefore, the data are expected to contain 100 court records.

court_list <- overall_pool %>%
  distinct(court_number, county_name) %>%
  arrange(county_name, court_number)

View(court_list)

# Count the number of distinct courts.

nrow(court_list)


# ============================================================
# 4. NOTES ABOUT DEMOGRAPHIC CATEGORIES
# ============================================================

# The primary analysis includes six demographic categories:
#
#   White
#   Black/African American
#   Hispanic/Latino/Spanish Origins
#   Asian
#   American Indian/Alaskan Native
#   Native Hawaiian/Pacific Islander
#
# Multiracial observations were not included in the cleaned
# analytical dataset because multiracial classifications were
# not represented consistently across the jury datasets.
#
# Hispanic/Latino/Spanish Origins is an ethnicity category and
# may overlap conceptually with race categories. It is retained
# because it is an important demographic group in Iowa.
#
# Therefore, each category is analyzed independently. The six
# categories should not be interpreted as mutually exclusive
# portions of a single distribution that must total 100%.


# ============================================================
# 5. VERIFY THE COURT-LEVEL TOTAL
# ============================================================

# adjusted_total should represent the complete adjusted jury-pool
# total for a court and should be repeated consistently across
# every demographic row belonging to that court.
#
# This check identifies courts with more than one adjusted_total.

adjusted_total_check <- overall_pool %>%
  group_by(court_number, county_name) %>%
  summarize(
    distinct_adjusted_totals = n_distinct(adjusted_total),
    minimum_adjusted_total = min(adjusted_total, na.rm = TRUE),
    maximum_adjusted_total = max(adjusted_total, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  filter(distinct_adjusted_totals != 1)

adjusted_total_check

# A result containing zero rows means adjusted_total is
# consistent within every court.


# ============================================================
# 6. CREATE RACE-SPECIFIC DATASETS
# ============================================================

# These subsets are used for the race-specific t-tests.

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


# Confirm the number of observations in each subset.

nrow(white_pool)
nrow(black_pool)
nrow(hispanic_pool)
nrow(asian_pool)
nrow(aian_pool)
nrow(nhpi_pool)


# ============================================================
# 7. OVERALL DESCRIPTIVE STATISTICS
# ============================================================

# The representation gap is calculated as:
#
# jury pool percentage - county population percentage
#
# Positive values indicate overrepresentation in the jury pool.
# Negative values indicate underrepresentation in the jury pool.

overall_gap_summary <- overall_pool %>%
  summarize(
    mean_gap = mean(representation_gap, na.rm = TRUE),
    median_gap = median(representation_gap, na.rm = TRUE),
    sd_gap = sd(representation_gap, na.rm = TRUE),
    min_gap = min(representation_gap, na.rm = TRUE),
    max_gap = max(representation_gap, na.rm = TRUE),
    range_gap =
      max(representation_gap, na.rm = TRUE) -
      min(representation_gap, na.rm = TRUE),
    observations = sum(!is.na(representation_gap))
  )

overall_gap_summary

# Review the distributions of court pool sizes and jury counts.

summary(overall_pool$adjusted_total)
summary(overall_pool$jury_count)


# ============================================================
# 8. DESCRIPTIVE STATISTICS BY RACE
# ============================================================

# sd_gap is a descriptive measure showing how much the
# representation gap varies across Iowa courts for each group.
#
# It is different from the binomial standard deviation used
# later to evaluate individual courts.

race_summary <- overall_pool %>%
  group_by(race) %>%
  summarize(
    mean_gap = mean(representation_gap, na.rm = TRUE),
    median_gap = median(representation_gap, na.rm = TRUE),
    sd_gap = sd(representation_gap, na.rm = TRUE),
    min_gap = min(representation_gap, na.rm = TRUE),
    max_gap = max(representation_gap, na.rm = TRUE),
    range_gap =
      max(representation_gap, na.rm = TRUE) -
      min(representation_gap, na.rm = TRUE),
    observations = sum(!is.na(representation_gap)),
    .groups = "drop"
  ) %>%
  arrange(mean_gap)

View(race_summary)


# ============================================================
# 9. LARGEST REPRESENTATION GAPS
# ============================================================

# Rank court and demographic combinations by the absolute size
# of the representation gap, regardless of direction.

largest_gaps <- overall_pool %>%
  select(
    court_number,
    county_name,
    race,
    adjusted_total,
    jury_count,
    jury_pool_pct,
    county_population_pct,
    representation_gap
  ) %>%
  arrange(desc(abs(representation_gap)))

View(largest_gaps)


# Most negative representation gaps.

most_underrepresented <- overall_pool %>%
  select(
    court_number,
    county_name,
    race,
    adjusted_total,
    jury_count,
    jury_pool_pct,
    county_population_pct,
    representation_gap
  ) %>%
  arrange(representation_gap)

View(most_underrepresented)


# Most positive representation gaps.

most_overrepresented <- overall_pool %>%
  select(
    court_number,
    county_name,
    race,
    adjusted_total,
    jury_count,
    jury_pool_pct,
    county_population_pct,
    representation_gap
  ) %>%
  arrange(desc(representation_gap))

View(most_overrepresented)


# Create more manageable top-10 tables.

top_10_underrepresented <- most_underrepresented %>%
  slice_head(n = 10)

top_10_overrepresented <- most_overrepresented %>%
  slice_head(n = 10)

View(top_10_underrepresented)
View(top_10_overrepresented)


# ============================================================
# 10. MEAN ABSOLUTE ERROR
# ============================================================

# Mean absolute error measures the average size of the
# representation gap without considering its direction.

overall_mae <- mean(
  abs(overall_pool$representation_gap),
  na.rm = TRUE
)

overall_mae


# Calculate MAE separately for each demographic group.

mae_by_race <- overall_pool %>%
  group_by(race) %>%
  summarize(
    mean_absolute_error =
      mean(abs(representation_gap), na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(mean_absolute_error))

View(mae_by_race)


# ============================================================
# 11. PEARSON CORRELATION
# ============================================================

# Pearson correlation measures the strength of the linear
# relationship between the jury-pool percentage and county
# population percentage.
#
# A high correlation does not necessarily mean all groups are
# represented equally. It only means the percentages tend to
# move together.

overall_correlation <- cor(
  overall_pool$jury_pool_pct,
  overall_pool$county_population_pct,
  use = "complete.obs",
  method = "pearson"
)

overall_correlation


# Calculate correlation separately for each demographic group.

correlation_by_race <- overall_pool %>%
  group_by(race) %>%
  summarize(
    pearson_correlation = cor(
      jury_pool_pct,
      county_population_pct,
      use = "complete.obs",
      method = "pearson"
    ),
    .groups = "drop"
  ) %>%
  arrange(desc(pearson_correlation))

View(correlation_by_race)


# ============================================================
# 12. ONE-SAMPLE T-TESTS AND 95% CONFIDENCE INTERVALS
# ============================================================

# Each one-sample t-test evaluates whether the average
# representation gap across courts differs from zero.
#
# Null hypothesis:
# The mean representation gap equals zero.
#
# Alternative hypothesis:
# The mean representation gap does not equal zero.
#
# Limitation:
# Every court receives equal weight in these tests regardless
# of the size of its jury pool.

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


# Display the complete test results.

overall_test
white_test
black_test
hispanic_test
asian_test
aian_test
nhpi_test


# ============================================================
# 13. CREATE A T-TEST SUMMARY TABLE
# ============================================================

# Combine the race-specific t-test results into one table.
#
# Benjamini-Hochberg adjusted p-values are included to account
# for conducting multiple race-specific tests.

t_test_summary <- tibble(
  race = c(
    "White",
    "Black/African American",
    "Hispanic/Latino/Spanish Origins",
    "Asian",
    "American Indian/Alaskan Native",
    "Native Hawaiian/Pacific Islander"
  ),
  
  mean_gap = c(
    unname(white_test$estimate),
    unname(black_test$estimate),
    unname(hispanic_test$estimate),
    unname(asian_test$estimate),
    unname(aian_test$estimate),
    unname(nhpi_test$estimate)
  ),
  
  confidence_interval_lower = c(
    white_test$conf.int[1],
    black_test$conf.int[1],
    hispanic_test$conf.int[1],
    asian_test$conf.int[1],
    aian_test$conf.int[1],
    nhpi_test$conf.int[1]
  ),
  
  confidence_interval_upper = c(
    white_test$conf.int[2],
    black_test$conf.int[2],
    hispanic_test$conf.int[2],
    asian_test$conf.int[2],
    aian_test$conf.int[2],
    nhpi_test$conf.int[2]
  ),
  
  t_statistic = c(
    unname(white_test$statistic),
    unname(black_test$statistic),
    unname(hispanic_test$statistic),
    unname(asian_test$statistic),
    unname(aian_test$statistic),
    unname(nhpi_test$statistic)
  ),
  
  degrees_freedom = c(
    unname(white_test$parameter),
    unname(black_test$parameter),
    unname(hispanic_test$parameter),
    unname(asian_test$parameter),
    unname(aian_test$parameter),
    unname(nhpi_test$parameter)
  ),
  
  p_value = c(
    white_test$p.value,
    black_test$p.value,
    hispanic_test$p.value,
    asian_test$p.value,
    aian_test$p.value,
    nhpi_test$p.value
  )
) %>%
  mutate(
    p_value_adjusted_bh = p.adjust(
      p_value,
      method = "BH"
    ),
    
    significant_unadjusted = p_value < 0.05,
    
    significant_after_adjustment =
      p_value_adjusted_bh < 0.05
  ) %>%
  arrange(p_value)

View(t_test_summary)


# ============================================================
# 14. CALCULATE EXPECTED COUNTS
# ============================================================

# The expected count is the number of people from a demographic
# group that would be expected in the court's adjusted jury pool
# if the jury-pool percentage matched the county percentage.

expected_count_data <- overall_pool %>%
  mutate(
    population_proportion =
      county_population_pct / 100,
    
    expected_count =
      adjusted_total * population_proportion
  )

View(expected_count_data)


# ============================================================
# 15. BINOMIAL STANDARD-DEVIATION ANALYSIS
# ============================================================

# This analysis follows the standard-deviation approach discussed
# in State v. Lilly (2019).
#
# It evaluates each demographic group independently within each
# court.
#
# For each court and group:
#
#   1. Calculate the expected count.
#   2. Calculate the binomial standard deviation.
#   3. Determine how many standard deviations the observed count
#      is above or below the expected count.
#
# Binomial standard deviation:
#
#   sqrt(n × p × (1 - p))
#
# where:
#
#   n = adjusted jury-pool total
#   p = county population proportion for the group
#
# Standardized difference:
#
#   (observed count - expected count) /
#   expected binomial standard deviation
#
# Negative values indicate underrepresentation.
# Positive values indicate overrepresentation.
#
# The one-standard-deviation threshold reflects the threshold
# discussed in State v. Lilly.
#
# The two-standard-deviation threshold is also retained as a
# more conservative statistical comparison.

standard_deviation_results <- expected_count_data %>%
  mutate(
    expected_binomial_sd = sqrt(
      adjusted_total *
        population_proportion *
        (1 - population_proportion)
    ),
    
    standardized_difference = if_else(
      expected_binomial_sd > 0,
      (jury_count - expected_count) /
        expected_binomial_sd,
      NA_real_
    ),
    
    below_expected_1sd =
      standardized_difference <= -1,
    
    below_expected_2sd =
      standardized_difference <= -2,
    
    above_expected_1sd =
      standardized_difference >= 1,
    
    above_expected_2sd =
      standardized_difference >= 2
  )

View(standard_deviation_results)


# Count rows where the standard-deviation calculation could not
# be performed because the county population percentage was zero.

sum(is.na(
  standard_deviation_results$standardized_difference
))


# ============================================================
# 16. STANDARD-DEVIATION SUMMARY BY RACE
# ============================================================

# Summarize how many courts fall below the expected count by
# at least one or two binomial standard deviations.

standard_deviation_summary <- standard_deviation_results %>%
  group_by(race) %>%
  summarize(
    courts_tested =
      sum(!is.na(standardized_difference)),
    
    courts_below_1sd =
      sum(below_expected_1sd, na.rm = TRUE),
    
    percent_below_1sd =
      mean(below_expected_1sd, na.rm = TRUE) * 100,
    
    courts_below_2sd =
      sum(below_expected_2sd, na.rm = TRUE),
    
    percent_below_2sd =
      mean(below_expected_2sd, na.rm = TRUE) * 100,
    
    courts_above_1sd =
      sum(above_expected_1sd, na.rm = TRUE),
    
    percent_above_1sd =
      mean(above_expected_1sd, na.rm = TRUE) * 100,
    
    courts_above_2sd =
      sum(above_expected_2sd, na.rm = TRUE),
    
    percent_above_2sd =
      mean(above_expected_2sd, na.rm = TRUE) * 100,
    
    .groups = "drop"
  ) %>%
  arrange(desc(percent_below_1sd))

View(standard_deviation_summary)


# ============================================================
# 17. COURTS FLAGGED BELOW EXPECTED REPRESENTATION
# ============================================================

# Identify court and demographic combinations at least one
# standard deviation below the expected count.

courts_below_1sd <- standard_deviation_results %>%
  filter(below_expected_1sd) %>%
  select(
    court_number,
    county_name,
    race,
    adjusted_total,
    jury_count,
    expected_count,
    expected_binomial_sd,
    standardized_difference,
    jury_pool_pct,
    county_population_pct,
    representation_gap
  ) %>%
  arrange(race, standardized_difference)

View(courts_below_1sd)


# Identify court and demographic combinations at least two
# standard deviations below the expected count.

courts_below_2sd <- standard_deviation_results %>%
  filter(below_expected_2sd) %>%
  select(
    court_number,
    county_name,
    race,
    adjusted_total,
    jury_count,
    expected_count,
    expected_binomial_sd,
    standardized_difference,
    jury_pool_pct,
    county_population_pct,
    representation_gap
  ) %>%
  arrange(race, standardized_difference)

View(courts_below_2sd)


# ============================================================
# 18. CREATE A COURT-LEVEL FLAG SUMMARY
# ============================================================

# This table shows how many demographic groups were flagged
# within each court.
#
# Lee County's two courts remain separate because court_number
# is used as part of the grouping.

court_flag_summary <- standard_deviation_results %>%
  group_by(court_number, county_name) %>%
  summarize(
    groups_tested =
      sum(!is.na(standardized_difference)),
    
    groups_below_1sd =
      sum(below_expected_1sd, na.rm = TRUE),
    
    groups_below_2sd =
      sum(below_expected_2sd, na.rm = TRUE),
    
    groups_above_1sd =
      sum(above_expected_1sd, na.rm = TRUE),
    
    groups_above_2sd =
      sum(above_expected_2sd, na.rm = TRUE),
    
    .groups = "drop"
  ) %>%
  arrange(
    desc(groups_below_1sd),
    county_name,
    court_number
  )

View(court_flag_summary)


# ============================================================
# 19. EXPORT FINAL DATASETS FOR TABLEAU AND REPORTING
# ============================================================

# Create the output folder if it does not already exist.

dir.create(
  "data/processed",
  recursive = TRUE,
  showWarnings = FALSE
)


# Detailed court-by-demographic dataset.
#
# This is the primary Tableau data source. It contains:
#
#   jury and census percentages
#   representation gaps
#   observed and expected counts
#   binomial standard deviations
#   standardized differences
#   one- and two-standard-deviation flags

write_csv(
  standard_deviation_results,
  "data/processed/overall_pool_final.csv"
)


# Descriptive statistics by demographic group.

write_csv(
  race_summary,
  "data/processed/race_summary.csv"
)


# Mean absolute error by demographic group.

write_csv(
  mae_by_race,
  "data/processed/mae_by_race.csv"
)


# Pearson correlation by demographic group.

write_csv(
  correlation_by_race,
  "data/processed/correlation_by_race.csv"
)


# T-test estimates, confidence intervals, and adjusted p-values.

write_csv(
  t_test_summary,
  "data/processed/t_test_summary.csv"
)


# Summary of one- and two-standard-deviation results by group.

write_csv(
  standard_deviation_summary,
  "data/processed/standard_deviation_summary.csv"
)


# Detailed court and group combinations below one standard
# deviation from the expected count.

write_csv(
  courts_below_1sd,
  "data/processed/courts_below_1sd.csv"
)


# Detailed court and group combinations below two standard
# deviations from the expected count.

write_csv(
  courts_below_2sd,
  "data/processed/courts_below_2sd.csv"
)


# Number of demographic groups flagged within each court.

write_csv(
  court_flag_summary,
  "data/processed/court_flag_summary.csv"
)


# ============================================================
# 20. FINAL OUTPUT CHECK
# ============================================================

# Confirm that the expected files were created successfully.

list.files(
  "data/processed",
  pattern = "\\.csv$"
)
  row.names = FALSE
)

write.csv(
  race_summary,
  "race_summary.csv",
  row.names = FALSE
)

write.csv(
  standard_deviation_results,
  "standard_deviation_results.csv",
  row.names = FALSE
)

write.csv(
  courts_below_1sd,
  "courts_below_1sd.csv",
  row.names = FALSE
)

