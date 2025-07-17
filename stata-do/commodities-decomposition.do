//------------------------------------------------------------------------------
//      Commodities and manufactured goods trade decomposition.do
//------------------------------------------------------------------------------


//------ 1.  Manipulating the series on commodities exports after 1938 --------

u "$wid_dir/Country-Updates/Trade/UNComtrade/uncomtrade_merchandisetrade", clear 
sort iso year 
destring year, replace

renvars exp* imp* sh*, postfix(_ct)
destring year, replace
merge 1:1 iso year using "$work_data/merchandisetrade.dta" 

// flagging missing values or 0 values
gen flagexp = 1 if mi(sh_exp_AG) | mi(sh_exp_MA) | mi(sh_exp_MI)
replace flagexp = 1 if sh_exp_AG == 0 | sh_exp_MA == 0 | sh_exp_MI == 0  
replace flagexp = 0 if mi(flagexp)

gen flagimp = 1 if mi(sh_imp_AG) | mi(sh_imp_MA) | mi(sh_imp_MI)
replace flagimp = 1 if sh_imp_AG == 0 | sh_imp_MA == 0 | sh_imp_MI == 0  
replace flagimp = 0 if mi(flagimp)

foreach s in AG MA MI {
	foreach f in exp imp {
		replace `f'ort`s' = `f'ort`s'_ct/1e6 if flag`f' == 1	
		replace sh_`f'_`s' = sh_`f'_`s'_ct if flag`f' == 1	
	}
}
replace exportTO = exportAG + exportMI + exportMA
replace importTO = importAG + importMI + importMA

drop flag* *ct _m

replace iso = "RU" if iso == "SU"
replace iso = "CZ" if iso == "CS"
replace iso = "RS" if iso == "YU"
replace iso = "CW" if iso == "AN"

drop sh_*

* Special case: Complete RU
fillin iso year
drop if (_fillin==1 & year<1970) | (_fillin==1 & year>=1970 & iso!="RU")
drop _fillin

sort iso year
foreach v in exportAG exportMA exportMI exportTO importAG importMA importMI importTO {

    quietly {
        forvalues i = `=_N'(-1)1 {
            quietly replace `v' =(`v'[`i'+1] + `v'[`i'+2] + `v'[`i'+3]) / 3 ///
                if iso=="RU" & missing(`v'[`i']) & iso[`i'] == iso[`i'+1] in `i'
        }
    }
}

//Keep Core countries
merge m:1 iso using "$work_data/import-core-country-codes-output.dta", nogen keep(matched)
drop titlename-corecountry region1 region3

preserve
	replace region2="OA" if iso=="RU" & year<=1994 // THis for compleating the regional data of OA
	drop if missing(region2)
	collapse (sum) exp* imp*, by(year region2)
	rename region2 iso
	tempfile merchandise_reg
	save    `merchandise_reg'
restore

drop region2
append using "`merchandise_reg'"

// shares
so iso year 
foreach v in AG MA MI {
	gen double sh_exp_`v' = export`v'/exportTO
}
foreach v in AG MA MI {
	gen sh_imp_`v' = import`v'/importTO
}

	foreach f in exp imp {
		gen double sh_`f'_com = sh_`f'_AG + sh_`f'_MI
	}


keep iso year sh* 

//Format
rename sh_exp_AG tgxmx // share of manufactured goods in exports in goods (%) (after net zero correction) (benchmark series)
rename sh_exp_MI  tgmmx // share of manufactured goods in imports in goods (%) (after net zero correction) (benchmark series)
rename sh_exp_com tgxcx // share of primary commodities in exports in goods (%) (after net zero correction) (benchmark series)
rename sh_imp_com tgmcx // share of primary commodities in imports in goods (%) (after net zero correction) (benchmark series)
*replace widcode="" if code=="imp_AG"  // trade balance in manufactured goods (% GDP) (MER $) (after net zero correction) (benchmark series)
*replace widcode="" if code=="imp_MI"  // exports in manufactured goods (% GDP) (MER $) (after net zero correction) (benchmark series)

drop sh_*



tempfile merchandise
save    `merchandise'



// -------- 2. Trade Stats 1938-1960  ------------------------------------------						

u "$wid_dir/Country-Updates/Trade/UNComtrade/UN Trade Statistics/share_commodities.dta", clear 

//Keep Core countries
merge m:1 iso using "$work_data/import-core-country-codes-output.dta", nogen keep(matched)
drop titlename-corecountry region1 region3

preserve
	drop if missing(region2)
	collapse (sum) Mtot Mmanuf Xtot Xmanuf, by(region2 year)
	rename region2 iso
	tempfile hist_reg
	save    `hist_reg'
