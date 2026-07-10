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


greshape wide value data_quality s_, i(iso year p currency) j(widcode) string
rename (value* data_quality*) (* q_*)


* Calculate shares
** NDPRO
gen ndp_fp = yceugo999i + ynsrgo999i + yceuco999i + yceuhn999i + ynsrco999i + ynmxhn999i + ynsrhn999i
** GNI
gen gni_fp = ygvato999i + ycomnx999i + ypinnx999i // since pinnx comnx available (normally 1970 u 80 for non-core countries)
** NNI
gen nni_fp = ndp_fp + ycomnx999i + ypinnx999i // since pinnx comnx available (normally 1970 u 80 for non-core countries)

* Labor share of total (factor-price) GDP
gen   ylsgdp999i = (yceugo999i + yceuco999i + yceuhn999i + 0.6*ygmxhn999i) / ygvato999i
quality yceugo999i yceuco999i yceuhn999i ygmxhn999i, gen(q_ylsgdp999i)  weights(1 1 1 .6)
gen s_ylsgdp999i = "(ceugo+ceuco+ceuhn+0.6*gmxhn)/gvato"
*Labor share of total (factor-price) NDP
gen   ylsndp999i = (yceugo999i + yceuco999i + yceuhn999i + 0.6*ygmxhn999i) / ndp_fp
quality yceugo999i yceuco999i yceuhn999i ygmxhn999i, gen(q_ylsndp999i) weights(1 1 1 .6)
gen s_ylsndp999i = "(ceugo+ceuco+ceuhn+0.6*gmxhn)/ndpro(FactorPrice)"
*Capital share of total (factor-price) GDP
gen   ycsgdp999i =  (ygsrco999i + ygsrhn999i + ygsrgo999i + 0.4*ygmxhn999i)/ ygvato999i
quality ygsrco999i ygsrhn999i ygsrgo999i ygmxhn999i, gen(q_ycsgdp999i) weights(1 1 1 .4)
gen s_ycsgdp999i =  "(gsrco+gsrhn+gsrgo+0.4*gmxhn)/gvato"
*Capital share of total (factor-price) NDP
gen   ycsndp999i =  (ynsrco999i + ynsrhn999i + ynsrgo999i + (0.4*ygmxhn999i - yccmhn999i)) / ndp_fp
quality ynsrco999i ynsrhn999i ynsrgo999i ygmxhn999i yccmhn999i, gen(q_ycsndp999i) weights(1 1 1 .4 1)
gen s_ycsndp999i =  "(nsrco+nsrhn+nsrgo+(0.4*gmxhn-ccmhn))/ndpro(FactorPrice)"

*Labor share in corporate (factor-price) GVA
gen   ylscgv999i = yceuco999i / (yceuco999i + ygsrco999i)
gen q_ylscgv999i = q_yceuco999i 
gen s_ylscgv999i = "ceuco/(ceuco+gsrco)"
* Labor share in corporate (factor-price) NVA
gen   ylscnv999i = yceuco999i / (yceuco999i + ynsrco999i)
gen q_ylscnv999i = q_yceuco999i 
gen s_ylscnv999i = "ceuco/(ceuco+nsrco)"
*Capital share in corporate (factor-price) GVA
gen   ycscgv999i = ygsrco999i / (yceuco999i + ygsrco999i)
gen q_ycscgv999i = q_ygsrco999i 
gen s_ycscgv999i = "gsrco/(ceuco+gsrco)"
*Capital share in corporate (factor-price) NVA
gen   ycscnv999i = ynsrco999i / (yceuco999i + ynsrco999i)
gen q_ycscnv999i = q_ynsrco999i 
gen s_ycscnv999i = "nsrco/(ceuco+nsrco)"

