//------------------------------------------------------------------------------
//            Merge Historical aggregates .do-File
//------------------------------------------------------------------------------

// Objetive: Integrate and calibrate the historical series on nninc and nopul to
// the WID data  dataset.

// Note 25/08/25: Following the availablility of complete poplation series 
//      from Federico-tena and the long run series from Nievas Piketty(2025) and 
//      Diertich et at.(2025) this new version of the file  appends the available 
//      historical series of WBOP and Institutional sectors for the 58 core-
//      territories.

/// Note: while calcualtationf in aggregate-macro regions are mad efrom the 1970, the trught is that the small cotuntries presente missing data from during the 70's. That is why the merge of Diertrich et al happends from 1980, rewriting the data in 1970.

// --------------- 0.  Index -------------------------------------------------//
//  1. Call necessary data from WID
//  2. Merge Historical regions from Nievas & Piketty (2025), Dietrich et al.(2025) and Bauluz et al.(2025)
//      2.1.  Bring wealth to product ratios (y)
//		2.2.  Rebase the price index to the $pastyear
//  	2.4.  Calculate mnninc999i and mndpro999i 
//      2.3.  Generate constant $pastyear monetary values
//      2.5.  Calculate wealth to income ratios (w)
// 		2.6.  Extend exchange rate to regions-MER before 1970 
// 		2.7.  Extend PPP to regions-MER before 1970
//		2.8.  Extend exchange rate to regions-MER before 1970
//      2.9.  Complete Price index for regions -PPP  
//      2.10. Extend Population to regions-PPP  (obsolete)
// 		2.11. Extend aggregates  to regions-PPP
//      2.12. Complete intclu 
//      2.13. Exclusion checks
//  3. Merge Historical countries from Nievas & Piketty (2025)
//  4. Final Formating and export
//      4.1. Pile countries 
//      4.2. Add regions
//      4.3.  Save
//  5. Create metadata
//------------------------------------------------------------------------------

// -------------------------------------------------------------------------- //
* 	1. Call necessary data from WID
// -------------------------------------------------------------------------- //
use "$work_data/aggregate-regions-output.dta", clear

keep if inlist(substr(widcode, 1, 6), "xlcusx", "xlcusp", "xlceux", "xlceup", "xlcyux", "xlcyup") /// 
	  | inlist(substr(widcode, 1, 6), "inyixx","mgdpro","ynninc","mnnfin") /// ,"npopul") // , "intlcu","xrerus") ///
	  | inlist(substr(widcode, 1, 6), "yhweal", "ypweal", "mhweal", "mpweal")
drop currency

* Call historical population for regions
/*
preserve
	keep if inlist(substr(iso, 1, 1), "X", "O") | inlist(iso,"QL", "QM","WO","QE","QF","QP")
	drop if inlist(iso,"OM")
	keep if year<1970
	keep  if strpos(widcode,"npopul")
	rename iso region
	 gen wid=1
	
	tempfile hist_pop_reg
	save    `hist_pop_reg'
restore
*/

reshape wide value, i(iso year p) j (widcode) string

* call updated price index for NP data in 2023 prices
preserve	
	keep if !strpos(iso,"-PPP") & year==2023 // last year of Nievas piketty
	keep  iso valueinyixx999i
	rename (iso valueinyixx999i) (region inyixx_23)
	
	tempfile  indx_xlc
	save `indx_xlc'
restore

* Estimate ratio hweal/pweal in 1980
preserve
	keep if year==1980
	
	*complete y variables( this is no yet calcuated for the countries)
	replace valueypweal999i=valuemhweal999i/valuemgdpro999i if missing(valueypweal999i)
	replace valueyhweal999i=valuempweal999i/valuemgdpro999i if missing(valueyhweal999i)
	
	gen rat_weal=valueyhweal999i/valueypweal999i
	drop if missing(rat_weal)
	
	keep iso rat_weal
	
	gen region=iso
	
	tempfile rat_weal_80
	save    `rat_weal_80'
