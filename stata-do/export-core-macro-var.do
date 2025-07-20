clear all 
/*
use "/Users/rowaidamoshrif/Downloads/merge-historical-aggregates (11).dta", clear

// keep if (substr(widcode, 1, 1) == "m" | substr(widcode, 1, 1) == "a" | substr(widcode, 1, 1) == "w")
keep if  inlist(substr(widcode, 1, 6), "npopul") ///
	   | inlist(substr(widcode, 2, 5), "nninc", "ndpro", "gdpro") ///
	   | inlist(substr(widcode, 2, 5), "nnfin", "finrx", "finpx", "comnx", "pinnx", "nwnxa", "nwgxa", "nwgxd") ///
	   | inlist(substr(widcode, 2, 5), "comhn", "fkpin", "confc", "comrx", "compx", "pinrx", "pinpx", "fdinx") ///
	   | inlist(substr(widcode, 2, 5), "fdirx", "fdipx", "ptfnx", "ptfrx", "ptfpx", "flcin", "flcir", "flcip") ///
	   | inlist(substr(widcode, 2, 5), "ncanx", "tbnnx", "comnx", "opinx", "scinx", "tbxrx", "tbmpx", "opirx") ///
	   | inlist(substr(widcode, 2, 5), "opipx", "scirx", "scipx", "fkarx", "fkapx", "fkanx") ///
	   | inlist(substr(widcode, 2, 5), "taxnx", "fsubx", "ftaxx") ///
	   | inlist(substr(widcode, 2, 5), "nyixx", "lceux", "lceup", "lcyux", "lcyup", "lcusx", "lcusp") ///
	   | inlist(substr(widcode, 2, 5), "expgo", "gpsge", "defge", "polge", "ecoge", "envge", "houge", "heage") ///
	   | inlist(substr(widcode, 2, 5), "recge", "eduge", "edpge", "edsge", "edtge", "sopge", "spige", "sacge") ///
	   | inlist(substr(widcode, 2, 5), "sakge", "revgo", "pitgr", "citgr", "scogr", "pwtgr", "intgr", "ottgr") ///
	   | inlist(substr(widcode, 2, 5), "ntrgr", "psugo", "retgo") 
	   
	   *| inlist(substr(widcode, 2, 5), "", "", "", "", "", "", "", "")
	   

replace p = "p0p100"
replace value = round(value, 0.1)    if inlist(substr(widcode, 1, 1), "a", "t")
replace value = round(value, 1)      if inlist(substr(widcode, 1, 1), "m", "n")
replace value = round(value, 0.0001) if inlist(substr(widcode, 1, 1), "s")
drop if strpos(iso, "XX")
drop if missing(year)
keep iso year p widcode value 

rename iso Alpha2
rename p   perc
order Alpha2 year perc widcode
export delim "$output_dir/$time/wid-data-$time-core-macro.csv", delimiter(";") replace
*/
//------------------------------------------------------------------------------
// Macro update Data
//------------------------------------------------------------------------------


clear all 
**
use "$work_data/merge-historical-aggregates.dta", clear
*use "/Users/rowaidamoshrif/Downloads/merge-historical-aggregates (22).dta", clear
keep if (substr(widcode, 1, 1) == "m" | substr(widcode, 1, 1) == "w" | substr(widcode, 1, 1) == "y")
generate fivelet = substr(widcode, 2, 5)
levelsof fivelet, local(fivelet)
**
use "$work_data/merge-historical-aggregates.dta", clear
*use "/Users/rowaidamoshrif/Downloads/merge-historical-aggregates (22).dta", clear

generate fivelet = substr(widcode, 2, 5)
generate tokeep = 0

foreach l in `fivelet' {
	replace tokeep = 1 if fivelet == "`l'"
}
replace tokeep = 1 if inlist(substr(widcode, 1, 6), "npopul")
replace tokeep = 1 if inlist(substr(widcode, 2, 5), "nyixx", "ntlcu", "rerus", "lceux", "lceup", "lcyux", "lcyup", "lcusx", "lcusp")
*replace tokeep = 1 if inlist(substr(widcode, 1, 6), "npopul", "intlcu")
replace tokeep = 0 if inlist(substr(widcode, 1, 1), "s", "t", "o")
replace tokeep = 0 if inlist(substr(widcode, 2, 5), "fdimp", "fdion", "fdiop", "fdior",           "fkfiw", "nwoff")
replace tokeep = 0 if inlist(substr(widcode, 2, 5), "ptfor",           "ptfhr", "ptfon", "ptfop", "ptfop", "comco")
replace tokeep = 0 if inlist(substr(widcode, 2, 5), "comgo", "comnf", "comfc")
replace tokeep = 0 if inlist(substr(widcode, 2, 5), "gninc", "wealg", "wealh", "weali", "wealn") // Obsolet variables
replace tokeep = 0 if inlist(substr(widcode, 2, 5), "gwass", "cwtoq", "icwto")  // new variables unincluded variables
replace tokeep = 0 if inlist(substr(widcode, 2, 5), "cwequ", "gwequ","hwequ","iwequ","pwequ")
replace tokeep = 1 if widcode=="icwtoq999i"
replace tokeep = 0 if inlist(widcode, "wlabsh999i","wcapsh999i")