*Labor share of total (factor-price) GNI
gen   wlsgni999i = (yceugo999i + yceuco999i + yceuhn999i + ycomnx999i + 0.6*ygmxhn999i) / gni_fp
quality yceugo999i yceuco999i yceuhn999i ycomnx999i ygmxhn999i, gen(q_wlsgni999i) weights(1 1 1 1 .6)
gen s_wlsgni999i = "(ceugo+ceuco+ceuhn+comnx+0.6*gmxhn)/(gvato+comnx+pinnx)"
*Labor share of total (factor-price) NNI
gen   wlsnni999i = (yceugo999i + yceuco999i + yceuhn999i + ycomnx999i + 0.6*ygmxhn999i) / nni_fp
quality yceugo999i yceuco999i yceuhn999i ycomnx999i ygmxhn999i, gen(q_wlsnni999i) weights(1 1 1 1 .6)
gen s_wlsnni999i = "(ceugo+ceuco+ceuhn+comnx+0.6*gmxhn)/nninc(FactorPrice)"
*Capital share of total (factor-price) GNI
gen   wcsgni999i =  (ygsrco999i + ygsrhn999i + ygsrgo999i + ypinnx999i + 0.4*ygmxhn999i) / gni_fp
quality ygsrco999i ygsrhn999i ygsrgo999i ypinnx999i ygmxhn999i, gen(q_wcsgni999i) weights(1 1 1 1 .4)
gen s_wcsgni999i =  "(gsrco+gsrhn+gsrgo+pinnx+0.4*gmxhn)/(gvato+comnx+pinnx)"
*Capital share of total (factor-price) NNI
gen   wcsnni999i =  (ynsrco999i + ynsrhn999i + ynsrgo999i + ypinnx999i + (0.4*ygmxhn999i - yccmhn999i)) / nni_fp
quality ynsrco999i ynsrhn999i ynsrgo999i ypinnx999i ygmxhn999i yccmhn999i, gen(q_wcsnni999i) weights(1 1 1 1 .4 1)
gen s_wcsnni999i =  "(nsrco+nsrhn+nsrgo+pinnx+(0.4*gmxhn-ccmhn))/nninc(FactorPrice)"

keep iso year p currency *ylsgdp999i *ylsndp999i *ycsgdp999i *ycsndp999i *wlsgni999i *wlsnni999i *wcsgni999i *wcsnni999i *ylscgv999i *ylscnv999i *ycscgv999i *ycscnv999i

rename (yl* yc* w*) (valueyl* valueyc* valuew*)

greshape long value q_ s_, i(iso year p currency) j(widcode) string
rename q_ data_quality
drop if missing(value)

gen new=1

tempfile factorshares
save `factorshares'

//------  2. Complete  wealth aggregates -------------------------------------//
use "$work_data/calculate-real-exchange-rate-output.dta", clear

keep if (substr(widcode, 2, 2) == "nw") & inlist(substr(widcode,1,1),"m","y","w")

greshape wide value data_quality s_, i(iso year p currency) j(widcode) string
rename (value* data_quality*) (* q_*)

foreach c in m y w {
	replace q_`c'nwhou999i = min(3, cond(`c'nwdwe999i>=`c'nwlan999i, q_`c'nwdwe999i, q_`c'nwlan999i))   if missing(`c'nwhou999i)
	replace s_`c'nwhou999i = "nwdwe,nwlan"                                                              if missing(`c'nwhou999i) & (!mi(`c'nwdwe999i) & !mi(`c'nwlan999i))
	replace `c'nwhou999i = `c'nwdwe999i + `c'nwlan999i                                                  if missing(`c'nwhou999i)

	quality `c'nwagr999i `c'nwodk999i `c'nwnat999i, gen(temp)
	replace q_`c'nwbus999i =temp                                                                        if missing(`c'nwbus999i)
	replace s_`c'nwbus999i = "nwagr,nwodk" + cond(missing(`c'nwnat999i), "", ",nwnat")                  if missing(`c'nwbus999i) &(!mi(`c'nwagr999i) & !mi(`c'nwodk999i))
	replace `c'nwbus999i = `c'nwagr999i + `c'nwodk999i + cond(missing(`c'nwnat999i), 0, `c'nwnat999i)   if missing(`c'nwbus999i)

	replace q_`c'nwnfa999i =min(3, cond(`c'nwhou999i >= `c'nwbus999i,  q_`c'nwhou999i, q_`c'nwbus999i)) if missing(`c'nwnfa999i)
	replace s_`c'nwnfa999i = "nwhou,nwbus999i"                                                          if missing(`c'nwnfa999i) & (!mi(`c'nwhou999i) & !mi(`c'nwbus999i))
	replace `c'nwnfa999i = `c'nwhou999i + `c'nwbus999i                                                  if missing(`c'nwnfa999i)
	drop temp
}
keep iso year p currency *nwhou* *nwbus* *nwnfa*
rename (ynw* mnw* wnw*) (valueynw* valuemnw* valuewnw*)
greshape long value q_ s_, i(iso year p currency) j(widcode) string
rename q_ data_quality
drop if missing(value)

gen new=1

tempfile completed
save `completed'
/*
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
*/
//------  4. Export ----------------------------------------------------------// 
use "$work_data/calculate-real-exchange-rate-output.dta", clear

* add new variables
append using "`completed'"
append using "`factorshares'"

* remove duplicates, keep new calculations
duplicates tag iso year widcode p, gen(dup)
drop if dup==1 & new!=1
duplicates tag iso year widcode p, gen(dup2)
assert dup2==0
drop dup* new

compress
label data "Generated by complete-variables.do"
save "$work_data/complete-variables-output.dta", replace
