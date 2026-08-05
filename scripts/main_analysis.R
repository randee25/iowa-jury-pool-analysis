# ============================================================
# IOWA JURY POOL ANALYSIS
# FINAL RESULTS AND TABLE EXPORTS
# ============================================================
#
# 1. Data preparation and validation
# 2. Overall summary statistics
# 3. Race-level representation results
# 4. One-sample t-tests
# 5. Exact one-sided binomial tests
# 6. Court-level flags and final exports
# 7. Monte Carlo tests
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
## Hispanic/Latino/Spanish origin is treated separately
# because the Census defines it as an ethnicity rather
# than a race. Individuals may identify as both Hispanic
# and a racial category (for example, White or Black),
# so these percentages should not be added to race-based
# percentages to create a total distribution.
#
# Because the Census and jury data may define Hispanic
# origin differently, results for this category should
# be interpreted cautiously.
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
#Jury pool percentage - county population percentage
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
    "Root mean squared error (RMSE)",
    "Percentage of gaps ≤ -5",
    "Percentage of gaps ≤ 5",
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
    
    sqrt(
      mean(
        overall_pool$representation_gap^2,
        na.rm = TRUE
      )
    ),
    
    mean(
      overall_pool$representation_gap <= -5,
      na.rm = TRUE
    )*100,
    
    mean(
      overall_pool$representation_gap >= 5,
      na.rm = TRUE
    )*100,
    
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
overall_results_summary <- overall_results_summary %>%
  mutate(
    across(
      where(is.numeric),
      ~ round(.x, 4)
    )
  )

View(overall_results_summary)
# ============================================================
# 3. RACE-LEVEL REPRESENTATION RESULTS
# ============================================================
# Representation gap:
# Jury pool percentage - county population percentage
#
# Positive values indicate overrepresentation.
# Negative values indicate underrepresentation.

race_level_summary <- overall_pool %>%
  mutate(
    race = recode(
      race,
      "HLSO Ethnicity" = "Hispanic/Latino"
    )
  ) %>%
  group_by(race) %>%
  summarize(
    
    mean_jury_pct = mean(
      jury_pool_pct,
      na.rm = TRUE
    ),
    
    mean_census_pct = mean(
      county_population_pct,
      na.rm = TRUE
    ),
    
    mean_gap = mean(
      representation_gap,
      na.rm = TRUE
    ),
    
    median_gap = median(
      representation_gap,
      na.rm = TRUE
    ),
    
    minimum_gap = min(
      representation_gap,
      na.rm = TRUE
    ),
    
    maximum_gap = max(
      representation_gap,
      na.rm = TRUE
    ),
    
    mae = mean(
      abs(representation_gap),
      na.rm = TRUE
    ),
    
    rmse = sqrt(
      mean(
        representation_gap^2,
        na.rm = TRUE
      )
    ),
    
    standard_deviation = sd(
      representation_gap,
      na.rm = TRUE
    ),
    
    pearson_correlation = cor(
      jury_pool_pct,
      county_population_pct,
      use = "complete.obs",
      method = "pearson"
    ),
    
    .groups = "drop"
  ) %>%
  arrange(mean_gap)

race_level_summary <- race_level_summary %>%
  mutate(
    across(
      where(is.numeric),
      ~ round(.x, 4)
    )
  )

View(race_level_summary)
# ============================================================
# 4. ONE-SAMPLE T-TESTS
# ============================================================
# These one-sample t-tests evaluate whether the average
# representation gap differs significantly from zero.
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
# 4. The overall test combines all court-group observations and
#    should be interpreted cautiously because each court appears
#    once for every demographic group.
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

overall_t_test_row <- tibble(
  group = "Overall",
  
  observations = sum(
    !is.na(overall_pool$representation_gap)
  ),
  
  mean_gap = as.numeric(
    overall_t_test$estimate
  ),
  
  confidence_interval_lower =
    overall_t_test$conf.int[1],
  
  confidence_interval_upper =
    overall_t_test$conf.int[2],
  
  t_statistic = as.numeric(
    overall_t_test$statistic
  ),
  
  p_value =
    overall_t_test$p.value,
  
  statistically_significant =
    overall_t_test$p.value < 0.05
)


