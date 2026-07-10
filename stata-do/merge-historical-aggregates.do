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
//      3.1.  Extend PPP to non-main countries before 1970
//      3.2.  Extend Xrates to non-main countries before 1970 
//  4. Final Formating and export
//      4.1.  Pile countries 
//      4.2.  Add regions
//      4.3.  Save
//  5. Create metadata
//------------------------------------------------------------------------------

// -------------------------------------------------------------------------- //
* 	1. Call necessary data from WID
// -------------------------------------------------------------------------- //
use "$work_data/aggregate-regions-output.dta", clear
keep if inlist(substr(widcode, 1, 6), "xlcusx", "xlcusp", "xlceux", "xlceup", "xlcyux", "xlcyup") /// 
	  | inlist(substr(widcode, 1, 6), "inyixx", "mgdpro", "ynninc", "mnnfin") /// ,"npopul") // , "intlcu","xrerus") ///
	  | inlist(substr(widcode, 1, 6), "yhweal", "ypweal", "mhweal", "mpweal")
drop currency
rename data_quality q_



preserve 
	keep if widcode=="inyixx999i"
	keep iso year p value widcode s_ q_
	rename value value_wid
	tempfile prices1
	save `prices1'

restore
preserve
	use "$wid_dir/Country-Updates/Historical_series/2025_Nov/output5_Extended_deflactor_non_benchmark.dta", clear
	gen     q_ = 4
	gen     s_ = "arias2025"
	append using "$wid_dir/Country-Updates/Historical_series/2026-Feb/output1_Extended_deflactor_PE.dta"
	replace q_ = 4 if missing(q_)
	replace s_= "castillogarcia2026" if missing(s_)
	merge 1:1 iso year widcode p using "`prices1'", nogen
	sort iso year
	
	* Recreate the price index as if pastyear=2024 ( when the non benchmark data was generated)
	gen value_aux1=value_wid if year==2024
	bysort iso : egen base1 = mode(value_aux1)
	replace value_wid=value_wid/base1
	
	gen value_aux2=value_wid if year==$pastyear
	bysort iso : egen base2 = mode(value_aux2)
	replace value=value/base2
	
	replace value_wid=value if missing(value_wid)
	
	keep iso year widcode p value_wid q_ s_
	rename value_wid value
	
	tempfile full_prices
	save "`full_prices'"
restore

drop if widcode=="inyixx999i"

append using "`full_prices'"

sort iso widcode year p

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

reshape wide value q_ s_, i(iso year p) j (widcode) string

* call updated price index for NP data in 2023 prices
preserve	
	keep if !strpos(iso,"-PPP") & year==2023 // last year of Nievas piketty
	keep    iso valueinyixx999i
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
	keep iso year *inyixx999i *mgdpro999i *ynninc999i  //valuemnnfin999i
	rename       (*inyixx999i *mgdpro999i *ynninc999i) (*inyixx999ib *mgdpro999ib *ynninc999ib)
	
	gen region=iso
	
	tempfile agg_70s
	save `agg_70s'
restore


* Call the MER conversion factors of the USD
preserve
	keep if iso=="US" 
	rename value* *
	keep year *xlcusx999i *xlceux999i *xlcyux999i 
	
	tempfile xrateusd
	save `xrateusd'		
restore

* Call the PPP conversion factors of the USD
preserve
	keep if iso=="US" 
	keep iso year *valueinyixx999i *valuexlcusp999i
	
	gen ppp_usa_iso=1
	tempfile pppusa_iso
	save `pppusa_iso'	
	
	drop ppp_usa_iso
	rename (iso) (region)
	
	tempfile pppusa
	save `pppusa'		
restore

* Call price index and recent conversion rates for all the countries
preserve
	keep if year<=1980
	keep  iso year *inyixx999i *xlcusp999i *xlceup999i *xlcyup999i *xlcusx999i *xlceux999i *xlcyux999i
	
	tempfile country_idx
	save    `country_idx'
restore


	
* Call conversion factors PPP fo the $pastyear for regions
preserve	
	keep if !strpos(iso,"-PPP") & year==$pastyear 
	keep  iso year *inyixx999i *xlcusp999i *xlceup999i *xlcyup999i 
	
	tempfile  indx_pasty_iso
	save `indx_pasty_iso'
	
	* Keep only regions
	keep if inlist(substr(iso, 1, 1), "X", "O") | inlist(iso,"QL", "QM","WO","QE","QF","QP")
	drop if inlist(iso,"OM")
	
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
drop if strpos(widcode,"confc") & year>=1970 //Keep the confc estimated in the main.do
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



