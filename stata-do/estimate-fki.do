// -------------------------------------------------------------------------- //
// Imputing Foreign Capital Income
// -------------------------------------------------------------------------- //

// ------------------  Index  ----------------------------------------------- //
//   1. Import data
//   2. Clean and complete data
//   3. Transform share values to monetary
//   4. Adjust monetary values
//   5. Predicting rates of return 
// 			 5.1  Non Tax Havens
// 			 5.2  Tax Havens
//   6.  completing missing assets
//   7. completing missing income
//   8. ensuring consistency
//   9. Merging with retropolate
//  10. Export
// -------------------------------------------------------------------------- //


// -------------------------------------------------------------------------- //
// --- 1. Import data ------------------------------------------------------- //
// -------------------------------------------------------------------------- //
u "$work_data/sna-combined-prefki.dta", clear

drop series_*
keep iso year *pinrx *pinpx *fdirx *ptfrx* *fdipx *ptfpx* *nnfin *pinnx *fdinx *ptfnx flag* neg*
drop miss*

// adding corecountry dummy and Tax Haven dummy
*merge 1:1 iso year using "$work_data/country-codes-list-core-year.dta", nogen keepusing(country corecountry TH) 
merge 1:1 iso year using "$work_data/import-core-country-codes-year-output", nogen keepusing(shortname corecountry TH) 
rename shortname countryname
keep if corecountry == 1

merge 1:1 iso year using "$work_data/foreign-wealth-total-EWN_new.dta", nogen

// -------------------------------------------------------------------------- //
// --- 2. Clean and complete data  ------------------------------------------ //
// -------------------------------------------------------------------------- //

// fixing some imputations
replace fdixa =. if inlist(iso, "DM", "HT") & year == 1994
replace fdixa =. if inlist(iso, "SL")
replace fdixa =. if inlist(iso, "GT") & (year == 1981 | year == 1987 | year == 1992)
replace fdixa =. if inlist(iso, "RO") & year <= 1995
replace fdixa =. if inlist(iso, "TR") & inrange(year,1974,1987)
replace fdixa =. if inlist(iso, "TO") & inrange(year,1978,1999)
replace fdixa =. if inlist(iso, "SV") & inrange(year,1987,1995)
replace fdixa =. if inlist(iso, "CV") & inrange(year,1988,2006)
replace fdixa =. if inlist(iso, "TN") & year == 1978
replace fdirx =. if fdirx < 0 & fdixa < 0
replace fdipx =. if fdipx < 0 & fdixd < 0
replace fdixa =. if fdixa < 0
replace ptfxa =. if ptfxa < 0
replace fdixd =. if fdixd < 0
replace ptfxd =. if ptfxd < 0

replace fdixd =. if iso == "AG" & year == 1978
replace fdixd =. if iso == "KN" & year == 1979
replace fdixd =. if iso == "MO" & (year == 1993 | year == 1998)

so iso year
by iso : ipolate fdixd year if inlist(iso, "AG", "KN", "MO"), gen(xfdixd) 
replace q_fdixd = 3      if missing(fdixd) & !missing(xfdixd)
replace s_fdixd = "ipol" if missing(fdixd) & !missing(xfdixd)
replace fdixd = xfdixd if missing(fdixd) 
drop xfdixd


replace q_fdirx = 0          if fdixa == 0 & (flagfdirx == 1 | flagimffdirx == 1 | missing(flagimffdirx))
replace q_fdipx = 0          if fdixd == 0 & (flagfdipx == 1 | flagimffdipx == 1 | missing(flagimffdipx))
replace q_ptfrx = 0          if ptfxa == 0 & (flagptfrx == 1 | flagimfptfrx == 1 | missing(flagimfptfrx)) 
replace q_ptfpx = 0          if ptfxd == 0 & (flagptfpx == 1 | flagimfptfpx == 1 | missing(flagimfptfpx))
replace s_fdirx = "assumed0" if fdixa == 0 & (flagfdirx == 1 | flagimffdirx == 1 | missing(flagimffdirx))
replace s_fdipx = "assumed0" if fdixd == 0 & (flagfdipx == 1 | flagimffdipx == 1 | missing(flagimffdipx))
replace s_ptfrx = "assumed0" if ptfxa == 0 & (flagptfrx == 1 | flagimfptfrx == 1 | missing(flagimfptfrx)) 
replace s_ptfpx = "assumed0" if ptfxd == 0 & (flagptfpx == 1 | flagimfptfpx == 1 | missing(flagimfptfpx))
replace   fdirx = 0          if fdixa == 0 & (flagfdirx == 1 | flagimffdirx == 1 | missing(flagimffdirx))
replace   fdipx = 0          if fdixd == 0 & (flagfdipx == 1 | flagimffdipx == 1 | missing(flagimffdipx))
replace   ptfrx = 0          if ptfxa == 0 & (flagptfrx == 1 | flagimfptfrx == 1 | missing(flagimfptfrx)) 
replace   ptfpx = 0          if ptfxd == 0 & (flagptfpx == 1 | flagimfptfpx == 1 | missing(flagimfptfpx))

replace fdirx =. if fdirx == 0 & abs(fdixa) > 0 & negfdirx != 1
replace fdipx =. if fdipx == 0 & abs(fdixd) > 0 & negfdipx != 1
replace ptfrx =. if ptfrx == 0 & abs(ptfxa) > 0
replace ptfpx =. if ptfpx == 0 & abs(ptfxd) > 0

replace q_fdirx = min(3, q_pinrx) if ptfrx == 0 & pinrx != 0
replace q_fdipx = min(3, q_pinpx) if ptfpx == 0 & pinpx != 0
replace q_ptfrx = min(3, q_pinrx) if fdirx == 0 & pinrx != 0
replace q_ptfpx = min(3, q_pinpx) if fdipx == 0 & pinpx != 0
replace s_fdirx = "pinrx"         if ptfrx == 0 & pinrx != 0
replace s_fdipx = "pinpx"         if ptfpx == 0 & pinpx != 0
replace s_ptfrx = "pinrx"         if fdirx == 0 & pinrx != 0
replace s_ptfpx = "pinpx"         if fdipx == 0 & pinpx != 0
replace   fdirx = pinrx           if ptfrx == 0 & pinrx != 0
replace   fdipx = pinpx           if ptfpx == 0 & pinpx != 0
replace   ptfrx = pinrx           if fdirx == 0 & pinrx != 0
replace   ptfpx = pinpx           if fdipx == 0 & pinpx != 0

// maybe change later in other dofile
foreach v in ptfrx {
	replace `v'=. if iso == "DJ" & (year >= 2013 | year <= 1977) // not in original IMF BOP
	replace `v'=. if iso == "RW" & (year == 1980 | year == 1981) // not in original IMF BOP
	replace `v'=. if iso == "MN" & (year >= 1989 & year <= 1991) // not in original IMF BOP
	replace `v'=. if iso == "LS" & flag`v' == 1 & missing(flagimf`v') // it's just for first years where pinrx is inflated
	replace `v'=. if iso == "FM" & flag`v' == 1 & missing(flagimf`v') // not sure about this
}

foreach v in ptfrx ptfpx {
	replace `v'=. if inlist(iso, "ER") & flag`v' == 1 // not in original IMF BOP
}
foreach v in ptfrx ptfpx fdirx fdipx {
	replace `v'=. if iso == "GL" // not in original IMF BOP
	replace `v'=. if iso == "AF" & flag`v' == 1 // not in original IMF BOP 
	replace `v'=. if iso == "GH" & flag`v' == 1 & missing(flagimf`v') // only for the beginning
	replace `v'=. if iso == "JO" & flag`v' == 1 & missing(flagimf`v') // only for the beginning
	replace `v'=. if iso == "BM" & flag`v' == 1 & missing(flagimf`v') // only for the beginning
	}

foreach v in fdirx {
	replace   `v'=.          if iso == "NI" & flagimf`v' == 1 & fdixa != 0
	replace   `v'=0          if iso == "MG" & year == 1989 // does not have FDI data from EWN but has FDI income from IMF BOP
	replace s_`v'="assumed0" if iso == "MG" & year == 1989 
	replace q_`v'=0          if iso == "MG" & year == 1989 
	replace   `v'=0          if iso == "TZ" & year < 1999 // does not have FDI data from EWN but has FDI income from IMF BOP
	replace s_`v'="assumed0" if iso == "TZ" & year < 1999
	replace q_`v'=0          if iso == "TZ" & year < 1999
	replace   `v'=0          if iso == "UG" & inrange(year,1985,1986) // does not have FDI data from EWN but has FDI income from IMF BOP
	replace   `v'=.          if iso == "CD" & flagimf`v' == 1 & fdixa != 0
	replace   `v'=.          if iso == "TD" & flag`v' == 1 & fdixa != 0 & missing(flagimf`v') // maybe also change ptfrx 
	replace   `v'=.          if iso == "CV" & inrange(year,1997,1999) // not in original IMF BOP 
	replace   `v'=.          if iso == "GH" & fdixa != 0
	replace   `v'=0          if iso == "GN" & year == 2015 // not in original IMF BOP 
	replace s_`v'="assumed0" if iso == "GN" & year == 2015
	replace q_`v'=0          if iso == "GN" & year == 2015
	replace   `v'=.          if iso == "GN" & year == 2016 // not in original IMF BOP 
	replace   `v'=.          if iso == "GW" & year == 2010
	replace   `v'=0          if iso == "NE" & year < 1980 // EWN data = 0 
	replace s_`v'="assumed0" if iso == "NE" & year < 1980
	replace q_`v'=0          if iso == "NE" & year < 1980
	replace   `v'=.          if iso == "AZ" & fdixa != 0 & year <= 2004 // only data for 2003 in IMF BOP
	replace   `v'=.          if iso == "SY" & flagimf`v' == 1 & fdixa != 0 & year >= 2006
	replace   `v'=.          if iso == "TC" & year == 2012 // not in original IMF BOP 
 	replace   `v'=.          if iso == "VC" & inrange(year,1999,2004) // weird records with the same data every other year
	replace   `v'=0          if iso == "ZM" & year == 1997 // only year until 2016 with data
	replace s_`v'="assumed0" if iso == "ZM" & year == 1997
	replace q_`v'=0          if iso == "ZM" & year == 1997
}

ds iso year q_* s_* TH corecountry countryname neg* flag*, not
foreach v in `r(varlist)' {
	replace s_`v' = "" if missing(`v')
	replace q_`v' = .  if missing(`v')
}

foreach v in ptfrx fdirx ptfxd fdipx {
	replace   `v'=.  if inlist(iso, "AE") & (year == 2010 | year == 2020) // not in original IMF BOP 
	replace q_`v'=.  if inlist(iso, "AE") & (year == 2010 | year == 2020) 
	replace s_`v'="" if inlist(iso, "AE") & (year == 2010 | year == 2020) 
	so iso year
	by iso :    ipolate `v' year if inlist(iso, "AE"), gen(x`v') 
	replace q_`v' = 3      if missing(`v') & !missing(x`v') 
	replace s_`v' = "ipol" if missing(`v') & !missing(x`v') 
	replace   `v' = x`v'   if missing(`v') 
	drop x`v'
	gsort iso year 
	by iso: carryforward `v' if inlist(iso, "AE"), replace 
	replace q_`v' = 1              if missing(q_`v') & !missing(`v') 
	replace s_`v' = "carryfor" if missing(s_`v')       & !missing(`v')
}

foreach v in ptfrx { 
	so iso year
	replace   `v' = .  if inlist(iso, "MT") & year == 1970 // not in original IMF BOP 
	replace q_`v' = .  if inlist(iso, "MT") & year == 1970  
	replace s_`v' = "" if inlist(iso, "MT") & year == 1970 
	gsort iso -year 
	by iso: carryforward `v' if inlist(iso, "MT"), replace
	replace q_`v' = 1          if missing(q_`v') & !missing(`v') 
	replace s_`v' = "carryfor" if missing(s_`v')       & !missing(`v') 
}
so iso year

