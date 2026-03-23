//**############################################################################
//**############### Import Exchange Rate Do-File ###############################
//**############################################################################

*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
* Contents:

* 1. Import Data
*---------------------
*** PART O: Import Data with R

* 2. Aux Tables
*---------------------
*** PART A : WID Price Index........................................ --> `countires'
*** PART B : Currency Rates + `EUR' --> `merged'  
***        PART B.1 : + `countires' ...............-->`EUR'......... --> `merged' 
***        PART B.2 : + `merged'.................................... --> `xrate' 
*** PART C : WB Somalia ............................................ --> `somalia'
*** PART D : usd-exchange-rate-$year.csv............................ --> `ves'
*** PART E : retropolate-gdp.dta + gdp_usd_YUratio + price-index.dta --> `exrateyu'
*** PART F : retropolate-gdp.dta + price-index.dta+ gdp_usd_SUratio. --> `exratesu'
*** PART G : usd-exchange-rate-$year  .............................. --> `xrateunsna' 
*** PART H : exrate_TWD_USD  ....................................... --> `xratetwdusd'

* 3. Main Table
*----------------------
*** PART Main :  WB PI_PA.NUS.FCRF_DS2 --> exchange-rates.dta 
***        PART Main.1  :  + wb-metadata.dta                   (World Bank Data)
***        PART Main.2  :  + `Somalia'  + correction NG      (Somalia & Nigeria)
***        PART Main.3  :  + `ves'+ + New Ouguiya, IslandUSD and missings (Venezuela)
***        PART Main.4  :  + `merged'           (currencies of most recent year)
***        PART Main.5  :  + `exrateyu'                             (Yugoslavia)
***        PART Main.6  :  + `exratesu'                           (Soviet Union)
***        PART Main.7  :  + `xrateunsna'
***        PART Main.8  :  + xratetwdusd'                               (Taiwan)
***        PART Main.9  :  + NievasPiketty (2025) 
***        PART Main.10 : 
***        PART Main.11 : + import-country-codes-output.dta and carryforward last year 
***        PART Main.12 : + Generate data_quality and export data
***        PART Main.13 : + Generate and export metadata
*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



*-------------------------------------------------------------------------------
*---------------------  1. Import Data      ------------------------------------
*-------------------------------------------------------------------------------

// *********** PART O: Import Data with R   ************************************
// Import exchange rates via R
* Quandl data for exchange rates stopped at Feb 2018, we needed a new source to use



*-------------------------------------------------------------------------------
*---------------------  2. Aux Tables  -----------------------------------------
*-------------------------------------------------------------------------------

// *************** PART A : WID Price Index --> `'Countires **********************

// Import the WID to know the list of required currencies and associated countries
use "$work_data/price-index.dta", clear
keep iso currency year
drop if currency == ""
replace currency = "MRU" if iso == "MR"
*duplicates drop
drop if year <= 1998


tempfile countries
save "`countries'" 

// Remove some problematic currencies (to be dealt with later)
drop if (currency == "ERN")
drop if (currency == "SSP")
drop if (currency == "USD")
drop if (currency == "YUN")
drop if (currency == "BYN") 
//Having this drops after the save make them useless but dupplicates 
//the amount of USD countries. we loose countries applying them



// *************** PART B : Currency Rates + `EUR' --> `merged'    ***********

// Import exchange rates from openexchangerates.org (This data was downloaded 
//      with an R code in the same folder)
import delimited "$input_data_dir/currency-rates/currencies-rates-$pastyear.csv", clear delim(",") encoding("utf8")
drop if currency == "CYP"
drop if currency == "CUP"
*replace lcu_to_usd = substr(lcu_to_usd, 1, 1) + "." + substr(lcu_to_usd, 3, .)
*destring lcu_to_usd, replace

// Mauritania new ouguiya (MRU) = 10 old ouguiya (MRO)
replace lcu_to_usd = lcu_to_usd/10 if currency == "MRO"
drop if currency == "MRO" & year >= 2017
replace currency = "MRU" if currency == "MRO"
gduplicates tag year currency, gen(dup)
assert dup == 0
drop dup

* Gen source
gen source2=  "openexchangerate"

// ************** PART B.1 : -->`EUR'--> merged' *******************************
preserve
	// generate a only-EUR dataset 
	keep if currency == "EUR"
	merge 1:n currency year using "`countries'", nogenerate
	drop if currency != "EUR"
	tempfile EUR
	save "`EUR'"
restore 

drop if currency == "EUR" 
merge 1:n currency year using "`countries'"
drop if (_merge != 3) & (currency != "YUN" | year != $pastyear)
drop _merge
append using "`EUR'"

tempfile merged
save "`merged'" 

// *************** PART B.2 : `merged' --> `xrate'   ***************************
keep if year == $pastyear

*replace lcu_to_usd = 87.6462   if (currency == "YUN") // source: mataf.net, April 2021
replace lcu_to_usd = 76.7601    if (currency == "YUN") // source: mataf.net, June 2025
replace source = "mataf" if (currency == "YUN")

*replace lcu_to_usd = 1355.14   if (currency == "YER") & $pastyear == 2023 // taken from IMF WEO (GDP lcu/GDP USD)current prices
replace lcu_to_usd = 1355.116   if (currency == "YER") & $pastyear == 2024 // taken from IMF Data Exchange Rates
replace source="IMF"            if (currency == "YER") & $pastyear == 2024 

*replace lcu_to_usd = 380127.65 if (currency == "IRR") & $pastyear == 2023 // taken from IMF WEO (GDP lcu/GDP USD)current prices
replace lcu_to_usd = 42000      if (currency == "IRR") & $pastyear == 2024 // taken from IMF Data Exchange Rates
replace source="IMF"            if (currency == "IRR") & $pastyear == 2024

*replace lcu_to_usd = 2289.92   if (currency == "SSP") & $pastyear == 2023 // taken from IMF WEO (GDP lcu/GDP USD)current prices
replace lcu_to_usd = 2163.104   if (currency == "SSP") & $pastyear == 2024 // taken from IMF Data Exchange Rates
replace source="IMF"            if (currency == "SSP") & $pastyear == 2024 

assert $pastyear == 2024

// Generate exchange rates with euro and yuan
rename lcu_to_usd valuexlcusx999i

// Sanity checks
assert valuexlcusx999i == 1 if (currency == "USD")

