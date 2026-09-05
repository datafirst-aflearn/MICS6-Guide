# AFLEARN MICS6 Analysis Guide

A bookdown guide to analysing the MICS6 Foundational Learning Skills (FLS)
module: getting the data from UNICEF or IPUMS, understanding its structure,
harmonising it across countries, setting the survey design, and running
survey-weighted worked examples in R and Stata.

The published site has two layers:

- `docs/index.html` — the navigation landing page, built from `nav-guide.Rmd`
- `docs/c*.html` — the gitbook chapters, built from the numbered `.Rmd` files

## Repository layout

```text
MICS6-Guide/
├── index.Rmd                  book setup only (packages, knitr options)
├── 01…07*.Rmd                 seven chapters, each with nested sections
├── nav-guide.Rmd              landing page -> docs/index.html
├── _bookdown.yml              chapter order, output_dir, after_render hook
├── _output.yml                gitbook format, CSS, TOC logo, split_by: section
├── style.css                  AFLEARN gitbook theme and callout boxes
├── home-link.html             "back to guide home" strip on every chapter
├── render-site.R              build everything
├── R/publish-nav.R            render nav-guide.Rmd as docs/index.html
├── files/                     brand mark, DataHub lockup, section icons
├── Script/                    user-facing data preparation and analysis scripts
│   ├── run-it.R               the one script readers run
│   ├── prepare-mics-fs.R      unpacks the UNICEF download into Data/UNICEF/
│   ├── harmonize-mics-fs-v1.0.R
│   └── harmonize-mics-reading-v1.1.R
├── Data/                      working data (contents git-ignored)
│   ├── UNICEF/                one folder per survey, written by prepare-mics-fs.R
│   └── AFLEARN Harmonised Data/   harmonisation script output
└── docs/                      rendered site (GitHub Pages source)
```

`R/` holds scripts that build the book. `Script/` holds scripts that readers of
the guide run on data. The two are deliberately separate.

## Building the site

From the project root, in R:

```r
source("render-site.R")
```

That renders the gitbook chapters into `docs/`, then runs `R/publish-nav.R` to
install the landing page as `docs/index.html`.

For a landing-page change only, skip the full book render:

```r
source("R/publish-nav.R")
```

For a single chapter while writing:

```r
bookdown::preview_chapter("01b-organise-download.Rmd")
```

Chapters that touch microdata are `eval=FALSE`, so the book builds without any
MICS files present.

### Requirements

`bookdown`, `rmarkdown` and `knitr`. `Statamarkdown` is loaded if installed but
is not required, because Stata chunks are not evaluated.

## Working with the data

Readers run one script. They unzip the `Script` folder into a project folder,
put `MICS_Datasets.zip` beside it, then:

```r
setwd("C:/path/to/MICS project")
source("Script/run-it.R")
```

`run-it.R` sources `prepare-mics-fs.R` and calls `prepare_mics_data()`, which
creates `Data/UNICEF/` and `Data/AFLEARN Harmonised Data/` and unpacks the
nested UNICEF archives into one clean folder per survey. It then sources
`harmonize-mics-fs-v1.0.R` and `harmonize-mics-reading-v1.1.R` from `Script/`
if they are there, warning and skipping any that are missing. Re-running is
safe.

The working directory must be the project folder holding `Script/`; `run-it.R`
stops before creating anything if it is not. `Script/` is never created — it
comes from the download. The unzip step is base R only.

### Harmonisation scripts

| Script | Reads | Writes |
|---|---|---|
| `Script/harmonize-mics-fs-v1.0.R` | `Data/UNICEF/` | `Data/AFLEARN Harmonised Data/mics6-fs-harmonised.{dta,rds}` and the variable crosswalk |
| `Script/harmonize-mics-reading-v1.1.R` | `Data/UNICEF/` | `Data/AFLEARN Harmonised Data/mics6-reading-harmonised.{dta,rds}` |

`run-it.R` sources them in that order.

Known outstanding change, flagged in the worked-example notes:
`harmonize-mics-fs-v1.0.R` retains `fsweight` but not `PSU`, `stratum` or
`windex5`. The worked examples assume those are added.

## Publishing

`docs/` is the GitHub Pages source. Commit and push it after a render; nothing
in the build pipeline talks to GitHub.