restore

drop region2
append using "`hist_reg'"

keep Mtot Mmanuf Xtot Xmanuf iso year
foreach var in Mtot Mmanuf Xtot Xmanuf {
	replace `var' =. if `var' == 0
}


gen double sh_import_com = 1 - (Mmanuf/Mtot)
gen double sh_export_com = 1 - (Xmanuf/Xtot)
gen double sh_import_man = Mmanuf/Mtot
gen double sh_export_man = Xmanuf/Xtot

keep iso year sh*
order iso year 

//Format
rename sh_export_com tgxcx //  Raw series on share of primary commodities in exports in goods (%)
rename sh_import_com tgmcx // Raw series on share of primary commodities in imports in goods (%)
rename  sh_export_man tgxmx //  Raw series on share of manufactured goods in exports in goods (%)
rename sh_import_man tgmmx // Raw series on share of manufactured goods in imports in goods (%)



tempfile historical
save    `historical'



//---------- 3. Checking how big is code 68 and 9  -----------------------------
/*
u "$wid_dir/Country-Updates/Trade/UNComtrade/sitc19661999", clear // Have to be actualized
keep period reporter_iso reporter_desc flow_code partner_desc classification_code classification_search_code is_original_classification cmd_code cmd_desc aggr_level primary_value

kountry reporter_iso, from(iso3c) to(iso2c)
ren _ISO2C_ iso
fre reporter_desc if mi(iso)

/*
reporter_desc
----------------------------------------------------------------------------------------------
                                                 |      Freq.    Percent      Valid       Cum.
-------------------------------------------------+--------------------------------------------
Valid   Czechoslovakia (...1992)                 |        500      21.01      21.01      21.01
        Dem. Rep. of Germany (...1990)           |        132       5.55       5.55      26.55
        Dem. Yemen (...1990)                     |         21       0.88       0.88      27.44
        Other Asia, nes                          |        462      19.41      19.41      46.85
        Peninsula Malaysia (...1963)             |         44       1.85       1.85      48.70
        Sabah (...1963)                          |         44       1.85       1.85      50.55
        Serbia and Montenegro (...2005)          |        110       4.62       4.62      55.17
        Southern African Customs Union (...1999) |        429      18.03      18.03      73.19
        Yugoslavia (...1991)                     |        638      26.81      26.81     100.00
        Total                                    |       2380     100.00     100.00           
----------------------------------------------------------------------------------------------
*/

replace iso = "CZ" if reporter_desc == "Czechoslovakia (...1992)"
replace iso = "DD" if reporter_desc == "Dem. Rep. of Germany (...1990)"
replace iso = "YD" if reporter_desc == "Dem. Yemen (...1990)"
replace iso = "" if reporter_desc == "Other Asia, nes"
replace iso = "MY" if reporter_desc == "Peninsula Malaysia (...1963)"
replace iso = "MY" if reporter_desc == "Sabah (...1963)"
replace iso = "RS" if reporter_desc == "Serbia and Montenegro (...2005)"
replace iso = "ZA" if reporter_desc == "Southern African Customs Union (...1999)"
replace iso = "YU" if reporter_desc == "Yugoslavia (...1991)"

replace iso = "RU" if iso == "SU"
replace iso = "CZ" if iso == "CS"
replace iso = "RS" if iso == "YU"
replace iso = "CW" if iso == "AN"

drop if mi(iso)
collapse (sum) primary_value, by(iso period flow_code cmd_code)

ren (period primary_value) (year value)
destring year, replace

gen flow = flow_code + cmd_code 
drop flow_code cmd_code
reshape wide value, i(iso year) j(flow) string 

renvars value*, pred(5)


gen exportAG = cond(mi(X0),0,X0) + cond(mi(X1),0,X1) + cond(mi(X2),0,X2) + cond(mi(X4),0,X4) - cond(mi(X27),0,X27) - cond(mi(X28),0,X28)
gen exportMI = cond(mi(X27),0,X27) + cond(mi(X28),0,X28) + cond(mi(X3),0,X3) + cond(mi(X68),0,X68)
gen exportMA = cond(mi(X5),0,X5) + cond(mi(X6),0,X6) + cond(mi(X7),0,X7) + cond(mi(X8),0,X8) + cond(mi(X9),0,X9) - cond(mi(X68),0,X68)

gen exportTO = exportAG + exportMI + exportMA

gen importAG = cond(mi(M0),0,M0) + cond(mi(M1),0,M1) + cond(mi(M2),0,M2) + cond(mi(M4),0,M4) - cond(mi(M27),0,M27) - cond(mi(M28),0,M28)
gen importMI = cond(mi(M27),0,M27) + cond(mi(M28),0,M28) + cond(mi(M3),0,M3) + cond(mi(M68),0,M68)
gen importMA = cond(mi(M5),0,M5) + cond(mi(M6),0,M6) + cond(mi(M7),0,M7) + cond(mi(M8),0,M8) + cond(mi(M9),0,M9) - cond(mi(M68),0,M68)

gen importTO = importAG + importMI + importMA

//Keep Core countries
merge m:1 iso using "$work_data/import-core-country-codes-output.dta", nogen keep(matched)
drop titlename-corecountry region*

keep iso year exportTO importTO X9 X68 M9 M68


// Calculate ratios
gen ratiox68tot = X68/exportTO
gen ratiom68tot = M68/importTO
gen ratiox9tot = X9/exportTO
gen ratiom9tot = M9/importTO


//Format
*rename ratiom68tot tgmmx  // Raw series on exports in manufactured goods (% GDP) (MER $) (before net zero correction)
rename ratiom9tot tgmmx_sitc  // Raw series on share of manufactured goods in imports in goods (%)
*rename ratiox68tot tgxmx  // Raw series on trade balance in manufactured goods (% GDP) (MER $) (before net zero correction)
rename ratiox9tot tgxmx_sitc  // Raw series on share of manufactured goods in exports in goods (%)
keep iso year *_sitc

tempfile sitc
save `sitc'
*/