// --------- 2.2.  Rebase the price index to the $pastyear ---------------------
merge m:1 region using "`indx_xlc'" , nogenerate keep(master match)
replace value = value/inyixx_23 if widcode=="inyixx999i" 
drop inyixx_23

reshape wide value q_ s_, i(region year p) j(widcode) string


// --------- 2.3.  Calculate mnninc999i and mndpro999i -------------------------
*Generate national income
gen double valueynninc999i = (1 - valueyconfc999i + valueynnfin999i) // ygdpro999i==1
gen           q_ynninc999i = min(3, cond(valueyconfc999i >= valueynnfin999i, q_yconfc999i, q_ynnfin999i)) // ygdpro999i==1
gen           s_ynninc999i = "confc,nnfin" // ygdpro999i==1
*gen double valueyndpro999i= 1 - valueyconfc999i // ygdpro999i==1

* Generate personal wealth 
merge m:1 region using "`rat_weal_80'", nogen keep(master match) keepusing(rat_weal)
gen double valueyhweal999i = valueypweal999i*rat_weal
gen           q_yhweal999i = q_ypweal999i if !missing(valueyhweal999i)
gen           s_yhweal999i = "pweal_ratiohweal/pweal(1980)" if !missing(valueyhweal999i)
gen double valueyiweal999i = valueypweal999i- valueyhweal999i
gen           q_yiweal999i = min(3, cond(valueypweal999i >= valueyhweal999i, q_ypweal999i, q_yhweal999i)) if !missing(valueyiweal999i)
gen           s_yiweal999i = "pweal,hweal" if !missing(valueyiweal999i)
drop rat_weal

merge 1:1 region year using "`agg_70s'", nogenerate keep(master match) 
foreach v in mgdpro inyixx ynninc {
	replace value`v'999i = value`v'999ib if missing(value`v'999i) 
	replace    q_`v'999i =    q_`v'999ib if missing(q_`v'999i) 
	replace    s_`v'999i =    s_`v'999ib if missing(s_`v'999i) 
}
drop *b iso

// --------- 2.4. Generate constant $pastyear monetary values (m)  ---------- //
replace valuemgdpro999i= valuemgdpro999i/ valueinyixx999i if year<1970
ds region year p valueintlcu999i valueinyixx999i valuemgdpro999i valuexlcusx999i s_* q_* valueylsgdp999i valueycsgdp999i , not // We don't want the Factro Shares to be extended
foreach v in `r(varlist)' {
	local v_clean = subinstr("`v'", "value", "", .)
	gen double       `v'_m = `v' *  valuemgdpro999i
	gen      q_`v_clean'_m = q_`v_clean' 
	gen      s_`v_clean'_m = s_`v_clean' 
}

// --------- 2.5. Calculate wealth to income ratios (w) --------------------- //
ds value*_m  valuemgdpro999i 
foreach v of varlist `r(varlist)' {
	local v_clean = subinstr("`v'", "value", "", .)
	gen double      `v'_w = `v' /  valueynninc999i_m
	gen     q_`v_clean'_w = q_`v_clean' 
	gen     s_`v_clean'_w = s_`v_clean' 
}

reshape long value q_ s_, i(region year p) j(widcode) string
replace widcode = "w" + substr(widcode,2,9) if strpos(widcode,"m_w")
replace widcode = "w" + substr(widcode,2,9) if strpos(widcode,"_w")
replace widcode = "m" + substr(widcode,2,9) if strpos(widcode,"_m")

replace p ="pall" if missing(p)
duplicates tag region year p widcode, gen(dup)
drop if dup==1 & missing(value)
drop dup
drop if missing(value) & year<1900

