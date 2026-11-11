# Purpose: reusable helper functions. Each takes its inputs as arguments.
# Needs: setup.R. Produces: functions only.
# Several helpers stand in for sRtr functions that are planned but not yet
# written; each says which sRtr issue will replace it.

## ---- srtr-code
# The numeric code of an SRTR value. sRtr::load_srtr_file() labels coded
# values as "<code>: <meaning>" (for example "3011: KI:DIABETES ..."); this
# returns 3011 whether the value is labelled or still a number.
srtr_code <- function(x) {
  if (is.numeric(x)) {
    return(as.numeric(x))
  }
  x |>
    as.character() |>
    stringr::str_extract("^-?[0-9]+") |>
    as.numeric()
}

## ---- diagnosis-group
# Diagnosis group from REC_DGN. To move to sRtr::srtr_collapse_codes()
# (VagishHemmige/sRtr#2) once it exists.
diagnosis_group <- function(dgn, codes, other_label) {
  dgn_code <- srtr_code(dgn)
  group <- rep(other_label, length(dgn_code))
  for (group_name in names(codes)) {
    group[dgn_code %in% codes[[group_name]]] <- group_name
  }
  factor(group, levels = c(names(codes), other_label))
}

## ---- impute-preservation-time
# Missing preservation time for the PDRI (decision pending: #10). `rule` is
# "hiv_only", "everyone" or "none"; the mean is taken over `eligible` rows.
impute_preservation_time <- function(preserv_tm, hiv_positive, eligible, rule) {
  if (rule == "none") {
    return(preserv_tm)
  }
  fill_value <- mean(preserv_tm[eligible], na.rm = TRUE)
  to_fill <- is.na(preserv_tm)
  if (rule == "hiv_only") {
    to_fill <- to_fill & hiv_positive == 1
  }
  dplyr::if_else(to_fill, fill_value, preserv_tm)
}

## ---- center-volume
# Transplants per center per calendar year, from a whole transplant file.
# To move to sRtr::srtr_center_volume() (VagishHemmige/sRtr#52).
center_volume <- function(tx, prefix, subset = NULL) {
  subset <- rlang::enquo(subset)
  if (!rlang::quo_is_null(subset)) {
    tx <- dplyr::filter(tx, !!subset)
  }
  tx |>
    dplyr::filter(!is.na(.data$REC_TX_DT)) |>
    dplyr::mutate(YEAR_TRANSPLANT = as.integer(format(.data$REC_TX_DT, "%Y"))) |>
    dplyr::count(.data$REC_CTR_CD, .data$YEAR_TRANSPLANT,
                 name = paste0(prefix, "_VOLUME"))
}

# Group volumes by upper cut-points: `breaks` is a named vector of the upper
# bound of each group but the last (for example c(Low = 6, Medium = 13)).
center_volume_group <- function(volume, breaks, top_label = "High") {
  labels <- c(names(breaks), top_label)
  cut(volume, breaks = c(-Inf, breaks, Inf), labels = labels, right = TRUE)
}

## ---- induction-flags
# Induction classes per transplant from IMMUNO rows (decision pending: #11).
# Returns one row per TRR_ID in `immuno`. To move to sRtr::srtr_induction()
# (VagishHemmige/sRtr#51).
induction_flags <- function(immuno, drug_codes, use_induction_flag) {
  if (use_induction_flag) {
    immuno <- dplyr::filter(immuno, srtr_code(.data$REC_DRUG_INDUCTION) == 1)
  }
  immuno <- dplyr::mutate(immuno, DRUG_CODE = srtr_code(.data$REC_DRUG_CD))
  flags <- dplyr::distinct(immuno, .data$TRR_ID)
  for (class_name in names(drug_codes)) {
    class_flags <- immuno |>
      dplyr::group_by(.data$TRR_ID) |>
      dplyr::summarise(
        !!paste0("INDUCTION_", toupper(class_name)) :=
          as.integer(any(.data$DRUG_CODE %in% drug_codes[[class_name]])),
        .groups = "drop"
      )
    flags <- dplyr::left_join(flags, class_flags,
                              by = dplyr::join_by("TRR_ID"),
                              relationship = "one-to-one")
  }
  flags
}

