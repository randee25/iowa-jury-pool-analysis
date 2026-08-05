# Racial Disparity in Iowa Jury Pools 

**Jude Aboagye and Randee Goeke:** 
**STAT 230:** 
**Summer 2026:** 

---

# Project Summary

This project examines whether the racial composition of Iowa jury pools reflects the demographic composition of the counties from which jurors are drawn. County-level census data were combined with Iowa jury pool data to compare expected and observed representation across racial groups. Exploratory data analysis, weighted summary statistics, visualization techniques, and statistical testing methods were used to evaluate potential disparities. An interactive Tableau dashboard was also developed to allow users to explore county-level patterns throughout Iowa.

## Research Question

To what extent do the racial demographics of Iowa jury pools differ from the racial demographics of the counties they represent? Additionally, are observed differences large enough to suggest systematic underrepresentation rather than random sampling variation?

## Motivation

The right to an impartial jury is a fundamental principle of the American legal system. If certain groups are consistently underrepresented in jury pools, the fairness and representativeness of the judicial process may be affected. Understanding these patterns may help identify structural barriers to participation and improve the jury selection process.

## Summary of Findings

White jurors appeared to be overrepresented relative to county census populations, while Hispanic/Latino and Multiracial populations appeared to be underrepresented. Black, Asian, American Indian or Alaska Native (AIAN), and Native Hawaiian or Pacific Islander (NHPI) populations generally displayed smaller differences. Representation patterns also varied substantially among counties.
---

# Data

## Data Source

This project combines publicly available data from multiple sources.

Iowa jury pool data
Jury pool data supplied by Professor Lovell
County-level empanelment data
County-level jury pool data
Census data
United States Census Bureau
American Community Survey (ACS) 2024 estimates
Tables B05003B–B05003I

Source:

https://data.census.gov/
## Data Files

| File | Description |
| File                             | Description                        |
| -------------------------------- | ---------------------------------- |
| `data/raw/`                      | Original source files              |
| `data/processed/`                | Cleaned datasets used for analysis |
| `race_summary.csv`               | Race-specific summary statistics   |
| `standard_deviation_results.csv` | Standard deviation calculations    |

## Important Variables
| Variable                | Description                                                        |
| ----------------------- | ------------------------------------------------------------------ |
| `county_name`           | Iowa county name                                                   |
| `race_short`            | Standardized race category                                         |
| `jury_pool_pct`         | Percentage of jurors belonging to a particular race                |
| `county_population_pct` | Percentage of the county population belonging to a particular race |
| `representation_gap`    | Difference between jury percentage and census percentage           |
| `adjusted_total`        | Number of jurors included in the analysis                          |
| `jury_count`            | Number of jurors in a race category                                |


---

## Project Organization
## Project Organization

- README.md

- data
  - raw
  - processed

- outputs
  - figures
  - summary tables
  - Tableau workbook

- scripts
  - chi_square.R
  - exploratory_analysis.R
  - get_census_data.R
  - main_analysis.R
  - visualizations.R

- sql
  - analytics_views.sql
  - create_clean_tables.sql
  - create_lookup_table.sql
  - create_raw_tables.sql
  - create_schemas.sql
  - create_tables.sql
 

## Key Files/

### data/

This folder contains both the original data files and the processed datasets used throughout the analysis.

### raw/
Contains the original census files and jury pool datasets.

### processed/
Contains cleaned and merged datasets used in the final analysis.

### scripts/

| File                     | Description                                             |
| ------------------------ | ------------------------------------------------------- |
| `chi_square.R`           | Performs exploratory chi-square analyses.               |
| `exploratory_analysis.R` | Produces summary statistics and exploratory analyses.   |
| `get_census_data.R`      | Imports and cleans census data.                         |
| `main_analysis.R`        | Merges datasets and calculates representation measures. |
| `visualizations.R`       | Produces figures used in the final report.              |

### sql/
This folder contains SQL scripts used to construct the database, import data, clean tables, and create analytical views.
| File                      | Description                                       |
| ------------------------- | ------------------------------------------------- |
| `create_schemas.sql`      | Creates the database schema structure.            |
| `create_raw_tables.sql`   | Creates tables for the imported raw data.         |
| `create_clean_tables.sql` | Creates tables containing cleaned data.           |
| `create_lookup_table.sql` | Creates lookup tables used to standardize values. |
| `create_tables.sql`       | Creates additional tables required for analysis.  |
| `analytics_views.sql`     | Creates analytical views used in R.               |


### outputs/

### Figures

- `figure_1_census_vs_jury.png` – Scatterplot comparing county census percentages with jury pool percentages for each racial group.

- `figure_2_weighted_mae_by_race.png` – Mean absolute error (MAE) plot summarizing the average magnitude of representation differences across racial groups.

- `figure_3_minority_census_vs_jury.png` – Bar chart comparing weighted census percentages with weighted jury pool percentages for minority populations.

- `figure_4_gap_distribution_boxplot.png` – Boxplots illustrating the distribution of county-level representation gaps for each racial group.

- `appendix_A1_weighted_representation_gap.png` – Weighted representation-gap plot showing the direction and magnitude of overrepresentation and underrepresentation.

- `appendix_A2_all_races_weighted_error_bars.png` – Weighted census-versus-jury comparison with approximate 95% binomial error intervals.

- `Iowa_Jury_Representation_Dashboard.twb` – Tableau workbook containing the interactive county-level dashboard.

https://public.tableau.com/shared/94TFZHHK3?:display_count=n&:origin=viz_share_link
---

# Software Requirements

## Software
R version 4.5.1
RStudio
Tableau Public
MySQL Workbench
Git
GitHub

## Required Packages


```r
library(tidyverse)
library(dplyr)
library(tidyr)
library(ggplot2)
library(readr)
library(stringr)
library(scales)
library(forcats)
```


---

# Reproducing the Analysis

Describe how to reproduce the project from start to finish.

1.Open the R project in RStudio.
2.Install all required packages.
3.Run the SQL scripts to create and populate the database.
4.Run the census import script.
5.Run the analysis scripts.
6.Run the visualization scripts.
7.Publish the Tableau dashboard if desired.

Expected runtime is generally a matter of minutes.
---

# Methods

The following methods were used throughout the analysis:

Exploratory data analysis (EDA)
Descriptive statistics
Weighted mean calculations
Standard deviation calculations
Mean absolute error (MAE)
Monte Carlo simulation
Binomial probability models
Chi-square analysis
County-level visualizations
Interactive dashboard development in Tableau

These methods were selected to evaluate differences between expected and observed representation while allowing both statewide and county-level patterns to be examined.
---

# Results

##Key Findings

White jurors were generally overrepresented relative to census estimates.
Hispanic/Latino and Multiracial populations tended to be underrepresented.
Representation varied substantially across counties.
Several observed differences were larger than would be expected under proportional sampling.

## Recommendation

Future work should investigate the factors contributing to underrepresentation, including response rates, eligibility requirements, geographic factors, and the jury selection process itself.

---

# Limitations

Several limitations should be considered when interpreting these findings.

The study is limited to Iowa counties.
Race categories required standardization across datasets.
Several counties had relatively small sample sizes.
Some counties contained missing information.
Weighted analyses emphasize counties with larger jury pools.
Statistical analyses assume proportional random sampling.
Results may be influenced by differences in county reporting practices.

---

# Contact Information

**Randee Goeke or Jude Aboagye:** 

**randee.goeke@drake.edu jude.aboagye@drake.edu:** 