foreach v in fdirx { 
	so iso year
	replace `v' =.  if iso == "SM" & year == 2013 // not in original IMF BOP
	replace `v' =.  if iso == "QA" & year == 2003 // not in original IMF BOP
	replace `v' = . if iso == "TR" & flagimf`v' == 1
	replace `v' = . if iso == "LB" & inrange(year,1983,1996) //  weird but I prefer to respect pinrx. maybe change the composition of fdirx ptfrx later. not in original IMF BOP
	by iso : ipolate    `v' year if inlist(iso, "KR", "ZM", "SM", "CV", "GN", "GW", "QA", "TR") | inlist(iso, "NZ", "PG", "WS", "LB", "JP"), gen(x`v') 
	replace q_`v' = 3      if missing(`v') & !missing(x`v')
	replace s_`v' = "ipol" if missing(`v') & !missing(x`v')
	replace   `v' = x`v' if missing(`v') 
	drop x`v'
	replace q_`v' = 0          if iso == "LB" & year == 1983
	replace s_`v' = "assumed" if iso == "LB" & year == 1983
	replace   `v' = 0          if iso == "LB" & year == 1983
	replace `v' = . if inlist(iso, "GR") & year == 1970 // not in original IMF BOP
	gsort iso -year 
	by iso: carryforward `v' if inlist(iso, "GR"), replace
	by iso: carryforward `v' if iso == "UZ", replace
	replace  q_`v' = 1              if missing(q_`v') & !missing(`v') 
	replace  s_`v' = "carryfor" if missing(s_`v')       & !missing(`v') 
}
so iso year

replace q_ptfxd =.  if iso == "RO" & flagnwgxd == 1
replace s_ptfxd ="" if iso == "RO" & flagnwgxd == 1
replace   ptfxd =.  if iso == "RO" & flagnwgxd == 1

gsort iso -year 
by iso: carryforward ptfxd if inlist(iso, "RO"), replace 
replace q_ptfxd = 1              if missing(q_ptfxd) & !missing(ptfxd) 
replace s_ptfxd = "carryfor" if missing(s_ptfxd)       & !missing(ptfxd) 

foreach v in ptfpx {
	replace `v'=. if iso == "ER" & flag`v' == 1 & ptfxd != 0 //before was flagimf. not in original IMF BOP
	replace `v'=. if iso == "LV" & flag`v' == 1 & missing(flagimf`v') & ptfxd != 0
	replace `v'=. if iso == "TH" & flag`v' == 1 & missing(flagimf`v') & ptfxd != 0
	replace `v'=. if iso == "SA" & year == 1970 // before was < 1975. I prefer to respect pinpx. not in original IMF BOP
}

ds iso year q_* s_* neg* flag* TH corecountry countryname, not
foreach v in `r(varlist)' {
	replace s_`v' = "" if missing(`v')
	replace q_`v' = .  if missing(`v')
}

foreach v in ptfpx { 
	so iso year
	replace q_`v' = .      if iso == "TD" & year == 2006 
	replace s_`v' = ""     if iso == "TD" & year == 2006 
	replace   `v' = .      if iso == "TD" & year == 2006 // not in original IMF BOP
	
	by iso : ipolate    `v' year     if inlist(iso, "KI", "TD", "DK", "BF", "CV", "GN", "LR", "QA"), gen(x`v') 
	replace q_`v' = 3      if missing(`v') & !missing(x`v')
	replace s_`v' = "ipol" if missing(`v') & !missing(x`v')
	replace   `v' = x`v'   if missing(`v') 
	drop x`v'
	replace   `v' = . if inlist(iso, "MT") & year == 1970 // not in original IMF BOP 
	gsort iso -year 
	by iso: carryforward `v' if inlist(iso, "DK", "BF", "CV", "GN", "SA", "MT"), replace
}
so iso year

foreach v in fdipx {
	replace `v'=. if iso == "ER" & flagimf`v' == 1 & fdixd != 0
	replace `v'=. if iso == "SA" & flagimf`v' == 1
}

replace fdixa =. if fdixa == 0 & abs(fdirx) > 0 & !missing(fdirx)
replace fdixd =. if fdixd == 0 & abs(fdipx) > 0 & !missing(fdipx)
replace ptfxa =. if ptfxa == 0 & abs(ptfrx) > 0 & !missing(ptfrx)
replace ptfxd =. if ptfxd == 0 & abs(ptfpx) > 0 & !missing(ptfpx)

ds iso year q_* s_* neg* flag* TH corecountry countryname, not
foreach v in `r(varlist)' {
	replace s_`v' = "" if missing(`v')
	replace q_`v' = .  if missing(`v')
}

so iso year
by iso : ipolate fdixd year if inlist(iso, "SL"), gen(xfdixd) 
replace q_fdixd = 3      if missing(fdixd) & !missing(xfdixd)
replace s_fdixd = "ipol" if missing(fdixd) & !missing(xfdixd)
replace   fdixd = xfdixd if missing(fdixd) 
drop xfdixd

foreach v in fdixa { 
	so iso year
	by iso : ipolate `v' year if inlist(iso, "GA", "TN", "CV", "SV", "TO", "TR") | inlist(iso, "RO", "GT", "SL", "DM", "HT"), gen(x`v') 
	replace q_`v' = 3      if missing(`v') & !missing(x`v')
	replace s_`v' = "ipol" if missing(`v') & !missing(x`v')
	replace   `v' = x`v'   if missing(`v') 
	drop x`v'
	gsort iso -year 
	by iso: carryforward `v' if iso == "IS", replace
	replace q_`v' = 3      if missing(q_`v') & !missing(`v') &  iso == "IS"
	replace s_`v' = "ipol" if missing(      s_`v') & !missing(`v') &  iso == "IS"
}

foreach v in fdixa ptfxa fdixd ptfxd { 
	so iso year
	replace q_`v'=.  if iso == "CU"
	replace s_`v'="" if iso == "CU"
	replace   `v'=.  if iso == "CU"
	
	by iso : ipolate `v' year   if iso != "TR", gen(x`v') 
	replace q_`v' = 3      if missing(`v') & !missing(x`v') 
	replace s_`v' = "ipol" if missing(`v') & !missing(x`v') 
	replace   `v' = x`v'   if missing(`v') 
	drop x`v'
	*gsort iso -year 
	*by iso: carryforward `v', replace
}

foreach x in eq deb {
	replace ptfrx_`x' = . if ptfrx == . & negptfrx_`x' != 1
	replace ptfpx_`x' = . if ptfpx == . & negptfpx_`x' != 1
}
replace ptfrx_res = . if ptfrx == . & negptfrx_res != 1

ds iso year q_* s_* TH corecountry countryname neg* flag*, not
foreach v in `r(varlist)' {
	replace s_`v' = "" if missing(`v')
	replace q_`v' = .  if missing(`v')
}

foreach v in fdirx fdipx ptfrx ptfpx ptfrx_eq ptfrx_deb ptfrx_res ptfpx_eq ptfpx_deb {
	gsort iso year
	by iso : carryforward `v'        if year >= 2020, replace 
	by iso : carryforward flagimf`v' if year >= 2020, replace
	by iso : carryforward flag`v'    if year >= 2020, replace
	replace flag`v' = 0              if flagimf`v' == 0 & year >= 2020
	
	replace s_`v' = "" if missing(q_`v') & !missing(`v') & year >= 2020
	replace q_`v' = .  if missing(s_`v') & !missing(`v') & year >= 2020
}
// -------------------------------------------------------------------------- //
// --- 3. Transform share values to monetary -------------------------------- //
// -------------------------------------------------------------------------- //
merge 1:1 iso year using "$work_data/exchange-rates.dta",  nogen keep(master matched) keepusing(exrate_usd)
merge 1:1 iso year using "$work_data/price-index.dta",     nogen keep(master matched) keepusing(index)
merge 1:1 iso year using "$work_data/retropolate-gdp.dta", nogen                      keepusing(gdp)
keep if corecountry == 1

foreach var in gdp {
	gen `var'_idx = `var'*index
	replace `var' = `var'_idx/exrate_usd
}

foreach var in nwgxa nwgxd fdixa fdixd ptfxa ptfxd pinrx pinpx fdirx ptfrx fdipx ptfpx nnfin pinnx fdinx ptfnx ptfxa_eq ptfxa_deb ptfxa_res ptfxa_fin ptfxd_eq ptfxd_deb ptfxd_fin ptfrx_eq ptfrx_deb ptfrx_res ptfpx_eq ptfpx_deb {
	gen q_`var'_gdp = q_`var'
	gen s_`var'_gdp = s_`var'
	gen   `var'_gdp = `var'
	replace   `var' = `var'*gdp
}

encode iso, gen(i)
xtset i year 
foreach var in fdirx fdipx ptfrx ptfpx pinrx pinpx ptfrx_eq ptfrx_deb ptfrx_res ptfpx_eq ptfpx_deb {
	gen   orig`var' = `var'
	gen origs_`var' = s_`var'
	gen origq_`var' = q_`var'
	
	replace   `var' = f.`var'
	replace q_`var' = f.q_`var'
	by i (year): replace s_`var' = s_`var'[_n+1]	
}
drop i 

// -------------------------------------------------------------------------- //
// --- 4. Adjust monetary values -------------------------------------------- //
// -------------------------------------------------------------------------- //

// Calcualte rates of return
gen   rf_a = fdirx/fdixa
gen   rf_d = fdipx/fdixd
gen   rp_a = ptfrx/ptfxa
gen   rp_d = ptfpx/ptfxd
gen s_rf_a = "fdirx/fdixa" if !missing(rf_a)
gen s_rf_d = "fdipx/fdixd" if !missing(rf_d)
gen s_rp_a = "ptfrx/ptfxa" if !missing(rp_a)
gen s_rp_d = "ptfpx/ptfxd" if !missing(rp_d)

gen    rpeq_a = ptfrx_eq /ptfxa_eq
gen   rpdeb_a = ptfrx_deb/ptfxa_deb
gen   rpres_a = ptfrx_res/ptfxa_res
gen  s_rpeq_a = "ptfrx-eq/ptfxa-eq"   if !missing(rpeq_a)
gen s_rpdeb_a = "ptfrx-deb/ptfxa-deb" if !missing(rpdeb_a)
gen s_rpres_a = "ptfrx-res/ptfxa-res" if !missing(rpres_a)

gen    rpeq_d = ptfpx_eq /ptfxd_eq
gen   rpdeb_d = ptfpx_deb/ptfxd_deb
gen  s_rpeq_d = "ptfpx-eq /ptfxd-eq"  if !missing(rpeq_d)
gen s_rpdeb_d = "ptfpx-deb/ptfxd-deb" if !missing(rpdeb_d)

gen   r_a = pinrx/nwgxa
gen   r_d = pinpx/nwgxd
gen s_r_a = "pinrx/nwgxa"
gen s_r_d = "pinpx/nwgxd"


replace  s_rf_a = "assumed" if missing(rf_a) & (abs(fdirx) >= 0 & !missing(fdirx) & abs(fdixa) >= 0 & !missing(fdixa))
replace  s_rf_d = "assumed" if missing(rf_d) & (abs(fdipx) >= 0 & !missing(fdipx) & abs(fdixd) >= 0 & !missing(fdixd))
replace  s_rp_a = "assumed" if missing(rp_a) & (abs(ptfrx) >= 0 & !missing(ptfrx) & abs(ptfxa) >= 0 & !missing(ptfxa))
replace  s_rp_d = "assumed" if missing(rp_d) & (abs(ptfpx) >= 0 & !missing(ptfpx) & abs(ptfxd) >= 0 & !missing(ptfxd))
replace    rf_a = 0 if missing(rf_a) & (abs(fdirx) >= 0 & !missing(fdirx) & abs(fdixa) >= 0 & !missing(fdixa))
replace    rf_d = 0 if missing(rf_d) & (abs(fdipx) >= 0 & !missing(fdipx) & abs(fdixd) >= 0 & !missing(fdixd))
replace    rp_a = 0 if missing(rp_a) & (abs(ptfrx) >= 0 & !missing(ptfrx) & abs(ptfxa) >= 0 & !missing(ptfxa))
replace    rp_d = 0 if missing(rp_d) & (abs(ptfpx) >= 0 & !missing(ptfpx) & abs(ptfxd) >= 0 & !missing(ptfxd))

replace s_rpeq_a  = "assumed" if missing(rpeq_a)  & (abs(ptfrx_eq)  >= 0 & !missing(ptfrx_eq)  & abs(ptfxa_eq)  >= 0 & !missing(ptfxa_eq))
replace s_rpdeb_a = "assumed" if missing(rpdeb_a) & (abs(ptfrx_deb) >= 0 & !missing(ptfrx_deb) & abs(ptfxa_deb) >= 0 & !missing(ptfxa_deb))
replace s_rpres_a = "assumed" if missing(rpres_a) & (abs(ptfrx_res) >= 0 & !missing(ptfrx_res) & abs(ptfxa_res) >= 0 & !missing(ptfxa_res))
replace s_rpeq_d  = "assumed" if missing(rpeq_d)  & (abs(ptfpx_eq)  >= 0 & !missing(ptfpx_eq)  & abs(ptfxd_eq)  >= 0 & !missing(ptfxd_eq))
replace s_rpdeb_d = "assumed" if missing(rpdeb_d) & (abs(ptfpx_deb) >= 0 & !missing(ptfpx_deb) & abs(ptfxd_deb) >= 0 & !missing(ptfxd_deb))
replace   rpeq_a  = 0 if missing(rpeq_a)  & (abs(ptfrx_eq)  >= 0 & !missing(ptfrx_eq)  & abs(ptfxa_eq)  >= 0 & !missing(ptfxa_eq))
replace   rpdeb_a = 0 if missing(rpdeb_a) & (abs(ptfrx_deb) >= 0 & !missing(ptfrx_deb) & abs(ptfxa_deb) >= 0 & !missing(ptfxa_deb))
replace   rpres_a = 0 if missing(rpres_a) & (abs(ptfrx_res) >= 0 & !missing(ptfrx_res) & abs(ptfxa_res) >= 0 & !missing(ptfxa_res))
replace   rpeq_d  = 0 if missing(rpeq_d)  & (abs(ptfpx_eq)  >= 0 & !missing(ptfpx_eq)  & abs(ptfxd_eq)  >= 0 & !missing(ptfxd_eq))
replace   rpdeb_d = 0 if missing(rpdeb_d) & (abs(ptfpx_deb) >= 0 & !missing(ptfpx_deb) & abs(ptfxd_deb) >= 0 & !missing(ptfxd_deb))