preserve
	keep if substr(widcode,1,1)=="y"
	replace region = region + "-PPP"
	gen org=1
	
	tempfile y_agg_reg
	save `y_agg_reg'
restore


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
	
	keep widcode region year value s_ q_
	
	fillin region year widcode 
	drop _fillin
	merge m:1 year using "`xrateusd'", nogenerate
	
	foreach	c in us eu yu {
		replace value =   xlc`c'x999i if widcode == "xlc`c'x999i" 
		replace    s_ = "_USDassumed" if widcode == "xlc`c'x999i" 
		replace    q_ = q_xlc`c'x999i if widcode == "xlc`c'x999i" 
	}
	
	
	drop *xlc*
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

	reshape wide value q_ s_, i(region year p) j(widcode) string
	append using "`indx_pasty'"
	append using "`pppusa'"
	
	*drop q_* s_*
	
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
		
		keep year /*currency*/ region p *inyixx999i *xlcusp999i  localindex2021  // valuexlcyup999i
	}
	drop localindex2021
	
	replace q_xlcusp999i = 0
	replace s_xlcusp999i = "inhouse"
	
	 keep if year<1970 	& !inlist(region,"US") // ,"CN")
	 
	 ** Convert to EUR and CNY
	 merge m:1 year using "$work_data/ppp_ea_cn_weithgted.dta", nogenerate
	 
	 keep if year< 1970
	 gen double valuexlcyup999i = valuexlcusp999i/ppp_cn
	 gen           q_xlcyup999i = min(q_xlcusp999i, q_cn)
	 gen           s_xlcyup999i = "triang"
	 gen double valuexlceup999i = valuexlcusp999i/ppp_ea
	 gen           q_xlceup999i = min(q_xlcusp999i, q_ea)
	 gen           s_xlceup999i = "triang"
	 
	 drop ppp_* /*refyear*/ *inyixx999i *_cn *_ea
	 
	 
	reshape long value q_ s_ , i(region year p) j(widcode) string   
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
	keep region year widcode value                                                               
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
	gen q_=0
	gen s_="reginhouse"
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
	keep region year p widcode value
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
	gen q_=0
	gen s_="reginhouse"
	
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
keep iso year widcode value s_ q_
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
append using "$wid_dir/Country-Updates/Historical_series/2025_Nov/output6_Extended_macro_non_benchmark.dta"
replace  q_ = 4           if missing(q_)
replace  s_ = "arias2025" if missing(s_)
append using "$wid_dir/Country-Updates/Historical_series/2026-Feb/output2_Extended_macro_PE.dta"
replace q_ = 4 if missing(q_)
replace s_= "castillogarcia2026" if missing(s_)
duplicates tag iso year widcode p, gen(dup)
drop if np==1 & dup==1
duplicates tag iso year widcode p, gen(dup2)
assert dup2==0
drop dup*

append using "$work_data/dietrichetal2025sectors_hist.dta"
drop if strpos(widcode,"confc") & year>=1970 //Keep the confc estimated in the main.do
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
keep if !inlist(substr(iso, 1, 1), "X", "O") & !inlist(iso,"QL", "QM","WO","QE")

drop if widcode=="inyixx999i"
reshape wide value s_ q_, i(iso year p) j(widcode) string

* calculate nninc and ndpro
replace valueynninc999i = (1 - valueyconfc999i + valueynnfin999i) if !(missing(valueyconfc999i) & missing(valueynnfin999i))
replace s_ynninc999i = "yconfc,ynnfin" if !(missing(valueyconfc999i) & missing(valueynnfin999i))
replace q_ynninc999i = min(3, cond( valueyconfc999i  >= valueynnfin999i, q_yconfc999i, q_ynnfin999i))  if !(missing(valueyconfc999i) & missing(valueynnfin999i))
*gen double valueyndpro999i= 1 - valueyconfc999i // valueygdpro999i==1

* Generate personal wealth 
merge m:1 iso using "`rat_weal_80'", nogen keep(master match) keepusing(rat_weal)
gen double valueyhweal999i = valueypweal999i*rat_weal
gen           q_yhweal999i = q_ypweal999i if !missing(valueyhweal999i)
gen           s_yhweal999i = "pweal_ratiohweal/pweal(1980)" if !missing(valueyhweal999i)
gen double valueyiweal999i = valueypweal999i- valueyhweal999i
gen           q_yiweal999i = min(3, cond(valueypweal999i >= valueyhweal999i, q_ypweal999i, q_yhweal999i)) if !missing(valueyiweal999i)
gen           s_yiweal999i = "pweal,hweal" if !missing(valueyiweal999i)
drop rat_weal


merge 1:1 iso year using "`country_idx'", nogenerate keep(master match)