reshape long value, i(iso) j(widcode) string

generate p = "pall"

tempfile xrate
save "`xrate'"

// *************** PART C : WB Somalia --> `somalia'   *************************
//--------------> Somalia
// Historical data in Somalia: WB and official exchange rate series are weird:
// use the UN SNA instead
import excel "$un_data/sna-main/exchange-rate/somalia/tableExPop.xlsx", clear firstrow
drop in 1
destring Year AMAexchangerate, replace
keep Year AMAexchangerate
rename Year year
rename AMAexchangerate value
generate currency = "SOS"
generate iso = "SO"
generate p = "pall"
generate widcode = "xlcusx999i"
expand 2 if year == 2018, gen(new)
replace value = 24300*(1/.97969919)/(1/.98220074) if new
replace year = 2019 if new
drop new
expand 2 if year == 2019, gen(new)
replace value = 24362.04727494*(1/.97969919)/(1/.98220074) if new
replace year = 2020 if new
drop new
generate source="UN_SNA"

tempfile somalia
save "`somalia'"

// *************** PART D :  usd-exchange-rate-$year.csv --> `ves' *************
//---------------> Venezuela
// VE: data for Bolivar digital from UN 
import delimited "$un_data/sna-main/exchange-rate/usd-exchange-rate-$year.csv", clear
keep if countryarea == "Venezuela (Bolivarian Republic of)"
destring year amaexchangerate, replace
keep year amaexchangerate
rename amaexchangerate value
gen iso = "VE"
gen currency = "VES"
gen widcode = "xlcusx999i"
generate source2="UN_SNA"

tempfile ves
sa `ves'

// *************** PART E : retropolate-gdp.dta + price-index.dta + gdp_usd_YUratio --> exrateyu 

//---------------> Former Yugoslavia
//	Former Yugoslavia
// We have 1990 ratio of GDP_USD from UN SNA, and applied that backward to former yugoslavan countries
// We have gdp_lcu in real terms from Blanchet, Chancel & Gethin (2018)
// We ued Yugoslavian price index for former countries, and get gdp_lcu in nominal terms
// Will divide gdp_lcu in nominal terms/GDP_USD to get an estimate of the exchange rate

u "$input_data_dir/snapshots/snapshot-SUYU-retropolate-gdp-output.dta",clear // Modif: Loop Solution
merge 1:1 iso year using "$work_data/price-index.dta", nogen keepusing(index)
gen yugosl = 1 if inlist(iso, "BA", "HR", "MK", "RS", "YU", "KS", "SI", "ME")
keep if yugosl == 1 & year >= 1970

foreach var in gdp {
gen `var'_idx = `var'*index
}

merge 1:1 iso year using "$input_data_dir/currency-rates/gdp_usd_YUratio", nogen keep(3)
gen double exrate_usd = gdp_idx/gdp_usd_YUratio
drop if iso == "YU"
keep iso year exrate_usd
gen source2="calculationfromGDP_yugosl"

tempfile exrateyu
sa `exrateyu', replace 

// *************** PART F : retropolate-gdp.dta + price-index.dta+ gdp_usd_SUratio --> `exratesu'
//---------------> Soviet Union
	//	Former USSR. ONLY APPLIES TO GEORGIA. other countries using the evolution of USSR exrate below
	// We have 1990 ratio of GDP_USD from UN SNA, and applied that backward to former USSR countries
	// We have gdp_lcu in real terms from interpolating GDP 1990 to GDP 1973 from Madisson. Before 1973 comes by applying shares
	// We ued USSR price index for former countries, and get gdp_lcu in nominal terms
	// Will divide gdp_lcu in nominal terms/GDP_USD to get an estimate of the exchange rate

u "$input_data_dir/snapshots/snapshot-SUYU-retropolate-gdp-output.dta",clear // Modif: Loop Solution
merge 1:1 iso year using "$work_data/price-index.dta", nogen
gen soviet = 1 if iso == "AM"
replace soviet = 1 if inlist(iso, "AZ", "BY", "KG", "KZ", "TJ", "TM")
replace soviet = 1 if inlist(iso, "UZ", "EE", "LT", "LV", "MD", "GE")
replace soviet = 1 if iso == "RU" | iso == "UA" | iso == "SU"
keep if soviet == 1 & year >= 1970

foreach var in gdp {
gen `var'_idx = `var'*index
}

merge 1:1 iso year using "$input_data_dir/currency-rates/gdp_usd_SUratio", nogen keep(3)
gen exrate_usd = gdp_idx/gdp_usd_SUratio
drop if iso == "SU"
keep iso year exrate_usd
gen source2="calculationfromGDP_soviet"

tempfile exratesu
sa `exratesu', replace 

// *************** PART G : usd-exchange-rate-$year --> `xrateunsna' *************
// Complete the missing exchange rates using UN SNA data

* Note: From 2025 update, some observations from SS and ME are missing so we call 
*       them from previous versions, here, "-2024" can be retained.
import delimited "$un_data/sna-main/exchange-rate/usd-exchange-rate-2024.csv", clear 
keep if (countryarea=="South Sudan" & year<2008) | (countryarea=="Montenegro" & year<1990)
drop if unit=="..."

gen old=1
tempfile missing
save `missing'

import delimited "$un_data/sna-main/exchange-rate/usd-exchange-rate-$year.csv", clear 

append using "`missing'"


duplicates tag countryarea year, gen(dup)
drop if dup!=0 & old!=1 & unit=="..."
duplicates tag countryarea year, gen(dup2)
assert dup2==0
drop dup* old

ren (countryarea amaexchangerate imfbasedexchangerate) (country amaxrt imfxrt)

gen soviet = 1 if country == "Armenia"
replace soviet = 1 if country == "Azerbaijan"
replace soviet = 1 if country == "Belarus"
replace soviet = 1 if country == "Former USSR"
replace soviet = 1 if country == "Georgia"
replace soviet = 1 if country == "Kazakhstan"
replace soviet = 1 if country == "Kyrgyzstan"
replace soviet = 1 if country == "Republic of Moldova"
replace soviet = 1 if country == "Russian Federation"
replace soviet = 1 if country == "Tajikistan"
replace soviet = 1 if country == "Turkmenistan"
replace soviet = 1 if country == "Ukraine"
replace soviet = 1 if country == "Uzbekistan"
replace soviet = 0 if missing(soviet)