foreach var in rp_d rpeq_d rpdeb_d { 
	replace s_`var' ="" if iso == "NC" & year == 2001
	replace   `var' =. if iso == "NC" & year == 2001
}

gen s_rf_a2 = s_rf_a if flagfdirx == 0
gen s_rf_d2 = s_rf_d if flagfdipx == 0
gen s_rp_a2 = s_rp_a if flagptfrx == 0
gen s_rp_d2 = s_rp_d if flagptfpx == 0
gen   rf_a2 = rf_a if flagfdirx == 0
gen   rf_d2 = rf_d if flagfdipx == 0
gen   rp_a2 = rp_a if flagptfrx == 0
gen   rp_d2 = rp_d if flagptfpx == 0

gen s_rpeq_a2  = s_rpeq_a  if flagptfrx_eq  == 0
gen s_rpdeb_a2 = s_rpdeb_a if flagptfrx_deb == 0
gen s_rpres_a2 = s_rpres_a if flagptfrx_res == 0
gen s_rpeq_d2  = s_rpeq_d  if flagptfpx_eq  == 0
gen s_rpdeb_d2 = s_rpdeb_d if flagptfpx_deb == 0
gen   rpeq_a2  = rpeq_a    if flagptfrx_eq  == 0
gen   rpdeb_a2 = rpdeb_a   if flagptfrx_deb == 0
gen   rpres_a2 = rpres_a   if flagptfrx_res == 0
gen   rpeq_d2  = rpeq_d    if flagptfpx_eq  == 0
gen   rpdeb_d2 = rpdeb_d   if flagptfpx_deb == 0

order flag*, last

