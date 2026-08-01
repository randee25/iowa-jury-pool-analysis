# ============================================================
# IOWA JURY POOL ANALYSIS:
# FINAL RESULTS AND VISUALIZATION EXPORTS
# ============================================================
#   1. Overall summary statistics
#   2. Race-level representation results
#   3. Mean absolute error
#   4. One-sample t-tests
#   5. Binomial probabilities
#   6. Equivalent standardized differences
#   7. Court-level flags
#   8. Final Tableau exports

# The analysis includes six demographic categories:
#   White
#   Black/African American
#   Hispanic/Latino/Spanish Origins
#   Asian
#   American Indian/Alaskan Native
#   Native Hawaiian/Pacific Islander
#
# Multiracial observations are not included because they were
# not represented consistently across the available datasets.
#
# Hispanic/Latino/Spanish Origins is an ethnicity category and
# may overlap conceptually with race categories. It is analyzed
# independently and should not be added to the race percentages
# to create a total distribution.
# ============================================================
# LOAD REQUIRED PACKAGE
library(tidyverse)
#  IMPORT THE PRIMARY ANALYTICAL DATASET
main_analytics_view <- read_csv(
  "data/processed/main_analytics_view.csv",
  col_types = cols(
    court_number = col_character()
  ))
# PREPARE THE OVERALL JURY POOL DATA
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
# adjusted_total should be identical across all demographic rows
# for the same court.
#
# Zero returned rows means the check was satisfied.

