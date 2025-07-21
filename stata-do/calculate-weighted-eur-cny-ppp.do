//------------------------------------------------------------------------------
//         Calculate weighted eur cny ppp . do
//------------------------------------------------------------------------------


// 1. Bringing  GDP to weight the EUR
use "$work_data/retropolate-gdp.dta" if currency == "EUR", clear
drop if iso == "DD"

keep iso year gdp currency
	
tempfile eurgdp
save `eurgdp'

// 2. Process PPP
* Bring PPP
use "$work_data/ppp.dta", clear

* Isolate EUR data of funder countries
preserve 
	keep if currency == "EUR" ///	
							& (inlist(iso, "DE", "ES", "FR", "IT", "NL")) 

	drop if iso == "DD"
	merge 1:1 iso year using `eurgdp', nogen 
	drop if mi(ppp)

	/* for weight table
	bys year : egen totalincome = total(nninc)
	gen weight = nninc/totalincome
	drop if mi(ppp)
	*/
	drop iso
	rename ppp ppp_ea
	* Calcualte the weight of each contry according to the GDP and caculate average
	collapse (mean) ppp_ea [aweight=gdp], by(year)
	
	
	tempfile ppp_ea
	save "`ppp_ea'" 
restore

preserve
	* Isolate CNY data 
	keep if iso == "CN"
	drop iso
	rename ppp ppp_cn
	tempfile ppp_cn
	save "`ppp_cn'" 
restore


// Generate a table for aggregate-macro-regions and calcuate sector factor shares
use "`ppp_ea'"
merge 1:1 year using "`ppp_cn'", nogenerate

drop refyear currency


label data "Generate by calculate-weighted-eur-cny-ppp.do"
save "$work_data/ppp_ea_cn_weithgted.dta", replace