foreach level in undet un {
	kountry iso, from(iso2c) geo(`level')

	replace GEO = "Western Asia" 	if iso == "AE" & "`level'" == "undet"
	replace GEO = "Caribbean" 		if iso == "CW" & "`level'" == "undet"
	replace GEO = "Caribbean"		if iso == "SX" & "`level'" == "undet"
	replace GEO = "Caribbean" 		if iso == "BQ" & "`level'" == "undet"
	replace GEO = "Southern Europe" if iso == "KS" & "`level'" == "undet"
	replace GEO = "Southern Europe" if iso == "ME" & "`level'" == "undet"
	replace GEO = "Eastern Asia" 	if iso == "TW" & "`level'" == "undet"
	replace GEO = "Northern Europe" if iso == "GG" & "`level'" == "undet"
	replace GEO = "Northern Europe" if iso == "JE" & "`level'" == "undet"
	replace GEO = "Northern Europe" if iso == "IM" & "`level'" == "undet"

	replace GEO = "Asia"     if inlist(iso, "AE", "TW")                   & "`level'" == "un"
	replace GEO = "Americas" if inlist(iso, "CW", "SX", "BQ")             & "`level'" == "un"
	replace GEO = "Europe"   if inlist(iso, "KS", "ME", "GG", "JE", "IM") & "`level'" == "un"
	ren GEO geo`level'
	drop NAMES_STD 
}
gen soviet = 1 if inlist(iso, "AZ", "AM", "BY", "KG", "KZ", "GE") ///
				| inlist(iso, "TJ", "MD", "TM", "UA", "UZ") ///
				| inlist(iso, "EE", "LT", "LV", "RU", "SU")

gen yugosl = 1 if inlist(iso, "BA", "HR", "MK", "RS") ///
				| inlist(iso, "KS", "ME", "SI", "YU")

gen other = 1 if inlist(iso, "ER", "EH", "CS", "CZ", "SK", "SD", "SS", "TL") ///
			   | inlist(iso, "ID", "SX", "CW", "AN", "YE", "ZW", "IQ", "TW")

// some countries will only use IMF
foreach var in rf_a rf_d rp_a rp_d rpeq_a rpdeb_a rpres_a rpeq_d rpdeb_d { 
	replace s_`var' = s_`var'2 if inlist(iso, "EG", "IS", "NA", "GR", "KH", "BW", "PT", "MZ") /// 
							| inlist(iso, "DJ", "CZ", "SK", "TR", "GH", "", "", "")		 ///
							| soviet == 1 | yugosl == 1
	replace `var' = `var'2 if inlist(iso, "EG", "IS", "NA", "GR", "KH", "BW", "PT", "MZ") /// 
							| inlist(iso, "DJ", "CZ", "SK", "TR", "GH", "", "", "")		 ///
							| soviet == 1 | yugosl == 1
}
            
replace s_rf_a = "assumed" if missing(rf_a) & (abs(fdirx) == 0 & abs(fdixa) == 0)
replace s_rf_d = "assumed" if missing(rf_d) & (abs(fdipx) == 0 & abs(fdixd) == 0)
replace s_rp_a = "assumed" if missing(rp_a) & (abs(ptfrx) == 0 & abs(ptfxa) == 0)
replace s_rp_d = "assumed" if missing(rp_d) & (abs(ptfpx) == 0 & abs(ptfxd) == 0)
replace   rf_a = 0 if missing(rf_a) & (abs(fdirx) == 0 & abs(fdixa) == 0)
replace   rf_d = 0 if missing(rf_d) & (abs(fdipx) == 0 & abs(fdixd) == 0)
replace   rp_a = 0 if missing(rp_a) & (abs(ptfrx) == 0 & abs(ptfxa) == 0)
replace   rp_d = 0 if missing(rp_d) & (abs(ptfpx) == 0 & abs(ptfxd) == 0)

replace s_rpeq_a  = "assumed" if missing(rpeq_a)  & (abs(ptfrx_eq)  == 0 & abs(ptfxa_eq)  == 0)
replace s_rpdeb_a = "assumed" if missing(rpdeb_a) & (abs(ptfrx_deb) == 0 & abs(ptfxa_deb) == 0)
replace s_rpres_a = "assumed" if missing(rpres_a) & (abs(ptfrx_res) == 0 & abs(ptfxa_res) == 0)
replace s_rpeq_d  = "assumed" if missing(rpeq_d)  & (abs(ptfpx_eq)  == 0 & abs(ptfxd_eq)  == 0)
replace s_rpdeb_d = "assumed" if missing(rpdeb_d) & (abs(ptfpx_deb) == 0 & abs(ptfxd_deb) == 0)
replace   rpeq_a  = 0 if missing(rpeq_a)  & (abs(ptfrx_eq)  == 0 & abs(ptfxa_eq)  == 0)
replace   rpdeb_a = 0 if missing(rpdeb_a) & (abs(ptfrx_deb) == 0 & abs(ptfxa_deb) == 0)
replace   rpres_a = 0 if missing(rpres_a) & (abs(ptfrx_res) == 0 & abs(ptfxa_res) == 0)
replace   rpeq_d  = 0 if missing(rpeq_d)  & (abs(ptfpx_eq)  == 0 & abs(ptfxd_eq)  == 0)
replace   rpdeb_d = 0 if missing(rpdeb_d) & (abs(ptfpx_deb) == 0 & abs(ptfxd_deb) == 0)

// Soviet, Yugoslavian and pre-communist China are assumed to earn/pay 1% on their assets and liabilities
foreach v in rp_a rp_d rf_a rf_d rpeq_a rpdeb_a rpres_a rpeq_d rpdeb_d {
	replace s_`v' = "assumed" if (soviet == 1 & year <= 1991) | (yugosl == 1 & year <= 1991) | (iso == "CN" & year <= 1981) | (inlist(iso, "SK", "CZ") & year <= 1992)
	replace   `v' = 0.01      if (soviet == 1 & year <= 1991) | (yugosl == 1 & year <= 1991) | (iso == "CN" & year <= 1981) | (inlist(iso, "SK", "CZ") & year <= 1992)
}
foreach v in rp_a rp_d rf_a rf_d rpeq_a rpdeb_a rpres_a rpeq_d rpdeb_d {
	replace s_`v' = "assumed" if iso == "AM" & year == 1992
	replace s_`v' = "assumed" if iso == "AZ" & year <= 1994
	replace s_`v' = "assumed" if iso == "MD" & year <= 1993
	replace s_`v' = "assumed" if iso == "RU" & year <= 1993
	replace s_`v' = "assumed" if iso == "UA" & year <= 1995
	replace   `v' = 0.01 if iso == "AM" & year == 1992
	replace   `v' = 0.01 if iso == "AZ" & year <= 1994
	replace   `v' = 0.01 if iso == "MD" & year <= 1993
	replace   `v' = 0.01 if iso == "RU" & year <= 1993
	replace   `v' = 0.01 if iso == "UA" & year <= 1995
}

// table for appendix 
/*
	preserve
	// gen rf_a_flag = flagfdirx 
	// gen rf_d_flag = flagfdipx 
	// gen rp_a_flag = flagptfrx
	// gen rp_d_flag = flagptfpx 

	// foreach var in rf_a rf_d rp_a rp_d {
	// 	bys iso : egen minyearIMF`var' = min(year) if !missing(`var') & `var'_flag == 0
	// 	bys iso : egen maxyearIMF`var' = max(year) if !missing(`var') & `var'_flag == 0
	// 	bys iso : egen minyearUN`var' = min(year) if !missing(`var') & `var'_flag == 1
	// 	bys iso : egen maxyearUN`var' = max(year) if !missing(`var') & `var'_flag == 1
	// }

	foreach v in pinrx pinpx {
	// AE gets SA rates of return later 
	replace orig`v' = . if iso == "AE"
		replace flag`v' =. if mi(orig`v')
	}

	gen r_a_flag = flagpinrx
	gen r_d_flag = flagpinpx 
	gen r_a_imfflag = flagimfpinrx
	gen r_d_imfflag = flagimfpinpx 
	 

	foreach var in pinrx pinpx {
		bys iso : egen minyearIMF`var' = min(year) if !missing(orig`var') & flagimf`var' == 0
		bys iso : egen maxyearIMF`var' = max(year) if !missing(orig`var') & flagimf`var' == 0
		bys iso : egen minyearUN`var' = min(year) if !missing(orig`var') & flagimf`var' == 1 & flag`var' == 0 & orig`var' != 0 
		bys iso : egen maxyearUN`var' = max(year) if !missing(orig`var') & flagimf`var' == 1 & flag`var' == 0 & orig`var' != 0
	}

	foreach var in nwgxa nwgxd {
		bys iso : egen minyear`var' = min(year) if !missing(`var') & flag`var' == 0
		bys iso : egen maxyear`var' = max(year) if !missing(`var') & flag`var' == 0
	}
	keep iso countryname year max* min*
	ds iso countryname year, not 
	local varlist = r(varlist)
	collapse (mean) `varlist', by(iso countryname)

	gl corevar = `""pinrx" "pinpx""'

	foreach var of global corevar {
			tostring minyearIMF`var', replace force
			tostring maxyearIMF`var', replace force
	gen periodIMF_`var' = minyearIMF`var' + "-" + maxyearIMF`var'
	replace periodIMF_`var' = minyearIMF`var' if minyearIMF`var' == maxyearIMF`var'
			tostring minyearUN`var', replace force
			tostring maxyearUN`var', replace force
	gen periodUN_`var' = minyearUN`var' + "-" + maxyearUN`var'
	replace periodUN_`var' = minyearUN`var' if minyearUN`var' == maxyearUN`var'
	}

	foreach var in  nwgxa nwgxd {
			tostring minyear`var', replace force
			tostring maxyear`var', replace force
	gen period_`var' = minyear`var' + "-" + maxyear`var'
	replace period_`var' ="." if period_`var' == ".-."
	}

	drop min* max*
restore
*/

foreach v in fdirx fdipx ptfrx ptfpx ptfrx_eq ptfrx_deb ptfrx_res ptfpx_eq ptfpx_deb {
	bys geoundet year : egen auxundet_`v' = mean(`v')         if flag`v' == 0 & TH == 0
	bys geoundet year : egen  avundet_`v' = mode(auxundet_`v')
 }
foreach v in fdirx fdipx ptfrx ptfpx ptfrx_eq ptfrx_deb ptfrx_res ptfpx_eq ptfpx_deb {
	bys year : egen auxTH_`v' = mean(`v')       if flag`v' == 0 & TH == 1
	bys year :  egen avTH_`v' = mode(auxTH_`v')
}
drop aux*

foreach v in fdirx fdipx ptfrx ptfpx ptfrx_eq ptfrx_deb ptfrx_res ptfpx_eq ptfpx_deb {
	bys iso : egen  tag`v' = mean(flag`v')
	bys iso : egen miss`v' = mean(`v')
}
so iso year
// -------------------------------------------------------------------------- //
// --- 5. Predicting rates of return ---------------------------------------- //
// -------------------------------------------------------------------------- //

gen flag_rf_a = 1 if tagfdirx == 1
gen flag_rf_d = 1 if tagfdipx == 1 
gen flag_pt_a = 1 if tagptfrx == 1 
gen flag_pt_d = 1 if tagptfpx == 1

gen flag_pt_eq_a  = 1 if tagptfrx_eq  == 1 
gen flag_pt_deb_a = 1 if tagptfrx_deb == 1 
gen flag_pt_res_a = 1 if tagptfrx_res == 1 
gen flag_pt_eq_d  = 1 if tagptfpx_eq  == 1 
gen flag_pt_deb_d = 1 if tagptfpx_deb == 1 

foreach v in flag_rf_a flag_rf_d flag_pt_a flag_pt_d flag_pt_eq_a flag_pt_deb_a flag_pt_res_a flag_pt_eq_d flag_pt_deb_d {
	replace `v' = 0 if missing(`v')
}

encode iso, gen(i)
xtset i year
gen   inflation = (index - l.index)/l.index
order inflation, after(index)

encode geoundet, gen(reg) 
encode geoun,    gen(regun)

egen regyear = group(reg year)


// -------- 5.1  Non Tax Havens ------------------------------------------------

*portfolio received
// first winsorize
winsor2 rp_a if TH == 0, cut(20 80) by(regyear)

reghdfe rp_a_w ptfxa_gdp exrate_usd inflation if TH == 0, ab(i reg#year, savefe)
predict rp_a_predict if TH == 0
bys iso : egen cfe = mode(__hdfe1__)
bys geoundet year : egen cry = mode(__hdfe2__)
replace rp_a_predict = rp_a_predict + cfe + cry
replace s_rp_a = "regression[rportafolio-a]FE" + geoundet if missing(rp_a) & rp_a_predict > 0
replace   rp_a = rp_a_predict               if missing(rp_a) & rp_a_predict > 0
drop __hdfe1__ __hdfe2__ cfe cry rp_a_predict rp_a_w
replace   rp_a = .  if iso == "RS" & year == 1993

// decomposing 
	// equity
	// more volatile, we use a different winsor
	winsor2 rpeq_a if TH == 0, cut(5 80) by(regyear)

	reghdfe rpeq_a_w ptfxa_eq_gdp exrate_usd inflation if TH == 0, ab(i reg#year, savefe)
	predict rp_a_predict if TH == 0
	bys iso : egen cfe = mode(__hdfe1__)
	bys geoundet year : egen cry = mode(__hdfe2__)
	replace rp_a_predict = rp_a_predict + cfe + cry
	replace s_rpeq_a = "regression[rportafolioequity-a]FE" + geoundet if missing(rpeq_a) & rp_a_predict > 0
	replace   rpeq_a = rp_a_predict               if missing(rpeq_a) & rp_a_predict > 0
	drop __hdfe1__ __hdfe2__ cfe cry rp_a_predict rpeq_a_w
	replace rpeq_a =. if iso == "RS" & year == 1993

	// debt 
	winsor2 rpdeb_a if TH == 0, cut(20 80) by(regyear)

	reghdfe rpdeb_a_w ptfxa_deb_gdp exrate_usd inflation if TH == 0, ab(i reg#year, savefe)
	predict rp_a_predict if TH == 0
	bys iso : egen cfe = mode(__hdfe1__)
	bys geoundet year : egen cry = mode(__hdfe2__)
	replace rp_a_predict = rp_a_predict + cfe + cry
	replace s_rpdeb_a = "regression[rportafoliodebt-a]FE"+geoundet if missing(rpdeb_a) & rp_a_predict > 0
	replace   rpdeb_a = rp_a_predict             if missing(rpdeb_a) & rp_a_predict > 0
	drop __hdfe1__ __hdfe2__ cfe cry rp_a_predict rpdeb_a_w
	replace rpdeb_a =. if iso == "RS" & year == 1993

	// reserves
	winsor2 rpres_a if TH == 0, cut(20 80) by(regyear)

	reghdfe rpres_a_w ptfxa_res_gdp exrate_usd inflation if TH == 0, ab(i reg#year, savefe)
	predict rp_a_predict if TH == 0
	bys iso : egen cfe = mode(__hdfe1__)
	bys geoundet year : egen cry = mode(__hdfe2__)
	replace rp_a_predict = rp_a_predict + cfe + cry
	replace s_rpres_a = "regression[rportafolioreserves-a]FE"+geoundet if missing(rpres_a) & rp_a_predict > 0
	replace   rpres_a = rp_a_predict             if missing(rpres_a) & rp_a_predict > 0
	drop __hdfe1__ __hdfe2__ cfe cry rp_a_predict rpres_a_w
	replace rpres_a =. if iso == "RS" & year == 1993

*portfolio paid
// first winsorize
winsor2 rp_d if TH == 0, cut(20 80) by(regyear)

reghdfe rp_d_w ptfxd_gdp exrate_usd inflation if TH == 0, ab(i reg#year, savefe)
predict rp_d_predict if TH == 0
bys iso : egen cfe = mode(__hdfe1__)
bys geoundet year : egen cry = mode(__hdfe2__)
replace rp_d_predict = rp_d_predict + cfe + cry
replace s_rp_d = "regression[rportafolio-d]FE"+geoundet if missing(rp_d) & rp_d_predict > 0
replace   rp_d = rp_d_predict             if missing(rp_d) & rp_d_predict > 0
drop __hdfe1__ __hdfe2__ cfe cry rp_d_predict rp_d_w
replace rp_d =. if iso == "RS" & year == 1993

// decomposing 
	// equity
	// more volatile, we use a different winsor
	winsor2 rpeq_d if TH == 0, cut(20 80) by(regyear)
	
	reghdfe rpeq_d_w ptfxd_eq_gdp exrate_usd inflation if TH == 0, ab(i reg#year, savefe)
	predict rp_d_predict if TH == 0
	bys iso : egen cfe = mode(__hdfe1__)
	bys geoundet year : egen cry = mode(__hdfe2__)
	replace rp_d_predict = rp_d_predict + cfe + cry
	replace s_rpeq_d = "regression[rportafolioequity-d]FE"+geoundet if missing(rpeq_d) & rp_d_predict > 0
	replace   rpeq_d = rp_d_predict             if missing(rpeq_d) & rp_d_predict > 0
	drop __hdfe1__ __hdfe2__ cfe cry rp_d_predict rpeq_d_w
	replace rpeq_d =. if iso == "RS" & year == 1993

	// debt
	winsor2 rpdeb_d if TH == 0, cut(20 80) by(regyear)
	
	reghdfe rpdeb_d_w ptfxd_deb_gdp exrate_usd inflation if TH == 0, ab(i reg#year, savefe)
	predict rp_d_predict if TH == 0
	bys iso : egen cfe = mode(__hdfe1__)
	bys geoundet year : egen cry = mode(__hdfe2__)
	replace rp_d_predict = rp_d_predict + cfe + cry
	replace s_rpdeb_d = "regression[rportafoliodebt-d]FE"+geoundet if missing(rpdeb_d) & rp_d_predict > 0
	replace   rpdeb_d = rp_d_predict             if missing(rpdeb_d) & rp_d_predict > 0
	drop __hdfe1__ __hdfe2__ cfe cry rp_d_predict rpdeb_d_w
	replace rpdeb_d =. if iso == "RS" & year == 1993
	
foreach v in rpdeb_d rpeq_d rp_d rpres_a rpdeb_a rpeq_a rp_a {
	replace s_`v' = "" if iso == "RS" & year == 1993
}

*FDI received
// more volatile, we use a different winsor
// first winsorize
winsor2 rf_a if TH == 0, cut(5 80) by(regyear)

reghdfe rf_a_w fdixa_gdp exrate_usd inflation if TH == 0, ab(i reg#year, savefe)
predict rf_a_predict if TH == 0
bys iso : egen cfe = mode(__hdfe1__)
bys geoundet year : egen cry = mode(__hdfe2__)
replace rf_a_predict = rf_a_predict + cfe + cry
replace s_rf_a = "regression[rFDI-a]FE"+ geoun if missing(rf_a) & rf_a_predict > 0 & !inlist(iso, "BN", "KH", "LA", "TL", "VN", "SM", "NA", "MZ", "PT") & geoun != "Oceania"
replace   rf_a = rf_a_predict           if missing(rf_a) & rf_a_predict > 0 & !inlist(iso, "BN", "KH", "LA", "TL", "VN", "SM", "NA", "MZ", "PT") & geoun != "Oceania"
drop __hdfe1__ __hdfe2__ cfe cry rf_a_predict

reghdfe rf_a_w fdixa_gdp exrate_usd inflation if TH == 0, ab(i regun#year, savefe)
predict rf_a_predict2 if TH == 0
bys iso : egen cfe = mode(__hdfe1__)
bys geoundet year : egen cry = mode(__hdfe2__)
replace rf_a_predict2 = rf_a_predict2 + cfe + cry
replace s_rf_a = "regression[rFDI-a]FE"+ geoun if missing(rf_a) & rf_a_predict2 > 0 & inlist(iso, "BN", "KH", "LA", "TL", "VN", "SM") & geoun == "Oceania"
replace   rf_a = rf_a_predict2          if missing(rf_a) & rf_a_predict2 > 0 & inlist(iso, "BN", "KH", "LA", "TL", "VN", "SM") & geoun == "Oceania"
drop __hdfe1__ __hdfe2__ cfe cry rf_a_predict2 rf_a_w

*FDI paid
// first winsorize
winsor2 rf_d if TH == 0, cut(5 80) by(regyear)

reghdfe rf_d_w fdixd_gdp exrate_usd inflation if TH == 0, ab(i reg#year, savefe)
predict rf_d_predict if TH == 0
bys iso : egen cfe = mode(__hdfe1__)
bys geoundet year : egen cry = mode(__hdfe2__)
replace rf_d_predict = rf_d_predict + cfe + cry
replace s_rf_d = "regression[rFDI-d]FE"+geoundet if missing(rf_d) & rf_d_predict > 0 & !inlist(iso, "BN", "KH", "LA", "TL", "VN", "SM", "NA", "MZ", "PT") & geoun != "Oceania"
replace   rf_d = rf_d_predict             if missing(rf_d) & rf_d_predict > 0 & !inlist(iso, "BN", "KH", "LA", "TL", "VN", "SM", "NA", "MZ", "PT") & geoun != "Oceania"
drop __hdfe1__ __hdfe2__ cfe cry rf_d_predict 

reghdfe rf_d_w fdixd_gdp exrate_usd inflation if TH == 0, ab(i regun#year, savefe)
predict rf_d_predict2 if TH == 0
bys iso : egen cfe = mode(__hdfe1__)
bys geoundet year : egen cry = mode(__hdfe2__)
replace rf_d_predict2 = rf_d_predict2 + cfe + cry
replace s_rf_d = "regression[rFDI-d]FE"+ geoun if missing(rf_d) & rf_d_predict2 > 0 & inlist(iso, "BN", "KH", "LA", "TL", "VN", "SM") & geoun == "Oceania"
replace   rf_d = rf_d_predict2          if missing(rf_d) & rf_d_predict2 > 0 & inlist(iso, "BN", "KH", "LA", "TL", "VN", "SM") & geoun == "Oceania"
drop __hdfe1__ __hdfe2__ cfe cry rf_d_predict2 rf_d_w

replace s_rf_d ="" if iso == "KW" & missing(rf_d2)
replace   rf_d =.  if iso == "KW" & missing(rf_d2)
replace s_rf_a ="" if iso == "KW" & missing(rf_a2)
replace   rf_a =.  if iso == "KW" & missing(rf_a2)

foreach v in rp_a rp_d rf_a rf_d rpeq_a rpdeb_a rpres_a rpeq_d rpdeb_d {
	sort iso year
	by iso : carryforward `v' if TH == 0, replace
	gsort iso -year
	by iso : carryforward `v' if TH == 0, replace
	
	replace s_`v' = "carryfor" if TH == 0 & !missing(`v') & missing(s_`v')
}

replace s_rf_a ="" if iso == "AE" & year >= 1984
replace   rf_a =.  if iso == "AE" & year >= 1984
replace s_rf_a ="" if iso == "AT" & year < 2005
replace   rf_a =.  if iso == "AT" & year < 2005

// AE will take the same rates than SA
foreach v in rp_a rp_d rf_a rf_d rpeq_a rpdeb_a rpres_a rpeq_d rpdeb_d {
	local v_dash = subinstr("`v'", "_", "-", .)
	gen aux`v' =      `v'    if iso == "SA"
	bys year : egen SA`v' = mode(aux`v')
	replace s_`v' = "`v_dash'(SA)"  if iso == "AE" & !missing(aux`v')
	replace `v'   = SA`v'    if iso == "AE"
	drop aux`v' SA`v'
}
foreach v in fdipx fdirx pinpx pinrx ptfpx ptfpx_deb ptfpx_eq ptfrx ptfrx_deb ptfrx_eq ptfrx_res {
	replace flag`v' = 1 if iso == "AE"
}


// -------- 5.2  Tax Havens ----------------------------------------------------

*portfolio received
// first winsorize
winsor2 rp_a if TH == 1, cut(20 80) by(year)

reghdfe rp_a_w ptfxa_gdp exrate_usd inflation if TH == 1, ab(i year, savefe)
predict rp_a_predict if TH == 1
bys iso : egen cfe = mode(__hdfe1__)
bys year : egen cy = mode(__hdfe2__)
replace rp_a_predict = rp_a_predict + cfe + cy
replace s_rp_a = "regressionTH[rportafolio-a]FE" if missing(rp_a) & rp_a_predict > 0
replace rp_a = rp_a_predict     if missing(rp_a) & rp_a_predict > 0
drop __hdfe1__ __hdfe2__ cfe cy rp_a_predict rp_a_w

// decomposing 
	// equity
	// more volatile, we use a different winsor
	winsor2 rpeq_a if TH == 1, cut(5 75) by(regyear)

	reghdfe rpeq_a_w ptfxa_eq_gdp exrate_usd inflation if TH == 1, ab(i reg#year, savefe)
	predict rp_a_predict if TH == 1
	bys iso : egen cfe = mode(__hdfe1__)
	bys geoundet year : egen cry = mode(__hdfe2__)
	replace rp_a_predict = rp_a_predict + cfe + cry
	replace s_rpeq_a = "regressionTH[rportafolioequity-a]FE"+geoundet if missing(rpeq_a) & rp_a_predict > 0
	replace   rpeq_a = rp_a_predict             if missing(rpeq_a) & rp_a_predict > 0
	drop __hdfe1__ __hdfe2__ cfe cry rp_a_predict rpeq_a_w
	replace rpeq_a = . if iso == "KY" & missing(ptfrx_eq)
	// debt
	winsor2 rpdeb_a if TH == 1, cut(20 80) by(regyear)

	reghdfe rpdeb_a_w ptfxa_deb_gdp exrate_usd inflation if TH == 1, ab(i reg#year, savefe)
	predict rp_a_predict if TH == 1
	bys iso : egen cfe = mode(__hdfe1__)
	bys geoundet year : egen cry = mode(__hdfe2__)
	replace rp_a_predict = rp_a_predict + cfe + cry
	replace s_rpdeb_a = "regressionTH[rportafoliodebt-a]FE"+geoundet if missing(rpdeb_a) & rp_a_predict > 0
	replace   rpdeb_a = rp_a_predict             if missing(rpdeb_a) & rp_a_predict > 0
	drop __hdfe1__ __hdfe2__ cfe cry rp_a_predict rpdeb_a_w
	replace rpdeb_a = . if iso == "KY" & missing(ptfrx_deb)

	// reserves
	winsor2 rpres_a if TH == 1, cut(20 80) by(regyear)

	reghdfe rpres_a_w ptfxa_res_gdp exrate_usd inflation if TH == 1, ab(i reg#year, savefe)
	predict rp_a_predict if TH == 1
	bys iso : egen cfe = mode(__hdfe1__)
	bys geoundet year : egen cry = mode(__hdfe2__)
	replace rp_a_predict = rp_a_predict + cfe + cry
	replace s_rpres_a = "regressionTH[rpirtafolioreserves-a]FE"+geoundet if missing(rpres_a) & rp_a_predict > 0
	replace   rpres_a = rp_a_predict            if missing(rpres_a) & rp_a_predict > 0
	drop __hdfe1__ __hdfe2__ cfe cry rp_a_predict rpres_a_w
	replace rpres_a = . if iso == "KY" & missing(ptfrx_res)

*portfolio paid
// first winsorize
winsor2 rp_d if TH == 1, cut(20 80) by(year)

reghdfe rp_d_w ptfxd_gdp exrate_usd inflation if TH == 1, ab(i year, savefe)
predict rp_d_predict if TH == 1
bys iso : egen cfe = mode(__hdfe1__)
bys year : egen cy = mode(__hdfe2__)
replace rp_d_predict = rp_d_predict + cfe + cy
replace s_rp_d = "regressionTH[rportafolio-d]" if missing(rp_d) & rp_d_predict > 0
replace   rp_d = rp_d_predict   if missing(rp_d) & rp_d_predict > 0
drop __hdfe1__ __hdfe2__ cfe cy rp_d_predict rp_d_w

// decomposing 
	// equity
	// more volatile, we use a different winsor
	winsor2 rpeq_d if TH == 1, cut(5 75) by(regyear)
	
	reghdfe rpeq_d_w ptfxd_eq_gdp exrate_usd inflation if TH == 1, ab(i reg#year, savefe)
	predict rp_d_predict if TH == 1
	bys iso : egen cfe = mode(__hdfe1__)
	bys geoundet year : egen cry = mode(__hdfe2__)
	replace rp_d_predict = rp_d_predict + cfe + cry
	replace s_rpeq_d = "regressionTH[rportafolioequity-d]FE"+geoundet if missing(rpeq_d) & rp_d_predict > 0
	replace   rpeq_d = rp_d_predict             if missing(rpeq_d) & rp_d_predict > 0
	drop __hdfe1__ __hdfe2__ cfe cry rp_d_predict rpeq_d_w

	// debt
	winsor2 rpdeb_d if TH == 1, cut(20 80) by(regyear)
	
	reghdfe rpdeb_d_w ptfxd_deb_gdp exrate_usd inflation if TH == 1, ab(i reg#year, savefe)
	predict rp_d_predict if TH == 1
	bys iso : egen cfe = mode(__hdfe1__)
	bys geoundet year : egen cry = mode(__hdfe2__)
	replace rp_d_predict = rp_d_predict + cfe + cry
	replace s_rpdeb_d = "regressionTH[rportafoliodebt-d]FE"+geoundet if missing(rpdeb_d) & rp_d_predict > 0
	replace rpdeb_d = rp_d_predict             if missing(rpdeb_d) & rp_d_predict > 0
	drop __hdfe1__ __hdfe2__ cfe cry rp_d_predict rpdeb_d_w

*FDI received
// more volatile, we use a different winsor
// first winsorize
winsor2 rf_a if TH == 1, cut(5 75) by(year)

reghdfe rf_a_w fdixa_gdp exrate_usd inflation if TH == 1, ab(i year, savefe)
predict rf_a_predict if TH == 1
bys iso : egen cfe = mode(__hdfe1__)
bys year : egen cy = mode(__hdfe2__)
replace rf_a_predict = rf_a_predict + cfe + cy
replace s_rf_a = "regressionTH[rFDI-a]" if missing(rf_a) & rf_a_predict > 0
replace   rf_a = rf_a_predict   if missing(rf_a) & rf_a_predict > 0
drop __hdfe1__ __hdfe2__ cfe cy rf_a_predict rf_a_w

*FDI paid
// first winsorize
winsor2 rf_d if TH == 1, cut(5 75) by(year)

reghdfe rf_d_w fdixd_gdp exrate_usd inflation if TH == 1, ab(i year, savefe)
predict rf_d_predict if TH == 1
bys iso : egen cfe = mode(__hdfe1__)
bys year : egen cy = mode(__hdfe2__)
replace rf_d_predict = rf_d_predict + cfe + cy
replace s_rf_d = "regressionTH[rFDI-d]" if missing(rf_d) & rf_d_predict > 0 & inlist(iso, "AI", "VG", "MH", "MO", "TC")
replace   rf_d = rf_d_predict   if missing(rf_d) & rf_d_predict > 0 & inlist(iso, "AI", "VG", "MH", "MO", "TC")
drop __hdfe1__ __hdfe2__ cfe cy rf_d_predict rf_d_w

replace s_rf_d ="" if iso == "VG" & year <= 1977
replace s_rf_d ="" if iso == "VG" & year >= 2020
replace s_rf_d ="" if iso == "VC" & year <= 1982
replace s_rf_d ="" if iso == "AW" & year == 1987
replace   rf_d =.  if iso == "VG" & year <= 1977
replace   rf_d =.  if iso == "VG" & year >= 2020
replace   rf_d =.  if iso == "VC" & year <= 1982
replace   rf_d =.  if iso == "AW" & year == 1987

foreach v in rp_a rp_d rf_a rf_d rpeq_a rpdeb_a rpres_a rpeq_d rpdeb_d {
	sort iso year
	by iso : carryforward `v' if TH == 1, replace
	gsort iso -year
	by iso : carryforward `v' if TH == 1, replace
	
	replace s_`v' = "carryfor" if TH == 1 & !missing(`v') & missing(s_`v')
}
// replace rf_d = 0 if missing(rf_d) & TH == 1

// Completing with regional average for countries with missing values or zeros
*non-havens 
foreach v in rp_a rp_d rpdeb_a rpres_a rpdeb_d {
	local v_dash = subinstr("`v'", "_", "-", .)

	bys geoundet year : egen avg`v' = mean(`v') if TH == 0
	bys geoun year : egen  avgun`v' = mean(`v') if TH == 0
	
	replace s_`v' = "mean[`v_dash']reg"+geoundet if missing(`v') & TH == 0
	replace   `v' = avg`v'          if missing(`v') & TH == 0
	
	replace s_`v' = "mean[`v_dash']reg"+geoun if missing(`v') & TH == 0
	replace   `v' = avgun`v'     if missing(`v') & TH == 0
	
	replace s_`v' = subinstr(s_`v', "rp_", "rportfolio", .)
	replace s_`v' = subinstr(s_`v', "rpdeb_", "rportfoliodebt", .)
	replace s_`v' = subinstr(s_`v', "rpres_", "rportfolioreserves", .)
}

foreach v in rf_a rf_d rpeq_a rpeq_d {
	local v_dash = subinstr("`v'", "_", "-", .)

	winsor2 `v' if TH == 0, cut(20 80) by(year)
	bys geoundet year : egen avg`v'_w = mean(`v'_w) if TH == 0
	bys geoun year : egen  avgun`v'_w = mean(`v'_w) if TH == 0
	replace s_`v' = "mean[`v_dash']reg"+geoundet if missing(`v') & TH == 0
	replace   `v' = avg`v'_w        if missing(`v') & TH == 0
	replace s_`v' = "mean[`v_dash']reg"+geoun    if missing(`v') & TH == 0
	replace   `v' = avgun`v'_w      if missing(`v') & TH == 0
	
	replace s_`v' = subinstr(s_`v', "rf_", "rFDI", .)
	replace s_`v' = subinstr(s_`v', "rpeq_", "rportfolioequity", .)
}

