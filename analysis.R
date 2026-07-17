library(tidyverse)
library(janitor)

crim_empanelment <- read_csv("data/raw/crim_empanelment_results.csv")
crim_panel_mr <- read_csv("data/raw/crim_panel_mr_breakdown.csv")
pool_mr <- read_csv("data/raw/pool_mr_breakdown.csv")
state_crim_panel_race <- read_csv("data/raw/state_crim_panel_race.csv")
state_pool_race <- read_csv("data/raw/state_pool_race.csv")