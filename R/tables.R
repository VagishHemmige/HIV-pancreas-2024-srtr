# Purpose: tables: Table 1 before and after matching and after weighting,
#   balance, and Cox model results.
# Needs: cohort, matched, weighted, balance_matched, balance_weighted,
#   cox_fit (08-10); TABLES_DIR, OUTCOMES.
# Produces: HTML tables in tables/ (gitignored). Nothing here leaves the
#   approved environment until the SRTR small-cell rule is recorded and
#   applied (decision pending: #15).
# DRAFT, exploratory: run through R/draft_pipeline.R, not R/main.R.

## ---- table-1-variables
table1_variables <- c(
  MATCHING_VARIABLES,
  "WAITLIST_TIME_YEARS", "REC_BMI", "DON_AGE_IN_MONTHS", "DON_BMI",
  "REC_PA_PRESERV_TM_RAW", "REC_PREV_KI",
  "INDUCTION_LYMPHOCYTE_DEPLETING", "INDUCTION_IL2_RECEPTOR_ANTAGONIST",
  "INDUCTION_STEROIDS", "CENTER_OWN_VOLUME_GROUP", "CENTER_KI_VOLUME_GROUP"
)

## ---- table-1
# Weighted Table 1 would need gtsummary::tbl_svysummary(); balance after
# weighting is in the balance table instead.
dir.create(TABLES_DIR, showWarnings = FALSE)
table1 <- list()
for (type in names(cohort)) {
  samples <- list(
    "Before matching" = cohort[[type]],
    "After matching" = matched[[type]]
  )
  for (sample in names(samples)) {
    table1[[type]][[sample]] <- samples[[sample]] |>
      dplyr::select(dplyr::any_of(c(table1_variables, "HIV_GROUP"))) |>
      gtsummary::tbl_summary(
        by = HIV_GROUP,
        missing = tidyselect::everything() ~ "always",
        missing_stat = "{N_miss}"
      ) |>
      gtsummary::add_difference(tidyselect::everything() ~ "smd") |>
      gtsummary::modify_caption(stringr::str_glue(
        "**{TRANSPLANT_TYPE_LABELS[[type]]}: {sample}**"
      ))
  }
}

## ---- table-balance
balance_all <- dplyr::bind_rows(
  dplyr::bind_rows(balance_matched, .id = "type"),
  dplyr::bind_rows(balance_weighted, .id = "type")
)

## ---- table-cox
cox_tables <- list()
for (analysis in names(cox_fit)) {
  for (type in names(cox_fit[[analysis]])) {
    outcome_tables <- list()
    for (outcome in names(cox_fit[[analysis]][[type]])) {
      outcome_tables[[outcome]] <- gtsummary::tbl_regression(
        cox_fit[[analysis]][[type]][[outcome]], exponentiate = TRUE
      )
    }
    outcome_labels <- OUTCOMES |>
      dplyr::filter(.data$outcome %in% names(outcome_tables)) |>
      dplyr::arrange(match(.data$outcome, names(outcome_tables))) |>
      dplyr::pull(.data$label)
    cox_tables[[analysis]][[type]] <- gtsummary::tbl_stack(
      outcome_tables, group_header = outcome_labels
    )
  }
}

## ---- save-tables
for (type in names(table1)) {
  for (sample in names(table1[[type]])) {
    file_name <- stringr::str_glue(
      "table1_{type}_{stringr::str_replace_all(tolower(sample), ' ', '_')}.html"
    )
    gtsummary::as_gt(table1[[type]][[sample]]) |>
      gt::gtsave(file.path(TABLES_DIR, file_name))
  }
}
for (analysis in names(cox_tables)) {
  for (type in names(cox_tables[[analysis]])) {
    gtsummary::as_gt(cox_tables[[analysis]][[type]]) |>
      gt::gtsave(file.path(TABLES_DIR, stringr::str_glue("cox_{analysis}_{type}.html")))
  }
}