//---------- 4. Compiling  -----------------------------------------------------

use "`merchandise'", clear
append using  "`historical'"
*merge 1:1 iso year using "`sitc'"

keep if year >=1970
sort iso year 
fillin iso year 
drop _fillin 

preserve
	keep if inlist(iso,"OC","OI","OD","QM","OA","OJ","OE","OH","OB")
	
	foreach v in tgxmx tgmmx tgxcx tgmcx {
		gsort iso -year 
		bysort iso (year): carryforward `v', replace
	}
	rename tg* reg_tg*
	rename iso region
	tempfile regions
	save `regions'
restore

//---------- 5. Completing missing data  ---------------------------------------

//Keep Core countries
merge m:1 iso using "$work_data/import-core-country-codes-output.dta", nogen keep(matched using)
drop titlename-corecountry region1 region3
rename region2 region

replace year=1970 if missing(year) // this are core countries not evailable in any of the sources
fillin iso year
drop _fillin
bysort iso (year): replace region = region[_n-1] if missing(region) & (iso[_n-1]==iso)


replace region="OC" if inlist(iso, "DE", "DK", "ES", "FR", "GB", "IT", "NL", "NO", "SE")
replace region="OH"	if inlist(iso, "US", "CA", "AU", "NZ")
replace region="OD"	if inlist(iso, "AR", "BR", "CL", "CO", "MX")
replace region="OE"	if inlist(iso, "AE", "DZ", "EG", "IR", "MA", "SA", "TR")
replace region="OJ"	if inlist(iso, "CD", "CI", "ET", "KE", "ML", "NE", "NG", "RW")
replace region="OJ"	if inlist(iso, "SD", "ZA")
replace region="OA"	if inlist(iso, "RU")	
replace region="OB"	if inlist(iso, "CN", "JP", "KR", "TW")	
replace region="OI"	if inlist(iso, "BD", "IN", "ID", "MM", "PK", "PH", "TH", "VN")
assert !missing(region)

merge m:1 region year using "`regions'", nogenerate 

sort iso year

/*
* Tag single missing years
gen     tag = 0
foreach v in tgxmx tgmmx tgxcx tgmcx {
	replace tag = 1 if mi(`v') & ///
					(!mi(`v'[_n-1]) & !mi(`v'[_n+1])) 
}
replace tag = 0 if inlist(year, 1970 , $pastyear )
*/
* Tag missings
gen tag_m=0
foreach v in tgxmx tgmmx tgxcx tgmcx {
	replace tag_m = 1 if mi(`v') & !missing(region)
}


* Complete missings
*gsort iso -year 
*foreach v in tgxmx tgmmx tgxcx tgmcx {
*	replace 3`v' = (reg_`v'*`v'[_n-1])/`v'[_n-1] if tag_m==1 
*}
// Inputing based in the region data
* Input n+1
gsort iso -year 
foreach v in tgxmx tgmmx tgxcx tgmcx {
	gen double filled_`v' = `v'
    quietly {
        forvalues i = `=_N'(-1)1 {
            quietly replace filled_`v' = (reg_`v'[`i'] * filled_`v'[`i'+1]) / reg_`v'[`i'+1]  /// 
			if tag_m[`i'] == 1  & missing(filled_`v'[`i']) & iso[`i'] == iso[`i'+1] in `i'
        }
    }
}
* Input n-1
sort iso year
foreach v in tgxmx tgmmx tgxcx tgmcx {

    quietly {
        forvalues i = `=_N'(-1)1 {
            quietly replace filled_`v' = (reg_`v'[`i'] * filled_`v'[`i'+1]) / reg_`v'[`i'+1] ///
                if tag_m[`i'] == 1 & missing(filled_`v'[`i']) & iso[`i'] == iso[`i'+1] in `i'
        }
    }
}

