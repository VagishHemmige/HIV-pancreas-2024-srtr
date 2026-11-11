# Analysis plan: Outcomes of pancreas transplantation in recipients with HIV

Status: draft

## Scope and reporting framework

This document is the authoritative specification of the study's scientific objectives,
population, definitions, estimands and statistical methods. `ARCHITECTURE.md` documents
the implementation, `AGENTS.md` the working conventions, and GitHub Issues the open
decisions and implementation status. Neither file supersedes this plan.

Reporting will follow STROBE [@vonelm2007strobe] and its extension for routinely collected
health data, RECORD [@benchimol2015record]. The reporting map below links each checklist
item to a section of this plan.

This plan was first drafted in 2026 from an unfinished 2024 analysis script, which is kept
outside the repository as a source. The decider confirmed the choices that script made,
and three proposed during setup (the estimand, complete-case analysis and no multiplicity
adjustment), on 2026-11-11; they are stated below as decided. The rest are open.

## 1. Objective

To compare outcomes after kidney–pancreas (simultaneous pancreas–kidney) and pancreas-alone
transplantation between recipients with and without HIV in the United States.

Outcomes are listed in [§7](#7-outcomes).

**Open:** which outcome is primary, and which are secondary ([#7](https://github.com/VagishHemmige/HIV-pancreas-2024-srtr/issues/7)).

## 2. Design

Retrospective cohort study using registry data. Recipients with HIV are compared with
recipients without HIV in two ways, both based on a propensity score
([§6](#6-comparator-or-matching)): matching, and inverse probability weighting.
Kidney–pancreas and pancreas-alone transplants are analysed separately.

The estimand is the average effect of HIV status among recipients with HIV (the average
treatment effect in the treated, ATT), as implied by matching each recipient with HIV to
recipients without HIV. The weights target the same estimand.

## 3. Data source

- **Database:** Scientific Registry of Transplant Recipients (SRTR) standard analysis files
  (SAF), accessed under the SRTR data use agreement through the `sRtr` package.
- **Release:** the 2024 script used the March 2023 release (2303).

  **Open:** which release the updated analysis uses ([#8](https://github.com/VagishHemmige/HIV-pancreas-2024-srtr/issues/8)).

- **Files:**
  - `TX_KP` and `TX_PA`: transplant records (cohort, donor and recipient characteristics,
    graft failure and death).
  - `TXF_KP` and `TXF_PA`: follow-up forms (rejection and malignancy after discharge).
  - `IMMUNO`: immunosuppression at transplant (induction).
  - `TX_KI`: kidney transplants, for kidney center volume.
  - The KDPI supplement file (kidney donor profile index at allocation), for description only.
- **Public data:** HRSA list of transplant centers, for maps.
- **Prior use:** the investigators used the 2303 release in the 2024 script, including
  unadjusted outcome comparisons. That earlier work was not published.

## 4. Study population

Source population: all kidney–pancreas and pancreas-alone transplants in the release.

Exclusions, in order (each is one flowchart step), applied separately to each transplant type:

1. No transplant date (`REC_TX_DT` missing).
2. Age at transplant under 16 years (`REC_AGE_AT_TX` < 16).
3. No follow-up information (`REC_PX_STAT_DT` missing), meaning the transplant was too
   recent to contribute follow-up.
4. Pancreas donor risk index (PDRI) cannot be calculated ([§5](#5-exposure-and-time-zero)).

Index event: the transplant. Transplant period: every transplant in the release.

**Open:** whether to restrict or stratify by transplant era ([#2](https://github.com/VagishHemmige/HIV-pancreas-2024-srtr/issues/2)).

## 5. Exposure and time zero

- **Exposure:** recipient HIV status at transplant, `REC_HIV_STAT` = "P" (positive).

  **Open:** how recipients with HIV status negative, missing, unknown or not done are
  classified; the 2024 script counted all of them as HIV-negative ([#9](https://github.com/VagishHemmige/HIV-pancreas-2024-srtr/issues/9)).

- **Time zero:** transplant date (`REC_TX_DT`).
- **Covariates,** measured at transplant:
  - recipient age, sex (`CAN_GENDER`), race (`CAN_RACE`), primary diagnosis (`REC_DGN`),
    weight and body mass index, panel-reactive antibody, cytomegalovirus and hepatitis C
    serostatus, time on the waiting list (`CAN_LISTING_DT` to `REC_TX_DT`);
  - donor age, sex, race, height, weight and body mass index, creatinine, cause of death,
    donation after circulatory death, diabetes history, hepatitis C and cytomegalovirus
    serostatus;
  - pancreas preservation time, duct management, previous kidney transplant;
  - induction therapy from `IMMUNO`;
  - transplant center volume in the transplant year ([§8](#8-statistical-analysis)).
- **Diagnosis group** from `REC_DGN`: type 1 diabetes (3011, 3038, 3069, 5001), type 2
  diabetes (3012, 3039, 3070, 5002), or other.
- **PDRI** is calculated from donor characteristics and preservation time as published
  [@axelrod2010pdri], with the pancreas-alone stroke and previous-kidney term applied to
  pancreas-alone transplants only.

  **Open:** how missing preservation time is handled; the 2024 script imputed the cohort mean
  for recipients with HIV only ([#10](https://github.com/VagishHemmige/HIV-pancreas-2024-srtr/issues/10)).

- **Induction:** lymphocyte-depleting antibody, interleukin-2 receptor antagonist and
  steroids, each yes or no.

  **Open:** which drugs count in each class, and whether only drugs recorded as induction
  count ([#11](https://github.com/VagishHemmige/HIV-pancreas-2024-srtr/issues/11)).

## 6. Comparator or matching

- **Comparator:** recipients without HIV of the same transplant type.
- **Method:** propensity score from logistic regression; nearest-neighbour matching without
  replacement, 10 recipients without HIV per recipient with HIV, no caliper. Kidney–pancreas
  and pancreas-alone transplants are matched separately.
- **Matching variables:** PDRI, transplant year, diagnosis group, recipient sex, recipient
  age, and recipient Black race.

  **Open:** balance criteria (for example a standardized mean difference threshold) and what
  happens if they are not met ([#12](https://github.com/VagishHemmige/HIV-pancreas-2024-srtr/issues/12)).

- **Inverse probability weighting:** a propensity score from logistic regression, estimated
  separately for each transplant type, with weights for the average effect among recipients
  with HIV: 1 for recipients with HIV, and the propensity score divided by one minus it for
  recipients without HIV.

  **Open:** the covariates in the weighting model, whether weighting is a main or a
  supporting analysis alongside matching, and how weights are stabilized or truncated
  ([#21](https://github.com/VagishHemmige/HIV-pancreas-2024-srtr/issues/21)).

## 7. Outcomes

Each outcome is measured from transplant. Follow-up ends at the organ's last follow-up date
(`TFL_LAFUDATEKI` or `TFL_LAFUDATEPA`, or `TFL_LAFUDATE` for pancreas alone).

| Outcome | Transplant type | Event |
|---|---|---|
| Death-censored kidney graft loss | Kidney–pancreas | `TFL_GRAFT_DT_KI` |
| Death-censored pancreas graft loss | Both | `TFL_GRAFT_DT_PA`, or `TFL_GRAFT_DT` for pancreas alone |
| Treated acute kidney rejection | Kidney–pancreas | treated rejection during the transplant hospitalization, or the first follow-up form reporting it |
| Treated acute pancreas rejection | Both | as above, for the pancreas |
| Death | Both | first available of the OPTN, Social Security and follow-up death dates |
| Malignancy | Both | first follow-up form reporting a malignancy |

A rejection during the transplant hospitalization is dated at discharge (transplant date plus
length of stay). Events reported on follow-up forms are dated by the form.

Also described, not compared formally: length of stay, anastomotic leak, abscess and
pancreatitis during the transplant hospitalization, and cause of death.

**Open:** censoring rules: whether graft loss is censored at death, whether rejection and
malignancy are censored at graft loss or death, and how deaths found only after last
follow-up are handled ([#13](https://github.com/VagishHemmige/HIV-pancreas-2024-srtr/issues/13)).

## 8. Statistical analysis

- **Descriptive:** characteristics of recipients with and without HIV, before and after
  matching and after weighting, including each matching variable and missingness.
- **Primary model:** Kaplan–Meier curves and Cox proportional hazards models of each outcome
  by HIV status in the matched cohort.

  **Open:** how the matched design enters the model (for example robust variance clustered by
  matched set) and whether covariates are added ([#14](https://github.com/VagishHemmige/HIV-pancreas-2024-srtr/issues/14)).

- **Weighted analysis:** weighted Kaplan–Meier curves and weighted Cox models of each outcome
  by HIV status in the full cohort, using the weights in [§6](#6-comparator-or-matching).
  Whether this is a main or a supporting analysis is open
  ([#21](https://github.com/VagishHemmige/HIV-pancreas-2024-srtr/issues/21)).

- **Secondary analyses:**
  - infection-related graft loss in the first year ([#1](https://github.com/VagishHemmige/HIV-pancreas-2024-srtr/issues/1));
  - center experience with transplantation in recipients with HIV ([#4](https://github.com/VagishHemmige/HIV-pancreas-2024-srtr/issues/4));
  - pooled kidney–pancreas and pancreas-alone analysis ([#5](https://github.com/VagishHemmige/HIV-pancreas-2024-srtr/issues/5)).
- **Center volume:** transplants per center per calendar year. Kidney–pancreas centers are
  grouped as low (1–6), medium (7–13) or high (14 or more), and pancreas-alone centers as low
  (1–3), medium (4–10) or high (11 or more), following published tertiles
  [@alhamad2017volume]. That study grouped each center's average annual volume over the study
  period, not its volume in each year. Kidney center volume is grouped by quartiles following
  [@sonnenberg2019volume].

  **Open:** whether volume is counted per year or averaged over the period, and the kidney
  cut-points, which the 2024 script set at 65, 110 and 195 ([#4](https://github.com/VagishHemmige/HIV-pancreas-2024-srtr/issues/4)).

- **Descriptive geography:** the number of recipients with HIV by UNOS region of residence
  (`REC_PERM_STATE`), with pancreas transplant centers shown; no state-level map
  ([#3](https://github.com/VagishHemmige/HIV-pancreas-2024-srtr/issues/3)). Which centers are
  shown is open ([#6](https://github.com/VagishHemmige/HIV-pancreas-2024-srtr/issues/6)).
- **Concentration of care:** Lorenz curves and Gini coefficients of transplants in recipients
  with HIV across centers, and transplants per year and number of centers per year.
- **Missing data:** complete-case analysis unless stated otherwise in this plan.
- **Multiplicity:** no adjustment; secondary analyses are reported as exploratory.
- **Software:** R, with `sRtr` for SRTR files, `MatchIt` for matching and `survival` for
  time-to-event models.

## 9. Sensitivity analyses

- Transplants from 2014 onwards only, testing whether the comparison holds in the recent era
  ([#2](https://github.com/VagishHemmige/HIV-pancreas-2024-srtr/issues/2)).

## 10. Disclosure control

Outputs follow the SRTR data use agreement, and tables, figures and maps stay out of the public
repository until reviewed against it.

**Open:** the small-cell rule that applies, including flowchart boxes, risk tables and regional
counts ([#15](https://github.com/VagishHemmige/HIV-pancreas-2024-srtr/issues/15)).

## 11. Limitations to address in reporting

- Small number of recipients with HIV, limiting precision and the number of matching variables.
- Registry follow-up forms date events by the form, not the event.
- HIV-related variables (viral load, CD4 count, antiretroviral regimen) are not in the SAF.
- Residual confounding by center selection practices.

## 12. Reporting map

| Checklist item | Topic | Plan section |
|---|---|---|
| STROBE 1 / RECORD 1.1–1.3 | Title, abstract, data source and database type | 3 |
| STROBE 2–3 | Background and objectives | 1 |
| STROBE 4 | Study design | 2 |
| STROBE 5 | Setting, dates of data | 3, 4 |
| STROBE 6 / RECORD 6.1–6.3 | Eligibility, selection codes and algorithms, linkage | 4, 5 |
| STROBE 7 / RECORD 7.1 | Variables, codes and algorithms | 5, 7 |
| STROBE 8 | Data sources and measurement | 3, 5, 7 |
| STROBE 9 | Bias | 6, 11 |
| STROBE 10 | Study size | 4 |
| STROBE 11 | Quantitative variables | 5, 8 |
| STROBE 12 / RECORD 12.1–12.2 | Statistical methods, data access and cleaning, linkage | 6, 8, 9 |
| STROBE 13 / RECORD 13.1 | Participants and flow | 4 |
| STROBE 14–17 | Descriptive data, outcomes, main and other results | 7, 8 |
| STROBE 19 / RECORD 19.1 | Limitations | 11 |
| STROBE 22 / RECORD 22.1 | Funding, access to data and code | 3, 10 |

## References

::: {#refs}
:::