gen yugosl = 1 if country == "Bosnia and Herzegovina"
*replace yugosl = 1 if country == "Croatia"
replace yugosl = 1 if country == "Former Yugoslavia"
replace yugosl = 1 if country == "Republic of North Macedonia"
replace yugosl = 1 if country == "Serbia"
replace yugosl = 0 if missing(yugosl)

gen euro = 1 if inlist(country, "Estonia", "Kosovo", "Lithuania", "Latvia", "Slovenia", "Slovakia", "Croatia")
replace euro = 0 if missing(euro)

*extrapolating variation rates of main currency to the post-union currency
encode country, gen(i)
destring year, replace
xtset i year
destring imfxrt, replace force
destring amaxrt, replace force

* Gen source
generate source2="UN_SNA" if !missing(amaxrt) | !missing(imfxrt)

// Soviet
* Calculate yearly growth
foreach xr in ama imf {
xtset i year
gen double growth_`xr'_soviet = (`xr'xrt - l1.`xr'xrt)/l1.`xr'xrt if country == "Former USSR"
	bys year : egen aux`xr'soviet = max(growth_`xr'_soviet) 
}
/*
	// using 1993 values for 1990, 1991 and 1992
xtset i year
foreach i in 1992 1991 1990 {
	replace imfxrt = f.imfxrt if year == `i' & soviet == 1 & country != "Former USSR"
}
*/

* Project values backwards
foreach xr in ama imf {
	gen aux1`xr' = `xr'xrt 
	gen aux2`xr' = aux1`xr'/(1+aux`xr'soviet) if year == 1990 & soviet == 1

	xtset i year
	forvalues i = 1989(-1)1970 { 
		replace aux1`xr' = f.aux2`xr'                 if year == `i' & soviet == 1
		replace aux2`xr' = aux1`xr'/(1+aux`xr'soviet) if year == `i' & soviet == 1
	}
}

* Input values
foreach xr in ama imf {
	gen double extrap_`xr'_soviet = 1   if missing(`xr'xrt) & soviet == 1
	replace extrap_`xr'_soviet = 0      if missing(extrap_`xr'_soviet)
	replace `xr'xrt = aux1`xr'          if extrap_`xr'_soviet == 1
	replace source2="extrapolated_ratio_soviet" if extrap_`xr'_soviet == 1
}
drop aux* growth*

// Yugoslavia
* Calculate yearly growth
foreach xr in ama imf {
	xtset i year
	gen double growth_`xr'_yug = (`xr'xrt - l1.`xr'xrt)/l1.`xr'xrt if country == "Former Yugoslavia"
	bys year : egen aux`xr'yug = max(growth_`xr'_yug) 
}

* Project values backwards
foreach xr in ama imf {
	gen double aux1`xr' = `xr'xrt 
	gen double aux2`xr' = aux1`xr'/(1+aux`xr'yug) if year == 1990 & yugosl == 1

	xtset i year
	forvalues i = 1989(-1)1970 { 
		replace aux1`xr' = f.aux2`xr'              if year == `i' & yugosl == 1
		replace aux2`xr' = aux1`xr'/(1+aux`xr'yug) if year == `i' & yugosl == 1
	}
}

* Input values
foreach xr in ama imf {
	gen double extrap_`xr'_yugosl = 1   if missing(`xr'xrt) & yugosl == 1
	replace extrap_`xr'_yugosl = 0      if missing(extrap_`xr'_yugosl)
	replace `xr'xrt = aux1`xr'          if extrap_`xr'_yugosl == 1
	replace source2="extrapolated_ratio_yugosl" if extrap_`xr'_yugosl == 1
}
drop aux* growth*

// Yemen
* Calculate yearly growth 
foreach xr in ama imf {
xtset i year
gen double growth_`xr'_yem = (`xr'xrt - l1.`xr'xrt)/l1.`xr'xrt if country == "Yemen: Former Yemen Arab Republic"
	bys year : egen aux`xr'yem = max(growth_`xr'_yem) 
}

* Project values backwards
foreach xr in ama imf {
	gen double aux1`xr' = `xr'xrt 
	gen double aux2`xr' = aux1`xr'/(1+aux`xr'yem) if year == 1989 & country == "Yemen"

	xtset i year
	forvalues i = 1988(-1)1970 { 
		replace aux1`xr' = f.aux2`xr'              if year == `i' & country == "Yemen"
		replace aux2`xr' = aux1`xr'/(1+aux`xr'yem) if year == `i' & country == "Yemen"
	}
}

* Input values
foreach xr in ama imf {
	gen double extrap_`xr'_yem = 1      if missing(`xr'xrt) & country == "Yemen"
	replace extrap_`xr'_yem = 0         if missing(extrap_`xr'_yem)
	replace `xr'xrt = aux1`xr'          if extrap_`xr'_yem == 1
	replace source2="extrapolated_ratio_yemen" if extrap_`xr'_yem == 1
}
drop aux* growth*


// Euro before 1990 for some countries 
* Calculate average yearly growth
foreach xr in ama imf {
	bys year : egen avg_`xr'xrt = mean(`xr'xrt) if unit == "Euro"
	xtset i year
	gen double growth_`xr'_eu = (avg_`xr'xrt - l1.avg_`xr'xrt)/l1.avg_`xr'xrt if unit == "Euro"
	bys year : egen aux`xr'eu = max(growth_`xr'_eu) 
}