* Fill data
foreach v in tgxmx tgmmx tgxcx tgmcx {
	replace `v' =filled_`v'  if tag_m==1 & missing(`v')
}
foreach v in tgxmx tgmmx tgxcx tgmcx {
	replace `v' =reg_`v'     if tag_m==1 & missing(`v')
}

drop region tag_m reg_* filled*
// --------------> Raw series on share of var in X or M in goods (%)
//---------- 6. Calling GDP, price index and XRate data  -----------------------
// Bring the value of the trade balance
merge 1:1 iso year using "$work_data/bop_currentacc.dta",  nogen                    keepusing(tgxrx tgmpx) // tgnnx
// Bring Product 
merge 1:1 iso year using "$work_data/retropolate-gdp.dta", nogen keep(match master) keepusing(gdp currency)
merge 1:1 iso year using "$work_data/price-index.dta",     nogen keep(match master) keepusing(index)
merge 1:1 iso year using "$work_data/exchange-rates.dta",  nogen keep(match master) keepusing(value)
rename value xrateusd
keep if year>=1970


* Calculate values in Current USD Dollars 
replace gdp=(gdp*index)/xrateusd //GDP current Miill USD MER
drop currency index xrateusd

replace tgxrx= tgxrx*gdp  //Exports of goods current Miill USD MER after net zero correction
replace tgmpx= tgmpx*gdp //Imports of goods current Miill USD MER after net zero correction

//step 1: Raw series on X or M (current millon USD) (MER) (before net zero correction)
replace tgxcx = tgxcx * tgxrx
replace tgmcx = tgmcx * tgmpx
replace tgxmx = tgxmx * tgxrx
replace tgmmx = tgmmx * tgmpx

// step 2: New series on X or M in var (current millon USD) (MER) (after net zero correction) (benchmark series)
foreach v in tgxmx tgmmx tgxcx tgmcx {
	egen `v'_wo=sum(`v'), by(year)
	replace `v'_wo=. if `v'_wo==0
}
replace tgxcx = tgxcx*((((2*tgxcx_wo)+(0*tgmcx_wo)))/2)/tgxcx_wo
replace tgmcx = tgmcx*((((2*tgmcx_wo)+(0*tgxcx_wo)))/2)/tgmcx_wo
replace tgxmx = tgxmx*((((2*tgxmx_wo)+(0*tgmmx_wo)))/2)/tgxmx_wo
replace tgmmx = tgmmx*((((2*tgmmx_wo)+(0*tgxmx_wo)))/2)/tgmmx_wo

// step 3:
replace tgxmx = tgxrx - tgxcx
replace tgmmx = tgmpx - tgmcx

*assert tgxcx + tgxmx == tgxrx if !mi(tgxcx) & !mi(tgxmx)
*assert tgmcx + tgmmx == tgmpx if !mi(tgmcx) + !mi(tgmmx)

//step 4:
foreach v in tgxmx tgmmx tgxcx tgmcx {
	replace `v'=`v'/gdp
}


// Calculate net values
gen double tgncx = tgxcx - tgmcx
gen double tgnmx = tgxmx - tgmmx

drop *_wo


