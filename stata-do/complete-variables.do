//----------------------------------------------------------------------------//
//-------------------  Complete variables.Do ---------------------------------//
//----------------------------------------------------------------------------//


//------  1. Complete institutional factor shares (Dietrisch et al.2025) -----//
use "$work_data/calculate-real-exchange-rate-output.dta", clear

gen flag= 1 if inlist(widcode, "yndpro999i", "ynninc999i", "ygvato999i", "yptxgo999i", "ygvato999i", "ygvago999i", "yceugo999i", "ygsrgo999i", "ynsrgo999i") | ///
			   inlist(widcode, "ycfcgo999i", "ygvaco999i", "yceuco999i", "ygsrco999i", "ynsrco999i", "ycfcco999i", "ygvahn999i", "yceuhn999i", "ygmxhn999i") | ///
			   inlist(widcode, "ynmxhn999i", "yccmhn999i", "ygsrhn999i", "ynsrhn999i", "yccshn999i", "ypinnx999i", "ycomnx999i")
keep if flag==1
drop flag

greshape wide value, i(iso year p currency) j(widcode) string

* Calculate shares
gen ndp_fp = valueyceugo999i + valueynsrgo999i + valueyceuco999i+ valueyceuhn999i+ valueynsrco999i+ valueynmxhn999i+ valueynsrhn999i
gen gni_fp = valueygvato999i + valueycomnx999i + valueypinnx999i // since pinnx comnx available (normally 1970 u 80 for non-core countries)
gen nni_fp = ndp_fp + valueycomnx999i + valueypinnx999i // since pinnx comnx available (normally 1970 u 80 for non-core countries)

* Labor share of total (factor-price) GDP
gen valueylsgdp999i = (valueyceugo999i + valueyceuco999i + valueyceuhn999i + 0.6*valueygmxhn999i) / valueygvato999i
*Labor share of total (factor-price) NDP
gen valueylsndp999i = (valueyceugo999i + valueyceuco999i + valueyceuhn999i + 0.6*valueygmxhn999i) / ndp_fp
*Capital share of total (factor-price) GDP
gen valueycsgdp999i =  (valueygsrco999i + valueygsrhn999i + valueygsrgo999i + 0.4*valueygmxhn999i)/ valueygvato999i
*Capital share of total (factor-price) NDP
gen valueycsndp999i =  (valueynsrco999i + valueynsrhn999i + valueynsrgo999i + (0.4*valueygmxhn999i - valueyccmhn999i)) / ndp_fp

*Labor share in corporate (factor-price) GVA
gen valueylscgv999i = valueyceuco999i / (valueyceuco999i + valueygsrco999i)
* Labor share in corporate (factor-price) NVA
gen valueylscnv999i = valueyceuco999i / (valueyceuco999i + valueynsrco999i)
*Capital share in corporate (factor-price) GVA
gen valueycscgv999i = valueygsrco999i / (valueyceuco999i + valueygsrco999i)
*Capital share in corporate (factor-price) NVA
gen valueycscnv999i = valueynsrco999i / (valueyceuco999i + valueynsrco999i)

*Labor share of total (factor-price) GNI
gen valuewlsgni999i = (valueyceugo999i + valueyceuco999i + valueyceuhn999i + valueycomnx999i + 0.6*valueygmxhn999i) / gni_fp
*Labor share of total (factor-price) NNI
gen valuewlsnni999i = (valueyceugo999i + valueyceuco999i + valueyceuhn999i + valueycomnx999i + 0.6*valueygmxhn999i) / nni_fp
*Capital share of total (factor-price) GNI
gen valuewcsgni999i =  (valueygsrco999i + valueygsrhn999i + valueygsrgo999i + valueypinnx999i + 0.4*valueygmxhn999i) / gni_fp
*Capital share of total (factor-price) NNI
gen valuewcsnni999i =  (valueynsrco999i + valueynsrhn999i + valueynsrgo999i + valueypinnx999i + (0.4*valueygmxhn999i - valueyccmhn999i)) / nni_fp

keep iso year p currency valueylsgdp999i valueylsndp999i valueycsgdp999i valueycsndp999i valuewlsgni999i valuewlsnni999i valuewcsgni999i valuewcsnni999i valueylscgv999i valueylscnv999i valueycscgv999i valueycscnv999i

greshape long value, i(iso year p currency) j(widcode) string

drop if missing(value)

tempfile factorshares
save `factorshares'

//------  2. Complete  wealth aggregates -------------------------------------//
use "$work_data/calculate-real-exchange-rate-output.dta", clear

keep if (substr(widcode, 1, 3) == "mnw")

greshape wide value, i(iso year p currency) j(widcode) string

replace valuemnwhou = valuemnwdwe + valuemnwlan if missing(valuemnwhou)
replace valuemnwbus = valuemnwagr + valuemnwodk + cond(missing(valuemnwnat), 0, valuemnwnat) if missing(valuemnwbus)

replace valuemnwnfa = valuemnwhou + valuemnwbus if missing(valuemnwnfa)


greshape long value, i(iso year p currency) j(widcode) string
drop if missing(value)

tempfile completed
save `completed'

//------  3. Generate metadata -----------------------------------------------//  
keep iso widcode
generate sixlet = substr(widcode, 1, 6)
keep if inlist(sixlet, "mnwhou", "mnwbus", "mnwnfa")

// Associate codes of parent variables
replace sixlet = "mnwdwe" if sixlet == "mnwhou"
replace sixlet = "mnwodk" if sixlet == "mnwbus"
replace sixlet = "mnwdwe" if sixlet == "mnwnfa"

gduplicates drop

merge n:1 iso sixlet using "$work_data/calculate-real-exchange-rate-metadata-output.dta", nogenerate keep(master match)
replace sixlet = substr(widcode, 1, 6)
drop widcode
generate new = 1
// append using "$work_data/add-researchers-data-real-metadata.dta"
// append using "$work_data/add-wealth-distribution-metadata.dta"
//append using "$work_data/aggregate-regions-metadata-output.dta"
append using "$work_data/calculate-real-exchange-rate-metadata-output.dta"
replace new = 0 if missing(new)
gduplicates tag iso sixlet, gen(dup)
drop if new & dup
drop new dup
label data "Generated by complete-variables.do"
save "$work_data/complete-variables-metadata.dta", replace

//------  4. Export ----------------------------------------------------------// 
use "$work_data/calculate-real-exchange-rate-output.dta", clear
drop if (substr(widcode, 1, 3) == "mnw")

append using "`completed'"
append using "`factorshares'"

compress
label data "Generated by complete-variables.do"
save "$work_data/complete-variables-output.dta", replace
