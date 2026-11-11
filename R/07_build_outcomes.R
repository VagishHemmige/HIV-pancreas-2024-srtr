# Purpose: build the six outcomes (plan §7) as time from transplant, event
#   indicator and censor date, using sRtr's death and time-to-event helpers.
# Needs: cohort (06_add_center_volume.R); OUTCOMES, OUTCOME_TIME_UNITS,
#   REJECTION_TREATED_CODE, KP_DEATH_CENSOR_DATE.
# Produces: cohort with, for each outcome, <OUTCOME>_CENSOR, <OUTCOME>_BINARY
#   and <OUTCOME>_yrs.
# DRAFT, exploratory: run through R/draft_pipeline.R, not R/main.R.
# Decision pending: #13 (censoring). Provisional, as in 2024: no censoring at
#   death or graft loss; see also VagishHemmige/sRtr#18, #21 and #22.

## ---- add-death-and-followup-dates
for (type in names(cohort)) {
  cohort[[type]] <- cohort[[type]] |>
    sRtr::srtr_composite_death() |>
    add_followup_dates(file_key = TRANSPLANT_TYPES[[type]])
}

## ---- add-rejection-dates
# A treated rejection during the transplant hospitalization is dated at
# discharge; otherwise the first follow-up form reporting one.
cohort$KP <- cohort$KP |>
  dplyr::mutate(
    REJECTION_KI_DT = dplyr::if_else(
      srtr_code(.data$REC_ACUTE_REJ_EPISODE) %in% REJECTION_TREATED_CODE,
      .data$REC_TX_DT + .data$REC_POSTX_LOS, .data$FIRST_FU_REJ_DATE_KI
    ),
    REJECTION_PA_DT = dplyr::if_else(
      srtr_code(.data$REC_ACUTE_REJ_EPISODE_PA) %in% REJECTION_TREATED_CODE,
      .data$REC_TX_DT + .data$REC_POSTX_LOS, .data$FIRST_FU_REJ_DATE_PA
    )
  )
cohort$PA <- cohort$PA |>
  dplyr::mutate(
    REJECTION_PA_DT = dplyr::if_else(
      srtr_code(.data$REC_ACUTE_REJ_EPISODE_PA) %in% REJECTION_TREATED_CODE,
      .data$REC_TX_DT + .data$REC_POSTX_LOS, .data$FIRST_FU_REJ_DATE
    )
  )

## ---- add-time-to-event
# Event date and censor date for each outcome; the censor date is the organ's
# last follow-up (decision pending: #13).
outcome_dates <- list(
  KP = list(
    GRAFT_LOSS_KI = c(event = "TFL_GRAFT_DT_KI", censor = "TFL_LAFUDATEKI"),
    GRAFT_LOSS_PA = c(event = "TFL_GRAFT_DT_PA", censor = "TFL_LAFUDATEPA"),
    REJECTION_KI = c(event = "REJECTION_KI_DT", censor = "TFL_LAFUDATEKI"),
    REJECTION_PA = c(event = "REJECTION_PA_DT", censor = "TFL_LAFUDATEPA"),
    DEATH = c(event = "REC_DEATH_DT_COMPOSITE", censor = KP_DEATH_CENSOR_DATE),
    MALIGNANCY = c(event = "FIRST_FU_MALIG_DATE", censor = "TFL_LAFUDATEKI")
  ),
  PA = list(
    GRAFT_LOSS_PA = c(event = "TFL_GRAFT_DT_PA", censor = "TFL_LAFUDATEPA"),
    REJECTION_PA = c(event = "REJECTION_PA_DT", censor = "TFL_LAFUDATEPA"),
    DEATH = c(event = "REC_DEATH_DT_COMPOSITE", censor = "TFL_LAFUDATEPA"),
    MALIGNANCY = c(event = "FIRST_FU_MALIG_DATE", censor = "TFL_LAFUDATEPA")
  )
)
for (type in names(outcome_dates)) {
  for (outcome in names(outcome_dates[[type]])) {
    dates <- outcome_dates[[type]][[outcome]]
    cohort[[type]] <- sRtr::srtr_time_to_event(
      cohort[[type]],
      event_date = .data[[dates[["event"]]]],
      start_date = .data$REC_TX_DT,
      censor_date = .data[[dates[["censor"]]]],
      prefix = outcome,
      units = OUTCOME_TIME_UNITS
    )
  }
}
