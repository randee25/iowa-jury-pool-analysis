# Racial Representation in Iowa Jury Pools 

**Jude Aboagye and Randee Goeke:** 
**STAT 230:** 
**Summer 2026** 

---
# Project Summary

This project examines whether the racial composition of Iowa jury pools reflects the demographic composition of the counties from which jurors are drawn. County-level census data were combined with Iowa jury data to compare expected and observed representation across racial and ethnic groups. Exploratory data analysis, weighted summary statistics, visualization techniques, and statistical tests were used to evaluate potential disparities. A supplementary analysis was also conducted to examine changes in racial and ethnic representation across multiple stages of the jury-selection process. An interactive Tableau dashboard was developed to allow users to explore county-level patterns throughout Iowa.

---

## Research Question

To what extent do the racial demographics of Iowa jury pools differ from the racial demographics of the counties they represent? Additionally, are observed differences large enough to suggest systematic underrepresentation rather than random sampling variation?

A secondary analysis examined whether racial and ethnic representation changed across successive stages of the jury-selection process.

---

## Motivation

The right to an impartial jury is a fundamental principle of the American legal system. If certain groups are consistently underrepresented in jury pools, the fairness and representativeness of the judicial process may be affected. Understanding these patterns may help identify structural barriers to participation and improve the jury-selection process.

---

## Summary of Findings

White jurors generally appeared to be overrepresented relative to county census populations, whereas Hispanic/Latino and Multiracial populations appeared to be underrepresented. Black, Asian, American Indian or Alaska Native (AIAN), and Native Hawaiian or Pacific Islander (NHPI) populations generally displayed smaller differences. Representation patterns also varied substantially across counties.

Supplementary analyses indicated that the demographic composition of jurors may change across successive stages of the jury-selection process, suggesting that disparities can emerge or widen after the initial jury pool is assembled.

---

# Data

## Data Source

### Iowa Jury Data

- Jury data supplied by Professor Lovell
- County-level jury pool data
- County-level empanelment data

### Census Data

- U.S. Census Bureau
- American Community Survey (ACS) 2024 5-Year Estimates
- County-level estimates for Iowa
- Tables used:
  - **B02001 – Race**
  - **B03002 – Hispanic or Latino Origin by Race**
  - **B03003 – Hispanic or Latino Origin**

Source: https://data.census.gov/

## Data Files

- `data/raw/`   -  Contains the original Iowa jury datasets used in the project, including county-level jury pool and empanelment data. 
- `data/processed/`  - Contains cleaned, standardized, and merged datasets created from the raw jury data and ACS Census data. These files serve as the primary inputs for the statistical analyses and visualizations

## Important Variables

| Variable | Description |
|---|---|
| `county_name` | Iowa county name |
| `race_short` | Standardized race or ethnicity category |
| `jury_pool_pct` | Percentage of individuals belonging to a particular race within the overall jury pool |
| `county_population_pct` | Percentage of the county population belonging to a particular race |
| `representation_gap` | Difference between jury and census percentages |
| `adjusted_total` | Number of jurors included in the analysis |
| `jury_count` | Number of jurors belonging to a particular race category |
| `panel_pct` | Percentage of individuals belonging to a particular race within the criminal panel stage |
| `juror_pct` | Percentage of individuals belonging to a particular race among empaneled jurors |
| `pool_to_panel_change` | Percentage-point change from the pool stage to the panel stage |
| `panel_to_juror_change` | Percentage-point change from the panel stage to the empaneled juror stage |
| `pool_to_juror_change` | Percentage-point change from the pool stage to the empaneled juror stage |
---
## Project Organization

```
├── README.md
├── data/
│   ├── raw/
│   └── processed/
├── outputs/
│   ├── figures/
│   ├── tables/
│   └── Tableau/
├── scripts/
│   ├── get_census_data.R
│   ├── main_analysis.R
│   ├── stage_analysis.R
│   └── visualizations.R
└── sql/
    ├── analytics_views.sql
    ├── create_clean_tables.sql
    ├── create_lookup_table.sql
    ├── create_raw_tables.sql
    ├── create_schemas.sql
    └── create_tables.sql
```
---

## Key Files

### `data/`
This folder contains both the original data files and the processed datasets used throughout the analysis.

| File | Description |
|---|---|
| `data/raw/iowa_race.csv` | County-level Census demographic data used to provide expected racial and ethnic population proportions for comparison with the jury data. |
| `data/processed/new_main_view.csv` | Consolidated analysis-ready dataset containing court, county, jury-selection stage, race or ethnicity, jury counts and percentages, Census percentages, and representation differences. |
| `data/processed/overall_pool_final.csv` | Final processed dataset for the overall jury pool used in the primary analysis comparing jury pool composition with county Census demographics. |

