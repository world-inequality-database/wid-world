// -----------------------------------------------------------------------------
//        Import IMF BOP trade gravity .Do-file
// -----------------------------------------------------------------------------

// ---------------------  Index   ----------------------------------------------
// 1. Import IMF data
//      1.1 Adding the negative values to the other gross aggregated component
// 2. Format 
//      2.1 Netherlands Antilles split
// 3. Bringing gravity data
// 4. Complete data (interpolations and adjustments from gravity) 
// 5. Bring GDP in usd
// 6. Compleate missing observations (carry forward and regional imputation) 
// 7. Ensure consitency 
// 8. Export
// -----------------------------------------------------------------------------


// --- 1. Import IMF data ------------------------------------------------------
use "$wid_dir/Country-Updates/National_Accounts/imf-data/BOP-treated-$pastyear.dta", clear

// Current Account, Goods and Services, Goods, Debit, US Dollars	BMG_BP6_USD, now CD_T.G
// Current Account, Goods and Services, Goods, Credit, US Dollars	BXG_BP6_USD, now DB_T.G

keep if code3 == "G" 
keep if inlist(code2, "DB_T","CD_T") 

replace  indicator = "goods_credit" if code3 == "G" & code2=="CD_T"  
replace  indicator = "goods_debit"  if code3 == "G" & code2=="DB_T" 

drop bop* code*

collapse (sum) value, by(country indicator year)

greshape wide v, i(country year) j(indicator) 
renpfix value

foreach v in goods_credit goods_debit {
	gen     neg`v' = 1  if `v' < 0
	replace neg`v' = 0  if mi(neg`v')	
	
	gen q_`v' = 5        if `v'!=.
	gen s_`v' = "IMFBOP" if `v'!=.
}

// ----------- 1.1 Adding the negative values to the other gross aggregated component
gen                 aux = 1                   if neggoods_credit == 1 & neggoods_debit == 1
replace neggoods_credit = 0                   if aux == 1 
replace neggoods_debit  = 0                   if aux == 1 
cap swapval goods_credit goods_debit          if aux == 1 
replace   goods_credit    = abs(goods_credit) if aux == 1
replace   goods_debit     = abs(goods_debit)  if aux == 1
replace q_goods_credit    = min(3, cond(goods_credit >= goods_debit, q_goods_credit, q_goods_debit)) if neggoods_debit == 1
replace s_goods_credit    = "tgxrx,tgmpx" if neggoods_debit == 1
replace   goods_credit    = goods_credit - goods_debit if neggoods_debit == 1
replace q_goods_debit     = 0                 if neggoods_debit == 1 
replace s_goods_debit     = "assumed"         if neggoods_debit == 1 
replace   goods_debit     = 0                 if neggoods_debit == 1 
replace q_goods_debit     = min(3, cond(goods_debit >= goods_credit, q_goods_debit, q_goods_credit)) if neggoods_credit == 1 
replace s_goods_debit     = "tgmpx,tgxrx" if neggoods_credit == 1 
replace   goods_debit     = goods_debit - goods_credit if neggoods_credit == 1 
replace q_goods_credit    = 0                 if neggoods_credit == 1
replace s_goods_credit    = "assumed"         if neggoods_credit == 1
replace   goods_credit    = 0                 if neggoods_credit == 1
drop aux 

// --- 2. Format --------------------------------------------------------------
*kountry countrycode, from(imfn) to(iso2c)
*ren _ISO2C_ iso 
countrycode country, generate(iso) from("imf data")
drop if iso == "CWX" 
/*
replace iso="AD" if countryname=="Andorra, Principality of"
replace iso="SS" if countryname=="South Sudan, Rep. of"
replace iso="TC" if countryname=="Turks and Caicos Islands"
replace iso="TV" if countryname=="Tuvalu"
replace iso="RS" if countryname=="Serbia, Rep. of"
replace iso="KV" if countryname=="Kosovo, Rep. of"
replace iso="CW" if countryname=="Curaçao, Kingdom of the Netherlands"
replace iso="SX" if countryname=="Sint Maarten, Kingdom of the Netherlands"
replace iso="PS" if countryname=="West Bank and Gaza"
*/
drop if mi(iso)
drop country

fillin iso year


