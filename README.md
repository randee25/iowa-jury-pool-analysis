# Racial Disparity in Iowa Jury Pools 

**Jude Aboagye and Randee Goeke:** 
**STAT 230:** 
**Summer 2026:** 

---

# Project Summary

Provide a super brief description of the project. (3-6 sentences)

## Research Question

What question are you trying to answer? (1-3 sentences)

## Motivation

Why is this problem important? i.e., why should your chosen audience care? (1-3 sentences)

## Summary of Findings

Provide a short summary of the most important findings. (2-4 sentences is fine)

---

# Data

## Data Source

Describe where the data came from - urls are appropriate here. 
If you scraped your data, you'll talk about the code you used to do that below. 


Examples:

- Public data source
- Company-provided data
- Survey data


## Data Files

| File | Description |
|--------|--------|
| data/raw_data.csv | Original data |
| data/cleaned_data.csv | Cleaned analysis dataset |

## Important Variables

| Variable | Description |
|-----------|-------------|
| variable_1 | Description |
| variable_2 | Description |
| variable_3 | Description |

If you have extremely large data, this may be too tedious. Feel free to link
to an existing data dictionary if that is possible.

---

# Project Organization

Using github is not required for this project. This section is largely relevant for those who choose to use github as a collaboration and sharing tool.
It is meant to illustrate how you have organized your project directory (folder).
When you update this section, keep the ```text and ```. Only modify what is between those two bits.

```text
project/

├── README.md
├── report.Rmd
├── report.pdf
├── data/
├── scripts/
└── figures/
```

## Key Files

### data/

Describe the contents of this folder.

### scripts/

Describe the contents of this folder (should be each of your code files). For example
- cleaning_code.R: describe what this does
- modeling_code.R: describe what this does
- scraping_code.py: describe what this does

### figures/

Describe the contents of this folder. For example:
- figure1.pdf: a scatterplot showing the relationship between temperature and impulsive spending patterns. code to reproduce can be found in scripts/modeling_code.R
- figure2.pdf: a barchart showing....

---

# Software Requirements

## Software
modify this section to simply explain what software you used.
- R version: (or python version or Tableau... what did you use for software)
- RStudio version: (if applicable)

## Required Packages

If you used R or python you almost certainly used packages. list them here.
Use the formatting i used below (i.e., keep the tickmarks and the r - this will format it correctly when it renders)

```r
library(tidyverse)
library(caret)
library(randomForest)
```


---

# Reproducing the Analysis

Describe how to reproduce the project from start to finish.

1. Open the R Project.
2. Install required packages.
3. Run data cleaning scripts. Which ones? in which order?
4. Run analysis scripts. Which ones? in which order?
5. Knit report.Rmd.

Expected runtime: Some of my analyses take days or weeks to run. Is that the case? or is it a matter of minutes?

---

# Methods

Describe the analytical methods used.

Examples:

- Exploratory Data Analysis
- Linear Regression
- Logistic Regression
- Random Forest
- Clustering - hierarchical or k-means?
- Latent Dirichlet Allocation

Explain why these methods were selected.

---

# Results

This is a bit redundant given the beginning but it's not a bad idea. 

## Key Findings

- Finding 1
- Finding 2
- Finding 3

## Recommendation

Provide a practical recommendation based on the results.

---

# Limitations

Describe important limitations of the project. I take this portion very seriously.

Examples:

- Small sample size
- Missing data
- Nonrandom sample (limited ability to generalize)
- Data might be fake
- Limited geographic scope
- Modeling assumptions
  - e.g., we were unable to explore interactions. This means we are assuming the effect of vehicle power on risky behavior is the same regardless of vehicle usage. 
  - We are assuming linearity, which is questionable because...
  - Residual plots show...
  - The domain of the response is {0,1} but we fit an OLR and this is a problem because...
  


---

# Contact Information

**Randee Goeke:** 

**randee.goeke@drake.edu:** your.email@example.com
