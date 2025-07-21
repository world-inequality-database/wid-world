// -----------------------------------------------------------------------------
//           Calculate Sector-Factor Shares . Do
// -----------------------------------------------------------------------------

* Objective:  Sectoral Decomposition and Factor Shares Complete Sectoral 
*             Decomomposition of GDP for 216 countries 1980-2023 and from 
*             1900-2023 for 57 core terretories.

 
// Create Globals
global all_vars confc cfcgo cfcco ceugo ceuco ceuhn nsrco nmxhn nsrhn nsrgo ccmhn ccshn /// 
gsrhn gvago gvahn gvmhn gvaco gmxhn gsrco gsrgo ptxgo 
 
global coreterritories `" "DE" "DK" "ES" "FR" "GB" "IT" "NL" "NO" "SE" "OC" "QM" "US" "CA" "AU" "NZ" "OH" "AR" "BR" "CL" "CO" "MX" "OD" "AE" "DZ" "EG" "IR" "MA" "SA" "TR" "OE" "CD" "CI" "ET" "KE" "ML" "NE" "NG" "RW" "SD" "ZA" "OJ" "RU" "OA" "CN" "JP" "KR" "TW" "OB" "BD" "IN" "ID" "MM" "PK" "PH" "TH" "VN" "OI" "' // <<<-------------

/* 
//------------------------------------------------------------------------------
// 0. Create Data files needed
//------------------------------------------------------------------------------
// Population WID
wid, indicators(npopul agdpro) areas(_all)  pop(i) ages(999) clear
rename country iso 
rename valuepopulation population
keep iso year population
save "$work_data/pop_wid_all.dta", replace

// GDP: per capita in EuroPPP WID
wid, indicators(xlceup) areas(_all)  pop(i) clear
rename country iso 
rename value xlceup999i
keep if year == 2023
drop percentile age pop variable year
save "$work_data/lcu_ppp.dta", replace

wid, indicators(agdpro) areas(_all) pop(i) ages(999) clear
rename value agdp
rename country iso
merge iso using "$work_data/lcu_ppp.dta"
gen agdpro_ppp = agdp / xlceup999i
keep iso year agdpro_ppp
keep if agdpro_ppp != .
save "$work_data/agdpro_ppp.dta", replace

// Load Historical Natinal Accounts of Sweden (Edvinsson2005)
import excel using "$project_dir/country-fix/Sweden_Edvinsson2005.xlsx", cellrange(A8:AA209) firstrow clear
save "$work_data/SE_historical_account.dta"

// Import CFC from Bengston Waldenström
use "$project_dir/country-fix/BW_capitalsharedatabase_gross_net.dta", clear
rename Year year
countrycode Country, generate(iso) from("wb")
gen confc_BW =  Depreciationrate /100
gen confc_source = "BW"
replace confc_BW = . if confc_BW == 0 | confc_BW < 0
keep iso year confc_BW confc_source
drop if iso == "IT" | iso == "CA" |  iso == "BR" | iso == "FR" | iso == "GB" | iso == "AR"
save "$input_data_dir/BW_Historical_Factor_Share_Database.dta", replace

// Import series for Thailand
use "$project_dir/country-fix/TH_1960-2021.dta", clear
gen iso = "TH"
merge 1:1 iso year using "$work_data\cfc-full-imputation.dta"
keep if iso == "TH" & year >= 1960 & year <= 2021

gen ptxgo_nni = (nni_mp - nni_fp) / nni_mp
gen comhn_nni = hh_linc / nni_mp
gen nmxhn_nni = hh_minc / nni_mp
gen nsrhn_nni = imputedrent / nni_mp
gen nsrco_nni = (hh_kinc - imputedrent + corp_inc + gov_inc)  / nni_mp

* calculate as share of GDP
foreach var in ptxgo comhn nmxhn nsrhn nsrco {
	gen `var' = `var'_nni * (1-imputed_confc)
	gen series_`var' = 200000
}
keep comhn nmxhn nsrhn nsrco iso year ptxgo series*
save "$project_dir/country-fix/TH_hisorical_national_accounts.dta", replace

* China Import China National Accounts from PYZ 2017 
import excel using "$project_dir/country-fix/CN_PYZ2017.xlsx", cellrange(A7:V45) clear firstrow
drop *2 comhn
save "$project_dir/country-fix/CN_PYZ2017.dta", replace

* RU: Russia
*---Use data from Piketty-Novokmet-Zucman including the Assumtion to keep 1980 sectoral shares constat until 1913, because very little self-employment
import excel using "$project_dir/country-fix/NPZ2017Appendix.xlsx", sheet("RU") cellrange(A7:AA223) clear firstrow
drop X W Y
save "$project_dir/country-fix/NPZ2017.dta", replace


### Import Values for Historical Imputation
import excel "C:\Users\Lenovo\Dropbox\Piketty2025GlobalJusticeProjectSectors\Dietrichetal2025sectors.xlsx", sheet(A6a) cellrange(A5:U8) firstrow clear
rename * *_world
replace gdp_range_historic_world = "0_3000" if gdp_range_historic_world  == "0€ to 3000€"
replace gdp_range_historic_world = "3000_6000" if gdp_range_historic_world  == "3000€ to 6000€"
replace gdp_range_historic_world = "6000_10000" if gdp_range_historic_world  == "6000€ to 10000€"
gen historical_imp = "A6a"

tempfile A15a
save `A15a', replace

