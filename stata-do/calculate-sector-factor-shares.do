// -----------------------------------------------------------------------------
//           Calculate Sector-Factor Shares . Do
// -----------------------------------------------------------------------------

* Objective:  Sectoral Decomposition and Factor Shares Complete Sectoral 
*             Decomomposition of GDP for 216 countries 1980-2023 and from 
*             1900-2023 for 57 core terretories.

//-----------------   0. Index      --------------------------------------------
// 1. Call Base series: Product(total and desaggregations) and CFC
// 2. Selected Country adjustments
// 			2.1  Constaints for CFC
// 			2.2  New Zealand - Australia
// 			2.3  China: 
// 			2.4  Russia
// 			2.5  Former Soviet Countries
// 			2.6  Sweden
// 			2.7  Thailand
// 			2.8  Saudi Arabia
//          2.9  Peru
//	3. Use other data sources if missing
//  4. Logical Splits
//  5. Distribute compensation of employees between corporations and households 
// 			5.1 If possible use last data share available
// 			5.2 Use the share of Mixen income and Firm profits as proxy
//  6. Intrapolate all values linearly between gabs and carryforeward last observation
//  7. Calculate aggreate sectoral value added which we base the imputation on 
//  8. Impute sector until 1980 based on regional GDP per capita for 216 countries 
//  9. Split imputed sectoral shares to single components
//			9.1  Governement
//			9.2 Corporations (gvaco)
//			9.3 Households Mixed Income (gvmhn)
//			9.4 Households Housing (gsrhn)
// 10. replace imputed components if missing, create imputed indicator
// 11. Calculate Gross-Net values
// 12. Calculate Other Regions
// 13. Enforce accounting identities
// 14. Calculate Factor Shares
// 15. Format and export
//------------------------------------------------------------------------------


// Create Globals
global all_vars confc cfcgo cfcco ceugo ceuco ceuhn nsrco nmxhn nsrhn nsrgo ccmhn ccshn /// 
gsrhn gvago gvahn gvmhn gvaco gmxhn gsrco gsrgo ptxgo 
 
global coreterritories `" "DE" "DK" "ES" "FR" "GB" "IT" "NL" "NO" "SE" "OC" "QM" "US" "CA" "AU" "NZ" "OH" "AR" "BR" "CL" "CO" "MX" "OD" "AE" "DZ" "EG" "IR" "MA" "SA" "TR" "OE" "CD" "CI" "ET" "KE" "ML" "NE" "NG" "RW" "SD" "ZA" "OJ" "RU" "OA" "CN" "JP" "KR" "TW" "OB" "BD" "IN" "ID" "MM" "PK" "PH" "TH" "VN" "OI" "' 


//------------------------------------------------------------------------------
// 1. Call Base series: Product(total and desaggregations) and CFC
//------------------------------------------------------------------------------

// Bring GDP in 
use  "$work_data/retropolate-gdp.dta", clear
keep iso year gdp
rename gdp mgdpro_lcu
preserve
	use "$work_data/populations.dta", clear
	keep if widcode=="npopul999i"
	keep iso year value
	rename value npopul
	
	tempfile popul
	save `popul'
restore
merge 1:1 iso year using "`popul'", nogenerate keep(master match)
preserve
	use  "$work_data/ppp.dta", clear
	merge m:1 year using  "$work_data/ppp_ea_cn_weithgted.dta", nogen keep(master match)
	generate xlceup = ppp/ppp_ea
	
	keep if year==$pastyear    
	keep iso xlceup
	
	tempfile ppp
	save `ppp'
restore
merge m:1 iso  using "`ppp'", nogenerate

gen mgdpro_pppeur = (mgdpro_lcu)/xlceup
gen agdpro_pppeur = ((mgdpro_lcu)/xlceup)/npopul

// Load SNA Data (UN, OECD and WITD) and Bachas and PZ2017
merge  1:1 iso year using "$work_data/sna-combined.dta", nogen
drop flag*

// Merge WID regions
merge m:1 iso using "$work_data/import-country-codes-output.dta", nogen keepusing(region1 region2 corecountry)
keep if corecountry==1

// Merge WIL imputed CFC Data
merge 1:1 iso year using "$work_data/cfc-full-imputation.dta", nogen

// Merge historical CFC data from Bengtsson Waldenström
merge 1:1 iso year using "$work_data/BW_Historical_Factor_Share_Database.dta", nogen

//This section is only necesary in case fo calculating the historical regions.
gen core57 = .
foreach country of global coreterritories {
    replace core57 = 1 if iso == `"`country'"' // <<<-----------------------------------
}

order iso year ptxgo confc comhn comnx ceugo ceuhn ceuco gsrhn gsrco gmxhn nmxhn cfcgo cfchn cfcco ccmhn ccshn


//------------------------------------------------------------------------------
// 2. Selected Country adjustments
//------------------------------------------------------------------------------

//---------- 2.1 Constaints for CFC
* Set no negative or zero vars for gross surplus and cfc (remove case by case later)
foreach v of varlist gsr*  gmx*  comhn ceu* cfc* ccm* ccs* {
	replace q_`v' = .  if `v' <= 0
	replace s_`v' = "" if `v' <= 0
	replace   `v' = .  if `v' <= 0
}

*  set CFC lowest value after 1980 ot  0.05
replace q_confc = 0         if confc < 0.05 & year >= 1980
replace s_confc = "assumed" if confc < 0.05 & year >= 1980
replace   confc = 0.05      if confc < 0.05 & year >= 1980
*  set CFC lowest cfc value from 1950-1980 to 0.04
replace q_confc = 0         if confc < 0.04 & year >= 1950
replace s_confc = "assumed" if confc < 0.04 & year >= 1950
replace   confc = 0.04      if confc < 0.04 & year >= 1950


//----------- 2.2 New Zealand - Australia
* Does not report mixed income seperately (report it in corporation(see WID  Issue Brief 2020-07))
* take Australian mixed income and deduct from New Zealand replace by Australian mixed income and deduct from corporation share
preserve
	keep if iso == "AU"
	keep iso year nmxhn gmxhn ccmhn q_nmxhn q_gmxhn q_ccmhn s_nmxhn s_gmxhn s_ccmhn
	foreach v in nmxhn gmxhn ccmhn {
		replace q_`v' = 0
		replace s_`v' = "`v'(AU)"
	}
	replace iso = "NZ"
	tempfile AU_for_NZ
	save `AU_for_NZ'
restore 
merge 1:1 iso year using `AU_for_NZ', update nogen

*deduct from operating surplus
replace q_nsrco = min(3, cond(nsrco >= nmxhn, q_nsrco, q_nmxhn)) if iso == "NZ" & !missing(nsrco) & !missing(nmxhn)
replace s_nsrco = "nsrco,nmxhn" if iso == "NZ" & !missing(nsrco) & !missing(nmxhn)
replace   nsrco = nsrco - nmxhn if iso == "NZ"

replace q_gsrco = min(3, cond(gsrco >= gmxhn, q_gsrco, q_gmxhn)) if iso == "NZ" & missing(gsrco) & !missing(gmxhn)
replace s_gsrco = "gsrco,gmxhn" if iso == "NZ" & missing(gsrco) & !missing(gmxhn)
replace   gsrco = gsrco - gmxhn if iso == "NZ"

//----------- 2.3 China
* Wages paid by the household sector are very large (15-20%)
* item refers rater to total mixed income including wages paid by households (mixed income is missing)
* Assume 10 % wages paid by households
replace q_gmxhn = 1           if iso == "CN" & !missing(ceuhn)
replace s_gmxhn = "0.9ceuhn"  if iso == "CN" & !missing(ceuhn)
replace   gmxhn = ceuhn * 0.9 if iso == "CN"
replace q_comhn = min(3, cond(comhn >= ceuhn, q_comhn, q_ceuhn)) if iso == "CN" & !missing(comhn) & !missing(ceuhn)
replace s_comhn = "comhn,0.9ceuhn"                               if iso == "CN" & !missing(comhn) & !missing(ceuhn)
replace   comhn = comhn - ceuhn * 0.9                            if iso == "CN"
replace q_ceuhn = 1           if iso == "CN" & year >= 1992 & !missing(ceuhn)
replace s_ceuhn = "0.1ceuhn"  if iso == "CN" & year >= 1992 & !missing(ceuhn)
replace   ceuhn = 0.1 * ceuhn if iso == "CN" & year >= 1992