restore

*call GDP and NNI for compleating W and Y calculations for Dietrischelal.(2025) 1970-1980
preserve
	keep if year>=1970 & year<=1980

	keep iso year valueinyixx999i valuemgdpro999i valueynninc999i //valuemnnfin999i
	rename (valueinyixx999i valuemgdpro999i valueynninc999i) (valueinyixx999ib valuemgdpro999ib valueynninc999ib)
	
	gen region=iso
	
	tempfile agg_70s
	save `agg_70s'
restore


* Call the MER conversion factors of the USD
preserve
	keep if iso=="US" 
	rename value* *
	keep year xlcusx999i xlceux999i xlcyux999i 
	
	tempfile xrateusd
	save `xrateusd'		
restore

* Call the PPP conversion factors of the USD
preserve
	keep if iso=="US" 
	keep iso year valueinyixx999i valuexlcusp999i
	rename (iso) (region)
	
	tempfile pppusa
	save `pppusa'		
restore

* Call price index and recent conversion rates for all the countries
preserve
	keep if year<=1980
	keep  iso year valueinyixx999i valuexlcusp999i valuexlceup999i valuexlcyup999i valuexlcusx999i valuexlceux999i valuexlcyux999i
	
	tempfile country_idx
	save    `country_idx'
restore

* Keep only regions
keep if inlist(substr(iso, 1, 1), "X", "O") | inlist(iso,"QL", "QM","WO","QE","QF","QP")
drop if inlist(iso,"OM")
	
* Call conversion factors PPP fo the $pastyear for regions
preserve	
	keep if !strpos(iso,"-PPP") & year==$pastyear 
	keep  iso year valueinyixx999i valuexlcusp999i valuexlceup999i valuexlcyup999i
	rename iso region
	
	tempfile  indx_pasty
	save `indx_pasty'
restore


// -------------------------------------------------------------------------- //
* 	2. Merge Historical Regions 
// -------------------------------------------------------------------------- //
* Note: This section integrates macroeconomic data from Nievas & Piketty(2025) 
*		(except for the confc), the trade data from Nievas & Piketty(2025), 
* 		the confc and the intitutional sector historical data from Diertrich 
*		et al. (2025) and the wealth data from and Bauluz et al (2025) before 1970. 
*       Nievas & Piketty(2025) from 1800 and Diertrich et al. (2025) from 1900 and 
*       Bauluz et al (2025) from 1800.

// --------- 2.1. Bring wealth to product ratios (y)  ----------------------- //
use  "$work_data/nievaspiketty2025_hist.dta", clear
gen np=1

append using "$work_data/dietrichetal2025sectors_hist.dta"
duplicates tag iso year widcode p, gen(dup)
drop if np==1 & dup==1
duplicates tag iso year widcode p, gen(dup2)
assert dup2==0
drop dup* np

gen npd=1
append using "$work_data/bauluzetal2025wealth_2025_hist.dta"
duplicates tag iso year widcode p, gen(dup)
drop if npd==1 & dup==1
duplicates tag iso year widcode p, gen(dup2)
assert dup2==0
drop dup* npd

* keep relevant observations
keep if inlist(substr(iso, 1, 1), "X", "O") | inlist(iso,"QL", "QM","WO","QE","QF","QP")

rename iso region
*fillin region year widcode p
*drop _fillin

* Generate observations for OK
expand 2 if region=="OH", gen(xpnd)
replace region="OK" if xpnd==1 & region=="OH"
drop xpnd
* Generate observations for QL
expand 2 if region=="OH", gen(xpnd)
replace region="OL" if xpnd==1 & region=="OH"
drop xpnd

* Generate observations for  QF
expand 2 if region=="XB", gen(xpnd)
replace region="QF" if xpnd==1 & region=="XB"
drop xpnd
* Generate observations for  QP
expand 2 if region=="XB", gen(xpnd)
replace region="QP" if xpnd==1 & region=="XB"
drop xpnd

* Adjust the GDP proportionally to the size od OK and OL in 1970
merge m:1 region using "$work_data/ratioOKOL", nogenerate

replace value= value*usx if widcode=="mgdpro999i" & inlist(region,"OK","OL")
drop eux eup usx usp yux yup

* Adjust the GDP proportionally to the size of QF and QP in 1970
merge m:1 region using "$work_data/ratioQPQF.dta", nogenerate

replace value= value*usx if widcode=="mgdpro999i" & inlist(region,"QP","QF")
drop eux eup usx usp yux yup

preserve
	keep if substr(widcode,1,1)=="y"
	replace region = region + "-PPP"
	gen org=1
	
	tempfile y_agg_reg
	save `y_agg_reg'
