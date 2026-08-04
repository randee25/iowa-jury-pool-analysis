# ============================================================
# Iowa Jury Pool Representation Project
# Script: visualizations.R

# Load packages -----------------------------------------------------------

library(tidyverse)


# Import processed data ---------------------------------------------------

jury_data <- read_csv(
  "data/processed/overall_pool_final.csv",
  show_col_types = FALSE
)


# Prepare race labels and ordering ----------------------------------------

race_order <- c(
  "AIAN",
  "Asian",
  "Black",
  "Hispanic/Latino",
  "Multiracial",
  "NHPI",
  "White"
)

jury_data_plot <- jury_data %>%
  mutate(
    race_short = case_when(
      str_detect(
        race,
        regex("American Indian|Alaska", ignore_case = TRUE)
      ) ~ "AIAN",
      
      str_detect(
        race,
        regex("Asian", ignore_case = TRUE)
      ) ~ "Asian",
      
      str_detect(
        race,
        regex("Black|African American", ignore_case = TRUE)
      ) ~ "Black",
      
      str_detect(
        race,
        regex("HLSO", ignore_case = TRUE)
      ) ~ "Hispanic/Latino",
      
      str_detect(
        race,
        regex("Multiracial|Two or More|Multi", ignore_case = TRUE)
      ) ~ "Multiracial",
      
      str_detect(
        race,
        regex(
          "Native Hawaiian|Pacific Islander",
          ignore_case = TRUE
        )
      ) ~ "NHPI",
      
      str_detect(
        race,
        regex("White", ignore_case = TRUE)
      ) ~ "White",
      
      TRUE ~ race
    ),
    
    race_short = factor(
      race_short,
      levels = race_order
    )
  )


# Confirm representation-gap calculation ---------------------------------

jury_data_plot <- jury_data_plot %>%
  mutate(
    representation_gap_check =
      jury_pool_pct - county_population_pct
  )

gap_check <- jury_data_plot %>%
  summarise(
    largest_difference = max(
      abs(representation_gap - representation_gap_check),
      na.rm = TRUE
    )
  )

print(gap_check)

# The largest_difference value should be zero or extremely close to zero.


# ========================================================================
# FIGURE 1
# Census versus jury pool representation by race
# ========================================================================

census_jury_plot <- ggplot(
  jury_data_plot,
  aes(
    x = county_population_pct,
    y = jury_pool_pct
  )
) +
  geom_point(
    size = 1.7,
    alpha = 0.60,
    shape = 21,
    fill = "gray40",
    color = "black",
    stroke = 0.25
  ) +
  geom_abline(
    slope = 1,
    intercept = 0,
    linetype = "dashed",
    linewidth = 0.65
  ) +
  facet_wrap(
    ~ race_short,
    scales = "free"
  ) +
  labs(
    title = "Census and Jury Pool Representation by Race",
    subtitle = "Each point represents an Iowa county.",
    x = "Census %",
    y = "Jury %",
    caption = paste(
      "The dashed line represents equal census and",
      "jury pool percentages."
    )
  ) +
  theme_classic() +
  theme(
    plot.title = element_text(
      face = "bold",
      size = 16
    ),
    plot.subtitle = element_text(
      size = 11
    ),
    strip.background = element_blank(),
    strip.text = element_text(
      face = "bold",
      size = 10
    ),
    axis.title = element_text(
      size = 11
    ),
    plot.caption = element_text(
      size = 9
    ),
    panel.spacing = unit(
      1,
      "lines"
    )
  )

print(census_jury_plot)

ggsave(
  filename = "outputs/figure_1_census_vs_jury.png",
  plot = census_jury_plot,
  width = 10,
  height = 8,
  dpi = 300,
  bg = "white"
)


# ========================================================================
# FIGURE 2
# Weighted mean absolute error by race
# ========================================================================

weighted_mae_by_race <- jury_data_plot %>%
  filter(
    !is.na(representation_gap),
    !is.na(adjusted_total),
    adjusted_total > 0
  ) %>%
  group_by(race_short) %>%
  summarise(
    weighted_mae = weighted.mean(
      abs(representation_gap),
      w = adjusted_total,
      na.rm = TRUE
    ),
    .groups = "drop"
  ) %>%
  arrange(weighted_mae) %>%
  mutate(
    race_short = factor(
      race_short,
      levels = race_short
    )
  )