*Use China National Accounts from PYZ 2017 (1992-2014)
merge 1:1 iso year using "$work_data/CN_PYZ2017.dta" , update replace nogen

//----------- 2.4  Russia
*---Use data from Piketty-Novokmet-Zucman including the Assumtion to keep 1980 sectoral shares constat until 1913, because very little self-employment
* use values from Russian National accounts from 1980 to 2014, delete UN data
foreach var in cfcgo cfcco ceugo ceuco ceuhn nsrco nmxhn nsrhn ccmhn ccshn ptxgo confc comhn  {
	replace q_`var' = .  if iso == "RU" & year >= 1900 & year <=2015
	replace s_`var' = "" if iso == "RU" & year >= 1900 & year <=2015
	replace   `var' = .  if iso == "RU" & year >= 1900 & year <=2015
}
merge 1:1 iso year using "$work_data/NPZ2017.dta", nogen update replace


//----------- 2.5  Former Soviet Countries
* Input Russian data
preserve
	keep if iso == "RU"
	replace region2 = "OA"
	keep year region2 cfcgo cfcco ceugo ceuco ceuhn nsrco nmxhn nsrhn ccmhn ccshn ptxgo confc q_cfcgo q_cfcco q_ceugo q_ceuco q_ceuhn q_nsrco q_nmxhn q_nsrhn q_ccmhn q_ccshn q_ptxgo q_confc s_cfcgo s_cfcco s_ceugo s_ceuco s_ceuhn s_nsrco s_nmxhn s_nsrhn s_ccmhn s_ccshn s_ptxgo s_confc 
	foreach v in cfcgo cfcco ceugo ceuco ceuhn nsrco nmxhn nsrhn ccmhn ccshn ptxgo confc {
		replace q_`v' = 0
		replace s_`v' = "`v'(RU)"
	}
	keep if year <= 1987 & year >= 1980
	
	tempfile russia
	save `russia'
restore
* use russia pre 1980 values for all countries in RUCA
merge m:1 year region2 using `russia', update replace nogen



//----------- 2.6 Sweden
merge 1:1 iso year using "$work_data/SE_historical_account.dta", update nogen