import excel "C:\Users\Lenovo\Dropbox\Piketty2025GlobalJusticeProjectSectors\Dietrichetal2025sectors.xlsx", sheet(A6b) cellrange(A5:U8) firstrow clear
rename * *_world
replace gdp_range_historic_world = "0_3000" if gdp_range_historic_world  == "0€ to 3000€"
replace gdp_range_historic_world = "3000_6000" if gdp_range_historic_world  == "3000€ to 6000€"
replace gdp_range_historic_world = "6000_10000" if gdp_range_historic_world  == "6000€ to 10000€"
gen historical_imp = "A6b"
append using `A15a'

save "$work_data/gdp_range_assumptions_world.dta", replace


*/


//------------------------------------------------------------------------------
// 1. Merge all series
//------------------------------------------------------------------------------

// Population series, GDP  and GDP PPP -EUR
*use "$work_data/populations.dta", clear
*keep if widcode=="npopul999i"
*keep iso year value p
*rename value npopul

*merge 1:1 iso year using "$work_data/retropolate-gdp.dta", nogenerate keepusing(gdp)
use  "$work_data/retropolate-gdp.dta", clear
keep iso year gdp
rename gdp mgdpro_lcu

preserve
	use  "$work_data/ppp.dta", clear
	merge m:1 year using  "$work_data/ppp_ea_cn_weithgted.dta", nogen
	generate xlceup = ppp/ppp_ea
	keep iso year xlceup
	tempfile ppp
	save `ppp'
restore
merge 1:1 iso year using "`ppp'", nogenerate

gen mgdpro_pppeur = (mgdpro_lcu)/xlceup

// Load SNA Data (UN, OECD and WITD) and Bachas and PZ2017
merge  1:1 iso year using "$work_data/sna-combined-prefki.dta", nogen
drop flag*

// Merge WID regions
merge m:1 iso using "$work_data/import-country-codes-output.dta", nogen keepusing(region1 region2)


// Merge WIL imputed CFC Data
merge 1:1 iso year using "$work_data/cfc-full-imputation.dta", nogen

// Merge historical CFC data from Bengtsson Waldenström
*merge 1:1 iso year using "$work_data/BW_Historical_Factor_Share_Database.dta", nogen

gen core57 = .
foreach country of global coreterritories {
    replace core57 = 1 if iso == `"`country'"' // <<<-----------------------------------
}

order iso year ptxgo confc comhn comnx ceugo ceuhn ceuco gsrhn gsrco gmxhn nmxhn cfcgo cfchn cfcco ccmhn ccshn


//------------------------------------------------------------------------------
// 2. Country Data Fixes
//------------------------------------------------------------------------------

* no negative or zero vars for gross surplus and cfc (remove case by case later)
foreach v of varlist gsr*  gmx*  comhn ceu* cfc* ccm* ccs* {
	replace `v' = . if `v' <= 0
}

*  set CFC lowest value after 1980 ot  0.05
replace confc = 0.05 if confc < 0.05 & year >= 1980
*  set CFC lowest cfc value from 1950-1980 to 0.04
replace confc = 0.04 if confc < 0.04 & year >= 1950


*NZ:New Zealand: 
*Does not report mixed income seperately (report it in corporation(see WID  Issue Brief 2020-07))
* take Australian mixed income and deduct from New Zealand replace by Australian mixed income and deduct from corporation share
preserve
keep if iso == "AU"
keep iso year nmxhn gmxhn ccmhn
replace iso = "NZ"
tempfile AU_for_NZ
save `AU_for_NZ'
restore 
merge 1:1 iso year using `AU_for_NZ', update nogen
*deduct from operating surplus
replace nsrco = nsrco - nmxhn if iso == "NZ"
replace gsrco = gsrco - gmxhn if iso == "NZ"


