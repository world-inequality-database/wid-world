// -------------------------------------------------------------------------- //
// Import foreign share of reinvested earnings on portfolio investment
// -------------------------------------------------------------------------- //

// -------------------------------------------------------------------------- //
// Get estimate of GPD in current USD
// -------------------------------------------------------------------------- //

u "$work_data/exchange-rates.dta", clear
merge 1:1 iso year using "$work_data/retropolate-gdp.dta", nogen keepusing(gdp)
merge 1:1 iso year using "$work_data/price-index.dta", nogen keepusing(index)
merge 1:1 iso year using "$work_data/sna-series-finalized.dta", nogenerate keep(match) keepusing(*ptfnx *ptfrx *ptfpx)

foreach v in ptfnx ptfrx ptfpx {
	replace `v' = `v'*gdp
}

foreach var in gdp ptfnx ptfrx ptfpx {
gen `var'_idx = `var'*index
	gen `var'_usd = `var'_idx/exrate_usd
}

merge 1:1 iso year using "$work_data/import-core-country-codes-year-output.dta", nogen keepusing(corecountry) 
keep if corecountry == 1

keep iso year gdp_usd
ren gdp_usd gdp
drop if missing(gdp)

tempfile gdp
save "`gdp'"

// Store relative size of Curacao and Sint Marteen to split them in
// the CPIS statistics
keep if inlist(iso, "CW", "SX")

egen total = total(gdp), by(year)
generate share_gdp = gdp/total

keep iso year share_gdp

tempfile gdp_cw_sx
save "`gdp_cw_sx'"

// -------------------------------------------------------------------------- //
// Import OECD data on equity
// -------------------------------------------------------------------------- //

import delimited "$input_data_dir/oecd-data/national-accounts/balance-sheet/SNA_TABLE720_18032020115610660.csv", clear encoding(utf8)

keep location time transact sector value
greshape wide value, i(location time transact) j(sector) string
greshape wide value*, i(location time) j(transact) string

generate equ_liabi_dom = valueS1SAF5LINC
generate equ_liabi_row = valueS2SAF5ASNC
generate equ_asset_row = valueS2SAF5LINC

generate ratio_equ_liabi_dom = valueS1SAF51LINC/valueS1SAF5LINC
generate ratio_equ_liabi_row = valueS2SAF51ASNC/valueS2SAF5ASNC
generate ratio_equ_asset_row = valueS2SAF51LINC/valueS2SAF5LINC

replace ratio_equ_liabi_row = . if location == "MEX"
replace ratio_equ_liabi_row = . if location == "MEX"

keep location time equ_liabi_dom equ_liabi_row equ_asset_row ratio_equ_liabi_dom ratio_equ_liabi_row ratio_equ_asset_row

tempfile oecd
save "`oecd'"

import delimited "$input_data_dir/oecd-data/national-accounts/balance-sheet/SNA_TABLE720R_18032020115434814.csv", clear encoding(utf8)

keep location time transact sector value
greshape wide value , i(location time transact) j(sector)   string
greshape wide value*, i(location time)          j(transact) string

generate equ_liabi_dom = valueRS1LF5LINC
generate equ_liabi_row = valueRS2LF5ASNC
generate equ_asset_row = valueRS2LF5LINC

generate ratio_equ_liabi_dom = valueRS1LF51LINC/valueRS1LF5LINC
generate ratio_equ_liabi_row = valueRS2LF51ASNC/valueRS2LF5ASNC
generate ratio_equ_asset_row = valueRS2LF51LINC/valueRS2LF5LINC

keep location time equ_liabi_dom equ_liabi_row equ_asset_row ratio_equ_liabi_dom ratio_equ_liabi_row ratio_equ_asset_row

append using "`oecd'"

collapse (mean) equ_liabi_dom equ_liabi_row equ_asset_row ratio_equ_liabi_dom ratio_equ_liabi_row ratio_equ_asset_row, by(location time)

kountry location, from(iso3c) to(iso2c)
rename _ISO2C_ iso
drop location

rename time year

replace equ_liabi_dom = equ_liabi_dom*1e6
replace equ_liabi_row = equ_liabi_row*1e6
replace equ_asset_row = equ_asset_row*1e6

