# Unit tests for R/functions.R, on synthetic values with known answers.

env <- new.env()
source_setup_constants(env)
source_project_script("functions.R", env)

test_that("srtr_code reads labelled and numeric codes", {
  expect_equal(env$srtr_code(c("3011: KI:DIABETES - TYPE I", "-1: ALG", NA)),
               c(3011, -1, NA))
  expect_equal(env$srtr_code(c(41, 2)), c(41, 2))
  expect_equal(env$srtr_code(factor("1: Yes, at least one episode treated")), 1)
})

test_that("diagnosis_group maps codes and leaves the rest as Other", {
  groups <- env$diagnosis_group(c("3011: x", "5002: y", "3071: z", NA),
                                env$DIAGNOSIS_CODES, env$DIAGNOSIS_OTHER_LABEL)
  expect_equal(as.character(groups),
               c("Type 1 diabetes", "Type 2 diabetes", "Other", "Other"))
  expect_equal(levels(groups), c("Type 1 diabetes", "Type 2 diabetes", "Other"))
})

test_that("impute_preservation_time follows each rule", {
  tm <- c(10, NA, 20, NA)
  hiv <- c(0, 1, 0, 0)
  eligible <- c(TRUE, TRUE, TRUE, FALSE)
  expect_equal(env$impute_preservation_time(tm, hiv, eligible, "hiv_only"),
               c(10, 15, 20, NA))
  expect_equal(env$impute_preservation_time(tm, hiv, eligible, "everyone"),
               c(10, 15, 20, 15))
  expect_equal(env$impute_preservation_time(tm, hiv, eligible, "none"), tm)
})

test_that("center_volume counts per center and year, with an optional subset", {
  tx <- tibble::tibble(
    REC_CTR_CD = c("A", "A", "A", "B", "B"),
    REC_TX_DT = as.Date(c("2010-01-01", "2010-06-01", "2011-01-01",
                          "2010-03-01", NA)),
    REC_HIV_STAT = c("P", "N", "P", "N", "P")
  )
  vol <- env$center_volume(tx, prefix = "CENTER_X")
  expect_equal(vol$CENTER_X_VOLUME[vol$REC_CTR_CD == "A" & vol$YEAR_TRANSPLANT == 2010], 2)
  expect_equal(nrow(vol), 3)
  hiv_vol <- env$center_volume(tx, prefix = "CENTER_X_HIV",
                               subset = .data$REC_HIV_STAT == "P")
  expect_equal(sum(hiv_vol$CENTER_X_HIV_VOLUME), 2)
})

test_that("center_volume_group uses upper cut-points inclusively", {
  groups <- env$center_volume_group(c(1, 6, 7, 13, 14), env$CENTER_VOLUME_BREAKS$KP)
  expect_equal(as.character(groups), c("Low", "Low", "Medium", "Medium", "High"))
})

test_that("induction_flags honours the induction flag and drug classes", {
  immuno <- tibble::tibble(
    TRR_ID = c(1, 1, 2, 3),
    REC_DRUG_CD = c("41: Thymoglobulin", "1: Prednisone", "1: Prednisone", "43: Simulect"),
    REC_DRUG_INDUCTION = c(1, 0, 0, 1)
  )
  all_drugs <- env$induction_flags(immuno, env$INDUCTION_DRUG_CODES, FALSE)
  expect_equal(all_drugs$INDUCTION_STEROIDS[all_drugs$TRR_ID == 2], 1L)
  expect_equal(all_drugs$INDUCTION_LYMPHOCYTE_DEPLETING[all_drugs$TRR_ID == 1], 1L)
  induction_only <- env$induction_flags(immuno, env$INDUCTION_DRUG_CODES, TRUE)
  # Maintenance-only steroid no longer counts; transplant 2 has no rows left.
  expect_false(2 %in% induction_only$TRR_ID)
  expect_equal(induction_only$INDUCTION_STEROIDS[induction_only$TRR_ID == 1], 0L)
  expect_equal(induction_only$INDUCTION_IL2_RECEPTOR_ANTAGONIST[induction_only$TRR_ID == 3], 1L)
})

test_that("att_weights give 1 to exposed and ps/(1-ps) to unexposed", {
  w <- env$att_weights(c(1, 0, 0, 0), c(0.5, 0.5, 0.2, 0.8))
  expect_equal(w, c(1, 1, 0.25, 4))
  capped <- env$att_weights(c(1, 0, 0, 0), c(0.5, 0.5, 0.2, 0.8),
                            truncate_percentile = 0.5)
  expect_equal(capped, c(1, 1, 0.25, 1))
  expect_error(env$att_weights(c(1, 0), c(0.5, 1)))
})

test_that("weighted_smd matches a hand calculation", {
  x <- c(1, 2, 3, 2, 4, 6)
  exposed <- c(1, 1, 1, 0, 0, 0)
  expect_equal(env$weighted_smd(x, exposed), (2 - 4) / 1)
  expect_equal(env$weighted_smd(x, exposed, c(1, 1, 1, 3, 1, 0)),
               (2 - (2 * 3 + 4) / 4) / 1)
})

test_that("gini and Lorenz points behave at the extremes", {
  expect_equal(env$gini_coefficient(c(5, 5, 5, 5)), 0)
  expect_equal(env$gini_coefficient(c(0, 0, 0, 12)), 0.75)
  expect_true(is.na(env$gini_coefficient(c(0, 0))))
  pts <- env$lorenz_points(c(3, 1))
  expect_equal(pts$share_counts, c(0, 0.25, 1))
  expect_equal(pts$share_units, c(0, 0.5, 1))
})