Additional raw, intermediate, and processed files are retained in the repository to document the complete data-cleaning and preparation workflow.
---

## Script Descriptions

### `get_census_data.R`
Imports, cleans, and processes county-level demographic data obtained from the United States Census Bureau.

Primary tasks include:
- Importing Census tables
- Filtering data to Iowa counties
- Standardizing race and ethnicity categories
- Creating processed datasets for analysis

---

### `main_analysis.R`
Performs the primary statistical analyses used throughout the project.

Analyses include:
- Descriptive statistics
- Mean absolute error (MAE) and root mean squared error (RMSE)
- One-sample t-tests
- Exact binomial tests
- Monte Carlo simulations
- Court-level summaries
- Data exports
- Preparation of data for visualizations

---

### `stage_analysis.R`
Performs supplementary analyses examining changes in racial and ethnic representation across multiple stages of the jury-selection process.

Analyses include:
- Calculating statewide racial and ethnic composition at each stage
- Measuring percentage-point changes between the overall pool, criminal panel, and empaneled juror stages
- Generating county-level summaries
- Performing Wilcoxon signed-rank tests
- Exporting summary tables and figures
- Preparing data for stage-based visualizations

---

### `visualizations.R`
Creates the figures used in the report and appendix.

Tasks include:
- Reshaping data for visualization
- Creating publication-quality graphics
- Exporting figures to the `outputs/figures` directory
- Maintaining consistent formatting, labeling, and color schemes

---

### `sql/`
This folder contains SQL scripts used to construct the database, import data, clean tables, and create analytical views.

| File | Description |
|------|-------------|
| `create_schemas.sql` | Creates the database schema structure. |
| `create_raw_tables.sql` | Creates tables for the imported raw data. |
| `create_clean_tables.sql` | Creates tables containing cleaned data. |
| `create_lookup_table.sql` | Creates lookup tables used to standardize values. |
| `create_tables.sql` | Creates additional tables required for analysis. |
| `analytics_views.sql` | Creates analytical views used in R. |

---

## outputs/

### Tables

#### Overall analysis

| File | Description |
|------|-------------|
| `overall_results_summary.csv` | Summary statistics for all demographic groups, including mean representation gap, median gap, mean absolute error (MAE), root mean squared error (RMSE), and correlation measures. |
| `race_level_summary.csv` | Summary statistics calculated separately for each demographic group. |
| `t_test_summary.csv` | Results of one-sample t-tests comparing observed jury representation with expected Census representation. |
| `binomial_summary_by_race.csv` | Summary of exact binomial test results for each demographic group. |
| `court_flag_summary.csv` | Court-level summary of demographic groups flagged as significantly underrepresented and those falling below one-standard-deviation and two-standard-deviation thresholds. |
| `significant_underrepresentation_results.csv` | Detailed results for court-demographic-group combinations identified as significantly underrepresented. |
| `binomial_results.csv` | Complete set of exact binomial test results. |
| `monte_carlo_validation.csv` | Summary of agreement between the exact binomial and Monte Carlo approaches. |

#### Stage analysis

| File | Description |
|------|-------------|
| `statewide_stage_composition.csv` | Statewide racial and ethnic composition at each stage of the jury-selection process. |
| `statewide_stage_changes.csv` | Percentage-point changes in representation between jury-selection stages. |
| `county_stage_changes.csv` | County-level changes in representation across stages. |
| `stage_wilcoxon_tests.csv` | Results of Wilcoxon signed-rank tests comparing changes in representation across stages. |

### Figures

- `figure_1_census_vs_jury.png` – Scatterplot comparing county census percentages with jury pool percentages for each racial group.

- `figure_2_weighted_mae_by_race.png` – Mean absolute error (MAE) plot summarizing the average magnitude of representation differences across racial groups.

- `figure_3_minority_census_vs_jury.png` – Bar chart comparing weighted census percentages with weighted jury pool percentages for minority populations.

- `figure_4_gap_distribution_boxplot.png` – Boxplots illustrating the distribution of county-level representation gaps for each racial group.
  
- `figure_5_stage_composition_barplot.png` – Comparison of racial and ethnic composition across the jury pool, criminal panel, and empaneled juror stages.
  
- `figure_6_stage_percentage_point_changes.png` – Percentage-point changes in representation across jury-selection stages.

- `appendix_A1_weighted_representation_gap.png` – Weighted representation-gap plot showing the direction and magnitude of overrepresentation and underrepresentation.