ds iso year, not 
foreach v in `r(varlist)' {
	gen s_`v' = "OECD" if !missing(`v')
	gen q_`v' = 5      if !missing(`v')
}

save "`oecd'", replace

// -------------------------------------------------------------------------- //
// Import data on net asset position of countries
// -------------------------------------------------------------------------- //
/*
// IMF
*import delimited "$input_data_dir/imf-data/balance-of-payments/BOP_04-04-2024 10-40-55-91.csv", clear encoding(utf8)
use "$wid_dir/Country-Updates/National_Accounts/imf-data/IIP-treated-$pastyear.dta", clear

drop if country == "Cayman Islands" // Data inconsistent with EWN
drop if value == 0
keep if year > 2015 & year <= ($pastyear - 1)

keep if inlist(code2,"A_P","L_P")	
keep if inlist(code3, "P_F5_MV","D")
 
// Note: From 2025 version the codes to be used are:
//		  - P_F5_MV is "Portfolio investment, Equity and investment fund shares"
//        - D       is "Direct Investment"

gen code= code2+code3
drop code2 code3
 
keep country code year value

greshape wide value, i(country year) j(code) string

generate ptf_asset = valueA_PP_F5_MV // Before: IAPE_BP6_USD
generate ptf_liabi = valueL_PP_F5_MV // Before: ILPE_BP6_USD

generate fdi_asset = valueA_PD // before: IAD_BP6_USD
generate fdi_liabi = valueL_PD // beofre: ILD_BP6_USD

keep country year ptf_*

tempfile iip
save "`iip'"
*/
// EWN
import excel "$input_data_dir/ewn-data/EWN-database-$pastyear.xlsx", sheet("Dataset") clear firstrow case(lower)

rename portfolioequityassets      ptf_asset
rename portfolioequityliabilities ptf_liabi

rename fdiassets      fdi_asset
rename fdiliabilities fdi_liabi

rename gdpus gdp

ren country countryname

ren ifs_code ifsid 

keep countryname ifsid year ptf_asset ptf_liabi fdi_asset fdi_liabi gdp

foreach v of varlist ptf_asset ptf_liabi fdi_asset fdi_liabi gdp {
	gen     q_`v' = 5       if !missing(`v')
	gen     s_`v' = "lmf"  if !missing(`v')
	replace   `v' = `v'*1e6
}

*append using "`iip'" // Use official IIP for recent years

kountry ifsid, from(imfn) to(iso2c)
rename _ISO2C_ iso
replace iso = "AD" if countryname == "Andorra" | countryname == "Andorra, Principality of"
replace iso = "VG" if countryname == "British Virgin Islands"
replace iso = "CW" if countryname == "Curacao" | countryname == "Curaçao" | countryname == "Curaçao and Sint Maarten"
replace iso = "GG" if countryname == "Guernsey"
replace iso = "IM" if countryname == "Isle of Man"
replace iso = "JE" if countryname == "Jersey"
replace iso = "KS" if countryname == "Kosovo"
replace iso = "RS" if countryname == "Serbia"
replace iso = "SX" if countryname == "Sint Maarten"
replace iso = "SS" if countryname == "South Sudan"
replace iso = "TC" if countryname == "Turks and Caicos"
replace iso = "TV" if countryname == "Tuvalu"
replace iso = "PS" if countryname == "West Bank and Gaza"
replace iso = "CW" if countryname == "Curaçao, Kingdom of the Netherlands"
replace iso = "KS" if countryname == "Kosovo, Rep. of"
replace iso = "RS" if countryname == "Serbia, Rep. of"
replace iso = "SX" if countryname == "Sint Maarten, Kingdom of the Netherlands"
replace iso = "TC" if countryname == "Turks and Caicos Islands"
replace iso = "LI" if countryname == "Liechtenstein"
drop if inlist(countryname, "Eastern Caribbean Currency Union", "Euro Area", "ECCU")
assert iso != ""

drop if iso == ""
drop ifsid countryname

