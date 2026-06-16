// -------------------------------------------------------------------------- //
// Calculate wealth-income ratios and labor/capital shares
// -------------------------------------------------------------------------- //

// -------------------------------------------------------------------------- //
// Wealth-income ratios (W)
// -------------------------------------------------------------------------- //

use "$work_data/complete-variables-output.dta", clear

keep if inlist(substr(widcode, 1, 6), "mpweal", "mhweal", "miweal", "mgweal", "mnweal", "mnninc")
replace p="pall" if p=="p0p100"

drop currency
reshape wide value data_quality s_, i(iso year) j(widcode) string

foreach l in n p h i g {
	generate valuewweal`l'999i = valuem`l'weal999i/valuemnninc999i
	generate data_qualitywweal`l'999i = data_qualitymnninc999i
	generate s_wweal`l'999i = s_m`l'weal999i
}

keep iso year *wweal*

reshape long value data_quality s_, i(iso year) j(widcode) string

drop if value >= .

generate p = "pall"

gen ratios=1
tempfile ratios
save "`ratios'"
// -------------------------------------------------------------------------- //
// Other variables-income/product ratios (W) for PPP vars
// -------------------------------------------------------------------------- //
*Note: During aggegate macro regions the W variables are calculated for the MER regions
*      but not for the PPP ones, so this section completes the process

use "$work_data/complete-variables-output.dta", clear
*keep only regions PPP
keep if (inlist(substr(iso, 1, 1), "X", "O") & !inlist(iso,"OM","XI")) | inlist(substr(iso, 1, 2), "QL","QM","WO","QE","QF","QP")
keep if strpos(iso, "-PPP")
*Keep only relevant aggregates
keep if substr(widcode,1,1)=="m"
gen     flag=0
replace flag = 1 if   inlist(substr(widcode, 2, 5), "citgr", "comhn", "comnx", "compx", "comrx", "confc", "cwboo", "cwbus", "cwdeb")  ///
					| inlist(substr(widcode, 2, 5), "cwdeq", "cwfin", "cwhou", "cwnfa", "cwres", "defge", "ecoge", "edpge", "edsge")  ///
					| inlist(substr(widcode, 2, 5), "edtge", "eduge", "envge", "expgo", "fdinx", "fdipx", "fdirx", "fdixa", "fdixd")  
replace flag = 1 if   inlist(substr(widcode, 2, 5), "fdixn", "finpx", "finrx", "fkanx", "fkapx", "fkarx", "fkpin", "flcin", "flcip")  ///
					| inlist(substr(widcode, 2, 5), "flcir", "fsubx", "ftaxx", "gdpro", "gpsge", "gwbus", "gwdeb", "gweal", "gwfin")  ///
					| inlist(substr(widcode, 2, 5), "gwhou", "gwnfa", "heage", "houge", "hweal", "intgr", "iweal", "ncanx", "ndpro")  
replace flag = 1 if   inlist(substr(widcode, 2, 5), "nnfin", "nninc", "ntlcu", "ntrgr", "nwagr", "nwboo", "nwbus", "nwdka", "nweal")  ///
					| inlist(substr(widcode, 2, 5), "nwgxa", "nwgxd", "nwhou", "nwnfa", "nwnxa", "ottgr", "pinnx", "pinpx", "pinrx")  ///
					| inlist(substr(widcode, 2, 5), "pitgr", "polge", "psugo", "ptdpx", "ptdrx", "ptdxa", "ptdxd", "ptepx", "pterx")  
replace flag = 1 if   inlist(substr(widcode, 2, 5), "ptexa", "ptexd", "ptfnx", "ptfpx", "ptfrn", "ptfrp", "ptfrr", "ptfrx", "ptfxa")  ///
					| inlist(substr(widcode, 2, 5), "ptfxd", "ptfxn", "ptrrx", "ptrxa", "pwagr", "pwbus", "pwdeb", "pweal", "pweqi")  ///
					| inlist(substr(widcode, 2, 5), "pwfin", "pwfiw", "pwhou", "pwnfa", "pwodk", "pwpen", "pwtgr", "recge", "retgo")  
