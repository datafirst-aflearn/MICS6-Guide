# AFLEARN MICS6 worked examples
# --------------------------------
# This is a reproducible template corresponding to Section 6 of the guide.
# Run only after Sections 3-5 have been completed.
#
# REQUIRED final AFLEARN FS fields not currently retained by v1.0:
#   PSU, stratum
#
# OPTIONAL for wealth example:
#   windex5 (merge from hh.sav or obtain from IPUMS)

library(tidyverse)
library(haven)
library(survey)
library(srvyr)

# -------------------------------------------------------------------------
# 1. READ AND MERGE
# -------------------------------------------------------------------------

harmonised <- file.path("Data", "AFLEARN Harmonised Data")

fs <- read_dta(file.path(harmonised, "mics6-fs-harmonised.dta"))
reading <- read_dta(file.path(harmonised, "mics6-reading-harmonised.dta"))

d <- fs %>%
  left_join(
    reading,
    by = c("country_iso3", "year", "HH1", "HH2", "LN"),
    relationship = "one-to-one",
    suffix = c("", "_reading")
  )

required <- c(
  "country_iso3", "year", "HH1", "HH2", "LN",
  "age", "enrolled", "current_level_h", "current_grade",
  "fsweight", "PSU", "stratum"
)

missing_required <- setdiff(required, names(d))

if (length(missing_required) > 0) {
  stop(
    "Missing required variables: ",
    paste(missing_required, collapse = ", "),
    "\nUpdate the harmonised FS file before running Section 6."
  )
}

# -------------------------------------------------------------------------
# 2. POOLED SURVEY IDENTIFIERS
# -------------------------------------------------------------------------

d <- d %>%
  mutate(
    survey_id = paste(country_iso3, year, sep = "_"),
    psu_pool = interaction(survey_id, PSU, drop = TRUE),
    stratum_pool = interaction(survey_id, stratum, drop = TRUE)
  )

# -------------------------------------------------------------------------
# 3. NUMERACY SCORES
# -------------------------------------------------------------------------

num_items <- c(
  grep("^number_id_", names(d), value = TRUE),
  grep("^number_compare_", names(d), value = TRUE),
  grep("^number_add_", names(d), value = TRUE),
  grep("^number_pattern_", names(d), value = TRUE)
)

# Remove any already-derived score fields if script is rerun.
num_items <- num_items[!grepl("_score$", num_items)]

if (length(num_items) != 21) {
  warning(
    "Expected 21 numeracy item variables but found ",
    length(num_items),
    ". Check the harmonisation crosswalk."
  )
}

score_correct <- function(x) {
  case_when(
    x == 1 ~ 1,
    x %in% c(2, 3) ~ 0,
    TRUE ~ NA_real_
  )
}

d <- d %>%
  mutate(
    across(
      all_of(num_items),
      score_correct,
      .names = "{.col}_score"
    )
  )

id_score <- grep("^number_id_.*_score$", names(d), value = TRUE)
compare_score <- grep("^number_compare_.*_score$", names(d), value = TRUE)
add_score <- grep("^number_add_.*_score$", names(d), value = TRUE)
pattern_score <- grep("^number_pattern_.*_score$", names(d), value = TRUE)

d <- d %>%
  rowwise() %>%
  mutate(
    n_number_id = sum(c_across(all_of(id_score)), na.rm = TRUE),
    n_number_compare = sum(c_across(all_of(compare_score)), na.rm = TRUE),
    n_number_add = sum(c_across(all_of(add_score)), na.rm = TRUE),
    n_number_pattern = sum(c_across(all_of(pattern_score)), na.rm = TRUE),
    numeracy_total_raw =
      n_number_id + n_number_compare + n_number_add + n_number_pattern,
    numeracy_total = if_else(
      age >= 7 & age <= 14 & fl_child_result == 1,
      as.numeric(numeracy_total_raw),
      NA_real_
    )
  ) %>%
  ungroup()

# IMPORTANT:
# foundational_numeracy should be added only after validating its exact
# construction against MICS published indicators. Do not invent it here.

# -------------------------------------------------------------------------
# 4. OTHER DERIVED VARIABLES
# -------------------------------------------------------------------------

d <- d %>%
  mutate(
    in_school = case_when(
      enrolled == 1 ~ 1,
      enrolled == 2 ~ 0,
      TRUE ~ NA_real_
    ),
    reading_attempted = reading_status %in% c(7, 8),
    language_mismatch = reading_status == 4
  )

# -------------------------------------------------------------------------
# 5. SURVEY DESIGN
# -------------------------------------------------------------------------

des <- d %>%
  as_survey_design(
    ids = psu_pool,
    strata = stratum_pool,
    weights = fsweight,
    nest = TRUE
  )

# -------------------------------------------------------------------------
# EXAMPLE 1. WHO IS ASSESSED?
# -------------------------------------------------------------------------

attendance_by_age <- des %>%
  filter(age >= 7, age <= 14) %>%
  group_by(country_iso3, year, age) %>%
  summarise(
    enrolled_share = survey_mean(
      in_school,
      vartype = c("se", "ci"),
      na.rm = TRUE
    )
  )

# -------------------------------------------------------------------------
# EXAMPLE 2. NUMERACY DISTRIBUTIONS
# -------------------------------------------------------------------------