merge 1:1 iso year using "`oecd'", nogenerate
merge 1:1 iso year using "`gdp'", nogenerate update
fillin iso year
drop _fillin

// There is data for Netherlands Antilles until 2009
// Curacao and Sint Maarten will be calculated based on GDP shares
merge m:1 iso using "$work_data/ratioCWSX_AN.dta", nogen 
foreach v in ptf_asset ptf_liabi fdi_asset fdi_liabi { 
	bys year : gen aux`v'   = `v' if iso == "AN"
	bys year : egen   `v'AN = mode(aux`v')
}
foreach v in ptf_asset ptf_liabi fdi_asset fdi_liabi { 
	foreach c in CW SX {
		local v_dash = subinstr("`v'", "_", "-", .)
		replace q_`v' = 1                      if iso == "`c'" & missing(`v') & !missing(`v'AN) & !missing(ratio`c'_ANlcu)
		replace s_`v' = "`v_dash'(AN)_ratio`c'/AN'"           if iso == "`c'" & missing(`v') & !missing(`v'AN) & !missing(ratio`c'_ANlcu)
		replace   `v' =   `v'AN*ratio`c'_ANlcu if iso == "`c'" & missing(`v')
	}
}	
drop aux* *AN *ANlcu

merge 1:1 iso year using "$work_data/import-core-country-codes-year-output.dta", nogen keepusing(corecountry) 
keep if corecountry == 1

sort iso year

// Extrapolate portfolio position based on GDP
sort iso year
foreach v of varlist ptf_asset ptf_liabi fdi_asset fdi_liabi {
	generate coef = `v'/gdp
	by iso: carryforward coef, replace
	replace q_`v' =  1                if missing(`v') & !missing(coef)
	replace s_`v' = "carrifor`v'/gdp" if missing(`v') & !missing(coef)
	replace   `v' = gdp*coef          if missing(`v')
	drop coef
}

// Extrapolate share of pure equity out out equity + investment fund shares
gsort iso -year
by iso: carryforward ratio_*,  replace
gsort iso year
by iso: carryforward ratio_*, replace

foreach v of varlist ratio_* {
	replace q_`v' = 1          if missing(q_`v') & !missing(`v') 
	replace s_`v' = "carryfor" if missing(s_`v') & !missing(`v') 
}

// If no data: assume all pure equity (ie. no correction)
foreach v of varlist ratio_* {
	replace q_`v' = 0         if missing(`v')
	replace s_`v' = "assumed" if missing(`v')
	replace   `v' = 1         if missing(`v')
}



tempfile netpos
save "`netpos'"

// Keep a list countries with a net asset position
keep iso
gduplicates drop

tempfile iso_netpos
save "`iso_netpos'"

use "`netpos'", clear

// -------------------------------------------------------------------------- //
// Estimate the fraction of equities owned by foreigners
// -------------------------------------------------------------------------- //
gen cond =1 if !mi(ptf_liabi) & !mi(ratio_equ_liabi_row) & !mi(equ_liabi_dom) & !mi(ratio_equ_liabi_dom) & !mi(fdi_asset) & !mi(fdi_liabi)
generate q_share_foreign = min(3, ptf_liabi)                                                                               if cond==1
generate s_share_foreign = "EquitysOwnedByForeigners"         if cond==1
generate   share_foreign = ptf_liabi * ratio_equ_liabi_row / (equ_liabi_dom * ratio_equ_liabi_dom + fdi_asset - fdi_liabi) if cond==1
generate q_ratio_liab = min(3, q_ptf_liabi)                 if cond==1
generate s_ratio_liab = "EquitysOwnedByForeigners" if cond==1
generate   ratio_liab = ptf_liabi * ratio_equ_liabi_row / gdp

generate            a = fdi_asset - fdi_li

// Use liability ratio to exptrapolate share of foreign earnings (correlation around 0.85)
encode2 iso
xtset iso year
tsfill, full

gen x = log(ratio_liab)
gen y = logit(share_foreign)

corr x y

xtreg y x, re
predict yhat, xb
predict uhat, u
egen      u2 = mode(uhat), by(iso)
replace uhat = u2 if missing(uhat)
drop u2
replace uhat = 0 if missing(uhat)

