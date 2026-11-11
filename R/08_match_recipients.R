# Purpose: match recipients with HIV to recipients without HIV on a propensity
#   score, separately for each transplant type (plan §6), and report balance.
# Needs: cohort (07_build_outcomes.R); MATCHING_VARIABLES, MATCH_* constants.
# Produces: match_fit (MatchIt objects), matched (named list of matched data,
#   with `weights` and `subclass` from MatchIt), balance_matched (SMD tables).
# DRAFT, exploratory: run through R/draft_pipeline.R, not R/main.R.

## ---- match-formula
match_formula <- stats::reformulate(MATCHING_VARIABLES, response = "HIV_POSITIVE")

## ---- check-matching-variables
# MatchIt cannot match rows with missing matching variables. How such rows are
# handled is open (#18), so the draft stops rather than dropping them.
for (type in names(cohort)) {
  complete_rows <- cohort[[type]] |>
    dplyr::select(dplyr::all_of(MATCHING_VARIABLES)) |>
    stats::complete.cases()
  if (!all(complete_rows)) {
    stop("Missing matching variables in the ", type, " cohort; ",
         "handling is a pending decision (#18).", call. = FALSE)
  }
}

## ---- match-cohorts
# Decision pending: #12 (balance criteria). Balance is reported, not enforced.
match_fit <- list()
matched <- list()
balance_matched <- list()
for (type in names(cohort)) {
  match_fit[[type]] <- MatchIt::matchit(
    match_formula,
    data = cohort[[type]],
    method = MATCH_METHOD,
    distance = MATCH_DISTANCE,
    ratio = MATCH_RATIO,
    replace = MATCH_REPLACE
  )
  matched[[type]] <- MatchIt::match.data(match_fit[[type]])
  balance_matched[[type]] <- dplyr::bind_rows(
    balance_table(cohort[[type]], MATCHING_VARIABLES, "HIV_POSITIVE") |>
      dplyr::mutate(sample = "Before matching"),
    balance_table(matched[[type]], MATCHING_VARIABLES, "HIV_POSITIVE",
                  weights = "weights") |>
      dplyr::mutate(sample = "After matching")
  )
}
