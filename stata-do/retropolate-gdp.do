// -------------------------------------------------------------------------- //
*	Retropolate backwards gdo for countries that were part 
*	of other countries before independance
*
// -------------------------------------------------------------------------- //


// -------------------- Index ----------------------------------------------- //
// 1. Extrapolate backwards for countries without gdp before independance
// 	1.1 Yugoslavia
//	1.2 Czechoslovakia
// 	1.3 Eriteria 1993 with Ethiopia
// 	1.4 Kosovo 1990  with Serbia
// 	1.5 Timor Leste with Indonesia
// 	1.6 South Sudan and Sudan
// 	1.7 Zanzibar and Tanzania
// 	1.8 Birtish Territories	
//  1.9 Soviet Union
//     1.9.1 Turkmenistan
// 2. Substrat the amount of GDP from country of origin  (only KS out of RS active)
// 3. Correction: Fitting residual contries into NP2025 residual regions 
// 4. Generate Metadata
//	 4.1 Generate method
//	 4.2 Generate source
//	 4.3 Compile both
// 5. Export
// -------------------------------------------------------------------------- //

clear all
tempfile combined
save `combined', emptyok


//------ 1. Extrapolate backwards for countries without gdp before independance

use "$work_data/gdp.dta", clear
*keep iso year gdp currency level_src level_year

greshape wide gdp currency level_src level_year growth_src, i(year) j(iso) string

//------------- 1.1 Yugoslavia
// Yugoslavia: shares applied to BA, HR, ME, MK, RS and SI. KS later applied to RS
foreach iso in BA HR ME MK RS SI {
	gen ratio`iso'_YU = gdp`iso'/gdpYU if year == 1980
	egen x2 = mode(ratio`iso'_YU) 
	replace growth_src`iso' = "YU_1980_GDP_share" if missing(gdp`iso') & year >= 1970
	replace gdp`iso'        = gdpYU*x2 if missing(gdp`iso') & year >= 1970
	drop ratio`iso'_YU x2
}

//------------- 1.2 Czechoslovakia
foreach iso in CZ SK {
	gen ratio`iso'_CS= gdp`iso'/gdpCS if year == 1980
	egen x2 = mode(ratio`iso'_CS) 
	replace growth_src`iso' = "CS_1980_GDP_share" if missing(gdp`iso') & year >= 1970
	replace gdp`iso' = gdpCS*x2 if missing(gdp`iso') & year >= 1970
	drop ratio`iso'_CS x2
}

foreach var in gdp {
//------------- 1.3 Eriteria 1993 with Ethiopia
	gen ratioET_ER = `var'ER/`var'ET if year == 1993
	egen x2 = mode(ratioET_ER) 
	replace growth_srcER = "ET_1993_GDP_share" if missing(`var'ER) & year >= 1970
	replace `var'ER = `var'ET*x2 if missing(`var'ER) & year >= 1970
	drop ratioET_ER x2
	
//------------- 1.4 Kosovo 1990  with Serbia
	gen ratioKS_RS = `var'KS/`var'RS if year == 1990
	egen x2 = mode(ratioKS_RS) 
	replace growth_srcKS = "RS_1990_GDP_share" if missing(`var'KS) & year >= 1970
	replace `var'KS = `var'RS*x2 if missing(`var'KS) & year >= 1970
	drop ratioKS_RS x2
	
//------------- 1.5 Timor Leste with Indonesia
	gen ratioTL_ID = `var'TL/`var'ID if year == 1990
	egen x2 = mode(ratioTL_ID) 
	replace growth_srcTL = "ID_1990_GDP_share" if missing(`var'TL) & year >= 1970
	replace `var'TL = `var'ID*x2 if missing(`var'TL) & year >= 1970
	drop ratioTL_ID x2
	
//------------- 1.6 South Sudan and Sudan
	gen ratioSS_SD = `var'SS/`var'SD if year == 2012
	egen x2 = mode(ratioSS_SD) 
	replace growth_srcSS = "SD_2012_GDP_share" if missing(`var'SS) & year >= 1970
	replace `var'SS = `var'SD*x2 if missing(`var'SS) & year >= 1970
	drop ratioSS_SD x2
	
//------------- 1.7 Zanzibar and Tanzania
	gen ratioZZ_TZ = `var'ZZ/`var'TZ if year == 1990
	egen x2 = mode(ratioZZ_TZ) 
	replace growth_srcZZ = "TZ_1990_GDP_share" if missing(`var'ZZ) & year >= 1970
	replace `var'ZZ = `var'TZ*x2 if missing(`var'ZZ) & year >= 1970
	drop ratioZZ_TZ x2

//------------- 1.8 Birtish Territories	
	// Isle of Man and United Kingdom
	gen ratioIM_GB = `var'IM/`var'GB if year == 1985
	egen x2 = mode(ratioIM_GB) 
	replace growth_srcIM = "GB_1985_GDP_share" if missing(`var'IM) & year >= 1970
	replace `var'IM = `var'GB*x2 if missing(`var'IM) & year >= 1970
	drop ratioIM_GB x2

	// Guernsey and United Kingdom
	gen ratioGG_GB = `var'GG/`var'GB if year == 1991
	egen x2 = mode(ratioGG_GB) 
	replace growth_srcGG = "GB_1991_GDP_share" if missing(`var'GG) & year >= 1970
	replace `var'GG = `var'GB*x2 if missing(`var'GG) & year >= 1970
	drop ratioGG_GB x2

	// Jersey and United Kingdom
	gen ratioJE_GB = `var'JE/`var'GB if year == 1998
	egen x2 = mode(ratioJE_GB) 
	replace growth_srcJE = "GB_1998_GDP_share" if missing(`var'JE) & year >= 1970
	replace `var'JE = `var'GB*x2 if missing(`var'JE) & year >= 1970
	drop ratioJE_GB x2

	// Gibraltar and United Kingdom
	gen ratioGI_GB = `var'GI/`var'GB if year == 1997
	egen x2 = mode(ratioGI_GB) 
	replace growth_srcGI = "GB_1997_GDP_share" if missing(`var'GI) & year >= 1970
	replace `var'GI = `var'GB*x2 if missing(`var'GI) & year >= 1970
	drop ratioGI_GB x2
	
tempfile `var'
append using `combined'
save `combined', replace
}

//------------- 1.9 Soviet Union
// Ex-soviet countriees , there is a year of GDP in 1973 we interpolate up to that year
foreach iso in AM AZ BY KG KZ TJ TM UZ EE LT LV MD {
	ipolate gdp`iso' year , gen(x)
	replace growth_src`iso' = "SU_1973_GDP_interp" if missing(gdp`iso') 
	replace gdp`iso' = x if missing(gdp`iso') 
	drop x

	// From 1973 to 1970 we will use share of URSS GDP
	gen ratio`iso'_SU = gdp`iso'/gdpSU if year == 1973
	egen x2 = mode(ratio`iso'_SU) 
	replace growth_src`iso' = "SU_1973_GDP_share" if missing(gdp`iso') & year >= 1970 & missing(growth_src`iso')
	replace gdp`iso' = gdpSU*x2 if missing(gdp`iso') & year >= 1970
	drop ratio`iso'_SU x2
}

//----------------- 1.9.1 Turkmenistan
// For TM the datapoint from Madison in 1973 is the same that the value from the WB in 1987, so the interpolation gives the same value for 14 years.
// Solution: use the share from Soviet Union in 1987 and compute backwards
gen ratioTM_SU = gdpTM/gdpSU if year == 1987	
egen x2 = mode(ratioTM_SU) 
replace growth_srcTM = "SU_1987_GDP_share" if year >= 1970 & year < 1987
replace gdpTM = gdpSU*x2 if year >= 1970 & year < 1987
drop ratioTM_SU x2

*use `combined', clear
duplicates drop year, force
		
greshape long gdp currency level_src level_year growth_src, i(year) j(iso) string

foreach var in currency level_year /*growth_src level_src*/{
	egen `var'2 = mode(`var'), by(iso)
	drop `var'
	rename `var'2 `var'

}

duplicates tag year iso gdp currency, gen(dup)
assert dup == 0
drop dup 

drop if missing(gdp)

//------ 2. Substrat the amount of GDP from country of origin (only KS out of RS active)
// We do not do this for Yugoslavia nor the Soviet Union nor Czechoslovakia because they are special cases
preserve
	use "$work_data/ppp.dta", clear
	drop data_quality
	keep if inlist(iso, "SD", "SS") 
	keep if year == $pastyear
	
	drop currency refyear
	reshape wide ppp, i(year) j(iso) string
	gen valueSD_SS = pppSS/pppSD

	reshape long
	drop year iso ppp
	ren valueSD_SS value
	gen exchange = "SD_SS"
	gen iso = "SS"
	duplicates drop
		
	tempfile pppSS_SD
	save `pppSS_SD'
restore

preserve
	use "$work_data/exchange-rates.dta", clear
	drop data_quality
	keep exrate_usd  year iso 
	keep if inlist(iso, "ER", "ET", "TL", "ID") ///
		  | inlist(iso, "KS", "RS") 
	keep if year == $pastyear
*	drop if year<1990
	greshape wide exrate_usd, i(year) j(iso) string
*	reshape wide value*, i(widcode) j(year)

*	keep widcode valueKS1999 valueRS1999 valueTL1990 valueID1990 valueER1993 valueET1993
*	reshape long

	gen exrate_usdET_ER = exrate_usdER/exrate_usdET
	gen exrate_usdRS_KS = exrate_usdKS/exrate_usdRS
	gen exrate_usdID_TL = exrate_usdTL/exrate_usdID
	*gen valueNL_BQ = valueBQ/valueNL
*	drop valueKS-valueTL
	drop exrate_usdER-exrate_usdTL
		

	greshape long exrate_usd, i(year) j(iso) string
	drop if missing(exrate_usd)
	replace iso = substr(iso, 4, 2)
	drop year 
	
	tempfile exchange
	save `exchange'
restore

merge m:1 iso using `exchange', nogenerate
merge m:1 iso using `pppSS_SD', update replace nogen
//
generate value_origin = gdp/exrate_usd if inlist(iso, "SS", "ER", "TL", "KS","ZZ") 
drop exrate_usd
gsort iso year
// br if inlist(iso, "SD", "SS", "ER", "ET", "TL", "ID") ///
// 	| inlist(iso, "KS", "RS", "TZ", "ZZ")

preserve 
	keep if inlist(iso, "SS", "ER", "TL", "KS","ZZ") | inlist(iso, "SD", "ET", "ID", "RS","TZ")
	keep year iso gdp value_origin
	greshape wide value_origin gdp, i(year) j(iso) string
	replace value_originRS = value_originKS
	replace value_originET = value_originER
	replace value_originID = value_originTL
	replace value_originSD = value_originSS
	replace value_originTZ = value_originZZ
	*replace value_originNL = value_originBQ  Statistics Netherlands confirmed that Bonaire is not included in their calculation of GDP
	greshape long value_origin gdp, i(year) j(iso) string
	
	tempfile double
	save `double'
restore 

merge 1:1 iso year using `double', update replace nogen

*replace gdp = gdp-value_origin if iso == "SD" & year < 2012 // Desactivated bec&use NievasPiketty2025 has the data
*replace gdp = gdp-value_origin if iso == "ET" & year < 1993 // Desactivated bec&use NievasPiketty2025 has the data
replace gdp = gdp-value_origin if iso == "RS" & year < 1990
*replace gdp = gdp-value_origin if iso == "ID" & year < 1990 // Desactivated bec&use NievasPiketty2025 has the data
*replace gdp = gdp-value_origin if iso == "NL" & year >= 2010
*replace gdp = gdp-value_origin if iso == "TZ" & year < 1990

replace growth_src = "KS_takeaway_"+growth_src if iso == "RS" & year < 1990

drop value* exchange 
drop if missing(gdp)

duplicates tag year iso gdp currency, gen(dup)
assert dup == 0
drop dup 


//------ 3. Correction: Fitting residual contries into NP2025 residual regions --//

//-->> GDP Values in  Constant Prices LCU
*recast int year
*recast str2 iso

* Call Price index and exchange rate of countries
preserve 
	use "$work_data/exchange-rates.dta", clear
	keep iso year exrate_usd
	drop if strpos(iso,"-")
	recast str2 iso
	compress
	tempfile xrates
	save `xrates'
restore 
merge 1:1 iso year using "$work_data/exchange-rates.dta", nogen keep(master matched) keepusing(exrate_usd)

merge 1:1 iso year using "$work_data/price-index.dta", nogen keepusing(index) keep(master matched)
* Call data of Nievas&Piketty(2025) for residual regions
merge m:1 iso using "$work_data/import-core-country-codes-output.dta", nogen keepusing(corecountry region2)
merge m:1 region2 year using "$work_data/nievaspiketty2025_gdp-reg.dta", nogen  keepusing(gdp_usd_np)
drop if missing(iso)
sort iso year

* Convert GDP 
gen double gdp_usd =(gdp*index)/exrate_usd
 //-->> GDP values in Current Prices USD (as in NP2025)
 
* Caculate residual regions with local data
bys year region2: egen reg_gdp_usd = total(gdp_usd) 
replace reg_gdp_usd=. if missing(region2) // Core countries are aggregated as a region

* Calculate the diference between local and NP2025 agregattes
gen double totnet = (reg_gdp_usd- gdp_usd_np) if year>=1970 & year<=2022

* Generate shares of this difference according to each country gdp
gen double prop_c  = gdp_usd / reg_gdp_usd
gen double adjustment= prop_c*totnet 
* Apply corrections to local gdp
gen double gdp_usd_corrected= gdp_usd - adjustment

* Recalculate GDp in LCU constant $pastyear prices
gen double gdp_lcu_constat_corr= (gdp_usd_corrected/index)*exrate_usd

* Input new values in the dataset
gen detail="adj_np" if !missing(region2) & year>= 1970 & year<=2022
replace gdp = gdp_lcu_constat_corr if !missing(region2) & year>= 1970 & year<=2022

//------------------------------------------------------------------------------

* Gen data quality
gen     data_quality = 5 if inlist(substr(level_src, 5,.),"cbs","lmf","un2","wb","OECD") | strpos(level_src,"OECD") | strpos(level_src,"weo")
replace data_quality = 5 if inlist(growth_src,"OECD","cbs","lmf","un2","wb","weo")

replace data_quality = 4 if inlist(substr(level_src,5,.),"np") | strpos(growth_src,"Mad") | strpos(growth_src,"np")  | strpos(growth_src,"wid")  
replace data_quality = 4 if strpos(growth_src,"_forecast") 

replace data_quality = 3 if strpos(growth_src,"interp")

replace data_quality = 2 if strpos(growth_src,"_GDP_")

replace data_quality = 1 if strpos(growth_src,"carryforward")


//------ 5. Export
*preserve
	replace growth_src = subinstr(growth_src, "_", "&", .)
	replace level_src = subinstr(level_src, "_", "&", .)
	replace detail = subinstr(detail, "_", "&", .)
	gen     s_ = "level" + string(level_year) + level_src if year==level_year
	replace s_ = growth_src if year!=level_year
	
	replace s_ = s_ + "_"+ detail if detail!=""
	
	keep year iso gdp currency data_quality s_
	rename data_quality data_qualitygdp
	
	label data "Generated by retropolate-gdp.do"
	save "$work_data/retropolate-gdp.dta", replace
*restore
/*
//------ 4. Generate Metadata
keep year iso gdp currency level_src level_year growth_src detail
bysort iso: egen detail2=mode(detail)
drop detail

//----------- 4.1 Generate method
gen method = "Reference level"      if level_year==year
replace method="(This level was calcualted from data in internaitonal Dollars of 2011)"       if level_year==year & !strpos(level_src,"lcu" )

replace method = "Growth rates extended from " + substr(growth_src,1,2) if strpos(growth_src,"GDP_growth")
replace method = "Growth rates extended from the ratio of "+ iso + " relative to the " + substr(growth_src,1,2) + " in " + substr(growth_src,4,4) if strpos(growth_src,"GDP_share")
replace method = "Growth rates extended from the ratio of "+ iso + " relative to the " + substr(growth_src,13,2) + " in " + substr(growth_src,16,4) + ", taking away the value of " + substr(growth_src,1,2) if strpos(growth_src,"GDP_share") &  strpos(growth_src,"takeaway")
replace method= "Value calculated taking away the value of " + substr(growth_src,1,2) if !strpos(growth_src,"GDP_share") &  strpos(growth_src,"takeaway")

replace method= "Forecast value from IMF WEO" if  strpos(growth_src,"_forecast")
replace method= "Value carried forward" if  growth_src=="carryforward"
replace method= "Values extended from the interpolation of the ratio of " + iso + " relative to the " + substr(growth_src,1,2)  + " in " + substr(growth_src,4,4)   if  strpos(growth_src,"_interp")

replace method=method + "Maddison's source values in USD International Dollars"       if strpos(growth_src,"_usd" )


//----------- 4.2 Generate source
gen source=""
foreach v in growth level {
	
		replace source = `"[URL][URL_LINK]http://piketty.pse.ens.fr/fr/capitalisback[/URL_LINK][URL_TEXT]"' ///
		+ `"Piketty, T. and Zucman, G. (2014). Capital is Back: Wealth-Income Ratios in Rich Countries 1700-2010 [/URL_TEXT][/URL]"' if regexm(`v'_src, "wid") & (iso != "SE")
	
		replace source = `"[URL][URL_LINKhttps://wid.world/document/what-determines-the-capital-share-world-inequality-lab-wp-2020-08/[/URL_LINK][URL_TEXT] "' ///
		+ `"Bengtsson, E., Enrico Rubolino, E., Waldenström D.(2020).What Determines the Capital Share over the Long Run of History? [/URL_TEXT][/URL]"' if regexm(`v'_src, "wid") & (iso == "SE")
		
		replace source = `"[URL][URL_LINK]https://www.cbs.nl/en-gb/our-services/open-data[/URL_LINK][URL_TEXT]"' ///
		+ `"Statistics Netherlands[/URL_TEXT][/URL]"' if regexm(`v'_src, "cbs")
	
		replace source = `"[URL][URL_LINK]https://datacatalog.worldbank.org/search/dataset/0037798/global-economic-monitor[/URL_LINK][URL_TEXT] "' ///
		+ `"The World Bank Global Economic Monitor[/URL_TEXT][/URL]"' if regexm(`v'_src, "gem")
		
		replace source = `"[URL][URL_LINK]https://www.rug.nl/ggdc/productivity/pwt/related-research-papers/maddison-wu_draft_jan07.pdf[/URL_LINK][URL_TEXT]Maddison, "' ///
		+ `"A. & Wu, H. China s Economic Performance: How Fast Has GDP Grown; How "' ///
		+ `"Big is it Compared to the USA? (2007). Series updated by Prof. Harry Wu[/URL_TEXT][/URL]"' ///
		if regexm(`v'_src, "mw")
		
		
		replace source = `"[URL][URL_LINK]https://unesdoc.unesco.org/ark:/48223/pf0000102385[/URL_LINK][URL_TEXT] "' ///
		+ `" Maddison, Angus (1995). Monitoring the world economy, 1820-1992[/URL_TEXT][/URL]"' ///
		if regexm(`v'_src, "Mad95")
		
		*replace source = `"[URL][URL_LINK]http://ndl.ethernet.edu.et/bitstream/123456789/11295/1/116%20.%20Angus_Maddison.pdf[/URL_LINK][URL_TEXT] "' ///
		*+ `" Maddison, A. (2007). Contours of the World Economy 1-2030 AD[/URL_TEXT][/URL]; "' ///
		*if regexm(`v'_src, "Mad07")
		replace source = `"[URL][URL_LINK]https://www.rug.nl/ggdc/historicaldevelopment/maddison/releases/maddison-project-database-2023[/URL_LINK][URL_TEXT] "' ///
		+ `" MPD version 2023: Bolt, Jutta and Jan Luiten van Zanden (2024). Maddison style estimates of the evolution of the world economy: A new 2023 update [/URL_TEXT][/URL]"' ///
		if regexm(`v'_src, "Mad07")
		
		replace source = `"[URL][URL_LINKhttps://www.oecd.org/en/publications/2003/09/the-world-economy_g1gh38a7.html[/URL_LINK][URL_TEXT]IMF "' ///
		+ `"Maddison, A.(2003).The World Economic History Madsison. OECD [/URL_TEXT][/URL]"' if regexm(`v'_src, "OECD")
		
	replace source = `"[URL][URL_LINK]http://unstats.un.org/unsd/snaama/Introduction.asp[/URL_LINK][URL_TEXT]United "' ///
		+ `"Nations National Accounts Main Aggregates Database[/URL_TEXT][/URL]"' if regexm(`v'_src, "un2")

	replace source = `"[URL][URL_LINK]http://data.worldbank.org/[/URL_LINK][URL_TEXT]World Bank[/URL_TEXT][/URL]"' ///
		if regexm(`v'_src, "wb")

	replace source = `"[URL][URL_LINK]https://www.imf.org/en/publications/weo/weo-database/2025/april/download-entire-database[/URL_LINK][URL_TEXT]IMF "' ///
		+ `"World Economic Outlook (04/$year)[/URL_TEXT][/URL]"' if regexm(`v'_src, "weo")
		
		replace source = `"[URL][URL_LINK]https://www.brookings.edu/articles/the-external-wealth-of-nations-database/[/URL_LINK][URL_TEXT]"' ///
		+ `"[/URL_TEXT]Milesi-Ferretti, J.M., The external wealth of nations database. Bookings[/URL]"' if regexm(`v'_src, "lmf")
		
	replace source = `"[URL][URL_LINK]https://wid.world/document/unequal-exchange-and-north-south-relations-evidence-from-global-trade-flows-and-the-world-balance-of-payments-1800-2025-world-inequality-lab-working-paper-2025-11/[/URL_LINK][URL_TEXT]"' ///
		+ `"Nievas, G., Piketty, T. (2025). "' ///
		+ `"Unequal Exchange & North-South Relations: Evidence from Global Trade Flows and the World Balance of Payments, 1800-2025[/URL_TEXT][/URL]"' ///
		if regexm(`v'_src, "np")
}


/*
//----------- 4.3 Compile both
replace growth_src=level_src if mi(growth_src)

sort iso year
bysort iso (year): generate categ = sum(growth_src[_n - 1] != growth_src)
egen firstyear = min(year), by(iso categ)
egen lastyear = max(year), by(iso categ)

foreach v in source method {
	preserve
		generate `v'_new = string(firstyear) + ": " + `v' + ";" ///
			if (firstyear == lastyear) & (`v'!="")
		replace `v'_new = string(firstyear) + "-" + string(lastyear) + ///
			": " + `v' + ";" if  (firstyear != lastyear)  & (`v'!="")
		drop firstyear lastyear 

		keep iso `v'_new categ detail2
		drop if `v'_new == ""
		duplicates drop

		greshape wide `v'_new, i(iso detail2) j(categ)
		egen `v' = concat(`v'_new*), punct(" ")
		keep iso `v' detail2
		if "`v'" != "source" {
			replace `v' = "The value is generated by chaining the growth rates from the selected sources, " + /// 
			 "departing from observe reference year level; "  + substr(`v', 1, length(`v') - 1) + "." if detail2==""
			replace `v' = "The value is generated by chaining the growth rates from the selected sources, " + /// 
			 "departing from an observed reference year level (Series adjusted from 1970-2023 to match with Nievas G., & Piketty, T.(2025)); " ///
															+ substr(`v', 1, length(`v') - 1) + "." if detail2!=""
			 
		}
			
		generate sixlet = "mgdpro"
		drop detail2
		tempfile metadata_`v'
		save    `metadata_`v''
	restore
}
u "`metadata_method'", clear
merge 1:1 iso sixlet using "`metadata_source'", nogen 
order iso sixlet method source
*/
keep iso year detail2 source method

gen sixlet = "mgdpro" 

// Export 
label data "Generated by retropolate-gdp.do"
save "$work_data/retropolate-gdp-metadata.dta", replace