replace yhat = yhat + uhat
gen q_yhat = 2            if !missing(yhat)
gen s_yhat = "regressionEquitysOwnedByForeigners" if !missing(yhat)

by iso: ipolate yhat year, gen(yhat2)
replace q_yhat = 2      if !missing(yhat2) & missing(yhat)
replace s_yhat = "ipol" if !missing(yhat2) & missing(yhat)
replace   yhat = yhat2
drop yhat2

replace q_share_foreign = q_yhat         if missing(share_foreign) & !missing(yhat)
replace s_share_foreign = s_yhat         if missing(share_foreign) & !missing(yhat)
replace   share_foreign = invlogit(yhat) if missing(share_foreign)

xtset, clear
decode2 iso

keep iso year *share_foreign
replace q_share_foreign = 0         if share_foreign > 1 & !missing(share_foreign)
replace s_share_foreign = "assumed" if share_foreign > 1 & !missing(share_foreign)
replace   share_foreign = 1         if share_foreign > 1 & !missing(share_foreign)
replace q_share_foreign = 0         if share_foreign < 0 & !missing(share_foreign)
replace s_share_foreign = "assumed" if share_foreign < 0 & !missing(share_foreign)
replace   share_foreign = 0         if share_foreign < 0 & !missing(share_foreign)

// Assume that foreign share was 0 in 1970 and then rose linearly (unless we know otherwise)
keep if year >= 1970 & year <= ($pastyear - 1)
replace q_share_foreign = 0         if year == 1970 & missing(share_foreign)
replace s_share_foreign = "assumed" if year == 1970 & missing(share_foreign)
replace   share_foreign = 0         if year == 1970 & missing(share_foreign)
gsort iso year
by iso: ipolate share_foreign year, gen(i)
replace q_share_foreign = 3
replace s_share_foreign = "ipol" if missing(share_foreign) & !missing(i)
replace   share_foreign = i
drop i
egen nnonmiss = total(!missing(share_foreign)), by(iso)
replace q_share_foreign = .  if nnonmiss <= 1
replace s_share_foreign = "" if nnonmiss <= 1
replace   share_foreign = .  if nnonmiss <= 1
drop nnonmiss

// Make extrapolation as a last resort
gsort iso -year
by iso: carryforward share_foreign, replace
gsort iso year
by iso: carryforward share_foreign, replace
replace q_share_foreign = .  if !missing(share_foreign) & missing(q_share_foreign)
replace s_share_foreign = "" if !missing(share_foreign) & missing(s_share_foreign)


