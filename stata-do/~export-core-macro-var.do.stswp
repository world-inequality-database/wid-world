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
use "$work_data/calculate-per-capita-series-output.dta", clear
*use "/Users/rowaidamoshrif/Downloads/merge-historical-aggregates (22).dta", clear
keep if (substr(widcode, 1, 1) == "m" | substr(widcode, 1, 1) == "w" | substr(widcode, 1, 1) == "y")
generate fivelet = substr(widcode, 2, 5)
levelsof fivelet, local(fivelet)
**
use "$work_data/calculate-per-capita-series-output.dta", clear
*use "/Users/rowaidamoshrif/Downloads/merge-historical-aggregates (22).dta", clear
replace p = "p0p100" if p=="pall"

generate fivelet = substr(widcode, 2, 5)
generate tokeep = 0

drop if p!="p0p100"

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

*replace tokeep = 0 if inlist(substr(fivelet, 1, 2), "gw")

/*
levelsof fivelet if inlist(substr(widcode, 1, 1), "s", "t", "o"), local(fivelet_2)
foreach l in `fivelet_2' {
	replace tokeep = 0 if fivelet == "`l'" 
}
*/

keep if tokeep == 1
drop if inlist(widcode, "aTH999992i", "aTH999999i", "mTH999i", "wicwtoq999i", "micwtoq999i") 




replace value = round(value, 0.1)    if inlist(substr(widcode, 1, 1), "a", "t")
replace value = round(value, 1)      if inlist(substr(widcode, 1, 1), "m", "n")
replace value = round(value, 0.0001) if inlist(substr(widcode, 1, 1), "s","y","w")
drop if strpos(iso, "XX")
drop if iso == "KV"
drop if missing(year)

replace data_quality = round(data_quality, 1)     

keep iso year p widcode value data_quality
order iso year p widcode value data_quality




// Prepare to export
//------------- wealth only available until 2023
*gen flag= 1	if  ( inlist(substr(widcode, 2, 5), "nwnfa","nwhou","nwbus","nwagr","nwboo") ///  "mnweal",
				| inlist(substr(widcode, 2, 5), "nwdka","cwres","cwtoq","gwass","pwnfa","pwhou","pwbus","pwagr") ///  ,"mpweal"
				| inlist(substr(widcode, 2, 5), "pwodk","pwfin","pwfiw","pweqi","pwpen","pwdeb","iweal","cwboo") ///  ,"mhweal"
				| inlist(substr(widcode, 2, 5), "cwnfa","cwhou","cwbus","cwfin","cwdeb","cwdeq","gwnfa","gwhou") ///  ,"mgweal"
				| inlist(substr(widcode, 2, 5), "gwbus","gwfin","gwdeb"))  & year==2024
				
*drop if  flag==1 & value==0
*drop if year=2024 & strpos(widcode,"nwnxa")
*drop flag

*gen regions=0

