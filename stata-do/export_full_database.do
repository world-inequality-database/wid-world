clear all 
//------------------------------------------------------------------------------
// Macro update Data
//------------------------------------------------------------------------------


clear all 
**
use "$work_data/calculate-per-capita-series-output.dta", clear
*use "/Users/rowaidamoshrif/Downloads/merge-historical-aggregates (22).dta", clear
keep if (substr(widcode, 1, 1) == "m" | substr(widcode, 1, 1) == "w" | substr(widcode, 1, 1) == "y")
generate fivelet = substr(widcode, 2, 5)
levelsof fivelet, local(fivelet)
**
use "$work_data/calculate-per-capita-series-output.dta", clear
*use "/Users/rowaidamoshrif/Downloads/merge-historical-aggregates (22).dta", clear

generate fivelet = substr(widcode, 2, 5)
generate tokeep = 0

foreach l in `fivelet' {
	replace tokeep = 1 if fivelet == "`l'"
}
replace tokeep = 1 if inlist(substr(widcode, 1, 6), "npopul")
replace tokeep = 1 if inlist(substr(widcode, 2, 5), "nyixx", "ntlcu", "lceux", "lceup", "lcyux", "lcyup", "lcusx", "lcusp")
*replace tokeep = 1 if inlist(substr(widcode, 2, 5), "rerus", "rereu", "reryu")
replace tokeep = 0 if inlist(substr(widcode, 1, 1), "s", "t", "o")
replace tokeep = 0 if inlist(substr(widcode, 2, 5), "fdimp", "fdion", "fdiop", "fdior",           "fkfiw", "nwoff")
replace tokeep = 0 if inlist(substr(widcode, 2, 5), "ptfor",           "ptfhr", "ptfon", "ptfop", "ptfop", "comco")
replace tokeep = 0 if inlist(substr(widcode, 2, 5), "comgo", "comnf", "comfc")
replace tokeep = 0 if inlist(substr(widcode, 2, 5), "gninc", "wealg", "wealh", "weali", "wealn") // Obsolet variables
replace tokeep = 0 if inlist(substr(widcode, 2, 5), "gwass", "cwtoq", "icwto")  // new variables unincluded variables
replace tokeep = 0 if inlist(substr(widcode, 2, 5), "cwequ", "gwequ", "hwequ", "iwequ", "pwequ")


replace tokeep = 0 if inlist(substr(widcode, 2, 5), "ceufc", "ceuho", "ceunf", "ceunp","wealp","cwcub","gwcub") 
replace tokeep = 0 if inlist(substr(widcode, 2, 5), "cwnat","iwnat","nwnat", "gwnat")
replace tokeep = 0 if inlist(substr(widcode, 2, 5), "gvbco", "gvbfc", "gvbgo", "gvbhn", "gvbho", "gvbnf", "gvbnp")
replace tokeep = 0 if inlist(substr(widcode, 2, 5), "lscgv","lscnv","lsgdp","lsgni","lsndp","lsnni")
replace tokeep = 0 if inlist(substr(widcode, 2, 5), "sbpco","sbpfc","sbpgo","sbphn","sbpho","sbpnf","sbpnp")
replace tokeep = 0 if inlist(substr(widcode, 2, 5), "tapco","tapfc","tapgo","taphn","tapho","tapnf","tapnp")
replace tokeep = 0 if inlist(substr(widcode, 2, 5), "tspco","tspfc","tspgo","tsphn","tspho","tspnf","tspnp")
replace tokeep = 0 if inlist(substr(widcode, 2, 3), "csc","csg","csn")

replace tokeep = 1 if widcode=="icwtoq999i"
replace tokeep = 0 if inlist(widcode, "wlabsh999i","wcapsh999i")



keep if tokeep == 1
drop if inlist(widcode, "aTH999992i", "aTH999999i", "mTH999i", "wicwtoq999i", "micwtoq999i") 


replace p = "p0p100" if p=="pall"

replace value = round(value, 0.1)    if inlist(substr(widcode, 1, 1), "a", "t")
replace value = round(value, 1)      if inlist(substr(widcode, 1, 1), "m", "n")
replace value = round(value, 0.0001) if inlist(substr(widcode, 1, 1), "s","y","w")
drop if strpos(iso, "XX")
drop if iso == "KV"
drop if missing(year)
keep iso year p widcode value 




// Prepare to export
rename iso Alpha2
rename p   perc
order Alpha2 year perc widcode

tempfile core_macro
save `core_macro'



u "$work_data/calculate-gini-coef-output.dta", clear


// ------- 7. Export the distributions to data to CSV --------------------------
replace value = round(value, 0.1)    if inlist(substr(widcode, 1, 1), "a", "t")
replace value = round(value, 1)      if inlist(substr(widcode, 1, 1), "m", "n")
replace value = round(value, 0.0001) if inlist(substr(widcode, 1, 1), "s")
					  
drop if missing(value)
keep iso year p widcode value 

rename iso Alpha2
rename p   perc
order Alpha2 year perc widcode

keep if strpos(widcode,"ptinc") | strpos(widcode,"diinc") | strpos(widcode,"hweal") | strpos(widcode,"fainc") | strpos(widcode,"fiinc") | strpos(widcode,"cainc")
keep if inlist(substr(widcode, 1, 1), "a", "t", "s")
keep if (strpos(widcode,"992j")  |  strpos(widcode,"999j")) |  (strpos(widcode,"992i") | strpos(widcode,"fiinc"))
drop if (strpos(widcode,"fiinc")) & !strpos(widcode,"992i") 
drop if (strpos(widcode,"cainc")) & !strpos(widcode,"992j") 

tempfile core_distri
save `core_distri'



u "$work_data/calculate-gini-coef-output.dta", clear
drop if missing(value)
keep iso year p widcode value 

replace value = round(value, 0.0001) if inlist(substr(widcode, 1, 1), "r","b","g")
drop if iso=="XX"

rename iso Alpha2
rename p   perc
order Alpha2 year perc widcode

keep if inlist(substr(widcode, 1, 1), "r", "b", "g")
keep if strpos(widcode,"ptinc") | strpos(widcode,"diinc") | strpos(widcode,"hweal") | strpos(widcode,"fainc") | strpos(widcode,"fiinc") | strpos(widcode,"cainc")

keep if (strpos(widcode,"992j")  |  strpos(widcode,"999j")) |  (strpos(widcode,"992i") | strpos(widcode,"fiinc"))
drop if (strpos(widcode,"fiinc")) & !strpos(widcode,"992i") 
drop if (strpos(widcode,"cainc")) & !strpos(widcode,"992j") 
replace value = round(value, 0.0001)

	
tempfile core_index
save `core_index'


append using "`core_distri'"
append using "`core_macro'"

export delim "$output_dir/$time/wid-data-$time-2025_Update_whole.csv", delimiter(";") replace


