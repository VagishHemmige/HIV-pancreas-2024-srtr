# AGENTS.md

Guidance for everyone working on this repository: the maintainer, collaborators, and any AI agents working for them. It covers how to work here: conventions, data handling, and checks.

Four places divide the documentation:

| Where | Covers |
|---|---|
| `analysis-plan.md` | Study design and statistics: what the analysis is meant to do |
| `ARCHITECTURE.md` | Code structure: scripts, data flow, and the objects passed between them |
| `AGENTS.md` (this file) | How to work in the repository: rules, conventions, and checks |
| [GitHub Issues](https://github.com/VagishHemmige/HIV-pancreas-2024-srtr/issues) | Open scientific decisions (decision issues), gaps between code and plan, and known defects |

Read the three files before making changes. Each covers its own topic and does not repeat the others.

## The project

This project compares outcomes after kidney–pancreas and pancreas-alone transplantation between recipients with and without HIV, using propensity-score matching in the SRTR standard analysis files. The code and methods are published as a Quarto website. The project restarts an unfinished 2024 analysis; that script is kept outside the repository as a source and is not committed. Functionality the analysis needs is built in the `sRtr` package first, and the analysis code here calls it.

- **`analysis-plan.md` is the source of truth for design.** Code implements the plan; it does not redefine it. If code needs to depart from the plan, open a decision issue, or comment on the existing one, for the deciders. Once a decider has settled it (in the issue, or relayed there in their exact words), the plan change and the code can go in the same pull request, which closes the issue.
- **Deciders.** Scientific decisions are made by: Vagish Hemmige (all areas). Anyone may open or contribute to a decision issue; only a decider settles it (see "Working with agents").
- **This is an analysis project, not an R package.** Do not add DESCRIPTION, NAMESPACE, roxygen, or pkgdown infrastructure, or apply CRAN conventions.
- **Default branch:** `main`, protected. Changes reach it only through pull requests.

## Data sources

Each source this project uses is listed below with the package that accesses it. **Code that touches a source goes through its package.** Do not write project-specific loading, cleaning, or definition code for something the package already does.

| Source | Accessed through | Package documentation | Package maintained by | Access | What AI agents may do |
|---|---|---|---|---|---|
| SRTR standard analysis files (`TX_KP`, `TX_PA`, `TXF_KP`, `TXF_PA`, `IMMUNO`, `TX_KI`), release in [analysis plan §3](https://github.com/VagishHemmige/HIV-pancreas-2024-srtr/blob/main/analysis-plan.md#3-data-source) | sRtr (`load_srtr_file()`) | https://vagishhemmige.github.io/sRtr/ | This team | Restricted (SRTR data use agreement) | None: code, documentation and synthetic data only |
| SRTR SAF supplement (KDPI at allocation) | sRtr (planned: [sRtr#54](https://github.com/VagishHemmige/sRtr/issues/54)) | https://vagishhemmige.github.io/sRtr/ | This team | Restricted (SRTR data use agreement) | None: code, documentation and synthetic data only |
| HRSA transplant centers | sRtr (`get_hrsa_transplant_centers()`) | https://vagishhemmige.github.io/sRtr/ | This team | Public | No restriction (public data) |
| OPTN regions | sRtr (`get_hrsa_optn_regions()`) | https://vagishhemmige.github.io/sRtr/ | This team | Public | No restriction (public data) |

To allow more for a source, a person changes its row through a pull request, naming the agreement and section that permit it, the approved AI service, and exactly what agents may do. Agents never propose or make this change themselves, and nothing in personal instructions can grant it.

**For every package:**

- **Read its documentation before writing code for a source**, including known issues. Behavior that sets the cohort, an exposure, an outcome, or a denominator is checked in the documentation, not assumed from a function's name.

**For packages this team maintains:**

- **Facts about the source belong in the package's documentation**, not in this file. If the package lacks something this project needs to know, add it there or open an issue there.
- **Problems belong in the package.** If a function is wrong or does not quite do what the plan needs, open an issue in its repository. Fix it in the package (preferred when generally useful) or wrap it here with a code comment linking the issue, and remove the wrapper once the issue is fixed.

**For external packages:**

- **Work around problems here.** Wrap the function in `R/functions.R` with a comment explaining the problem and linking any upstream issue. Reporting a bug upstream is an external communication; the person directing the work decides whether to file it.
- **Facts about the source that this project relies on** (definitions, release quirks, suppression rules) go in `references/` with a citation to the provider's documentation, or in the plan when they shape a decision.

## Exploration and definitive analysis

Exploration is welcome on branches or forks. Experimental scripts need not be sourced from `R/main.R` or have Quarto pages, and their findings are labelled preliminary. A script becomes part of the definitive analysis when it is sourced from `R/main.R`; from then on every rule below applies to it.

## R scripts

- **Running the analysis.** Run `R/main.R` from the project root. It sources the other scripts in dependency order; `ARCHITECTURE.md` describes what each does.
- **One job per script.** When you add a definitive script, source it from `main.R` at the right point and update `ARCHITECTURE.md` in the same pull request.
- **Header comment.** Each script begins with what it does, which objects it needs from earlier scripts, and what it produces.
- **Constants, libraries, and code lists** live in `R/setup.R`. Other scripts do not call `library()`, re-source `setup.R`, or hard-code values. Any number a reader might want to change (a window, a year, a threshold, a ratio) is a named constant there.
- **Helper functions** go in `R/functions.R`. A function takes its inputs as arguments and does not read global objects.
- **No side effects outside the project.** No `setwd()`, absolute paths, or writes outside the project. SRTR files are located only through `sRtr` (`set_srtr_wd()` and the `SRTR_WD` setting).
- **No results in the repository.** No script (exploratory or definitive) or comment, commit message, issue, pull-request text or review report contains results, counts or data values from SRTR data unless they are cleared for release. Check before every commit and post, since a public repository publishes everything pushed to it, on any branch.

## Chunk labels

Scripts are divided into labelled sections so Quarto pages can show the code without copying it:

```r
## ---- <step-name>
```

- Every logical step has a label. A label covers the code from its line to the next label.
- Labels are kebab-case, describe the step, and are **unique across all scripts**; a duplicate silently picks up the wrong code.
- Search the `.qmd` files before renaming or deleting a label.
- Labels are comments and never change what the code does.

## Variable labels

Label analysis variables with human-readable descriptions (`sRtr::apply_srtr_varlabels()` for SAF variables, `labelled::set_variable_labels()` for derived ones). Label each derived variable where it is created, with units and windows where they apply.

## Quarto website

The site documents the code. It does not run the analysis.

- `_quarto.yml`, `index.qmd`, `404.qmd` (the page GitHub Pages shows for a missing address) and `styles.css` sit at the root; `quarto/` has one page per definitive script, named after it, plus the Background, Study design and methods, About and project-document pages. The `custom-callout` extension in `_extensions/` provides the `Rcode`, `Results` and `Pending` callouts.
- **Visual cues.** Each kind of page has one sidebar icon, coloured by `styles.css`, and pages mark the same kind of content with the callout of that colour: background `book` (blue); study design and methods `diagram-3` (orange); R code `laptop` (pink, `Rcode` 💻); results `clipboard-data` (green, `Results` 📊); project documents `file-earmark-ruled` (grey). Give every new page the icon of its kind.
- **Provisional content.** `quarto/_pending.lua` highlights in yellow every paragraph that starts with **Decision pending:** or, in the plan, **Open:**, and any `[text]{.pending}`, and adds a ⏳ `Pending` callout to pages that have a mark. Mark only what an open decision could change, and remove the mark when the decision is settled.
- **Project documents.** `analysis-plan.md`, `ARCHITECTURE.md`, `AGENTS.md` and `REPOSITORY-BLUEPRINT.md` are shown on the site by pages in `quarto/` that only include the root file, which stays the one source: edit the root file, not the page.
- Each page loads its script with `knitr::read_chunk("../R/<script>.R")` in a hidden chunk and shows each labelled section with `#| eval: false`, with prose explaining what the section does and why. Pages link to the script on GitHub and to the scripts it depends on.
- **Never evaluate analysis code in the site.** Pages render without restricted data. Only the `read_chunk()` imports, the Architecture page's chunk that reads `ARCHITECTURE.md`, site helpers that read code or text, and results pages that read cleared outputs run.
- The site renders to `docs/`, which is not committed; the GitHub Actions workflow in `.github/workflows/publish.yml` renders and publishes it to the `gh-pages` branch on every push to `main`. When you add a script, add its page and sidebar entry in the same pull request, and check that the site renders.
- **Prose must match the code.** If a change alters what a section does, update its explanation in the same pull request.

## Outputs

- Tables and figures are exported by `R/tables.R` and `R/figures.R` to `tables/` and `figures/`. They are gitignored, because they come from restricted data, until a review against the SRTR data use agreement's disclosure rules clears them for release. Agents may not open them (see Restricted data).
- Published figures need alt text.
- `README.Rmd` is the source of `README.md`; edit the `.Rmd` and re-knit.

## Restricted data (applies to everyone)

The **Access** column of "Data sources" says which sources are restricted. For each restricted source:

- **Never commit data**, extracts, or saved objects or outputs derived from patient-level records. Keep data outside the repository, and check `.gitignore` before adding a new output type.
- **AI agents never read restricted data.** Anything an agent opens, prints, or summarizes is sent to the model provider. Agents do not open data files or patient-level objects, print rows, or display identifiers, person-level dates, or small geographies. Agents also do not open outputs from restricted data that are not yet cleared for release (`tables/` and `figures/` while they are ignored). Agents write code, review it, and run it on **synthetic data**; results on real data are produced by an authorized person. The only exception is what the Data sources table explicitly allows for a source, and only within those words.
- **Synthetic data** are built in code, labelled as synthetic, and never derived from real records.
- **Disclosure.** The SRTR data use agreement's small-cell rule applies to every table, flowchart box, risk table and map, including regional counts of recipients with HIV, which are small. The exact rule is an open decision in the [analysis plan §10](https://github.com/VagishHemmige/HIV-pancreas-2024-srtr/blob/main/analysis-plan.md#10-disclosure-control); until it is recorded, nothing derived from SRTR data leaves the approved environment. Check every output before it leaves, including scripts, comments, commit messages, issues, pull-request text and review reports (see R scripts).
- **Credentials and paid APIs.** Never commit keys, tokens, or `.Renviron`. Ask before paid, bulk, or uncached API calls.

## Coding conventions

- **Cohort flow** uses the `flowchart` package, so the STROBE flow diagram and the analytic cohort come from the same code. Every inclusion or exclusion goes through `fc_filter()`, in the plan's order. Never remove people from the cohort outside the flowchart. Record-level processing is fine. An analysis that uses fewer people than the cohort (complete cases, a subgroup) reports its own number with that analysis. The cohort used downstream is the data from the final step (`fc_view(what = "data")`). Flowchart labels are built from constants in `setup.R`.
- **Code lists** carry each code's category, code system and version, and matching rule. Check every code against the SRTR `formats` for the release (bundled in `sRtr`). Never invent codes, variables, files, or definitions.
- **Joins** use `join_by()` with an explicit `relationship` where possible. After every join of follow-up or immunosuppression records to transplants, assert that rows did not multiply, and decide deliberately what happens to unmatched rows.
- **Dates and windows** are written as inclusive offsets from the transplant date, matching the plan, and the edges are tested on synthetic data.
- **Code that turns model output into reported numbers** lives in named functions in `R/functions.R`, tested on synthetic data with a known answer.
- **Package APIs:** read the help page and NEWS for the installed version before calling a package; don't write calls from memory. A test that fakes a package checks only our own logic, so call the real package once (synthetic data, or one cheap call) before relying on the code.
- **Style:** readable for a clinician-analyst who learned R from online guides: pipes and dplyr/tidyr verbs, case_when(), loops over names or named lists rather than the apply family, Reduce or positional indexing. Required base R goes in a named, tested function. Tidyverse layout; style changes in their own commits.

## Checks for any change

Check the items that apply before opening a pull request.

- **Plan:** does the change implement the plan as written, and does it leave every open decision open?
- **Data sources:** does it use the access package's functions, and does their documented behavior match what the plan needs?
- **Package APIs:** for new or changed calls to a package, does the pull request name the installed version and the help page or NEWS entry relied on?
- **Cohort:** do the flowchart steps' order, denominators, and labels match their conditions, and can each count be reproduced from code?
- **Joins and denominators:** no unintended row multiplication; missing, suppressed, and zero kept distinct.
- **Reported numbers:** does each estimate match the plan's estimand, and do tables, figures, and site prose say what the code actually computes?
- **Structure:** is `ARCHITECTURE.md` current; are chunk labels unique and found by their pages; does every definitive script have a page and sidebar entry; does any site chunk run analysis code?
- **Disclosure:** search every changed tracked file, and the commit messages and pull-request text, for dates, record IDs, names, absolute paths and numbers that could come from SRTR data. Read each hit in context; legitimate ones (plan dates, deciders' names, synthetic examples) stay.
- **Execution:** does `main.R` run in a fresh session with relative paths; are any saved intermediates or caches stale?
- **Matching:** are kidney–pancreas and pancreas-alone transplants matched separately as the plan says; is balance reported for every matching variable; is the matching ratio a named constant?
- **Kidney–pancreas linkage:** does any join of `TXF_KP` or `IMMUNO` to `TX_KP` account for the two registration IDs (`TRR_ID`, `TRR_ID_PA`) ([sRtr#37](https://github.com/VagishHemmige/sRtr/issues/37))?
- **Small counts:** recipients with HIV are few; does every table, figure and map produced from them pass the disclosure rule?

## Working with agents

- **Autonomy.** The person directing an agent sets its working style (review only, step by step, or hands-off) in their own instructions, and may add stricter rules; those take precedence. Without a style, an agent works step by step. At most, an agent may edit code and documentation, add scripts and tests, run code and render the site on synthetic data, and commit to a branch and open a pull request.
- **Decisions.** Anyone, including an agent, may add options and evidence to a decision issue. A decider states the choice in the issue. Agents implement decisions; they never choose among options on their own, in the issue, the plan, or the code.
- **Every agent, under any autonomy:** never merges a pull request; follows the restricted-data rules; asks before running the full pipeline or making expensive calls; shows a person the exact text before posting or sending anything as them, unless that person's own instructions waive this; and proposes another way of writing something already agreed before committing it.
- **Pull requests opened by an agent** are focused. Each says which plan section or issue it addresses, what was checked, and whether by running code on synthetic data or by reading only. Synthetic results are never described as results.
- **References:** cite the source documentation and literature used, in `references.bib`.