tempfile core_macro
save `core_macro'

//---------------- Temporary -----------------------
/*
drop regions
gen region = 1 if (inlist(substr(iso, 1, 1), "X", "O") & !inlist(iso,"OM","XI")) | inlist(substr(iso, 1, 2), "QL","QM","WO","QE","QP","QF")
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

gen regions=1

tempfile regions
save `regions'
*/
/*
rename iso Alpha2
rename p   perc
order Alpha2 year perc widcode

preserve
	keep if inlist(substr(Alpha2,1,2),"QF","QP")
	*export delim "$output_dir/$time/wid-data-$time-macro-var-$year-QFQP.csv", delimiter(";") replace
restore

foreach onelet in w  { //a i m n  w y x { //   p
	preserve
		keep if substr(widcode,1,1)=="`onelet'"
		di "Exporting `onelet'..."
		*export delim "$output_dir/$time/wid-data-$time-macro-var-$year_`onelet'_regions.csv", delimiter(";") replace
	restore
}
*/
//--------------------------------------------------
/*
use "`core_macro'", clear
*append using "`regions'"

duplicates tag iso year widcode p, gen(dup)
drop if dup==1 & regions!=1
duplicates tag iso year widcode p, gen(dup2)
assert dup2==0
drop dup*


rename iso Alpha2
rename p   perc
order Alpha2 year perc widcode


preserve
	*drop if Alpha2=="RU"
	*keep if year==2024
	gen flag=0
	replace flag= 1 if  inlist(substr(widcode, 2, 5), "ptxgo", "gvato", "gvago", "ceugo", "gsrgo", "nsrgo", "cfcgo", "gvaco") | ///
				    inlist(substr(widcode, 2, 5), "ceuco", "gsrco", "nsrco", "cfcco", "gvahn", "ceuhn", "gmxhn", "nmxhn") | ///
				    inlist(substr(widcode, 2, 5), "ccmhn", "gsrhn", "nsrhn", "ccshn","confc")
	replace flag= 1 if  inlist(substr(widcode, 1, 6), "ylsgdp", "ylsndp", "ycsgdp", "ycsndp", "wlsgni", "wlsnni", "wcsgni") | ///
						inlist(substr(widcode, 1, 6),"wcsnni", "ylscgv", "ylscnv", "ycscgv","ycscnv")
	keep if flag==1 
	drop flag regions
	
	gen region = 1 if (inlist(substr(Alpha2, 1, 1), "X", "O") & !inlist(Alpha2,"OM","XI")) | inlist(substr(Alpha2, 1, 2), "QL","QM","WO","QE","QP","QF")
	drop if region == 1  & substr(Alpha2,3,1)!="-"
	drop region
	*export delim "$output_dir/$time/wid-data-$time-macro-var-$year-dietrischetal25.csv", delimiter(";") replace
restore

preserve
	keep if p=="p0p100" | p=="pall"
	gen flag=0
	replace flag= 1 if  inlist(substr(widcode, 2, 5), "ptxgo", "gvato", "gvago", "ceugo", "gsrgo", "nsrgo", "cfcgo", "gvaco") | ///
						inlist(substr(widcode, 2, 5), "ceuco", "gsrco", "nsrco", "cfcco", "gvahn", "ceuhn", "gmxhn", "nmxhn") | ///
						inlist(substr(widcode, 2, 5), "ccmhn", "gsrhn", "nsrhn", "ccshn","confc")
	replace flag= 1 if  inlist(substr(widcode, 1, 6), "ylsgdp", "ylsndp", "ycsgdp", "ycsndp", "wlsgni", "wlsnni", "wcsgni") | ///
						inlist(substr(widcode, 1, 6), "wcsnni", "ylscgv", "ylscnv", "ycscgv","ycscnv")
						
	replace flag= 1	if 	( inlist(substr(widcode, 2, 5),widcode, "cwagr", "cwbol", "cwboo", "cwbus", "cwcud", "cwdeb", "cwdeq", "cwdwe") ///
						| inlist(substr(widcode, 2, 5),widcode, "cwequ", "cwfie", "cwfin", "cwfiw", "cwhou", "cwlan", "cwnat", "cwnfa") ///
						| inlist(substr(widcode, 2, 5),widcode, "cwoff", "cwpen", "cwres", "gwagr", "gwass", "gwbol", "gwbus", "gwcud"))
	replace flag= 1	if  ( inlist(substr(widcode, 2, 5),widcode, "gwdec", "gwdwe", "gweal", "gweqi", "gwequ", "gwfie", "gwfin", "gwfiw") ///
						| inlist(substr(widcode, 2, 5),widcode, "gwlan", "gwnat", "gwnfa", "gwodk", "gwoff", "gwpen", "hwagr", "hwbol") ///
						| inlist(substr(widcode, 2, 5),widcode, "hwcud", "hwdeb", "hwdwe", "hweal", "hweqi", "hwequ", "hwfie", "hwfin"))
	replace flag= 1	if  ( inlist(substr(widcode, 2, 5),widcode, "hwhou", "hwlan", "hwnat", "hwnfa", "hwodk", "hwoff", "hwpen",  "iwagr") ///
						| inlist(substr(widcode, 2, 5),widcode, "iwbol", "iwbus", "iwcud", "iwdeb", "iwdwe", "iweal", "iweqi", "iwequ") ///
						| inlist(substr(widcode, 2, 5),widcode, "iwfin", "iwfiw", "iwhou", "iwlan", "iwnat", "iwnfa", "iwodk", "iwoff"))
	replace flag= 1	if  ( inlist(substr(widcode, 2, 5),widcode, "nwagr", "nwboo", "nwbus", "nwdka", "nwdwe", "nweal", "nwgxa", "nwgxd") ///
						| inlist(substr(widcode, 2, 5),widcode, "nwlan", "nwnat", "nwnfa", "nwnxa", "nwodk", "nwoff", "pwagr", "pwbol") ///
						| inlist(substr(widcode, 2, 5),widcode, "pwcud", "pwdeb", "pwdwe", "pweal", "pweqi", "pwequ", "pwfie", "pwfin"))
	replace flag= 1	if  ( inlist(substr(widcode, 2, 5),widcode, "pwhou", "pwlan", "pwnat", "pwnfa", "pwodk", "pwoff", "pwpen") ///
						| inlist(substr(widcode, 2, 5),widcode, "cweqi", "cwodk", "gwdeb", "gwhou", "hwbus", "hwfiw", "iwfie", "iwpen") ///
						| inlist(substr(widcode, 2, 5),widcode, "nwhou", "pwbus", "pwfiw"))
	replace flag=1 if strpos(widcode,"icwtoq")
	keep if flag==1 
	drop flag regions
	
	gen region = 1 if (inlist(substr(Alpha2, 1, 1), "X", "O") & !inlist(Alpha2,"OM","XI")) | inlist(substr(Alpha2, 1, 2), "QL","QM","WO","QE","QP","QF")
	drop if region == 1  & substr(Alpha2,3,1)!="-"
	drop region
	*export delim "$output_dir/$time/wid-data-$time-macro-var-$year-wealth_diertchetal25.csv", delimiter(";") replace
restore


preserve
	keep if Alpha2=="ZW"
	keep if substr(widcode,1,3)=="xlc"
	drop regions
	*export delim "$output_dir/$time/wid-data-$time-macro-var-$year-ZWconvFact.csv", delimiter(";") replace
restore

preserve
	drop if Alpha2=="RU"
	*keep if year==2024
	drop regions
	*export delim "$output_dir/$time/wid-data-$time-macro-var-$year.csv", delimiter(";") replace
restore

preserve
	keep if year<2024
	keep if region==1
	drop regions
	keep if substr(widcode,1,1)=="w"
	*export delim "$output_dir/$time/wid-data-$time-macro-var-$year-reg_w.csv", delimiter(";") replace
restore

preserve
	*keep if strpos(Alpha2,"-PPP")
	keep if region==1
	drop regions
	*drop if strpos(Alpha2,"-MER") & !inlist(widcode,"xlceup999i","xlceux999i","xlcusp999i","xlcusx999i","xlcyup999i","xlcyux999i") 
	*export delim "$output_dir/$time/wid-data-$time-macro-var-$year-reg.csv", delimiter(";") replace
restore

foreach onelet in a i m n  w y x { //   p
	preserve
		keep if substr(widcode,1,1)=="`onelet'"
*		export delim "$output_dir/$time/wid-data-$time-macro-var-$year_var_`onelet'.csv", delimiter(";") replace
	restore
	
}

*/

