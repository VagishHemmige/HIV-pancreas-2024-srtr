# Purpose: derive record-level variables needed before the cohort is built:
#   HIV status, diagnosis group, recipient Black race, year of transplant and
#   waiting time; and copy the pancreas-alone date columns to the
#   kidney-pancreas names.
# Needs: tx_raw (01_load_srtr_files.R); constants and helpers from setup.R
#   and functions.R.
# Produces: tx_derived, a named list (KP, PA) with the new columns.
# DRAFT, exploratory: run through R/draft_pipeline.R, not R/main.R.

## ---- derive-recipient-variables
tx_derived <- list()
for (type in names(tx_raw)) {
  tx_derived[[type]] <- tx_raw[[type]] |>
    dplyr::mutate(
      # Exposure (plan §5); decision pending: #9
      HIV_POSITIVE = as.integer(
        dplyr::coalesce(.data$REC_HIV_STAT == HIV_POSITIVE_CODE, FALSE)
      ),
      HIV_GROUP = factor(.data$HIV_POSITIVE, levels = c(0, 1),
                         labels = c("HIV negative", "HIV positive")),
      DIAGNOSIS_GROUP = diagnosis_group(.data$REC_DGN, DIAGNOSIS_CODES,
                                        DIAGNOSIS_OTHER_LABEL),
      REC_BLACK = as.integer(srtr_code(.data$CAN_RACE) %in% RACE_BLACK_CODE),
      YEAR_TRANSPLANT = as.integer(format(.data$REC_TX_DT, "%Y")),
      WAITLIST_TIME_YEARS = as.numeric(.data$REC_TX_DT - .data$CAN_LISTING_DT) / 365.25
    ) |>
    labelled::set_variable_labels(
      HIV_POSITIVE = "Recipient HIV positive at transplant",
      HIV_GROUP = "Recipient HIV status",
      DIAGNOSIS_GROUP = "Primary diagnosis group",
      REC_BLACK = "Recipient Black race",
      YEAR_TRANSPLANT = "Year of transplant",
      WAITLIST_TIME_YEARS = "Time on the waiting list (years)"
    )
}

## ---- harmonize-pancreas-columns
# TX_PA names the pancreas graft failure and last follow-up dates without the
# organ suffix that TX_KP uses; copy them to the TX_KP names so later code can
# treat both types alike. The original columns are kept.
tx_derived$PA <- tx_derived$PA |>
  dplyr::mutate(
    TFL_GRAFT_DT_PA = .data$TFL_GRAFT_DT,
    TFL_LAFUDATEPA = .data$TFL_LAFUDATE,
    REC_ACUTE_REJ_EPISODE_PA = .data$REC_ACUTE_REJ_EPISODE
  )

