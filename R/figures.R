# Purpose: figures: cohort flow diagrams, Kaplan-Meier curves with risk
#   tables, transplants in recipients with HIV by UNOS region, Lorenz curves
#   of concentration across centers, and transplants and centers per year.
# Needs: cohort_fc (04_build_cohort.R), km_fit (10_fit_outcome_models.R),
#   tx_derived (03_calculate_pdri.R); FIGURES_DIR and related constants.
# Produces: image files in figures/ (gitignored). Counts in risk tables,
#   flowchart boxes and the regional map must pass the SRTR small-cell rule
#   before anything leaves the approved environment (decision pending: #15).
# DRAFT, exploratory: run through R/draft_pipeline.R, not R/main.R.

## ---- figure-flowcharts
dir.create(FIGURES_DIR, showWarnings = FALSE)
for (type in names(cohort_fc)) {
  cohort_fc[[type]] |>
    flowchart::fc_draw() |>
    flowchart::fc_export(filename = stringr::str_glue("flowchart_{type}.png"),
                         path = FIGURES_DIR, width = 2400, height = 1800,
                         units = "px", res = 300)
}

## ---- figure-km
# KMunicate style: confidence intervals, and numbers at risk, censored and
# with events under the plot.
km_plots <- list()
for (analysis in names(km_fit)) {
  for (type in names(km_fit[[analysis]])) {
    for (outcome in names(km_fit[[analysis]][[type]])) {
      outcome_label <- OUTCOMES$label[OUTCOMES$outcome == outcome]
      plot <- km_fit[[analysis]][[type]][[outcome]] |>
        ggsurvfit::ggsurvfit() +
        ggsurvfit::add_confidence_interval() +
        ggsurvfit::add_risktable(
          risktable_stats = c("n.risk", "cum.censor", "cum.event")
        ) +
        ggplot2::labs(
          title = stringr::str_glue("{outcome_label}: {TRANSPLANT_TYPE_LABELS[[type]]}"),
          x = "Years after transplant",
          y = stringr::str_glue("Proportion free of {tolower(outcome_label)}")
        )
      km_plots[[analysis]][[type]][[outcome]] <- plot
      ggplot2::ggsave(
        file.path(FIGURES_DIR, stringr::str_glue("km_{analysis}_{type}_{outcome}.png")),
        plot = plot, width = 7, height = 6, dpi = 300
      )
    }
  }
}

## ---- figure-region-map
# Recipients with HIV by UNOS region of residence (decided: #3). Which
# centers are shown is pending (#6); centers are not drawn in this draft.
hiv_by_state <- dplyr::bind_rows(tx_derived, .id = "type") |>
  dplyr::filter(.data$HIV_POSITIVE == 1) |>
  dplyr::count(.data$REC_PERM_STATE, name = "n")
state_names <- tibble::tibble(REC_PERM_STATE = c(state.abb, "DC"),
                              State = c(state.name, "District of Columbia"))
hiv_by_region <- sRtr::UNOS_regions_sf |>
  sf::st_drop_geometry() |>
  dplyr::left_join(state_names, by = dplyr::join_by("State"),
                   relationship = "many-to-one") |>
  dplyr::left_join(hiv_by_state, by = dplyr::join_by("REC_PERM_STATE"),
                   relationship = "many-to-one") |>
  dplyr::summarise(n = sum(.data$n, na.rm = TRUE), .by = "Region")
region_map <- sRtr::get_hrsa_optn_regions() |>
  dplyr::left_join(hiv_by_region, by = dplyr::join_by("Region"),
                   relationship = "one-to-one") |>
  ggplot2::ggplot() +
  ggplot2::geom_sf(ggplot2::aes(fill = .data$n), color = "black") +
  ggplot2::scale_fill_distiller(palette = "YlOrRd", direction = 1,
                                name = "Transplants in recipients with HIV") +
  ggplot2::theme_void()
ggplot2::ggsave(file.path(FIGURES_DIR, "region_map.png"), plot = region_map,
                width = 9, height = 6, dpi = 300)

## ---- figure-lorenz
lorenz_plots <- list()
gini <- list()
for (type in names(tx_derived)) {
  center_counts <- tx_derived[[type]] |>
    dplyr::filter(.data$YEAR_TRANSPLANT >= LORENZ_START_YEAR[[type]]) |>
    dplyr::summarise(n_hiv = sum(.data$HIV_POSITIVE), .by = "REC_CTR_CD") |>
    dplyr::pull(.data$n_hiv)
  gini[[type]] <- gini_coefficient(center_counts)
  lorenz_plots[[type]] <- lorenz_points(center_counts) |>
    ggplot2::ggplot(ggplot2::aes(x = .data$share_units, y = .data$share_counts)) +
    ggplot2::geom_abline(linetype = "dashed") +
    ggplot2::geom_step() +
    ggplot2::labs(
      title = stringr::str_glue(
        "{TRANSPLANT_TYPE_LABELS[[type]]}, {LORENZ_START_YEAR[[type]]} onwards"
      ),
      x = "Proportion of transplant centers",
      y = "Proportion of transplants in recipients with HIV"
    ) +
    ggplot2::theme_minimal()
  ggplot2::ggsave(file.path(FIGURES_DIR, stringr::str_glue("lorenz_{type}.png")),
                  plot = lorenz_plots[[type]], width = 6, height = 6, dpi = 300)
}

## ---- figure-per-year
per_year <- dplyr::bind_rows(tx_derived, .id = "type") |>
  dplyr::filter(.data$HIV_POSITIVE == 1) |>
  dplyr::summarise(
    Transplants = dplyr::n(),
    Centers = dplyr::n_distinct(.data$REC_CTR_CD),
    .by = "YEAR_TRANSPLANT"
  ) |>
  tidyr::pivot_longer(c("Transplants", "Centers"), names_to = "measure",
                      values_to = "count")
per_year_plot <- per_year |>
  ggplot2::ggplot(ggplot2::aes(x = .data$YEAR_TRANSPLANT, y = .data$count,
                               color = .data$measure)) +
  ggplot2::geom_line() +
  ggplot2::labs(x = "Year of transplant", y = "Number", color = NULL) +
  ggplot2::theme_bw()
ggplot2::ggsave(file.path(FIGURES_DIR, "per_year.png"), plot = per_year_plot,
                width = 7, height = 4, dpi = 300)
