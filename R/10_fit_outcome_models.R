# Purpose: Kaplan-Meier estimates and Cox models of each outcome by HIV
#   status, in the matched cohort and in the weighted cohort (plan §8).
# Needs: matched (08_match_recipients.R), weighted (09_estimate_weights.R);
#   OUTCOMES, MATCHED_COX_VARIANCE.
# Produces: km_fit and cox_fit, nested lists indexed
#   [[analysis]][[type]][[outcome]], where analysis is "matched" or "weighted".
# DRAFT, exploratory: run through R/draft_pipeline.R, not R/main.R.
# Decision pending: #7 (primary outcome), #14 (how matching enters the
#   model), #21 (role of the weighted analysis).

## ---- outcome-formulas
surv_formula <- function(outcome) {
  stats::as.formula(stringr::str_glue(
    "survival::Surv({outcome}_yrs, {outcome}_BINARY) ~ HIV_POSITIVE"
  ))
}

## ---- fit-outcome-models
km_fit <- list(matched = list(), weighted = list())
cox_fit <- list(matched = list(), weighted = list())
for (type in names(matched)) {
  type_outcomes <- OUTCOMES |>
    dplyr::filter(stringr::str_detect(.data$types, type)) |>
    dplyr::pull(.data$outcome)
  for (outcome in type_outcomes) {
    f <- surv_formula(outcome)

    # Matched cohort (decision pending: #14; provisional as in 2024)
    km_fit$matched[[type]][[outcome]] <- survival::survfit(
      f, data = matched[[type]]
    )
    cox_fit$matched[[type]][[outcome]] <- if (MATCHED_COX_VARIANCE == "cluster") {
      survival::coxph(f, data = matched[[type]], weights = weights,
                      cluster = subclass)
    } else {
      survival::coxph(f, data = matched[[type]])
    }

    # Weighted cohort, robust variance for estimated weights
    km_fit$weighted[[type]][[outcome]] <- survival::survfit(
      f, data = weighted[[type]], weights = IPW
    )
    cox_fit$weighted[[type]][[outcome]] <- survival::coxph(
      f, data = weighted[[type]], weights = IPW, robust = TRUE
    )
  }
}