* Calculate LCU constant Prices $pastyear
replace valuemgdpro999i= valuemgdpro999i/valueinyixx999i

merge 1:1 iso year using "`agg_70s'", nogenerate keep(master match) 

foreach v in mgdpro ynninc {
	replace value`v'999i = value`v'999ib if missing(value`v'999i ) 
	replace    q_`v'999i =    q_`v'999ib if missing(q_`v'999i ) 
	replace    s_`v'999i =    s_`v'999ib if missing(s_`v'999i ) 
}
drop *b region



* Generate aggregates
ds iso year p valueintlcu999i valueinyixx999i valuemgdpro999i valuexlc* q_* s_* valueylsgdp999i valueycsgdp999i, not // we dont want the Fractor shaares to be extended to other onlets
foreach v in `r(varlist)' {
	local v_clean = subinstr("`v'", "value", "", .)
	gen double       `v'_m = `v' *  valuemgdpro999i
	gen      q_`v_clean'_m = q_`v_clean' 
	gen      s_`v_clean'_m = s_`v_clean' 
}

* generate  wealth to income ratios (W)
ds value*_m  valuemgdpro999i 
foreach v of varlist `r(varlist)' {
	local v_clean = subinstr("`v'", "value", "", .)
	gen double      `v'_w = `v' /  valueynninc999i_m
	gen     q_`v_clean'_w = q_`v_clean' 
	gen     s_`v_clean'_w = s_`v_clean' 
}


reshape long value s_ q_, i(iso year p) j(widcode) string
replace widcode = "w" + substr(widcode,2,9) if strpos(widcode,"m_w")
replace widcode = "w" + substr(widcode,2,9) if strpos(widcode,"_w")
replace widcode = "m" + substr(widcode,2,9) if strpos(widcode,"_m")

drop if missing(value)

*drop if widcode=="ygvato999i" & iso=="PE" & inrange(year,1950,1980)

// --------- 3.1. Extend PPP to non core countries. before 1970 ----------- //

preserve 	
	keep if inlist(widcode,"inyixx999i", "xlcusp999i", "xlcusx999i") // , "xlcyup999i")

	reshape wide value s_ q_, i(iso year p) j(widcode) string
	append using "`pppusa_iso'"
	append using "`indx_pasty_iso'"
	
	
	
	**PI home 2011
	gen double localindex20210 = valueinyixx999i if year==$pastyear
	egen localindex2021        = mode(localindex20210), by(iso)
	
	foreach c in us { // yu { 
		**PPP home 2011
		gen double lcl`c'ppp20210 = valuexlc`c'p999i if year==$pastyear
		egen lcl`c'ppp2021        = mode(lcl`c'ppp20210), by(iso)
		
		** PI foreing current
		gen double index`c'0 = valueinyixx999i      if iso==cond("`c'"=="us", "US", "CN")
		egen index`c'        = mode(index`c'0), by(year)
		** PI foreing 2021
		gen double index`c'20210 = valueinyixx999i if iso==cond("`c'"=="us", "US", "CN") & year==$pastyear
		egen index`c'2021         = mode(index`c'20210)
		
		drop *0
		
		**extendPPP
		gen ppp= lcl`c'ppp2021*((valueinyixx999i/localindex2021)/(index`c'/index`c'2021))
		
		replace valuexlc`c'p999i=ppp if year<1970 & !inlist(iso,"US","CN")
		
		keep year /*currency*/ iso *inyixx999i *xlcusp999i  p localindex2021  // valuexlcyup999i
	}
	drop localindex2021
	
	keep if year<1970 	& !inlist(iso,"US") // ,"CN") 
	drop *inyixx999i
	 
	gen widcode="xlcusp999i"
	replace q_xlcusp999i = 0         if missing(q_xlcusp999i)
	replace s_xlcusp999i = "extendedPPP" if missing(s_xlcusp999i)
	rename valuexlcusp999i value_new
	rename    q_xlcusp999i q_new
	rename    s_xlcusp999i s_new

	
	tempfile ppp_complete_iso
	save `ppp_complete_iso'
restore


merge 1:1 iso year widcode p using "`ppp_complete_iso'", nogenerate

replace value=value_new if missing(value) & !missing(value_new)
replace q_   = q_new if missing(q_) & !missing(q_new)
replace s_   =  s_new if missing(s_) & !missing(s_new)
drop *_new