restore


// --------- 2.2.  Rebase the price index to the $pastyear ---------------------
merge m:1 region using "`indx_xlc'" , nogenerate keep(master match)
replace value = value/inyixx_23 if widcode=="inyixx999i" 
drop inyixx_23

reshape wide value, i(region year p) j(widcode) string


// --------- 2.3.  Calculate mnninc999i and mndpro999i -------------------------
*Generate national income
gen double valueynninc999i = (1 - valueyconfc999i + valueynnfin999i) // ygdpro999i==1
*gen double valueyndpro999i= 1 - valueyconfc999i // ygdpro999i==1

* Generate personal wealth 
merge m:1 region using "`rat_weal_80'", nogen keep(master match) keepusing(rat_weal)
gen double valueyhweal999i = valueypweal999i*rat_weal
gen double valueyiweal999i = valueypweal999i- valueyhweal999i
drop rat_weal

merge 1:1 region year using "`agg_70s'", nogenerate keep(master match) 
foreach v in mgdpro inyixx ynninc {
	replace value`v'999i = value`v'999ib if missing(value`v'999i ) 
}
drop *b iso

// --------- 2.4. Generate constant $pastyear monetary values (m)  ---------- //
replace valuemgdpro999i= valuemgdpro999i/ valueinyixx999i if year<1970
ds region year p valueintlcu999i valueinyixx999i valuemgdpro999i valuexlcusx999i , not
foreach v in `r(varlist)' {
 gen double `v'_m = `v' *  valuemgdpro999i
}

// --------- 2.5. Calculate wealth to income ratios (w) --------------------- //
ds *_m  valuemgdpro999i 
foreach v of varlist `r(varlist)' {
	 gen double `v'_w = `v' /  valueynninc999i_m
}
reshape long
replace widcode = "w" + substr(widcode,2,9) if strpos(widcode,"_w")
replace widcode = "m" + substr(widcode,2,9) if strpos(widcode,"_m")

replace p ="pall" if missing(p)
duplicates tag region year p widcode, gen(dup)
drop if dup==1 & missing(value)
drop dup
drop if missing(value) & year<1900


preserve
	keep if substr(widcode,1,1)=="w"
	replace region = region + "-PPP"
	gen org=1
	
	tempfile w_agg_reg
	save `w_agg_reg'
restore

/*
append using "`full_post_1970'"
duplicates tag region year p widcode, gen(dup)
assert dup==0
drop dup 
*/


// --------- 2.6. Extend exchange rate to regions-MER before 1970 ----------- //

preserve
	drop if substr(region,4,3)=="PPP"
	keep if inlist(widcode,"xlcusx999i")
	foreach x in eu yu {
		expand 2 if  year==1800, gen(xpnd)
		replace widcode="xlc`x'x999i" if xpnd==1
		drop xpnd
	}
	
	keep widcode region year value
	
	fillin region year widcode 
	drop _fillin
	merge m:1 year using "`xrateusd'", nogenerate
	
	replace value = xlcusx999i if widcode == "xlcusx999i" 
	replace value = xlceux999i if widcode == "xlceux999i" 
	replace value = xlcyux999i if widcode == "xlcyux999i" 
	
	drop xlc*
	keep if year<1970
	gen new = 1
	duplicates drop 
	gen p="pall"
	
	tempfile xrate_pre70
	save    `xrate_pre70'
restore 

append using "`xrate_pre70'"

