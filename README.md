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
├── 01…07*.Rmd                 the 37 chapters, in seven sections
├── nav-guide.Rmd              landing page -> docs/index.html
├── _bookdown.yml              chapter order, output_dir, after_render hook
├── _output.yml                gitbook format, CSS, TOC logo
├── style.css                  AFLEARN gitbook theme and callout boxes
├── home-link.html             "back to guide home" strip on every chapter
├── render-site.R              build everything
├── R/publish-nav.R            render nav-guide.Rmd as docs/index.html
├── files/                     brand mark, DataHub lockup, section icons
├── Script/                    user-facing data preparation and analysis scripts
├── Data/                      working data (contents git-ignored)
│   ├── UNICEF/                one folder per survey, written by prepare-mics-fs.R
│   ├── IPUMS/                 your IPUMS MICS extracts
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
bookdown::preview_chapter("03a-organise-download.Rmd")
```

Chapters that touch microdata are `eval=FALSE`, so the book builds without any
MICS files present.

### Requirements

`bookdown`, `rmarkdown` and `knitr`. `Statamarkdown` is loaded if installed but
is not required, because Stata chunks are not evaluated.

## Working with the data

Put the UNICEF bulk download next to `Script/prepare-mics-fs.R` and source it:

```r
source("Script/prepare-mics-fs.R")
```

Sourcing runs the script. It creates `Data/UNICEF/`, `Data/IPUMS/`,
`Data/AFLEARN Harmonised Data/` and `Script/`, unpacks the nested UNICEF
archives into one clean folder per survey, and copies itself plus any
harmonisation scripts it finds into `Script/`. Re-running is safe. It uses base
R only.

The script also works outside this project: run it in any folder containing
`MICS_Datasets.zip` and it builds the same structure there.

### Harmonisation scripts

The two AFLEARN harmonisation scripts are referenced throughout Sections 3, 4
and 7 but are **not yet in this repository**:

| Script | Reads | Writes |
|---|---|---|
| `Script/harmonize-mics-fs-v1.0.R` | `Data/UNICEF/` | `Data/AFLEARN Harmonised Data/mics6_fs_harmonized.dta` and the variable crosswalk |
| `Script/harmonize-mics-reading-v1.1.R` | `Data/UNICEF/` | `Data/AFLEARN Harmonised Data/mics6_reading_harmonized.dta` |

Drop them into `Script/` and point their input and output paths at those two
folders. `prepare-mics-fs.R` will move them there automatically if it finds them
beside the zip.

Known outstanding change, flagged in the Section 7 notes: `harmonize-mics-fs-v1.0.R`
retains `fsweight` but not `PSU`, `stratum` or `windex5`. The worked examples
assume those are added.

## Publishing

`docs/` is the GitHub Pages source. Commit and push it after a render; nothing
in the build pipeline talks to GitHub.