- `appendix_A2_all_races_weighted_error_bars.png` – Weighted census-versus-jury comparison with approximate 95% binomial error intervals.

---

## Interactive Tableau Dashboard

An interactive Tableau dashboard was developed to allow users to explore county-level jury representation patterns across Iowa. Users can examine Census and jury percentages, raw counts, absolute representation gaps, relative differences, and geographic patterns for each demographic group.

**Tableau dashboard:**  
https://public.tableau.com/shared/B4SZM9Z2P?:display_count=n&:origin=viz_share_link

---

# Software Requirements

## Software
- **R 4.6.1 / RStudio** — Statistical analysis, Census data retrieval, data processing, and visualization
- **MySQL Workbench 8.0.47** — SQL-based data cleaning, restructuring, standardization, and creation of analytical views
- **Tableau Public 2026.2.1** — Development and publication of the interactive county-level dashboard
- **Git / GitHub** — Version control, project organization, and repository hosting
  
## Required Packages

```r
library(tidyverse)
library(tidycensus)
library(scales)
```


---
# Reproducing the Analysis

Follow these steps to reproduce the analysis:

1. Open the R project in RStudio and install the required R packages.

2. Run `get_census_data.R` to retrieve and prepare the county-level Census data.

3. Run the SQL scripts in the `sql/` directory to import, clean, standardize, and organize the jury and Census data into analysis-ready tables and views.

4. Run `main_analysis.R` to perform the primary analysis comparing overall jury pool composition with county Census demographics.

5. Run `stage_analysis.R` to perform the supplementary analysis examining changes across the overall pool, criminal panel, and empanelment stages.

6. Run `visualizations.R` to generate the figures and tables used in the report.

7. To recreate the interactive dashboard, open Tableau Public and connect to `data/processed/overall_pool_final.csv`.

8. Build or update the Tableau dashboard using the processed overall-pool data and publish to Tableau Public if desired.

Expected runtime: a matter of minutes.

---

# Methods

The following methods were used throughout the analysis:

- Exploratory data analysis (EDA)
- Descriptive statistics
- Weighted summary statistics
- Mean absolute error (MAE)
- Root mean squared error (RMSE)
- Pearson correlation analysis
- One-sample t-tests
- Exact binomial tests
- Monte Carlo simulations
- Wilcoxon signed-rank tests
- County-level visualizations
- Interactive dashboard development in Tableau

These methods were selected to evaluate differences between expected and observed representation while allowing both statewide and county-level patterns to be examined.

---

# Results
## Key Findings

- Jury composition generally reflected county demographics, but meaningful differences were observed for several racial and ethnic groups.
  
- White jurors tended to be overrepresented, while Multiracial and Hispanic/Latino populations showed the largest patterns of underrepresentation.
  
- Representation patterns varied across counties, demonstrating the importance of examining both statewide and county-level results.
  
- Exact binomial tests and Monte Carlo simulations produced highly consistent results when evaluating potential underrepresentation.
  
- Supplementary stage analyses indicated that demographic composition may change between the initial jury pool, criminal panel, and empaneled juror stages.

### Notes on Interpretation

These findings should be interpreted cautiously. Differences in demographic classifications between the Census and jury data, relatively small population sizes for some demographic groups, and substantial county-level variation may have influenced the observed results. Consequently, the findings should be viewed as evidence of patterns of representation rather than definitive evidence of bias or intentional exclusion.

---
## Recommendations

Future work could incorporate multiple years of jury data, examine additional demographic characteristics, and further investigate how representation changes throughout the jury-selection process. The analytical framework could also be developed into an interactive monitoring tool that updates as new Census and jury data become available.


---

 ## Limitations

- Differences in demographic definitions, reporting, and classification between Census and jury data may affect comparisons.
  
- Several decisions were required to standardize racial and ethnic categories across datasets. For example, "White alone" and "Hispanic only" categories were used to reduce overlap among demographic groups. In addition, the jury data relied on self-reported information, and some records were classified as "Unknown" or "Not provided" and were excluded from portions of the analysis.
  
- Small sample sizes for some counties and demographic groups may increase variability.
  
- Census values are estimates and are themselves subject to sampling error.
  
- Jury representation may be influenced by factors not captured in the available data, including eligibility requirements, excusals, disqualifications, nonresponses, and other stages of jury selection.
  
- Results are specific to on year in Iowa and should not be assumed to generalize to other jurisdictions.

---

## Contact Information

For questions regarding this project, please contact:

- Randee Goeke – randee.goeke@drake.edu
- Jude Aboagye – jude.aboagye@drake.edu