// --------- 3.2. Extend Xrates to non-main countries before 1970 ----------- //
preserve
	keep if inlist(substr(widcode,1,5),"xlceu","xlcyu","xlcus")
	keep iso year p widcode value q_ s_
	reshape wide value q_ s_, i(iso year p) j(widcode) string
	
	** Complete PPP exange rates
	merge m:1 year using "$work_data/ppp_ea_cn_weithgted.dta", nogenerate

	replace valuexlcyup999i= valuexlcusp999i/ppp_cn     if missing(valuexlcyup999i)
	replace q_xlcyup999i= min(q_xlcusp999i, q_cn)       if missing(   q_xlcyup999i)
	replace s_xlcyup999i= "triang"                      if missing(   s_xlcyup999i)
	
	replace valuexlceup999i= valuexlcusp999i/ppp_ea     if missing(valuexlceup999i)
	replace q_xlceup999i= min(q_xlcusp999i, q_ea)       if missing(   q_xlceup999i)
	replace s_xlceup999i= "triang"                      if missing(   s_xlceup999i)
	
	* Complete MER echange rate
	merge m:1 year using "$work_data/xrate_ea_cn_weithgted.dta", nogenerate
	
	replace valuexlcyux999i = valuexlcusx999i/xr_cn      if missing(valuexlcyux999i)
	replace    q_xlcyux999i = min(q_xlcusx999i, q_xr_cn) if missing(   q_xlcyux999i)
	replace    s_xlcyux999i = "triang"                   if missing(   s_xlcyux999i)
	
	replace valuexlceux999i = valuexlcusx999i/xr_ea      if missing(valuexlceux999i)
	replace    q_xlceux999i = min(q_xlcusx999i, q_xr_ea) if missing(   q_xlceux999i)
	replace    s_xlceux999i = "triang"                   if missing(   s_xlceux999i)
	
	
	keep if year<1970
	drop ppp_* *xr_* *_ea *_cn
	
	reshape long value q_ s_, i(iso year p) j(widcode) string
	
	rename value value_new
	rename  q_ q_new
	rename  s_ s_new
	
	
	tempfile extended_rates
	save `extended_rates'
restore

merge 1:1 iso year widcode p using "`extended_rates'", nogenerate

replace value=value_new if missing(value) & !missing(value_new)
replace q_=q_new if missing(q_) & !missing(q_new)
replace s_=s_new if missing(s_) & !missing(s_new)

drop  *_new

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

replace flag = 1 if inlist(substr(widcode, 1, 6), "ylsgdp", "ylsndp", "ycsgdp", "ycsndp", "wlsgni", "wlsnni") | ///
					inlist(substr(widcode, 1, 6), "wcsgni", "wcsnni", "ylscgv", "ylscnv", "ycscgv", "ycscnv") | ///
					inlist(substr(widcode, 1, 6), "yconfc")

replace flag = 1 if inlist(substr(widcode, 2, 5), "nwdka", "nweal", "gweal", "gwass", "gwdeb", "nwnfa") | ///
					inlist(substr(widcode, 2, 5), "hweal","pweal")
					
drop if year>=1970 & flag==0 //& regions!=1
drop flag regions


keep if year<=1980



rename q_ data_quality

