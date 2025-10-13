// -----------------------------------------------------------------------------
// -------------------------------------------------------------------------- //
* 	           Aggregates macro variables to Regions
// -------------------------------------------------------------------------- //
// -----------------------------------------------------------------------------

// Note: The purpose of this do-file is to aggregate some of the macro variables 
// in order to calculate estimates for the well-defined regions and world estimates.

// --------------- 0.  Index -------------------------------------------------//
// 	1. Get Macroeconomic data 
// 		1.1  Store PPP and exchange rates as extra variables
// 		1.2 Get Macro Variables to be aggregated 
// 		1.3 Generate constant, current and XR comparable values
//  2. Generate Regional Aggregations
//      2.1  Call the region definition
//		2.2  Calculation: Population 1800-$pastyear
// 		2.3  Calculation: Macro variables 1970-$pastyear
// 			2.3.1 Expansion of the macro variables to the subregions OL and OK
//  3. Generate World Aggregations
// 		3.1 Calculate WO
//  4. Generate currency values, price indexes and xrates
// 		4.1 Generate W and Y of the regional variables
//		4.2 Use mnninc values for estimating regional price indexes and XR
// 		4.3 Retain only MER USD values of regions
//		4.4 Call intlcu for regions 
//      4.5 Format for appending  
//  5. Merge Historical regions from Nievas & Piketty (2025)
//  	5.1 Calculate missing conf  
//      5.2. Bring wealth to product ratios (y)
//      5.3. Generate constant $pastyear monetary values
//      5.4. Calculate wealth to income ratios (w)
// 		5.5. Extend exchange rate to regions-MER before 1970 
// 		5.6. Extend PPP to regions-MER before 1970
//		5.7. Extend exchange rate to regions-MER before 1970
//      5.7. Complete Price index for regions -PPP  
//      5.8.  Extend Population to regions-PPP
// 		5.9.  Extend aggregates  to regions-PPP
//      5.8.  Complete intclu 
//      5.11. Exclusion checks
//  6. Merge Historical countries from Nievas & Piketty (2025)
//  7. Final Formating and export
//      7.1. Pile countries 
//      7.2. Add regions
//      7.3.  Save
//  8. Create metadata
//------------------------------------------------------------------------------

clear all
tempfile regions_npopul
save    `regions_npopul', emptyok

tempfile regions_rest
save    `regions_rest', emptyok


// -------------------------------------------------------------------------- //
* 	1. Get Macroeconomic data 
// -------------------------------------------------------------------------- //

// --------- 1.1  Store PPP and exchange rates as extra variables ----------- //

use "$work_data/add-wealth-aggregates-output.dta", clear

keep if substr(widcode, 1, 3) == "xlc"