* China: 
* Wages paid by the household sector are very large (15-20%)
* item refers rater to total mixed income including wages paid by households (mixed income is missing)
* Assume 10 % wages paid by households
replace gmxhn = ceuhn * 0.9 if iso == "CN"
replace comhn = comhn - ceuhn * 0.9 if iso == "CN"
replace ceuhn = 0.1 * ceuhn if iso == "CN" & year >= 1992
*Use China National Accounts from PYZ 2017 (1992-2014)
merge 1:1 iso year using "$work_data/CN_PYZ2017.dta" , update replace nogen



* RU: Russia
*---Use data from Piketty-Novokmet-Zucman including the Assumtion to keep 1980 sectoral shares constat until 1913, because very little self-employment
* use values from Russian National accounts from 1980 to 2014, delete UN data
foreach var in cfcgo cfcco ceugo ceuco ceuhn nsrco nmxhn nsrhn ccmhn ccshn ptxgo confc comhn  {
	replace `var' = . if iso == "RU" & year >= 1900 & year <=2015
}
merge 1:1 iso year using "$work_data/NPZ2017.dta", nogen update replace


* Exception for Former Soviet Countries
local vars cfcgo cfcco ceugo ceuco ceuhn nsrco nmxhn nsrhn ccmhn ccshn ptxgo confc 
preserve
keep if iso == "RU"
replace region4 = "Other Russia & Central Asia"
keep year `vars' region4
keep if year <= 1987 & year >= 1980
tempfile russia
save `russia'
restore
* use russia pre 1980 values for all countries in RUCA
merge m:1 year region4 using `russia', update replace nogen



* SE: Sweden
merge 1:1 iso year using "$work_data/SE_historical_account.dta", update nogen

*TH: Thailand: use historical sources from Marc
preserve
	// Import series for Thailand
	use "$project_dir/country-fix/TH_1960-2021.dta", clear
	gen iso = "TH"
	merge 1:1 iso year using "$work_data\cfc-full-imputation.dta"
	keep if iso == "TH" & year >= 1960 & year <= 2021

	gen ptxgo_nni = (nni_mp - nni_fp) / nni_mp
	gen comhn_nni = hh_linc / nni_mp
	gen nmxhn_nni = hh_minc / nni_mp
	gen nsrhn_nni = imputedrent / nni_mp
	gen nsrco_nni = (hh_kinc - imputedrent + corp_inc + gov_inc)  / nni_mp

	* calculate as share of GDP
	foreach var in ptxgo comhn nmxhn nsrhn nsrco {
		gen `var' = `var'_nni * (1-imputed_confc)
		gen series_`var' = 200000
	}
	keep comhn nmxhn nsrhn nsrco iso year ptxgo series*
	
	tempfile TH_hisorical_na.dta
	save `TH_hisorical_na.dta'
restore
merge 1:1 iso year using "`TH_hisorical_na.dta'", update replace nogen


// SA: Saudi Arabia:
* --- unreaslistic 0 mixed income, use data from offical puplication
/*import excel "~/Documents/GitHub/WIL_sector_output\WIL_GitHub\data-input/SA_national_accounts.xlsx", sheet("SA")  cellrange(A7:AA30) firstrow clear
drop X W Y
drop gsrhn nsrhn ccshn
save "$work_data/country_fix_SA.dta", replace 
*/
replace gmxhn = . if iso == "SA" & year >= 2002 & year <= 2009
replace gvahn = . if iso == "SA" & year >= 2002 & year <= 2009
// From 2002 to 2009 mixed income and operating surplus of HH is 0
// we assume that both is included in corporation profits
// we use the average of the years with data avaibility (2013 to 2015) to split corporate profits
// Net mixed income share of total operating surplus (incl. mixed income): 14 %
// Net OS of housholds of total operating surplus (incl. mixed income): 7 %
replace nmxhn = 0.14 * nsrco if iso == "SA" 
replace gmxhn = . if iso == "SA" 
replace nsrhn = 0.07 * nsrco if iso == "SA" 
replace nsrco = nsrco - nsrhn - nmxhn if iso == "SA" 
replace gsrco = gsrco - nsrhn - nmxhn if iso == "SA"
merge 1:1 iso year using "$work_data/country_fix_SA.dta", nogen update replace
replace gsrhn = . if iso == "SA" 


//------------------------------------------------------------------------------
// 3. Use other data sources if missing
//------------------------------------------------------------------------------

// use BW CFC values for selected countries
replace confc = confc_BW if missing(confc) & iso == "DE" | iso == "ES"  | iso == "JP"  | iso == "NL"  | iso == "NO" ///
| iso == "NZ" | (iso == "AU" & year != 1941 & year != 1942) | iso == "FI"  | ( iso == "US" & year >1920) ///
| iso == "AT"  | iso == "BE" | iso == "DK"

// ---------- LOOP for using Imputed CFC data
local imputedvars "confc cfcgo cfchn cfcco ccshn ccmhn"
foreach var in `imputedvars' {
    local impvar = "imputed_`var'"
*	replace series_`var' = 8888 if missing(`var') & !missing(`impvar')
    replace `var' = `impvar' if missing(`var') & !missing(`impvar')
}

// following the method in impute-confc.do
replace ccshn = cfchn*nsrhn/(nsrhn + 0.3*nmxhn)     if missing(ccshn)
replace ccmhn = cfchn*0.3*nmxhn/(nsrhn + 0.3*nmxhn) if missing(ccmhn)

//------------------------------------------------------------------------------
// 4. Logical Splits
//------------------------------------------------------------------------------

* Logical splits (gross-net)
// Complete gross / net values
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

// By convention nsrgo == 0
replace nsrgo = 0 if missing(nsrgo)
replace gsrgo = cfcgo if missing(gsrgo)
replace gsmhn = gmxhn + gsrhn if missing(gsmhn)

// Logical splits Compensation of employees
replace comnx = comrx - compx if missing(comnx)
replace ceuco = comhn - comnx - ceugo - ceuhn if missing(ceuco)
replace ceuco = . if ceuco < 0
replace ceugo = comhn - comnx - ceuhn - ceuco if missing(ceugo) & iso != "GB"
replace ceugo = . if ceugo < 0
replace ceuhn = comhn - comnx - ceugo - ceuco if missing(ceuhn)
replace ceuhn = . if ceuhn < 0

//-----------------------------------------------------------------------------
// 5. Distribute compensation of employees between corporations and households if we have goverment wages payed
//    wages paid by households are anyways allways very small (<<5%)
//-----------------------------------------------------------------------------
gen ceu_priv = comhn - comnx - ceugo

// Assume zero net foreighn labour income if missing (comnx = 0)
replace ceu_priv = comhn - ceugo if missing(ceu_priv)
replace ceu_priv = . if ceu_priv < 0

// 5.1 If possible use last data share available
gen valid_year = !missing(ceu_priv) & !missing(ceuco)  & !missing(ceuhn) 
bysort iso (year): egen oldest_valid_year = min(year) if valid_year
gen ceuhn_share = .
replace ceuhn_share = ceuhn / (ceuhn + ceuco) if year == oldest_valid_year
gsort iso - year
by iso: replace ceuhn_share = ceuhn_share[_n-1] if missing(ceuhn_share)
gsort iso year
by iso: replace ceuhn_share = ceuhn_share[_n-1] if missing(ceuhn_share) 
replace ceuhn = ceuhn_share * ceu_priv if missing(ceuhn)
replace ceuco = ceu_priv - ceuhn if missing(ceuco)
drop valid_year ceuhn_share oldest_valid_year valid_year

// 5.2 Use the share of Mixen income and Firm profits as proxy
gen gmx_share = gmxhn / (gmxhn + gsrco)
replace ceuhn = ceu_priv * (0.3 * gmx_share) if missing(ceuhn)
replace ceuco = ceu_priv - ceuhn if missing(ceuco)
drop ceu_priv gmx_share

//------------------------------------------------------------------------------
// 6. Intrapolate all values linearly between gabs and carryforeward last observation
//------------------------------------------------------------------------------

* Sort the data by iso and year
sort iso year

* List of variables to process
local vars confc cfcgo cfcco ceugo ceuco ceuhn nsrco nmxhn nsrhn ccmhn ccshn ///
gsrhn gmxhn comhn ptxgo mgdpro_ppp

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
    replace `var' = `var'_interp if `var'_is_interp == 1
    replace `var' = `var'_carried if `var'_is_carried == 1
	drop `var'_carried `var'_interp
}