duplicates tag region year  p widcode, gen(dup)
drop if dup==1 & new!=1

duplicates tag region year p widcode, gen(dup2)
assert dup2==0
drop dup* new


// --------- 2.7. Extend PPP to regions-MER before 1970 ----------- //

preserve 
	* Generate a ppp usd
	*gen type_v=substr(region,3,4)

	*keep if (type_v=="-PPP" & year>=1970) | (year<1970)
	*drop type_v
	*replace region = substr(region,1,2)
	
	drop if substr(region,4,3)=="PPP"
	
	keep if inlist(widcode,"inyixx999i", "xlcusp999i") // , "xlcyup999i")

	reshape wide value, i(region year p) j(widcode) string
	append using "`indx_pasty'"
	append using "`pppusa'"
	**PI home 2011
	gen double localindex20210 = valueinyixx999i if year==$pastyear
	egen localindex2021        = mode(localindex20210), by(region)
	
	foreach c in us { // yu { 
		**PPP home 2011
		gen double lcl`c'ppp20210 = valuexlc`c'p999i if year==$pastyear
		egen lcl`c'ppp2021        = mode(lcl`c'ppp20210), by(region)
		
		** PI foreing current
		gen double index`c'0 = valueinyixx999i      if region==cond("`c'"=="us", "US", "CN")
		egen index`c'        = mode(index`c'0), by(year)
		** PI foreing 2021
		gen double index`c'20210 = valueinyixx999i if region==cond("`c'"=="us", "US", "CN") & year==$pastyear
		egen index`c'2021         = mode(index`c'20210)
		
		drop *0
		
		**extendPPP
		gen ppp= lcl`c'ppp2021*((valueinyixx999i/localindex2021)/(index`c'/index`c'2021))
		
		replace valuexlc`c'p999i=ppp if year<1970 & !inlist("US","CN")
		
		keep year /*currency*/ region p valueinyixx999i valuexlcusp999i  localindex2021  // valuexlcyup999i
	}
	drop localindex2021
	
	 keep if year<1970 	& !inlist(region,"US") // ,"CN")
	 
	 ** Convert to EUR and CNY
	 merge m:1 year using "$work_data/ppp_ea_cn_weithgted.dta", nogenerate
	 keep if year< 1970
	 gen double valuexlcyup999i= valuexlcusp999i/ppp_cn
	 gen double valuexlceup999i= valuexlcusp999i/ppp_ea
	 
	 drop ppp_* /*refyear*/ valueinyixx999i
	 
	 
	reshape long value,i(region year p)j(widcode) string   
	gen new=1
	
	*replace region= region+"-PPP"
	replace p="pall"
	tempfile ppp_complete
	save `ppp_complete'
restore


append using "`ppp_complete'"
duplicates tag region year p widcode, gen(dup)
drop if dup==1 & new!=1
drop dup new 

// --------- 2.8. Extend exchange rate to regions-MER before 1970 ----------- //

* Note: Given that we have already have the full convertion factors for the MER 
*       regions, we can use them for calculating the conversion factors for the 
*        regions-ppp 

