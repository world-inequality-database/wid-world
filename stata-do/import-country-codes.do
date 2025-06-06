// -------------------------------------------------------------------------- //
// Export countries and region codes
// -------------------------------------------------------------------------- //
/*
import excel "$country_codes/country-codes-core.xlsx", clear firstrow
keep if shortname != ""
rename code iso
*/

// ---------- 1. import core countries
import excel "$codes_dictionary", sheet("Country_List") cellrange(A2:K219) firstrow clear

drop Alpha3  ISONumeric region region2 
rename (Alpha2 TitleName ShortName) (iso titlename shortname)


ds iso titlename shortname TH, not

* Name generically the regions                
local cnt = 1
foreach r in `r(varlist)' {
    rename `r' region`cnt'
    local cnt = `cnt' + 1
}

gen corecountry=1

* clean repeated subdivision denominations
*replace region3="" if region2==region3

order iso titlename shortname

* Call the region's names
ds iso titlename shortname corecountry TH, not
preserve
	* Generate a table with name-Alpha2 codes equivalences 
	import excel "$codes_dictionary", sheet("Region_List") cellrange(A2:B22) firstrow clear	
	foreach r in `r(varlist)'{
		gen `r' = ShortName
	}
	drop ShortName
	rename (Alpha2) (code)
	
	tempfile regions_list
	save "`regions_list'"
restore

ds iso titlename shortname corecountry TH, not
* Bring the table generated and replace the names by alpha2 codes
foreach r in `r(varlist)'{
	merge m:1 `r' using "`regions_list'", nogenerate keepusing(code) keep(master matched)
	drop `r'
	rename code `r'
}

** Add a column for codes XA and XM  (Asia Decompositons)
*gen region6 = "XA" if region2 == "QD" & region1!="XN"
*replace region6 = "XM" if region2 == "QD" & region1=="XN"

*assert !missing(region6) if region2 == "QD" 

// ---------- 2. import historical countries
preserve
	import excel "$codes_dictionary", sheet("Historical_Country_List") cellrange(A2:C7) firstrow clear
	rename (Alpha2 ShortName TitleName) (iso shortname titlename)
	tempfile historical
	save   "`historical'"
restore
// ---------- 3. import Regions
preserve
	import excel "$codes_dictionary", sheet("Region_List") cellrange(A2:B22) firstrow clear
	rename (Alpha2 ShortName) (iso shortname)
	drop if iso=="WO"
	tempfile regions
	save   "`regions'"
restore
// ---------- 4. import the sub country territories
preserve
	import excel "$codes_dictionary", sheet("Sub_Country_List") cellrange(A2:C63) firstrow clear
	rename (Alpha2 ShortName TitleName) (iso shortname titlename)
	tempfile country_subregion
	save   "`country_subregion'"
restore
// ---------- 5. import Other jurisdiction
preserve
	import excel "$codes_dictionary", sheet("Other_Juridisdictions_List") cellrange(A2:C30) firstrow clear
	rename (Alpha2 ShortName TitleName) (iso shortname titlename)
	tempfile other_country
	save   "`other_country'"
restore

// ---------- 6. Append all lists
append using "`historical'"
append using "`regions'"
append using "`country_subregion'"
append using "`other_country'"

*Clean-up
replace titlename=shortname if missing(titlename)
sort iso

// -------------------------------------------------------------------------- //
// Core Countries only
// -------------------------------------------------------------------------- //
preserve
	keep if corecountry == 1
	drop if iso=="WO"
	label data "Generated by import-country-codes.do"
	save "$work_data/import-core-country-codes-output.dta", replace
restore
// -------------------------------------------------------------------------- //
// Core Countries-year
// -------------------------------------------------------------------------- //
preserve
	keep if corecountry == 1
	drop if iso=="WO"
	local n_years = $pastyear - 1970 + 1
	expand `n_years'
	sort iso 
	bysort iso: gen year = 1970 + _n - 1

	
	label data "Generated by import-country-codes.do"
	save "$work_data/import-core-country-codes-year-output.dta", replace
restore
// -------------------------------------------------------------------------- //
// Countries only
// -------------------------------------------------------------------------- //

preserve
	drop if inrange(iso, "QB", "QZ") | iso == "WO"  | inrange(iso, "OA", "OJ") ///
	| inrange(iso, "XA", "XF") | inrange(iso, "XL", "XS")
	label data "Generated by import-country-codes.do"
	save "$work_data/import-country-codes-output.dta", replace
restore

// -------------------------------------------------------------------------- //
// Regions (PPP)
// -------------------------------------------------------------------------- //

preserve
	keep if inrange(iso, "QB", "QZ") | iso == "WO"  | inrange(iso, "OA", "OJ") ///
	| inrange(iso, "XA", "XF") | inrange(iso, "XL", "XS")
	keep iso titlename shortname
	
	generate matchname = shortname
	
*	replace titlename = titlename + " (at purchasing power parity)"
*	replace shortname = shortname + " (at purchasing power parity)"
	
	label data "Generated by import-country-codes.do"
	save "$work_data/import-region-codes-output.dta", replace
restore

// -------------------------------------------------------------------------- //
// Regions (MER)
// -------------------------------------------------------------------------- //
/*
preserve
	keep if inrange(iso, "QB", "QZ") | iso == "WO"  | inrange(iso, "OA", "OJ") ///
	| inrange(iso, "XA", "XF") | inrange(iso, "XL", "XS")
	keep iso titlename shortname
	
	replace iso = iso + "-MER"
	replace titlename = titlename + " (at market exchange rate)"
	replace shortname = shortname + " (at market exchange rate)"
	
	label data "Generated by import-country-codes.do"
	save "$work_data/import-region-codes-mer-output.dta", replace
restore
*/