# ------------------------------------------------------------
# T-tests by demographic group
# ------------------------------------------------------------

t_test_rows_by_group <- overall_pool %>%
  filter(
    !is.na(representation_gap)
  ) %>%
  mutate(
    race = recode(
      race,
      "HLSO Ethnicity" = "Hispanic/Latino"
    )
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
        observations = nrow(.x),
        
        mean_gap = as.numeric(
          test_result$estimate
        ),
        
        confidence_interval_lower =
          test_result$conf.int[1],
        
        confidence_interval_upper =
          test_result$conf.int[2],
        
        t_statistic = as.numeric(
          test_result$statistic
        ),
        
        p_value =
          test_result$p.value,
        
        statistically_significant =
          test_result$p.value < 0.05
      )
    }
  ) %>%
  ungroup() %>%
  rename(
    group = race
  )
# ------------------------------------------------------------
# Combined t-test summary
# ------------------------------------------------------------

t_test_summary <- bind_rows(
  overall_t_test_row,
  t_test_rows_by_group
) %>%
  mutate(
    group = factor(
      group,
      levels = c(
        "Overall",
        "Multiracial",
        "Hispanic/Latino",
        "Black/African American",
        "Asian",
        "Native Hawaiian/Pacific Islander",
        "American Indian/Alaskan Native",
        "White"
      )
    )
  ) %>%
  arrange(
    group
  ) %>%
  mutate(
    group = as.character(group)
  ) %>%
  rename(
    ci_lower = confidence_interval_lower,
    ci_upper = confidence_interval_upper
  ) %>%
  mutate(
    significance = if_else(
      statistically_significant,
      "Significant",
      "Not significant"
    )
  ) %>%
  select(
    group,
    observations,
    mean_gap,
    ci_lower,
    ci_upper,
    t_statistic,
    p_value,
    significance
  ) %>%
  mutate(
    across(
      c(
        mean_gap,
        ci_lower,
        ci_upper,
        t_statistic
      ),
      ~ round(.x, 4)
    ),
    
    p_value = if_else(
      p_value < 0.0001,
      "< 0.0001",
      format(
        round(p_value, 4),
        nsmall = 4
      )
    )
  )

t_test_summary

View(t_test_summary)
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

# Because separate tests are conducted for every court-group
# combination, some statistically significant results may occur
# by chance due to multiple testing. Results are therefore
# interpreted using both the individual p-values and the overall
# pattern across courts.
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
  mutate(
    race = recode(
      race,
      "HLSO Ethnicity" = "Hispanic/Latino"
    )
  ) %>%
  group_by(
    race
  ) %>%
  summarize(
    courts_tested = sum(
      !is.na(exact_p_value)
    ),
    
    percent_below_expected = mean(
      jury_count < expected_count,
      na.rm = TRUE
    ) * 100,
    
    percent_significantly_underrepresented = mean(
      statistically_significant &
        jury_count < expected_count,
      na.rm = TRUE
    ) * 100,
    
    percent_below_1sd = mean(
      below_expected_1sd,
      na.rm = TRUE
    ) * 100,
    
    percent_below_2sd = mean(
      below_expected_2sd,
      na.rm = TRUE
    ) * 100,
    
    .groups = "drop"
  ) %>%
  arrange(
    desc(percent_significantly_underrepresented)
  ) %>%
  mutate(
    across(
      where(is.numeric),
      ~ round(.x, 2)
    )
  )

binomial_summary_by_race

View(binomial_summary_by_race)
# ============================================================
# 7. COURT-LEVEL FLAGS
# ============================================================
# This section summarizes how many demographic groups within
# each court were flagged by the exact binomial analysis.
#
# Note:
# These categories overlap.
#
# groups_below_1sd:
#     exact_p_value < 0.16
#
# groups_significantly_underrepresented:
#     exact_p_value < 0.05
#
# groups_below_2sd:
#     exact_p_value < 0.025
#
# The 2-SD threshold is the most stringent criterion,
# whereas the 1-SD threshold is the least stringent.