//----------- 2.7  Thailand
* use historical shares by Thanasak Jenmana
preserve
	// Import series for Thailand
	use  "$project_dir/data-input/sector-factor-shares/TH_1960-2021.dta", clear
	gen iso = "TH"
	merge 1:1 iso year using "$work_data/cfc-full-imputation.dta"
	keep if iso == "TH" & year >= 1960 & year <= 2021

	gen ptxgo_nni = (nni_mp - nni_fp) / nni_mp
	gen comhn_nni = hh_linc / nni_mp
	gen nmxhn_nni = hh_minc / nni_mp
	gen nsrhn_nni = imputedrent / nni_mp
	gen nsrco_nni = (hh_kinc - imputedrent + corp_inc + gov_inc)  / nni_mp

	* calculate as share of GDP
	foreach var in ptxgo comhn nmxhn nsrhn nsrco {
		gen      q_`var' = min(4, imputed_q_confc)
		gen      s_`var' = "Jenmana"
		gen        `var' = `var'_nni * (1-imputed_confc)
		gen series_`var' = 200000
	}
	keep comhn nmxhn nsrhn nsrco iso year ptxgo  q_comhn q_nmxhn q_nsrhn q_nsrco q_ptxgo s_comhn s_nmxhn s_nsrhn s_nsrco s_ptxgo series*
	
	tempfile TH_hisorical_na
	save `TH_hisorical_na'
restore

merge 1:1 iso year using "`TH_hisorical_na'", update replace nogen


//------------ 2.8  Saudi Arabia
* --- unreaslistic 0 mixed income, use data from offical puplication
/*import excel "~/Documents/GitHub/WIL_sector_output\WIL_GitHub\data-input/SA_national_accounts.xlsx", sheet("SA")  cellrange(A7:AA30) firstrow clear
drop X W Y
drop gsrhn nsrhn ccshn
save "$work_data/country_fix_SA.dta", replace 
*/
replace q_gmxhn = .  if iso == "SA" & year >= 2002 & year <= 2009
replace s_gmxhn = "" if iso == "SA" & year >= 2002 & year <= 2009
replace gmxhn = .    if iso == "SA" & year >= 2002 & year <= 2009

replace q_gvahn = .  if iso == "SA" & year >= 2002 & year <= 2009
replace s_gvahn = "" if iso == "SA" & year >= 2002 & year <= 2009
replace gvahn = .    if iso == "SA" & year >= 2002 & year <= 2009
// From 2002 to 2009 mixed income and operating surplus of HH is 0
// we assume that both is included in corporation profits
// we use the average of the years with data avaibility (2013 to 2015) to split corporate profits
// Net mixed income share of total operating surplus (incl. mixed income): 14 %
// Net OS of housholds of total operating surplus (incl. mixed income): 7 %
replace q_nmxhn = min(3,q_nsrco)    if iso == "SA" & !missing(nsrco)
replace s_nmxhn = "0.14nsrco"       if iso == "SA" & !missing(nsrco)
replace   nmxhn = 0.14 * nsrco      if iso == "SA" 
replace q_gmxhn = .  if iso == "SA" 
replace s_gmxhn = "" if iso == "SA" 
replace   gmxhn = .  if iso == "SA" 
replace q_nsrhn = min(3, q_nsrco) if iso == "SA" & !missing(nsrco)
replace s_nsrhn = "0.07nsrco".    if iso == "SA" & !missing(nsrco)
replace   nsrhn = 0.07 * nsrco    if iso == "SA" 

quality nsrco nsrhn nmxhn, gen(temp1)
replace q_nsrco = temp1                 if iso == "SA" & !missing(nsrco) & !missing(nsrhn) & !missing(nmxhn)
replace s_nsrco = "nsrco,nsrhn,nmxhn"   if iso == "SA" & !missing(nsrco) & !missing(nsrhn) & !missing(nmxhn)
replace   nsrco = nsrco - nsrhn - nmxhn if iso == "SA" 

quality gsrco nsrhn nmxhn, gen(temp2)
replace q_gsrco = temp2              if iso == "SA" & !missing(gsrco) & !missing(nsrhn) & !missing(nmxhn)
replace s_gsrco = "gsrco,nsrhn,nmxh" if iso == "SA" & !missing(gsrco) & !missing(nsrhn) & !missing(nmxhn)
replace   gsrco = gsrco - nsrhn - nmxhn if iso == "SA"
merge 1:1 iso year using "$work_data/country_fix_SA.dta", nogen update replace
replace q_gsrhn = .  if iso == "SA" 
replace s_gsrhn = "" if iso == "SA" 
replace   gsrhn = .  if iso == "SA" 
drop temp*

//------------ 2.9  Peru
** -- Data from Castillo Garcia
merge 1:1 iso year using "$work_data/castillogarcia2026.dta", update replace nogen keepusing( comhn gmxhn ptxgo nnfin q_comhn q_gmxhn q_ptxgo q_nnfin s_comhn s_gmxhn s_ptxgo s_nnfin)

drop *gvato
//------------------------------------------------------------------------------
// 3. Use other data sources if missing
//------------------------------------------------------------------------------

// use BW CFC values for selected countries
gen cond= 1 if missing(confc) & ( inlist(iso, "DE", "ES", "JP", "NL", "NO", "NZ") ///
    | inlist(iso, "FI", "AT", "BE", "DK") ///
    | (iso == "AU" & year != 1941 & year != 1942) ///
    | (iso == "US" & year > 1920))
replace q_confc = q_confc_BW if cond & !missing(confc_BW)
replace s_confc = s_confc_BW       if cond & !missing(confc_BW)
replace confc = confc_BW             if cond
drop cond

local imputedvars "confc cfcgo cfchn cfcco ccshn ccmhn"
foreach var in `imputedvars' {
    local impvar   = "imputed_`var'"
	local impvar_d = "imputed_q_`var'"
	local impvar_s = "imputed_s_`var'"
*	replace series_`var' = 8888 if missing(`var') & !missing(`impvar')
    replace q_`var' = `impvar_d' if missing(`var') & !missing(`impvar') 
	replace s_`var' = `impvar_s' if missing(`var') & !missing(`impvar')
	replace   `var' = `impvar'   if missing(`var') & !missing(`impvar')
}

// following the method in impute-confc.do
quality cfchn nsrhn nmxhn, gen(temp1)
replace q_ccshn = temp1                          if missing(ccshn) & !missing(cfchn) & !missing(nsrhn) & !missing(nmxhn)
replace s_ccshn = "cfchn*nsrhn/(nsrhn+0.3nmxhn)" if missing(ccshn) & !missing(cfchn) & !missing(nsrhn) & !missing(nmxhn)
replace ccshn = cfchn*nsrhn/(nsrhn + 0.3*nmxhn)  if missing(ccshn)  
quality cfchn nmxhn nsrhn, gen(temp2)            
replace q_ccmhn = temp2                             if missing(ccmhn) & !missing(cfchn) & !missing(nsrhn) & !missing(nmxhn)
replace s_ccmhn = "cfchn*0.3nmxhn/(nsrhn+0.3nmxhn)" if missing(ccmhn) & !missing(cfchn) & !missing(nsrhn) & !missing(nmxhn)
replace ccmhn = cfchn*0.3*nmxhn/(nsrhn + 0.3*nmxhn) if missing(ccmhn)
drop temp*
//------------------------------------------------------------------------------
// 4. Logical Splits
//------------------------------------------------------------------------------

* Logical splits (gross-net)
// Complete gross / net values
replace q_nsrhn = min(3, cond(gsrhn >= ccshn, q_gsrhn, q_ccshn)) if missing(nsrhn) & (gsrhn > ccshn)
replace q_nmxhn = min(3, cond(gmxhn >= ccmhn, q_gmxhn, q_ccmhn)) if missing(nmxhn) & (gmxhn > ccmhn)
replace q_nsmhn = min(3, cond(gsmhn >= cfchn, q_gsmhn, q_cfchn)) if missing(nsmhn) & (gsmhn > cfchn)
replace q_nsrgo = min(3, cond(gsrgo >= cfcgo, q_gsrgo, q_cfcgo)) if missing(nsrgo) & (gsrgo > cfcgo)
replace q_nsrco = min(3, cond(gsrco >= cfcco, q_gsrco, q_cfcco)) if missing(nsrco) & (gsrco > cfcco)
replace q_gsrhn = min(3, cond(nsrhn >= ccshn, q_nsrhn, q_ccshn)) if missing(gsrhn)
replace q_gmxhn = min(3, cond(nmxhn >= ccmhn, q_nmxhn, q_ccmhn)) if missing(gmxhn)
replace q_gsmhn = min(3, cond(nsmhn >= cfchn, q_nsmhn, q_cfchn)) if missing(gsmhn)
replace q_gsrgo = min(3, cond(nsrgo >= cfcgo, q_nsrgo, q_cfcgo)) if missing(gsrgo)
replace q_gsrco = min(3, cond(nsrco >= cfcco, q_nsrco, q_cfcco)) if missing(gsrco)
replace s_nsrhn = "gsrhn,ccshn"   if missing(nsrhn) & (gsrhn > ccshn)
replace s_nmxhn = "gmxhn,ccmhn"   if missing(nmxhn) & (gmxhn > ccmhn)
replace s_nsmhn = "gsmhn,cfchn"   if missing(nsmhn) & (gsmhn > cfchn)
replace s_nsrgo = "gsrgo,cfcgo"   if missing(nsrgo) & (gsrgo > cfcgo)
replace s_nsrco = "gsrco,cfcco"   if missing(nsrco) & (gsrco > cfcco)
replace s_gsrhn = "nsrhn,ccshn"   if missing(gsrhn) & !mi(nsrhn) & !mi(ccshn)
replace s_gmxhn = "nmxhn,ccmhn"   if missing(gmxhn) & !mi(nmxhn) & !mi(ccmhn)
replace s_gsmhn = "nsmhn,cfchn"   if missing(gsmhn) & !mi(nsmhn) & !mi(cfchn)
replace s_gsrgo = "nsrgo,cfcgo"   if missing(gsrgo) & !mi(nsrgo) & !mi(cfcgo)
replace s_gsrco = "nsrco,cfcco"   if missing(gsrco) & !mi(nsrco) & !mi(cfcco)
replace nsrhn = gsrhn - ccshn if missing(nsrhn) & (gsrhn > ccshn)
replace nmxhn = gmxhn - ccmhn if missing(nmxhn) & (gmxhn > ccmhn)
replace nsmhn = gsmhn - cfchn if missing(nsmhn) & (gsmhn > cfchn)
replace nsrgo = gsrgo - cfcgo if missing(nsrgo) & (gsrgo > cfcgo)
replace nsrco = gsrco - cfcco if missing(nsrco) & (gsrco > cfcco)
replace gsrhn = nsrhn + ccshn if missing(gsrhn) & !mi(nsrhn) & !mi(ccshn)
replace gmxhn = nmxhn + ccmhn if missing(gmxhn) & !mi(nmxhn) & !mi(ccmhn)
replace gsmhn = nsmhn + cfchn if missing(gsmhn) & !mi(nsmhn) & !mi(cfchn)
replace gsrgo = nsrgo + cfcgo if missing(gsrgo) & !mi(nsrgo) & !mi(cfcgo)
replace gsrco = nsrco + cfcco if missing(gsrco) & !mi(nsrco) & !mi(cfcco)

// By convention nsrgo == 0
replace q_nsrgo = 0          if missing(nsrgo)
replace s_nsrgo = "assumed0" if missing(nsrgo)
replace nsrgo = 0            if missing(nsrgo)
replace q_gsrgo = min(3, q_cfcgo) if missing(gsrgo) & !missing(cfcgo)
replace s_gsrgo = "cfcgo"         if missing(gsrgo) & !missing(cfcgo)
replace   gsrgo = cfcgo           if missing(gsrgo)
replace q_gsmhn = min(3, cond(gmxhn >= gsrhn, q_gmxhn, q_gsrhn)) if missing(gsmhn) & !missing(gmxhn) & !missing(gsrhn)
replace s_gsmhn = "gmxhn,gsrhn" if missing(gsmhn) & !missing(gmxhn) & !missing(gsrhn)
replace   gsmhn = gmxhn + gsrhn if missing(gsmhn)

// Logical splits Compensation of employees
replace q_comnx = min(3, cond(comrx >= compx, q_comrx, q_compx)) if missing(comnx) & !missing(comrx) & !missing(compx)
replace s_comnx = s_comrx   if missing(comnx) & !missing(comrx) & !missing(compx)
replace   comnx = comrx - compx if missing(comnx)
quality comhn comnx ceugo ceuhn, gen(temp2) 
replace q_ceuco = temp2     if missing(ceuco) & !missing(comhn) & !missing(comnx) & !missing(ceugo) & !missing(ceuhn)
replace s_ceuco = "comhn,comnx,ceugo,ceuhn"   if missing(ceuco) & !missing(comhn) & !missing(comnx) & !missing(ceugo) & !missing(ceuhn)
replace ceuco = comhn - comnx - ceugo - ceuhn if missing(ceuco)
replace q_ceuco = .  if ceuco < 0
replace s_ceuco = "" if ceuco < 0
replace ceuco = .  if ceuco < 0
quality comhn comnx ceuhn ceuco, gen(temp3)
replace q_ceugo = temp3                         if missing(ceugo) & iso != "GB" & !missing(comhn) & !missing(comnx) & !missing(ceuco) & !missing(ceuhn)
replace s_ceugo = "comhn,comnx,ceuhn,ceuco"     if missing(ceugo) & iso != "GB" & !missing(comhn) & !missing(comnx) & !missing(ceuco) & !missing(ceuhn)
replace   ceugo = comhn - comnx - ceuhn - ceuco if missing(ceugo) & iso != "GB"
replace q_ceugo = .  if ceugo < 0
replace s_ceugo = "" if ceugo < 0
replace ceugo = .  if ceugo < 0
quality comhn comnx ceugo ceuco, gen(temp4)
replace q_ceuhn = temp4                         if missing(ceuhn) & !missing(comhn) & !missing(comnx) & !missing(ceugo) & !missing(ceuco)
replace s_ceuhn = "comhn,comnx,ceugo,ceuco"     if missing(ceuhn) & !missing(comhn) & !missing(comnx) & !missing(ceugo) & !missing(ceuco)
replace   ceuhn = comhn - comnx - ceugo - ceuco if missing(ceuhn)
replace q_ceuhn = .  if ceuhn < 0
replace s_ceuhn = "" if ceuhn < 0
replace   ceuhn = .  if ceuhn < 0
drop temp*

//-----------------------------------------------------------------------------
// 5. Distribute compensation of employees between corporations and households 
//-----------------------------------------------------------------------------
// Distribute compensation of employees between corporations and households if we have goverment wages payed
//    wages paid by households are anyways allways very small (<<5%)
quality comhn comnx ceugo, gen(temp)
gen q_ceu_priv = temp                  if !missing(comhn) & !missing(comnx) & !missing(ceugo)
gen s_ceu_priv = "comhn,comnx,ceugo"   if !missing(comhn) & !missing(comnx) & !missing(ceugo)
gen   ceu_priv = comhn - comnx - ceugo
drop temp

// Assume zero net foreighn labour income if missing (comnx = 0)
replace q_ceu_priv = min(3, cond(comhn >= ceugo, q_comhn, q_ceugo)) if missing(ceu_priv) & !missing(comhn) & !missing(ceugo)
replace s_ceu_priv = "comhn,ceugo"                                 if missing(ceu_priv) & !missing(comhn) & !missing(ceugo)
replace   ceu_priv = comhn - ceugo                                 if missing(ceu_priv)
replace q_ceu_priv = .  if ceu_priv < 0
replace s_ceu_priv = "" if ceu_priv < 0
replace  ceu_priv = . if ceu_priv < 0

// 5.1 If possible, use last data share available
gen valid_year = !missing(ceu_priv) & !missing(ceuco)  & !missing(ceuhn) 
bysort iso (year): egen oldest_valid_year = min(year) if valid_year
gen     ceuhn_share = .
replace ceuhn_share = ceuhn / (ceuhn + ceuco) if year == oldest_valid_year
gsort iso - year
by iso: replace ceuhn_share = ceuhn_share[_n-1]     if missing(ceuhn_share)
gsort iso year
by iso: replace ceuhn_share = ceuhn_share[_n-1]     if missing(ceuhn_share) 
replace q_ceuhn = q_ceu_priv                             if missing(ceuhn) & !missing(ceu_priv) & !missing(ceuhn_share)
replace s_ceuhn = "ceu-priv_ratiolagceuhn/(ceuhn+ceuco)" if missing(ceuhn) & !missing(ceu_priv) & !missing(ceuhn_share)
replace   ceuhn = ceuhn_share * ceu_priv                 if missing(ceuhn)
replace q_ceuco = min(3, cond(ceu_priv >= ceuhn,q_ceu_priv, q_ceuhn)) if missing(ceuco) & !missing(ceu_priv) & !missing(ceuhn)
replace s_ceuco = "ceu-priv,ceuhn"                                    if missing(ceuco) & !missing(ceu_priv) & !missing(ceuhn)
replace   ceuco = ceu_priv - ceuhn                                    if missing(ceuco)
drop valid_year ceuhn_share oldest_valid_year valid_year

// 5.2 Use the share of Mixen income and Firm profits as proxy
gen gmx_share = gmxhn / (gmxhn + gsrco)
quality ceu_priv gmxhn gsrco, gen(temp2)
replace q_ceuhn = temp2                                  if missing(ceuhn) & !missing(ceu_priv) & !missing(gmx_share)
replace s_ceuhn = "ceu-priv_ratio0.3gmxhn/(gmxhn+gsrco)" if missing(ceuhn) & !missing(ceu_priv) & !missing(gmx_share)
replace ceuhn = ceu_priv * (0.3 * gmx_share)             if missing(ceuhn)
replace q_ceuco = min(3, cond(ceu_priv >= ceuhn, q_ceu_priv, q_ceuhn)) if missing(ceuco) & !missing(ceu_priv) & !missing(ceuhn) 
replace s_ceuco = "ceu-priv,ceuhn"                                     if missing(ceuco) & !missing(ceu_priv) & !missing(ceuhn) 
replace   ceuco = ceu_priv - ceuhn                                     if missing(ceuco)
drop *ceu_priv gmx_share temp*

//------------------------------------------------------------------------------
// 6. Intrapolate all values linearly between gabs and carryforeward last observation
//------------------------------------------------------------------------------

* Sort the data by iso and year
sort iso year

* List of variables to process
local vars confc cfcgo cfcco ceugo ceuco ceuhn nsrco nmxhn nsrhn ccmhn ccshn ///
gsrhn gmxhn comhn ptxgo mgdpro_pppeur

gen q_mgdpro_pppeur=.
gen       s_mgdpro_pppeur=""
* Loop through each variable
foreach var in `vars' {
    bysort iso (year): ipolate `var' year, gen(`var'_interp)

    * Step 2: Carry forward the last observed value after the last observed year
    bysort iso (year): carryforward `var'_interp if year >= 2013, gen(`var'_carried)

    * Step 3: Create an indicator for interpolated values
    gen `var'_is_interp = 0
    replace `var'_is_interp = 1 if missing(`var') & !missing(`var'_interp) & year >= year[_n-1] & year <= year[_n+1]

    * Step 4: Create an indicator for carried-forward values
    gen `var'_is_carried = 0
        replace `var'_is_carried = 1 if missing(`var') & !missing(`var'_carried) & year >= 2013

    * Step 5: Replace original variable with interpolated/carried-forward values
    replace q_`var' = 3              if `var'_is_interp == 1
	replace s_`var' = "ipol"         if `var'_is_interp == 1
	replace `var' = `var'_interp   if `var'_is_interp == 1
	
    replace q_`var' = 0              if `var'_is_carried == 1
    replace s_`var' = "carryfor" if `var'_is_carried == 1
    replace `var' = `var'_carried  if `var'_is_carried == 1
	drop `var'_carried  `var'_interp `var'_is_carried  `var'_is_interp
}
drop q_mgdpro_pppeur s_mgdpro_pppeur

* do logical splits again
replace q_nsrhn = min(3, cond(gsrhn >= ccshn, q_gsrhn, q_ccshn)) if missing(nsrhn) & (gsrhn > ccshn)
replace q_nmxhn = min(3, cond(gmxhn >= ccmhn, q_gmxhn, q_ccmhn)) if missing(nmxhn) & (gmxhn > ccmhn)
replace q_nsmhn = min(3, cond(gsmhn >= cfchn, q_gsmhn, q_cfchn)) if missing(nsmhn) & (gsmhn > cfchn)
replace q_nsrgo = min(3, cond(gsrgo >= cfcgo, q_gsrgo, q_cfcgo)) if missing(nsrgo) & (gsrgo > cfcgo)
replace q_nsrco = min(3, cond(gsrco >= cfcco, q_gsrco, q_cfcco)) if missing(nsrco) & (gsrco > cfcco)
replace q_gsrhn = min(3, cond(nsrhn >= ccshn, q_nsrhn, q_ccshn)) if missing(gsrhn) & !missing(q_nsrhn) & !missing(q_ccshn)
replace q_gmxhn = min(3, cond(nmxhn >= ccmhn, q_nmxhn, q_ccmhn)) if missing(gmxhn) & !missing(q_nmxhn) & !missing(q_ccmhn)
replace q_gsmhn = min(3, cond(nsmhn >= cfchn, q_nsmhn, q_cfchn)) if missing(gsmhn) & !missing(q_nsrgo) & !missing(q_cfcgo)
replace q_gsrgo = min(3, cond(nsrgo >= cfcgo, q_nsrgo, q_cfcgo)) if missing(gsrgo) & !missing(q_nsrgo) & !missing(q_cfcgo)
replace q_gsrco = min(3, cond(nsrco >= cfcco, q_nsrco, q_cfcco)) if missing(gsrco) & !missing(q_nsrco) & !missing(q_cfcco)
replace s_nsrhn = "gsrhn,ccshn" if missing(nsrhn) & (gsrhn > ccshn)
replace s_nmxhn = "gmxhn,ccmhn" if missing(nmxhn) & (gmxhn > ccmhn)
replace s_nsmhn = "gsmhn,cfchn" if missing(nsmhn) & (gsmhn > cfchn)
replace s_nsrgo = "gsrgo,cfcgo" if missing(nsrgo) & (gsrgo > cfcgo)
replace s_nsrco = "gsrco,cfcco" if missing(nsrco) & (gsrco > cfcco)
replace s_gsrhn = "nsrhn,ccshn" if missing(gsrhn) & !missing(s_nsrhn) & !missing(s_ccshn)
replace s_gmxhn = "nmxhn,ccmhn" if missing(gmxhn) & !missing(s_nmxhn) & !missing(s_ccmhn)
replace s_gsmhn = "nsmhn,cfchn" if missing(gsmhn) & !missing(s_nsmhn) & !missing(s_cfchn)
replace s_gsrgo = "nsrgo,cfcgo" if missing(gsrgo) & !missing(s_nsrgo) & !missing(s_cfcgo)
replace s_gsrco = "nsrco,cfcco" if missing(gsrco) & !missing(s_nsrco) & !missing(s_cfcco)
replace nsrhn = gsrhn - ccshn if missing(nsrhn) & (gsrhn > ccshn)
replace nmxhn = gmxhn - ccmhn if missing(nmxhn) & (gmxhn > ccmhn)
replace nsmhn = gsmhn - cfchn if missing(nsmhn) & (gsmhn > cfchn)
replace nsrgo = gsrgo - cfcgo if missing(nsrgo) & (gsrgo > cfcgo)
replace nsrco = gsrco - cfcco if missing(nsrco) & (gsrco > cfcco)
replace gsrhn = nsrhn + ccshn if missing(gsrhn)
replace gmxhn = nmxhn + ccmhn if missing(gmxhn)
replace gsmhn = nsmhn + cfchn if missing(gsmhn)
replace gsrgo = nsrgo + cfcgo if missing(gsrgo)
replace gsrco = nsrco + cfcco if missing(gsrco)


//------------------------------------------------------------------------------
// 7. calculate aggreate sectoral value added which we base the imputation on 
//------------------------------------------------------------------------------

* Compute Institutional sector totals
replace q_gvago = min(2, cond(ceugo >= cfcgo, q_ceugo, q_cfcgo)) if !missing(ceugo) | !missing(cfcgo)
quality ceuco nsrco cfcco, gen(temp1)
replace q_gvaco = temp1                                          if !missing(ceuco) | !missing(nsrco) | !missing(cfcco)  
replace q_gsrhn = min(2, cond(nsrhn >= ccshn, q_nsrhn, q_ccshn)) if !missing(nsrhn) | !missing(ccshn)  
quality nmxhn ccmhn ceuhn, gen(temp2)
replace q_gvmhn = temp2                                          if !missing(nmxhn) | !missing(ccmhn) | !missing(ceuhn) 		
replace q_gvahn = min(2, cond(gsrhn >= gvmhn, q_gsrhn, q_gvmhn)) if !missing(gsrhn) | !missing(gvmhn)
replace s_gvago = "ceugo,cfcgo"       if (!missing(ceugo) | !missing(cfcgo)) & !mi(q_gvago)
replace s_gvaco = "ceuco,nsrco,cfcco" if (!missing(ceuco) | !missing(nsrco) | !missing(cfcco)) & !mi(q_gvaco)
replace s_gsrhn = "nsrhn,ccshn"       if (!missing(nsrhn) | !missing(ccshn)) & !mi(q_gsrhn)  
replace s_gvmhn = "nmxhn,ccmhn,ceuhn" if (!missing(nmxhn) | !missing(ccmhn) | !missing(ceuhn)) & !mi(q_gvmhn) 	
replace s_gvahn = "gsrhn,gvmhn"       if (!missing(gsrhn) | !missing(gvmhn)) & !mi(q_gvahn)
replace gvago = ceugo + cfcgo  
replace gvaco = ceuco + nsrco + cfcco  
replace gsrhn = nsrhn + ccshn         // GVA operating surplus (Housing)
replace gvmhn = nmxhn + ccmhn + ceuhn // GVA Mixed income = Self-employment + compensation of emplyees
replace gvahn = gsrhn + gvmhn
drop temp*

* Use gva by sector from national accounts at basic prices. 
* To have value added at factor-price we have to deduct "other net taxes on production"
replace q_gvago = min(3, cond(gvbgo >= tspgo, q_gvbgo, q_tspgo)) if missing(gvago) & !missing(gvbgo) & missing(tspgo)
replace s_gvago = "gvbgo,tspgo"                                  if missing(gvago) & !missing(gvbgo) & missing(tspgo)
replace   gvago = gvbgo - tspgo                                  if missing(gvago)
replace q_gvaco = min(3, cond(gvbco >= tspco, q_gvbco, q_tspco)) if missing(gvaco) & !missing(gvbco) & !missing(tspco)
replace s_gvaco = "gvbco,tspco"                                  if missing(gvaco) & !missing(gvbco) & !missing(tspco)
replace   gvaco = gvbco - tspco                                  if missing(gvaco)
replace q_gvahn = min(3, cond(gvbhn >= tsphn, q_gvbhn, q_tsphn)) if missing(gvahn) & !missing(gvbhn) & !missing(tsphn)
replace s_gvahn = "gvbhn,tsphn"                                  if missing(gvahn) & !missing(gvbhn) & !missing(tsphn)
replace   gvahn = gvbhn - tsphn                                  if missing(gvahn)

* This ignores the inconsistency that "other taxes and production" are included in the gvb variable and again in ptxgo, however very small
replace q_gvago = min(3,q_gvbgo) if missing(gvago) & !missing(gvbgo)
replace s_gvago = "gvbgo"        if missing(gvago) & !missing(gvbgo)
replace   gvago = gvbgo          if missing(gvago)
replace q_gvaco = min(3,q_gvbco) if missing(gvaco) & !missing(gvbco)
replace s_gvaco = "gvbco"        if missing(gvaco) & !missing(gvbco)
replace   gvaco = gvbco          if missing(gvaco)
replace q_gvahn = min(3,q_gvbhn) if missing(gvahn) & !missing(gvbhn)
replace s_gvahn = "gvbhn"        if missing(gvahn) & !missing(gvbhn)
replace   gvahn = gvbhn          if missing(gvahn)

* Create GDP per capita ranges
gen gdp_range = cond(agdpro_pppeur >= 0 & agdpro_pppeur < 2500, "0_2500", ///
                cond(agdpro_pppeur >= 2500 & agdpro_pppeur < 5000, "2500_5000", ///
                cond(agdpro_pppeur >= 5000 & agdpro_pppeur < 10000, "5000_10000", ///
                cond(agdpro_pppeur >= 10000 & agdpro_pppeur < 25000, "10000_25000", ///
                "above_25000"))))

tempfile NDP_inst_bef_imputation
save `NDP_inst_bef_imputation'


//------------------------------------------------------------------------------
// 8. Impute sector until 1980 based on regional GDP per capita for 216 countries  
//------------------------------------------------------------------------------
* In RUCA we use post 1990 variables, before we assumed that they follow Russia
drop if region1 == "XR" & year < 1990

* Calcualte regional averages based on gdp per capita
keep if corecountry == 1 & year >= 1950 & agdpro_ppp != .

* Collapse data by region and GDP range 
collapse (median) confc ptxgo gvago gvaco gvmhn gsrhn agdpro_pppeur ///
         (count) obs_count = gvago country_year_count = year, by(region1 gdp_range)
		 

fillin region1 gdp_range
keep gvago gvaco gvmhn gsrhn gdp_range region1 confc ptxgo country_year_count

* sort the vars propperly
gen         gdp_numeric = real(substr(gdp_range, 1, strpos(gdp_range, "_") - 1))
replace     gdp_numeric = 25000 if gdp_range == "above_25000"
sort region gdp_numeric

* If no data for a certain bracket use closeset bracket
foreach var in gvago gvaco gvmhn gsrhn confc ptxgo{
	by region: replace `var' = `var'[_n+1] if gdp_range == "0_2500" & missing(`var')
}