drop avg* *_w 

*tax-havens 
foreach v in rp_a rp_d rf_a rf_d rpeq_a rpdeb_a rpres_a rpeq_d rpdeb_d {
	local v_dash = subinstr("`v'", "_", "-", .)

	winsor2 `v' if TH == 1, cut(20 80) by(year)
	bys year : egen avg`v'_w = mean(`v'_w) if TH == 1
	
	replace s_`v' = "mean[`v_dash']regTH" if missing(`v'_w) & TH == 1
	replace   `v' = avg`v'_w   if missing(`v'_w) & TH == 1
	
	replace s_`v' = subinstr(s_`v', "rp_", "rportfolio", .)
	replace s_`v' = subinstr(s_`v', "rpdeb_", "rportfoliodebt", .)
	replace s_`v' = subinstr(s_`v', "rpres_", "rportfolioreserves", .)
	replace s_`v' = subinstr(s_`v', "rf_", "rFDI", .)
}
drop avg* *_w
drop i
encode iso, gen(i)

// Old note: fixing Gibraltar. it's sudden jump in fdixd is making national income < 0
// we replace rate of return for KY, which is also Tax Haven

// Note: 23Jan2025, Following the masive jump of KY, I selected BS has a soomth increase
xtset i year
replace   fdixd = .          if iso == "GI" & year == 2020 
replace s_fdixd = "carryfor" if iso == "GI" & missing(fdixd) & year == 2020 
replace fdixd = l.fdixd      if iso == "GI" & missing(fdixd) & year == 2020 
replace rf_d = .             if iso == "GI" & inrange(year,2012,2015)
gen      aux = rf_d          if iso == "BS"
bys year : egen aux2 = mode(aux)
replace s_rf_d = "rFDI-d(BS)" if iso == "GI" & inrange(year,2012,2015) & mi(rf_d)
replace   rf_d = aux2       if iso == "GI" & inrange(year,2012,2015) & mi(rf_d)
drop aux* 

// fixing VG. it's sudden jump in fdixd is making national income < 0
// we replace rate of return for BH, which is also Tax Have
foreach v in rf_d {
	replace `v' =.     if iso == "VG" & year >= 1999
	gen aux = `v'      if iso == "KY"
	bys year : egen aux2 = mode(aux)
	replace s_`v' = "rFDI-d(KY)" if iso == "VG" & year >= 1999 & mi(`v')
	replace   `v' = aux2       if iso == "VG" & year >= 1999 & mi(`v')
	drop aux*
}

replace s_rf_d = ""  if iso == "MC" & year == 2014 
replace   rf_d = .   if iso == "MC" & year == 2014 
gsort iso -year 
carryforward rf_d               if iso == "MC" & year == 2014, replace
replace s_rf_d = "carryfor" if iso == "MC" & year == 2014 

// -------------------------------------------------------------------------- //
// ---  6.  completing missing assets --------------------------------------- //
// -------------------------------------------------------------------------- //