// ----------- 2.1 Netherlands Antilles split
merge m:1 iso using "$work_data/ratioCWSX_AN.dta", nogen 

foreach v in goods_credit goods_debit {
	bys year : gen aux`v' = `v' if iso == "AN" & year<2011
	bys year : egen `v'AN = mode(aux`v')
}

foreach v in goods_credit goods_debit {
	local v_dash = subinstr("`v'", "_", "-", .)
	
	foreach c in CW SX {
		replace q_`v' = 1                        if iso == "`c'" & missing(`v')
		replace s_`v' = "`v_dash'(AN)_ratio`c'/AN" if iso == "`c'" & missing(`v')
		replace   `v' = `v'AN*ratio`c'_ANusd     if iso == "`c'" & missing(`v')
	}
}	

drop aux* *AN *ANlcu

drop if mi(iso)

//Keep core countries only
merge 1:1 iso year using "$work_data/import-core-country-codes-year-output.dta", nogen 
keep if corecountry == 1

keep iso year *goods_credit *goods_debit 

// --- 3. Bringing gravity data -----------------------------------------------
merge 1:1 iso year using "$work_data/gravity-isoyear-19702020.dta", nogen keepusing( exports imports q_*)

// ratios IMF-gravity
gen ratioexports = goods_credit/exports
gen ratioimports = goods_debit/imports

by iso : egen auxfirstyearexp = min(year) if !mi(ratioexports)
by iso : egen auxfirstyearimp = min(year) if !mi(ratioimports)

by iso : egen firstyearexp = mode(auxfirstyearexp) 
by iso : egen firstyearimp = mode(auxfirstyearimp) 
drop aux*

// --- 4. Complete data (interpolations and adjustments from gravity) ----------
// lineraly interpolated ratio equal to 1 in year t-5 and to observed IMF/Gravity ratio in year t when we start observing IMF
replace ratioexports = 1 if year <  firstyearexp - 5
replace ratioexports = . if year <= firstyearexp - 1 & year >= firstyearexp - 5
replace ratioimports = 1 if year <  firstyearimp - 5
replace ratioimports = . if year <= firstyearimp - 1 & year >= firstyearimp - 5

// lineraly interpolated ratio equal to 1 in year t-5 and to observed IMF/Gravity ratio in year t when we start observing IMF
replace ratioexports = 1 if year <  firstyearexp - 5
replace ratioexports = . if year <= firstyearexp - 1 & year >= firstyearexp - 5
replace ratioimports = 1 if year <  firstyearimp - 5
replace ratioimports = . if year <= firstyearimp - 1 & year >= firstyearimp - 5


//Interpolate missing values within the series 
foreach v in ratioexports ratioimports {
	* Interpolate
	replace `v' =.     if `v' == 0
	by iso : ipolate `v' year, gen(x`v') 
	
	replace   `v' = x`v'     if missing(`v') 
	drop x`v'
}

// calculated adjusted imports and exports
foreach x in imports exports {
	gen `x'adj = `x'*ratio`x'
}

// if there is an adjusted value
replace q_goods_credit = 2   if mi(goods_credit) & !missing(exportsadj)
replace q_goods_debit  = 2   if mi(goods_debit)  & !missing(importsadj)
replace s_goods_credit = "exports_ratiotgxrxipol/exports" if mi(goods_credit) & !missing(exportsadj)
replace s_goods_debit  = "imports_ratiotgmpxipol/imports"  if mi(goods_debit)  & !missing(importsadj)
replace goods_credit   = exportsadj               if mi(goods_credit)
replace goods_debit    = importsadj               if mi(goods_debit)

// if IMF never reported
replace q_goods_credit = 2         if mi(goods_credit) & !missing(exports)
replace q_goods_debit  = 2         if mi(goods_debit)  & !missing(imports)
replace s_goods_credit = "exports" if mi(goods_credit) & !missing(exports)
replace s_goods_debit  = "imports" if mi(goods_debit)  & !missing(imports)
replace goods_credit   = exports   if mi(goods_credit)
replace goods_debit    = imports   if mi(goods_debit)

// --- 5. Bring GDP in usd ----------------------------------------------------
merge 1:1 iso year using "$work_data/retropolate-gdp.dta", nogenerate keepusing(gdp) keep(master matched)
merge 1:1 iso year using "$work_data/exchange-rates.dta", nogen keepusing(exrate_usd) keep(master matched)
merge 1:1 iso year using "$work_data/price-index.dta", nogen keep(master matched)

gen gdp_idx = gdp*index
	gen gdp_usd = gdp_idx/exrate_usd
drop gdp 	
sort iso year 
keep if inrange(year, 1970, $pastyear )

foreach v in goods_credit goods_debit {
	replace `v' = `v'/gdp_usd
}