replace flag = 1 if   inlist(substr(widcode, 2, 5), "revgo", "sacge", "sakge", "scgnx", "scgpx", "scgrx", "scinx", "scipx", "scirx")  ///
					| inlist(substr(widcode, 2, 5), "scogr", "sconx", "scopx", "scorx", "scrnx", "scrpx", "scrrx", "sopge", "spige")  ///
					| inlist(substr(widcode, 2, 5), "taxnx", "tbmpx", "tbnnx", "tbxrx", "tgmcx", "tgmmx", "tgmpx", "tgncx", "tgnmx")  
replace flag = 1 if   inlist(substr(widcode, 2, 5), "tgnnx", "tgxcx", "tgxmx", "tgxrx", "tsmpx", "tsnnx", "tsonx", "tsopx", "tsorx")  ///
					| inlist(substr(widcode, 2, 5), "tstnx", "tstpx", "tstrx", "tsvnx", "tsvpx", "tsvrx", "tsxrx")  

replace flag= 1 if    inlist(substr(widcode, 2, 5), "ptxgo", "gvato", "gvago", "ceugo", "gsrgo", "nsrgo", "cfcgo", "gvaco") | ///
				      inlist(substr(widcode, 2, 5), "ceuco", "gsrco", "nsrco", "cfcco", "gvahn", "ceuhn", "gmxhn", "nmxhn") | ///
				      inlist(substr(widcode, 2, 5), "ccmhn", "gsrhn", "nsrhn", "ccshn")
					  
replace flag= 1 if    inlist(substr(widcode, 1, 6), "ylsgdp", "ylsndp", "ycsgdp", "ycsndp", "wlsgni", "wlsnni", "wcsgni") | ///
					  inlist(substr(widcode, 1, 6), "wcsnni", "ylscgv", "ylscnv", "ycscgv", "ycscnv", "yconfc")	
					  
replace flag= 1 if 	  inlist(substr(widcode, 1, 6), "mpweal", "mhweal", "miweal", "mgweal", "mnweal", "mnninc")
keep if flag==1
drop flag

* Separete the nninc for W and the gdpro for Y
preserve          
	drop currency p s_
	keep if inlist(widcode,"mnninc999i","mgdpro999i") 

	reshape wide value data_quality, i(iso year) j (widcode) string
	rename (*mnninc999i *mgdpro999i)(*w *y)
	
	
	tempfile denominators
	save `denominators'
restore
merge m:1 iso year using "`denominators'", nogen

* Calculate ratios
gen        value_y=value/valuey // for Y
gen data_quality_y=data_qualityy // for Y
gen            s__y=s_ // for Y
gen        value_w=value/valuew // for W
gen data_quality_w=data_qualityw // for W
gen           s__w=s_ // for W

keep iso year p widcode currency *_y *_w

* Format
reshape long value s_ data_quality, i(iso year widcode p currency) j(ratio) string
replace widcode= substr(ratio,2,1) +substr(widcode,2,.)
drop ratio 
drop  if inlist(widcode,"wnninc999i","ygdpro999i") // ilogical values

gen full_ppp=1

tempfile full_ppp
save `full_ppp'

// -------------------------------------------------------------------------- //
// Labor/capital share
// -------------------------------------------------------------------------- //
/*
use "$work_data/complete-variables-output.dta", clear

keep if inlist(widcode, "mfkpin999i", "mnmxho999i", "mcomhn999i")
greshape wide value, i(iso year) j(widcode) string

generate valuewlabsh999i = (valuemcomhn999i + 0.7*valuemnmxho999i)/(valuemcomhn999i + valuemfkpin999i + valuemnmxho999i)
generate valuewcapsh999i = (valuemfkpin999i + 0.3*valuemnmxho999i)/(valuemcomhn999i + valuemfkpin999i + valuemnmxho999i)
keep iso year p valuew*

greshape long value, i(iso year) j(widcode) string

tempfile shares
save "`shares'"
*/
// -------------------------------------------------------------------------- //
// Combine
// -------------------------------------------------------------------------- //

