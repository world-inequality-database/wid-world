
// =============================================================================
// 								IMPORT ALL FILES
// =============================================================================

// Objective: This file adds all new data provided by researchers to WID, 
// pre-cleaned in their respective folders.

// Latest modifications: A. Van Der Ree, 23 Oct 2025

//--------------------- INDEX ------------------------------------------------//
//       1. Import series that are not regularly updated
//            1.1. Import fiinc series
//            1.2. Import other series
//            1.3. Import series that include wealth aggregates
//            1.4. Dropping wealth aggregates 
//       2. Import updated ptinc series
//       	  2.1. Save researchers data (tempfile)
//       3. Import meta data
//       	  3.1. Dropping wealth aggregates
// 		 4. Final cleaning & pulling old data
// 		 	  4.1 Add data to WID
// 		 	  4.2 Add meta data to WID

//----------------------------------------------------------------------------//

// -----------------------------------------------------------------------------
// ----------- 1. Import series that are not regularly updated  ----------------
// -----------------------------------------------------------------------------

// ===================== 1.1. Import fiinc series ==============================

// Poland 2017 (Novokmet2017) - fiinc series
use using "$wid_dir/Country-Updates/Poland/2021_July/poland_fiinc_novokmet2017.dta", clear

// Germany 2017 (Bartles2017 & update 2021) - fiinc series
append using "$wid_dir/Country-Updates/Germany/2021_August/germany-fiinc-Aug2021.dta"

// Czech Republic 2018 (Novokmet2018) - fiinc series
append using "$wid_dir/Country-Updates/Czech_Republic/2018/March/czech-novokmet2018.dta"

// Bulgaria 2018 (Novokmet2018) - fiinc series
append using "$wid_dir/Country-Updates/Bulgaria/2018/March/bulgaria-novokmet2018.dta"
tab iso 
// Slovenia and Croatia 2018 (Novokmet 2018) - fiinc series
append using "$wid_dir/Country-Updates/Croatia/2018/April/croatia_slovenia-novokmet2018.dta"

// Belgium 2019 (Decoster2019) - fiinc series
append using "$wid_dir/Country-Updates/Belgium/2019_02/belgium-decoster2019.dta" 

// Norway - fiinc series
append using "$wid_dir/Country-Updates/Norway/2021_August/Norway_fiscal2021.dta"

// Greece 2019 (chrissis2019&Kout2021) - fiinc series
append using "$wid_dir/Country-Updates/Greece/2021_August/greece-fiinc-2021.dta"
// 8 observations have missing value & year for Greece (2019 observations)
drop if missing(value) & iso == "GR"

// Brazil 2017 (Morgan2017) - fiinc series
append using "$wid_dir/Country-Updates/Brazil/2018_January/BR_fiinc_Jan2018.dta"

// Chile 2018 (Flores2018) - fiinc series
append using "$wid_dir/Country-Updates/Chile/2018_October/chile-flores2018.dta"

// French Colonies [Cameroon, Algeria, Tunisia, Vietnam] (ACP2020) - fiinc series
append using "$wid_dir/Country-Updates/French_Colonies/french_colonies.dta"

// US States (frank2021 & update 2021) - fiinc series
append using "$wid_dir/Country-Updates/US_states/2021_April/us-states-Apr2021.dta"

// Ivory Coast 2017 (Czajka2017 + update 2020) - fiinc series 
append using "$wid_dir/Country-Updates/Ivory_Coast/2022/ivory_coast_2022.dta"
// ptinc series from this file is redundant as it has been more recently updated in Section 2 (Africa file)
drop if iso == "CI" & author == "czajka2017+update" & strpos(widcode, "ptinc")

// Netherlands 2019 (Salverda2019) - fiinc series
append using "$wid_dir/Country-Updates/Netherlands/2019_05/netherlands-salverda2019.dta"
drop if widcode == "inyixx999i" & iso == "NL"

// UK 2021 (alvaredo2017&AST2021) -  fiinc series 
append using "$wid_dir/Country-Updates/UK/2021_August/UK-fiinc-Aug2021.dta"

// --------------------- New addition 22 Oct 2025: -----------------------------

