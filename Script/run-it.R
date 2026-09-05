# AFLEARN MICS6 -- run the whole data preparation pipeline.
#
# This is the only script you need to run.
#
# 1. Make a folder for the project, for example "MICS project".
# 2. Unzip the AFLEARN Script folder into it, so you have "MICS project/Script".
# 3. Put the UNICEF MICS_Datasets.zip in the project folder.
# 4. In R, set the project folder as the working directory and source this file:
#
#      setwd("C:/path/to/MICS project")
#      source("Script/run-it.R")
#
# When it finishes you will have:
#
#   MICS project/
#     Data/
#       UNICEF/                    one clean folder per survey
#       AFLEARN Harmonised Data/   harmonised analysis files
#     Script/                      these scripts
#
# Base R only -- no extra packages are needed for the unzip step. The
# harmonisation scripts have their own package requirements.

SCRIPT_DIR_NAME <- "Script"
PREPARE_SCRIPT <- "prepare-mics-fs.R"

# Run in this order. Each is sourced from Script/ if it is present.
HARMONISE_SCRIPTS <- c(
  "harmonize-mics-fs-v1.0.R",
  "harmonize-mics-reading-v1.1.R"
)

run_it <- function() {
  if (!dir.exists(SCRIPT_DIR_NAME)) {
    stop(
      "No '", SCRIPT_DIR_NAME, "' folder in the working directory:\n  ", getwd(),
      "\n\nThe working directory must be your MICS project folder -- the one\n",
      "containing the ", SCRIPT_DIR_NAME, " folder you unzipped. For example:\n",
      "  setwd(\"C:/path/to/MICS project\")\n",
      "  source(\"", SCRIPT_DIR_NAME, "/run-it.R\")",
      call. = FALSE
    )
  }

  prepare_path <- file.path(SCRIPT_DIR_NAME, PREPARE_SCRIPT)
  if (!file.exists(prepare_path)) {
    stop(
      "Could not find ", prepare_path, ".\n",
      "Re-unzip the AFLEARN Script folder into your project folder.",
      call. = FALSE
    )
  }

  message("=====================================================")
  message(" AFLEARN MICS6 -- preparing the UNICEF download")
  message("=====================================================")
  message("Project folder: ", normalizePath(getwd(), winslash = "/"))
  message("")

  # Sourced into the global environment so that prepare_mics_data() stays
  # available afterwards if you want to re-run it with different arguments.
  source(prepare_path)
  prepared <- prepare_mics_data()

  ran <- character()
  skipped <- character()

  for (s in HARMONISE_SCRIPTS) {
    path <- file.path(SCRIPT_DIR_NAME, s)
    if (!file.exists(path)) {
      skipped <- c(skipped, s)
      next
    }
    message("")
    message("=====================================================")
    message(" Running ", s)
    message("=====================================================")
    source(path)
    ran <- c(ran, s)
  }

  if (length(skipped) > 0L) {
    warning(
      "Harmonisation step(s) skipped because the script is not in ",
      SCRIPT_DIR_NAME, "/:\n  ",
      paste(skipped, collapse = "\n  "),
      "\nThe UNICEF folders have still been prepared. Add the missing ",
      "script(s)\nto ", SCRIPT_DIR_NAME, "/ and run this file again to harmonise.",
      call. = FALSE,
      immediate. = TRUE
    )
  }

  paths <- prepared$paths

  message("")
  message("=====================================================")
  message(" Finished")
  message("=====================================================")
  message("  UNICEF country data:  ", paths$unicef)
  message("  Harmonised output:    ", paths$harmonised)
  message("  Scripts:              ", paths$script)
  if (length(ran) > 0L) {
    message("  Harmonisation steps run:")
    for (s in ran) message("    - ", s)
  }
  if (length(skipped) > 0L) {
    message("  Harmonisation steps skipped (script missing):")
    for (s in skipped) message("    - ", s)
  }

  invisible(list(
    prepared = prepared,
    harmonisation_run = ran,
    harmonisation_skipped = skipped
  ))
}

run_it()