use "$work_data/complete-variables-output.dta", clear
append using "`ratios'"

duplicates tag iso year p widcode, gen(dup)
drop if ratios==1 & dup==1
drop ratios dup

*append using "`shares'"
append using "`full_ppp'"

duplicates tag iso year p widcode, gen(dup)
drop if full_ppp==1 & dup==1
drop full_ppp dup

drop if missing(value)
duplicates drop iso year p widcode, force

//0 values can be the result of missing info
replace value=. if inlist(substr(widcode,1,1),"y", "w") & value==0 //& year<1970
drop if missing(value)

compress
label data "Generated by calculate-wealth-income-ratios.do"
save "$work_data/calculate-wealth-income-ratio-output.dta", replace


// -------------------------------------------------------------------------- //
// Add metadata
// -------------------------------------------------------------------------- //
/*
use "`ratios'", clear
append using "`shares'"

generate sixlet = substr(widcode, 1, 6)

generate source = "WID.world estimates based on macro aggregates: see method and corresponding macro variables for details."
generate method = ""
replace method = "Capital share defined as the ratio of pure capital income and 30% of mixed income over factor price national income. See [URL][URL_LINK]https://wid.world/document/distributional-national-accounts-guidelines-2020-concepts-and-methods-used-in-the-world-inequality-database/[/URL_LINK][URL_TEXT]DINA Guidelines[/URL_TEXT][/URL] for details." if sixlet == "wcapsh"
replace method = "Labor share defined as the ratio of compensation of employees and 70% of mixed income over factor price national income. See [URL][URL_LINK]https://wid.world/document/distributional-national-accounts-guidelines-2020-concepts-and-methods-used-in-the-world-inequality-database/[/URL_LINK][URL_TEXT]DINA Guidelines[/URL_TEXT][/URL] for details." if sixlet == "wlabsh"
replace method = "Public wealth-to-income ratio defined as the ratio of government wealth to market-price national income. See [URL][URL_LINK]https://wid.world/document/distributional-national-accounts-guidelines-2020-concepts-and-methods-used-in-the-world-inequality-database/[/URL_LINK][URL_TEXT]DINA Guidelines[/URL_TEXT][/URL] for details." if sixlet == "wwealg"
replace method = "Household wealth-to-income ratio defined as the ratio of household wealth to market-price national income. See [URL][URL_LINK]https://wid.world/document/distributional-national-accounts-guidelines-2020-concepts-and-methods-used-in-the-world-inequality-database/[/URL_LINK][URL_TEXT]DINA Guidelines[/URL_TEXT][/URL] for details." if sixlet == "wwealh"
replace method = "Nonprofit wealth-to-income ratio defined as the ratio of NPISH wealth to market-price national income. See [URL][URL_LINK]https://wid.world/document/distributional-national-accounts-guidelines-2020-concepts-and-methods-used-in-the-world-inequality-database/[/URL_LINK][URL_TEXT]DINA Guidelines[/URL_TEXT][/URL] for details." if sixlet == "wweali"
replace method = "National wealth-to-income ratio defined as the ratio of market-price national wealth to market-price national income. See [URL][URL_LINK]https://wid.world/document/distributional-national-accounts-guidelines-2020-concepts-and-methods-used-in-the-world-inequality-database/[/URL_LINK][URL_TEXT]DINA Guidelines[/URL_TEXT][/URL] for details." if sixlet == "wwealn"
replace method = "Private wealth-to-income ratio defined as the ratio of household and NPISH wealth to market-price national income. See [URL][URL_LINK]https://wid.world/document/distributional-national-accounts-guidelines-2020-concepts-and-methods-used-in-the-world-inequality-database/[/URL_LINK][URL_TEXT]DINA Guidelines[/URL_TEXT][/URL] for details." if sixlet == "wwealp"

keep iso sixlet source method
gduplicates drop

append using "$work_data/complete-variables-metadata.dta", gen(old)

gduplicates tag iso sixlet, gen(dup)
drop if old & dup
drop old dup

save "$work_data/calculate-wealth-income-ratio-metadata.dta", replace

*/