// Asia 2025 [Korea, Japan]  - fiinc series 
append using "$wid_dir/Country-Updates/Asia/2025/asia-fiinc-2025.dta"

assert !missing(iso, year, widcode)
isid iso year p widcode

// ========================= 1.2. Import other series  =========================
// Notes: 
// 		"macro series" = do not vary by percentile (eg. nninc, inyixx)
// 		"distributional series" = vary by percentile (eg. fiinc, hweal)

// Netherlands 2022 (Tousaint 2022) - macro series (inyixx, nninc, taxma)
append using "$wid_dir/Country-Updates/Netherlands/2022_11/netherlands-tousaint2022.dta"

// UK 2017 (Alvaredo2017) -  distributional series (only ahweal, shweal)
append using "$wid_dir/Country-Updates/UK/2017/June/uk-wealth-alvaredo2017.dta"

// Hungary 2017 (Mosberger2017) 
// 				- macro series (gdpro, popul, taxad, cpixx)
// 				- & distributional series (fiinc)
append using "$wid_dir/Country-Updates/Hungary/2017/September/hungary-mosberger2017.dta"

// France 2018 (Goupille2018) - Gender series
append using "$wid_dir/Country-Updates/France/2018/January/france-goupille2018-gender.dta"

// India 2018 (Bharti2018) -  distributional series (ahweal, bhweal, shweal, thweal)
append using "$wid_dir/Country-Updates/India/2018/November/india-bharti2018.dta"
drop if widcode=="bhweal992j" & iso=="IN" // reconstructed in calc-pareto-ceof

assert !missing(iso, year, widcode)
isid iso year p widcode, missok 

//================ 1.3. Import series that include wealth aggregates ===========

// -----------------------------------------------------------------------------
// Note - 23 Oct 2025: 
// 		to lighten the file, we are dropping macro wealth aggregates from the 
// 		files below. Any previous files added do not contain macro wealth aggs. 
// 		We are dropping them because they are redudant here, since we import  
// 		wealth aggregates later in add-wealth-aggregates.do.
// ----------------------------------------------------------------------------

// Wealth Aggregates (Bauluz & Brassac 2020 + update 2021 for all countries) 
// 					- wealth aggregates 
// 					- macro series (inyixx & others, only for ES and SE)
append using "$wid_dir/Country-Updates/Wealth/2021_July/macro-wealth-Jul2021.dta"

// Russia 2017 (NPZ2017) - macro series +  distributional series 
append using "$wid_dir/Country-Updates/Russia/2017/August/russia-npz2017.dta"

// Australia, New Zealand, Canada - macro series +  distributional series 
append using "$wid_dir/Country-Updates/North_America/2025_10/aucanz-other-macro-dist-2025.dta"

// South Africa 2020 (ccg2020) - macro series + distributional series 
append using "$wid_dir/Country-Updates/South_Africa/2020/April/south-africa-wealth-Apr2020.dta"

// India 2019 - macro series (many inc. wwealn) (Kumar2019) 
append using "$wid_dir/Country-Updates/India/2019_April/india-kumar2019.dta"
drop if iso == "IN" & author == "kumar2019" & inlist(widcode, "npopul999i") & year>1947

// Korea 2018 (Kim2018) - macro series + distributional series (gdp & nni cstt LCU imported in add-researchers-real.do) 
append using "$wid_dir/Country-Updates/Korea/2018_10/korea-kim2018-current.dta"
// dropping fiinc as there are newer versions of this data for KR added in Section (1.1) 
drop if iso == "KR" & inlist(widcode, "afiinc992i", "sfiinc992i", "tfiinc992i") ///
& author == "kim2018"

// --------------------- Modified 22 Oct 2025: -----------------------------

// US - macro series +  distributional series 
append using "$wid_dir/Country-Updates/US/2025/us-other-macro-dist-2025.dta"

// Asia (China, Hong Kong, Indonesia, Myanmar, Singapore, Thailand, Taiwan) 
// 	-  macro series + distributional series
append using "$wid_dir/Country-Updates/Asia/2025/asia-other-macro-dist-2025.dta" 

//======================= 1.4. Dropping wealth aggregates ======================

