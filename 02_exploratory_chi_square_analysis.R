# ============================================================
# EXPLORATORY CHI-SQUARE ANALYSIS
# ============================================================
#
# Purpose:
# Explore whether observed jury-pool counts differ from expected
# counts derived from county demographic percentages.
#
# IMPORTANT:
#
# These analyses are exploratory and are not treated as the
# primary findings of this project.
#
# Limitations:
#
# 1. Hispanic/Latino/Spanish Origins is an ethnicity category
#    and may overlap with racial categories.
#
# 2. Multiracial observations were excluded because they were
#    not represented consistently across the available datasets.
#
# 3. Other, unknown, and not-provided jury observations are not
#    included in the six-category analytical dataset.
#
# 4. Therefore, the categories are not fully mutually exclusive
#    and exhaustive.
#
# 5. Some courts have very small expected counts.
#
# Monte Carlo simulation can reduce problems caused by small
# expected counts, but it does not correct the category-alignment
# limitations described above.
#
# Consequently, these results should be interpreted cautiously.
#
# Primary results are produced in:
#     01_main_analysis.R
#
# ============================================================


# ============================================================
# 1. LOAD REQUIRED PACKAGE
# ============================================================

library(tidyverse)


# ============================================================
# 2. PREPARE THE OVERALL JURY POOL DATA
# ============================================================

# Create a cleaned working dataset containing only observations
# from the overall jury pool.

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
# 3. VERIFY COURT-LEVEL TOTALS
# ============================================================

# adjusted_total should be the same for every demographic row
# belonging to the same court.
#
# A result containing zero rows means the totals are consistent.

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


# ============================================================
# 4. CALCULATE EXPECTED COUNTS
# ============================================================

# The expected count is the number expected in the jury pool if
# the court's demographic percentage matched the county Census
# percentage.
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

# Calculate county population proportions and expected counts
# needed for the chi-square analyses.

chi_data <- overall_pool %>%
  mutate(
    population_proportion =
      county_population_pct / 100,
    
    expected_count =
      adjusted_total * population_proportion
  )

chi_data <- overall_pool %>%
  mutate(
    population_proportion =
      county_population_pct / 100,
    
    expected_count =
      adjusted_total * population_proportion
  )

View(chi_data)


# ============================================================
# 5. OPTIONAL EXAMPLE: ADAIR COUNTY
# ============================================================

# This example demonstrates the six-category test for one court.
#
# R may warn that the chi-square approximation is unreliable
# when one or more expected counts are small.

adair_data <- chi_data %>%
  filter(county_name == "Adair")

adair_test <- chisq.test(
  x = adair_data$jury_count,
  p = adair_data$expected_count /
    sum(adair_data$expected_count)
)

adair_test


# ============================================================
# 6. COMBINE SMALLER DEMOGRAPHIC CATEGORIES
# ============================================================

# The six analytical categories are combined into four groups:
#
# White
# Black
# Hispanic
# Other
#
# Asian, American Indian/Alaskan Native, and Native
# Hawaiian/Pacific Islander observations are included in Other.