// Cuba and North Korea will have an average of svoiet countries for wealth 
foreach v in ptfxa_gdp ptfxd_gdp fdixa_gdp fdixd_gdp ptfxd_deb_gdp ptfxd_eq_gdp ptfxd_fin_gdp ptfxa_res_gdp ptfxa_deb_gdp ptfxa_eq_gdp ptfxa_fin_gdp {
	local v_dash = subinstr("`v'", "_", "-", .)

	bys year : egen  aux`v' = mean(`v') if TH == 0 & (soviet == 1 | yugosl == 1)
	bys year : egen  avg`v' = mode(aux`v')
	replace s_`v' = "`v_dash'(SUYU)" if iso == "CU" & !missing(avg`v')
	replace q_`v' = 1             if iso == "CU" & !missing(avg`v')
	replace   `v' = avg`v'        if iso == "CU"
	so iso year
	by iso : ipolate `v' year if iso == "CU", epolate generate(x`v')
	replace s_`v' = "ipol"    if missing(`v') &  !missing(x`v')
	replace q_`v' = 3         if missing(`v') &  !missing(x`v')
	replace   `v' = x`v'      if missing(`v')
}
drop aux* avg*

foreach v in ptfxa ptfxd fdixa fdixd ptfxd_deb ptfxd_eq ptfxd_fin ptfxa_res ptfxa_deb ptfxa_eq ptfxa_fin {
	replace s_`v' = s_`v'+s_`v'_gdp       if iso == "CU" & !missing(`v'_gdp)
	replace q_`v' = min(q_`v', q_`v'_gdp) if iso == "CU" & !missing(`v'_gdp)
	replace   `v' = `v'_gdp*gdp           if iso == "CU"
}


sort iso year 
carryforward fdixa fdixd ptfxa ptfxd ptfxd_deb ptfxd_eq ptfxd_fin ptfxa_res ptfxa_deb ptfxa_eq ptfxa_fin fdirx fdipx ptfrx ptfpx ptfxd_deb_gdp ptfxd_eq_gdp ptfxd_fin_gdp ptfxa_res_gdp ptfxa_deb_gdp ptfxa_eq_gdp ptfxa_fin_gdp if iso == "CU", replace
foreach v in fdixa fdixd ptfxa ptfxd ptfxd_deb ptfxd_eq ptfxd_fin ptfxa_res ptfxa_deb ptfxa_eq ptfxa_fin fdirx fdipx ptfrx ptfpx ptfxd_deb_gdp ptfxd_eq_gdp ptfxd_fin_gdp ptfxa_res_gdp ptfxa_deb_gdp ptfxa_eq_gdp ptfxa_fin_gdp {
	replace q_`v' = 1          if iso == "CU" & !missing(`v') & missing(q_`v')
	replace s_`v' = "carryfor" if iso == "CU" & !missing(`v') & missing(s_`v')
}

// Completing for the countries where we have income but not asset
replace q_fdixa = min(3, q_fdirx) if missing(fdixa) & !missing(fdirx)
replace q_fdixd = min(3, q_fdipx) if missing(fdixd) & !missing(fdipx)
replace q_ptfxa = min(3, q_ptfrx) if missing(ptfxa) & !missing(ptfrx)
replace q_ptfxd = min(3, q_ptfpx) if missing(ptfxd) & !missing(ptfpx)
replace s_fdixa = "fdirx_return"+s_rf_a if missing(fdixa) & !missing(fdirx)
replace s_fdixd = "fdipx_return"+s_rf_d if missing(fdixd) & !missing(fdipx)
replace s_ptfxa = "ptfrx_return"+s_rp_a if missing(ptfxa) & !missing(ptfrx)
replace s_ptfxd = "ptfpx_return"+s_rp_d if missing(ptfxd) & !missing(ptfpx)
replace   fdixa = fdirx/rf_a if missing(fdixa)
replace   fdixd = fdipx/rf_d if missing(fdixd) 
replace   ptfxa = ptfrx/rp_a if missing(ptfxa)
replace   ptfxd = ptfpx/rp_d if missing(ptfxd)

replace q_ptfxa_eq  = min(3, q_ptfrx_eq)  if missing(ptfxa_eq)  & !missing(ptfrx_eq)
replace q_ptfxa_deb = min(3, q_ptfrx_deb) if missing(ptfxa_deb) & !missing(ptfrx_deb)
replace q_ptfxa_res = min(3, q_ptfrx_res) if missing(ptfxa_res) & !missing(ptfrx_res)
replace q_ptfxd_eq  = min(3, q_ptfpx_eq)  if missing(ptfxd_eq)  & !missing(ptfpx_eq)
replace q_ptfxd_deb = min(3, q_ptfpx_deb) if missing(ptfxd_deb) & !missing(ptfpx_deb)
replace s_ptfxa_eq  = "ptfrx-eq_return" +s_rpeq_a  if missing(ptfxa_eq)  & !missing(ptfrx_eq) 
replace s_ptfxa_deb = "ptfrx-deb_return"+s_rpdeb_a if missing(ptfxa_deb) & !missing(ptfrx_deb)
replace s_ptfxa_res = "ptfrx-res_return"+s_rpres_a  if missing(ptfxa_res) & !missing(ptfrx_res)
replace s_ptfxd_eq  = "ptfpx-eq_return" +s_rpeq_d  if missing(ptfxd_eq)  & !missing(ptfpx_eq)
replace s_ptfxd_deb = "ptfpx-deb_return"+s_rpdeb_d if missing(ptfxd_deb) & !missing(ptfpx_deb)
replace   ptfxa_eq  = ptfrx_eq/rpeq_a   if missing(ptfxa_eq) 
replace   ptfxa_deb = ptfrx_deb/rpdeb_a if missing(ptfxa_deb)
replace   ptfxa_res = ptfrx_res/rpres_a if missing(ptfxa_res)
replace   ptfxd_eq  = ptfpx_eq/rpeq_d   if missing(ptfxd_eq)
replace   ptfxd_deb = ptfpx_deb/rpdeb_d if missing(ptfxd_deb)


// -------------------------------------------------------------------------- //
// ---- 7. completing missing income ---------------------------------------- //
// -------------------------------------------------------------------------- //
replace q_fdirx = min(3,q_fdixa) if !missing(fdixa) 
replace q_fdipx = min(3,q_fdixd) if !missing(fdixd)
replace q_ptfrx = min(3,q_ptfxa) if !missing(ptfxa) 
replace q_ptfpx = min(3,q_ptfxd) if !missing(ptfxd) 
replace s_fdirx = "fdixa_return"+s_rf_a if !missing(fdixa) 
replace s_fdipx = "fdixd_return"+s_rf_d if !missing(fdixd) 
replace s_ptfrx = "ptfxa_return"+s_rp_a if !missing(ptfxa) 
replace s_ptfpx = "ptfxd_return"+s_rp_d if !missing(ptfxd) 
replace   fdirx = fdixa * rf_a if !missing(fdixa)
replace   fdipx = fdixd * rf_d if !missing(fdixd) 
replace   ptfrx = ptfxa * rp_a if !missing(ptfxa)
replace   ptfpx = ptfxd * rp_d if !missing(ptfxd)

replace q_ptfrx_eq  = min(3, q_ptfxa_eq)  if !missing(ptfxa_eq) 
replace q_ptfrx_deb = min(3, q_ptfxa_deb) if !missing(ptfxa_deb) 
replace q_ptfrx_res = min(3, q_ptfxa_res) if !missing(ptfxa_res) 
replace q_ptfpx_eq  = min(3, q_ptfxd_eq)  if !missing(ptfxd_eq)  
replace q_ptfpx_deb = min(3, q_ptfxd_deb) if !missing(ptfxd_deb) 
replace s_ptfrx_eq  = "ptfxa-eq_return" + s_rpeq_a  if !missing(ptfxa_eq)  
replace s_ptfrx_deb = "ptfxa-deb_return"+ s_rpdeb_a if !missing(ptfxa_deb) 
replace s_ptfrx_res = "ptfxa-res_return"+ s_rpres_a if !missing(ptfxa_res) 
replace s_ptfpx_eq  = "ptfxd-eq_return" + s_rpeq_d  if !missing(ptfxd_eq)  
replace s_ptfpx_deb = "ptfxd-deb_return"+ s_rpdeb_d if !missing(ptfxd_deb)
replace   ptfrx_eq  = rpeq_a  * ptfxa_eq  if !missing(ptfxa_eq) 
replace   ptfrx_deb = rpdeb_a * ptfxa_deb if !missing(ptfxa_deb)
replace   ptfrx_res = rpres_a * ptfxa_res if !missing(ptfxa_res)
replace   ptfpx_eq  = rpeq_d  * ptfxd_eq  if !missing(ptfxd_eq)
replace   ptfpx_deb = rpdeb_d * ptfxd_deb if !missing(ptfxd_deb)

gsort iso -year 
carryforward fdixa fdirx if iso == "RO", replace
replace q_fdixa = 1              if iso == "RO" & !missing(fdixa) & missing(q_fdixa)
replace s_fdixa = "carryfor" if iso == "RO" & !missing(fdixa) & missing(      s_fdixa)
replace q_fdirx = 1              if iso == "RO" & !missing(fdixa) & missing(q_fdirx)
replace s_fdirx = "carryfor" if iso == "RO" & !missing(fdixa) & missing(      s_fdirx)

// Cuba and North Korea will have an average of soviet countries for wealth 
// 0.01 for return rates 
foreach v in rp_a rp_d rf_a rf_d rpeq_a rpdeb_a rpres_a rpeq_d rpdeb_d {
	replace s_`v'= "assumed" if iso == "CU"
	replace   `v'= .01       if iso == "CU"
}
replace q_fdirx = min(3, q_fdixa) if iso == "CU"
replace q_fdipx = min(3, q_fdixd) if iso == "CU" 
replace q_ptfrx = min(3, q_ptfxa) if iso == "CU"
replace q_ptfpx = min(3, q_ptfxd) if iso == "CU"
replace s_fdirx = "fdixa_return" + s_rf_a if iso == "CU"
replace s_fdipx = "fdixd_return" + s_rf_d if iso == "CU" 
replace s_ptfrx = "ptfxa_return" + s_rp_a if iso == "CU"
replace s_ptfpx = "ptfxd_return" + s_rp_d if iso == "CU"
replace   fdirx = fdixa*rf_a if iso == "CU"
replace   fdipx = fdixd*rf_d if iso == "CU" 
replace   ptfrx = ptfxa*rp_a if iso == "CU"
replace   ptfpx = ptfxd*rp_d if iso == "CU"

replace q_ptfrx_eq  = min(3, q_ptfxa_eq)  if iso == "CU"
replace q_ptfrx_deb = min(3, q_ptfxa_deb) if iso == "CU"
replace q_ptfrx_res = min(3, q_ptfxa_res) if iso == "CU"
replace q_ptfpx_eq  = min(3, q_ptfxd_eq)  if iso == "CU"
replace q_ptfpx_deb = min(3, q_ptfxd_deb) if iso == "CU"
replace s_ptfrx_eq  = "ptfxa-eq_return"  + s_rpeq_a  if iso == "CU"
replace s_ptfrx_deb = "ptfxa-deb_return" + s_rpdeb_a if iso == "CU"
replace s_ptfrx_res = "ptfxa-res_return" + s_rpres_a if iso == "CU"
replace s_ptfpx_eq  = "ptfxd-eq_return"  + s_rpeq_d  if iso == "CU"
replace s_ptfpx_deb = "ptfxd-deb_return" + s_rpdeb_d if iso == "CU"
replace   ptfrx_eq  = rpeq_a*ptfxa_eq   if iso == "CU"
replace   ptfrx_deb = rpdeb_a*ptfxa_deb if iso == "CU"
replace   ptfrx_res = rpres_a*ptfxa_res if iso == "CU"
replace   ptfpx_eq  = rpeq_d*ptfxd_eq   if iso == "CU"
replace   ptfpx_deb = rpdeb_d*ptfxd_deb if iso == "CU"

// North Korea = Cuba
foreach var in rp_a rp_d rf_a rf_d rpeq_a rpdeb_a rpres_a rpeq_d rpdeb_d fdirx fdipx ptfrx ptfpx ptfrx_eq ptfrx_deb ptfrx_res ptfpx_eq ptfpx_deb {
    gen aux`var' = cond(iso=="CU", `var', .)
    bys year: egen CU`var' = mode(aux`var'), maxmode
	
	local v_dash = subinstr("`var'", "_", "-", .)
	
    capture replace s_`var' = "`v_dash'(CU)" if iso == "KP"
    capture replace q_`var' = 0          if iso == "KP"
    capture replace s_`var' = "`v_dash'(CU)" if iso == "KP"
    capture replace q_`var' = 0          if iso == "KP"

    replace `var' = CU`var' if iso == "KP" & !missing(CU`var')
	replace s_`var' = subinstr(s_`var', "rp_", "rportfolio", .)
	replace s_`var' = subinstr(s_`var', "rpdeb_", "rportfoliodebt", .)
	replace s_`var' = subinstr(s_`var', "rpres_", "rportfolioreserves", .)
}
drop aux*

foreach v in ptfxa ptfxd fdixa fdixd ptfxd_deb ptfxd_eq ptfxd_fin ptfxa_res ptfxa_deb ptfxa_eq ptfxa_fin {
	replace `v' = `v'_gdp*gdp if iso == "KP"
}