keep if year == $pastyear
keep iso widcode value
duplicates drop iso widcode, force
greshape wide value, i(iso) j(widcode) string
foreach v of varlist value* {
	drop if `v' >= .
}
rename valuexlceup999i pppeur
rename valuexlceux999i exceur
rename valuexlcusp999i pppusd
rename valuexlcusx999i excusd
rename valuexlcyup999i pppcny
rename valuexlcyux999i exccny
drop if inlist(iso, "CN-UR", "CN-RU")


tempfile pppexc
save "`pppexc'"


// --------- 1.2 Get Macro Variables to be aggregated ----------------------- //

* Call Data
use "$work_data/add-wealth-aggregates-output.dta", clear

// Keep desired variables
keep if p == "pall"
gen     flag= 0
* Keep populations
replace flag= 1 if  (substr(widcode, 1, 6) == "npopul" & inlist(substr(widcode, 10, 1), "i", "f", "m"))
* keep wealth aggregates		
replace flag= 1 if  inlist(widcode, "mnninc999i", "mndpro999i", "mgdpro999i") | ///
				   (inlist(widcode, "mgweal999i", "mhweal999i","mnweal999i", "mpweal999i")  & year>=1980) 

replace flag= 1	if inlist(substr(widcode, 1, 6),"mnwnxa","mnwgxd","mnwgxa")
					
replace flag= 1	if (inlist(substr(widcode, 1, 6),        "mnwnfa","mnwhou","mnwbus", "mnwagr", "mnwboo")                   | /// 
				  inlist(substr(widcode, 1, 6), "mnwdka","mcwres","mgwass", "mpwnfa","mpwhou","mpwbus","mpwagr") | ///  
				  inlist(substr(widcode, 1, 6), "mpwodk","mpwfin","mpwfiw", "mpweqi", "mpwpen","mpwdeb","miweal","mcwboo") | ///  
				  inlist(substr(widcode, 1, 6), "mcwnfa","mcwhou","mcwbus", "mcwfin", "mcwdeb","mcwdeq","mgwnfa","mgwhou") | ///  
				  inlist(substr(widcode, 1, 6), "mgwbus","mgwfin","mgwdeb"))  & year>=1980 //  "mnweal"  ,"mpweal","mhweal" ,"mgweal" "icwtoq",
* Keep Macro variables
replace flag= 1 if inlist(substr(widcode, 1, 6), "mnnfin", "mfinrx", "mfinpx", "mcomnx", "mpinnx", "mnwnxa", "mnwgxa", "mnwgxd") ///
				 | inlist(substr(widcode, 1, 6), "mcomhn", "mfkpin", "mconfc", "mcomrx", "mcompx", "mpinrx", "mpinpx", "mfdinx") ///
				 | inlist(substr(widcode, 1, 6), "mfdirx", "mfdipx", "mptfnx", "mptfrx", "mptfpx", "mflcin", "mflcir", "mflcip") /// 
				 | inlist(substr(widcode, 1, 6), "mncanx", "mtbnnx", "mcomnx", "mopinx", "mscinx", "mtbxrx", "mtbmpx", "mopirx") /// 
				 | inlist(substr(widcode, 1, 6), "mopipx", "mscirx", "mscipx", "mfkarx", "mfkapx", "mfkanx", "mtgncx", "mtgxcx") /// 
				 | inlist(substr(widcode, 1, 6), "mtaxnx", "mfsubx", "mftaxx", "mtgnmx", "mtgxmx", "mtgmmx", "mtgmcx") /// 
				 | inlist(substr(widcode, 1, 6), "mtgmpx", "mtgnnx", "mtgxrx", "mtsmpx", "mtsnnx", "mtsxrx") ///
				 | inlist(substr(widcode, 1, 6), "mexpgo", "mgpsge", "mdefge", "mpolge", "mecoge", "menvge", "mhouge", "mheage") ///
				 | inlist(substr(widcode, 1, 6), "mrecge", "meduge", "medpge", "medsge", "medtge", "msopge", "mspige", "msacge") ///
				 | inlist(substr(widcode, 1, 6), "msakge", "mrevgo", "mpitgr", "mcitgr", "mscogr", "mpwtgr", "mintgr", "mottgr") /// 
				 | inlist(substr(widcode, 1, 6), "mntrgr", "mpsugo", "mretgo")   

replace flag= 1 if 	inlist(substr(widcode, 1, 6), "mfdixa", "mfdixd", "mfdixn", "mgninc", "mptdpx", "mptdrx", "mptdxa", "mptdxd") | ///
					inlist(substr(widcode, 1, 6), "mptepx", "mpterx", "mptexa", "mptexd", "mptfrn", "mptfrp", "mptfrr", "mptfxa") | ///
					inlist(substr(widcode, 1, 6), "mptfxd", "mptfxn", "mptrrx", "mptrxa", "mscgnx", "mscgpx", "mscgrx", "msconx") | ///
					inlist(substr(widcode, 1, 6), "mscopx", "mscorx", "mscrnx", "mscrpx", "mscrrx", "mtsonx", "mtsopx", "mtsorx") | ///
					inlist(substr(widcode, 1, 6), "mtstnx", "mtstpx", "mtstrx", "mtsvnx", "mtsvpx", "mtsvrx") // New set of variables  16/JUL/25

replace flag= 1 if (inlist(substr(widcode, 1, 6), "mptxgo", "mgvato", "mgvago", "mceugo", "mgsrgo", "mnsrgo", "mcfcgo", "mgvaco") | ///
				    inlist(substr(widcode, 1, 6), "mceuco", "mgsrco", "mnsrco", "mcfcco", "mgvahn", "mceuhn", "mgmxhn", "mnmxhn") | ///
				    inlist(substr(widcode, 1, 6), "mccmhn", "mgsrhn", "mnsrhn", "mccshn")) & year>=1980 
					
* Keep exchange rates and indexes
replace flag= 1 if inlist(substr(widcode, 1, 6), "xlcusx", "xlcusp", "xlceux", "xlceup", "xlcyux", "xlcyup") /// 
				 | inlist(substr(widcode, 1, 6), "inyixx") // , "intlcu","xrerus") ///
			//     | (substr(widcode, 1, 1) == "m")
drop if flag==0
drop flag

preserve 
// Generate list for calculating W and Y ratios
	keep if  substr(widcode,1,1)=="m"
	keep  widcode
	duplicates drop
	replace widcode=substr(widcode,2,10)
	sort widcode
	glevelsof widcode, local(agg_var)
restore 

/*
// Retain price index and xrates MER and PPP for calculating 
preserve
	keep if year<1970
	keep if  inlist(widcode,"inyixx999i", "xlcusx999i", "xlcusp999i", "xlceux999i", "xlceup999i", "xlcyux999i", "xlcyup999i")
	keep iso year widcode value
	reshape wide value, i(iso year) j(widcode) string
	tempfile country_idx
	save    `country_idx'
restore
*/

* Formating
drop currency
greshape wide value, i(iso year p) j(widcode) string
renvars value*, pred(5)

// ----->> Data in LCU Constant Prices
	
// --------- 1.3 Generate constant, current and XR comparable values -------- //
// Add PPP and exchange rates 
merge n:1 iso using "`pppexc'", nogenerate 



//Make a copy of variable list for using in section 2.3.1 Expansion of the macro 
//variables to the subregions OL and OK
ds iso year p npopul*  ppp* exc* xlc* inyixx , not    // xrerus intlcu
local allvars `r(varlist)'

// Calculate convert LCU constant values to PPP(USD, EUR, CNY) and MER (USD, EUR, CNY) values
ds iso year p npopul*  ppp* exc* xlc* inyixx , not  // xrerus intlcu
*foreach v in `r(varlist)' {
foreach v in mnninc999i {
	foreach l of varlist ppp* exc* {
		gen double `v'_`l' = `v'/`l' 
	}
}

*merge  1:1 iso year usign "`country_idx'", nogen keep(master match)
foreach v in `r(varlist)' {
	foreach l in xlceu xlcus xlcyu {
		foreach x in x p {
			gen double `v'_`l'`x'_curr = (`v'*inyixx999i)/`l'`x'999i 
		}
	}
}


// ----->> Data in MER (USD, EUR, CNY) and PPP (USD, EUR, CNY) Constant Prices

// Calculate nninc in current prices in MER and PPP currencies
foreach l in x p {
	generate double mnninc999i_nomus`l' = (mnninc999i*inyixx)/xlcus`l'
	generate double mnninc999i_nomeu`l' = (mnninc999i*inyixx)/xlceu`l'
	generate double mnninc999i_nomyu`l' = (mnninc999i*inyixx)/xlcyu`l'

}

// ----->> Data in MER (USD, EUR, CNY) and PPP (USD, EUR, CNY) Current Prices

*drop mcitgr999i-mtaxnx999i pppeur-exccny inyixx999i xlc*
drop mccmhn999i-mtsxrx999i pppeur-exccny  xlc*   inyixx999i // xrerus999i intlcu999i

tempfile countries
save `countries'  

// -------------------------------------------------------------------------- //
* 	2. Generate Regional Aggregations
// -------------------------------------------------------------------------- //

// --------- 2.1  Call the region definition
merge m:1 iso using "$work_data/import-core-country-codes-output.dta", nogen keep(matched)
drop titlename shortname TH corecountry 

preserve
	collapse (firstnm) region*, by(iso year)
	generate region7 = "World"
	greshape long region, i(iso year) j(j)
	drop j
	drop if region == ""
	generate value = 1
	duplicates drop
	greshape wide value, i(region year) j(iso)
	foreach v of varlist value* {
		replace `v' = 0 if missing(`v')
	}
	renvars value*, predrop(5)
	rename region iso
	merge m:1 iso using "$work_data/import-region-codes-output.dta", keep(matched) nogen
	drop iso shortname matchname
	rename titlename region 
	order region AD
	gsort region year
	
	export excel "$wid_dir/wid-regions-list.xlsx", sheet("WID", replace) firstrow(variables)
