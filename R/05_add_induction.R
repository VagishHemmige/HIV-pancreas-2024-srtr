# Purpose: add induction therapy classes from IMMUNO to each cohort.
# Needs: cohort (04_build_cohort.R); INDUCTION_DRUG_CODES,
#   INDUCTION_USE_INDUCTION_FLAG; induction_flags() from functions.R.
# Produces: cohort with INDUCTION_* columns (NA where a transplant has no
#   IMMUNO rows).
# DRAFT, exploratory: run through R/draft_pipeline.R, not R/main.R.

## ---- add-induction
# Decision pending: #11. For TX_KP, IMMUNO rows are joined by TRR_ID; whether
# kidney-pancreas immunosuppression is recorded under TRR_ID or TRR_ID_PA is
# unverified (VagishHemmige/sRtr#37). Transplants with no IMMUNO rows keep NA.
for (type in names(cohort)) {
  immuno <- sRtr::load_srtr_file("IMMUNO",
                                 trr_id_filter = cohort[[type]]$TRR_ID)
  flags <- induction_flags(immuno, INDUCTION_DRUG_CODES,
                           use_induction_flag = INDUCTION_USE_INDUCTION_FLAG)
  n_before <- nrow(cohort[[type]])
  cohort[[type]] <- cohort[[type]] |>
    dplyr::left_join(flags, by = dplyr::join_by("TRR_ID"),
                     relationship = "one-to-one")
  stopifnot(nrow(cohort[[type]]) == n_before)
}