adjusted_total_check <- overall_pool %>%
  group_by(court_number, county_name) %>%
  summarize(
    number_of_totals = n_distinct(adjusted_total),
    minimum_total = min(adjusted_total, na.rm = TRUE),
    maximum_total = max(adjusted_total, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  filter(number_of_totals != 1)

adjusted_total_check
# ============================================================
# 1. OVERALL SUMMARY STATISTICS
# ============================================================
# Representation gap:
# Jury pool percentage − county population percentage
# Positive values indicate overrepresentation.
# Negative values indicate underrepresentation.

overall_results_summary <- tibble(
  
  metric = c(
    "Number of observations",
    "Number of courts",
    "Mean representation gap",
    "Median representation gap",
    "Mean absolute error (MAE)",
    "Standard deviation",
    "Pearson correlation"
  ),
  
  value = c(
    sum(!is.na(overall_pool$representation_gap)),
    n_distinct(overall_pool$court_number),
    mean(overall_pool$representation_gap, na.rm = TRUE),
    median(overall_pool$representation_gap, na.rm = TRUE),
    mean(abs(overall_pool$representation_gap), na.rm = TRUE),
    sd(overall_pool$representation_gap, na.rm = TRUE),
    cor(
      overall_pool$jury_pool_pct,
      overall_pool$county_population_pct,
      use = "complete.obs",
      method = "pearson"
    )
  )
)

overall_results_summary
View(overall_results_summary)
# ============================================================
# 2. RACE-LEVEL REPRESENTATION RESULTS
# ============================================================
race_level_summary <- overall_pool %>%
  group_by(race) %>%
  summarize(
    
    observations = n(),
    
    mean_gap =
      mean(representation_gap, na.rm = TRUE),
    
    median_gap =
      median(representation_gap, na.rm = TRUE),
    
    minimum_gap =
      min(representation_gap, na.rm = TRUE),
    
    maximum_gap =
      max(representation_gap, na.rm = TRUE),
    
    standard_deviation =
      sd(representation_gap, na.rm = TRUE),
    
    correlation =
      cor(
        jury_pool_pct,
        county_population_pct,
        use = "complete.obs"
      ),
    
    .groups = "drop"
  )

race_level_summary
View(race_level_summary)
# ============================================================
# 3. MEAN ABSOLUTE ERROR (MAE)
# ============================================================
mae_summary <- overall_pool %>%
  group_by(race) %>%
  summarize(
    mean_absolute_error =
      mean(abs(representation_gap), na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(mean_absolute_error))

mae_summary

View(mae_summary)
# ============================================================
# 4. ONE-SAMPLE T-TESTS
# ============================================================
# Each one-sample t-test evaluates whether the average
# representation gap across courts differs significantly from
# zero.
#
# Null hypothesis:
#   The mean representation gap equals zero.
#
# Alternative hypothesis:
#   The mean representation gap differs from zero.
#
# Negative values indicate average underrepresentation.
# Positive values indicate average overrepresentation.
#
# Important limitation:
# Each court receives equal weight regardless of the size of
# the jury pool.
#
# Note:
# No adjustment for multiple comparisons was applied because
# the t-tests are intended as descriptive and exploratory
# analyses rather than the primary measure of
# representativeness. The principal analysis relies on the
# binomial probability and standardized-difference methods.


# Overall t-test
overall_t_test <- t.test(
  overall_pool$representation_gap,
  mu = 0
)

overall_t_test_summary <- tibble(
  analysis = "All demographic groups combined",
  
  mean_gap =
    as.numeric(overall_t_test$estimate),
  
  confidence_interval_lower =
    overall_t_test$conf.int[1],
  
  confidence_interval_upper =
    overall_t_test$conf.int[2],
  
  t_statistic =
    as.numeric(overall_t_test$statistic),
  
  degrees_freedom =
    as.numeric(overall_t_test$parameter),
  
  p_value =
    overall_t_test$p.value
) %>%
  mutate(
    statistically_significant = p_value < 0.05,
    
    average_direction = case_when(
      mean_gap < 0 ~
        "Underrepresented on average",
      
      mean_gap > 0 ~
        "Overrepresented on average",
      
      TRUE ~
        "No average difference"
    )
  )

overall_t_test_summary

View(overall_t_test_summary)


# ------------------------------------------------------------
# Race-specific t-tests
# ------------------------------------------------------------

t_test_summary_by_race <- overall_pool %>%
  group_by(race) %>%
  group_modify(~ {
    
    test_result <- t.test(
      .x$representation_gap,
      mu = 0
    )
    
    tibble(
      courts_analyzed =
        sum(!is.na(.x$representation_gap)),
      
      mean_gap =
        as.numeric(test_result$estimate),
      
      confidence_interval_lower =
        test_result$conf.int[1],
      
      confidence_interval_upper =
        test_result$conf.int[2],
      
      t_statistic =
        as.numeric(test_result$statistic),
      
      degrees_freedom =
        as.numeric(test_result$parameter),
      
      p_value =
        test_result$p.value
    )
  }) %>%
  ungroup() %>%
  mutate(
    statistically_significant =
      p_value < 0.05,
    
    average_direction = case_when(
      mean_gap < 0 ~
        "Underrepresented on average",
      
      mean_gap > 0 ~
        "Overrepresented on average",
      
      TRUE ~
        "No average difference"
    )
  ) %>%
  arrange(mean_gap)

t_test_summary_by_race
View(t_test_summary_by_race)
# ============================================================
# 5. BINOMIAL PROBABILITIES
# ============================================================
# This section follows Professor Lovell's probability-based
# approach.
#
# For each demographic group within each court, pbinom()
# calculates the probability of observing the reported number
# of jurors or fewer, assuming that the jury pool reflects the
# county population proportion.
#
# Thresholds described by Professor Lovell:
# Probability < 0.16:
#   Below the approximate one-standard-deviation threshold.
#
# Probability < 0.025:
#   Below the approximate two-standard-deviation threshold.

probability_results <- overall_pool %>%
  mutate(
    expected_count =
      adjusted_total *
      (county_population_pct / 100),
    
    exact_probability =
      pbinom(
        q = jury_count,
        size = adjusted_total,
        prob = county_population_pct / 100
      ),
    
    below_expected_1sd =
      exact_probability < 0.16,
    
    below_expected_2sd =
      exact_probability < 0.025
  )
# Summarize the probability results by demographic group.
probability_summary_by_race <- probability_results %>%
  group_by(race) %>%
  summarize(
    courts_tested =
      sum(!is.na(exact_probability)),
    
    courts_below_1sd =
      sum(
        below_expected_1sd,
        na.rm = TRUE
      ),
    
    courts_below_2sd =
      sum(
        below_expected_2sd,
        na.rm = TRUE
      ),
    
    percent_courts_below_1sd =
      mean(
        below_expected_1sd,
        na.rm = TRUE
      ) * 100,
    
    percent_courts_below_2sd =
      mean(
        below_expected_2sd,
        na.rm = TRUE
      ) * 100,
    
    .groups = "drop"
  ) %>%
  arrange(
    desc(percent_courts_below_1sd)
  )

probability_summary_by_race
View(probability_summary_by_race)