# Test helpers. Tests run on synthetic data only; they never read SRTR files.
# The constants come from R/setup.R's define-constants section, without
# attaching its packages (sRtr and some reporting packages may not be
# installed where tests run).

project_root <- normalizePath(file.path("..", ".."))

source_setup_constants <- function(env) {
  setup_lines <- readLines(file.path(project_root, "R", "setup.R"))
  start <- which(setup_lines == "## ---- define-constants")
  eval(parse(text = setup_lines[(start + 1):length(setup_lines)]), envir = env)
}

source_project_script <- function(script, env) {
  sys.source(file.path(project_root, "R", script), envir = env)
}

# Synthetic analysis cohort, shaped like the output of R/07_build_outcomes.R.
# Values are random draws, labelled synthetic, not derived from SRTR data.
synthetic_cohort <- function(n, outcomes, n_hiv = round(n / 12), seed = 1) {
  withr::with_seed(seed, {
    hiv <- c(rep(1L, n_hiv), rep(0L, n - n_hiv))
    data <- tibble::tibble(
      SYNTHETIC = TRUE,
      TRR_ID = seq_len(n),
      HIV_POSITIVE = hiv,
      HIV_GROUP = factor(hiv, levels = c(0, 1),
                         labels = c("HIV negative", "HIV positive")),
      PDRI = stats::rlnorm(n, 0, 0.3),
      YEAR_TRANSPLANT = sample(2000:2022, n, replace = TRUE),
      DIAGNOSIS_GROUP = factor(
        sample(c("Type 1 diabetes", "Type 2 diabetes", "Other"), n,
               replace = TRUE, prob = c(0.7, 0.2, 0.1)),
        levels = c("Type 1 diabetes", "Type 2 diabetes", "Other")
      ),
      CAN_GENDER = sample(c("F", "M"), n, replace = TRUE),
      REC_AGE_AT_TX = round(stats::runif(n, 18, 65)),
      REC_BLACK = stats::rbinom(n, 1, 0.2 + 0.3 * hiv)
    )
    for (outcome in outcomes) {
      data[[paste0(outcome, "_yrs")]] <- stats::rexp(n, 0.1) + 1 / 365.25
      data[[paste0(outcome, "_BINARY")]] <- stats::rbinom(n, 1, 0.3)
    }
    data
  })
}