combined_data <- chi_data %>%
  mutate(
    race_group = case_when(
      race == "White" ~ "White",
      
      race == "Black/African American" ~
        "Black",
      
      race == "Hispanic/Latino/Spanish Origins" ~
        "Hispanic",
      
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

View(combined_data)


# ============================================================
# 7. CHECK COMBINED-CATEGORY ASSUMPTIONS
# ============================================================

# This table identifies small expected counts within each court.

combined_assumption_check <- combined_data %>%
  group_by(court_number, county_name) %>%
  summarize(
    minimum_expected =
      min(expected, na.rm = TRUE),
    
    number_below_5 =
      sum(expected < 5, na.rm = TRUE),
    
    percent_below_5 =
      mean(expected < 5, na.rm = TRUE) * 100,
    
    expected_total =
      sum(expected, na.rm = TRUE),
    
    observed_total =
      sum(observed, na.rm = TRUE),
    
    .groups = "drop"
  ) %>%
  mutate(
    totals_difference =
      observed_total - expected_total
  ) %>%
  arrange(desc(minimum_expected))

View(combined_assumption_check)


# ============================================================
# 8. RUN COMBINED-CATEGORY CHI-SQUARE TESTS
# ============================================================

# Monte Carlo simulation is used to estimate p-values without
# relying entirely on the usual large-sample approximation.
#
# This helps with small expected counts but does not resolve the
# broader category-overlap and omitted-category limitations.

set.seed(1234)

combined_results <- combined_data %>%
  group_by(court_number, county_name) %>%
  group_modify(~{
    
    valid_test <-
      all(.x$expected > 0) &&
      sum(.x$observed) > 0 &&
      sum(.x$expected) > 0
    
    if (!valid_test) {
      return(
        tibble(
          chi_square = NA_real_,
          p_value = NA_real_,
          test_status =
            "Not tested: zero expected or observed total"
        )
      )
    }
    
    test <- chisq.test(
      x = .x$observed,
      p = .x$expected / sum(.x$expected),
      simulate.p.value = TRUE,
      B = 2000
    )
    
    tibble(
      chi_square =
        as.numeric(test$statistic),
      
      p_value =
        test$p.value,
      
      test_status =
        "Monte Carlo test completed"
    )
  }) %>%
  ungroup() %>%
  left_join(
    combined_assumption_check,
    by = c(
      "court_number",
      "county_name"
    )
  ) %>%
  mutate(
    significant_unadjusted =
      p_value < 0.05,
    
    p_value_adjusted_bh =
      p.adjust(
        p_value,
        method = "BH"
      ),
    
    significant_after_adjustment =
      p_value_adjusted_bh < 0.05,
    
    assumption_flag = case_when(
      minimum_expected < 1 ~
        "Expected count below 1",
      
      percent_below_5 > 20 ~
        "More than 20% below 5",
      
      TRUE ~
        "Expected-count guideline satisfied"
    )
  ) %>%
  arrange(p_value)

View(combined_results)


# ============================================================
# 9. SUMMARIZE COMBINED-CATEGORY RESULTS
# ============================================================

combined_results_summary <- combined_results %>%
  summarize(
    total_courts = n(),
    
    courts_tested =
      sum(!is.na(p_value)),
    
    significant_unadjusted =
      sum(
        significant_unadjusted,
        na.rm = TRUE
      ),
    
    percent_significant_unadjusted =
      mean(
        significant_unadjusted,
        na.rm = TRUE
      ) * 100,
    
    significant_after_adjustment =
      sum(
        significant_after_adjustment,
        na.rm = TRUE
      ),
    
    percent_significant_after_adjustment =
      mean(
        significant_after_adjustment,
        na.rm = TRUE
      ) * 100,
    
    courts_meeting_expected_count_guideline =
      sum(
        assumption_flag ==
          "Expected-count guideline satisfied",
        na.rm = TRUE
      ),
    
    courts_with_assumption_warning =
      sum(
        assumption_flag !=
          "Expected-count guideline satisfied",
        na.rm = TRUE
      )
  )

combined_results_summary


# View statistically significant results after adjustment.

significant_combined_results <- combined_results %>%
  filter(significant_after_adjustment) %>%
  arrange(p_value_adjusted_bh)

View(significant_combined_results)


# View the ten largest finite chi-square statistics.

largest_combined_chi_square <- combined_results %>%
  filter(is.finite(chi_square)) %>%
  arrange(desc(chi_square)) %>%
  slice_head(n = 10)

View(largest_combined_chi_square)


# ============================================================
# 10. CHECK SIX-CATEGORY CHI-SQUARE ELIGIBILITY
# ============================================================

# This analysis retains all six demographic categories.
#
# Courts are considered eligible only when:
#
# 1. Every expected count is at least 5.
# 2. Every county population percentage is greater than zero.

full_assumption_check <- chi_data %>%
  group_by(court_number, county_name) %>%
  summarize(
    minimum_expected =
      min(expected_count, na.rm = TRUE),
    
    minimum_population_pct =
      min(
        county_population_pct,
        na.rm = TRUE
      ),
    
    number_below_5 =
      sum(
        expected_count < 5,
        na.rm = TRUE
      ),
    
    percent_below_5 =
      mean(
        expected_count < 5,
        na.rm = TRUE
      ) * 100,
    
    observed_total =
      sum(jury_count, na.rm = TRUE),
    
    expected_total =
      sum(expected_count, na.rm = TRUE),
    
    .groups = "drop"
  ) %>%
  mutate(
    totals_difference =
      observed_total - expected_total
  ) %>%
  arrange(desc(minimum_expected))

View(full_assumption_check)


# Keep only courts satisfying the specified expected-count rules.

eligible_full_race_courts <- full_assumption_check %>%
  filter(
    minimum_expected >= 5,
    minimum_population_pct > 0
  )

View(eligible_full_race_courts)


# Filter the detailed data to eligible courts.

full_race_data <- chi_data %>%
  semi_join(
    eligible_full_race_courts,
    by = c(
      "court_number",
      "county_name"
    )
  )


# ============================================================
# 11. RUN SIX-CATEGORY CHI-SQUARE TESTS
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
      chi_square =
        as.numeric(test$statistic),
      
      degrees_freedom =
        as.numeric(test$parameter),
      
      p_value =
        test$p.value
    )
  }) %>%
  ungroup() %>%
  mutate(
    significant_unadjusted =
      p_value < 0.05,
    
    p_value_adjusted_bh =
      p.adjust(
        p_value,
        method = "BH"
      ),
    
    significant_after_adjustment =
      p_value_adjusted_bh < 0.05
  ) %>%
  arrange(p_value)