//---------- 7. Adjust with Nievas Piketty 2025 ---------------------------- //
/*
preserve
	* Import Data
	use "$work_data/NievasPiketty2025WBOP.dta", clear

	keep if year<=2022
	
	* Generate Fivelets as defined in the Wid-Dictionary
	gen      fivelet= "tgxcx"  if origin =="B2b"
	replace  fivelet= "tgmcx"  if origin =="B2c"
	replace  fivelet= "tgxmx"  if origin =="B3b" 
	replace  fivelet= "tgmmx"  if origin =="B3c"
		
	*Format for importing
	drop if missing(fivelet)
	drop origin concept
	reshape wide value, i(iso year) j(fivelet) string
	rename value* *
	
	
	
	* Calculate net values
	*gen double tgncx = tgxcx - tgmcx
	*gen double tgnmx = tgxmx - tgmmx
		
	tempfile np2025
	save `np2025'
		
	keep  if inlist(substr(iso, 1, 1), "X", "O") | inlist(iso, "QL","QM","WO","QE")
	rename iso region2
	
	renvars tgmcx-tgxmx, prefix(paper_)	
	
	tempfile np2025_reg
	save `np2025_reg'
restore

* merge NP(2025)
merge 1:1 iso year using "`np2025'", update replace nogenerate

order iso year  

// Adjust countries in residual regions to fitin in the residual regions of NP2025
* Step 1: Call region defintions
merge 1:1 iso year using "$work_data/import-core-country-codes-year-output.dta", nogen keepusing(region2 corecountry)

sort iso year 
merge 1:1 iso year using "$work_data/retropolate-gdp.dta",    nogen keepusing(gdp)        keep(master matched)
merge 1:1 iso year using "$work_data/price-index.dta",        nogen                       keep(master matched)
merge 1:1 iso year using "$work_data/USS-exchange-rates.dta", nogen keepusing(exrate_usd) keep(master matched)
keep if year>=1970
drop if corecountry!=1

*gen double gdp_idx = gdp*index
gen double gdp_usd = (gdp*index)/ exrate_usd

 *calculate gdp of regions
bys year region2: egen reg_gdp_usd = total(gdp_usd)
replace reg_gdp_usd = . if missing(region2)

* Bring regions from Paper
merge m:1 region2 year using "`np2025_reg'", nogenerate keep(master match)


* Step 2: Calculate monetary values of the variables
foreach v in tgmcx tgmmx tgxcx tgxmx {
	replace `v'=`v'* gdp_usd
	replace paper_`v'=paper_`v'* reg_gdp_usd
}

* Step 3: Calculate total values by region-year
foreach v in tgmcx tgmmx tgxcx tgxmx  {
    gen double             abs_`v'       = abs(`v')
    bys region2 year: egen total_`v'     = total(`v')     // Raw regional sum
    bys region2 year: egen total_abs_`v' = total(abs_`v') // For proportional adjustment
}

* Step 4: Compute the net total vs paper values
foreach v in tgmcx tgmmx tgxcx tgxmx  {
    gen double totnet_`v' = (paper_`v'- total_abs_`v')
}
sort iso year 

* Step 5: Allocate adjustments proportionally for tgxrx and tgmpx
foreach v in tgmcx tgmmx tgxcx tgxmx {
    gen double prop_`v'   = abs_`v' / total_abs_`v' // Share in regional total
    gen double adjust_`v' = prop_`v' * totnet_`v'   // Adjustment share
    replace    `v'        = `v' + adjust_`v'       if !missing(region2) & year>=1970 & year<=2022 
}
drop corecountry paper_* abs_* adjust_* prop_*  total_* totnet_* reg_gdp_usd



* Recalculate net values
replace tgncx = tgxcx - tgmcx
replace tgnmx = tgxmx - tgmmx

* Recalcualte the shares of the GDP
foreach v in tgmcx tgmmx tgxcx tgxmx tgncx tgnmx {
	replace `v'=`v'/ gdp_usd	
	
} 
drop region2 gdp* index currency exrate_usd // gdp_xrate
drop  tgmpx tgxrx 



//---------------------------------------------------------------------------- //
enforce (tgncx = tgxcx - tgmcx) ///
		(tgnmx = tgxmx - tgmmx), fixed(tgmcx tgmmx tgxcx tgxmx) replace force
*/
//---------- 5. Export  --------------------------------------------------------
order iso year 
keep iso year tgncx tgxcx tgmcx tgnmx tgxmx tgmmx

// Save
label data "Generated by commodities-decomposition.do "
save         "$work_data/commodities-decomposition.dta", replace



/*
* checking adding to zero: 
*replace gdp_usd= round(gdp_usd,  0.0000000000000000001) 
foreach var in tgmcx tgmmx tgxcx tgxmx {
	*replace `var' = round(`var', 0.0000000000000000001)
	replace `var' = `var'*gdp_usd
}

collapse (sum) tgmcx tgmmx tgxcx tgxmx  tgncx tgnmx, by( year)    //
gen double tgncx = tgxcx - tgmcx
gen double tgnmx = tgxmx - tgmmx

foreach var in tbnnx tgnnx tsnnx scinx{
	replace `var' = `var'/gdp_usd
	replace `var' = round(`var',5)
}