// collapse (sum) fdirx fdipx ptfrx ptfpx gdp, by(TH year)
// gen fdinx = fdirx - fdipx 
// gen ptfnx = ptfrx - ptfpx 
// asd
// replace fdipx = - fdipx 
// replace fdinx = - fdinx 
// foreach v in fdirx fdipx fdinx { 
// replace `v' = `v'/gdp
// }

foreach var in fdirx fdipx ptfrx ptfpx pinrx pinpx ptfrx_eq ptfrx_deb ptfrx_res ptfpx_eq ptfpx_deb {
so i year
xtset i year 
	gen lagq_`var' = l.q_`var'
	bysort i (year): gen lags_`var' = s_`var'[_n-1]
	gen  lag`var' =  l.`var'
	
	replace q_`var' = lagq_`var'
	replace s_`var' = lags_`var'
	replace   `var' = lag`var'
	
	replace q_`var' = origq_`var' if year == 1970 & missing(`var')
	replace s_`var' = origs_`var' if year == 1970 & missing(`var')
	replace   `var' =   orig`var' if year == 1970 & missing(`var')
	gsort iso -year
	by iso : carryforward `var', replace
	replace q_`var' = 1              if !missing(`var') & missing(q_`var')
	replace s_`var' = "carryfor" if !missing(`var') & missing(s_`var')
}
so iso year

// -------------------------------------------------------------------------- //
// ---- 8. ensuring consistency ---------------------------------------------- //
// -------------------------------------------------------------------------- //
*------ ptfrx
egen auxptfrx = rowtotal(ptfrx_eq ptfrx_deb ptfrx_res), missing
quality ptfrx_eq ptfrx_deb ptfrx_res, gen(temp)
replace q_ptfrx = temp                           if !missing(auxptfrx) & flagpinrx == 1
drop temp
replace s_ptfrx = "ptfrx-eq,ptfrx-deb,ptfrx-res" if !missing(auxptfrx) & flagpinrx == 1
replace   ptfrx = auxptfrx                       if !missing(auxptfrx) & flagpinrx == 1 
gen     ratio = auxptfrx/ptfrx 
replace ratio = 0 if mi(ratio)

foreach var in ptfrx_deb ptfrx_eq ptfrx_res {
	local v_dash = subinstr("`var'", "_", "-", .)
	replace q_`var' = min(3, q_`var')                                   if !missing(auxptfrx) & flagpinrx == 0  // Keep the metadata as it is
	replace s_`var' = "`v_dash'_ratio(ptfrx-eq,ptfrx-deb,ptfrx-res)/ptfrx" if !missing(auxptfrx) & flagpinrx == 0  // Keep the metadata as it is
	replace   `var' = `var'/ratio                                       if !missing(auxptfrx) & flagpinrx == 0  // Keep the metadata as it is
}
drop ratio 
quality ptfrx_eq  ptfrx_deb ptfrx_res, gen(temp)
replace q_ptfrx = temp        if missing(ptfrx)
drop temp
replace s_ptfrx = "ptfrx-eq,ptfrx-deb,ptfrx-res"  if missing(ptfrx)
replace   ptfrx = auxptfrx    if missing(ptfrx)

*------ ptfpx
egen   auxptfpx = rowtotal(ptfpx_eq ptfpx_deb), missing
replace q_ptfpx = min(3, cond(ptfpx_eq >= ptfpx_deb, q_ptfpx_eq, q_ptfpx_deb)) if !missing(auxptfpx) & flagpinpx == 1 & iso != "KY"
replace s_ptfpx = "ptfpx-eq,ptfpx-deb"   if !missing(auxptfpx) & flagpinpx == 1 & iso != "KY"
replace   ptfpx = auxptfpx if !missing(auxptfpx) & flagpinpx == 1 & iso != "KY"
gen     ratio = auxptfpx/ptfpx 
replace ratio = 0 if mi(ratio)
foreach var in ptfpx_deb ptfpx_eq {
	local v_dash = subinstr("`var'", "_", "-", .)
	replace q_`var' = min(3, q_`var') if !missing(auxptfpx) & flagpinpx == 0  // Keep the metadata as it is
	replace s_`var' = "`v_dash'_ratio(ptfpx-eq + ptfpx-deb)/ptfpx" if !missing(auxptfpx) & flagpinpx == 0  // Keep the metadata as it is
	replace   `var' = `var'/ratio if !missing(auxptfpx) & flagpinpx == 0  // Keep the metadata as it is
	replace s_`var' = "`v_dash'_ratio(ptfpx-eq + ptfpx-deb)/ptfpx" if !missing(auxptfpx) & iso == "KY" & flagpinpx != 0  // Keep the metadata as it is
	replace q_`var' = min(3, q_`var') if !missing(auxptfpx) & iso == "KY" & flagpinpx != 0  // Keep the metadata as it is
	replace   `var' = `var'/ratio     if !missing(auxptfpx) & iso == "KY" & flagpinpx != 0  // Keep the metadata as it is
}
drop ratio 
replace q_ptfpx = min(3, cond(ptfpx_eq >= ptfpx_deb, q_ptfpx_eq, q_ptfpx_deb)) if missing(ptfpx)
replace s_ptfpx = "ptfpx-eq,ptfpx-deb" if missing(ptfpx)
replace   ptfpx = auxptfpx             if missing(ptfpx)

replace q_ptfnx = min(3, cond(ptfrx >= ptfpx, q_ptfrx, q_ptfpx))
replace s_ptfnx = "ptfrx,ptfpx"
replace   ptfnx = ptfrx - ptfpx 

*------ pinrx
egen auxpinrx = rowtotal(fdirx ptfrx), missing
replace q_pinrx = min(3, cond(fdirx >= ptfrx, q_fdirx, q_ptfrx)) if !missing(auxpinrx) & flagpinrx == 1
replace s_pinrx = "fdirx,ptfrx"                                  if !missing(auxpinrx) & flagpinrx == 1
replace   pinrx = auxpinrx                                       if !missing(auxpinrx) & flagpinrx == 1
gen       ratio = auxpinrx/pinrx 

replace ratio = 0 if mi(ratio)
foreach var in fdirx ptfrx {
	replace s_`var' = "`var'_ratio(fdirx + ptfrx)/pinrx" if !missing(auxpinrx) & flagpinrx == 0  
	replace s_`var' = "`var'_assumedratio0"              if !missing(auxpinrx) & flagpinrx == 0  & ratio==0
	replace q_`var' = min(3, q_`var') if !missing(auxpinrx) & flagpinrx == 0  
	replace   `var' = `var'/ratio if !missing(auxpinrx) & flagpinrx == 0  
}
drop ratio 


replace q_pinrx = min(3, cond(fdirx >= ptfrx, q_fdirx, q_ptfrx)) if missing(pinrx)
replace s_pinrx = "fdirx,ptfrx"                                  if missing(pinrx)
replace   pinrx = auxpinrx                                       if missing(pinrx)

*------ pinpx
egen auxpinpx = rowtotal(fdipx ptfpx), missing
replace q_pinpx = min(3, cond(fdipx >= ptfpx, q_fdipx, q_ptfpx)) if !missing(auxpinpx) & flagpinpx == 1
replace s_pinpx = "fdipx,ptfpx"                                  if !missing(auxpinpx) & flagpinpx == 1
replace   pinpx = auxpinpx                                       if !missing(auxpinpx) & flagpinpx == 1
gen     ratio = auxpinpx/pinpx 
replace ratio = 0 if mi(ratio)
foreach var in fdipx ptfpx {
	replace s_`var' = "`var'_ratio(fdipx + ptfpx)/pinpx" if !missing(auxpinpx) & flagpinpx == 0
	replace s_`var' = "`var'_assumedratio0"              if !missing(auxpinpx) & flagpinpx == 0 & ratio==0
	replace q_`var' = min(3,cond(fdipx >= ptfpx, q_fdipx, q_ptfpx)) if !missing(auxpinpx) & flagpinpx == 0
	replace   `var' = `var'/ratio if !missing(auxpinpx) & flagpinpx == 0
}
drop ratio 
replace q_pinpx = min(3, cond(fdipx >= ptfpx, q_fdipx, q_ptfpx)) if missing(pinpx)
replace s_pinpx = "fdipx,ptfpx" if missing(pinpx)
replace   pinpx = auxpinpx      if missing(pinpx)

keep iso year fdixa fdixd ptfxa ptfxd fdirx fdipx ptfrx ptfpx pinrx pinpx ptfxa_deb ptfxa_eq ptfxa_res ptfxa_fin ptfxd_eq ptfxd_deb ptfxd_fin ptfrx_eq ptfrx_deb ptfrx_res ptfpx_eq ptfpx_deb ///
q_fdixa q_fdixd q_ptfxa q_ptfxd q_fdirx q_fdipx q_ptfrx q_ptfpx q_pinrx q_pinpx q_ptfxa_deb q_ptfxa_eq q_ptfxa_res q_ptfxa_fin q_ptfxd_eq q_ptfxd_deb q_ptfxd_fin q_ptfrx_eq q_ptfrx_deb q_ptfrx_res q_ptfpx_eq q_ptfpx_deb ///
s_fdixa s_fdixd s_ptfxa s_ptfxd s_fdirx s_fdipx s_ptfrx s_ptfpx s_pinrx s_pinpx s_ptfxa_deb s_ptfxa_eq s_ptfxa_res s_ptfxa_fin s_ptfxd_eq s_ptfxd_deb s_ptfxd_fin s_ptfrx_eq s_ptfrx_deb s_ptfrx_res s_ptfpx_eq s_ptfpx_deb ///
gdp flagpinrx flagpinpx


// collapse (sum) fdirx fdipx ptfrx ptfpx gdp, by(year)
// gen fdinx = fdirx - fdipx 
// gen ptfnx = ptfrx - ptfpx 

foreach var in fdixa fdixd ptfxa ptfxd fdirx fdipx ptfrx ptfpx pinrx pinpx ptfxa_deb ptfxa_eq ptfxa_res ptfxa_fin ptfxd_eq ptfxd_deb ptfxd_fin ptfrx_eq ptfxd_fin ptfrx_deb ptfrx_res ptfpx_eq ptfpx_deb {
	replace   `var' = `var'/gdp
	replace q_`var' = 0          if mi(`var')
	replace s_`var' = "assumed" if mi(`var')
	replace   `var' = 0          if mi(`var')
}

// Ensuring ratios are consistent
gen ratio = (ptfxa_eq + ptfxa_deb + ptfxa_res + ptfxa_fin) / ptfxa 
foreach var in ptfxa_eq ptfxa_deb ptfxa_res ptfxa_fin {
	local v_dash = subinstr("`var'", "_", "-", .)
	replace q_`var' = min(3,q_`var')
	replace s_`var' = "`v_dash'_ratio(ptfxa-eq + ptfxa-deb + ptfxa-res + ptfxa-fin)/ptfxa" 
	replace   `var' = `var'/ratio  
}
gen ratio2 = (ptfxd_eq + ptfxd_deb + ptfxd_fin) / ptfxd 
foreach var in ptfxd_eq ptfxd_deb ptfxd_fin {
	local v_dash = subinstr("`var'", "_", "-", .)
	replace q_`var' = min(3,q_`var')
	replace s_`var' = "`v_dash'_ratio(ptfxd-eq + ptfxd-deb + ptfxd-fin)/ptfxd" 
	replace   `var' = `var'/ratio2                          
}
drop ratio*


// temporary solution for 2022 to ensure we can do the missing profits
// replace fdirx = . if year == 2022
//	gsort iso year
//	by iso : carryforward fdirx, replace

gen q_nwgxa = min(3, cond(fdixa >= ptfxa, q_fdixa, q_ptfxa))
gen s_nwgxa = "fdixa,ptfxa"
gen   nwgxa = fdixa + ptfxa

gen q_nwgxd = min(3, cond(fdixd >= ptfxd, q_fdixd, q_ptfxd))
gen s_nwgxd = "fdixd,ptfxd"
gen   nwgxd = fdixd + ptfxd
foreach v in nwgxa nwgxd fdirx fdipx ptfrx ptfpx {
gen `v'_gdp = `v'*gdp                                   // Keep metadata as it is
}

// collapse (sum) nwgxa_gdp nwgxd_gdp fdirx_gdp fdipx_gdp ptfrx_gdp ptfpx_gdp, by(year)
// gen nwnxa = nwgxa - nwgxd
// gen pinrx2 = fdirx + ptfrx 
// gen pinpx2 = fdipx + ptfpx 
// gen fdinx2 = fdirx_gdp - fdipx_gdp
// gen ptfnx2 = ptfrx_gdp - ptfpx_gdp

drop fdirx_gdp fdipx_gdp ptfrx_gdp ptfpx_gdp 