* Project values backwards
foreach xr in ama imf {
	gen double aux1`xr' = `xr'xrt 
	gen double aux2`xr' = aux1`xr'/(1+aux`xr'eu) if year == 1990 & euro == 1

	xtset i year
	forvalues i = 1989(-1)1970 { 
		replace aux1`xr' = f.aux2`xr'             if year == `i' & euro == 1
		replace aux2`xr' = aux1`xr'/(1+aux`xr'eu) if year == `i' & euro == 1
	}
}

* Input values
foreach xr in ama imf {
	gen double extrap_`xr'_eu = 1       if missing(`xr'xrt) & euro == 1
	replace extrap_`xr'_eu = 0          if missing(extrap_`xr'_eu)
	replace `xr'xrt = aux1`xr'          if extrap_`xr'_eu == 1
	replace source2="extrapolated_ratio_euro" if extrap_`xr'_eu == 1
}
drop aux* growth*

// Exend the unit currency for the inputed values
replace unit = "" if extrap_imf_soviet == 1 | extrap_imf_yugosl == 1 | ///
					 extrap_imf_yem == 1 | extrap_imf_eu == 1
gsort country -year 
by country : carryforward unit if extrap_imf_soviet == 1 | extrap_imf_yugosl == 1 | ///
								  extrap_imf_yem == 1 | extrap_imf_eu == 1, replace

// generating iso2 variable
ren country countryname
kountry country, from(other) stuck
ren _ISO3N_ iso3_n
kountry iso3_n, from(iso3n) to(iso2c)
ren _ISO2C_ country
replace country = "CZ" if countryname == "Czechia"
replace country = "CS" if countryname == "Former Czechoslovakia"
replace country = "SS" if countryname == "Former Sudan"
replace country = "YU" if countryname == "Former Yugoslavia"
replace country = "MK" if countryname == "Republic of North Macedonia"
*replace country = "YE" if countryname == "Yemen: Former Yemen Arab Republic"
replace country = "SU" if countryname == "Former USSR"
replace country = "KS" if countryname == "Kosovo"
replace country = "CW" if countryname == "CuraÃ§ao"
replace country = "CW" if countryname == "CuraĂ§ao" // For MAC laptops interpretor
replace country = "SX" if countryname == "Sint Maarten (Dutch part)"
replace country = "AN" if countryname == "Former Netherlands Antilles"
replace country = "BO" if countryname == "Bolivia (Plurinational State of)"
replace country = "HK" if countryname == "China, Hong Kong SAR"
replace country = "TR" if countryname == "TĂźrkiye"
replace country = "VE" if countryname == "Venezuela (Bolivarian Republic of)"
replace country = "TZ" if countryname == "United Republic of Tanzania: Mainland"
replace country = "CI" if countryname == "CĂ´te d'Ivoire"
replace country = "CV" if countryname == "Cabo Verde"
replace country = "SZ" if countryname == "Kingdom of Eswatini" 
replace country = "PS" if countryname == "State of Palestine" 
replace country = "GB" if countryname == "United Kingdom of Great Britain and Northern Ireland"

tab countryname if missing(country)
// Curacao and Sint Marteen using Former Netherlands Antilles
drop if country == "CW" & year < 1994
expand 2 if (country == "AN") & inrange(year, 1970, 1993), generate(newobsCW)
replace country = "CW"      if newobsCW
replace source = country+ "_assumed_as_" + source if newobsCW

drop if country == "SX" & year < 2000
expand 2 if (country == "AN") & inrange(year, 1970, 1999), generate(newobsSX)
replace country = "SX"        if newobsSX
replace source = country+"_assumed_as_"+ source if newobsSX
drop newobs* 

drop if missing(country) | unit == "..."
drop if countryname == "Former Sudan" & year >= 1995
drop if countryname == "South Sudan" & year < 1995
drop if inlist(countryname, "Yemen: Former Yemen Arab Republic")
rename country iso

tempfile xrateunsna
save `xrateunsna', replace


// *************** PART H : + exrate_TWD_USD --> `xratetwdusd' *****************
//-----------------> Taiwan
// Taiwan from FRED

import excel "$input_data_dir/currency-rates/exrate_TWD_USD", clear firstrow sheet("Annual")
gen year = year(DATE)
ren FXRATETWA618NUPN xrate_twd_usd
keep year xrate_twd_usd
gen iso = "TW"
generate source2="FRED"
tempfile xratetwdusd
sa `xratetwdusd', replace

*-------------------------------------------------------------------------------
*---------------------  3. Main Table   ----------------------------------------
*-------------------------------------------------------------------------------

// *************** PART Main :  WB PI_PA.NUS.FCRF_DS2 --> exchange-rates.dta  **

// WORLD BANK exchange rates for historical series
// Import exchange rates series from the World Bank
import delimited "$wb_data/exchange-rates/API_PA.NUS.FCRF_DS2_en_csv_v2_$pastyear.csv", ///
clear encoding("utf8") rowrange(3) varnames(4) delim(",")

// Rename year variables
cap dropmiss
cap dropmiss, force
foreach v of varlist v* {
	local year: variable label `v'
	rename `v' value`year'
}
cap drop value$pastyear

// Apply Euro area exchange rate to Euro area countries after 1999
* Values are missing when country joins Euro, so one replaces all missing values
local lastyear= $pastyear - 1
forval i=1999/`lastyear'{
	gen x=value`i' if countryname == "Euro area"
	egen e`i'=mean(x)
	drop x
	replace value`i'=e`i' if  (inlist(countryname, "Germany", "Austria", "Belgium", "Spain", "Finland", "France") ///
							 | inlist(countryname, "Ireland", "Italy", "Luxembourg", "Netherlands", "Portugal") ///
							 | inlist(countryname, "Greece", "Slovenia", "Cyprus", "Malta", "Slovak Republic", "Estonia") ///
							 | inlist(countryname, "Latvia", "Lithuania","Croatia")) ///
							 & value`i'==.
}
drop e*


// Identify countries
replace countryname = "Swaziland"      if countryname == "Eswatini"
replace countryname = "Macedonia, FYR" if countryname == "North Macedonia"
replace countryname = "Korea, Dem. People's Rep." if countryname == "Korea, Dem. People's Rep."
countrycode countryname, generate(iso) from("wb")


// *************** PART Main.1 : + wb-metadata.dta ******************************

// Add currency from the metadata
merge n:1 countryname using "$work_data/wb-metadata.dta", ///
	keep(master match) nogenerate //Regions are droppped

	// Identify currencies
replace currency = "vietnamese dong" if iso == "VN"
replace currency = "turkmenistan manat" if currency == "New Turkmen manat"
replace currency = "democratic people's republic of korean won" if countryname == "Korea, Dem. People's Rep."  // compared to xrate from 2020, KP used to have the same xrate as KR from 1999 onwards
currencycode currency, generate(currency_iso) iso2c(iso) from("wb")

drop currency
rename currency_iso currency

// Reshape
drop countryname countrycode indicatorname indicatorcode fiscalyearend
gen widcode = "xlcusx999i"
gen p = "pall"
cap drop value
greshape long value, i(iso currency widcode p) j(year)
drop if mi(value)
order iso widcode currency value year p

// Drop euro before year where countries joined
drop if currency == "EUR"    & year<1999
drop if currency == "EUR"    & iso == "GR" 			   & year<2001
drop if currency == "EUR"    & iso == "SI"             & year<2007
drop if currency == "EUR"    & inlist(iso,"CI","MT")   & year<2001
drop if currency == "EUR"    & iso == "MT"             & year<2008
drop if currency == "EUR"    & iso == "CY"             & year<2008
drop if currency == "EUR"    & iso == "SK"             & year<2009
drop if currency == "EUR"    & iso == "EE" 			   & year<2011
drop if currency == "EUR"    & iso == "LV" 			   & year<2014
drop if currency == "EUR"    & iso == "LT" 			   & year<2015
drop if currency == "EUR"    & iso == "HR" 			   & year<2023

// Drop Syria before $pastyear (strange values)
drop if inlist(iso, "SY") & (year<$pastyear)

//-------------------------------------------------------
preserve
	* Note: this file is usefull cor correcting the data of the WB's PPP for 
	* 		special USD country cases
	merge 1:1 iso currency year using "`merged'", update noreplace keepusing(lcu_to_usd) nogenerate
	keep if inlist(iso, "ZW", "SV", "LR", "EC")
	sort iso year 
	
	replace value= lcu_to_usd if missing(value)
	
	fillin iso year
	replace value=3266.33 if iso=="ZW" & year==2024 & missing(value) // WB data
	ipolate value year, gen (value2)
	replace value=value2 if missing(value)
	
	keep iso year value 
	order iso year value 
	rename value exrate_usd
	
	label data "Generated by import-exchange-rates.do"
	save "$work_data/exchange-rates-cases.dta",replace