* rescale everything to gdp
gen total_sectors = gvago + gvaco + ptxgo + gvmhn + gsrhn
foreach v in gvago gvaco ptxgo gvmhn gsrhn{
	replace `v'= `v' / total_sectors 
}
drop total_sector

foreach var of varlist gvago gvaco gvmhn gsrhn {
    replace `var' = round(`var', 0.01)
	local newname = "`var'5"
    rename `var' `newname'
}
replace confc = round(confc, 0.01)
rename confc confc5
replace ptxgo = round(ptxgo, 0.01)
rename ptxgo ptxgo5

foreach v in confc5 ptxgo5 gvago5 gvaco5 gvmhn5 gsrhn5 {
	gen     q_`v' = 0
	gen     s_`v' = substr("`v'",1,5)+"(medianreg" + region1+")"
	replace s_`v' = s_`v' + "(RUpre90)" if region1=="XR"
}

tempfile GDP_ranges_shares_six
save `GDP_ranges_shares_six', replace

//------------------------------------------------------------------------------
// 9. Split imputed sectoral shares to single components
//------------------------------------------------------------------------------

//        - if available use the oldest share available
//        - if not use the regional average share

* Merge and replace imputed sectoral gdp shares
use "`NDP_inst_bef_imputation'", clear
merge m:1 region1 gdp_range using "`GDP_ranges_shares_six'", nogen keep(master match)