preserve
	rename iso Alpha2
	rename p   perc
	order Alpha2 year perc widcode value data_quality
	export delim "$output_dir/$time/wid-data-$time-macro-var-2026.csv", delimiter(";") replace
restore


//------------------------------------------------------------------------------
//  Macro update Metadata
//------------------------------------------------------------------------------

u "`core_macro'", clear
generate sixlet = substr(widcode, 1, 6)
ds year p widcode value data_quality, not
keep `r(varlist)'
duplicates drop iso sixlet, force


merge m:1 iso sixlet using "$work_data/generate-macro-metadata.dta" , keep(match) nogen

* Drop the distrubutional fivelets, it will be exported in the distribution part
drop if inlist(substr(sixlet,2,5),"hweal","ptinc","fiinc","cainc")
 
rename iso Alpha2
generate twolet = substr(sixlet, 2, 2)
generate threelet = substr(sixlet, 4, 3)

keep Alpha2 twolet threelet method source 
duplicates drop

duplicates tag Alpha2 twolet threelet, gen(dup)
assert dup==0
drop dup

sort Alpha2 twolet threelet

gen data_quality  =. 
gen    imputation = ""
gen extrapolation = ""
gen   data_points = ""
gen data_quality_score=.

sort Alpha2 twolet threelet
order Alpha2 twolet threelet method source data_quality imputation extrapolation data_points data_quality_score
export delim "$output_dir/$time/metadata/var-notes-$time-macro-var-2026.csv", delimiter(";") replace

/*