restore
//-------------------------------------------------------

*Gen source
generate source="WB"

// Replace exchange rate by 1 for El Salvadore and Liberia and Zimbabwe (series in dollars)
replace value = 1 if inlist(iso, "ZW", "SV", "LR", "EC")   

replace source= currency+"_assumed_"+source if inlist(iso, "ZW", "SV", "LR", "EC")   

append using "`xrate'"
replace source=source2 if missing(source)
drop source2

// Fix in Zambia
replace value = value/1000 if iso == "ZM" & year < 1972

// Missing data (MR, 2004)
expand 2 if iso == "MR" & year == 2003, gen(new)
replace value = .   if new
replace year = 2004 if new
ipolate value year  if iso == "MR" & inrange(year, 2003, 2005), gen(i)
replace source = "interpolated"  if new
replace value = i   if new
drop new i

// *************** PART Main.2 :  + `Somalia' + correction NG ******************

// Fix Somalia using UN data
merge 1:1 iso year widcode using "`somalia'", nogenerate update replace

// Manual fix for Nigeria, 1994-1998 (official rate does not reflect reality, use
// backward PARE estimations from the UN)
replace value = 35.743628082917010 if iso == "NG" & year == 1994 & widcode == "xlcusx999i"
replace value = 61.407306954281104 if iso == "NG" & year == 1995 & widcode == "xlcusx999i"
replace value = 76.278096344699490 if iso == "NG" & year == 1996 & widcode == "xlcusx999i"
replace value = 78.775837490581820 if iso == "NG" & year == 1997 & widcode == "xlcusx999i"
replace value = 82.580278068470160 if iso == "NG" & year == 1998 & widcode == "xlcusx999i"

replace source = "UN_PARE" if iso == "NG" & inrange(year, 1994,1998) & widcode == "xlcusx999i"
// *************** PART Main.3 :  + `ves' + Fix New Ouguiya, Islands' USD and missings **

drop if iso == "VE"
append using `ves'

// Introduction of the new Ouguiya in 2018
replace currency = "MRU"    if currency == "MRO"

greshape wide value, i(iso year p currency) j(widcode) string

fillin iso year
replace currency = "USD"                if iso == "ZW"
replace valuexlcusx999i = 1             if iso == "ZW"
replace p = "pall"                      if iso == "ZW"

egen source_aux = mode(source), by(year currency)
replace source =  currency + "_assumed_"+ source_aux if iso == "ZW"
drop if _fillin & iso != "ZW"
drop _fillin source_aux

// Bonaire, Sint Eustatius and Saba series is in USD
drop if iso == "BQ"
expand 2 if (iso == "ZW"), generate(newobsBQ)
replace iso = "BQ"          if newobsBQ
replace currency = "USD"    if iso == "BQ"
replace valuexlcusx999i = 1 if iso == "BQ"
*replace p = "pall"          if iso == "BQ"

// Fixing Gibraltar
drop if iso == "GI"
expand 2 if (iso == "GG"), generate(newobsGI)
replace iso = "GI" if newobsGI
drop newobs*

// Fix countries with missing values
fillin iso year
egen currency2 = mode(currency), by(iso)
replace currency = currency2
drop currency2
replace p = "pall"
egen value2 = mean(valuexlcusx999i), by(year currency)
egen source_aux = mode(source), by(year currency)
replace source = currency + "_assumed_"+ source_aux   if missing(valuexlcusx999i) & !missing(value2)
replace valuexlcusx999i = value2       if missing(valuexlcusx999i)
drop value2 _fillin source_aux


// *************** PART Main.4 :  + `merged' **************************************

merge 1:1 iso currency year using "`merged'", update keepusing(lcu_to_usd source2) nogenerate
replace source = source2            if  missing(valuexlcusx999i) & !missing(lcu_to_usd)
replace valuexlcusx999i = lcu_to_usd if missing(valuexlcusx999i)
drop lcu_to_usd source2

drop if iso == "ZW" & currency == "ZWD"

 
// *************** PART Main.5 :  + `exrateyu' *********************************
	
drop if iso == "HR" & currency == "HRK"
merge 1:1 iso year using `exrateyu', nogenerate keep(master match) 

replace source = source2            if missing(valuexlcusx999i) & !missing(exrate_usd)
replace valuexlcusx999i = exrate_usd if missing(valuexlcusx999i) & !missing(exrate_usd)
drop exrate_usd  source2


	
// *************** PART Main.6 : + `exratesu' **********************************

merge 1:1 iso year using `exratesu', nogenerate keep(master match)


*replace valuexlcusx999i = exrate_usd if missing(valuexlcusx999i) & !missing(exrate_usd) & iso == "GE"
drop exrate_usd source2


// *************** PART D.7 : + `xrateunsna' *************************************