numeracy_country <- des %>%
  filter(age >= 7, age <= 14) %>%
  group_by(country_iso3, year) %>%
  summarise(
    mean_score = survey_mean(
      numeracy_total,
      vartype = c("se", "ci"),
      na.rm = TRUE
    ),
    id_share_correct = survey_mean(
      n_number_id / 6,
      na.rm = TRUE
    ),
    compare_share_correct = survey_mean(
      n_number_compare / 5,
      na.rm = TRUE
    ),
    add_share_correct = survey_mean(
      n_number_add / 5,
      na.rm = TRUE
    ),
    pattern_share_correct = survey_mean(
      n_number_pattern / 5,
      na.rm = TRUE
    )
  )

# -------------------------------------------------------------------------
# EXAMPLE 3. READING STATUS
# -------------------------------------------------------------------------

reading_status_country <- des %>%
  filter(age >= 7, age <= 14) %>%
  group_by(country_iso3, year, reading_status) %>%
  summarise(
    share = survey_mean(
      proportion = TRUE,
      vartype = c("se", "ci"),
      na.rm = TRUE
    )
  )

# -------------------------------------------------------------------------
# EXAMPLE 4. READING LANGUAGE
# -------------------------------------------------------------------------

reading_language <- des %>%
  filter(
    age >= 7,
    age <= 14,
    reading_attempted
  ) %>%
  group_by(country_iso3, year, passage_language) %>%
  summarise(
    share = survey_mean(
      proportion = TRUE,
      na.rm = TRUE
    )
  )

language_mismatch_country <- des %>%
  filter(age >= 7, age <= 14) %>%
  group_by(country_iso3, year) %>%
  summarise(
    mismatch = survey_mean(
      language_mismatch,
      vartype = c("se", "ci"),
      na.rm = TRUE
    )
  )

# -------------------------------------------------------------------------
# EXAMPLE 5. WEALTH
# -------------------------------------------------------------------------

if ("windex5" %in% names(d)) {
  wealth_numeracy <- des %>%
    filter(age >= 7, age <= 14) %>%
    group_by(country_iso3, year, windex5) %>%
    summarise(
      mean_num = survey_mean(
        numeracy_total,
        vartype = c("se", "ci"),
        na.rm = TRUE
      )
    )
}

# -------------------------------------------------------------------------
# EXAMPLE 6. IN-SCHOOL VS OUT-OF-SCHOOL
# -------------------------------------------------------------------------

school_status <- des %>%
  filter(age >= 10, age <= 14) %>%
  group_by(country_iso3, year, age, in_school) %>%
  summarise(
    mean_num = survey_mean(
      numeracy_total,
      vartype = c("se", "ci"),
      na.rm = TRUE
    )
  )

# -------------------------------------------------------------------------
# EXAMPLE 7. GRADE TRAJECTORIES
# -------------------------------------------------------------------------

grade_num <- des %>%
  filter(
    age >= 7,
    age <= 14,
    enrolled == 1,
    current_level_h == 1,
    current_grade >= 1,
    current_grade <= 6
  ) %>%
  group_by(country_iso3, year, current_grade) %>%
  summarise(
    mean_num = survey_mean(
      numeracy_total,
      vartype = c("se", "ci"),
      na.rm = TRUE
    ),
    mean_age = survey_mean(
      age,
      vartype = c("se", "ci"),
      na.rm = TRUE
    )
  )

trajectory_model <- svyglm(
  numeracy_total ~
    factor(country_iso3) *
    (current_grade + I(current_grade^2)),
  design = subset(
    des,
    enrolled == 1 &
      current_level_h == 1 &
      current_grade >= 1 &
      current_grade <= 6
  )
)

# -------------------------------------------------------------------------
# EXAMPLE 8. SCHOOL-YEAR TIMING
# -------------------------------------------------------------------------
# Requires a validated country-level school calendar:
#
# school_calendar <- read_csv("Data/school_calendar.csv")
#
# d <- d %>%
#   left_join(school_calendar, by = "country_iso3") %>%
#   mutate(
#     school_month = (interview_month - school_start_month) %% 12,
#     gradeprogress = current_grade + school_month / 12
#   )
#
# Re-create des after adding gradeprogress, then fit:
#
# timing_model <- svyglm(
#   numeracy_total ~
#     factor(country_iso3) *
#     (gradeprogress + I(gradeprogress^2)),
#   design = subset(
#     des,
#     enrolled == 1 &
#       current_level_h == 1 &
#       gradeprogress >= 1 &
#       gradeprogress <= 6
#   )
# )

# -------------------------------------------------------------------------
# SAVE OUTPUT TABLES IF DESIRED
# -------------------------------------------------------------------------

dir.create("output", showWarnings = FALSE)

write_csv(attendance_by_age, "output/attendance_by_age.csv")
write_csv(numeracy_country, "output/numeracy_country.csv")
write_csv(reading_status_country, "output/reading_status_country.csv")
write_csv(reading_language, "output/reading_language.csv")
write_csv(language_mismatch_country, "output/language_mismatch_country.csv")
write_csv(school_status, "output/school_status.csv")
write_csv(grade_num, "output/grade_numeracy.csv")