replace tokeep = 0 if inlist(substr(fivelet, 1, 2), "gw")

/*
levelsof fivelet if inlist(substr(widcode, 1, 1), "s", "t", "o"), local(fivelet_2)
foreach l in `fivelet_2' {
	replace tokeep = 0 if fivelet == "`l'" 
}
*/

keep if tokeep == 1
drop if inlist(widcode, "aTH999992i", "aTH999999i", "mTH999i",, "wicwtoq999i", "micwtoq999i")) 


replace p = "p0p100"
replace value = round(value, 0.1)    if inlist(substr(widcode, 1, 1), "a", "t")
replace value = round(value, 1)      if inlist(substr(widcode, 1, 1), "m", "n")
replace value = round(value, 0.0001) if inlist(substr(widcode, 1, 1), "s","y","w")
drop if strpos(iso, "XX")
drop if iso == "KV"
drop if missing(year)
keep iso year p widcode value 

tempfile core_macro
save `core_macro'


// Prepare to export
//------------- wealth only available until 2023
gen flag= 1	if  ( inlist(substr(widcode, 2, 5), "nwnfa","nwhou","nwbus","nwagr","nwboo") ///  "mnweal",
				| inlist(substr(widcode, 2, 5), "nwdka","cwres","cwtoq","gwass","pwnfa","pwhou","pwbus","pwagr") ///  ,"mpweal"
				| inlist(substr(widcode, 2, 5), "pwodk","pwfin","pwfiw","pweqi","pwpen","pwdeb","iweal","cwboo") ///  ,"mhweal"
				| inlist(substr(widcode, 2, 5), "cwnfa","cwhou","cwbus","cwfin","cwdeb","cwdeq","gwnfa","gwhou") ///  ,"mgweal"
				| inlist(substr(widcode, 2, 5), "gwbus","gwfin","gwdeb"))  & year==2024
drop if  flag==1 & value==0
drop flag


//---------------- Temporary -----------------------
gen region = 1 if (inlist(substr(iso, 1, 1), "X", "O") & !inlist(iso,"OM","XI")) | inlist(substr(iso, 1, 2), "QL","QM","WO","QE")
keep if region==1
drop region
gen      type = substr(iso,4,3)  
replace  type = "MER"            if missing(type)
replace   iso = substr(iso,1,2)	  

reshape wide value, i(iso year widcode p) j(type) string

replace valuePPP=valueMER if inlist(substr(widcode,1,1),"x","i") & missing(valuePPP)
replace valueMER=valuePPP if inlist(substr(widcode,1,1),"x") & missing(valueMER)
gen valueA = valuePPP

reshape long value, i(iso year p widcode) j(type) string
replace iso = iso + "-" + type if inlist(type,"MER","PPP")
drop type

rename iso Alpha2
rename p   perc
order Alpha2 year perc widcode

foreach onelet in a i m n  w y x { //   p
	preserve
		keep if substr(widcode,1,1)=="`onelet'"
		di "Exporting `onelet'..."
		export delim "$output_dir/$time/wid-data-$time-macro-var-$year_var_`onelet'_regions.csv", delimiter(";") replace
	restore
}
//--------------------------------------------------

use "`core-macro'"

rename iso Alpha2
rename p   perc
order Alpha2 year perc widcode

foreach onelet in a i m n  w y x { //   p
	preserve
		keep if substr(widcode,1,1)=="`onelet'"
*		export delim "$output_dir/$time/wid-data-$time-macro-var-$year_var_`onelet'.csv", delimiter(";") replace
	restore
	
}


/*
preserve
	rename iso Alpha2
	rename p   perc
	order Alpha2 year perc widcode
	export delim "$output_dir/$time/wid-data-$time-macro-var-2024.csv", delimiter(";") replace
restore
/*

//------------------------------------------------------------------------------
//  Macro update Metadata
//------------------------------------------------------------------------------
/*
u "`core-macro'", clear
generate sixlet = substr(widcode, 1, 6)
ds year p widcode value , not
keep `r(varlist)'
duplicates drop iso sixlet, force


merge m:1 iso sixlet using "$work_data/calculate-wealth-income-ratio-metadata.dta" 
keep if inlist(_merge,1,3)
 
rename iso alpha2
generate twolet = substr(sixlet, 2, 2)
generate threelet = substr(sixlet, 4, 3)

keep alpha2 twolet threelet method source data_quality imputation extrapolation data_points
duplicates drop 

sort alpha2 alpha2 twolet threelet
order alpha2 twolet threelet method source data_quality imputation extrapolation data_points
export delim "$output_dir/$time/metadata/var-notes-$time-macro-var-2024.csv", delimiter(";") replace

/*