merge 1:1 iso year using `xrateunsna', keepusing(imfxrt amaxrt soviet yugosl source2)

drop if _m == 2 & iso != "HR"
replace currency = "EUR" if iso == "HR"
drop _m 
gen flagexrate = 1 if missing(valuexlcusx999i)
replace flagexrate = 0 if missing(flagexrate)

replace valuexlcusx999i = amaxrt if currency == "EUR" & year < 1999
replace valuexlcusx999i = amaxrt if year >= 1990 & year <= 1994 & soviet == 1
replace valuexlcusx999i = amaxrt if iso == "UZ"	
replace valuexlcusx999i = amaxrt if iso == "GW"	
replace valuexlcusx999i = amaxrt if yugosl == 1 & year >= 1990
replace valuexlcusx999i = amaxrt if year > 1994 & year <= 2001 & iso == "TM" // Turkmenistan's exchange rate is preferred from UN SNA than from WB WDI
replace valuexlcusx999i = amaxrt if iso == "CD" & !missing(amaxrt) // if we use the imfxrt Congo gets and incredible jump in gdp_usd in 2000s
replace valuexlcusx999i = amaxrt if iso == "GN" & !missing(amaxrt) // we need to use ama because if not there is a disparity pre and post 1986
replace valuexlcusx999i = amaxrt if iso == "IQ" & !missing(amaxrt) // & year < 1991 // we need to use ama because of inconsistency pre 2003. We are comparing with WB whenever cases are critical
*replace valuexlcusx999i = amaxrt if iso == "IQ" & !missing(amaxrt) & year >= 1991 // we need to use ama because of inconsistency pre 2003
replace valuexlcusx999i = .      if iso == "IR" & year >= 2017
replace valuexlcusx999i = amaxrt if iso == "IR" & !missing(amaxrt) & year >= 1987 // 1990 is problematic if not
replace valuexlcusx999i = amaxrt if iso == "MM" & !missing(amaxrt) // evolution does not coincide with WB if not
replace valuexlcusx999i = amaxrt if iso == "NI" & !missing(amaxrt) // evolution does not coincide with WB if not. problematic year 1987: 0.00000014 from WB gdp_lcu/gdp_usd. we have the same gdp_lcu and the same exrate but values didn't aligned. apparently WB sometimes don't use the exrate they publish
replace valuexlcusx999i = amaxrt if iso == "PL"  // evolution does not coincide with WB if not
replace valuexlcusx999i = amaxrt if iso == "SO" // & year == 2021 // huge peak in 2021 if not
replace valuexlcusx999i = amaxrt if iso == "SR" // crazy peak if not
replace valuexlcusx999i = amaxrt if iso == "SS" & !missing(amaxrt)
replace valuexlcusx999i = amaxrt if iso == "SY" & !missing(amaxrt)
replace valuexlcusx999i = amaxrt if iso == "UG" & !missing(amaxrt)
replace valuexlcusx999i = amaxrt if iso == "YE" & !missing(amaxrt)
replace valuexlcusx999i = amaxrt if iso == "KP" & !missing(amaxrt)
replace valuexlcusx999i = amaxrt if iso == "AF" & !missing(amaxrt)
replace valuexlcusx999i = amaxrt if iso == "BG" & !missing(amaxrt)
replace valuexlcusx999i = amaxrt if iso == "ER" & !missing(amaxrt)
replace valuexlcusx999i = amaxrt if iso == "GH" & !missing(amaxrt)
replace valuexlcusx999i = amaxrt if iso == "KH" & !missing(amaxrt)
replace valuexlcusx999i = amaxrt if iso == "LA" & !missing(amaxrt)
replace valuexlcusx999i = amaxrt if iso == "LB" & !missing(amaxrt)
replace valuexlcusx999i = amaxrt if iso == "MN" & !missing(amaxrt)
replace valuexlcusx999i = amaxrt if iso == "RO" & !missing(amaxrt)
replace valuexlcusx999i = amaxrt if iso == "VN" & !missing(amaxrt)
replace valuexlcusx999i = amaxrt if iso == "TJ" & !missing(amaxrt)
replace valuexlcusx999i = amaxrt if iso == "CW" & !missing(amaxrt)
replace valuexlcusx999i = amaxrt if iso == "SX" & !missing(amaxrt)
replace valuexlcusx999i = amaxrt if iso == "ER" & !missing(amaxrt) & inrange(year, 1990, 1992) 
replace valuexlcusx999i = amaxrt if iso == "SD" & !missing(amaxrt) & year >= 2020
replace valuexlcusx999i = amaxrt if iso == "SL"
// from the ratio of gdp_lcu/gdp_usd from WB WDI to fix problematic years for Georgia. gdp_usd WB is calculated using their growth rate before 1990
/*
replace valuexlcusx999i = 0.000001323856 if iso == "GE" & year == 1975
replace valuexlcusx999i = 0.000001327758 if iso == "GE" & year == 1976
replace valuexlcusx999i = 0.00000134685 if iso == "GE" & year == 1977
replace valuexlcusx999i = 0.00000135122 if iso == "GE" & year == 1978
replace valuexlcusx999i = 0.00000138821 if iso == "GE" & year == 1979
replace valuexlcusx999i = 0.00000140190 if iso == "GE" & year == 1980
replace valuexlcusx999i = 0.00000144960 if iso == "GE" & year == 1981
replace valuexlcusx999i = 0.00000150204 if iso == "GE" & year == 1982
replace valuexlcusx999i = 0.00000146224 if iso == "GE" & year == 1983
replace valuexlcusx999i = 0.00000147103 if iso == "GE" & year == 1984
replace valuexlcusx999i = 0.00000140176 if iso == "GE" & year == 1985
replace valuexlcusx999i = 0.00000149385 if iso == "GE" & year == 1986
replace valuexlcusx999i = 0.00000152877 if iso == "GE" & year == 1987
replace valuexlcusx999i = 0.00000148910 if iso == "GE" & year == 1988
*/
replace source = source2         if !missing(valuexlcusx999i) & missing(source)


replace source = source2         if missing(valuexlcusx999i)	
replace valuexlcusx999i = amaxrt if missing(valuexlcusx999i)

gen auxcsk = valuexlcusx999i if iso == "CS"
gen auxsourcsk = source      if iso == "CS"

bys year : egen maxauxcsk  = max(auxcsk)
bys year : egen sourauxcsk = mode(auxsourcsk) 

replace source = sourauxcsk         if iso == "CZ" & missing(valuexlcusx999i)
replace valuexlcusx999i = maxauxcsk if iso == "CZ" & missing(valuexlcusx999i)

drop imfxrt amaxrt flagexrate auxcsk maxauxcsk soviet yugosl sourauxcsk

*missing years for CW
gen aux = valuexlcusx999i if iso == "SX"
gen auxsour = source2 if iso == "SX"

bys year : egen aux2 = mode(aux)
bys year : egen auxsour2 = mode(auxsour)

replace source = auxsour2        if iso == "CW" & mi(valuexlcusx999i)
replace valuexlcusx999i = aux2   if iso == "CW" & mi(valuexlcusx999i)

drop source2 aux*
/*
// replacing problematic Iraq data <= 2003 from WB WDI data
preserve
	import excel "$input_data_dir/currency-rates/exrate_IQ_USD_WDI", clear firstrow cellrange(A3)
	gen n = _n 
	foreach var in A B C D {
		replace `var' = subinstr(`var', " ", "", .) if _n == 1
	}
	
	ds A B C D n, not
	foreach var in `r(varlist)' {
		replace `var' = "v" + `var' if _n == 1
	}
	drop n
	renvars , map(word(@[1], 1))
	keep if CountryName == "Iraq"
	reshape long v, i(CountryName) j(year) string
	ren (v) (xrate_iq_usd) 
	gen iso = "IQ"
	keep iso year xrate_iq_usd
	destring year, replace
	destring xrate_iq_usd, replace
	keep if year >= 1970