preserve
	*Keep relevant values  
	keep if year<1970
	keep if substr(region,3,4)!="-PPP"
	keep if widcode=="mnninc999i" | inlist(widcode,"xlcusp999i", 				/// "xlcusx999i",
													"xlceup999i","xlceux999i", /// 
													"xlcyup999i","xlcyux999i") // 
	drop  p                                                                
	reshape wide value, i(region year) j(widcode) string
	rename value* *
	rename *999i *
	
	* Generate mnnninc values in ppp, MER for USD, EUR and CNY
	foreach c in  us eu yu {
		if "`c'" != "us" {
			replace xlc`c'x = mnninc / xlc`c'x
		}
		replace xlc`c'p  =mnninc/xlc`c'p
	}
	
	rename mnninc xlcusx
	rename xlc* mnninc_*
	
	* Calculate PPP convertions factors
	gen xlcusx999i= mnninc_usp / mnninc_usx
	gen xlceux999i= mnninc_usp / mnninc_eux
	gen xlcyux999i= mnninc_usp / mnninc_yux
	
	gen xlcusp999i= 1 // mnninc_usp / mnninc_usp
	gen xlceup999i= mnninc_usp / mnninc_eup
	gen xlcyup999i= mnninc_usp / mnninc_yup
	
	* Format
	drop mnninc_*
	rename xlc* valuexlc*
	replace region=region+"-PPP"
	
	reshape long value, i(region year) j(widcode) string
	
	gen p="pall"
	gen new=1
	tempfile ppp_mer_regppp_pre70
	save `ppp_mer_regppp_pre70'
restore


append using "`ppp_mer_regppp_pre70'"

duplicates tag region year p widcode, gen(dup)
drop if dup==1 & new!=1
duplicates tag region year p widcode, gen(dup2)
assert dup2==0
drop dup* new

// --------- 2.9. Complete Price index for regions -PPP  ------------------- //
preserve
	* Retain relevant variables
	keep if substr(region,3,4)!="-PPP"
	keep if inlist(widcode,"mnninc999i","inyixx999i","xlcusp999i")
	*drop currency
	* Wide variables
	reshape wide value, i(region year p) j(widcode) string
	rename value* *
	
	* Gen PPP pastyear 	
	merge m:1 region year using "`indx_pasty'", nogenerate keepusing(valuexlcusp999i)
	
	egen xlcusp999i_pasty = mode(valuexlcusp999i), by(region)
	drop valuexlcusp999i
	drop if year==$pastyear
	
	* gen Input variables
	gen double mnninc999i_nomusp=(mnninc999i*inyixx999i)/xlcusp999i
	gen double mnninc999i_pppusd=mnninc999i/xlcusp999i_pasty
	
	* Calculate Price index
	generate double inyixx999i_ppp = mnninc999i_nomusp/mnninc999i_pppusd
	
	* Format
	keep region year p  *_ppp
	
	rename inyixx999i_ppp value
	
	gen widcode = "inyixx999i"
	replace region = region + "-PPP"
	
	gen new=1
	tempfile idx_regpp_pre70
	save    `idx_regpp_pre70'
restore

append using "`idx_regpp_pre70'"

duplicates tag region year p widcode, gen(dup)
drop if dup==1 & new!=1
duplicates tag region year p widcode, gen(dup2)
assert dup2==0
drop dup* new

// --------- 2.10.  Extend Population to regions-PPP  (obsolete)------------------------- //
/*
append using "`hist_pop_reg'"

*expand 2 if substr(widcode,1,1)=="n", gen(xpnd)
*replace region=region+"-PPP" if xpnd==1
*drop xpnd
replace region=region+"-PPP" if wid==1
drop wid
*/
// --------- 2.11.  Extend aggregates  to regions-PPP ------------------------ //
preserve
	keep if substr(widcode,1,1)=="m" //| widcode=="xlcusp999i"
	keep if substr(region,3,4)!="-PPP"
	
	//gen aux=value if widcode=="xlcusp999i" & year==$pastyear
	//egen pppusd= mode(aux),by(region)
	//drop aux // currency
	merge m:1 region using "`indx_pasty'", nogenerate keepusing(valuexlcusp999i) keep(master match)
	
	*keep if year<1970
	*drop if widcode=="xlcusp999i"
	
	replace value=value/valuexlcusp999i
	drop valuexlcusp999i
	
	replace region= region + "-PPP"
	
	gen new=1
	tempfile agg_regpp_pre70
	save    `agg_regpp_pre70'
restore

append using "`agg_regpp_pre70'"
duplicates tag region year p widcode, gen(dup)
drop if dup==1 & new!=1
duplicates tag region year p widcode, gen(dup2)
assert dup2==0
drop dup* new