* do logical splits again
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
// 7. calcluate aggreate sectoral value added which we base the imputation on 
//------------------------------------------------------------------------------

* Compute Institutional sector totals
replace gvago = ceugo + cfcgo  
replace gvaco = ceuco + nsrco + cfcco  
replace gsrhn = nsrhn +  ccshn       // GVA operating surplus (Housing)
replace gvmhn = nmxhn + ccmhn + ceuhn 		// GVA Mixed income = Self-employment + compensation of emplyees
replace gvahn = gsrhn + gvmhn

* Use gva by sector from national accounts at basic prices. 
* To have value added at factor-price we have to deduct "other net taxes on production"
replace gvago = gvbgo - tspgo if missing(gvago)
replace gvaco = gvbco - tspco if missing(gvaco)
replace gvahn = gvbhn - tsphn if missing(gvahn)

* This ignores the inconsistency that "other taxes and production" are included in the gvb variable and again in ptxgo, however very small
replace gvago = gvbgo if missing(gvago)
replace gvaco = gvbco if missing(gvaco)
replace gvahn = gvbhn if missing(gvahn)

* Create GDP per capita ranges
gen gdp_range = cond(agdpro_ppp >= 0 & agdpro_ppp < 2500, "0_2500", ///
                  cond(agdpro_ppp >= 2500 & agdpro_ppp < 5000, "2500_5000", ///
                  cond(agdpro_ppp >= 5000 & agdpro_ppp < 10000, "5000_10000", ///
                  cond(agdpro_ppp >= 10000 & agdpro_ppp < 25000, "10000_25000", ///
                  "above_25000"))))