sort iso year
foreach var of varlist gvago5 gvaco5 gvmhn5 gsrhn5 ptxgo5 confc5{
    replace q_`var' = .  if year < 1980
	replace s_`var' = "" if year < 1980
	replace   `var' = .  if year < 1980
	replace q_`var' = .  if corecountry != 1
	replace s_`var' = "" if corecountry != 1
	replace   `var' = .  if corecountry != 1
}

// Create suffix _5 variables for all subcumponents for imputed values
foreach v in ceugo nsrgo ceuco ceuhn nsrco nmxhn nsrhn cfcgo cfcco ccmhn ccshn gsrco {
	gen q_`v'5 = .
	gen s_`v'5 = ""
	gen   `v'5 = .
}

//---------- 9.1  Governement
replace q_ceugo5 = min(3, cond(gvago5 >= cfcgo, q_gvago5, q_cfcgo)) if !missing(gvago5) & !missing(cfcgo)
replace s_ceugo5 = "gvago(medianreg"+region1+"),cfcgo"              if !missing(gvago5) & !missing(cfcgo)
replace   ceugo5 = gvago5 - cfcgo


//---------- 9.2 Corporations (gvaco)
* Step 1: Calculate shares for each country
gen  valid_year = !missing(ceuco) & !missing(nsrco) & !missing(cfcco)
bysort iso (year): egen oldest_valid_year = min(year) if valid_year
gen ceuco_share = .
gen nsrco_share = .
gen cfcco_share = .

bysort iso: replace ceuco_share = ceuco / (ceuco + nsrco + cfcco) if year == oldest_valid_year
bysort iso: replace cfcco_share = cfcco / (ceuco + nsrco + cfcco) if year == oldest_valid_year
bysort iso: replace nsrco_share = nsrco / (ceuco + nsrco + cfcco) if year == oldest_valid_year

gsort iso - year
by iso: replace ceuco_share = ceuco_share[_n-1] if missing(ceuco_share) 
by iso: replace cfcco_share = cfcco_share[_n-1] if missing(cfcco_share)
by iso: replace nsrco_share = nsrco_share[_n-1] if missing(nsrco_share)


* Step 2: Calculate regional averages for shares
preserve
	collapse (median) ceuco_share cfcco_share nsrco_share, by(region1)
	rename ceuco_share ceuco_share_region
	rename cfcco_share cfcco_share_region
	rename nsrco_share nsrco_share_region
	tempfile region_shares
	save `region_shares'
restore

* Step 3: Merge regional averages back into the main dataset
merge m:1 region1 using "`region_shares'", nogen

* Step 4: Replace missing shares with regional averages
replace ceuco_share = ceuco_share_region if missing(ceuco_share)
replace cfcco_share = cfcco_share_region if missing(cfcco_share)
replace nsrco_share = nsrco_share_region if missing(nsrco_share)
gen     s_ceuco_share = "median[ceuco/(ceuco+nsrco+cfcco)]reg" + cond(!mi(region1),region1,"others") if !missing(ceuco_share) 
gen     s_cfcco_share = "median[cfcco/(ceuco+nsrco+cfcco)]reg" + cond(!mi(region1),region1,"others") if !missing(cfcco_share) 
gen     s_nsrco_share = "median[nsrco/(ceuco+nsrco+cfcco)]reg" + cond(!mi(region1),region1,"others") if !missing(nsrco_share) 

* Step 5: Recompute imputed values
replace q_ceuco5 = min(3,q_gvaco5)                  if missing(ceuco) & missing(ceuco5) & !missing(ceuco_share) & !missing(gvaco5)
replace s_ceuco5 = s_gvaco5 +"_ratio"+s_ceuco_share if missing(ceuco) & missing(ceuco5) & !missing(ceuco_share) & !missing(gvaco5)
replace   ceuco5 = ceuco_share * gvaco5             if missing(ceuco) & missing(ceuco5) 

replace q_cfcco5 = min(3,q_gvaco5)                  if missing(cfcco) & missing(cfcco5) & !missing(cfcco_share) & !missing(gvaco5)
replace s_cfcco5 = s_gvaco5 +"_ratio"+s_cfcco_share if missing(cfcco) & missing(cfcco5) & !missing(cfcco_share) & !missing(gvaco5)
replace   cfcco5 = cfcco_share * gvaco5             if missing(cfcco) & missing(cfcco5) 

replace q_nsrco5 = min(3,q_gvaco5)                  if missing(nsrco) & missing(nsrco5) & !missing(nsrco_share) & !missing(gvaco5)
replace s_nsrco5 = s_gvaco5 +"_ratio"+s_nsrco_share if missing(nsrco) & missing(nsrco5) & !missing(nsrco_share) & !missing(gvaco5)
replace   nsrco5 = nsrco_share * gvaco5             if missing(nsrco) & missing(nsrco5) 

drop valid_year ceuco_share cfcco_share nsrco_share oldest_valid_year ceuco_share_region cfcco_share_region nsrco_share_region s_ceuco_share s_cfcco_share s_nsrco_share

//---------- 9.3 Households Mixed Income (gvmhn)
gen valid_year = !missing(ceuhn) & !missing(nmxhn) & !missing(ccmhn)
bysort iso (year): egen oldest_valid_year = min(year) if valid_year
gen ceuhn_share = .
gen nmxhn_share = .
gen ccmhn_share = .

bysort iso: replace ceuhn_share = ceuhn / (ceuhn + nmxhn + ccmhn) if year == oldest_valid_year
bysort iso: replace ccmhn_share = ccmhn / (ceuhn + nmxhn + ccmhn) if year == oldest_valid_year
bysort iso: replace nmxhn_share = nmxhn / (ceuhn + nmxhn + ccmhn) if year == oldest_valid_year


gsort iso - year
by iso: replace ceuhn_share = ceuhn_share[_n-1] if missing(ceuhn_share) 
by iso: replace ccmhn_share = ccmhn_share[_n-1] if missing(ccmhn_share)
by iso: replace nmxhn_share = nmxhn_share[_n-1] if missing(nmxhn_share)


* Calculate regional averages for shares
preserve
	collapse (median) ceuhn_share nmxhn_share ccmhn_share, by(region1)
	rename ceuhn_share ceuhn_share_region
	rename nmxhn_share nmxhn_share_region
	rename ccmhn_share ccmhn_share_region
	tempfile region_shares_hm
	save `region_shares_hm'
restore

* Merge regional averages back into the main dataset
merge m:1 region1 using "`region_shares_hm'", nogen

* Replace missing shares with regional averages
replace ceuhn_share = ceuhn_share_region if missing(ceuhn_share)
replace nmxhn_share = nmxhn_share_region if missing(nmxhn_share)
replace ccmhn_share = ccmhn_share_region if missing(ccmhn_share)
gen     s_ceuhn_share = "median[ceuhn/(ceuhn+nmxhn+ccmhn)]reg" + cond(!mi(region1),region1,"others") if !missing(ceuhn_share) 
gen     s_nmxhn_share = "median[ccmhn/(ceuhn+nmxhn+ccmhn)]reg" + cond(!mi(region1),region1,"others") if !missing(nmxhn_share) 
gen     s_ccmhn_share = "median[nmxhn/(ceuhn+nmxhn+ccmhn)]reg" + cond(!mi(region1),region1,"others") if !missing(ccmhn_share) 

* Recompute imputed values
replace q_ceuhn5 = min(3, q_gvmhn5)                  if missing(ceuhn) & missing(ceuhn5) & !missing(ceuhn_share) & !missing(gvmhn5)
replace s_ceuhn5 = s_gvmhn5 +"_ratio"+s_ceuhn_share  if missing(ceuhn) & missing(ceuhn5) & !missing(ceuhn_share) & !missing(gvmhn5)
replace ceuhn5 = ceuhn_share * gvmhn5                if missing(ceuhn) & missing(ceuhn5)
replace q_ccmhn5 = min(3, q_gvmhn5)                  if missing(ccmhn) & missing(ccmhn5) & !missing(ccmhn_share) & !missing(gvmhn5)
replace s_ccmhn5 = s_gvmhn5 +"_ratio"+s_ccmhn_share  if missing(ccmhn) & missing(ccmhn5) & !missing(ccmhn_share) & !missing(gvmhn5)
replace ccmhn5 = ccmhn_share * gvmhn5                if missing(ccmhn) & missing(ccmhn5)
replace q_nmxhn5 = min(3, q_gvmhn5)                  if missing(nmxhn) & missing(nmxhn5) & !missing(nmxhn_share) & !missing(gvmhn5)
replace s_nmxhn5 = s_gvmhn5 +"_ratio"+s_nmxhn_share  if missing(nmxhn) & missing(nmxhn5) & !missing(nmxhn_share) & !missing(gvmhn5)
replace nmxhn5 = nmxhn_share * gvmhn5                if missing(nmxhn) & missing(nmxhn5)

drop valid_year ceuhn_share nmxhn_share ccmhn_share oldest_valid_year ceuhn_share_region nmxhn_share_region ccmhn_share_region s_ceuhn_share s_ccmhn_share s_nmxhn_share

//---------- 9.4 Households Housing (gsrhn)
* Repeat the same steps for Households Housing
gen valid_year = !missing(nsrhn) & !missing(ccshn)
bysort iso (year): egen oldest_valid_year = min(year) if valid_year
gen nsrhn_share = .
gen ccshn_share = .

bysort iso: replace nsrhn_share = nsrhn / (nsrhn + ccshn) if year == oldest_valid_year
bysort iso: replace ccshn_share = ccshn / (nsrhn + ccshn) if year == oldest_valid_year


gsort iso - year
by iso: replace nsrhn_share = nsrhn_share[_n-1] if missing(nsrhn_share) 
by iso: replace ccshn_share = ccshn_share[_n-1] if missing(ccshn_share)


* Calculate regional averages for shares
preserve
	collapse (median) nsrhn_share ccshn_share, by(region1)
	rename nsrhn_share nsrhn_share_region
	rename ccshn_share ccshn_share_region
	tempfile region_shares_hh
	save `region_shares_hh'
restore

* Merge regional averages back into the main dataset
merge m:1 region1 using "`region_shares_hh'", nogen

* Replace missing shares with regional averages
replace   nsrhn_share = nsrhn_share_region if missing(nsrhn_share)
replace   ccshn_share = ccshn_share_region if missing(ccshn_share)
gen       s_nsrhn_share = "median[nsrhn/(nsrhn+ccshn)]reg" + cond(!mi(region1),region1,"others") if !missing(nsrhn_share)
gen       s_ccshn_share = "median[ccshn/(nsrhn+ccshn)]reg" + cond(!mi(region1),region1,"others") if !missing(ccshn_share)
* Recompute imputed values
replace q_nsrhn5 = min(3, q_gsrhn5 )               if missing(nsrhn) & missing(nsrhn5) & !missing(nsrhn_share) & !missing(gsrhn5)
replace s_nsrhn5 = s_gsrhn5+"_ratio"+s_nsrhn_share if missing(nsrhn) & missing(nsrhn5) & !missing(nsrhn_share) & !missing(gsrhn5)
replace nsrhn5 = nsrhn_share * gsrhn5              if missing(nsrhn) & missing(nsrhn5)
replace q_ccshn5 = min(3, q_gsrhn5 )               if missing(ccshn) & missing(ccshn5) & !missing(ccshn_share) & !missing(gsrhn5)
replace s_ccshn5 = s_gsrhn5+"_ratio"+s_ccshn_share if missing(ccshn) & missing(ccshn5) & !missing(ccshn_share) & !missing(gsrhn5)
replace ccshn5 = ccshn_share * gsrhn5              if missing(ccshn) & missing(ccshn5)

drop valid_year nsrhn_share ccshn_share oldest_valid_year nsrhn_share_region ccshn_share_region s_nsrhn_share s_ccshn_share

//------------------------------------------------------------------------------
// 10. replace imputed components if missing, create imputed indicator
//------------------------------------------------------------------------------

* List of variables to process
local vars cfcgo cfcco ceugo ceuco ceuhn nsrco nmxhn nsrhn ccmhn ccshn ptxgo confc 
sort iso year
* Loop through each variable
foreach var in `vars' {
    replace series_`var' = 9999 if missing(`var') & !missing(`var'5)
	replace q_`var' = q_`var'5 if missing(`var') & !missing(`var'5) & (year == 1970 | year == 1980 | year == 1990 | year == 2000 | year == 2010 | year == 2020)
	replace s_`var' = s_`var'5 if missing(`var') & !missing(`var'5) & (year == 1970 | year == 1980 | year == 1990 | year == 2000 | year == 2010 | year == 2020)
    replace   `var' =   `var'5 if missing(`var') & !missing(`var'5) & (year == 1970 | year == 1980 | year == 1990 | year == 2000 | year == 2010 | year == 2020)
	bysort iso (year): ipolate `var' year, generate(`var'_ipo)
	bysort iso (year): carryforward `var'_ipo, gen(`var'_carried)
	
	replace q_`var' = 3          if missing(`var') & !missing(`var'_ipo)
	replace q_`var' = 1          if missing(`var') &  missing(`var'_ipo)  & year > 2020 & !missing(`var'_carried)
	replace s_`var' = "ipol"     if missing(`var') & !missing(`var'_ipo)
	replace s_`var' = "carryfor" if missing(`var') &  missing(`var'_ipo)  & year > 2020 & !missing(`var'_carried)
	
	replace `var'_ipo = `var'_carried if missing(`var'_ipo) & year > 2020
	replace `var'     = `var'_ipo if missing(`var')
	drop `var'_ipo `var'_carried
}