## ---- att-weights
# Inverse probability weights for the average effect among the exposed (ATT):
# 1 for exposed, ps / (1 - ps) for unexposed. Optional truncation of the
# unexposed weights at an upper percentile (decision pending: #21).
att_weights <- function(exposed, ps, truncate_percentile = NA_real_) {
  stopifnot(length(exposed) == length(ps), all(ps > 0 & ps < 1, na.rm = TRUE))
  weights <- dplyr::if_else(exposed == 1, 1, ps / (1 - ps))
  if (!is.na(truncate_percentile)) {
    cap <- stats::quantile(weights[exposed == 0], truncate_percentile,
                           na.rm = TRUE, names = FALSE)
    weights <- dplyr::if_else(exposed == 0, pmin(weights, cap), weights)
  }
  weights
}

## ---- weighted-smd
# Standardized mean difference of a numeric or 0/1 variable between exposed
# and unexposed, with optional weights. The denominator is the unweighted
# standard deviation in the exposed group, as is usual for the ATT.
weighted_smd <- function(x, exposed, weights = rep(1, length(x))) {
  keep <- !is.na(x)
  x <- x[keep]
  exposed <- exposed[keep]
  weights <- weights[keep]
  mean_exposed <- stats::weighted.mean(x[exposed == 1], weights[exposed == 1])
  mean_unexposed <- stats::weighted.mean(x[exposed == 0], weights[exposed == 0])
  sd_exposed <- stats::sd(x[exposed == 1])
  if (is.na(sd_exposed) || sd_exposed == 0) {
    return(NA_real_)
  }
  (mean_exposed - mean_unexposed) / sd_exposed
}

# Balance table: one row per variable (factors expanded to one row per level).
balance_table <- function(data, variables, exposure, weights = NULL) {
  w <- if (is.null(weights)) rep(1, nrow(data)) else data[[weights]]
  rows <- list()
  for (variable in variables) {
    x <- data[[variable]]
    if (is.factor(x) || is.character(x)) {
      for (level in sort(unique(stats::na.omit(as.character(x))))) {
        rows[[paste(variable, level)]] <- tibble::tibble(
          variable = variable, level = level,
          smd = weighted_smd(as.numeric(as.character(x) == level),
                             data[[exposure]], w)
        )
      }
    } else {
      rows[[variable]] <- tibble::tibble(
        variable = variable, level = NA_character_,
        smd = weighted_smd(as.numeric(x), data[[exposure]], w)
      )
    }
  }
  dplyr::bind_rows(rows)
}

## ---- lorenz-gini
# Lorenz curve points and Gini coefficient for counts across units (centers).
lorenz_points <- function(counts) {
  counts <- sort(counts)
  tibble::tibble(
    share_units = c(0, seq_along(counts) / length(counts)),
    share_counts = c(0, cumsum(counts) / sum(counts))
  )
}

gini_coefficient <- function(counts) {
  counts <- sort(counts)
  n <- length(counts)
  if (n == 0 || sum(counts) == 0) {
    return(NA_real_)
  }
  # Gini from the ordered counts: base R arithmetic on one vector, kept here
  # in a named, tested function (AGENTS.md, "Coding conventions").
  sum((2 * seq_len(n) - n - 1) * counts) / (n * sum(counts))
}

## ---- followup-dates
# First follow-up rejection and malignancy dates through
# sRtr::add_txf_outcomes(), with the output columns fixed so they do not depend
# on which organs happen to have rejections (VagishHemmige/sRtr#16).
# For TX_KP, see also VagishHemmige/sRtr#37 (TRR_ID vs TRR_ID_PA).
add_followup_dates <- function(cohort, file_key) {
  attr(cohort, "file_key") <- file_key
  out <- sRtr::add_txf_outcomes(cohort)
  expected <- if (file_key == "TX_KP") {
    c("FIRST_FU_REJ_DATE_KI", "FIRST_FU_REJ_DATE_PA")
  } else {
    "FIRST_FU_REJ_DATE"
  }
  if (file_key == "TX_KP" && "FIRST_FU_REJ_DATE" %in% names(out)) {
    stop("add_txf_outcomes() returned a single rejection column for TX_KP; ",
         "the organ is ambiguous (VagishHemmige/sRtr#16).", call. = FALSE)
  }
  for (column in c("FIRST_FU_MALIG_DATE", expected)) {
    if (!column %in% names(out)) {
      out[[column]] <- as.Date(NA)
    }
  }
  out
}