restore
// --------- 2.2  Calculation: Population 1800-$pastyear
* The population data is available for all the core countries since 1800 
foreach x of varlist region* {
preserve
	drop if missing(`x')
	collapse (sum) npopul001f-npopul999m, by(year `x')
	
	rename `x' region
	
	tempfile `x'
	append using `regions_npopul'
	save "`regions_npopul'", replace
restore
}

// --------- 2.3  Calculation: Macro variables 1970-$pastyear

keep if year>=1970 

foreach x of varlist region* {
preserve
	drop if missing(`x')
	*collapse (sum) mcitgr999i_pppeur-mnninc999i_nomyup, by(year `x')
	collapse (sum) mnninc999i_pppeur-mnninc999i_nomyup, by(year `x')
	
	rename `x' region
	
	tempfile `x'
	append using `regions_rest'
	save "`regions_rest'", replace
restore
}

use  "`regions_npopul'", clear
merge 1:1 region year using  "`regions_rest'", nogenerate
gsort region year 


// --------- 2.3.1 Expansion of the macro variables to the subregions OL and OK
* Following the simplifaction of the WID region in 2025, only OK(NorthAmerica) 
*       and OL(Occeania) were retained as subregions of NAOC (OH). In order to 
*       complete the data for these regions,  we used the ratio between the GDP
*       percapita of OL and the one of OH (assigning 1- ratio to OK) for cacluating 
*       proportional values of the macroeconomic variables for each subregions 
*       comming from the values of the whole residual region OH.

* Step 1: call the GDP and population of OL and OH and calculate the percapita GDP
preserve
	keep if inlist(region,"OL","OH") & year==1970
	keep year region npopul999i mgdpro999i*
	*drop  *_curr
	foreach p in eu us yu {
		foreach c in p x {
			*replace mgdpro999i_xlc`p'`c'_curr= mgdpro999i_xlc`p'`c'_curr /npopul999i
			rename  mgdpro999i_xlc`p'`c'_curr `p'`c'
			}
	}
	drop npopul999i
	
* Step 2: calculate the ration GDPPerCap_OL/GDPPerCap_OH
	reshape wide eux eup usx usp yux yup, i(year) j(region) string
		foreach c in p x {
			foreach p in eu us yu {
				replace `p'`c'OL= `p'`c'OL/`p'`c'OH
				}
			}

	drop *OH
	reshape long
* Step 3: calculate the 1- ration for OK
	expand 2, gen(xpnd)
	replace region="OK" if xpnd==1
	drop  year xpnd
	foreach v in eux eup usx usp yux yup {
		replace `v'=1-`v' if region=="OK"
	}
	label data "Generated by aggregate-macro-regions.do"
	save "$work_data/ratioOKOL.dta",replace
restore

* Step 4: Make a copy of macroeconomic variables of OH
preserve
	keep if inlist(region,"OH") //& year<1970
	drop npopul*
	renvars mnninc999i_pppeur-mnninc999i_nomyup, pref("OH")
	expand 2, gen(xpnd)
	replace region="OK" if xpnd==0
	replace region="OL" if xpnd==1
	drop xpnd
	
	tempfile OH_data
	save `OH_data'
restore
* Step 5: Bring OH variables and ratios to the existing macroencomi variables
merge 1:1 region year using "`OH_data'",   nogenerate
merge m:1 region      using "$work_data/ratioOKOL.dta", nogenerate

* Step 6: Fill the macroeconomic variables for the missing years
*    Step 6.1:  Extrapolate proportionaly(based on ratio) the OH data to OK and OL
foreach v of local allvars {
    foreach p in p x {
        foreach c in eu us yu {
            replace `v'_xlc`c'`p'_curr = OH`v'_xlc`c'`p'_curr  * `c'`p'  if inlist(region, "OK", "OL") & year < 1970
        }
    }
}

replace mnninc999i_nomusx= OHmnninc999i_nomusx * usx if inlist(region, "OK", "OL") & year < 1970
replace mnninc999i_nomusp= OHmnninc999i_nomusp * usp if inlist(region, "OK", "OL") & year < 1970
replace mnninc999i_nomeux= OHmnninc999i_nomeux * eux if inlist(region, "OK", "OL") & year < 1970
replace mnninc999i_nomeup= OHmnninc999i_nomeup * eup if inlist(region, "OK", "OL") & year < 1970
replace mnninc999i_nomyux= OHmnninc999i_nomyux * yux if inlist(region, "OK", "OL") & year < 1970
replace mnninc999i_nomyup= OHmnninc999i_nomyup * yup if inlist(region, "OK", "OL") & year < 1970

*    Step 6.2:  Extrapolate proportionaly(based on ratio) the OH data to OK and OL for new NP2025 variables from 1970
foreach v in mtgncx999i mtgxcx999i mtgmcx999i mtgnmx999i mtgxmx999i mtgmmx999i {
    foreach p in p x {
        foreach c in eu us yu {
            replace `v'_xlc`c'`p'_curr = OH`v'_xlc`c'`p'_curr  * `c'`p'  if inlist(region, "OK", "OL") & year < 1970
        }
    }
}

drop OH* eux eup usx usp yux yup


// --------- 2.3.1 Expansion of the macro variables to the subregions OL and OK
* Following the simplifaction of the WID region in 2025, only OK(NorthAmerica) 
*       and OL(Occeania) were retained as subregions of NAOC (OH). In order to 
*       complete the data for these regions,  we used the ratio between the GDP
*       percapita of OL and the one of OH (assigning 1- ratio to OK) for cacluating 
*       proportional values of the macroeconomic variables for each subregions 
*       comming from the values of the whole residual region OH.

* Step 1: call the GDP and population of OL and OH and calculate the percapita GDP
preserve
	keep if inlist(region,"QF","XB") & year==1970
	keep year region npopul999i mgdpro999i*
	*drop  *_curr
	foreach p in eu us yu {
		foreach c in p x {
			*replace mgdpro999i_xlc`p'`c'_curr= mgdpro999i_xlc`p'`c'_curr /npopul999i
			rename  mgdpro999i_xlc`p'`c'_curr `p'`c'
			}
	}
	drop npopul999i
	
* Step 2: calculate the ration GDPPerCap_OL/GDPPerCap_OH
	reshape wide eux eup usx usp yux yup, i(year) j(region) string
		foreach c in p x {
			foreach p in eu us yu {
				replace `p'`c'QF= `p'`c'QF/`p'`c'XB
				}
			}

	drop *XB
	reshape long
* Step 3: calculate the 1- ration for OK
	expand 2, gen(xpnd)
	replace region="QP" if xpnd==1
	drop  year xpnd
	foreach v in eux eup usx usp yux yup {
		replace `v'=1-`v' if region=="QP"
	}
	label data "Generated by aggregate-macro-regions.do"
	save "$work_data/ratioQPQF.dta", replace
restore

* Step 4: Make a copy of macroeconomic variables of OH
preserve
	keep if inlist(region,"XB") //& year<1970
	drop npopul*
	renvars mnninc999i_pppeur-mnninc999i_nomyup, pref("XB")
	expand 2, gen(xpnd)
	replace region="QP" if xpnd==0
	replace region="QF" if xpnd==1
	drop xpnd
	
	tempfile XB_data
	save `XB_data'
restore
* Step 5: Bring OH variables and ratios to the existing macroencomi variables
merge 1:1 region year using "`XB_data'",   nogenerate
merge m:1 region      using "$work_data/ratioQPQF.dta", nogenerate

* Step 6: Fill the macroeconomic variables for the missing years
*    Step 6.1:  Extrapolate proportionaly(based on ratio) the OH data to OK and OL
foreach v of local allvars {
    foreach p in p x {
        foreach c in eu us yu {
            replace `v'_xlc`c'`p'_curr = XB`v'_xlc`c'`p'_curr  * `c'`p'  if inlist(region, "QP", "QF") & year < 1970
        }
    }
}

replace mnninc999i_nomusx= XBmnninc999i_nomusx * usx if inlist(region, "QP", "QF") & year < 1970
replace mnninc999i_nomusp= XBmnninc999i_nomusp * usp if inlist(region, "QP", "QF") & year < 1970
replace mnninc999i_nomeux= XBmnninc999i_nomeux * eux if inlist(region, "QP", "QF") & year < 1970
replace mnninc999i_nomeup= XBmnninc999i_nomeup * eup if inlist(region, "QP", "QF") & year < 1970
replace mnninc999i_nomyux= XBmnninc999i_nomyux * yux if inlist(region, "QP", "QF") & year < 1970
replace mnninc999i_nomyup= XBmnninc999i_nomyup * yup if inlist(region, "QP", "QF") & year < 1970

*    Step 6.2:  Extrapolate proportionaly(based on ratio) the OH data to OK and OL for new NP2025 variables from 1970
foreach v in mtgncx999i mtgxcx999i mtgmcx999i mtgnmx999i mtgxmx999i mtgmmx999i {
    foreach p in p x {
        foreach c in eu us yu {
            replace `v'_xlc`c'`p'_curr = XB`v'_xlc`c'`p'_curr  * `c'`p'  if inlist(region, "QP", "QF") & year < 1970
        }
    }
}
drop XB* eux eup usx usp yux yup

// -------------------------------------------------------------------------- //
* 	3. Generate World Aggregations
// -------------------------------------------------------------------------- //
//------- 3.1 Calculate WO
preserve
	keep if inlist(region, "QE","XB","XF","XL","QL","XN","XR","XS") & year<1970
	ds year region, not
	collapse (sum) npopul001f-npopul999m, by(year) // mnninc999i_nomyup, by(year)
	generate region = "WO"
	
	tempfile world_1800
	save `world_1800'
restore

** Note: here the program sum all the values available for each avariables. For 
**       the 216 core countries after 1970 this will lead to world aggregates. 
**       Before 1950, a world estimation based on the continents will lead to 
**       estimates.
preserve
	* Call country data 
	use "`countries'", clear
	* Keep only corecountries
	merge m:1 iso using "$work_data/import-core-country-codes-output.dta", nogen keepusing(corecountry) 

	* keep only core countries
	keep if corecountry == 1 & year>=1970 //| (inlist(iso, "OA", "OB", "OC", "OD", "OE", "OH", "OI", "OJ", "QM") & year>=1970)

	* Calculate world sum for all the years and variables included
	*ds year iso p, not
	collapse (sum) npopul001f-mnninc999i_nomyup, by(year)
	generate region = "WO"

	tempfile world_1970
	save `world_1970'
restore

append using "`world_1800'"
append using "`world_1970'"
 
 
// -------------------------------------------------------------------------- //
* 	4. Generate currency values, price indexes and xrates .
// -------------------------------------------------------------------------- //

// --------- 4.1 Generate W and Y of the regional variables ----------------- //
* Format
renvars npopul001f-mnninc999i_nomyup, pref("value")
/*
* Calculate W values for the macro variables ( variables as shares of nninc)
foreach v of local agg_var {
	gen double valuew`v'_excusd = valuem`v'_excusd/valuemnninc999i_excusd
}
drop  valuewnninc999i_excusd

* Calculate y values for the macro variables ( variables as shares of gdpro)
foreach v of  local agg_var {
	gen double valuey`v'_excusd = valuem`v'_excusd/valuemgdpro999i_excusd
}
drop  valueygdpro999i_excusd
*/
** Formating
duplicates tag year region, gen(dup)
duplicates tag , gen(dup1)
assert dup == 0 & dup1 == 0
drop dup*


duplicates drop
greshape long value, i(year region) j(widcode) string

assert value==0 if strpos(widcode, "npopul") & !inlist(substr(widcode,7,3),"014", "156", "991", "992", "997", "999") & year<1950
drop            if strpos(widcode, "npopul") & !inlist(substr(widcode,7,3),"014", "156", "991", "992", "997", "999") & year<1950
drop if year<1970 & substr(widcode,1,1) != "n" // Keep only npopul variables before 1970


// --------- 4.2 Use mnninc values for estimating regional price indexes and XR //
preserve
	keep if strpos(widcode, "mnninc999i")
	reshape wide value, i(year region) j(widcode) string
	renvars value*, pred(5)
	// PPPs
	*constant
	//generate valuexlceup999i = mnninc999i_pppusd/mnninc999i_pppeur 
	//generate valuexlcusp999i = mnninc999i_pppusd/mnninc999i_pppusd 
	//generate valuexlcyup999i = mnninc999i_pppusd/mnninc999i_pppcny 
	*nominal 
	generate double valuexlceup999i     = mnninc999i_nomusx/mnninc999i_nomeup 
	generate double valuexlcusp999i     = mnninc999i_nomusx/mnninc999i_nomusp 
	generate double valuexlcyup999i     = mnninc999i_nomusx/mnninc999i_nomyup 
	generate double valuexlceup999i_ppp = mnninc999i_nomusp/mnninc999i_nomeup 
	generate double valuexlcusp999i_ppp = mnninc999i_nomusp/mnninc999i_nomusp 
	generate double valuexlcyup999i_ppp = mnninc999i_nomusp/mnninc999i_nomyup 
	
	// MERs
	*constant
	//generate valuexlceux999i = mnninc999i_excusd/mnninc999i_exceur 
	//generate valuexlcusx999i = mnninc999i_excusd/mnninc999i_excusd 
	//generate valuexlcyux999i = mnninc999i_exceud/mnninc999i_exccny 
	*nominal 
	generate double valuexlceux999i     = mnninc999i_nomusx/mnninc999i_nomeux 
	generate double valuexlcusx999i     = mnninc999i_nomusx/mnninc999i_nomusx 
	generate double valuexlcyux999i     = mnninc999i_nomusx/mnninc999i_nomyux 
	generate double valuexlceux999i_ppp = mnninc999i_nomusp/mnninc999i_nomeux 
	generate double valuexlcusx999i_ppp = mnninc999i_nomusp/mnninc999i_nomusx 
	generate double valuexlcyux999i_ppp = mnninc999i_nomusp/mnninc999i_nomyux 
	
	// Price index 
	generate double valueinyixx999i     = mnninc999i_nomusx/mnninc999i_excusd 
	generate double valueinyixx999i_ppp = mnninc999i_nomusp/mnninc999i_pppusd
	*generate double valueinyixx999i    = mnninc999i_nomusp/mnninc999i_pppusd // former "_exc"
	
	*generate        valueinyusx999i = mnninc999i_nomusx/mnninc999i_excusd
	*generate        valueinyusp999i = mnninc999i_nomusp/mnninc999i_pppusd
	*generate        valueinyyux999i = mnninc999i_nomyux/mnninc999i_exccny
	*generate        valueinyyup999i = mnninc999i_nomyup/mnninc999i_pppcny
	
	keep region year value*
	
	greshape long value, i(region year) j(widcode) string
	drop if missing(value)

	tempfile ppp
	save "`ppp'"
restore

// --------- 4.3 Define PPP and  MER USD values of regions ---------------------- //
// Note: Prior May 2025, the bydefault data of the regions was EUR PPP. Now the 
//       data is presented, as all the other countries, in LCU in Constant prices, 
//       wher the LCU is the USD.

* Drop Nominal Values
drop if inlist(widcode, "mnninc999i_nomeup", "mnninc999i_nomeux", "mnninc999i_nomusp", "mnninc999i_nomusx", "mnninc999i_nomyup", "mnninc999i_nomyux")


*Retain current value aggregations 
drop if (strpos(widcode,"_exc") | strpos(widcode, "_ppp")) 

replace  widcode =  substr(widcode,1,11) + "exc" + substr(widcode,15,2) if /// 
									strpos(widcode,"_curr") & strpos(widcode,"_xlc") & substr(widcode, 17,1)=="x"
replace  widcode =  substr(widcode,1,11) + "ppp" + substr(widcode,15,2) if /// 
									strpos(widcode,"_curr") & strpos(widcode,"_xlc") & substr(widcode, 17,1)=="p"

replace widcode= widcode+"d" 				if  substr(widcode,15,2)=="us"  
replace widcode= widcode+"r" 				if  substr(widcode,15,2)=="eu" 
replace widcode= substr(widcode,1,14)+"cny" if  substr(widcode,15,2)=="yu" 


* Generate PPP regions
generate currency = upper(substr(widcode, -3, 3)) if !strpos(widcode, "npopul")
generate type     = upper(substr(widcode, -6, 3)) if !strpos(widcode, "npopul")
replace type = "-PPP" if type == "PPP"

replace region = region + type if !missing(type) & type == "-PPP"


*We choose to retain the USD
drop if inlist(currency, "CNY", "EUR")
drop type

* Reformat variables names
replace widcode = substr(widcode, 1, 10)


* Call ppp data                        
append using "`ppp'" 

replace region = region + "-PPP" if strpos(widcode, "_ppp") 
replace widcode = substr(widcode,1,10)

* bring WO values to constant prices again
preserve
	keep if inlist(widcode,"inyixx999i")
	keep year region value
	rename value index
	tempfile reg_idx
	save 	`reg_idx'
restore

merge m:1 year region using "`reg_idx'", nogenerate 
replace value=value/index if !missing(index) & substr(widcode,1,1)=="m"
drop index

* Complete the (W) y (Y) for WO
preserve
	keep if inlist(widcode, "mnninc999i", "mgdpro999i")
	drop currency
	
	reshape wide value, i(region year) j(widcode) string
	rename value* *
	
	tempfile nninc_gdpro
	save `nninc_gdpro'
restore

preserve
	keep if substr(widcode,1,1)=="m"
	merge m:1 region year using "`nninc_gdpro'", nogen
	
	gen double valuey = value/mgdpro999i
	gen double valuew = value/mnninc999i
	
	keep region year widcode valuey valuew
	reshape long value, i(region year  widcode) j(onelet) string
	replace widcode= onelet + substr(widcode,2,9)
	drop onelet
	
	drop if inlist(widcode,"ygdpro999i", "wmnninc999i")
	gen new=1
	
	tempfile reg_yw
	save `reg_yw'
restore

append using "`reg_yw'"
duplicates tag region year widcode, gen (dup)
drop if dup==1 & new==1
duplicates tag region year widcode, gen (dup2)
asser dup2==0
drop dup* new

// --------- 4.3 Extend Populations to PPP regions ---------------------- //
expand 2 if strpos(widcode,"npopul"), gen(xpnd)
replace region=region+"-PPP" if xpnd==1
drop xpnd

// --------- 4.4 Call intlcu for regions  ----------------------------------- //
preserve
	use  "$work_data/nievaspiketty2025_70.dta", clear
	*merge 1:1 iso year widcode using "`dietrish'", nogen keep(match master) 
	*replace value = value_d if !missing(value_d)
	*drop value_d
	
	* Deep relevant observations
	keep if year>=1970
	keep if widcode=="intlcu999i" 
	keep if inlist(substr(iso, 1, 1), "X", "O") | inlist(iso,"QL", "QM","WO","QE")
	
	* Complete data for QF and QP (North america and Oceania)
	expand 2 if iso=="XB",gen(xpnd)
	replace iso="QF" if xpnd==1
	drop xpnd
	
	expand 2 if iso=="XB",gen(xpnd)
	replace iso="QP" if xpnd==1
	drop xpnd
	
	* Complete data for OK and OL (Other North america and other Oceania)
	expand 2 if iso=="OH",gen(xpnd)
	replace iso="OK" if xpnd==1
	drop xpnd
	
	expand 2 if iso=="OH",gen(xpnd)
	replace iso="OL" if xpnd==1
	drop xpnd
	

	
	
	rename iso region

	tempfile intlcu_70
	save 	`intlcu_70'
restore

append using "`intlcu_70'"
/*
preserve
	keep if widcode=="inyixx999i" & !strpos(region,"-PPP") & year==2022 // last year of Nievas piketty
	keep  region value
	rename value inyixx_23
	tempfile  indx_xlc
	save `indx_xlc'
restore
*/


// --------- 4.5 Format for appending  ----------------------------------- //
gen new=1
replace p="pall" if missing(p)
rename region iso
drop if missing(value)

* clean variables that were unavailable 1970-1980 ( they values should be 0 anyways)
gen flag= 1    if  (inlist(substr(widcode, 2, 5), "gweal", "hweal", "nweal", "pweal")  & year<1980) 

replace flag= 1	if (inlist(substr(widcode, 2, 5), "nwnfa", "nwhou", "nwbus", "nwagr", "nwboo") ///  "mnweal",
				| 	inlist(substr(widcode, 2, 5), "nwdka", "cwres", "cwtoq", "gwass", "pwnfa", "pwhou", "pwbus", "pwagr") ///  ,"mpweal"
				| 	inlist(substr(widcode, 2, 5), "pwodk", "pwfin", "pwfiw", "pweqi", "pwpen", "pwdeb", "iweal", "cwboo") ///  ,"mhweal"
				| 	inlist(substr(widcode, 2, 5), "cwnfa", "cwhou", "cwbus", "cwfin", "cwdeb", "cwdeq", "gwnfa", "gwhou") ///  ,"mgweal"
				| 	inlist(substr(widcode, 2, 5), "gwbus", "gwfin", "gwdeb"))  & year<1980 //

replace flag= 1 if (inlist(substr(widcode, 2, 5), "ptxgo", "gvato", "gvago", "ceugo", "gsrgo", "nsrgo", "cfcgo", "gvaco") | ///
				    inlist(substr(widcode, 2, 5), "ceuco", "gsrco", "nsrco", "cfcco", "gvahn", "ceuhn", "gmxhn", "nmxhn") | ///
				    inlist(substr(widcode, 2, 5), "ccmhn", "gsrhn", "nsrhn", "ccshn")) & year<1980 

drop if flag==1
drop flag

tempfile full_post_1970
save `full_post_1970'



// -------------------------------------------------------------------------- //
* 	7. Final Formating and export
// -------------------------------------------------------------------------- //
 
// --------- 7.1. Pile regions -------------------------------------------- //
use "$work_data/add-wealth-aggregates-output.dta", clear
append using  "`full_post_1970'"
duplicates tag iso year widcode p, gen(dup)
drop if new!=1 & dup==1
duplicates tag iso year widcode p, gen(dup2)
assert dup2==0
drop dup* new


// --------- 7.3.  Save ----------------------------------------------------- //
compress

sort iso year widcode p
label data "Generated by aggregate-macro-regions.do"
save "$work_data/aggregate-regions-output.dta", replace

// -------------------------------------------------------------------------- //
* 8. Create metadata
// -------------------------------------------------------------------------- //

use "`full_post_1970'", clear
generate sixlet = substr(widcode, 1, 6)
keep iso sixlet
drop if substr(sixlet, 1, 3) == "xlc"
gduplicates drop
generate source = "WID.world (see individual countries for more details)"
generate method = "WID.world aggregations of individual country data"

append using "$work_data/add-wealth-aggregates-metadata.dta"


save "$work_data/aggregate-regions-metadata.dta", replace