// Fixing KP negative nninc and IQ negative nninc
foreach var in ptfrx_eq ptfrx_deb ptfrx_res ptfpx_eq ptfpx_deb fdirx fdipx {
	replace q_`var' =.  if iso == "KP" & year == 2023
	replace s_`var' ="" if iso == "KP" & year == 2023
	replace   `var' =.  if iso == "KP" & year == 2023
	replace q_`var' =.  if iso == "IQ" & inrange(year, 1991, 1993)
	replace s_`var' ="" if iso == "IQ" & inrange(year, 1991, 1993)
	replace   `var' =.  if iso == "IQ" & inrange(year, 1991, 1993)
	so iso year
	by iso : carryforward `var'      if iso == "KP" & year == 2023, replace
	replace q_`var' = 1              if iso == "KP" & year == 2023
	replace s_`var' = "carryfor" if iso == "KP" & year == 2023
	gsort iso -year
	by iso : carryforward `var'      if iso == "IQ" & inrange(year, 1991, 1993), replace
	replace q_`var' = 1              if iso == "IQ" & inrange(year, 1991, 1993)
	replace s_`var' = "carryfor" if iso == "IQ" & inrange(year, 1991, 1993)
}

replace q_ptfrx = min(q_ptfrx_eq, q_ptfrx_deb, q_ptfrx_res)
replace q_ptfpx = min(q_ptfpx_eq, q_ptfpx_deb)
replace q_pinrx = min(q_fdirx, q_ptfrx)
replace q_pinpx = min(q_fdipx, q_ptfpx) 
replace s_ptfrx = s_ptfrx_eq 
replace s_ptfpx = s_ptfpx_eq 
replace s_pinrx = s_fdirx 
replace s_pinpx = s_fdipx 
replace ptfrx = ptfrx_eq + ptfrx_deb + ptfrx_res
replace ptfpx = ptfpx_eq + ptfpx_deb
replace pinrx = fdirx + ptfrx 
replace pinpx = fdipx + ptfpx 



gen q_pinnx = min(3, cond(pinrx >= pinpx, q_pinrx, q_pinpx))
gen q_fdinx = min(3, cond(fdirx >= fdipx, q_fdirx, q_fdipx))
gen q_ptfnx = min(3, cond(ptfrx >= ptfpx, q_ptfrx, q_ptfpx))
gen s_pinnx = "pinrx,pinpx"
gen s_fdinx = "fdirx,fdipx"
gen s_ptfnx = "ptfrx,ptfpx"
gen   pinnx = pinrx - pinpx 
gen   fdinx = fdirx - fdipx 
gen   ptfnx = ptfrx - ptfpx 

drop gdp 

label data "Generated by estimate-fki.do"
save "$work_data/estimated-fki.dta", replace
keep iso year *fdirx *fdipx *ptfrx *ptfpx *pinrx *pinpx *ptfrx_eq *ptfrx_deb *ptfrx_res *ptfpx_eq *ptfpx_deb

//----------------------------------------------------------------------------//
//---- 9. Merging with retropolate ---------------------------------------------
//----------------------------------------------------------------------------//
use "$work_data/sna-combined-prefki.dta", clear

merge 1:1 iso year using "$work_data/estimated-fki.dta", nogen update replace

		
// Foreign income
enforce (comnx = comrx - compx) ///
		(pinnx = pinrx - pinpx) ///
		(flcin = flcir - flcip) ///
		(taxnx = fsubx - ftaxx) ///
		(nnfin = finrx - finpx) ///
		(finrx = comrx + pinrx + fsubx) ///
		(finpx = compx + pinpx + ftaxx) ///
		(nnfin = flcin + taxnx) ///
		(flcir = comrx + pinrx) ///
		(flcip = compx + pinpx) ///
		(ptfrx = ptfrx_eq + ptfrx_deb + ptfrx_res) ///
		(ptfpx = ptfpx_eq + ptfpx_deb) ///
		(fsubx = fpsub + fosub) ///
		(ftaxx = fptax + fotax) ///
		(taxnx = prtxn + optxn) ///
		///  Gross national income of the different sectors of the economy
		(gdpro + nnfin = prghn + prgco + prggo) ///
		(gdpro + nnfin = seghn + segco + seggo) ///
		/// Property income
		(pinnx = prphn + prpco + prpgo) ///
		(prphn = prpho + prpnp) ///
		(prpco = prpfc + prpnf) ///
		/// Taxes on income and wealth
		(tiwgo = tiwhn + taxco) ///
		(tiwhn = tiwho + tiwnp) ///
		(taxco = taxnf + taxfc) ///
		/// Social contributions
		(sschn = sscco + sscgo) ///
		(sscco = sscnf + sscfc) ///
		(sschn = sscho + sscnp) ///
		/// Social benefits
		(ssbhn = ssbco + ssbgo) ///
		(ssbco = ssbnf + ssbfc) ///
		(ssbhn = ssbho + ssbnp) ///
		/// Consumption of fixed capital
		(confc = cfchn + cfcco + cfcgo) ///
		/// National savings
		(savig = savin + confc) ///
		(savin = savhn + savgo + secco) ///
		/// Household + NPISH sector
		(prghn = comhn + caghn) ///
		(caghn = gsmhn + prphn) ///
		(caphn = nsmhn + prphn) ///
		(nsmhn = gsmhn - cfchn) ///
		(nsrhn = gsrhn - ccshn) ///
		(nmxhn = gmxhn - ccmhn) ///
		(cfchn = ccshn + ccmhn) ///
		(prihn = prghn - cfchn) ///
		(nsmhn = nmxhn + nsrhn) ///
		(gsmhn = gmxhn + gsrhn) ///
		(seghn = prghn - taxhn + ssbhn) ///
		(taxhn = tiwhn + sschn) ///
		(seghn = sechn + cfchn) ///
		(saghn = seghn - conhn) ///
		(saghn = savhn + cfchn) ///
		/// Households
        (prgho = comho + cagho) ///
		(cagho = gsmho + prpho) ///
		(capho = nsmho + prpho) ///
		(nsmho = gsmho - cfcho) ///
		(nsrho = gsrho - ccsho) ///
		(nmxho = gmxho - ccmho) ///
		(cfcho = ccsho + ccmho) ///
		(priho = prgho - cfcho) ///
		(nsmho = nmxho + nsrho) ///
		(gsmho = gmxho + gsrho) ///
		(segho = prgho - taxho + ssbho) ///
		(taxho = tiwho + sscho) ///
		(segho = secho + cfcho) ///
		(sagho = segho - conho) ///
		(sagho = savho + cfcho) ///
		/// NPISH
        /// (prgnp = comnp + cagnp) ///
		(cagnp = gsrnp + prpnp) ///
		(capnp = nsrnp + prpnp) ///
		(nsrnp = gsrnp - cfcnp) ///
		(prinp = prgnp - cfcnp) ///
		(segnp = prgnp - taxnp + ssbnp) ///
		(taxnp = tiwnp + sscnp) ///
		(segnp = secnp + cfcnp) ///
		(sagnp = segnp - connp) ///
		(sagnp = savnp + cfcnp) ///
		/// Combination of sectors
		(prihn = priho + prinp) ///
		/// (comhn = comho + comnp) ///
		(prphn = prpho + prpnp) ///
		(caphn = capho + capnp) ///
		(caghn = cagho + cagnp) ///
		(nsmhn = nsmho + nsrnp) ///
		(gsmhn = gsmho + gsrnp) ///
		(gsrhn = gsrho + gsrnp) ///
		(gmxhn = gmxho) ///
		(cfchn = cfcho + cfcnp) ///
		(ccshn = ccsho + cfcnp) ///
		(ccmhn = ccmho) ///
		(sechn = secho + secnp) ///
		(taxhn = taxho + taxnp) ///
		(tiwhn = tiwho + tiwnp) ///
		(sschn = sscho + sscnp) ///
		(ssbhn = ssbho + ssbnp) ///
		(seghn = segho + segnp) ///
		(savhn = savho + savnp) ///
		(saghn = sagho + sagnp) ///
		/// Corporate sector
		/// Combined sectors, primary income
		(prgco = prpco + gsrco) ///
		(prgco = prico + cfcco) ///
		(nsrco = gsrco - cfcco) ///
		/// Financial, primary income
		(prgfc = prpfc + gsrfc) ///
		(prgfc = prifc + cfcfc) ///
		(nsrfc = gsrfc - cfcfc) ///
		/// Non-financial, primary income
		(prgnf = prpnf + gsrnf) ///
		(prgnf = prinf + cfcnf) ///
		(nsrnf = gsrnf - cfcnf) ///
		/// Combined sectors, secondary income
		(segco = prgco - taxco + sscco - ssbco) ///
		(segco = secco + cfcco) ///
		/// Financial, secondary income
		(segfc = prgfc - taxfc + sscfc - ssbfc) ///
		(segfc = secfc + cfcfc) ///
		/// Non-financial, secondary income
		(segnf = prgnf - taxnf + sscnf - ssbnf) ///
		(segnf = secnf + cfcnf) ///
		/// Combination of sectors
		(prico = prifc + prinf) ///
		(prpco = prpfc + prpnf) ///
		(nsrco = nsrfc + nsrnf) ///
		(gsrco = gsrfc + gsrnf) ///
		(cfcco = cfcfc + cfcnf) ///
		(secco = secfc + secnf) ///
		(taxco = taxfc + taxnf) ///
		(sscco = sscfc + sscnf) ///
		(segco = segfc + segnf) ///
		/// Government
		/// Primary income
		(prggo = ptxgo + prpgo + gsrgo) ///
		(nsrgo = gsrgo - cfcgo) ///
		(prigo = prggo - cfcgo) ///
		/// Taxes less subsidies of production
		(ptxgo = tpigo - spigo) ///
		(tpigo = tprgo + otpgo) ///
		(spigo = sprgo + ospgo) ///
		/// Secondary incomes
		(seggo = prggo + taxgo - ssbgo) ///
		(taxgo = tiwgo + sscgo) ///
		(secgo = seggo - cfcgo) ///
		/// Consumption and savings
		(saggo = seggo - congo) ///
		(congo = indgo + colgo) ///
		(savgo = saggo - cfcgo) ///
		/// Structure of gov spending
		(congo = gpsgo + defgo + polgo + ecogo + envgo + hougo + heago + recgo + edugo + sopgo + othgo) ///
		/// Labor + capital income decomposition
		(fkpin = prphn + prico + nsrhn + prpgo), fixed(gdpro fsubx ftaxx comrx compx fdirx fdipx ptfrx ptfpx ptfrx_eq ptfrx_deb ptfrx_res ptfpx_eq ptfpx_deb confc fkpin comhn nmxhn) prefix(new) replace force

drop newgdp		
foreach v of varlist new* {
    local base = subinstr("`v'", "new", "", .)

    replace s_`base' = "enforce" if missing(`base') & !missing(`v')
	replace q_`base' = 3         if missing(`base') & !missing(`v')
	replace   `base' = `v'
}
drop new* 
		

* Some early government sector data too problematic to do anything
ds *go
local vars `r(varlist)'

foreach v of local vars {
    if !strpos("`v'", "s_") & !strpos("`v'", "q_") & !strpos("`v'", "series") {
        replace q_`v' = .  if inlist(iso, "TZ", "NA") & year < 2008
        replace s_`v' = "" if inlist(iso, "TZ", "NA") & year < 2008
        replace   `v' = .  if inlist(iso, "TZ", "NA") & year < 2008

        replace q_`v' = .  if inlist(iso, "NA")
        replace s_`v' = "" if inlist(iso, "NA")
        replace   `v' = .  if inlist(iso, "NA")
    }
}


// fixing some discrepancies caused by enforce
egen auxptfrx = rowtotal(ptfrx_eq ptfrx_deb ptfrx_res), missing
quality ptfrx_eq ptfrx_deb ptfrx_res, gen(temp)
replace q_ptfrx =temp                            if !missing(auxptfrx)
drop temp
replace s_ptfrx = "ptfrx-eq,ptfrx-deb,ptfrx-res" if !missing(auxptfrx)
replace   ptfrx = auxptfrx if !missing(auxptfrx)

egen auxptfpx = rowtotal(ptfpx_eq ptfpx_deb), missing
replace q_ptfpx = min(3, cond(ptfpx_eq >= ptfpx_deb,q_ptfpx_eq, q_ptfpx_deb)) if !missing(auxptfpx)
replace s_ptfpx = "ptfpx-eq,ptfpx-deb" if !missing(auxptfpx)
replace   ptfpx = auxptfpx             if !missing(auxptfpx)

egen auxpinrx = rowtotal(fdirx ptfrx)
replace q_pinrx = min(3, cond(fdirx >= ptfrx, q_fdirx, q_ptfrx)) if !missing(auxpinrx)
replace s_pinrx = "fdirx,ptfrx" if !missing(auxpinrx)
replace   pinrx = auxpinrx      if !missing(auxpinrx)

egen auxpinpx = rowtotal(fdipx ptfpx)
replace q_pinpx = min(3, cond(fdipx >= ptfpx, q_fdipx, q_ptfpx)) if !missing(auxpinpx)
replace s_pinpx = "fdipx,ptfpx" if !missing(auxpinpx)
replace   pinpx = auxpinpx      if !missing(auxpinpx)

replace q_pinnx = min(3, cond(pinrx >= pinpx,q_pinrx, q_pinpx))
replace s_pinnx = "pinrx,pinpx"
replace   pinnx = pinrx - pinpx
drop aux* 

//----------------------------------------------------------------------------//
//---- 10. Export ------------------------------------------------------------
//----------------------------------------------------------------------------//

label data "Generated by estimate-fki.do"
save "$work_data/sna-combined.dta", replace