* Note: No need since gdp_usd is complete
//Interpolate missing values within the series 
foreach v in goods_credit goods_debit {
	replace   `v' =.       if `v' == 0
	by iso : ipolate `v' year, gen(x`v') 
	replace s_`v' = "ipol" if missing(`v') & !missing(x`v')
	replace q_`v' = 3      if missing(`v') & !missing(x`v')
	replace   `v' = x`v'   if missing(`v') 
	drop x`v'
}

// --- 6. Compleate missing observations (carry forward and regional imputation) 
//Carryforward 
foreach v in goods_credit goods_debit {
	so iso year
	by iso: carryforward `v', replace 

	gsort iso -year 
	by iso: carryforward `v', replace
	
	replace s_`v' = "carryfor" if !missing(`v') & missing(s_`v')
	replace q_`v' = 1              if !missing(`v') & missing(q_`v')
}

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

	replace GEO = "Asia" if inlist(iso, "AE", "TW") & "`level'" == "un"
	replace GEO = "Americas" if inlist(iso, "CW", "SX", "BQ") & "`level'" == "un"
	replace GEO = "Europe" if inlist(iso, "KS", "ME", "GG", "JE", "IM") & "`level'" == "un"
	ren GEO geo`level'
	drop NAMES_STD 
}

//Fill missing with regional means 
foreach v in goods_credit goods_debit {
	foreach level in undet un {
		bys geo`level' year : egen av`level'`v' = mean(`v') 
	}
	replace   `v' = avundet`v'         if  missing(`v')
	replace s_`v' = "reg" + geoundet if !missing(`v') & missing(s_`v' )
	
	replace   `v' = avun`v'            if  missing(`v')
	replace s_`v' = "reg" + geoun    if !missing(`v') & missing(s_`v' )
	
	replace q_`v' = 0                  if !missing(`v') & missing(q_`v')
}
drop av*

// --- 7. Ensure consitency ----------------------------------------------------
// consistency of 0 at the global level (metadata remains the same)
foreach v in goods { 
	replace `v'_credit = `v'_credit*gdp_usd
	replace `v'_debit  = `v'_debit*gdp_usd
	gen net_`v'        = `v'_credit - `v'_debit

	bys year : egen tot`v'_credit = total(`v'_credit)
	bys year : egen tot`v'_debit  = total(`v'_debit)

	gen aux`v'_credit = abs(`v'_credit)
	gen aux`v'_debit  = abs(`v'_debit)
	bys year : egen totaux`v'_credit = total(aux`v'_credit)
	bys year : egen totaux`v'_debit  = total(aux`v'_debit)
}
drop aux*

gen totnet_goods = (totgoods_credit + totgoods_debit)/2
foreach v in goods { 
	replace tot`v'_credit = totnet_`v' - tot`v'_credit
	replace tot`v'_debit  = totnet_`v' - tot`v'_debit
}

foreach v in goods { 
	gen ratio_`v'_credit = `v'_credit/totaux`v'_credit
	gen ratio_`v'_debit  = `v'_debit/totaux`v'_debit
	
replace `v'_credit = `v'_credit + tot`v'_credit*ratio_`v'_credit 
replace `v'_debit  = `v'_debit  + tot`v'_debit*ratio_`v'_debit 
}
drop ratio* net* tot* 

foreach v in goods_credit goods_debit {
	replace `v' = `v'/gdp_usd
}

// --- 8. Export ---------------------------------------------------------------
sort iso year
keep iso year goods_credit goods_debit q_goods_credit q_goods_debit s_goods_credit s_goods_debit 
label data "Generated by imfbop-trade-gravity.do"
save "$work_data/imfbop-tradegoods-gravity.dta", replace