save "$work_data/NDP_institutions_before_imputation.dta", replace


//------------------------------------------------------------------------------
// 8. Impute sector until 1980 based on regional GDP per capita for 216 countries  
//------------------------------------------------------------------------------
use "$work_data/NDP_institutions_before_imputation.dta", clear

* In RUCA we use post 1990 variables, before we assumed that they follow Russia
drop if region5 == "Russia & Central Asia" & year < 1990

* Calcualte regional averages based on gdp per capita
keep if corecountry == 1 & year >= 1950 & agdpro_ppp != .

* Collapse data by region and GDP range 
collapse (median) confc ptxgo gvago gvaco gvmhn gsrhn agdpro_ppp ///
         (count) obs_count = gvago country_year_count = year, by(region5 gdp_range)
		 

fillin region5 gdp_range
keep gvago gvaco gvmhn gsrhn gdp_range region5 confc ptxgo country_year_count

* sort the vars propperly
gen gdp_numeric = real(substr(gdp_range, 1, strpos(gdp_range, "_") - 1))
replace gdp_numeric = 25000 if gdp_range == "above_25000"
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

save "$work_data/GDP_ranges_shares_six.dta", replace

//------------------------------------------------------------------------------
// 9. Split imputed sectoral shares to single components
//        - if available use the oldest share available
//        - if not use the regional average share
//------------------------------------------------------------------------------
* Merge and replace imputed sectoral gdp shares
use "$work_data/NDP_institutions_before_imputation.dta", clear
merge m:1 region5 gdp_range using "$work_data/GDP_ranges_shares_six.dta"
drop if _merge == 2
drop _merge
sort iso year
foreach var of varlist gvago5 gvaco5 gvmhn5 gsrhn5 ptxgo5 confc5{
    replace `var' = . if year < 1980
	replace `var' = . if corecountry != 1
}

// Create suffix _5 variables for all subcumponents for imputed values
gen ceugo5 = .
gen nsrgo5 = .
gen ceuco5 = .
gen ceuhn5 = .
gen nsrco5 = .
gen nmxhn5 = .
gen nsrhn5 = .
gen cfcgo5 = .
gen cfcco5 = .
gen ccmhn5 = .
gen ccshn5 = .
gen gsrco5 = .

///////////  Governement
replace ceugo5 = gvago5 - cfcgo


/////////// Corporations (gvaco)
* Step 1: Calculate shares for each country
gen valid_year = !missing(ceuco) & !missing(nsrco) & !missing(cfcco)
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
collapse (median) ceuco_share cfcco_share nsrco_share, by(region5)
rename ceuco_share ceuco_share_region
rename cfcco_share cfcco_share_region
rename nsrco_share nsrco_share_region
tempfile region_shares
save `region_shares'
restore

* Step 3: Merge regional averages back into the main dataset
merge m:1 region5 using `region_shares', nogen

