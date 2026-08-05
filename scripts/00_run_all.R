# ============================================================
# IOWA JURY POOL ANALYSIS
# FINAL RESULTS AND TABLE EXPORTS
# ============================================================
#
# 1. Data preparation and validation
# 2. Overall summary statistics
# 3. Race-level representation results
# 4. Mean absolute error
# 5. One-sample t-tests
# 6. Exact one-sided binomial tests
# 7. Monte Carlo tests
# 8. Court-level flags and final exports
#
# The analysis includes seven demographic categories:
#   White
#   Black/African American
#   Hispanic/Latino/Spanish Origins
#   Multiracial
#   Asian
#   American Indian/Alaskan Native
#   Native Hawaiian/Pacific Islander
#
# Multiracial observations are included in the analysis.
# However, these results should be interpreted cautiously
# because the Multiracial category may not be defined
# consistently across the jury and Census datasets.
#
# Hispanic/Latino/Spanish Origins is an ethnicity category and
# may overlap conceptually with the race categories. It is
# analyzed independently and should not be added to the race
# percentages to create a total demographic distribution.
# ============================================================


# ============================================================
# LOAD REQUIRED PACKAGES
# ============================================================

library(tidyverse)


# ============================================================
# CREATE OUTPUT FOLDERS
# ============================================================
# These commands create the folders only if they do not
# already exist.

dir.create(
  "outputs",
  recursive = TRUE,
  showWarnings = FALSE
)

dir.create(
  "outputs/tables",
  recursive = TRUE,
  showWarnings = FALSE
)

dir.create(
  "outputs/figures",
  recursive = TRUE,
  showWarnings = FALSE
)


# ============================================================
# 1. IMPORT AND PREPARE THE ANALYTICAL DATA
# ============================================================

main_analytics_view <- read_csv(
  "data/processed/new_main_view.csv",
  col_types = cols(
    court_number = col_character()
  )
)


# ------------------------------------------------------------
# Prepare the Overall Pool dataset
# ------------------------------------------------------------

overall_pool <- main_analytics_view %>%
  filter(
    dataset == "Overall Pool"
  ) %>%
  select(
    -result_status
  ) %>%
  mutate(
    court_number = as.character(court_number)
  ) %>%
  rename(
    adjusted_total = adj_total,
    jury_pool_pct = jury_pct,
    county_population_pct = census_pct,
    representation_gap = pt_diff
  )


# ------------------------------------------------------------
# Confirm required columns exist
# ------------------------------------------------------------

required_columns <- c(
  "court_number",
  "county_name",
  "dataset",
  "race",
  "adjusted_total",
  "jury_count",
  "jury_pool_pct",
  "county_population_pct",
  "representation_gap"
)

missing_columns <- setdiff(
  required_columns,
  names(overall_pool)
)

if (length(missing_columns) > 0) {
  stop(
    paste(
      "The following required columns are missing:",
      paste(missing_columns, collapse = ", ")
    )
  )
}


# ------------------------------------------------------------
# Check for missing or invalid values
# ------------------------------------------------------------

invalid_value_check <- overall_pool %>%
  filter(
    is.na(adjusted_total) |
      is.na(jury_count) |
      is.na(county_population_pct) |
      adjusted_total < 0 |
      jury_count < 0 |
      jury_count > adjusted_total |
      county_population_pct < 0 |
      county_population_pct > 100
  )

invalid_value_check

if (nrow(invalid_value_check) > 0) {
  warning(
    paste(
      nrow(invalid_value_check),
      "rows contain missing or invalid values."
    )
  )
}


# ------------------------------------------------------------
# Check that adjusted_total is consistent within each court
# ------------------------------------------------------------
# adjusted_total should be identical across the demographic
# rows belonging to the same court.
#
# Zero returned rows means this check was satisfied.

adjusted_total_check <- overall_pool %>%
  group_by(
    court_number,
    county_name
  ) %>%
  summarize(
    number_of_totals =
      n_distinct(adjusted_total),
    
    minimum_total =
      min(adjusted_total, na.rm = TRUE),
    
    maximum_total =
      max(adjusted_total, na.rm = TRUE),
    
    .groups = "drop"
  ) %>%
  filter(
    number_of_totals != 1
  )