weighted_mae_plot <- ggplot(
  weighted_mae_by_race,
  aes(
    x = weighted_mae,
    y = race_short
  )
) +
  geom_col(
    width = 0.65,
    fill = "black"
  ) +
  geom_text(
    aes(
      label = sprintf("%.2f", weighted_mae)
    ),
    hjust = -0.15,
    size = 3.5
  ) +
  scale_x_continuous(
    expand = expansion(
      mult = c(0, 0.10)
    )
  ) +
  labs(
    title = "Mean Absolute Error by Race",
    subtitle = paste(
      "Larger values indicate a greater mismatch between",
      "census and jury pool percentages."
    ),
    x = NULL,
    y = NULL,
    caption = paste(
      "Mean absolute error is the weighted average absolute",
      "difference between jury pool and census percentages.",
      "Counties are weighted by adjusted jury pool total."
    )
  ) +
  theme_classic() +
  theme(
    plot.title = element_text(
      face = "bold",
      size = 16
    ),
    plot.subtitle = element_text(
      size = 11
    ),
    axis.text.y = element_text(
      face = "bold",
      size = 10
    ),
    plot.caption = element_text(
      size = 9
    )
  )

print(weighted_mae_plot)

ggsave(
  filename = "outputs/figure_2_weighted_mae_by_race.png",
  plot = weighted_mae_plot,
  width = 9,
  height = 6,
  dpi = 300,
  bg = "white"
)


# ========================================================================
# FIGURE 3
# Census versus jury pool percentages for minority groups
# ========================================================================

minority_order <- c(
  "AIAN",
  "Asian",
  "Black",
  "Hispanic/Latino",
  "Multiracial",
  "NHPI"
)

minority_comparison <- jury_data_plot %>%
  filter(
    race_short != "White",
    !is.na(adjusted_total),
    adjusted_total > 0
  ) %>%
  group_by(race_short) %>%
  summarise(
    census_pct = weighted.mean(
      county_population_pct,
      w = adjusted_total,
      na.rm = TRUE
    ),
    jury_pct = weighted.mean(
      jury_pool_pct,
      w = adjusted_total,
      na.rm = TRUE
    ),
    .groups = "drop"
  ) %>%
  pivot_longer(
    cols = c(
      census_pct,
      jury_pct
    ),
    names_to = "measure",
    values_to = "percentage"
  ) %>%
  mutate(
    measure = recode(
      measure,
      census_pct = "Census %",
      jury_pct = "Jury %"
    ),
    
    measure = factor(
      measure,
      levels = c(
        "Census %",
        "Jury %"
      )
    ),
    
    race_short = factor(
      race_short,
      levels = minority_order
    )
  )

minority_comparison_plot <- ggplot(
  minority_comparison,
  aes(
    x = race_short,
    y = percentage,
    fill = measure
  )
) +
  geom_col(
    position = position_dodge(
      width = 0.75
    ),
    width = 0.65,
    color = "black",
    linewidth = 0.45
  ) +
  geom_text(
    aes(
      label = sprintf("%.2f", percentage)
    ),
    position = position_dodge(
      width = 0.75
    ),
    vjust = -0.35,
    size = 3.2
  ) +
  scale_fill_manual(
    values = c(
      "Census %" = "grey85",
      "Jury %" = "black"
    )
  ) +
  scale_y_continuous(
    expand = expansion(
      mult = c(0, 0.12)
    )
  ) +
  labs(
    title = paste(
      "Census and Jury Pool Representation",
      "for Minority Groups"
    ),
    subtitle = paste(
      "Percentages are weighted by adjusted jury pool total."
    ),
    x = NULL,
    y = "Percentage",
    fill = NULL,
    caption = paste(
      "White bars represent census percentages;",
      "black bars represent jury pool percentages."
    )
  ) +
  theme_classic() +
  theme(
    plot.title = element_text(
      face = "bold",
      size = 16
    ),
    plot.subtitle = element_text(
      size = 11
    ),
    axis.text.x = element_text(
      face = "bold",
      size = 9
    ),
    axis.title.y = element_text(
      size = 11
    ),
    legend.position = "top",
    legend.key = element_rect(
      color = "black"
    ),
    plot.caption = element_text(
      size = 9
    )
  )