* Step 4: Replace missing shares with regional averages
replace ceuco_share = ceuco_share_region if missing(ceuco_share)
replace cfcco_share = cfcco_share_region if missing(cfcco_share)
replace nsrco_share = nsrco_share_region if missing(nsrco_share)

* Step 5: Recompute imputed values
replace ceuco5 = ceuco_share * gvaco5 if missing(ceuco) & missing(ceuco5) 
replace cfcco5 = cfcco_share * gvaco5 if missing(cfcco) & missing(cfcco5) 
replace nsrco5 = nsrco_share * gvaco5 if missing(nsrco) & missing(nsrco5) 

drop valid_year ceuco_share cfcco_share nsrco_share oldest_valid_year ceuco_share_region cfcco_share_region nsrco_share_region

/////////// Households Mixed Income (gvmhn)
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
collapse (median) ceuhn_share nmxhn_share ccmhn_share, by(region5)
rename ceuhn_share ceuhn_share_region
rename nmxhn_share nmxhn_share_region
rename ccmhn_share ccmhn_share_region
tempfile region_shares_hm
save `region_shares_hm'
restore

* Merge regional averages back into the main dataset
merge m:1 region5 using `region_shares_hm', nogen

* Replace missing shares with regional averages
replace ceuhn_share = ceuhn_share_region if missing(ceuhn_share)
replace nmxhn_share = nmxhn_share_region if missing(nmxhn_share)
replace ccmhn_share = ccmhn_share_region if missing(ccmhn_share)

* Recompute imputed values
replace ceuhn5 = ceuhn_share * gvmhn5 if missing(ceuhn) & missing(ceuhn5)
replace ccmhn5 = ccmhn_share * gvmhn5 if missing(ccmhn) & missing(ccmhn5)
replace nmxhn5 = nmxhn_share * gvmhn5 if missing(nmxhn) & missing(nmxhn5)

drop valid_year ceuhn_share nmxhn_share ccmhn_share oldest_valid_year ceuhn_share_region nmxhn_share_region ccmhn_share_region

/////////// Households Housing (gsrhn)
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
collapse (median) nsrhn_share ccshn_share, by(region5)
rename nsrhn_share nsrhn_share_region
rename ccshn_share ccshn_share_region
tempfile region_shares_hh
save `region_shares_hh'
restore

* Merge regional averages back into the main dataset
merge m:1 region5 using `region_shares_hh', nogen

* Replace missing shares with regional averages
replace nsrhn_share = nsrhn_share_region if missing(nsrhn_share)
replace ccshn_share = ccshn_share_region if missing(ccshn_share)

* Recompute imputed values
replace nsrhn5 = nsrhn_share * gsrhn5 if missing(nsrhn) & missing(nsrhn5)
replace ccshn5 = ccshn_share * gsrhn5 if missing(ccshn) & missing(ccshn5)

drop valid_year nsrhn_share ccshn_share oldest_valid_year nsrhn_share_region ccshn_share_region

//------------------------------------------------------------------------------
// 10. replace imputed components if missing, create imputed indicator
//------------------------------------------------------------------------------

* List of variables to process
local vars cfcgo cfcco ceugo ceuco ceuhn nsrco nmxhn nsrhn ccmhn ccshn ptxgo confc 
sort iso year
* Loop through each variable
foreach var in `vars' {
    replace series_`var' = 9999 if missing(`var') & !missing(`var'5)
    replace `var' = `var'5 if missing(`var') & !missing(`var'5) & (year == 1970 | year == 1980 | year == 1990 | year == 2000 | year == 2010 | year == 2020)
	bysort iso (year): ipolate `var' year, generate(`var'_ipo)
	bysort iso (year): carryforward `var'_ipo, gen(`var'_carried)
	replace `var'_ipo = `var'_carried if missing(`var'_ipo) & year > 2020
	replace `var' = `var'_ipo if missing(`var')
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
replace gsrco = nsrco + cfcco if missing(gsrco)
replace gsrgo = nsrgo + cfcgo if missing(gsrgo)
replace gmxhn = nmxhn + ccmhn if missing(gmxhn)
replace gsrhn = nsrhn + ccshn if missing(gsrhn)

// Compute Institutional sector totals
replace gvago = ceugo + cfcgo  if missing(gvago)
replace gvaco = ceuco + nsrco + cfcco  if missing(gvaco) 
replace gsrhn = nsrhn +  ccshn  if missing(gsrhn)  
replace gvmhn = nmxhn + ccmhn + ceuhn  if missing(gvmhn)
replace gvahn = gsrhn + gvmhn if missing(gvahn)