/*
replace series_gsrhn = 9999 if missing(series_gsrhn) & series_nsrhn == 9999
replace series_gmxhn = 9999 if missing(series_gmxhn) & series_nmxhn == 9999
replace series_gsrgo = 9999 if missing(series_gsrgo) & series_nsrgo == 9999
replace series_gsrco = 9999 if missing(series_gsrco) & series_nsrco == 9999

replace series_gsrhn = 7777 if missing(series_gsrhn) & series_nsrhn == 7777
replace series_gmxhn = 7777 if missing(series_gmxhn) & series_nmxhn == 7777
replace series_gsrgo = 7777 if missing(series_gsrgo) & series_nsrgo == 7777
replace series_gsrco = 7777 if missing(series_gsrco) & series_nsrco == 7777
*/

//------------------------------------------------------------------------------
// 11. Calculate Gross-Net values
//------------------------------------------------------------------------------
// calculate gross shares
replace q_gsrco = min(3, cond(nsrco >= cfcco, q_nsrco, q_cfcco)) if missing(gsrco) & (!missing(nsrco) | !missing(cfcco))
replace q_gsrgo = min(3, cond(nsrgo >= cfcgo, q_nsrgo, q_cfcgo)) if missing(gsrgo) & (!missing(nsrgo) | !missing(cfcgo))
replace q_gmxhn = min(3, cond(nmxhn >= ccmhn, q_nmxhn, q_ccmhn)) if missing(gmxhn) & (!missing(nmxhn) | !missing(ccmhn))
replace q_gsrhn = min(3, cond(nsrhn >= ccshn, q_nsrhn, q_ccshn)) if missing(gsrhn) & (!missing(nsrhn) | !missing(ccshn))
replace s_gsrco = "nsrco,cfcco" if missing(gsrco) & (!missing(nsrco) | !missing(cfcco))
replace s_gsrgo = "nsrgo,cfcgo" if missing(gsrgo) & (!missing(nsrgo) | !missing(cfcgo))
replace s_gmxhn = "nmxhn,ccmhn" if missing(gmxhn) & (!missing(nmxhn) | !missing(ccmhn))
replace s_gsrhn = "nsrhn,ccshn" if missing(gsrhn) & (!missing(nsrhn) | !missing(ccshn))
replace gsrco = nsrco + cfcco if missing(gsrco)
replace gsrgo = nsrgo + cfcgo if missing(gsrgo)
replace gmxhn = nmxhn + ccmhn if missing(gmxhn)
replace gsrhn = nsrhn + ccshn if missing(gsrhn)

