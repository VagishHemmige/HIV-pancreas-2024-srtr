# Smoke test of R/08_match_recipients.R, R/09_estimate_weights.R and
# R/10_fit_outcome_models.R on a
# synthetic cohort. Checks that the scripts run and produce the expected
# objects; the numbers are synthetic and mean nothing.

env <- new.env()
source_setup_constants(env)
source_project_script("functions.R", env)

kp_outcomes <- env$OUTCOMES$outcome[grepl("KP", env$OUTCOMES$types)]
pa_outcomes <- env$OUTCOMES$outcome[grepl("PA", env$OUTCOMES$types)]
env$cohort <- list(
  KP = synthetic_cohort(600, kp_outcomes, seed = 1),
  PA = synthetic_cohort(300, pa_outcomes, n_hiv = 20, seed = 2)
)

test_that("matching runs and keeps up to MATCH_RATIO controls per case", {
  source_project_script("08_match_recipients.R", env)
  for (type in names(env$cohort)) {
    m <- env$matched[[type]]
    n_cases <- sum(env$cohort[[type]]$HIV_POSITIVE)
    expect_equal(sum(m$HIV_POSITIVE), n_cases)
    expect_lte(sum(m$HIV_POSITIVE == 0), env$MATCH_RATIO * n_cases)
    expect_true(all(c("weights", "subclass") %in% names(m)))
    expect_setequal(unique(env$balance_matched[[type]]$sample),
                    c("Before matching", "After matching"))
  }
})

test_that("matching stops on missing matching variables", {
  env_missing <- new.env()
  source_setup_constants(env_missing)
  source_project_script("functions.R", env_missing)
  env_missing$cohort <- env$cohort
  env_missing$cohort$KP$PDRI[1] <- NA
  expect_error(source_project_script("08_match_recipients.R", env_missing), "#18")
})

test_that("weighting gives exposed weight 1 and positive weights to others", {
  source_project_script("09_estimate_weights.R", env)
  for (type in names(env$cohort)) {
    w <- env$weighted[[type]]
    expect_true(all(w$IPW[w$HIV_POSITIVE == 1] == 1))
    expect_true(all(w$IPW[w$HIV_POSITIVE == 0] > 0))
    expect_equal(nrow(w), nrow(env$cohort[[type]]))
  }
})

test_that("models are fitted for each outcome that applies to each type", {
  source_project_script("10_fit_outcome_models.R", env)
  expect_setequal(names(env$cox_fit$matched$KP), kp_outcomes)
  expect_setequal(names(env$cox_fit$weighted$PA), pa_outcomes)
  fit <- env$cox_fit$weighted$KP$DEATH
  expect_s3_class(fit, "coxph")
  expect_true(!is.null(fit$naive.var))   # robust variance was used
  expect_s3_class(env$km_fit$matched$PA$GRAFT_LOSS_PA, "survfit")
})

test_that("clustered matched Cox model runs when chosen", {
  env$MATCHED_COX_VARIANCE <- "cluster"
  source_project_script("10_fit_outcome_models.R", env)
  expect_true(!is.null(env$cox_fit$matched$KP$DEATH$naive.var))
})