tempfile full_pre70
save `full_pre70'

*drop s_ 
// --------- 4.2. Pile regions and countries before 1970 -------------------- //
* Note: while nsrgo is assumed to be 0, this is not the exact case for all the 
*		countries (probalbly because of meassuremnt mistakes). As so, by keepusing
* 		what we had in the WID we avoid a suden pass from 0 until 1980 to not 0 
*		afterwards for all the contries at the same time.
append using  "$work_data/aggregate-regions-output.dta"

duplicates tag iso year widcode p, gen(dup0)
drop if new==1 & dup==1 & (inlist(substr(widcode, 2, 5), "confc", "ndpro","nnfin","nninc", "gvato")) & iso=="PE"

duplicates tag iso year widcode p, gen(dup)
drop if new!=1 & dup==1 & (!inlist(substr(widcode, 2, 5), "nwdka", "nweal", "gweal", "gwass", "gwdeb", "nwnfa") & ///
						   !inlist(substr(widcode, 2, 5), "hweal","pweal") & !strpos(widcode,"nsrgo"))					   
						   
drop if new==1 & dup==1 &  (inlist(substr(widcode, 2, 5), "nwdka", "nweal", "gweal", "gwass", "gwdeb", "nwnfa") | ///
					        inlist(substr(widcode, 2, 5), "hweal","pweal") |  strpos(widcode,"nsrgo"))


duplicates tag iso year widcode p, gen(dup2)
assert dup2==0
drop dup* new

* Drop ndpro from countries included in arias et all since there is not confc for them
gen flag_a = 1 if inlist(iso,"BG","CH","CM","FI","GH","GR","HR","HU","IE") | ///
				 inlist(iso,"MU","MW","MY","PL","PT","SC","SG","TN","TZ") | ///
				 inlist("UG","ZM","ZW")
drop if strpos(widcode,"ndpro") & flag_a==1 & year<1970
drop flag_a

* Complete currencies
bys iso : egen 		 aux = mode(currency)
replace 		currency = aux if substr(widcode,1,1)=="m" & missing(currency)
drop aux 

// --------- 4.3.  Save ----------------------------------------------------- //
compress

sort iso year widcode p
label data "Generated by merge-historical-aggregates.do"
save "$work_data/merge-historical-aggregates-output.dta", replace
/*


// -------------------------------------------------------------------------- //
* 5. Create metadata
// -------------------------------------------------------------------------- //

use "`full_pre70'", clear
save "$work_data/aux.dta", replace


u "$work_data/aux.dta", clear
keep iso year widcode s_ new
rename s_ metadata



* Generate sixlet
gen sixlet=substr(widcode,1,6)
drop widcode

bysort iso sixlet : egen lastyear = max(year)
drop if lastyear==year & inlist(year,1970,1980)
drop lastyear
*Identify frontier years
gen      aux=0 
replace  aux=1 if year>=1970
sort iso sixlet year metadata



sort iso sixlet aux year
bysort iso sixlet aux (year): ///
gen spell = sum(metadata != metadata[_n-1])
bysort iso sixlet aux spell: egen firstyear = min(year)
bysort iso sixlet aux spell: egen lastyear = max(year)

drop aux
collapse (first) metadata new , by(iso sixlet firstyear lastyear)

bysort iso sixlet (firstyear lastyear): gen categ = sum(firstyear != firstyear[_n-1] | lastyear  != lastyear[_n-1])

*Split source and method
split metadata, parse(_) generate(treat)

// Fill the metadata
generate source=""

* Papers
replace source=`"[URL][URL_LINK]https://wid.world/document/global-wealth-accumulation-and-ownership-patterns-1800-2025-world-inequality-lab-working-paper-2025-22/[/URL_LINK]"' ///
		+ `"[URL_TEXT]Bauluz, L., Brassac, P., Dietrich J., Martinez-Toledano, C., Nievas, G., Odersky, M., Piketty, T., Sodano, A., Somanchi, A.(2025). Global Wealth Accumulation and Ownership Patterns, 1800-2025[/URL_TEXT][/URL]"' if strpos(treat1,"bauluz25")
		
replace source=`"[URL][URL_LINK]https://wid.world/document/updated-and-extended-series-on-factor-shares-and-domestic-capital-stock-in-peru-1942-2024-world-inequality-lab-technical-note-2026-02/[/URL_LINK]"' ///
		+ `"[URL_TEXT]Castillo-Garcia, C.(2026). Updated and Extended Series on Factor Shares and Domestic Capital Stock in Peru, 1942-2024[/URL_TEXT][/URL]"' if strpos(treat1, "castillogarcia2026")		
		
replace source= `"[URL][URL_LINK]https://wid.world/document/extending-wid-national-accounts-series-institutional-sectors-and-factor-shares-world-inequality-lab-technical-note-2025-03/[/URL_LINK][URL_TEXT] Dietrich, J., Nievas, G., Odersky, M., Piketty, T., Somanchi, A. (2025) `Extending WID National Accounts Series: Institutional Sectors and Factor Shares'[/URL_TEXT][/URL]"' if strpos(treat1, "dietrich25")

replace source=`"[URL][URL_LINK]https://wid.world/document/wid-national-accounts-series-updated-and-extended-coverage-1800-2023-world-inequality-lab-technical-note-2025-02/[/URL_LINK]"' ///
		+ `"[URL_TEXT]Nievas, G., Piketty, T. (2025). WID National Accounts Series: Updated and Extended Coverage 1800-2023[/URL_TEXT][/URL]"' if strpos(treat1,"np2025")