View(full_race_results)


# ============================================================
# 12. SUMMARIZE SIX-CATEGORY RESULTS
# ============================================================

full_race_results_summary <- full_race_results %>%
  summarize(
    total_eligible_courts = n(),
    
    significant_unadjusted =
      sum(
        significant_unadjusted,
        na.rm = TRUE
      ),
    
    percent_significant_unadjusted =
      mean(
        significant_unadjusted,
        na.rm = TRUE
      ) * 100,
    
    significant_after_adjustment =
      sum(
        significant_after_adjustment,
        na.rm = TRUE
      ),
    
    percent_significant_after_adjustment =
      mean(
        significant_after_adjustment,
        na.rm = TRUE
      ) * 100
  )

full_race_results_summary


# ============================================================
# 13. EXPORT EXPLORATORY RESULTS
# ============================================================

# Create the output folder if it does not already exist.

dir.create(
  "data/processed",
  recursive = TRUE,
  showWarnings = FALSE
)


# Combined-category assumption checks.

write_csv(
  combined_assumption_check,
  "data/processed/combined_chi_square_assumption_check.csv"
)


# Combined-category court-level results.

write_csv(
  combined_results,
  "data/processed/combined_chi_square_results.csv"
)


# Combined-category overall summary.

write_csv(
  combined_results_summary,
  "data/processed/combined_chi_square_summary.csv"
)


# Six-category eligibility and assumption checks.

write_csv(
  full_assumption_check,
  "data/processed/full_race_chi_square_assumption_check.csv"
)


# Six-category court-level results.

write_csv(
  full_race_results,
  "data/processed/full_race_chi_square_results.csv"
)


# Six-category overall summary.

write_csv(
  full_race_results_summary,
  "data/processed/full_race_chi_square_summary.csv"
)


# ============================================================
# 14. FINAL OUTPUT CHECK
# ============================================================

# Confirm that the exploratory chi-square files were created.

list.files(
  "data/processed",
  pattern = "chi_square.*\\.csv$"
)