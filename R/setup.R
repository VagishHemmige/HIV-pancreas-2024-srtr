# Purpose: attach packages and define constants shared by every script.
# Needs: nothing. Produces: attached packages and named constants.
# SRTR files are located only through sRtr (set_srtr_wd() and SRTR_WD).
#
# DRAFT. Constants marked "Decision pending" hold a provisional value until the
# linked decision issue is settled. Where the 2024 script made a choice, the
# provisional value is what it did; where it made none, the comment says so.
# Change the value here, nowhere else, once the decision is made.

## ---- load-packages
library(sRtr)        # SRTR files, labels, PDRI, death and time-to-event helpers
library(dplyr)
library(tidyr)
library(stringr)
library(labelled)
library(flowchart)   # cohort flow diagram and analytic cohort from the same code
library(MatchIt)     # propensity-score matching
library(survival)
library(sandwich)
library(gtsummary)
library(ggsurvfit)
library(ggplot2)
library(sf)

## ---- define-constants
# Transplant types analysed, each separately (plan §2). Names are used as list
# keys throughout: values are the SRTR file keys.
TRANSPLANT_TYPES <- c(KP = "TX_KP", PA = "TX_PA")
TRANSPLANT_TYPE_LABELS <- c(KP = "Kidney-pancreas", PA = "Pancreas alone")

# Data release (plan §3). Decision pending: #8. The 2024 script used 2303.
# sRtr reads whichever release SRTR_WD points to; this label is used in outputs.
SRTR_RELEASE <- "2303"

# Cohort (plan §4)
MIN_AGE_AT_TRANSPLANT <- 16
# Decision pending: #17 (repeat recipients) and #19 (pancreas alone vs pancreas
# after kidney). Provisional, as in 2024: every transplant record is included,
# and every record in TX_PA counts as pancreas alone.

# Exposure (plan §5). Decision pending: #9. Provisional, as in 2024: every
# value of REC_HIV_STAT other than "P", including missing, counts as negative.
HIV_POSITIVE_CODE <- "P"
HIV_NOT_POSITIVE_RULE <- "negative"   # alternative: "exclude"

# Diagnosis groups from REC_DGN (format DGN), confirmed in the plan §5.
DIAGNOSIS_CODES <- list(
  "Type 1 diabetes" = c(3011, 3038, 3069, 5001),
  "Type 2 diabetes" = c(3012, 3039, 3070, 5002)
)
DIAGNOSIS_OTHER_LABEL <- "Other"

# Recipient race code for Black (CAN_RACE), as used in matching (plan §6).
RACE_BLACK_CODE <- 16

# PDRI missing preservation time (plan §5). Decision pending: #10.
# Provisional: mean imputation for recipients with HIV only, within transplant
# type, the closest listed option to what the 2024 script did.
PDRI_IMPUTE_RULE <- "hiv_only"        # alternatives: "everyone", "none"

# Induction (plan §5). Decision pending: #11. Provisional, as in 2024: any
# listed drug counts, whether or not IMMUNO records it as induction.
INDUCTION_USE_INDUCTION_FLAG <- FALSE
INDUCTION_DRUG_CODES <- list(
  lymphocyte_depleting = c(-1, 14, 15, 41, 50),
  il2_receptor_antagonist = c(20, 42, 43),
  steroids = c(1, 2, 49)
)

# Center volume groups (plan §8), transplants per center per year.
# Decision pending: #4 (per year or averaged; kidney cut-points).
CENTER_VOLUME_BREAKS <- list(
  KP = c(Low = 6, Medium = 13),     # 14 or more is High (Alhamad 2017)
  PA = c(Low = 3, Medium = 10),     # 11 or more is High (Alhamad 2017)
  KI = c(Low = 65, Medium = 110, "Medium-High" = 195)   # as in 2024
)

# Matching (plan §6), confirmed.
MATCH_RATIO <- 10
MATCH_METHOD <- "nearest"
MATCH_DISTANCE <- "glm"
MATCH_REPLACE <- FALSE
MATCHING_VARIABLES <- c("PDRI", "YEAR_TRANSPLANT", "DIAGNOSIS_GROUP",
                        "CAN_GENDER", "REC_AGE_AT_TX", "REC_BLACK")
# Decision pending: #12. No balance threshold is applied yet; balance is
# reported only.
BALANCE_SMD_THRESHOLD <- NA_real_

# Inverse probability weighting (plan §6). Decision pending: #21.
# Provisional (the 2024 script had no weighting): the matching variables,
# unstabilized ATT weights, no truncation.
IPW_COVARIATES <- MATCHING_VARIABLES
IPW_TRUNCATE_PERCENTILE <- NA_real_   # for example 0.99

# Outcomes (plan §7). One row per outcome; `types` lists where it applies.
OUTCOMES <- tibble::tribble(
  ~outcome,          ~label,                                ~types,
  "GRAFT_LOSS_KI",   "Death-censored kidney graft loss",    "KP",
  "GRAFT_LOSS_PA",   "Death-censored pancreas graft loss",  "KP,PA",
  "REJECTION_KI",    "Treated acute kidney rejection",      "KP",
  "REJECTION_PA",    "Treated acute pancreas rejection",    "KP,PA",
  "DEATH",           "Death",                               "KP,PA",
  "MALIGNANCY",      "Malignancy",                          "KP,PA"
)
OUTCOME_TIME_UNITS <- "years"
# Treated rejection during the transplant hospitalization (code 1 in
# REC_ACUTE_REJ_EPISODE and REC_ACUTE_REJ_EPISODE_PA).
REJECTION_TREATED_CODE <- 1
# Censoring (plan §7). Decision pending: #13. Provisional, as in 2024: every
# outcome is followed to the organ's last follow-up date, with no censoring at
# death or graft loss; kidney-pancreas death uses the kidney last follow-up.
KP_DEATH_CENSOR_DATE <- "TFL_LAFUDATEKI"

# Outcome models (plan §8). Decision pending: #14. Provisional, as in 2024:
# unadjusted Cox model in the matched cohort, ignoring matched sets.
MATCHED_COX_VARIANCE <- "model"       # alternative: "cluster" (by matched set)

# Descriptive geography and concentration (plan §8), as in 2024.
LORENZ_START_YEAR <- c(KP = 2009, PA = 2014)
# Decision pending: #6. Provisional, as in 2024: pancreas centers from HRSA,
# dropping names containing "Children" except these two.
CENTER_MAP_KEEP_CHILDRENS <- c(
  "Memorial Regional Hospital/Joe DiMaggio Children's Hospital",
  "Providence Sacred Heart Medical Center & Children's Hospital"
)

# Disclosure (plan §10). Decision pending: #15. Until the SRTR small-cell rule
# is recorded, nothing produced by tables.R or figures.R leaves the approved
# environment.
SMALL_CELL_THRESHOLD <- NA_integer_

# Output folders (gitignored until cleared for release)
TABLES_DIR <- "tables"
FIGURES_DIR <- "figures"