// Make regional imputation as last resort
foreach level in undet un {
	kountry iso, from(iso2c) geo(`level')
	egen mean_share_foreign = mean(share_foreign), by(GEO year)
	replace q_share_foreign = 0                  if missing(share_foreign) & !missing(mean_share_foreign)
	replace s_share_foreign = "EquitysOwnedByForeignersreg" + GEO        if missing(share_foreign) & !missing(mean_share_foreign)
	replace   share_foreign = mean_share_foreign if missing(share_foreign)
	drop GEO NAMES_STD mean_share_foreign
}
assert !missing(share_foreign)

tempfile share_foreign
save "`share_foreign'"

// -------------------------------------------------------------------------- //
// Match with corporate savings
// -------------------------------------------------------------------------- //

use "$work_data/sna-series-finalized.dta", clear
cap drop _m 
keep if year >= 1970 & year <= ($pastyear - 1)
fillin iso year
drop _fillin

// There is data for Netherlands Antilles until 2009
// Curacao and Sint Maarten will be calculated based on GDP shares
merge m:1 iso using "$work_data/ratioCWSX_AN.dta", nogen 
foreach v in secco { 
bys year : gen aux`v'   = `v'          if iso == "AN"
bys year : egen   `v'AN = mode(aux`v')
}
foreach v in secco { 
	foreach c in CW SX {
		replace q_`v' = 1                    if iso == "`c'" & missing(`v') & !missing(ratio`c'_ANlcu) & !missing(`v'AN)
		replace s_`v' = "`v'(AN)_`c'/AN"              if iso == "`c'" & missing(`v') & !missing(ratio`c'_ANlcu) & !missing(`v'AN)
		replace   `v' = `v'AN*ratio`c'_ANlcu if iso == "`c'" & missing(`v')
	}
}	
drop aux* *AN *ANlcu

merge 1:1 iso year using "$work_data/import-core-country-codes-year-output.dta", nogen keepusing(corecountry TH) 
keep if corecountry == 1

// Extrapolate the value of net corporate savings
gsort iso -year
by iso: carryforward secco, replace
gsort iso year
by iso: carryforward secco, replace

replace q_secco = 1          if missing(q_secco) & !missing(secco) 
replace s_secco = "carryfor" if missing(      s_secco) & !missing(secco) 


keep iso year *secco

// Make regional imputation as last resort
foreach level in undet un {
	kountry iso, from(iso2c) geo(`level')
	egen mean_secco = mean(secco), by(GEO year)
	replace q_secco = 0            if missing(secco) & !missing(mean_secco)
	replace s_secco = "reg" + GEO if missing(secco) & !missing(mean_secco)
	replace   secco = mean_secco   if missing(secco)
	drop GEO NAMES_STD mean_secco
}

assert !missing(secco)

merge 1:1 iso year using "`share_foreign'", nogenerate

generate q_foreign_secco = min(3, q_secco)
generate s_foreign_secco = "secco_ratio"+s_share_foreign
generate   foreign_secco = secco*share_foreign

// Add GDP data in USD
merge 1:1 iso year using "`gdp'", nogenerate

generate q_ptfrp = min(3,q_foreign_secco)
generate s_ptfrp = "foreign-secco"
generate   ptfrp = foreign_secco

replace  foreign_secco = foreign_secco*gdp

keep iso year *foreign_secco *ptfrp

*last year is not fully covered, we simply carryforward the pastpastyear
drop                     if year == $pastyear
expand 2                 if year == $pastpastyear, gen(exp)
replace year = $pastyear if exp == 1
drop exp

save "`share_foreign'", replace

// -------------------------------------------------------------------------- //
// Use IMF CPIS database to redistribute foreign earnings
// -------------------------------------------------------------------------- //

*import delimited "$input_data_dir/imf-data/cpis/CPIS_04-04-2024 10-53-59-65.csv", clear encoding(utf8)
use "$wid_dir/Country-Updates/National_Accounts/imf-data/PIP-treated-$pastyear.dta", clear

keep if indicator=="P_F51_P_SCC_USD" // before: "I_L_E_T_T_BP6_DV_USD"
drop if countryname=="World"

// Identify country
countrycode countryname,             generate(iso1) from("imf data")
// Identify counterpart country
countrycode counterpart_countryname, generate(iso2) from("imf data")

// Split Curacao and Sint Marteen in counterpart country
expand 2            if counterpart_countryname == "Curaçao and Sint Maarten", gen(cw)
replace iso2 = "CW" if counterpart_countryname == "Curaçao and Sint Maarten" &    cw
replace iso2 = "SX" if counterpart_countryname == "Curaçao and Sint Maarten" &   !cw
drop cw
rename iso2 iso
merge n:1 iso year using "`gdp_cw_sx'", keep(master match) nogenerate keepusing(share_gdp)
rename iso iso2
* this medatata will be corrected later
replace  value = value*share_gdp if inlist(iso2, "CW", "SX")
drop share_gdp

// Rectangularize
tempfile cpis
save "`cpis'"

keep iso1
gduplicates drop
rename iso1 iso
tempfile iso1
save "`iso1'"

use "`cpis'", clear
keep iso2
gduplicates drop
rename iso2 iso
append using "`iso1'"
gduplicates drop
tempfile iso
save "`iso'"

clear
local nobs = ($pastyear - 1) - 1970 + 1
set    obs `nobs'
generate year = 1970 + _n - 1
cross using "`iso'"
rename iso iso1
cross using "`iso'"
rename iso iso2

gduplicates drop

merge 1:1 iso1 iso2 year using "`cpis'", nogenerate keepusing(value)

// Group together countries for which we have no net asset position
forvalue i = 1/2 {
	rename iso`i' iso
	merge n:1 iso using "`iso_netpos'", keep(master match)
	rename iso iso`i'
	
	replace iso`i' = "other" if _merge != 3
	drop _merge
}
drop if iso1 == "other" | iso2 == "other"
generate nmiss = !missing(value)
collapse (sum) value nmiss, by(iso1 iso2 year)
replace value = . if nmiss == 0
drop nmiss


/*
// Set bilateral stock to zero if there is data for the country, but not the country pair
generate nnmiss_value = !missing(value)
egen nnmiss = total(nnmiss_value), by(iso1 year)
replace value = 0 if missing(value) & nnmiss > 0
drop nnmiss nnmiss_value
*/

gen q_value=5 		if !missing(value)
gen s_value="IMFPIP" if !missing(value)

// Match with net foreign asset position
rename iso1 iso
merge n:1 iso year using "`netpos'", keepusing(*ptf_liabi *ratio_equ_liabi_row *ratio_equ_liabi_dom) keep(master match) nogenerate
rename iso iso1

rename iso2 iso
merge n:1 iso year using "`netpos'", keepusing(*ptf_asset *ratio_equ_asset_row) keep(master match) nogenerate
rename iso iso2

// Compute as a share of a country total foreign assets
replace q_value = min(3, q_value) if !mi(value) & !mi(ratio_equ_asset_row) & !mi(ratio_equ_liabi_row) 
*replace s_value = s_value
replace value = value*ratio_equ_asset_row*ratio_equ_liabi_row
gegen   total = total(value), by(iso1 year)
replace value = value/total

// Winsorize to avoid excessive adjustments
winsor2 value, replace cuts(0 95) by(year)

replace q_value = 0          if year == 1970
replace s_value = "assumed" if year == 1970
replace   value = 0          if year == 1970

// Interpolate/extrapolate
sort iso1 iso2 year
by iso1 iso2: ipolate value year, gen(value2)
replace q_value = 3      if missing(value) & !missing(value2)
replace s_value = "ipol" if missing(value) & !missing(value2)
replace   value = value2
drop value2

gsort iso1 iso2 -year
by iso1 iso2: carryforward value, replace

gsort iso1 iso2 year
by iso1 iso2: carryforward value, replace

replace q_value = 1             if !missing(value) & !missing(q_value)
replace s_value = "carryfor" if !missing(value) & !missing(     s_value)

keep iso1 iso2 year *value
rename iso1 iso

//added by gaston. rescaling value so shares add up to 1
bys year iso : egen check = total(value)
replace value = value/check 
bys year iso : egen check2 = total(value)
replace q_value = 0         if year == 1970
replace s_value = "assumed" if year == 1970
replace   value = 0         if year == 1970

merge n:1 iso year using "`share_foreign'", nogenerate keep(master match)

*problems with KY
replace q_value =.  if iso2 == "KY" & year >= 2011 
replace s_value ="" if iso2 == "KY" & year >= 2011 
replace   value =.  if iso2 == "KY" & year >= 2011 
sort iso iso2 year 
by iso iso2 : carryforward value if iso2 == "KY" & year >= 2011, replace 
replace q_value = 1              if iso2 == "KY" & year >= 2011 & !missing(value) & !missing(q_value)
replace s_value = "carryfor"     if iso2 == "KY" & year >= 2011 & !missing(value) & !missing(     s_value)

*replace q_foreign_secco = min(3,q_value)
*replace s_foreign_secco = s_value
replace foreign_secco = value*foreign_secco
gen check3 = foreign_secco/value 

*last year is not fully covered, we simply carryforward the pastpastyear
drop                     if year == $pastyear
expand 2                 if year == $pastpastyear, gen(exp)
replace year = $pastyear if  exp == 1
drop exp

*exit 1
egen    mode_s_foreign_secco = mode(s_foreign_secco), by(iso2 year) 
replace mode_s_foreign_secco = mode_s_foreign_secco + "mode"

collapse (sum) foreign_secco (median) q_foreign_secco (first) mode_s_foreign_secco, by(iso2 year)
rename mode_s_foreign_secco s_foreign_secco


// Merge GDP data
rename iso2 iso
merge 1:1 iso year using "`gdp'", nogenerate

generate q_ptfrr = q_foreign_secco
generate s_ptfrr = s_foreign_secco
generate ptfrr = foreign_secco/gdp
replace  q_ptfrr = 0  if missing(ptfrr)
replace  s_ptfrr = "" if missing(ptfrr)
replace    ptfrr = 0  if missing(ptfrr)
*drop foreign_secco
ren *foreign_secco *foreign_secco_r

merge 1:1 iso year using "`share_foreign'", nogenerate
replace q_ptfrp = 0          if year == 1970
replace s_ptfrp = "assumed" if year == 1970
replace   ptfrp = 0          if year == 1970
replace q_foreign_secco = 0         if year == 1970
replace s_foreign_secco = "assumed" if year == 1970
replace   foreign_secco = 0         if year == 1970

// reallocating some minor imbalances
bys year : egen totfs_r = total(foreign_secco_r)
bys year : egen totfs_p = total(foreign_secco)
gen dif = totfs_r - totfs_p

gen ratio_r = foreign_secco_r/ totfs_r
gen ratio_p = foreign_secco  / totfs_p
by year : replace foreign_secco_r = foreign_secco_r + abs(dif)*ratio_r if dif < 0
by year : replace foreign_secco   = foreign_secco   + abs(dif)*ratio_p if dif > 0
drop tot* ratio*
/*
gsort year -foreign_secco_r
by year : replace foreign_secco_r = foreign_secco_r + abs(dif) if _n == 1 & dif < 0
gsort year -foreign_secco
by year : replace foreign_secco = foreign_secco + abs(dif) if _n == 1 & dif > 0
*/

// change later
sort iso year
by iso: carryforward foreign_secco_r foreign_secco, replace
foreach v in foreign_secco_r foreign_secco {
	replace q_`v' = 1              if !missing(`v') & !missing(q_`v')
	replace s_`v' = "carryfor"    if !missing(`v') & !missing(      s_`v')
}

bys year : egen totfs_r2 = total(foreign_secco_r)
bys year : egen totfs_p2 = total(foreign_secco)
//assert totfs_r2 == totfs_p2

replace ptfrr = foreign_secco_r/gdp
replace q_ptfrr = 0         if year == 1970
replace s_ptfrr = "assumed" if year == 1970
replace   ptfrr = 0         if year == 1970

replace ptfrp = foreign_secco/gdp
replace q_ptfrp = 0 if year == 1970
replace s_ptfrp = "assumed" if year == 1970
replace   ptfrp = 0 if year == 1970

keep iso year *ptfrr *ptfrp

generate q_ptfrn = min(3, cond(ptfrr >= ptfrp, q_ptfrr, q_ptfrp))
generate s_ptfrn = "ptfrr,ptfrp"
generate   ptfrn = ptfrr - ptfrp

keep if year >= 1970

// expand 2 if year == ($pastyear - 1), gen(new)
// replace year = $pastyear if new
// drop new

sort iso year
drop if missing(ptfrn)

save "$work_data/reinvested-earnings-portfolio.dta", replace
/*
use "$work_data/reinvested-earnings-portfolio.dta", clear

generate ptfrn_perc = 100*ptfrn

graph set window fontface "Times"
histogram ptfrn_perc if inrange(ptfrn_perc, -2, 2), bin(200) percent ///
	xtitle("Reinvested Earnings on Foreign Portfolio Investment, Net (% of GDP)") ///
	ytitle("% of country/years") ///
	xlabel(-2 "-2%" -1.5 "-1.5%" -1 "-1%" -0.5 "-0.5%" 0 "0%" 0.5 "+0.5%" 1 "+1%" 1.5 "+1.5%" 2 "+2%") ///
	ylabel(0 "0%" 5 "5%" 10 "10%" 15 "15%" 20 "20%" 25 "25%") lstyle(none) color(gray) graphregion(margin(0 3 0 3)) xsize(2) ysize(1) scale(1.2)
graph export "$report_output/foreign-retained-earnings.pdf", replace
	
