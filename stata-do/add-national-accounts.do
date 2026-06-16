// -------------------------------------------------------------------------- //
// Add harmonized national accounts series to the database
// -------------------------------------------------------------------------- //

// -------------------------------------------------------------------------- //
// Make list of widcodes to be removed from initial data because we are
// replacing them by new national accounts series (which incorporate
// initial data from WTID and WIL fellows).
// -------------------------------------------------------------------------- //

use "$work_data/national-accounts.dta", clear
generate fivelet = substr(widcode, 2, 5)
keep iso year fivelet
gduplicates drop
tempfile to_replace
save "`to_replace'"

// -------------------------------------------------------------------------- //
// Add new national accounts series
// -------------------------------------------------------------------------- //

use "$work_data/add-price-index-output.dta", clear

generate fivelet = substr(widcode, 2, 5)

// Remove series with old widcodes to be replaced with equivalent series with
// new widcodes
drop if inlist(fivelet, "psavi", "psgro", "psdep", "hsavi", "hsgro", "hsdep") ///
     | inlist(fivelet, "isavi", "isgro", "isdep", "csavi", "csgro", "csdep") ///
     | inlist(fivelet, "gsavi", "gsgro", "nsavi", "nsgro", "nsdep", "nsdep") ///
     | inlist(fivelet, "dsavi", "fsavi", "nvatp")
	 
// Remove series to be replaced
merge n:1 iso year fivelet using "`to_replace'", nogenerate keep(master)
drop fivelet

// Add new national accounts
append using "$work_data/national-accounts.dta"

drop if length(widcode) > 10

// Save
compress
save "$work_data/add-national-accounts-output.dta", replace

// -------------------------------------------------------------------------- //
// Correct metadata file
// -------------------------------------------------------------------------- //
/*
// Make list of widcode to be replaced
use "$work_data/national-accounts.dta", clear
generate fivelet = substr(widcode, 2, 5)
keep iso fivelet
gduplicates drop
tempfile to_replace
save "`to_replace'"

// Import old metadata
use "$work_data/add-price-index-metadata.dta", clear

generate fivelet = substr(sixlet, 2, 5)

// Remove widcodes that have changed
drop if inlist(fivelet, "psavi", "psgro", "psdep", "hsavi", "hsgro", "hsdep") ///
     | inlist(fivelet, "isavi", "isgro", "isdep", "csavi", "csgro", "csdep") ///
     | inlist(fivelet, "gsavi", "gsgro", "nsavi", "nsgro", "nsdep", "nsdep") ///
     | inlist(fivelet, "dsavi", "fsavi", "nvatp")
	 

// Remove widcodes that have been replaced
merge n:1 iso fivelet using "`to_replace'", nogenerate keep(master)
drop fivelet

gen old=1

// Add new metadata
append using "$work_data/na-metadata.dta"

// Check that we haven't created duplicates
gduplicates tag iso sixlet, gen(dup)
drop if dup!=0 & old==1
gduplicates tag iso sixlet, gen(dup2)
assert dup2 == 0
drop dup* old

// Save
compress
save "$work_data/add-national-accounts-metadata.dta", replace