print(minority_comparison_plot)

ggsave(
  filename = "outputs/figure_3_minority_census_vs_jury.png",
  plot = minority_comparison_plot,
  width = 10,
  height = 6,
  dpi = 300,
  bg = "white"
)


# ========================================================================
# FIGURE 4
# Distribution of county-level representation gaps
# ========================================================================

boxplot_order <- c(
  "White",
  "Hispanic/Latino",
  "Multiracial",
  "Black",
  "Asian",
  "AIAN",
  "NHPI"
)

boxplot_data <- jury_data_plot %>%
  mutate(
    race_boxplot = factor(
      as.character(race_short),
      levels = rev(boxplot_order)
    )
  )

representation_gap_boxplot <- ggplot(
  boxplot_data,
  aes(
    x = representation_gap,
    y = race_boxplot
  )
) +
  geom_vline(
    xintercept = 0,
    linetype = "dashed",
    linewidth = 0.65
  ) +
  geom_boxplot(
    width = 0.55,
    fill = "white",
    color = "black",
    outlier.shape = 21,
    outlier.fill = "gray50",
    outlier.color = "black",
    outlier.size = 1.5,
    outlier.alpha = 0.65
  ) +
  labs(
    title = "Distribution of Representation Gaps by Race",
    x = "Representation gap (percentage points)",
    y = NULL,
    caption = paste(
      "The dashed line represents equal census and",
      "jury pool percentages."
    )
  ) +
  theme_classic() +
  theme(
    plot.title = element_text(
      face = "bold",
      size = 16
    ),
    axis.text.y = element_text(
      face = "bold",
      size = 10
    ),
    axis.title.x = element_text(
      size = 11
    ),
    plot.caption = element_text(
      size = 9
    )
  )

print(representation_gap_boxplot)

ggsave(
  filename = "outputs/figure_4_gap_distribution_boxplot.png",
  plot = representation_gap_boxplot,
  width = 9,
  height = 6,
  dpi = 300,
  bg = "white"
)


# ========================================================================
# APPENDIX FIGURE A1
# Weighted signed representation gap by race
# ========================================================================

weighted_gap_by_race <- jury_data_plot %>%
  filter(
    !is.na(representation_gap),
    !is.na(adjusted_total),
    adjusted_total > 0
  ) %>%
  group_by(race_short) %>%
  summarise(
    weighted_gap = weighted.mean(
      representation_gap,
      w = adjusted_total,
      na.rm = TRUE
    ),
    .groups = "drop"
  ) %>%
  arrange(weighted_gap) %>%
  mutate(
    race_short = factor(
      race_short,
      levels = race_short
    )
  )

weighted_gap_plot <- ggplot(
  weighted_gap_by_race,
  aes(
    x = weighted_gap,
    y = race_short
  )
) +
  geom_vline(
    xintercept = 0,
    linetype = "dashed",
    linewidth = 0.65
  ) +
  geom_col(
    width = 0.65,
    fill = "black"
  ) +
  geom_text(
    aes(
      label = sprintf("%.2f", weighted_gap),
      hjust = if_else(
        weighted_gap >= 0,
        -0.15,
        1.15
      )
    ),
    size = 3.5
  ) +
  scale_x_continuous(
    expand = expansion(
      mult = c(0.05, 0.05)
    )
  ) +
  labs(
    title = "Weighted Representation Gap by Race",
    subtitle = paste(
      "Positive values indicate overrepresentation;",
      "negative values indicate underrepresentation."
    ),
    x = NULL,
    y = NULL,
    caption = paste(
      "Representation gap = jury pool percentage − census percentage.",
      "Counties are weighted by adjusted jury pool total."
    )
  ) +
  theme_classic() +
  theme(
    plot.title = element_text(
      face = "bold",
      size = 16
    ),
    plot.subtitle = element_text(
      size = 11
    ),
    axis.text.y = element_text(
      face = "bold",
      size = 10
    ),
    plot.caption = element_text(
      size = 9
    )
  )

print(weighted_gap_plot)

ggsave(
  filename = "outputs/appendix_A1_weighted_representation_gap.png",
  plot = weighted_gap_plot,
  width = 9,
  height = 6,
  dpi = 300,
  bg = "white"
) 