//------------------------------------------------------------------------------
// 12. Calculate Other Regions
//------------------------------------------------------------------------------
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

tempfile other_regions_1980
preserve
keep if corecountry == 1
keep if region4 != ""
keep if core57 == . 
collapse (mean) cfcgo cfcco ceugo ceuco ceuhn nsrco nmxhn nsrhn ccmhn ccshn ptxgo confc  [aw=mgdpro_ppp], by(region4 year)
gen iso = ""
replace iso = "QM" if region4 == "Other Eastern Europe"
replace iso = "OC" if region4 == "Other Western Europe"
replace iso = "OH" if region4 == "Other North America & Oceania"
replace iso = "OD" if region4 == "Other Latin America"
replace iso = "OE" if region4 == "Other MENA"
replace iso = "OJ" if region4 == "Other Sub-Saharan Africa"
replace iso = "OA" if region4 == "Other Russia & Central Asia"
replace iso = "OB" if region4 == "Other East Asia"
replace iso = "OI" if region4 == "Other South & South-East Asia"

save `other_regions_1980'
restore 
// Insert other region averages
merge 1:1 iso year using `other_regions_1980', update nogen

order iso shortname region5 year gvago gvaco gvmhn gsrhn ///
ceugo gsrgo nsrgo cfcgo ///
ceuco gsrco nsrco cfcco ///
ceuhn gmxhn nmxhn ccmhn gsrhn nsrhn ccmhn
sort iso year
save "$work_data/NDP_institutions_1980_216.dta", replace


//------------------------------------------------------------------------------
// ########## Begin Historical Part for 57 terretories until 1900 #############
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// 13. Use imputed values pre- 1950 for core 57
//------------------------------------------------------------------------------
use "$work_data/NDP_institutions_1980_216.dta", clear

gsort iso - year
foreach var in  $all_vars {	
    by iso: carryforward `var' ,  gen(`var'_backwards)
}

gen gdp_range_historic_world = cond(agdpro_ppp >= 0 & agdpro_ppp < 3000, "0_3000", ///
                  cond(agdpro_ppp >= 3000 & agdpro_ppp < 6000, "3000_6000", ///
				   cond(agdpro_ppp >= 6000 & agdpro_ppp < 10000, "6000_10000", "above_10000")))
	
gen historical_imp = ""
replace historical_imp = "A6a" if region5 == "Europe" | region5 == "North America & Oceania" | region5 == "East Asia"
replace historical_imp = "A6b" if region5 == "Latin America" | region5 == "MENA" | region5 == "South & South-East Asia" | region5 == "Sub-Saharan Africa"
				  

merge m:m gdp_range_historic_world historical_imp using "$work_data/gdp_range_assumptions_world.dta", update
local vars cfcgo cfcco ceugo ceuco ceuhn nsrco nmxhn nsrhn ccmhn ccshn ptxgo confc
foreach var in  `vars'{
	*Keep US 1929 values stable for 1900
	replace `var' = `var'_backwards if (year == 1930 | year == 1900) & iso == "US"
    replace `var' = `var'_world if (year == 1930 | year == 1900) & core57 == 1 & missing( `var') 
	 bysort iso (year): ipolate `var' year, gen(`var'_interp)
	 replace `var' = `var'_interp
}
// calculate gross shares
replace gsrco = nsrco + cfcco if missing(gsrco)
replace gsrgo = nsrgo + cfcgo if missing(gsrgo)
replace gsrgo = cfcgo if missing(gsrgo)
replace gmxhn = nmxhn + ccmhn if missing(gmxhn)
replace gsrhn = nsrhn + ccshn if missing(gsrhn)

replace nsrco = gsrco - cfcco if missing(nsrco)
replace nmxhn = gmxhn - ccmhn if missing(nmxhn)

// Compute Institutional sector totals
replace gvago = ceugo + cfcgo  if missing(gvago)
replace gvaco = ceuco + nsrco + cfcco  if missing(gvaco) 
replace gsrhn = nsrhn +  ccshn  if missing(gsrhn)      // GVA operating surplus (Housing)
replace gvmhn = nmxhn + ccmhn + ceuhn  if missing(gvmhn)		// GVA Mixed income = Self-employment + compensation of emplyees
replace gvahn = gsrhn + gvmhn if missing(gvahn)
save "$work_data/NDP_institutions_1900.dta", replace


