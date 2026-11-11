# Purpose: add transplant center volume in the transplant year, counted from
#   whole TX_KP, TX_PA and TX_KI files, and its groups.
# Needs: cohort (05_add_induction.R), tx_derived (03_calculate_pdri.R),
#   tx_ki_volume (01_load_srtr_files.R); CENTER_VOLUME_BREAKS.
# Produces: cohort with center volume counts and groups.
# DRAFT, exploratory: run through R/draft_pipeline.R, not R/main.R.

## ---- add-center-volume
# Volume is counted from whole files, not the cohort, so it reflects the whole
# program. Decision pending: #4 (per year or averaged; kidney cut-points).
kidney_volume <- center_volume(tx_ki_volume, prefix = "CENTER_KI")
kidney_hiv_volume <- center_volume(tx_ki_volume, prefix = "CENTER_KI_HIV",
                                   subset = .data$REC_HIV_STAT == HIV_POSITIVE_CODE)
for (type in names(cohort)) {
  own_volume <- center_volume(tx_derived[[type]],
                              prefix = paste0("CENTER_", type))
  n_before <- nrow(cohort[[type]])
  by_center_year <- dplyr::join_by("REC_CTR_CD", "YEAR_TRANSPLANT")
  cohort[[type]] <- cohort[[type]] |>
    dplyr::left_join(own_volume, by = by_center_year,
                     relationship = "many-to-one") |>
    dplyr::left_join(kidney_volume, by = by_center_year,
                     relationship = "many-to-one") |>
    dplyr::left_join(kidney_hiv_volume, by = by_center_year,
                     relationship = "many-to-one") |>
    dplyr::mutate(
      # A center-year with no qualifying transplants has volume 0, not NA.
      CENTER_KI_VOLUME = dplyr::coalesce(.data$CENTER_KI_VOLUME, 0L),
      CENTER_KI_HIV_VOLUME = dplyr::coalesce(.data$CENTER_KI_HIV_VOLUME, 0L),
      CENTER_OWN_VOLUME_GROUP = center_volume_group(
        .data[[paste0("CENTER_", type, "_VOLUME")]], CENTER_VOLUME_BREAKS[[type]]
      ),
      CENTER_KI_VOLUME_GROUP = center_volume_group(
        .data$CENTER_KI_VOLUME, CENTER_VOLUME_BREAKS$KI
      )
    )
  stopifnot(nrow(cohort[[type]]) == n_before)
}
