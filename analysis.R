# Iowa Jury Pool Analysis
# Author: Randee
# R version: 4.5.1
# Purpose: Load raw data files from Iowa Judicial Branch for jury pool analysis (racial bias project)

library(tidyverse)  # data manipulation and reading CSVs
library(janitor)    # cleaning column names

# ---- Load raw data ----
# All files sourced from Iowa Judicial Branch, Jan-Dec 2025
crim_empanelment <- read_csv("data/raw/crim_empanelment_results.csv")     # results of criminal jury empanelment
crim_panel_mr <- read_csv("data/raw/crim_panel_mr_breakdown.csv")        # criminal panel breakdown for jurors who selected multiple races, by county
pool_mr <- read_csv("data/raw/pool_mr_breakdown.csv")                    # same multi-race breakdown, but for the full jury pool instead of just the panel
state_crim_panel_race <- read_csv("data/raw/state_crim_panel_race.csv")  # statewide criminal panel race data
state_pool_race <- read_csv("data/raw/state_pool_race.csv")      # statewide jury pool race data

# ---- Clean column names ----
crim_empanelment <- clean_names(crim_empanelment)
crim_panel_mr <- clean_names(crim_panel_mr)
pool_mr <- clean_names(pool_mr)
state_crim_panel_race <- clean_names(state_crim_panel_race)
state_pool_race <- clean_names(state_pool_race)