append using "`y_agg_reg'"
duplicates tag region year p widcode, gen(dup)
drop if dup==1 & org!=1
duplicates tag region year p widcode, gen(dup2)
assert dup2==0
drop dup* org

append using "`w_agg_reg'"
duplicates tag region year p widcode, gen(dup)
drop if dup==1 & org!=1
duplicates tag region year p widcode, gen(dup2)
assert dup2==0
drop dup* org


// --------- 2.12.  Complete intclu ------------------------------------------ //
local n = 1+ ($pastyear - 2023)
expand `n' if widcode=="intlcu999i" & year==2023, gen(xpnd)

bysort region year widcode : gen year_plus = _n if xpnd==1
replace year = year + year_plus -1 if xpnd==1
drop xpnd year_plus

// --------- 2.13. Format  ----------------------------------------- //
rename region iso
keep iso year widcode value 
generate p = "pall"
replace value = round(value, 1) if strpos(widcode, "npopul")

gen currency="USD" if substr(widcode,1,1)=="m"

gduplicates drop

drop if missing(value)
gen new=1

gen regions=1
tempfile regions_pre70
save "`regions_pre70'"

// -------------------------------------------------------------------------- //
* 	3. Merge Historical Countries from Nievas & Piketty (2025)
// -------------------------------------------------------------------------- //
* Bring Wealth to product ratio (Y)
use  "$work_data/nievaspiketty2025_hist.dta", clear
gen np=1
append using "$work_data/dietrichetal2025sectors_hist.dta"

duplicates tag iso year widcode p, gen(dup)
drop if np==1 & dup==1
duplicates tag iso year widcode p, gen(dup2)
assert dup2==0
drop dup* np

gen npd=1
append using "$work_data/bauluzetal2025wealth_2025_hist.dta"
duplicates tag iso year widcode p, gen(dup)
drop if npd==1 & dup==1
duplicates tag iso year widcode p, gen(dup2)
assert dup2==0
drop dup* npd

* Deep relevant observations
keep if !inlist(substr(iso, 1, 1), "X", "O") & !inlist(iso,"QL", "QM","WO","QE")

drop if widcode=="inyixx999i"
reshape wide value, i(iso year p) j(widcode) string

* calcualte nninc and ndpro
gen double valueynninc999i = (1 - valueyconfc999i + valueynnfin999i) // valueygdpro999i==1
*gen double valueyndpro999i= 1 - valueyconfc999i // valueygdpro999i==1

* Generate personal wealth 
merge m:1 iso using "`rat_weal_80'", nogen keep(master match) keepusing(rat_weal)
gen double valueyhweal999i = valueypweal999i*rat_weal
gen double valueyiweal999i = valueypweal999i- valueyhweal999i
drop rat_weal


merge 1:1 iso year using "`country_idx'", nogenerate keep(master match)

* Calculate LCU constant Prices $pastyear
replace valuemgdpro999i= valuemgdpro999i/valueinyixx999i

merge 1:1 iso year using "`agg_70s'", nogenerate keep(master match) 
foreach v in mgdpro ynninc {
	replace value`v'999i = value`v'999ib if missing(value`v'999i ) 
}
drop *b region

* Generate aggregates
ds iso year p valueintlcu999i valueinyixx999i valuemgdpro999i valuexlcusx999i, not
foreach v in `r(varlist)' {
	gen double `v'_m = `v' *  valuemgdpro999i
}

* generate  wealth to income ratios (W)
ds *_m valuemgdpro999i 
foreach v of varlist `r(varlist)' {
	gen double `v'_w = `v' /  valueynninc999i_m
}
reshape long value, i(iso year p) j(widcode) string
replace widcode = "w" + substr(widcode,2,9) if strpos(widcode,"_w")
replace widcode = "m" + substr(widcode,2,9) if strpos(widcode,"_m")

drop if missing(value)

gen new=1

