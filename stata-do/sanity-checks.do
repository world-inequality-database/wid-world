//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
//                          Sanity checks.do                              
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

// Purpose: This Do-File is to ensure the consistency of series in terms of 
// monotonicity and other conditions.

//==============================================================================
// --------------------------- Load Data ---------------------------------------
//==============================================================================
 
u "$work_data/calculate-gini-coef-output.dta", clear
keep iso year widcode p value

//==============================================================================
// ----------------- Keep only distributions that we update --------------------
//==============================================================================

keep if strpos(widcode, "ptinc") | strpos(widcode, "hweal") | strpos(widcode, "diinc") | ///
		strpos(widcode, "cainc") | strpos(widcode, "fiinc") | strpos(widcode, "fainc")

//==============================================================================
// -------------------------------- Parse data ---------------------------------
//==============================================================================

//parse percentiles 
generate long p_min = round(1000*real(regexs(1))) if regexm(p, "^p([0-9\.]+)p([0-9\.]+)$")
generate long p_max = round(1000*real(regexs(2))) if regexm(p, "^p([0-9\.]+)p([0-9\.]+)$")

replace p_min = round(1000*real(regexs(1))) if regexm(p, "^p([0-9\.]+)$")
replace p_max = 1000*100 if (substr(widcode, 1, 1) == "s") & missing(p_max)

replace p_max = p_min + 1000 if (substr(widcode, 1, 1) == "a") & missing(p_max) & inrange(p_min, 0, 98000)
replace p_max = p_min + 100  if (substr(widcode, 1, 1) == "a") & missing(p_max) & inrange(p_min, 99000, 99800)
replace p_max = p_min + 10   if (substr(widcode, 1, 1) == "a") & missing(p_max) & inrange(p_min, 99900, 99980)
replace p_max = p_min + 1    if (substr(widcode, 1, 1) == "a") & missing(p_max) & inrange(p_min, 99990, 99999)

replace p = "p" + string(round(p_min/1e3, 0.001)) + "p" + string(round(p_max/1e3, 0.001)) if !missing(p_max)
generate n = round(p_max - p_min, 1)

sort iso widcode year p_min
gduplicates drop iso year widcode p, force

*save "$work_data/calculate-gini-coef-output-parsed.dta", replace
*u "$work_data/calculate-gini-coef-output-parsed.dta", clear 

//==============================================================================
// ----------- Run tests on (i) 127 g-percentiles and (ii) Deciles -------------
//==============================================================================

capture program drop run_checks
program define run_checks
    syntax, GRID(string) NB(integer)

    preserve

    if "`grid'" == "g127" {
        keep if inlist(n, 1, 10, 100, 1000)
        drop if n == 1000 & p_min >= 99000
        drop if n == 100  & p_min >= 99900
        drop if n == 10   & p_min >= 99990
    }
    else if "`grid'" == "decile" {
        keep if n == 10000
    }

    drop p p_max
    rename p_min p
    gduplicates drop iso year p widcode, force
    sort iso year widcode p

// only keep the series that have complete observations 
    bys iso year widcode: gen nb_obs = _N
    drop if nb_obs < `nb'
    drop nb_obs
	
// obtain data in wide format with a,s,t
    gen type = substr(widcode, 1, 1)
    gen widcode2 = substr(widcode, 2, .)
    drop widcode
	format value %20.5f
    reshape wide value, i(iso year p widcode2) j(type) string
    rename valuea a
    rename values s
    rename valuet t
    rename widcode2 widcode

// generate order	
    bys iso year widcode (p): gen order = _n

// rounding to the degree thats on our opensource database
	replace t = round(t, 0.1)
    replace a = round(a, 0.1)
    *replace s = round(s, 0.0001)

//==============================================================================
// ----------------- Check increasing values across percentiles ----------------
//==============================================================================
    bys iso year widcode (order): gen double a_forw = a[_n+1]
    bys iso year widcode (order): gen double t_forw = t[_n+1]
	bys iso year widcode (order): gen double s_forw = s[_n+1]

	format a* t* %20.5f

// check non-decreasing percentile averages
    gen byte decr_avg = a_forw < a - 0.05  if !missing(a_forw)
    replace decr_avg = 0 if missing(decr_avg)
	
// check non-decreasing percentile thresholds
    gen byte decr_thr = t_forw < t - 0.05 if !missing(t_forw)
    replace decr_thr = 0 if missing(decr_thr)
	
// check non-decreasing percentile shares for equally sized percentiles
    gen byte decr_sh = s_forw < s - 0.0001 if !missing(s_forw) & p<= 97000
    replace decr_sh = 0 if missing(decr_sh)

//==============================================================================
// ------------- Check monotonicity of thresholds with averages ----------------
//==============================================================================

// averages should not be below percentile threshold 
    gen byte t_greater_a = 1 if a < t - 0.05 & !missing(t)
	replace t_greater_a = 0 if missing(t_greater_a)

// averages should not exceed next percentile threshold
    gen byte a_greater_tforw = 1 if a > t_forw + 0.05 & !missing(t_forw) & !missing(a)
	replace a_greater_tforw = 0 if missing(a_greater_tforw)

	gen byte a_not_between = t_greater_a | a_greater_tforw
	
//==============================================================================
// ------------------------ Check shares sum up to 1 ---------------------------
//==============================================================================
    bys iso year widcode: egen sum_s = total(s)
    replace sum_s = round(sum_s, 0.001)
    gen byte sum_ok = abs(sum_s - 1) < 0.001
	
//==============================================================================
// ----------------------------- Report results --------------------------------
//==============================================================================
    di "Checks for `grid'"
    tab decr_avg
    tab decr_thr
	tab decr_sh
	tab a_not_between
    tab a_greater_tforw
    tab t_greater_a
    tab sum_ok
	
	save "$work_data/checks_`grid'.dta", replace
    restore
end

run_checks, grid(g127) nb(127)
di "Monotonicity checks for 127 g-percentiles finished :)"

run_checks, grid(decile) nb(10)
di "Monotonicity checks for deciles finished :)"

*u "$work_data/checks_g127.dta", clear
u "$work_data/checks_decile.dta", clear


//==============================================================================
// ------------------------ Check gini pre-tax > Gini post-tax -----------------
// (higher gini means more inequality)
//==============================================================================

u "$work_data/calculate-gini-coef-output.dta", clear
keep iso year widcode p value

keep if inlist(widcode, "gptinc992j", "gdiinc992j")
replace value = round(value, 0.0001)
reshape wide value, i(iso year p) j(widcode) string
rename value* *
keep if year >= 1980 //post-tax series only available after 1980
drop if gdiinc992j==.

// redistribution should reduce inequality as measured by gini. flag if not
gen flag = gdiinc992j - 0.0001 > gptinc992j
tab flag

gen gdif = gdiinc992j - gptinc992j
gsort -gdif
//==============================================================================
// ------------------------ Check gini is between 0 and 1 ----------------------
//==============================================================================


