// Compute Institutional sector totals
replace q_gvago = min(3, cond(ceugo >= cfcgo,q_ceugo, q_cfcgo))   if missing(gvago) & (!missing(ceugo) | !missing(cfcgo))
quality ceuco nsrco cfcco, gen(temp1)
replace q_gvaco = temp1                                           if missing(gvaco) & (!missing(ceuco) | !missing(nsrco) | !missing(cfcco)) 
replace q_gsrhn = min(3, cond(nsrhn >= ccshn, q_nsrhn, q_ ccshn)) if missing(gsrhn) & (!missing(nsrhn) | !missing(ccshn))
quality nmxhn ccmhn ceuhn, gen(temp2)
replace q_gvmhn = temp2                                           if missing(gvmhn) & (!missing(ceuco) | !missing(ccmhn) | !missing(ceuhn))
replace q_gvahn = min(3, gsrhn >= gvmhn, q_gsrhn, q_gvmhn)        if missing(gvahn) & (!missing(gsrhn) | !missing(gvmhn))
replace s_gvago = "ceugo,cfcgo"       if missing(gvago) & (!missing(ceugo) | !missing(cfcgo))
replace s_gvaco = "ceuco,nsrco,cfcco" if missing(gvaco) & (!missing(ceuco) | !missing(cfcco) | !missing(cfcco)) 
replace s_gsrhn = "nsrhn,ccshn"       if missing(gsrhn) & (!missing(nsrhn) | !missing(ccshn)) 
replace s_gvmhn = "nmxhn,ccmhn,ceuhn" if missing(gvmhn) & (!missing(ceuco) | !missing(ccmhn) | !missing(ceuhn))
replace s_gvahn = "gsrhn,gvmhn"       if missing(gvahn) & (!missing(gsrhn) | !missing(gvmhn))
replace gvago = ceugo + cfcgo          if missing(gvago)
replace gvaco = ceuco + nsrco + cfcco  if missing(gvaco) 
replace gsrhn = nsrhn + ccshn          if missing(gsrhn)  
replace gvmhn = nmxhn + ccmhn + ceuhn  if missing(gvmhn)
replace gvahn = gsrhn + gvmhn          if missing(gvahn)
drop temp*