tempfile xrateiqus
sa `xrateiqus', replace
restore
merge 1:1 iso year using `xrateiqus'
drop if _m == 2
drop _m 
replace valuexlcusx999i = xrate_iq_usd if iso == "IQ" & year < 2003
drop xrate_iq_usd 
*/

* ------- Compleating YUN ------------------------------------------------------
sort iso year 
gen currency3=currency
replace currency3="YUN" if inlist(iso,"RS","MK")
egen value3 = mean(valuexlcusx999i), by(year currency3)
bysort iso (year): gen double for_value3=value3[_n+1]

gen double value4 = (value3 - for_value3) / for_value3 if iso=="YU"

gsort iso -year 
by iso: gen value5 = sum(value4) if !mi(value4)

gen value6 = valuexlcusx999i if year==$pastyear
egen value7=mean(value6), by(iso)

gen double value8=value7*(1+value5)
replace value8=value3 if value5<-1

* data we are sure about from mataf.net, last observation fo each year
/*
replace value8=80.0274 if currency=="YUN" & year==2015
replace value8=83.8404 if currency=="YUN" & year==2016
replace value8=73.8245 if currency=="YUN" & year==2017
replace value8=76.2598 if currency=="YUN" & year==2018
replace value8=78.2429 if currency=="YUN" & year==2019
replace value8=71.7148 if currency=="YUN" & year==2020
replace value8=77.3620 if currency=="YUN" & year==2021
replace value8=89.1162 if currency=="YUN" & year==2022
*/
replace source = source + "_RS_MK" if missing(valuexlcusx999i) & iso=="YU"
replace valuexlcusx999i = value8 if missing(valuexlcusx999i) & iso=="YU"

drop value3-value8 currency3
* ------- Compleating YUN ------------------------------------------------------

// *************** PART Main.8 : + xratetwdusd' ********************************