gen is_wealth_agg = regexm(lower(widcode), "^(m[cghinp]w[a-z]{3}(999)i)$") ///
    | regexm(lower(widcode), "^wweal[cgnph](999)i$")
drop if is_wealth_agg
drop if widcode == "wincta992i"
drop is_wealth_agg

assert !missing(iso, year, widcode)
isid iso year p widcode, missok 

// -----------------------------------------------------------------------------
// --------------------- 2.1. Import updated ptinc series  ---------------------
// -----------------------------------------------------------------------------

// ----------------------- Below not updated in Autumn 2025: -------------------
											  
// Hong Kong 2021 (PY2021) - ptinc series
append using "$wid_dir/Country-Updates/Hong Kong/HongKong_ptinc_2021_Feb2026.dta"

// Georgia 2021 (Neef & BMN 2021) - ptinc series
append using "$wid_dir/Country-Updates/Georgia/2021_08/dina_georgia_8sep2021_Feb2026.dta"

// ------------------ Below modified 07 Oct 2025 by Manuel Esteban:: -----------
								 
// Russia (Neef 2022) -  ptinc series - 
append using "$wid_dir/Country-Updates/Russia/2024/Russia2024_Feb2026.dta"								
// Other Russia and central Asia countries 1980-1990 
// (extension of RU series following Neef 2022) -  ptinc series - 
append using "$wid_dir/Country-Updates/OtherRussia_CentralAsia/2025/otherrussia-ptinct-8090-2025_Feb2026.dta"

// --------- Main Pre-Tax Update: modified 20 Oct 2025 by Ana Van Der Ree: -----
						  
// Middle East (AAP2017 § Moshrif 2020 & BM2021 & HM2022) - ptinc series  
append using "$wid_dir/Country-Updates/Middle-East/2025/mena-2025.dta"

// Asia (MCY 2020 & BM 2021 & SZ 2022 & SZ 2023) - ptinc series 
append using "$wid_dir/Country-Updates/Asia/2025/asia-ptinc-2025.dta"                    
// Africa (CCGL & Robillard 2025) - ptinc series 
append using "$wid_dir/Country-Updates/Africa/2025_09/africa-ptinc-2025.dta"

// Australia, New Zealand & Canada (Matt 2022 & Matt 2023 & Matt 2025) 
// 				- ptinc series 
// 				- updated macro series (nninc, inyxx)
append using "$wid_dir/Country-Updates/North_America/2025_10/aucanz-2025.dta"
// drop wealth aggs
drop if widcode == "mhweal999i"

// US (PSZ + BSZ 2022 + BSZ 2023 + Matt 2025) 
// 				- ptinc series 
// 				- fainc series 
// 				- updated macro series (nninc, inyxx)
append using "$wid_dir/Country-Updates/US/2025/us-2025.dta"
drop if missing(year) & iso == "US"
// drop wealth aggs
drop if widcode == "mhweal999i"

assert !missing(iso, year, widcode)
isid iso year p widcode, missok 
                        		                       
/*
// India (Chancel 2020) - 
append using "$wid_dir/Country-Updates/India/2024/India_all_2024.dta"                                    //Modif: 10 Oct 2024 by Manuel Esteban
drop if iso == "IN" & author == "chancel2018" & inlist(widcode, "anninc992i", "mnninc999i")
drop if iso == "IN" & author == "kumar2019"   & inlist(widcode, "npopul999i") & year>1947
* Note: India was not included in Asia before. Since 2024 IN is included . The 
*      amount of observations widcode-p were verified and Asia contains all the 
*      combinations. As so, this file is no longer necessary.
*/

assert data_quality!=. if strpos(widcode, "ptinc") 

compress, nocoalesce 

tempfile researchers
save "`researchers'"

// -----------------------------------------------------------------------------
// --------------------------- 3. Import Meta Data  --------------------------
// -----------------------------------------------------------------------------

