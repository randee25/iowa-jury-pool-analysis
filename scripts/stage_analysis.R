# ============================================================
# JURY STAGE ANALYSIS
# Iowa Jury Pool Analysis
#
# Purpose:
# Examine changes in racial and ethnic representation
# across the overall pool, criminal panel, and juror
# stages of the jury selection process.
#
# Outputs:
# - Statewide composition table
# - Stage composition figure
# - Percentage-point change table
# - Percentage-point change figure
# - County-level summar
y table
# - Wilcoxon signed-rank test results
# ============================================================


# ------------------------------------------------------------
# 1. Load packages and import data
# ------------------------------------------------------------

library(tidyverse)
library(scales)

jury_stages_raw <- read_csv(
  "data/processed/new_main_view.csv",
  show_col_types = FALSE
)

# Create the output folder if it does not already exist
dir.create(
  "outputs/figures",
  recursive = TRUE,
  showWarnings = FALSE
)


# ------------------------------------------------------------
# 2. Clean race labels and create stage variable
# ------------------------------------------------------------

jury_stages <- jury_stages_raw %>%
  mutate(
    court_number = str_pad(
      as.character(court_number),
      width = 3,
      pad = "0"
    ),
    
    race = case_when(
      race %in% c("HLSO", "HLSO Ethnicity") ~
        "Hispanic/Latino",
      
      race == "American Indian/Alaskan Native" ~
        "American Indian/Alaska Native",
      
      TRUE ~ race
    ),
    
    stage = case_when(
      dataset == "Overall Pool" ~
        "Overall Pool",
      
      dataset == "Criminal Panel" ~
        "Criminal Panel",
      
      dataset == "Empanelment" &
        result_status == "Juror" ~
        "Juror",
      
      TRUE ~ NA_character_
    )
  )


# ------------------------------------------------------------
# 3. Calculate statewide composition by stage
# ------------------------------------------------------------

# Multiracial is excluded because it is not available in the
# empanelment records and therefore cannot be compared across
# all three stages.

