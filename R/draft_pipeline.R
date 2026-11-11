# Purpose: run the DRAFT pipeline in dependency order. These scripts are
#   exploratory (AGENTS.md, "Exploration and definitive analysis"): each
#   moves into R/main.R, with its website page, once its open decisions are
#   settled and it has been run in the approved environment.
# Run from the project root in a fresh session, with SRTR_WD set through
#   sRtr::set_srtr_wd(). Only an authorized person runs this on SRTR data.

source("R/setup.R")
source("R/functions.R")
source("R/01_load_srtr_files.R")
source("R/02_derive_variables.R")
source("R/03_calculate_pdri.R")
source("R/04_build_cohort.R")
source("R/05_add_induction.R")
source("R/06_add_center_volume.R")
source("R/07_build_outcomes.R")
source("R/08_match_recipients.R")
source("R/09_estimate_weights.R")
source("R/10_fit_outcome_models.R")
source("R/tables.R")
source("R/figures.R")
