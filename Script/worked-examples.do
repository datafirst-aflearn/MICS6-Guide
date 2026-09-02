*******************************************************
* AFLEARN MICS6 WORKED EXAMPLES
* Corresponds to Section 6 of the online guide
*******************************************************

clear all
set more off

* -----------------------------------------------------
* 1. READ AND MERGE
* -----------------------------------------------------

use "Data/AFLEARN Harmonised Data/mics6_fs_harmonized.dta", clear

merge 1:1 country_iso3 year HH1 HH2 LN using ///
    "Data/AFLEARN Harmonised Data/mics6_reading_harmonized.dta"

tab _merge
drop _merge

* Required before publication:
* harmonize-mics-fs-v1.0.R must retain PSU and stratum.

confirm variable PSU
confirm variable stratum
confirm variable fsweight

* -----------------------------------------------------
* 2. POOLED SURVEY DESIGN
* -----------------------------------------------------

egen survey_id = group(country_iso3 year)
egen psu_pool = group(survey_id PSU)
egen stratum_pool = group(survey_id stratum)

svyset psu_pool [pw=fsweight], strata(stratum_pool)

* -----------------------------------------------------
* 3. DERIVED SCHOOLING / READING VARIABLES
* -----------------------------------------------------

gen in_school = .
replace in_school = 1 if enrolled == 1
replace in_school = 0 if enrolled == 2

gen reading_attempted = inlist(reading_status,7,8) ///
    if reading_status < .

gen language_mismatch = reading_status == 4 ///
    if reading_status < .

* -----------------------------------------------------
* 4. NUMERACY SCORE TEMPLATE
* -----------------------------------------------------
* Harmonised fields:
*   number_id_*
*   number_compare_*
*   number_add_*
*   number_pattern_*
*
* 1 = correct, 2 = incorrect, 3 = no attempt.
*
* This code creates 0/1 score versions. Confirm the exact
* item names with describe before running.

ds number_id_* number_compare_* number_add_* number_pattern_*
local numvars `r(varlist)'

foreach v of local numvars {
    gen `v'_score = .
    replace `v'_score = 1 if `v' == 1
    replace `v'_score = 0 if inlist(`v',2,3)
}

egen n_number_id = rowtotal(number_id_*_score)
egen n_number_compare = rowtotal(number_compare_*_score)
egen n_number_add = rowtotal(number_add_*_score)
egen n_number_pattern = rowtotal(number_pattern_*_score)

gen numeracy_total = ///
    n_number_id + n_number_compare + ///
    n_number_add + n_number_pattern ///
    if inrange(age,7,14) & fl_child_result == 1

* foundational_numeracy should be added only after validating
* exact construction against published MICS indicators.

* -----------------------------------------------------
* EXAMPLE 1. WHO IS ASSESSED?
* -----------------------------------------------------

svy, subpop(if inrange(age,7,14)): ///
    mean in_school, over(country_iso3 age)

* -----------------------------------------------------
* EXAMPLE 2. NUMERACY DISTRIBUTIONS
* -----------------------------------------------------

svy, subpop(if inrange(age,7,14)): ///
    mean numeracy_total, over(country_iso3)

gen prop_id = n_number_id/6
gen prop_compare = n_number_compare/5
gen prop_add = n_number_add/5
gen prop_pattern = n_number_pattern/5

svy, subpop(if inrange(age,7,14)): ///
    mean prop_id prop_compare prop_add prop_pattern, ///
    over(country_iso3)

* -----------------------------------------------------
* EXAMPLE 3. READING STATUS
* -----------------------------------------------------

svy, subpop(if inrange(age,7,14)): ///
    proportion reading_status, over(country_iso3)

* -----------------------------------------------------
* EXAMPLE 4. READING LANGUAGE
* -----------------------------------------------------

svy, subpop(if inrange(age,7,14) & reading_attempted): ///
    proportion passage_language, over(country_iso3)

svy, subpop(if inrange(age,7,14)): ///
    mean language_mismatch, over(country_iso3)

* -----------------------------------------------------
* EXAMPLE 5. WEALTH
* -----------------------------------------------------
* Requires windex5 merged from hh.sav or WINDEX5 from IPUMS.

capture confirm variable windex5

if !_rc {
    svy, subpop(if inrange(age,7,14)): ///
        mean numeracy_total, over(country_iso3 windex5)
}

* -----------------------------------------------------
* EXAMPLE 6. IN-SCHOOL / OUT-OF-SCHOOL
* -----------------------------------------------------

svy, subpop(if inrange(age,10,14)): ///
    mean numeracy_total, ///
    over(country_iso3 age in_school)

svy: regress numeracy_total i.age i.in_school ///
    if inrange(age,10,14)

* -----------------------------------------------------
* EXAMPLE 7. GRADE TRAJECTORIES
* -----------------------------------------------------

svy, subpop(if inrange(age,7,14) & enrolled==1 & ///
    current_level_h==1 & inrange(current_grade,1,6)): ///
    mean numeracy_total, ///
    over(country_iso3 current_grade)

svy: regress numeracy_total ///
    i.country_iso3##c.current_grade##c.current_grade ///
    if enrolled==1 & current_level_h==1 & ///
       inrange(current_grade,1,6)

testparm i.country_iso3#c.current_grade ///
         i.country_iso3#c.current_grade#c.current_grade

* -----------------------------------------------------
* EXAMPLE 8. SCHOOL-YEAR TIMING
* -----------------------------------------------------
* Requires validated school_month variable.

capture confirm variable school_month

if !_rc {
    gen gradeprogress = current_grade + school_month/12

    svy: regress numeracy_total ///
        i.country_iso3##c.gradeprogress##c.gradeprogress ///
        if enrolled==1 & current_level_h==1 & ///
           inrange(gradeprogress,1,6)

    testparm i.country_iso3#c.gradeprogress ///
             i.country_iso3#c.gradeprogress#c.gradeprogress

    margins country_iso3, at(gradeprogress=(1(0.25)6))
    marginsplot
}

*******************************************************
* END
*******************************************************