generate sixlet = substr(widcode, 1, 6)
ds year p widcode value currency author data_quality, not
keep `r(varlist)'
// drop if sixlet=="npopul" & strpos(source,"chancel")>0

duplicates drop iso sixlet, force
order iso sixlet source method

// --------- Main Pre-Tax Update: modified 20 Oct 2025 by Ana Van Der Ree: -----

// Asia
// ptinc metadata
merge 1:1 iso sixlet using "$wid_dir/Country-Updates/Asia/2025/asia-ptinc-2025-metadata.dta", force update replace nogen
// fiinc metadata (KR, JP)
merge 1:1 iso sixlet using "$wid_dir/Country-Updates/Asia/2025/asia-fiinc-2025-metadata.dta", force update replace nogen
// other distributional data 
merge 1:1 iso sixlet using "$wid_dir/Country-Updates/Asia/2025/asia-other-macro-dist-2025-metadata.dta", force update replace nogen
	   
// Mena 
merge 1:1 iso sixlet using "$wid_dir/Country-Updates/Middle-East/2025/mena-2025-metadata.dta", force update replace nogen
 			
// Africa 
merge 1:1 iso sixlet using "$wid_dir/Country-Updates/Africa/2025_09/africa-ptinc-2025-metadata.dta", force update replace nogen

// North America & Oceania 
merge 1:1 iso sixlet using "$wid_dir/Country-Updates/North_America/2025_10/aucanz-2025-metadata.dta", force update replace nogen            
merge 1:1 iso sixlet using "$wid_dir/Country-Updates/US/2025/us-2025-metadata.dta", force update replace nogen

// Bauluz & Brassac wealth aggregates (only keeping macro vars in next step)
merge 1:1 iso sixlet using "$wid_dir/Country-Updates/Wealth/2021_July/macro-wealth-Jul2021-metadata.dta", update replace nogen

//======================= 3.2. Dropping wealth aggregate sixlets ===============

gen is_wealth_agg = regexm(lower(sixlet), "^(m[cghinp]w[a-z]{3})$") ///
    | regexm(lower(sixlet), "^wweal[cgnph]$")
drop if is_wealth_agg
drop is_wealth_agg    

gduplicates drop iso sixlet, force

tempfile meta
save "`meta'"

// -----------------------------------------------------------------------------
// -------------------- 4. Final cleaning & pulling old data  ------------------
// -----------------------------------------------------------------------------

use "$work_data/calculate-average-over-output.dta", clear
drop if inlist(iso, "NZ", "AU", "CA", "ID", "SG", "TW")
drop if iso == "NL" & widcode == "inyixx999i"
drop if iso == "NL" & widcode == "mnninc999i"
drop if missing(value)

// New from Oct 2025: dropping wealth aggregates from old file 
gen is_wealth_agg = regexm(lower(widcode), "^(m[cghinp]w[a-z]{3}(999)i)$") ///
    | regexm(lower(widcode), "^wweal[cgnph](999)i$")
drop if is_wealth_agg
drop if inlist(widcode, "wincta992i", "wincta992t")
drop is_wealth_agg 

generate oldobs = 1

append using "`researchers'"
replace currency = "EUR" if iso == "NL" & inlist(widcode, "inyixx999i", "mnninc999i")


// Correcting data quality from old database 
replace data_quality = 3 if iso=="ZZ" & strpos(widcode, "fiinc") // later this series gets converted to ptinc. Data comes from tax tabulations Atkinson 2015
replace data_quality = 3 if iso=="GB" & strpos(widcode, "diinc") & data_quality ==. 

replace p = "pall" if p == "p0p100"
replace oldobs = 0 if missing(oldobs)

*drop if iso == "ES" & year == 1900 & missing(value) & p == "p0p100"

// Drop old rows available in new data
sort iso year p widcode oldobs // sort to put the new observations first
gduplicates tag iso year p widcode, gen(dup)
drop if dup & oldobs

// US 2017: drop specific widcodes
drop if (inlist(widcode, "ahweal992j", "shweal992j", "afainc992j", "sfainc992j", "aptinc992j") ///
	   | inlist(widcode, "sptinc992j", "adiinc992j", "sdiinc992j", "npopul992i", "mhweal992j") ///
	   | inlist(widcode, "mfainc992j", "mptinc992j", "mdiinc992j", "mnninc999i") /// 	
	   | inlist(widcode, "mgdpro999i", "mnnfin999i", "mconfc999i")) ///
	   & (iso=="US") & (oldobs==1)