//------------------------------------------------------------------------------
// 12. Calculate Other Regions
//------------------------------------------------------------------------------
/*
* Exception for Soviet Union, "Other Russia" equals Russia
local vars cfcgo cfcco ceugo ceuco ceuhn nsrco nmxhn nsrhn ccmhn ccshn ptxgo confc 
preserve
	keep if iso == "RU"
	replace iso = "OA"
	keep year `vars' iso
	keep if year <= 1987 
	tempfile russia
	save `russia'
restore
* use russia pre 1980 values for "Other RUCA"
merge 1:1 year iso using `russia', update replace nogen

preserve
	keep if corecountry == 1
	keep if region2 != ""
	keep if core57 == . 
	collapse (mean) cfcgo cfcco ceugo ceuco ceuhn nsrco nmxhn nsrhn ccmhn ccshn ptxgo confc  [aw=mgdpro_pppeur], by(region2 year)
	rename region2 iso

	tempfile other_regions_1980
	save `other_regions_1980'
restore 
// Insert other region averages
merge 1:1 iso year using `other_regions_1980', update nogen

order iso region2 year gvago gvaco gvmhn gsrhn ///
ceugo gsrgo nsrgo cfcgo ///
ceuco gsrco nsrco cfcco ///
ceuhn gmxhn nmxhn ccmhn gsrhn nsrhn ccmhn
*/
sort iso year

//------------------------------------------------------------------------------
// 13. Enforce accounting identities
//------------------------------------------------------------------------------
quality ceugo ceuco ceuhn comnx, gen(temp)
replace q_comhn = temp                        if missing(comhn) & !missing(ceugo) & !missing(ceuco) & !missing(ceuhn) & !missing(comnx)
replace s_comhn = "ceugo,ceuco,ceuhn,comnx"   if missing(comhn) & !missing(ceugo) & !missing(ceuco) & !missing(ceuhn) & !missing(comnx)
replace comhn = ceugo + ceuco + ceuhn + comnx if missing(comhn)
drop temp

gen gdp = 1
enforce (gdp = gvago + gvaco + gvmhn + gsrhn + ptxgo) ///
		(gvago = ceugo + cfcgo + nsrgo) ///
		(gvaco = ceuco + cfcco + nsrco) ///
		(gvahn = ceuhn + gsmhn + ccmhn + ccshn) ///
		(gvmhn = ceuhn + nmxhn + ccmhn) ///
		(gsrhn = nsrhn + ccshn) ///
		(gmxhn = nmxhn + ccmhn) ///
		(gsrco = nsrco + cfcco) ///
		(comhn = ceugo + ceuco + ceuhn + comnx) ///
		(confc = cfcgo + cfcco + ccmhn + ccshn), ///
		fixed(confc gdp comhn) prefix(new) replace force 

drop newgdp
foreach v of varlist new* {
    local base = subinstr("`v'", "new", "", .)
	
	replace s_`base' = "enforce" if missing(`base') & !missing(`v')
    replace q_`base' = 3         if missing(`base') & !missing(`v')
    replace   `base' = `v'
}
drop new* 
	

//------------------------------------------------------------------------------
// 14. Calculate Factor Shares
* use "$work_data/sna-combined.dta", clear // to check labor shares from raw data
//------------------------------------------------------------------------------


order iso year ceugo nsrgo ceuco ceuhn gsrco gsrgo nsrco gmxhn nmxhn gsrhn nsrhn cfcgo cfcco ccmhn ccshn comnx pinnx comhn  ptxgo
gen   gvato = ceugo + nsrgo + ceuco + ceuhn + nsrco + nmxhn + nsrhn + cfcgo + cfcco + ccmhn + ccshn
quality ceugo nsrgo ceuco ceuhn nsrco nmxhn nsrhn cfcgo cfcco ccmhn ccshn, gen(q_gvato)
gen s_gvato = "ceugo,nsrgo,ceuco,ceuhn,nsrco,nmxhn,nsrhn,cfcgo,cfcco,ccmhn,ccshn" if !missing(gvato)

/*
gen ndp_fp = ceugo + nsrgo + ceuco+ ceuhn+ nsrco+ nmxhn+ nsrhn
gen gni_fp = gvato + comnx + pinnx
gen nni_fp = ndp_fp + comnx + pinnx

* Note: These varaibles are calculated in complete-variables.do
* Labor share of total (factor-price) GDP
gen lsgdp = (ceugo + ceuco + ceuhn + 0.6*gmxhn) / gvato
*Labor share of total (factor-price) NDP
gen lsndp = (ceugo + ceuco + ceuhn + 0.6*gmxhn) / ndp_fp
*Capital share of total (factor-price) GDP
gen csgdp =  (gsrco + gsrhn + gsrgo + 0.4*gmxhn) / gvato
*Capital share of total (factor-price) NDP
gen csndp =  (nsrco + nsrhn + nsrgo + (0.4*gmxhn - ccmhn)) / ndp_fp

*Labor share in corporate (factor-price) GVA
gen lscgv = ceuco / (ceuco + gsrco)
* Labor share in corporate (factor-price) NVA
gen lscnv = ceuco / (ceuco + nsrco)
*Capital share in corporate (factor-price) GVA
gen cscgv = gsrco / (ceuco + gsrco)
*Capital share in corporate (factor-price) NVA
gen cscnv = nsrco / (ceuco + nsrco)

*Labor share of total (factor-price) GNI
gen lsgni= (ceugo + ceuco + ceuhn + comnx + 0.6*gmxhn) / gni_fp
*Capital share of total (factor-price) GNI
gen  csgni =  (gsrco + gsrhn + gsrgo + pinnx + 0.4*gmxhn) / gni_fp

*/

//------------------------------------------------------------------------------
// 15. Format and export
//------------------------------------------------------------------------------
keep if corecountry==1

drop series* imputed_*
keep iso year *gvago *gvaco *gvato *gvahn *ceugo *nsrgo *ceuco *ceuhn *gsrco *nsrgo *gsrgo *nsrco *gmxhn *nmxhn *gsrhn *nsrhn *cfcgo *cfcco *ccmhn *ccshn *comnx *pinnx *comhn *ptxgo *confc /// /*lsgdp lsndp csgdp csndp lscgv lscnv cscgv cscnv lsgni lsnni csgni csnni*/
			
			
/*
tempfile inst_components
save `inst_components', replace

*merging with retropolate
u "$work_data/sna-combined.dta", clear
merge 1:1 iso year using "`inst_components'", nogen update replace
*/
label data "Generated by calculate-sector-factor-shares.do"
save "$work_data/sna-fullsector.dta", replace
