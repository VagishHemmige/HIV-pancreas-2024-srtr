# Purpose: calculate the pancreas donor risk index (PDRI, plan §5), after
#   filling missing preservation time by the provisional rule.
# Needs: tx_derived (02_derive_variables.R); MIN_AGE_AT_TRANSPLANT,
#   PDRI_IMPUTE_RULE; impute_preservation_time() from functions.R.
# Produces: tx_derived with PDRI, REC_PA_PRESERV_TM (filled) and
#   REC_PA_PRESERV_TM_RAW (as recorded).
# DRAFT, exploratory: run through R/draft_pipeline.R, not R/main.R.

## ---- calculate-pdri
# PDRI (plan §5) through sRtr's add_pdri(), not yet exported
# (VagishHemmige/sRtr#50). Missing preservation time is filled first by the
# provisional rule (decision pending: #10); the mean is taken over records
# that pass the first three exclusions.
for (type in names(tx_derived)) {
  eligible <- dplyr::coalesce(
    !is.na(tx_derived[[type]]$REC_TX_DT) &
      tx_derived[[type]]$REC_AGE_AT_TX >= MIN_AGE_AT_TRANSPLANT &
      !is.na(tx_derived[[type]]$REC_PX_STAT_DT),
    FALSE
  )
  tx_derived[[type]] <- tx_derived[[type]] |>
    dplyr::mutate(
      REC_PA_PRESERV_TM_RAW = .data$REC_PA_PRESERV_TM,
      REC_PA_PRESERV_TM = impute_preservation_time(
        .data$REC_PA_PRESERV_TM, .data$HIV_POSITIVE,
        eligible = eligible, rule = PDRI_IMPUTE_RULE
      )
    ) |>
    sRtr:::add_pdri(variant = type)
}