//------------------------------------------------------------------------------
// 14. Impute CFC to 1800
//------------------------------------------------------------------------------
use "$work_data/NDP_institutions_1900.dta", clear
// Countries that have observed historical data that is lower than 1800 value carry backwards this lower value
gsort iso - year
by iso: carryforward confc,  gen(confc_back)

replace confc = 0.06 if (year == 1880 | year == 1800) &  missing(confc) & (region5 == "Europe" ) & core57 == 1

replace confc = 0.05 if (year == 1880 | year == 1800) &  missing(confc) & ///
(region5 == "North America & Oceania" | region5 == "East Asia" |  ///
 region5 == "Russia & Central Asia" | region5 == "Latin America" ) & core57 == 1

replace confc = 0.04 if (year == 1880 | year == 1800)  &  missing(confc) & ///
(region5 == "MENA" | region5 == "Sub-Saharan Africa" | ///  
region5 == "South & South-East Asia") & core57 == 1

replace confc = confc_back if confc_back < confc & core57 == 1 & (year == 1800 | year == 1880)

bysort iso (year): ipolate confc year, gen(confc_interp_hist)
replace confc = confc_interp_hist if year <=1900 & missing(confc)


//------------------------------------------------------------------------------
// 15. Enfore accounting identities
//------------------------------------------------------------------------------
replace comhn = ceugo + ceuco + ceuhn + comnx if missing(comhn)
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
		fixed(confc gdp comhn) replace force 

//------------------------------------------------------------------------------
// 16. Create regional and world averages
//------------------------------------------------------------------------------
/*
// Region 5 Average 
preserve
keep  if core57 == 1
collapse (mean) $all_vars [aw=mgdpro_ppp], by(region5 year)
gen iso = ""
replace iso = "QE" if region5 == "Europe"
replace iso = "XB" if region5 == "North America & Oceania"
replace iso = "XL" if region5 == "Latin America"
replace iso = "XN" if region5 == "MENA"
replace iso = "XF" if region5 == "Sub-Saharan Africa"
replace iso = "XR" if region5 == "Russia & Central Asia"
replace iso = "QL" if region5 == "East Asia"
replace iso = "XS" if region5 == "South & South-East Asia"
drop if iso == ""
tempfile regional
save `regional', replace
restore

// World Average 
preserve
keep if core57 == 1
collapse (mean) $all_vars [aw=mgdpro_ppp], by(year)
gen iso = "WO"
tempfile world
save `world', replace
restore

// Merge final file
merge 1:1 iso year using `regional', nogen update
merge 1:1 iso year using  `world', nogen update
*/

//------------------------------------------------------------------------------
// 17. Calculate Factor Shares
* use "$work_data/sna-combined.dta", clear // to check labor shares from raw data
//------------------------------------------------------------------------------
order iso year ceugo nsrgo ceuco ceuhn gsrco gsrgo nsrco gmxhn nmxhn gsrhn nsrhn cfcgo cfcco ccmhn ccshn comnx pinnx comhn  ptxgo

gen gvato = ceugo + nsrgo + ceuco+ ceuhn+ nsrco+ nmxhn+ nsrhn+ cfcgo+ cfcco+ ccmhn+ ccshn
gen ndp_fp = ceugo + nsrgo + ceuco+ ceuhn+ nsrco+ nmxhn+ nsrhn
gen gni_fp = gvato + comnx + pinnx
gen nni_fp = ndp_fp + comnx + pinnx

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
*Labor share of total (factor-price) NNI
gen  lsnni= (ceugo + ceuco + ceuhn + comnx + 0.6*gmxhn) / nni_fp
*Capital share of total (factor-price) GNI
gen  csgni =  (gsrco + gsrhn + gsrgo + pinnx + 0.4*gmxhn) / gni_fp
*Capital share of total (factor-price) NNI
gen  csnni =  (nsrco + nsrhn + nsrgo + pinnx + (0.4*gmxhn - ccmhn)) / nni_fp

keep iso year gvago gvaco gvahn ceugo nsrgo ceuco ceuhn gsrco nsrgo gsrgo nsrco gmxhn nmxhn gsrhn nsrhn cfcgo cfcco ccmhn ccshn comnx pinnx comhn ptxgo confc lsgdp lsndp csgdp csndp lscgv lscnv cscgv cscnv lsgni lsnni csgni csnni
save "$work_data/NDP_institutions_components.dta", replace

*merging with retropolate
u "$work_data/sna-combined.dta", clear
merge 1:1 iso year using "$work_data/NDP_institutions_components.dta", nogen update replace
save "$work_data/sna-combined-fullsector.dta", replace