// -------------------------------------------------------------------------- //
* 	4. Final Formating and export
// -------------------------------------------------------------------------- //
 
// --------- 4.1. Pile regions and countries before 1970 if not Dietrisch et al.(2025) or Bauluz et al.(2025) //
append using  "`regions_pre70'"


gen     flag = 0
replace flag = 1 if inlist(substr(widcode, 2, 5), "ptxgo", "gvato", "gvago", "ceugo", "gsrgo", "nsrgo") | ///
				    inlist(substr(widcode, 2, 5), "cfcgo", "gvaco", "ceuco", "gsrco", "nsrco", "cfcco") | ///
				    inlist(substr(widcode, 2, 5), "ccmhn", "gsrhn", "nsrhn", "ccshn", "gvahn", "ceuhn") | ///
					inlist(substr(widcode, 2, 5), "gmxhn", "nmxhn")

replace flag = 1 if  inlist(substr(widcode, 1, 6), "ylsgdp", "ylsndp", "ycsgdp", "ycsndp", "wlsgni", "wlsnni") | ///
					inlist(substr(widcode, 1, 6), "wcsgni", "wcsnni", "ylscgv", "ylscnv", "ycscgv", "ycscnv") | ///
					inlist(substr(widcode, 1, 6), "yconfc")

replace flag = 1 if  inlist(substr(widcode, 2, 5), "nwdka", "nweal", "gweal", "gwass", "gwdeb", "nwnfa") | ///
					 inlist(substr(widcode, 2, 5), "hweal","pweal")

drop if year>=1970 & flag==0 & regions!=1
drop flag regions

tempfile full_pre70
save `full_pre70'

 
// --------- 4.2. Pile regions and countries before 1970 -------------------- //
* Note: while nsrgo is assumed to be 0, this is not the exact case for all the 
*		countries (probalbly because of meassuremnt mistakes). As so, by keepusing
* 		what we had in the WID we avoid a suden pass from 0 until 1980 to not 0 
*		afterwards for all the contries at the same time..
append using  "$work_data/aggregate-regions-output.dta"
duplicates tag iso year widcode p, gen(dup)

drop if new!=1 & dup==1 & (!inlist(substr(widcode, 2, 5), "nwdka", "nweal", "gweal", "gwass", "gwdeb", "nwnfa") & ///
					       !inlist(substr(widcode, 2, 5), "hweal","pweal") & !strpos(widcode,"nsrgo"))
drop if new==1 & dup==1 & ( inlist(substr(widcode, 2, 5), "nwdka", "nweal", "gweal", "gwass", "gwdeb", "nwnfa") | ///
					        inlist(substr(widcode, 2, 5), "hweal","pweal") |  strpos(widcode,"nsrgo"))

duplicates tag iso year widcode p, gen(dup2)
assert dup2==0
drop dup* new

* Complete currencies
bys iso : egen 		 aux = mode(currency)
replace 		currency = aux if substr(widcode,1,1)=="m" & missing(currency)
drop aux 

// --------- 4.3.  Save ----------------------------------------------------- //
compress



sort iso year widcode p
label data "Generated by merge-historical-aggregates.do"
save "$work_data/merge-historical-aggregates-output.dta", replace

// -------------------------------------------------------------------------- //
* 5. Create metadata
// -------------------------------------------------------------------------- //

use "`full_pre70'", clear
generate sixlet = substr(widcode, 1, 6)
keep iso sixlet
*drop if substr(sixlet, 1, 3) == "xlc"
gduplicates drop
*generate source = "WID.world (see individual countries for more details)" if missing(source)
*generate method = "WID.world aggregations of individual country data"     if missing(source)
gen newmeta=1
append using "$work_data/aggregate-regions-metadata.dta"

duplicates tag iso sixlet, gen(dup)
drop if newmeta==1 & dup==1
duplicates tag iso sixlet, gen(dup2)
assert dup2==0
drop dup* newmeta

save "$work_data/merge-historical-aggregates-metadata.dta", replace
