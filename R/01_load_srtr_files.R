# Purpose: load the SRTR transplant files the analysis uses.
# Needs: setup.R (TRANSPLANT_TYPES). SRTR_WD must point to the release in use
#   (decision pending: #8).
# Produces: tx_raw, a named list of transplant files (KP, PA), labelled by
#   sRtr; tx_ki_volume, the kidney file reduced to the columns needed for
#   kidney center volume.
# DRAFT, exploratory: run through R/draft_pipeline.R, not R/main.R.

## ---- load-transplant-files
tx_raw <- list()
for (type in names(TRANSPLANT_TYPES)) {
  tx_raw[[type]] <- sRtr::load_srtr_file(TRANSPLANT_TYPES[[type]])
}

## ---- load-kidney-volume-file
tx_ki_volume <- sRtr::load_srtr_file(
  "TX_KI",
  col_select = c("REC_CTR_CD", "REC_TX_DT", "REC_HIV_STAT")
)
