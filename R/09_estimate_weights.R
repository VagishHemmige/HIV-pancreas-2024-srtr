# Purpose: inverse probability weights for the average effect among
#   recipients with HIV (ATT), separately for each transplant type (plan §6),
#   and balance after weighting.
# Needs: cohort (07_build_outcomes.R); IPW_COVARIATES, IPW_TRUNCATE_PERCENTILE;
#   att_weights() and balance_table() from functions.R.
# Produces: ipw_fit (propensity models), weighted (named list: the cohort with
#   PS and IPW columns), balance_weighted (SMD tables).
# DRAFT, exploratory: run through R/draft_pipeline.R, not R/main.R.
# Decision pending: #21 (covariates, role, stabilization and truncation).

## ---- fit-weights
ipw_formula <- stats::reformulate(IPW_COVARIATES, response = "HIV_POSITIVE")
ipw_fit <- list()
weighted <- list()
balance_weighted <- list()
for (type in names(cohort)) {
  ipw_fit[[type]] <- stats::glm(ipw_formula, data = cohort[[type]],
                                family = stats::binomial())
  weighted[[type]] <- cohort[[type]] |>
    dplyr::mutate(
      PS = stats::predict(ipw_fit[[type]], newdata = cohort[[type]],
                          type = "response"),
      IPW = att_weights(.data$HIV_POSITIVE, .data$PS,
                        truncate_percentile = IPW_TRUNCATE_PERCENTILE)
    )
  balance_weighted[[type]] <- balance_table(
    weighted[[type]], IPW_COVARIATES, "HIV_POSITIVE", weights = "IPW"
  ) |>
    dplyr::mutate(sample = "After weighting")
}
