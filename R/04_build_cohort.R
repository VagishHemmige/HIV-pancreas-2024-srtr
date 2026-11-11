# Purpose: build the analytic cohort for each transplant type with the
#   flowchart package, applying the plan's exclusions in order (plan §4).
# Needs: tx_derived (03_calculate_pdri.R); MIN_AGE_AT_TRANSPLANT,
#   TRANSPLANT_TYPE_LABELS.
# Produces: cohort_fc (flowchart objects, split by HIV status, for the
#   diagram) and cohort (named list of analytic cohorts: the data from the
#   last exclusion step).
# DRAFT, exploratory: run through R/draft_pipeline.R, not R/main.R.
# Decision pending: #17 (repeat recipients), #18 (complete-case exclusions),
#   #19 (pancreas alone vs pancreas after kidney).

## ---- cohort-labels
cohort_labels <- list(
  start = "Transplants in the SRTR file",
  no_tx_date = "Transplant date recorded",
  age = stringr::str_glue("Age {MIN_AGE_AT_TRANSPLANT} or older at transplant"),
  followup = "Any follow-up recorded",
  pdri = "PDRI could be calculated"
)

## ---- build-cohort
cohort_fc <- list()
cohort <- list()
for (type in names(tx_derived)) {
  steps <- tx_derived[[type]] |>
    flowchart::as_fc(
      label = paste(TRANSPLANT_TYPE_LABELS[[type]], cohort_labels$start)
    ) |>
    flowchart::fc_filter(!is.na(REC_TX_DT),
                         label = cohort_labels$no_tx_date, show_exc = TRUE) |>
    flowchart::fc_filter(REC_AGE_AT_TX >= MIN_AGE_AT_TRANSPLANT,
                         label = cohort_labels$age, show_exc = TRUE) |>
    flowchart::fc_filter(!is.na(REC_PX_STAT_DT),
                         label = cohort_labels$followup, show_exc = TRUE) |>
    flowchart::fc_filter(is.finite(PDRI),
                         label = cohort_labels$pdri, show_exc = TRUE)

  # The analytic cohort is the data from the last exclusion step.
  cohort[[type]] <- flowchart::fc_view(steps, what = "data")
  # The diagram also shows the split by HIV status.
  cohort_fc[[type]] <- flowchart::fc_split(steps, HIV_GROUP)
}