replace source=`"[URL][URL_LINK]https://wid.world/document/wid-income-and-wealth-distributional-series-updated-and-extended-coverage-1800-2024-world-inequality-lab-technical-note-2025-10/[/URL_LINK]"' ///
		+ `"[URL_TEXT]Arias-Osorio, M., Bauluz, L., Brassac, P., Chancel, L., Martinez-Toledano, C., Moshrif, R., Piketty, T. (2025) WID Income and Wealth Distributional Series: Updated and Extended Coverage, 1800-2024[/URL_TEXT][/URL]"' if strpos(treat1,"arias2025")

* Method
** Treat1
gen     method = ""
replace method = "In-house calculation" if treat1=="inhouse"
replace method = "We extrapolate the PPP from the latest ICP using the evolution of the price index relative to the reference country"  if treat1=="extendedPPP"
foreach c in x p {
	replace method= "This indicator was triangulated from xlcus`c' by a <<Euro xlcus`c'>> weighting the xlcus`c' of DE, ES, FR, IT, NL" if missing(method) & sixlet=="xlceu`c'" 
	replace method= "This indicator was triangulated from xlcus`c' by a xlcus`c' of CN" if missing(method) & sixlet=="xlcyu`c'"
}

replace method = "This variable was calculated using the variables " + subinstr(treat1, ",", ", ", .)   if strpos(treat1,",") 
replace method = "This variable was calculated by using the value of the variable " + treat1 if missing(method) & missing(source) & treat1!="WID" 

** Treat2
gen adjustment = ""
replace adjustment = ", adjusted by the ratio " + substr(treat2,6,.) if strpos(treat2,"ratio") & missing(adjustment) 

replace method = method + adjustment



** Complete
replace  method = "Observed data"        if !missing(source) & missing(method)
replace  source = "In-house calculation" if !missing(method) & missing(source)

replace method="WID" if metadata=="WID"		
replace source="WID" if metadata=="WID"		
drop metadata treat* adjustment*


* Collase the metadata
foreach v in source method {
	preserve
		generate `v'_new = string(firstyear) + ": " + `v' + ";" ///
			if (firstyear == lastyear) & (`v'!="")
		replace `v'_new = string(firstyear) + "-" + string(lastyear) + ///
			": " + `v' + ";" if  (firstyear != lastyear)  & (`v'!="")
		drop firstyear lastyear 

		keep iso sixlet categ `v'_new 
		drop if `v'_new == ""
		duplicates drop

		greshape wide `v'_new, i(iso sixlet) j(categ)
		egen `v' = concat(`v'_new*), punct(" ")
		keep iso sixlet `v' 
		
		tempfile metadata_`v'
		save    `metadata_`v''
	restore
}

u "`metadata_method'", clear
merge 1:1 iso sixlet using "`metadata_source'", nogen 
order iso sixlet method source

rename (method source)(method_new source_new)

merge 1:1 iso sixlet using "$work_data/aggregate-regions-metadata.dta"

* Complete the metadata for the New data
replace source = source_new if _merge==1
replace method = method_new if _merge==1

* match the metadata
replace source = source_new if _merge==3
replace method = method_new if _merge==3

drop if new!=1 & dup==1 & (!inlist(substr(widcode, 2, 5), "nwdka", "nweal", "gweal", "gwass", "gwdeb", "nwnfa") & ///
						   !inlist(substr(widcode, 2, 5), "hweal","pweal") & !strpos(widcode,"nsrgo"))					   
						   
drop if new==1 & dup==1 &  (inlist(substr(widcode, 2, 5), "nwdka", "nweal", "gweal", "gwass", "gwdeb", "nwnfa") | ///
					        inlist(substr(widcode, 2, 5), "hweal","pweal") |  strpos(widcode,"nsrgo"))


duplicates tag iso year widcode p, gen(dup2)
assert dup2==0
drop dup* new







duplicates tag iso sixlet, gen(dup)
drop if newmeta==1 & dup==1
duplicates tag iso sixlet, gen(dup2)
assert dup2==0
drop dup* newmeta

save "$work_data/merge-historical-aggregates-metadata.dta", replace