merge 1:1 iso year using `xratetwdusd', nogenerate keepusing(xrate_twd_usd source2) keep(master match)

replace source = source2 if missing(valuexlcusx999i)
replace valuexlcusx999i = xrate_twd_usd if missing(valuexlcusx999i)

drop xrate_twd_usd source2

// *************** PART Main.9 : + NievasPiketty (2025)  ********
merge 1:1 iso year using "$work_data/nievaspiketty2025_xrate.dta", nogenerate keepusing(xrate_usd)
gen source2="np" if !missing(xrate_usd)

replace source= source2 if !missing(xrate_usd)
replace valuexlcusx999i= xrate_usd if !missing(xrate_usd)
drop xrate_usd source2

drop if missing(valuexlcusx999i)

// fill p and currency
sort iso year
replace p = "pall" if missing(p)
egen currency2 = mode(currency), by(iso)
replace currency = currency2 if missing(currency)
drop currency2


replace p = "pall" if iso=="HR" // Little adjusment for filling the data


greshape long value, i(iso year p currency) j(widcode) string
drop if mi(value)
sort iso widcode year

fillin iso widcode year

// *************** PART Main.11 : + import-country-codes-output.dta and carryforward last year ****

merge m:1 iso using "$work_data/import-country-codes-output.dta", nogen 
*drop titlename shortname region1 region2 region3 region4 region5 TH
drop if _fillin == 1 & corecountry != 1 
drop if _fillin == 1 & year < 1970 

sort iso widcode year
replace source = "carryforward"                if missing(value) & year == $pastyear & corecountry == 1
by iso widcode : carryforward value p currency if missing(value) & year == $pastyear & corecountry == 1, replace

// Drop Iraq before 2003 (problematic data)
// Gaston: I've replaced it with WDI data for year <= 2003 in line
// drop if iso == "IQ" & year < 2003

recast double value
drop if missing(value)

// *************** PART Main.12 : + Generate data_quality and export data ***

* gen data suality
gen data_quality=.

replace data_quality=5 if strpos(source,"WB")  | strpos(source,"openexchangerate") | ///
						  strpos(source,"IMF") | strpos(source,"UN_SNA") | strpos(source,"mataf")
replace data_quality=4 if strpos(source,"np")
replace data_quality=3 if strpos(source,"interpolated")
replace data_quality=2 if strpos(source,"carryforward")
replace data_quality=1 if strpos(source,"extrapolated_ratio") | strpos(source,"calculationfromGDP")
*replace data_quality=0 if

assert !missing(data_quality)
assert widcode=="xlcusx999i"

rename value exrate_usd

preserve
	drop source widcode
	recast int year	
	recast double exrate_usd

	label data "Generated by import-exchange-rates.do"
	save "$work_data/exchange-rates.dta", replace

	/*
	keep   if widcode == "xlcusx999i"
	rename    value exrate_usd
	label data "Generated by import-exchange-rates.do"
	save "$work_data/USS-exchange-rates.dta", replace
	*/
restore

// *************** PART Main.13 : + Generate and export metadata ***
keep iso year source widcode currency

replace widcode = substr(widcode,1,6)
rename (widcode source) (sixlet source_0)

bysort iso source (year): egen from = min(year)
bysort iso source (year): egen to   = max(year)

tostring from, replace
tostring to, replace
keep iso sixlet source from to
duplicates drop 



*Generate Period: 
gen period=""
replace period = from + "-" + to + ": " if from!=to
replace period = from + ": " if from==to

sort iso sixlet from to

*Generate Method
gen method=""

* countries with 
replace method = period + "Currency assumed to be " + substr(source_0, 1, 3) + ";" if strpos(source_0,"_assumed_")
replace method = period + "Data extended from "     + substr(source_0, 1, 2) + ";"          if strpos(source_0,"_assumed_as_")

replace method = period +  "Due to data limitations, this exchange rate is estimated as the " /// 
				+ "ratio between in-house GDP estimates in USD and the same variable " ///
				+ "in LCU for countries succeeding the former Yugoslavia (BA, HR, MK, " ///
				+ "RS, YU, KS, SI, ME);"                                      if strpos(source_0,"calculationfromGDP_yugosl")
replace method = period +  "Due to data limitations, this exchange rate is estimated as the " /// 
				+ "ratio between in-house GDP estimates in USD and the same variable " ///
				+ "in LCU for countries succeeding the former USRR (AM, AZ, BY, " ///
				+ "KG, KZ, TJ, TM, UZ, EE, LT, LV, MD, GE, RU, UA);"          if strpos(source_0,"calculationfromGDP_soviet")
				
replace method = period +  "Data carried forward from the last available year;"    if strpos(source_0,"carryforward")
replace method = period +  "Data interpolated;"                               if strpos(source_0,"interpolated")


replace method = period +  "Data projected backwards using the growth of exchange rates of " ///
				+ "the former USRR;"                                          if strpos(source_0,"extrapolated_ratio_soviet")
replace method = period +  "Data projected backwards using the growth of exchange rates of " ///
				+ "the former Yugoslavia;"                                    if strpos(source_0,"extrapolated_ratio_yugosl")
replace method = period +  "Data projected backwards using the average growth of exchange rates of " ///
				+ "countries with complete spliced exchange rate series (AD, AT, BE, CY, FI, " ///
				+ "FR, DE, GR, IE, IT, LU, MT, MC, ME, NL, PT, SM, ES);"      if strpos(source_0,"extrapolated_ratio_euro")
replace method = period +  "Data projected backwards using the growth of exchange rates of " ///
				+ "Former Yemen Arab Republic;"                               if strpos(source_0,"extrapolated_ratio_yemen")
replace method = period +  "Data projected backwards using the average growth of exchange rates of " ///
				+ "modern Montenegro and Serbia"                              if strpos(source_0,"extrapolated_ratio_RS_MK")

* Generate source
gen source = ""
replace source = period +  `"[URL][URL_LINK]https://www.imf.org/en/publications/weo/weo-database/2025/april/download-entire-database[/URL_LINK][URL_TEXT]IMF "' ///
		+ `"World Economic Outlook (04/$year)[/URL_TEXT][/URL];"' if strpos(source_0,"IMF")
replace source = period + `"[URL][URL_LINK]http://data.worldbank.org/[/URL_LINK][URL_TEXT]World Bank[/URL_TEXT][/URL];"' if strpos(source_0,"WB")
replace source = period + `"[URL][URL_LINK]http://unstats.un.org/unsd/snaama/Introduction.asp[/URL_LINK][URL_TEXT]United"' ///
		+ `"Nations National Accounts Main Aggregates Database[/URL_TEXT][/URL]; "' if strpos(source_0,"UN_SNA")
replace source =  period + `"[URL][URL_LINK]http://openexchangerates.org/[/URL_LINK][URL_TEXT]Open Exchange rates[/URL_TEXT][/URL];"' if strpos(source_0,"openexchangerate")
replace source = period + `"[URL][URL_LINK]https://wid.world/document/unequal-exchange-and-north-south-relations-evidence-from-global-trade-flows-and-the-world-balance-of-payments-1800-2025-world-inequality-lab-working-paper-2025-11/[/URL_LINK][URL_TEXT]"' ///
		+ `"Nievas, G., Piketty, T. (2025). "' ///
		+ `"Unequal Exchange & North-South Relations: Evidence from Global Trade Flows and the World Balance of Payments, 1800-2025[/URL_TEXT][/URL];"' /// 
		if strpos(source_0,"np")
replace source = period + `"[URL][URL_LINK]https://www.mataf.net/en[/URL_LINK][URL_TEXT]Mataf.net[/URL_TEXT][/URL];"' if strpos(source_0,"mataf")

replace source = substr(method, 1, strlen(method)-1) + " (Series inherited from" ///
				+ " another country with available " + substr(source_0,1,3) + "-denominated series);" if strpos(source_0,"_assumed_")
replace source = substr(method, 1, strlen(method)-1) + " (Series inherited from " ///
				+ substr(source_0,1,2) + ");" if strpos(source_0,"_assumed_as_")

// Concatenate sources and methods
* Note: the following wode works well only if the same source is not intermitent across years within the same country
duplicates tag iso sixlet source_0, gen(dup)
assert dup==0


//  Concatenate the methods and the sources

* Generate index per period
sort iso sixlet from
bysort iso sixlet: gen index = _n
keep iso sixlet method source index

* Reshape
reshape wide method source, i(iso sixlet) j(index)


* concatenate
egen    method_conc = concat(method*), punct(" ") 
replace method_conc = substr(method_conc, 1, strlen(method_conc)-1) + "." if !missing(method_conc)

egen source_conc = concat(source*), punct(" ") 
replace source_conc = substr(source_conc, 1, strlen(source_conc)-1) + "." if !missing(source_conc)

keep iso sixlet method_conc source_conc
duplicates drop

rename *_conc *

*Export
keep iso sixlet method source

label data "Generated by import-exchange-rates.do"
save "$work_data/exchange-rates-metadata.dta", replace