// ------------------------------------------------------------------------------   
// Update from Oct 2025: the chunk below is commented-out because it is redundant
// now that we don't import wealth aggs from Bauluz in this file. The code can be 
// run but it changes nothing to the file, 0 observations are dropped at the end. 

// Bauluz 2017 updates: drop all old series (widcode-years combinations), except for "n" and "i" where we fill gaps. 
// preserve
// 	keep if author == "BBM2021"
// 	keep iso widcode
// 	duplicates drop
// 	gen todrop = 1
//	
// 	tempfile todrop
// 	save "`todrop'"
// restore
// merge m:1 iso widcode using "`todrop'", assert(master matched) nogen
// drop if todrop == 1 & author!= "BBM2021" & !inlist(substr(widcode, 1, 1), "n", "i")
// ------------------------------------------------------------------------------   

*gduplicates tag iso year widcode p, gen(usdup) // solve conflict between bauluz and psz2017 (npopul, inyixx)
*drop if usdup & iso == "US" & author!= "BBM2021"

// India 2017: drop duplicates and old fiscal income data
// drop if substr(widcode, 2, 5) == "fiinc" & oldobs == 1 & iso == "IN"

// Korea 2018: drop all old variables present in updates
drop if iso == "KR" & oldobs == 1 ///
	& (inlist(widcode, "aficap992i", "afidiv992i", "afiinc992i", "afiinc999i", "afiint992i") ///
	 | inlist(widcode, "afilin992i", "ahweal992i", "bfiinc992i", "inyixx999i", "mcwboo999i", "mcwdeb999i", "mcwdeq999i", "mcwfin999i") ///
	 | inlist(widcode, "mcwnfa999i", "mcwres999i", "mcwtoq999i", "mfiinc999i", "mhweal999i", "mnwboo999i", "mnweal999i", "npopul992i") ///
	 | inlist(widcode, "npopul999i", "sfiinc992i", "shweal992i", "tfiinc992i", "thweal992i"))

// Drop old Malaysian top shares (fiinc992i)
drop if iso == "MY" & strpos(widcode, "fiinc992i")> 0

// Drop widcodes from previous ZA to be replaced with ccg2020
*drop if (widcode == "npopul992i"| widcode == "npopul999i" | widcode == "mnninc999i" ) & iso == "ZA" & author != "ccg2020"
*drop if (substr(widcode, 1, 3) == "mpw" ) & iso == "ZA" & oldobs == 1 & author != "ccg2020" & widcode != "mpwodk999i"

gduplicates tag iso year p widcode, gen(duplicate)
assert duplicate == 0

assert data_quality !=. if strpos(widcode, "ptinc")

// =============================================================================
// =============================================================================
// =============================================================================
// ----- TEMPORARY FIX TO BE REMOVED AFTER DATA QUALITY PROJECT IS COMPLETE!!! ---

preserve
	keep iso year widcode data_quality
	duplicates drop
	duplicates tag iso year widcode, gen(dup)
	drop if data_quality ==. & iso=="DE" & strpos(widcode, "fiinc992t") & dup==1
	duplicates drop
	isid iso year widcode
	drop dup 
	label data "Temporary data quality storage generated by add-researchers-data.do"
	save "$work_data/data-quality-add-researchers-data-output.dta", replace 
restore

keep iso year p widcode currency value //data_quality
// need to uncomment data quality when this project is ready for launch 
// =============================================================================
// =============================================================================
// =============================================================================

sort iso year p widcode
// There are few missing values for CM, DZ, GB, IN, JP, TN, VN for the widcodes:
// sfiinc992i, sfiinc992t, thweal992j
drop if missing(value) 

// // Remove carbon data (macro & distribution) as it will be performed separately
// drop if substr(widcode, 1, 1) == "l" | substr(widcode, 1, 1) == "e" 

//======================= 4.1 Add data to WID ==================================
label data "Generated by add-researchers-data.do"
save "$work_data/add-researchers-data-output.dta", replace

//======================= 4.2 Add meta data to WID =============================

use "$work_data/correct-wtid-metadata-output.dta", clear
merge 1:1 iso sixlet using "`meta'", nogenerate update replace

label data "Generated by add-researchers-data.do"
save "$work_data/add-researchers-data-metadata.dta", replace