adjusted_total_check


# ------------------------------------------------------------
# Check for duplicate court-race observations
# ------------------------------------------------------------
# Each court and demographic group should have one Overall Pool
# row.
#
# Zero returned rows means this check was satisfied.

duplicate_check <- overall_pool %>%
  count(
    court_number,
    county_name,
    race,
    name = "number_of_rows"
  ) %>%
  filter(
    number_of_rows > 1
  )

duplicate_check


# ------------------------------------------------------------
# Create a testing-ready dataset
# ------------------------------------------------------------
# Statistical tests require a valid total, observed count, and
# Census percentage.

overall_pool_testable <- overall_pool %>%
  filter(
    !is.na(adjusted_total),
    !is.na(jury_count),
    !is.na(county_population_pct),
    adjusted_total > 0,
    jury_count >= 0,
    jury_count <= adjusted_total,
    county_population_pct >= 0,
    county_population_pct <= 100
  )


# ============================================================
# 2. OVERALL SUMMARY STATISTICS
# ============================================================
# Representation gap:
#
#   Jury pool percentage - county population percentage
#
# Positive values indicate overrepresentation.
# Negative values indicate underrepresentation.

overall_results_summary <- tibble(
  metric = c(
    "Number of observations",
    "Number of courts",
    "Number of demographic groups",
    "Mean representation gap",
    "Median representation gap",
    "Mean absolute error (MAE)",
    "Standard deviation",
    "Minimum representation gap",
    "Maximum representation gap",
    "Pearson correlation"
  ),
  
  value = c(
    sum(!is.na(overall_pool$representation_gap)),
    
    n_distinct(
      overall_pool$court_number
    ),
    
    n_distinct(
      overall_pool$race
    ),
    
    mean(
      overall_pool$representation_gap,
      na.rm = TRUE
    ),
    
    median(
      overall_pool$representation_gap,
      na.rm = TRUE
    ),
    
    mean(
      abs(overall_pool$representation_gap),
      na.rm = TRUE
    ),
    
    sd(
      overall_pool$representation_gap,
      na.rm = TRUE
    ),
    
    min(
      overall_pool$representation_gap,
      na.rm = TRUE
    ),
    
    max(
      overall_pool$representation_gap,
      na.rm = TRUE
    ),
    
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
# 3. RACE-LEVEL REPRESENTATION RESULTS
# ============================================================

race_level_summary <- overall_pool %>%
  group_by(
    race
  ) %>%
  summarize(
    observations =
      sum(!is.na(representation_gap)),
    
    courts =
      n_distinct(court_number),
    
    mean_jury_pool_pct =
      mean(
        jury_pool_pct,
        na.rm = TRUE
      ),
    
    mean_county_population_pct =
      mean(
        county_population_pct,
        na.rm = TRUE
      ),
    
    mean_gap =
      mean(
        representation_gap,
        na.rm = TRUE
      ),
    
    median_gap =
      median(
        representation_gap,
        na.rm = TRUE
      ),
    
    minimum_gap =
      min(
        representation_gap,
        na.rm = TRUE
      ),
    
    maximum_gap =
      max(
        representation_gap,
        na.rm = TRUE
      ),
    
    standard_deviation =
      sd(
        representation_gap,
        na.rm = TRUE
      ),
    
    correlation =
      cor(
        jury_pool_pct,
        county_population_pct,
        use = "complete.obs",
        method = "pearson"
      ),
    
    .groups = "drop"
  ) %>%
  arrange(
    mean_gap
  )

race_level_summary

View(race_level_summary)


# ============================================================
# 4. MEAN ABSOLUTE ERROR
# ============================================================
# MAE measures the average absolute difference between the jury
# pool percentage and county population percentage.
#
# Because absolute values are used, MAE measures the size of
# the mismatch but not its direction.

mae_summary <- overall_pool %>%
  group_by(
    race
  ) %>%
  summarize(
    observations =
      sum(!is.na(representation_gap)),
    
    mean_absolute_error =
      mean(
        abs(representation_gap),
        na.rm = TRUE
      ),
    
    median_absolute_error =
      median(
        abs(representation_gap),
        na.rm = TRUE
      ),
    
    maximum_absolute_error =
      max(
        abs(representation_gap),
        na.rm = TRUE
      ),
    
    .groups = "drop"
  ) %>%
  arrange(
    desc(mean_absolute_error)
  )

mae_summary

View(mae_summary)


# ============================================================
# 5. ONE-SAMPLE T-TESTS
# ============================================================
# These one-sample t-tests evaluate whether the average
# representation gap across courts differs significantly from
# zero.
#
# Null hypothesis:
#   Mean representation gap = 0
#
# Alternative hypothesis:
#   Mean representation gap != 0
#
# These are two-sided tests.
#
# Negative mean gaps indicate average underrepresentation.
# Positive mean gaps indicate average overrepresentation.
#
# Important limitations:
#
# 1. Each court receives equal weight regardless of jury-pool
#    size.
#
# 2. The tests evaluate average differences across courts, not
#    whether a specific demographic group is underrepresented
#    within a specific court.
#
# 3. No multiple-comparison adjustment is applied because the
#    t-tests are secondary and exploratory.
#
# The primary court-level inferential analyses are the exact
# one-sided binomial and Monte Carlo tests.


# ------------------------------------------------------------
# Overall t-test
# ------------------------------------------------------------

overall_t_test <- t.test(
  overall_pool$representation_gap,
  mu = 0,
  alternative = "two.sided"
)

overall_t_test_summary <- tibble(
  analysis =
    "All demographic groups combined",
  
  observations =
    sum(
      !is.na(overall_pool$representation_gap)
    ),
  
  mean_gap =
    as.numeric(
      overall_t_test$estimate
    ),
  
  confidence_interval_lower =
    overall_t_test$conf.int[1],
  
  confidence_interval_upper =
    overall_t_test$conf.int[2],
  
  t_statistic =
    as.numeric(
      overall_t_test$statistic
    ),
  
  degrees_freedom =
    as.numeric(
      overall_t_test$parameter
    ),
  
  p_value =
    overall_t_test$p.value
) %>%
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
  )

overall_t_test_summary

View(overall_t_test_summary)


# ------------------------------------------------------------
# Race-specific t-tests
# ------------------------------------------------------------

t_test_summary_by_race <- overall_pool %>%
  filter(
    !is.na(representation_gap)
  ) %>%
  group_by(
    race
  ) %>%
  group_modify(
    ~ {
      
      test_result <- t.test(
        .x$representation_gap,
        mu = 0,
        alternative = "two.sided"
      )
      
      tibble(
        courts_analyzed =
          sum(
            !is.na(.x$representation_gap)
          ),
        
        mean_gap =
          as.numeric(
            test_result$estimate
          ),
        
        confidence_interval_lower =
          test_result$conf.int[1],
        
        confidence_interval_upper =
          test_result$conf.int[2],
        
        t_statistic =
          as.numeric(
            test_result$statistic
          ),
        
        degrees_freedom =
          as.numeric(
            test_result$parameter
          ),
        
        p_value =
          test_result$p.value
      )
    }
  ) %>%
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
  arrange(
    mean_gap
  )

t_test_summary_by_race

View(t_test_summary_by_race)


# ============================================================
# 6. EXACT ONE-SIDED BINOMIAL TESTS
# ============================================================
# For each demographic group within each court:
#
# Null hypothesis:
#   Jury pool proportion = county population proportion
#
# Alternative hypothesis:
#   Jury pool proportion < county population proportion
#
# pbinom() calculates the probability of observing the reported
# jury count or fewer under the null hypothesis.
#
# A small p-value indicates that the observed count would be
# unusually low if the jury pool followed the county population
# proportion.
#
# Statistical significance threshold:
#   p-value < 0.05
#
# Additional descriptive thresholds provided by the professor:
#
#   p-value < 0.16
#     Approximately below a one-standard-deviation threshold.
#
#   p-value < 0.025
#     Approximately below a two-standard-deviation threshold.


# ------------------------------------------------------------
# Calculate exact one-sided p-values
# ------------------------------------------------------------

binomial_results <- overall_pool_testable %>%
  mutate(
    census_probability =
      county_population_pct / 100,
    
    expected_count =
      adjusted_total *
      census_probability,
    
    observed_minus_expected =
      jury_count -
      expected_count,
    
    exact_p_value =
      pbinom(
        q = jury_count,
        size = adjusted_total,
        prob = census_probability,
        lower.tail = TRUE
      ),
    
    statistically_significant =
      exact_p_value < 0.05,
    
    below_expected_1sd =
      exact_p_value < 0.16,
    
    below_expected_2sd =
      exact_p_value < 0.025,
    
    binomial_result = case_when(
      statistically_significant &
        jury_count < expected_count ~
        "Significantly underrepresented",
      
      jury_count < expected_count ~
        "Below expected, not significant",
      
      jury_count == expected_count ~
        "Equal to expected",
      
      jury_count > expected_count ~
        "At or above expected",
      
      TRUE ~
        NA_character_
    )
  )

binomial_results

View(binomial_results)


# ------------------------------------------------------------
# Summarize exact binomial results by demographic group
# ------------------------------------------------------------

binomial_summary_by_race <- binomial_results %>%
  group_by(
    race
  ) %>%
  summarize(
    courts_tested =
      sum(
        !is.na(exact_p_value)
      ),
    
    courts_below_expected =
      sum(
        jury_count < expected_count,
        na.rm = TRUE
      ),
    
    courts_significantly_underrepresented =
      sum(
        statistically_significant &
          jury_count < expected_count,
        na.rm = TRUE
      ),
    
    percent_significantly_underrepresented =
      mean(
        statistically_significant &
          jury_count < expected_count,
        na.rm = TRUE
      ) * 100,
    
    courts_below_1sd =
      sum(
        below_expected_1sd,
        na.rm = TRUE
      ),
    
    percent_courts_below_1sd =
      mean(
        below_expected_1sd,
        na.rm = TRUE
      ) * 100,
    
    courts_below_2sd =
      sum(
        below_expected_2sd,
        na.rm = TRUE
      ),
    
    percent_courts_below_2sd =
      mean(
        below_expected_2sd,
        na.rm = TRUE
      ) * 100,
    
    median_exact_p_value =
      median(
        exact_p_value,
        na.rm = TRUE
      ),
    
    .groups = "drop"
  ) %>%
  arrange(
    desc(
      percent_significantly_underrepresented
    )
  )

binomial_summary_by_race

View(binomial_summary_by_race)


# ============================================================
# 7. MONTE CARLO TESTS
# ============================================================
# This section uses a simulation-based version of the same
# one-sided test.
#
# For each demographic group within each court:
#
# Null hypothesis:
#   Jury pool proportion = county population proportion
#
# Alternative hypothesis:
#   Jury pool proportion < county population proportion
#
# For every court-race observation, 10,000 jury-pool counts are
# simulated under the Census-based null probability.
#
# The Monte Carlo p-value is the proportion of simulated counts
# that are less than or equal to the observed jury count.
#
# The +1 correction in the numerator and denominator prevents a
# simulated p-value of exactly zero and produces a valid Monte
# Carlo estimate.


# ------------------------------------------------------------
# Set simulation options
# ------------------------------------------------------------

set.seed(230)

number_of_simulations <- 10000


# ------------------------------------------------------------
# Run the Monte Carlo tests
# ------------------------------------------------------------

monte_carlo_results <- overall_pool_testable %>%
  rowwise() %>%
  mutate(
    census_probability =
      county_population_pct / 100,
    
    expected_count =
      adjusted_total *
      census_probability,
    
    simulated_counts = list(
      rbinom(
        n = number_of_simulations,
        size = adjusted_total,
        prob = census_probability
      )
    ),
    
    monte_carlo_p_value =
      (
        sum(
          unlist(simulated_counts) <= jury_count
        ) + 1
      ) /
      (
        number_of_simulations + 1
      ),
    
    statistically_significant =
      monte_carlo_p_value < 0.05,
    
    monte_carlo_result = case_when(
      statistically_significant &
        jury_count < expected_count ~
        "Significantly underrepresented",
      
      jury_count < expected_count ~
        "Below expected, not significant",
      
      jury_count == expected_count ~
        "Equal to expected",
      
      jury_count > expected_count ~
        "At or above expected",
      
      TRUE ~
        NA_character_
    )
  ) %>%
  select(
    -simulated_counts
  ) %>%
  ungroup()

monte_carlo_results

View(monte_carlo_results)


# ------------------------------------------------------------
# Summarize Monte Carlo results by demographic group
# ------------------------------------------------------------

monte_carlo_summary_by_race <- monte_carlo_results %>%
  group_by(
    race
  ) %>%
  summarize(
    courts_tested =
      sum(
        !is.na(monte_carlo_p_value)
      ),
    
    courts_below_expected =
      sum(
        jury_count < expected_count,
        na.rm = TRUE
      ),
    
    significant_underrepresentation =
      sum(
        statistically_significant &
          jury_count < expected_count,
        na.rm = TRUE
      ),
    
    percent_significant_underrepresentation =
      mean(
        statistically_significant &
          jury_count < expected_count,
        na.rm = TRUE
      ) * 100,
    
    median_monte_carlo_p_value =
      median(
        monte_carlo_p_value,
        na.rm = TRUE
      ),
    
    minimum_monte_carlo_p_value =
      min(
        monte_carlo_p_value,
        na.rm = TRUE
      ),
    
    maximum_monte_carlo_p_value =
      max(
        monte_carlo_p_value,
        na.rm = TRUE
      ),
    
    .groups = "drop"
  ) %>%
  arrange(
    desc(
      percent_significant_underrepresentation
    )
  )

monte_carlo_summary_by_race

View(monte_carlo_summary_by_race)


# ------------------------------------------------------------
# Compare exact binomial and Monte Carlo results
# ------------------------------------------------------------

test_method_comparison <- binomial_results %>%
  select(
    court_number,
    county_name,
    race,
    adjusted_total,
    jury_count,
    jury_pool_pct,
    county_population_pct,
    expected_count,
    exact_p_value,
    exact_significant =
      statistically_significant
  ) %>%
  left_join(
    monte_carlo_results %>%
      select(
        court_number,
        county_name,
        race,
        monte_carlo_p_value,
        monte_carlo_significant =
          statistically_significant
      ),
    
    by = c(
      "court_number",
      "county_name",
      "race"
    )
  ) %>%
  mutate(
    absolute_p_value_difference =
      abs(
        exact_p_value -
          monte_carlo_p_value
      ),
    
    methods_agree =
      exact_significant ==
      monte_carlo_significant,
    
    comparison_result = case_when(
      methods_agree ~
        "Methods agree",
      
      !methods_agree ~
        "Methods differ",
      
      TRUE ~
        NA_character_
    )
  ) %>%
  arrange(
    desc(
      absolute_p_value_difference
    )
  )

test_method_comparison

View(test_method_comparison)


# ------------------------------------------------------------
# Overall comparison between the two methods
# ------------------------------------------------------------

test_comparison_summary <- test_method_comparison %>%
  summarize(
    observations_compared =
      sum(
        !is.na(methods_agree)
      ),
    
    number_methods_agree =
      sum(
        methods_agree,
        na.rm = TRUE
      ),
    
    number_methods_differ =
      sum(
        !methods_agree,
        na.rm = TRUE
      ),
    
    percent_agreement =
      mean(
        methods_agree,
        na.rm = TRUE
      ) * 100,
    
    mean_absolute_p_value_difference =
      mean(
        absolute_p_value_difference,
        na.rm = TRUE
      ),
    
    median_absolute_p_value_difference =
      median(
        absolute_p_value_difference,
        na.rm = TRUE
      ),
    
    maximum_absolute_p_value_difference =
      max(
        absolute_p_value_difference,
        na.rm = TRUE
      )
  )

test_comparison_summary

View(test_comparison_summary)


# ============================================================
# 8. COURT-LEVEL FLAGS
# ============================================================
# This section summarizes how many demographic groups within
# each court were flagged by the exact binomial analysis.


# ------------------------------------------------------------
# Court-level exact binomial flags
# ------------------------------------------------------------

court_flag_summary <- binomial_results %>%
  group_by(
    court_number,
    county_name
  ) %>%
  summarize(
    demographic_groups_tested =
      sum(
        !is.na(exact_p_value)
      ),
    
    groups_below_expected =
      sum(
        jury_count < expected_count,
        na.rm = TRUE
      ),
    
    groups_significantly_underrepresented =
      sum(
        statistically_significant &
          jury_count < expected_count,
        na.rm = TRUE
      ),
    
    percent_groups_significantly_underrepresented =
      mean(
        statistically_significant &
          jury_count < expected_count,
        na.rm = TRUE
      ) * 100,
    
    groups_below_1sd =
      sum(
        below_expected_1sd,
        na.rm = TRUE
      ),
    
    groups_below_2sd =
      sum(
        below_expected_2sd,
        na.rm = TRUE
      ),
    
    percent_groups_below_1sd =
      mean(
        below_expected_1sd,
        na.rm = TRUE
      ) * 100,
    
    percent_groups_below_2sd =
      mean(
        below_expected_2sd,
        na.rm = TRUE
      ) * 100,
    
    .groups = "drop"
  ) %>%
  arrange(
    desc(
      groups_significantly_underrepresented
    ),
    desc(
      groups_below_2sd
    ),
    desc(
      groups_below_1sd
    )
  )

court_flag_summary

View(court_flag_summary)


# ------------------------------------------------------------
# Detailed list of significant exact binomial results
# ------------------------------------------------------------

significant_underrepresentation_results <- binomial_results %>%
  filter(
    statistically_significant,
    jury_count < expected_count
  ) %>%
  select(
    court_number,
    county_name,
    race,
    adjusted_total,
    jury_count,
    expected_count,
    jury_pool_pct,
    county_population_pct,
    representation_gap,
    exact_p_value
  ) %>%
  arrange(
    exact_p_value,
    representation_gap
  )

significant_underrepresentation_results

View(significant_underrepresentation_results)


# ============================================================
# FINAL TABLE EXPORTS
# ============================================================
# All analytical tables are exported to outputs/tables.


# ------------------------------------------------------------
# Data-quality checks
# ------------------------------------------------------------

write_csv(
  adjusted_total_check,
  "outputs/tables/adjusted_total_check.csv"
)

write_csv(
  duplicate_check,
  "outputs/tables/duplicate_check.csv"
)

write_csv(
  invalid_value_check,
  "outputs/tables/invalid_value_check.csv"
)


# ------------------------------------------------------------
# Descriptive results
# ------------------------------------------------------------

write_csv(
  overall_results_summary,
  "outputs/tables/overall_results_summary.csv"
)

write_csv(
  race_level_summary,
  "outputs/tables/race_level_summary.csv"
)

write_csv(
  mae_summary,
  "outputs/tables/mae_summary.csv"
)


# ------------------------------------------------------------
# T-test results
# ------------------------------------------------------------

write_csv(
  overall_t_test_summary,
  "outputs/tables/overall_t_test_summary.csv"
)

write_csv(
  t_test_summary_by_race,
  "outputs/tables/t_test_summary_by_race.csv"
)


# ------------------------------------------------------------
# Exact binomial results
# ------------------------------------------------------------

write_csv(
  binomial_results,
  "outputs/tables/binomial_results.csv"
)

write_csv(
  binomial_summary_by_race,
  "outputs/tables/binomial_summary_by_race.csv"
)

write_csv(
  court_flag_summary,
  "outputs/tables/court_flag_summary.csv"
)

write_csv(
  significant_underrepresentation_results,
  paste0(
    "outputs/tables/",
    "significant_underrepresentation_results.csv"
  )
)


# ------------------------------------------------------------
# Monte Carlo results
# ------------------------------------------------------------

write_csv(
  monte_carlo_results,
  "outputs/tables/monte_carlo_results.csv"
)

write_csv(
  monte_carlo_summary_by_race,
  "outputs/tables/monte_carlo_summary_by_race.csv"
)


# ------------------------------------------------------------
# Method-comparison results
# ------------------------------------------------------------

write_csv(
  test_method_comparison,
  "outputs/tables/binomial_monte_carlo_comparison.csv"
)

write_csv(
  test_comparison_summary,
  "outputs/tables/test_comparison_summary.csv"
)


# ============================================================
# COMPLETION MESSAGE
# ============================================================

cat("\n")
cat("===============================================\n")
cat("Iowa jury pool analysis complete.\n")
cat("Tables exported to: outputs/tables\n")
cat("Monte Carlo simulations per test: ",
    number_of_simulations,
    "\n",
    sep = "")
cat("===============================================\n")