statewide_stage_composition <- jury_stages %>%
  filter(
    !is.na(stage),
    race != "Multiracial"
  ) %>%
  group_by(stage, race) %>%
  summarise(
    race_count = sum(jury_count, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  group_by(stage) %>%
  mutate(
    stage_total = sum(race_count),
    statewide_pct = 100 * race_count / stage_total
  ) %>%
  ungroup() %>%
  mutate(
    stage = factor(
      stage,
      levels = c(
        "Overall Pool",
        "Criminal Panel",
        "Juror"
      )
    )
  )

View(statewide_stage_composition)


# ------------------------------------------------------------
# 4. Figure 1: Composition across jury stages
# ------------------------------------------------------------

stage_composition_plot <- statewide_stage_composition %>%
  mutate(
    stage = factor(
      stage,
      levels = c(
        "Overall Pool",
        "Criminal Panel",
        "Juror"
      ),
      labels = c(
        "Pool",
        "Panel",
        "Juror"
      )
    ),
    
    race = recode(
      race,
      "Black/African American" = "Black",
      "American Indian/Alaska Native" = "AIAN",
      "Native Hawaiian/Pacific Islander" = "NHPI",
      "Hispanic/Latino" = "Hispanic"
    )
  ) %>%
  ggplot(
    aes(
      x = stage,
      y = statewide_pct,
      group = race
    )
  ) +
  geom_line(
    linewidth = 1,
    color = "black"
  ) +
  geom_point(
    size = 2.5,
    color = "black"
  ) +
  geom_text(
    aes(
      label = sprintf("%.2f", statewide_pct)
    ),
    size = 3.5,
    vjust = -0.7
  ) +
  facet_wrap(
    ~ race,
    scales = "free_y"
  ) +
  scale_y_continuous(
    labels = label_number(
      accuracy = 0.1,
      suffix = "%"
    ),
    expand = expansion(
      mult = c(0.08, 0.18)
    )
  ) +
  labs(
    title = "Racial and Ethnic Composition Across Jury Stages",
    subtitle = "Weighted statewide percentages",
    x = NULL,
    y = "Percentage"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    panel.spacing = unit(1.2, "lines"),
    legend.position = "none",
    
    strip.text = element_text(
      face = "bold",
      size = 11
    ),
    
    axis.text.x = element_text(
      angle = 45,
      hjust = 1
    )
  )

stage_composition_plot

ggsave(
  filename =
    "outputs/figures/stage_composition_by_race.png",
  plot = stage_composition_plot,
  width = 12,
  height = 8,
  dpi = 300
)


# ------------------------------------------------------------
# 5. Calculate statewide percentage-point changes
# ------------------------------------------------------------

statewide_stage_changes <- statewide_stage_composition %>%
  select(
    race,
    stage,
    statewide_pct
  ) %>%
  pivot_wider(
    names_from = stage,
    values_from = statewide_pct
  ) %>%
  mutate(
    `Pool → Panel` =
      `Criminal Panel` - `Overall Pool`,
    
    `Panel → Juror` =
      Juror - `Criminal Panel`,
    
    `Pool → Juror` =
      Juror - `Overall Pool`
  ) %>%
  arrange(`Pool → Juror`)

View(statewide_stage_changes)


# ------------------------------------------------------------
# 6. Figure 2: Changes between jury stages
# ------------------------------------------------------------

stage_change_long <- statewide_stage_changes %>%
  select(
    race,
    `Pool → Panel`,
    `Panel → Juror`
  ) %>%
  pivot_longer(
    cols = -race,
    names_to = "transition",
    values_to = "percentage_point_change"
  ) %>%
  mutate(
    transition = recode(
      transition,
      `Pool → Panel` =
        "Overall Pool to Criminal Panel",
      
      `Panel → Juror` =
        "Criminal Panel to Jurors"
    ),
    
    transition = factor(
      transition,
      levels = c(
        "Overall Pool to Criminal Panel",
        "Criminal Panel to Jurors"
      )
    ),
    
    race = recode(
      race,
      "Black/African American" = "Black",
      "American Indian/Alaska Native" = "AIAN",
      "Native Hawaiian/Pacific Islander" = "NHPI",
      "Hispanic/Latino" = "Hispanic"
    )
  )

stage_change_plot <- stage_change_long %>%
  ggplot(
    aes(
      x = percentage_point_change,
      y = reorder(race, percentage_point_change)
    )
  ) +
  geom_col(
    width = 0.7,
    fill = "grey40"
  ) +
  geom_vline(
    xintercept = 0,
    linewidth = 0.7,
    color = "black"
  ) +
  geom_text(
    aes(
      label = sprintf(
        "%+.2f",
        percentage_point_change
      ),
      
      hjust = if_else(
        percentage_point_change >= 0,
        -0.15,
        1.15
      )
    ),
    size = 3.5
  ) +
  facet_wrap(
    ~ transition,
    scales = "free_x",
    nrow = 1
  ) +
  scale_x_continuous(
    expand = expansion(
      mult = c(0.20, 0.20)
    )
  ) +
  labs(
    title =
      "Change in Representation Between Jury Stages",
    
    subtitle = paste(
      "Positive values indicate increased representation;",
      "negative values indicate decreased representation"
    ),
    
    x = "Percentage-point change",
    y = NULL
  ) +
  theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    panel.spacing = unit(1.5, "lines"),
    
    strip.text = element_text(
      face = "bold",
      size = 11
    ),
    
    axis.text.y = element_text(
      size = 10
    )
  )

stage_change_plot

ggsave(
  filename =
    "outputs/figures/stage_percentage_point_changes.png",
  plot = stage_change_plot,
  width = 11,
  height = 6,
  dpi = 300
)


# ------------------------------------------------------------
# 7. Create matched county-level stage data
# ------------------------------------------------------------

county_stage_wide <- jury_stages %>%
  filter(
    !is.na(stage),
    race != "Multiracial"
  ) %>%
  select(
    court_number,
    county_name,
    race,
    stage,
    jury_pct
  ) %>%
  pivot_wider(
    names_from = stage,
    values_from = jury_pct
  ) %>%
  mutate(
    pool_panel_change =
      `Criminal Panel` - `Overall Pool`,
    
    panel_juror_change =
      Juror - `Criminal Panel`,
    
    pool_juror_change =
      Juror - `Overall Pool`
  )


# Summarize the typical county-level change

county_change_summary <- county_stage_wide %>%
  summarise(
    `Pool → Panel` =
      median(
        pool_panel_change,
        na.rm = TRUE
      ),
    
    `Panel → Juror` =
      median(
        panel_juror_change,
        na.rm = TRUE
      ),
    
    `Pool → Juror` =
      median(
        pool_juror_change,
        na.rm = TRUE
      ),
    
    .by = race
  ) %>%
  mutate(
    across(
      where(is.numeric),
      ~ round(.x, 3)
    )
  ) %>%
  arrange(race)

View(county_change_summary)


# ------------------------------------------------------------
# 8. Paired Wilcoxon signed-rank tests
# ------------------------------------------------------------

# The Wilcoxon test determines whether county-level changes
# are consistently above or below zero across matched counties.

run_paired_wilcoxon <- function(
    data,
    earlier_stage,
    later_stage,
    comparison_name
) {
  
  data %>%
    filter(
      !is.na(.data[[earlier_stage]]),
      !is.na(.data[[later_stage]])
    ) %>%
    group_by(race) %>%
    group_modify(
      ~ {
        
        test_result <- wilcox.test(
          x = .x[[later_stage]],
          y = .x[[earlier_stage]],
          paired = TRUE,
          exact = FALSE
        )
        
        tibble(
          median_change = median(
            .x[[later_stage]] -
              .x[[earlier_stage]],
            na.rm = TRUE
          ),
          
          p_value = test_result$p.value
        )
      }
    ) %>%
    ungroup() %>%
    mutate(
      comparison = comparison_name
    )
}


# Run the three comparisons

pool_panel_tests <- run_paired_wilcoxon(
  data = county_stage_wide,
  earlier_stage = "Overall Pool",
  later_stage = "Criminal Panel",
  comparison_name = "pool_panel"
)

panel_juror_tests <- run_paired_wilcoxon(
  data = county_stage_wide,
  earlier_stage = "Criminal Panel",
  later_stage = "Juror",
  comparison_name = "panel_juror"
)

pool_juror_tests <- run_paired_wilcoxon(
  data = county_stage_wide,
  earlier_stage = "Overall Pool",
  later_stage = "Juror",
  comparison_name = "pool_juror"
)


# Combine results and adjust for multiple tests

stage_tests_long <- bind_rows(
  pool_panel_tests,
  panel_juror_tests,
  pool_juror_tests
) %>%
  group_by(comparison) %>%
  mutate(
    p_adjusted = p.adjust(
      p_value,
      method = "BH"
    )
  ) %>%
  ungroup()


# Create one clean row per race

stage_tests_report <- stage_tests_long %>%
  select(
    race,
    comparison,
    median_change,
    p_adjusted
  ) %>%
  pivot_wider(
    names_from = comparison,
    values_from = c(
      median_change,
      p_adjusted
    )
  ) %>%
  rename(
    `Pool → Panel` =
      median_change_pool_panel,
    
    `Panel → Juror` =
      median_change_panel_juror,
    
    `Pool → Juror` =
      median_change_pool_juror,
    
    `Pool → Panel p` =
      p_adjusted_pool_panel,
    
    `Panel → Juror p` =
      p_adjusted_panel_juror,
    
    `Pool → Juror p` =
      p_adjusted_pool_juror
  ) %>%
  mutate(
    across(
      c(
        `Pool → Panel`,
        `Panel → Juror`,
        `Pool → Juror`
      ),
      ~ round(.x, 3)
    ),
    
    across(
      contains(" p"),
      ~ case_when(
        .x < 0.001 ~ "<0.001",
        TRUE ~ sprintf("%.3f", .x)
      )
    )
  ) %>%
  arrange(race)

View(stage_tests_report)

print(stage_tests_report)


# ------------------------------------------------------------
# 9. Export final tables
# ------------------------------------------------------------

dir.create(
  "outputs/tables",
  recursive = TRUE,
  showWarnings = FALSE
)

write_csv(
  statewide_stage_composition,
  "outputs/tables/statewide_stage_composition.csv"
)

write_csv(
  statewide_stage_changes,
  "outputs/tables/statewide_stage_changes.csv"
)

write_csv(
  county_change_summary,
  "outputs/tables/county_stage_changes.csv"
)

write_csv(
  stage_tests_report,
  "outputs/tables/stage_wilcoxon_tests.csv"
)