# ------------------------------------------------------------
# Court-level exact binomial flags
# ------------------------------------------------------------

court_flag_summary <- binomial_results %>%
  group_by(
    court_number,
    county_name
  ) %>%
  summarize(
    groups_tested = sum(
      !is.na(exact_p_value)
    ),
    
    groups_significantly_underrepresented = sum(
      statistically_significant &
        jury_count < expected_count,
      na.rm = TRUE
    ),
    
    groups_below_1sd = sum(
      below_expected_1sd,
      na.rm = TRUE
    ),
    
    groups_below_2sd = sum(
      below_expected_2sd,
      na.rm = TRUE
    ),
    
    .groups = "drop"
  ) %>%
  arrange(
    desc(groups_significantly_underrepresented),
    desc(groups_below_2sd),
    desc(groups_below_1sd)
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
  mutate(
    race = recode(
      race,
      "HLSO Ethnicity" = "Hispanic/Latino"
    )
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
    court_binomial_p_value = exact_p_value
  ) %>%
  arrange(
    court_binomial_p_value,
    representation_gap
  )

significant_underrepresentation_results

View(significant_underrepresentation_results)
# ============================================================
# 8. MONTE CARLO VALIDATION
# ============================================================
# This section performs the simulation-based one-sided test.
#
# For each court and demographic group:
#
# Null hypothesis:
#   Jury pool proportion = county population proportion
#
# Alternative hypothesis:
#   Jury pool proportion < county population proportion
#
# A total of 10,000 jury-pool counts are simulated under the
# Census-based null probability.
#
# The Monte Carlo p-value is the proportion of simulated counts
# that are less than or equal to the observed jury count.
#
# The +1 correction prevents an estimated p-value of exactly
# zero and produces a valid Monte Carlo estimate.
#
# The Monte Carlo results are used as a validation analysis.
# The primary court-level results are reported using the exact
# binomial tests.
# ============================================================
# ------------------------------------------------------------
# Set simulation options
# ------------------------------------------------------------

set.seed(230)

number_of_simulations <- 10000
# ------------------------------------------------------------
# Run Monte Carlo tests
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
    
    monte_carlo_significant =
      monte_carlo_p_value < 0.05
  ) %>%
  select(
    -simulated_counts
  ) %>%
  ungroup()

monte_carlo_results

# ------------------------------------------------------------
# Compare Monte Carlo and exact binomial classifications
# ------------------------------------------------------------

monte_carlo_validation <- binomial_results %>%
  select(
    court_number,
    county_name,
    race,
    exact_significant =
      statistically_significant
  ) %>%
  left_join(
    monte_carlo_results %>%
      select(
        court_number,
        county_name,
        race,
        monte_carlo_significant
      ),
    
    by = c(
      "court_number",
      "county_name",
      "race"
    )
  ) %>%
  summarize(
    observations_compared =
      sum(
        !is.na(exact_significant) &
          !is.na(monte_carlo_significant)
      ),
    
    disagreements =
      sum(
        exact_significant !=
          monte_carlo_significant,
        na.rm = TRUE
      )
  )

monte_carlo_validation

View(monte_carlo_validation)

# ============================================================
# FINAL TABLE EXPORTS
# ============================================================

dir.create(
  "outputs/tables",
  recursive = TRUE,
  showWarnings = FALSE
)

write_csv(
  overall_results_summary,
  "outputs/tables/overall_results_summary.csv"
)

write_csv(
  race_level_summary,
  "outputs/tables/race_level_summary.csv"
)

write_csv(
  t_test_summary,
  "outputs/tables/t_test_summary.csv"
)

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
  "outputs/tables/significant_underrepresentation_results.csv"
)

write_csv(
  monte_carlo_validation,
  "outputs/tables/monte_carlo_validation.csv"
)
cat("\n===============================================\n")
cat("Iowa jury pool analysis complete.\n")
cat("Tables exported to outputs/tables.\n")
cat(
  "Monte Carlo simulations per test: ",
  number_of_simulations,
  "\n",
  sep = ""
)
cat("===============================================\n")