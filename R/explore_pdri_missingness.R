# Purpose: EXPLORATORY check of missing PDRI inputs by transplant year and
#   HIV status, to inform the study start date and the handling of missing
#   preservation time (decisions pending: #24, study start date, and #10).
# Needs: setup.R, functions.R, 01_load_srtr_files.R, 02_derive_variables.R
#   (sourced below). Run from the project root with SRTR_WD set.
# Produces: tables/pdri_missingness_<type>.csv, one row per transplant year
#   and HIV status, and a plot in figures/. Both folders are gitignored.
#   These are counts from SRTR data: look at them yourself, and share only
#   the pattern (for example "mostly missing before 2005"), not the numbers
#   (AGENTS.md, "Restricted data").
# Not part of the draft pipeline or main.R.

source("R/setup.R")
source("R/functions.R")
source("R/01_load_srtr_files.R")
source("R/02_derive_variables.R")

## ---- pdri-input-names
pdri_inputs <- c("DON_GENDER", "DON_AGE_IN_MONTHS", "DON_CREAT", "DON_RACE",
                 "DON_HGT_CM", "DON_WGT_KG", "DON_COD_DON_STROKE",
                 "REC_PA_PRESERV_TM", "DON_NON_HR_BEAT")

## ---- tabulate-pdri-missingness
# The PDRI is calculated without any imputation here, so "PDRI_MISSING"
# counts who would be excluded if missing preservation time were not filled.
dir.create(TABLES_DIR, showWarnings = FALSE)
dir.create(FIGURES_DIR, showWarnings = FALSE)
pdri_missingness <- list()
for (type in names(tx_derived)) {
  pdri_missingness[[type]] <- tx_derived[[type]] |>
    dplyr::filter(!is.na(.data$REC_TX_DT),
                  .data$REC_AGE_AT_TX >= MIN_AGE_AT_TRANSPLANT) |>
    sRtr:::add_pdri(variant = type) |>
    dplyr::group_by(.data$YEAR_TRANSPLANT, .data$HIV_GROUP) |>
    dplyr::summarise(
      N = dplyr::n(),
      dplyr::across(dplyr::all_of(pdri_inputs), ~ sum(is.na(.x)),
                    .names = "{.col}_MISSING"),
      PDRI_MISSING = sum(!is.finite(.data$PDRI)),
      .groups = "drop"
    )
  utils::write.csv(
    pdri_missingness[[type]],
    file.path(TABLES_DIR, stringr::str_glue("pdri_missingness_{type}.csv")),
    row.names = FALSE
  )
}

## ---- plot-pdri-missingness
missingness_plot <- dplyr::bind_rows(pdri_missingness, .id = "type") |>
  dplyr::mutate(share_missing = .data$PDRI_MISSING / .data$N) |>
  ggplot2::ggplot(ggplot2::aes(x = .data$YEAR_TRANSPLANT, y = .data$share_missing,
                               color = .data$HIV_GROUP)) +
  ggplot2::geom_line() +
  ggplot2::facet_wrap(ggplot2::vars(.data$type)) +
  ggplot2::scale_y_continuous(labels = scales::percent) +
  ggplot2::labs(x = "Year of transplant", y = "PDRI could not be calculated",
                color = NULL) +
  ggplot2::theme_bw()
ggplot2::ggsave(file.path(FIGURES_DIR, "pdri_missingness.png"),
                plot = missingness_plot, width = 8, height = 4, dpi = 300)
