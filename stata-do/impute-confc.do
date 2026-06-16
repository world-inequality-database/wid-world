// -------------------------------------------------------------------------- //
// Impute consumption of fixed capital
// -------------------------------------------------------------------------- //

// -------------------------------------------------------------------------- //
// Import explanatory variables: GDP per capita at PPP
// -------------------------------------------------------------------------- //

// PPPs
use "$work_data/ppp.dta", clear
keep if year == $pastyear
keep iso ppp
tempfile ppp
save "`ppp'"

// Populations
use "$work_data/populations.dta", clear
keep if widcode == "npopul999i"
keep iso year value
rename value pop
tempfile pop
save "`pop'"

// GDP
use "$work_data/retropolate-gdp.dta", clear
keep iso year gdp currency
merge 1:1 iso year using "$work_data/sna-combined.dta", keep(master match) keepusing(confc series_confc q_confc s_confc) nogenerate

merge n:1 iso      using "`ppp'", keep(master match) nogenerate
merge n:1 iso year using "`pop'", keep(master match) nogenerate

// Simple imputation based on countries with same currency for missin PPPs
gegen   ppp2 = median(ppp), by(currency)
replace ppp  = ppp2 if mi(ppp)
drop ppp

// Last resort: use exchange rate
preserve
	use "$work_data/exchange-rates.dta", clear
	keep if year == $pastyear
	rename exrate_usd mer
	collapse (mean) mer, by(currency)
	tempfile mer
	save "`mer'"
restore

merge n:1 currency using "`mer'", nogenerate keep(master match)
replace ppp = mer if mi(ppp)
assert !missing(ppp)

// We smooth the GDP variable using Hodrick-Prescott filter so that the
// imputation is not affected by short-term fluctuations
generate log_gdp = log(gdp)
drop if (log_gdp >= .)
// Create categories of contiguous years
sort iso year
by iso: generate categ = sum(year != year[_n - 1] + 1)
egen id = group(iso categ)
drop categ
// Create a panel of continuous time series
xtset id year, yearly
// Apply filter
generate log_gdp_hp = .
quietly levelsof id if (log_gdp < .), local(id_list)
foreach id of local id_list {
	quietly count if (id == `id')
	if (r(N) > 2) {
		tempvar cycle trend
		tsfilter hp `cycle' = log_gdp if (id == `id'), trend(`trend')
		replace log_gdp_hp = `trend' if (id == `id')
		drop `cycle' `trend'
	}
	else {
		replace log_gdp_hp = log_gdp if (id == `id')
	}
}

// Graph GDP series
if ($plot_imputation_cfc) {
	capture mkdir "$report_output/impute-cfc"
	quietly levelsof iso if (log_gdp < .), local(iso_list)
	foreach iso of local iso_list {
		graph twoway connected log_gdp_hp log_gdp year if (iso == "`iso'"), ///
			title("Real Gross Domestic Product") subtitle("`iso'") ///
			xscale(range(1810 $pastyear)) xlabel(1810(10)$pastyear, angle(vertical)) ///
			xtitle("Year") ytitle("log(real GDP)") symbol(none none) ///
			legend(order(1 "Filtered GDP" 2 "Raw GDP"))
		graph export "$report_output/impute-cfc/gdp-`iso'.pdf", replace
		graph close
	}
}

// -------------------------------------------------------------------------- //
// Estimate model
// -------------------------------------------------------------------------- //

// Smooth GDP per capita at PPP
generate x = log_gdp_hp - log(ppp) - log(pop)
// Calculate CFC as a % of filtered GDP
generate y = log(confc*gdp) - log_gdp_hp

// Set the panel
encode2 iso
tsset iso year, yearly
tsfill, full

// Polynomial for explanatory variable
forvalues i = 1/2 {
	generate x`i' = x^`i'/10^(`i' - 1)
}

// Estimate random effect model with AR(1) error term for CFC
cap drop u
xtregar y x?, re

// Store parameters
local rho     = e(rho_ar)
local sigma_u = e(sigma_u)
// Stata is quite confusing here: "e" refers to the error term that follows the
// AR(1) process, but "sigma_e" refers to the residual of the AR(1) process
local sigma_eta = e(sigma_e)
// Random effect and error term
predict xb, xb
// Simple estimation of the random effect (more robust than 'predict' when few data points)
egen u        = mean(y - xb), by(iso)
generate varu = cond(u < ., 0, `sigma_u'^2)
replace u     = 0 if (u >= .)
generate e    = y - xb - u

// Check whitening of residuals
if ($plot_imputation_cfc) {
	generate      eta = e - `rho'*L.e
	matrix define ac1 = J(1, 10, .)
	matrix define ac2 = J(1, 10, .)
	forvalues i = 1/10 {
		corr e L`i'.e
		matrix define sigma = r(C)
		matrix ac1[1, `i']  = sigma[1, 2]
		
		corr eta L`i'.eta
		matrix define sigma = r(C)
		matrix ac2[1, `i']  = sigma[1, 2]
	}
	matrix list ac1
	matrix list ac2
	coefplot (matrix(ac1[1, ])) (matrix(ac2[1, ])), vertical recast(dropline) ///
		coeflabel(c1 = "1" c2 = "2" c3 = "3" c4 = "4" c5 = "5" c6 = "6" ///
			c7 = "7" c8 = "8" c9 = "9" c10 = "10") format(%2.1f) ///
		ytitle("Correlation coefficient") xtitle("Number of lags") ///
		plotlabel("ε" "η") title("Autocorrelation of residuals") ///
		subtitle("Imputation of CFC") yscale(range(0 1)) ylabel(0(0.2)1)
	graph export "$report_output/impute-cfc/autocorrelation-cfc.pdf", replace
	graph close
	drop eta
}

// -------------------------------------------------------------------------- //
// Use model to perform imputation
// -------------------------------------------------------------------------- //

// Zero conditional variance when the cfc is observed
generate vare = 0 if (e < .)
// When CFC is never observed, we impute the value of the stationary process
egen  hascfc = total(y < .), by(iso)
replace    e = 0 if (!hascfc)
replace vare = `sigma_eta'^2/(1 - `rho'^2) if (!hascfc)
replace varu = `sigma_u'^2 if (!hascfc)
// When some CFCs are observed, divide time in segments of contiguous
// observations with or without observed CFC
sort iso year
by iso: generate segment = sum((y < .) != (y[_n - 1] < .))
egen    minseg = min(segment), by(iso)
egen    maxseg = max(segment), by(iso)
egen seghascfc = total(y < .), by(iso segment)
sort iso segment year
by iso segment: generate t = _n
by iso segment: generate T = _N
by iso: generate        e0 = e[_n - 1]
by iso: generate        eF = e[_n + 1]
by iso segment: replace e0 = e0[1]
by iso segment: replace eF = eF[_N]
// Extrapolate e into the future
replace    e = `rho'^t*e0 if (hascfc) & (segment == maxseg) & (!seghascfc)
replace vare = `sigma_eta'^2*(1 - `rho'^(2*t))/(1 - `rho'^2) ///
	if (hascfc) & (segment == maxseg) & (!seghascfc)
// Extrapolate e into the past
replace    e = `rho'^(T + 1 - t)*eF if (hascfc) & (segment == minseg) & (!seghascfc)
replace vare = `sigma_eta'^2*(1 - `rho'^(2*(T + 1 - t)))/(1 - `rho'^2) ///
	if (hascfc) & (segment == minseg) & (!seghascfc)
// Interpolate in the gaps
sort iso segment year
replace    e = `rho'^t*e0 + (eF - `rho'^(T+1)*e0)*`rho'^(T + 1 - t)*(1 - `rho'^(2*t))/(1 - `rho'^(2*(T+1))) ///
	if (hascfc) & !inlist(segment, minseg, maxseg) & (!seghascfc)
replace vare = `sigma_eta'^2*(1 - `rho'^(2*t))*(1 - `rho'^(2*(T + 1 - t)))/((1 - `rho'^2)*(1 - `rho'^(2*(T + 1)))) ///
	if (hascfc) & !inlist(segment, minseg, maxseg) & (!seghascfc)

drop hascfc segment minseg maxseg seghascfc t T e0 eF

// Predict actual value (best prediction, 80% prediction interval)
generate cfc_pct_hp_pred = exp(xb + u + e + 0.5*(varu + vare))
generate cfc_pct_hp_lb   = exp(xb + u + e - 1.281551565545*sqrt(varu + vare))
generate cfc_pct_hp_ub   = exp(xb + u + e + 1.281551565545*sqrt(varu + vare))

generate cfc_pred = cfc_pct_hp_pred * exp(log_gdp_hp)
generate cfc_lb   = cfc_pct_hp_lb   * exp(log_gdp_hp)
generate cfc_ub   = cfc_pct_hp_ub   * exp(log_gdp_hp)

generate cfc_pct_pred = cfc_pred/gdp
generate cfc_lb_pred  = cfc_lb/gdp
generate cfc_ub_pred  = cfc_ub/gdp

replace      q_confc = 2            if missing(confc) & !missing(cfc_pct_pred)
replace      s_confc = "regression" if missing(confc) & !missing(cfc_pct_pred)
replace series_confc = -1           if missing(confc)
replace        confc = cfc_pct_pred if missing(confc)

// Correct very low cfc values by threshold
replace q_confc = 0         if (confc < 0.05 & year >= 1980)
replace s_confc = "assumed" if (confc < 0.05 & year >= 1980)
replace   confc = 0.05      if (confc < 0.05 & year >= 1980)
replace q_confc = 0         if (confc < 0.04 & year < 1980 & year >= 1950) 
replace s_confc = "assumed" if (confc < 0.04 & year < 1980 & year >= 1950) 
replace   confc = 0.04      if (confc < 0.04 & year < 1980 & year >= 1950) 

// Plot CFC series
global plot_imputation_cfc 0
if ($plot_imputation_cfc) {
	foreach v of varlist cfc_pct_pred cfc_lb_pred cfc_ub_pred {
		replace `v' = `v'*100
	}
	quietly levelsof iso if (cfc_pct_pred < .), local(iso_list)
	foreach iso of local iso_list {
		local cc: label iso `iso'
		graph twoway (rarea cfc_lb_pred cfc_ub_pred year, color("166 206 227") lwidth(0), if (iso == `iso')) ///
			(line cfc_pct_pred year, color("8 48 107"), if (iso == `iso')) ///
			(scatter cfc_pct_pred year, msymbol(O..) color("8 48 107") msize(tiny), if (iso == `iso') & (series < 10) & (series > 0)), ///
			ytitle("% of GDP") yscale(range(0 45)) ylabel(0(5)45, format(%2.0f)) ///
			xscale(range(1810 $pastyear)) xlabel(1810(10)$pastyear, angle(vertical)) ///
			legend(order(2 "Consumption of fixed capital" 1 "80% prediction interval")) ///
			title("Imputation of the consumption of fixed capital") subtitle("`cc'")
		graph export "$report_output/impute-cfc/cfc-imputation-`cc'.pdf", replace
		graph close
	}
}
global plot_imputation_cfc 0

drop e u varu vare xb
decode2 iso

keep iso year confc series_confc q_confc s_confc

keep if !missing(confc)

// fixing North Korea
replace q_confc = .  if iso == "KP" & inlist(year, 2002, 2003)
replace s_confc = "" if iso == "KP" & inlist(year, 2002, 2003)
replace   confc = .  if iso == "KP" & inlist(year, 2002, 2003)
sort iso year
by iso : ipolate confc year if iso == "KP", gen(xconfc)
replace q_confc = 3       if missing(confc) & iso == "KP" 
replace s_confc = "ipol" if missing(confc) & iso == "KP" 
replace   confc = xconfc  if missing(confc) & iso == "KP" 

// fixing Oman
replace q_confc = .  if iso == "OM" & inlist(year, 1964)
replace s_confc = "" if iso == "OM" & inlist(year, 1964)
replace   confc = .  if iso == "OM" & inlist(year, 1964)
sort iso year
by iso : ipolate confc year if iso == "OM", gen(yconfc)
replace q_confc = 3      if missing(confc) & iso == "OM" 
replace s_confc = "ipol" if missing(confc) & iso == "OM" 
replace   confc = yconfc if missing(confc) & iso == "OM" 
drop yconfc

*label data "Generated by impute-confc.do"
*save "$work_data/confc-imputed.dta", replace
tempfile confc_imputed
save    `confc_imputed'

// -------------------------------------------------------------------------- //
// Split CFC within institutional sectors
// -------------------------------------------------------------------------- //
use "$work_data/sna-combined.dta", clear
drop confc s_confc q_confc

merge 1:1 iso year using "`confc_imputed'", nogenerate

// Flag to indicate that we force original CFC values to be replaced by the
// imputation (when CFC values are absurd)
generate toreplace = 0

// -------------------------------------------------------------------------- //
// Start with CFC of the government sector
// -------------------------------------------------------------------------- //

replace q_cfcgo = min(3,q_gsrgo) if missing(cfcgo) & !missing(gsrgo)
replace s_cfcgo = "gsrgo"        if missing(cfcgo) & !missing(gsrgo)
replace   cfcgo = gsrgo          if missing(cfcgo)

// Countries with cfcgo too high vs. confc: top-code cfcgo at 75% of total CFC
generate flag = (cfcgo >= 0.75*confc) & !missing(cfcgo)

generate old_cfcgo = max(cfcgo, 0)
replace q_cfcgo = 1                  if flag & !missing(confc)
replace s_cfcgo = "assumedconfc0.75" if flag & !missing(confc)
replace   cfcgo = 0.75*confc         if flag
replace q_nsrgo = 0          if flag
replace s_nsrgo = "assumed0" if flag
replace   nsrgo = 0          if flag
replace q_gsrgo = min(3, q_cfcgo) if flag & !missing(cfcgo)
replace s_gsrgo = "cfcgo"         if flag & !missing(cfcgo)
replace   gsrgo =  cfcgo          if flag
drop old_cfcgo

replace toreplace = 1 if flag
drop flag
		
// Country with cfcgo too low vs confc: bottom-code at 10% of total CFC:
// we do that by adusting GDP upward too (more cfcgo => more gsrgo)
generate flag = (cfcgo <= 0.10*confc) & !missing(cfcgo)

generate old_cfcgo = max(cfcgo, 0)
replace q_cfcgo = 1                  if flag & !missing(confc)
replace s_cfcgo = "assumedconfc0.10" if flag & !missing(confc)
replace   cfcgo = 0.10*confc         if flag
replace q_nsrgo = 0          if flag
replace s_nsrgo = "assumed0" if flag
replace   nsrgo = 0          if flag
replace q_gsrgo = min(3, q_cfcgo) if flag & !missing(cfcgo)
replace s_gsrgo = "cfcgo"         if flag & !missing(cfcgo)
replace   gsrgo =  cfcgo          if flag
drop old_cfcgo

replace toreplace = 1 if flag
drop flag

// Impute cfcgo
replace q_cfcgo = min(3, q_gsrgo) if missing(cfcgo) & !missing(gsrgo) 
replace s_cfcgo = "gsrgo"         if missing(cfcgo) & !missing(gsrgo)
replace   cfcgo = gsrgo           if missing(cfcgo) // In general, nsrgo = 0
gegen   median_cfcgo1 = median(cfcgo/confc), by(iso)
gegen   median_cfcgo2 = median(cfcgo/confc)
replace q_cfcgo = min(3, q_confc)                    if missing(cfcgo) & !missing(confc) & !missing(median_cfcgo1)
replace s_cfcgo = "confc_median[cfcgo/confc]iso"+iso if missing(cfcgo) & !missing(confc) & !missing(median_cfcgo1)
replace   cfcgo = confc*median_cfcgo1                if missing(cfcgo)
replace q_cfcgo = min(3, q_confc)                    if missing(cfcgo) & !missing(confc) & !missing(median_cfcgo2)
replace s_cfcgo = "confc_median[cfcgo/confc]isoWO"   if missing(cfcgo) & !missing(confc) & !missing(median_cfcgo2)
replace   cfcgo = confc*median_cfcgo2                if missing(cfcgo)

// Then split remaining CFC between households and corporations
generate q_cfc_private = min(3, cond(confc >= cfcgo,q_confc, q_cfcgo))  if !missing(confc) & !missing(cfcgo)
generate s_cfc_private = "confc,cfcgo"                                  if !missing(confc) & !missing(cfcgo)
generate   cfc_private = confc - cfcgo

foreach v of varlist cfchn cfcco {
	gen   share = `v'/cfc_private
	gen s_share = "`v'/cfc-private" if !missing(share)
	
	replace   share = 0.95          if share >= 0.95 & !missing(share)
	replace s_share = "assumed0.95" if share >= 0.95 & !missing(share)
	replace   share = 0.05          if share <= 0.05 & !missing(share)
	replace s_share = "assumed0.05" if share <= 0.05 & !missing(share)
	
	gegen share1 = median(share), by(iso)
	gegen share2 = median(share)
	
	replace share = share1                    if missing(share)
	replace share = share2                    if missing(share)
	
	replace s_share = "median[`v'/cfc-private]"        if !missing(share)
	replace s_share = "median[`v'/cfc-private]iso("+iso+")"  if missing(s_share) | !missing(share1)
	replace s_share = "median[`v'/cfc-private]iso(WO)"   if missing(s_share) | !missing(share2)
	
	replace q_`v' = min(3, q_`v')               if !missing(cfc_private) & !missing(share)
	replace s_`v' = "cfc-private_ratio"+s_share if !missing(cfc_private) & !missing(share)
	replace   `v' = share*cfc_private
	
	drop share share1 share2 s_share
}
drop cfc_private

// Split CFC between financial and non-financial corporations
foreach v of varlist cfcnf cfcfc {
	generate share = `v'/cfcco
	gen s_share = ""
	
	replace share = 0.99            if share >= 0.99 & !missing(share)
	replace s_share = "assumed0.99" if share >= 0.99 & !missing(share)
	replace share = 0.01            if share <= 0.01 & !missing(share)
	replace s_share = "assumed0.01" if share <= 0.01 & !missing(share)
	
	gegen share1 = median(share), by(iso)
	gegen share2 = median(share)
	
	replace share = share1             if missing(share)
	replace share = share2             if missing(share)
	
	replace s_share = "median[`v'/cfcco]"          if !missing(share)
	replace s_share = "median[`v'/cfcco]iso("+iso+")" if missing(s_share) | !missing(share1)
	replace s_share = "median[`v'/cfcco]iso(WO)"      if missing(s_share) | !missing(share2)
	
	replace q_`v' = min(3, q_cfcco) if !missing(cfcco)
	replace s_`v' = "cfcco_ratio"+s_share if !missing(cfcco)
	replace   `v' = share*cfcco
	
	drop share share1 share2  s_share
}

// Split CFC between households and NPISH
foreach v of varlist cfcnp cfcho {
	generate share = `v'/cfchn
	gen s_share = "" 
	
	replace   share = 0.99          if share >= 0.99 & !missing(share)
	replace s_share = "assumed0.99" if share >= 0.99 & !missing(share)
	replace   share = 0.01          if share <= 0.01 & !missing(share)
	replace s_share = "assumed0.01" if share <= 0.01 & !missing(share)
	
	gegen share1 = median(share), by(iso)
	gegen share2 = median(share)
	
	replace share = share1 if missing(share)
	replace share = share2 if missing(share)
	
	replace s_share = "median[`v'/cfchn]"          if !missing(share)
	replace s_share = "median[`v'/cfchn]iso("+iso+")" if missing(s_share) | !missing(share1)
	replace s_share = "median[`v'/cfchn]iso(WO)"      if missing(s_share) | !missing(share2)
	
	replace q_`v' = min(q_`v', q_cfchn) if !missing(cfchn)
	replace s_`v' = "cfchn_ratio"+s_share if !missing(cfchn)
	replace   `v' = share*cfchn
	
	drop share share1 share2  s_share
}

// Split CFC between operating surplus and mixed income
quality cfcho gsrho gmxho, gen(temp1)
replace q_ccsho = temp1                           if missing(ccsho)
replace s_ccsho = "cfcho*gsrho/(gsrho+0.3gmxho)"  if missing(ccsho)
replace   ccsho = cfcho*gsrho/(gsrho + 0.3*gmxho) if missing(ccsho)
quality cfcho gmxho gsrho, gen(temp2)
replace q_ccmho = temp2                               if missing(ccmho)
replace s_ccmho = "cfcho*0.3gmxho/(gsrho+0.3gmxho)"   if missing(ccmho)
replace   ccmho = cfcho*0.3*gmxho/(gsrho + 0.3*gmxho) if missing(ccmho)

quality cfcho nsrho nmxho, gen(temp3)
replace q_ccsho = temp3                           if missing(ccsho)
replace s_ccsho = "cfcho*nsrho/(nsrho+0.3nmxho)"  if missing(ccsho)
replace   ccsho = cfcho*nsrho/(nsrho + 0.3*nmxho) if missing(ccsho)
quality cfcho nmxho nsrho, gen(temp4)
replace q_ccmho = temp4                               if missing(ccmho)
replace s_ccmho = "cfcho*0.3nmxho/(nsrho+0.3nmxho)"   if missing(ccmho)
replace   ccmho = cfcho*0.3*nmxho/(nsrho + 0.3*nmxho) if missing(ccmho)

replace q_ccshn = min(3, cond(ccsho >= cfcnp, q_ccsho, q_cfcnp)) if missing(ccshn)
replace s_ccshn = "ccsho,cfcnp"                                  if missing(ccshn)
replace   ccshn = ccsho + cfcnp                                  if missing(ccshn)
replace q_ccmhn = min(3,q_ccmho) if missing(ccmhn)
replace s_ccmhn = "ccmho"        if missing(ccmhn)
replace   ccmhn = ccmho          if missing(ccmhn)

quality cfchn gsrhn gmxhn, gen(temp5)
replace q_ccshn = temp5                           if missing(ccshn)
replace s_ccshn = "cfchn*gsrhn/(gsrhn+0.3gmxhn)"  if missing(ccshn)
replace   ccshn = cfchn*gsrhn/(gsrhn + 0.3*gmxhn) if missing(ccshn)
quality cfchn gmxhn gsrhn, gen(temp6)
replace q_ccmhn = temp6                               if missing(ccmhn)
replace s_ccmhn = "cfchn*0.3gmxhn/(gsrhn+0.3gmxhn)"   if missing(ccmhn)
replace   ccmhn = cfchn*0.3*gmxhn/(gsrhn + 0.3*gmxhn) if missing(ccmhn)

quality cfchn nsrhn nmxhn, gen(temp7)
replace q_ccshn = temp7                           if missing(ccshn)
replace s_ccshn = "cfchn*nsrhn/(nsrhn+0.3nmxhn)"  if missing(ccshn)
replace   ccshn = cfchn*nsrhn/(nsrhn + 0.3*nmxhn) if missing(ccshn)
replace q_ccmhn = min(q_cfchn, q_nmxhn, q_nsrhn)      if missing(ccmhn)
replace s_ccmhn = "cfchn*0.3nmxhn/(nsrhn+0.3nmxhn)"   if missing(ccmhn)
replace   ccmhn = cfchn*0.3*nmxhn/(nsrhn + 0.3*nmxhn) if missing(ccmhn)
drop temp*
// Ensure consistency
enforce (confc = cfcgo + cfcco + cfchn) ///
		(cfcco = cfcnf + cfcfc) ///
		(cfchn = cfcho + cfcnp) ///
		(ccshn = ccsho + cfcnp) ///
		(ccmhn = ccmho) ///
		(cfchn = ccshn + ccmhn) ///
		(cfcho = ccsho + ccmho), fixed(confc cfcgo) prefix(new) replace

drop newconfc newcfcgo
foreach v of varlist new* {
    local base = subinstr("`v'", "new", "", .)
	
	replace s_`base' = "enforce" if missing(`base') & !missing(`v')
    replace q_`base' = 3         if missing(`base') & !missing(`v')
    replace   `base' = `v'
}
drop new* 
	
	
// Foreign income
enforce (comnx = comrx - compx) ///
		(pinnx = pinrx - pinpx) ///
		(flcin = flcir - flcip) ///
		(taxnx = fsubx - ftaxx) ///
		(nnfin = finrx - finpx) ///
		(finrx = comrx + pinrx + fsubx) ///
		(finpx = compx + pinpx + ftaxx) ///
		(nnfin = flcin + taxnx) ///
		(flcir = comrx + pinrx) ///
		(flcip = compx + pinpx) ///
		(pinnx = fdinx + ptfnx) ///
		(pinpx = fdipx + ptfpx) ///
		(pinrx = fdirx + ptfrx) ///
		(fdinx = fdirx - fdipx) ///
		(ptfnx = ptfrx - ptfpx) ///
		(fsubx = fpsub + fosub) ///
		(ftaxx = fptax + fotax) ///
		(taxnx = prtxn + optxn) ///
		///  Gross national income of the different sectors of the economy
		(gdpro + nnfin = prghn + prgco + prggo) ///
		(gdpro + nnfin = seghn + segco + seggo) ///
		/// Property income
		(pinnx = prphn + prpco + prpgo) ///
		(prphn = prpho + prpnp) ///
		(prpco = prpfc + prpnf) ///
		/// Taxes on income and wealth
		(tiwgo = tiwhn + taxco) ///
		(tiwhn = tiwho + tiwnp) ///
		(taxco = taxnf + taxfc) ///
		/// Social contributions
		(sschn = sscco + sscgo) ///
		(sscco = sscnf + sscfc) ///
		(sschn = sscho + sscnp) ///
		/// Social benefits
		(ssbhn = ssbco + ssbgo) ///
		(ssbco = ssbnf + ssbfc) ///
		(ssbhn = ssbho + ssbnp) ///
		/// Consumption of fixed capital
		(confc = cfchn + cfcco + cfcgo) ///
		/// National savings
		(savig = savin + confc) ///
		(savin = savhn + savgo + secco) ///
		/// Household + NPISH sector
		(prghn = comhn + caghn) ///
		(caghn = gsmhn + prphn) ///
		(caphn = nsmhn + prphn) ///
		(nsmhn = gsmhn - cfchn) ///
		(nsrhn = gsrhn - ccshn) ///
		(nmxhn = gmxhn - ccmhn) ///
		(cfchn = ccshn + ccmhn) ///
		(prihn = prghn - cfchn) ///
		(nsmhn = nmxhn + nsrhn) ///
		(gsmhn = gmxhn + gsrhn) ///
		(seghn = prghn - taxhn + ssbhn) ///
		(taxhn = tiwhn + sschn) ///
		(seghn = sechn + cfchn) ///
		(saghn = seghn - conhn) ///
		(saghn = savhn + cfchn) ///
		/// Households
        (prgho = comho + cagho) ///
		(cagho = gsmho + prpho) ///
		(capho = nsmho + prpho) ///
		(nsmho = gsmho - cfcho) ///
		(nsrho = gsrho - ccsho) ///
		(nmxho = gmxho - ccmho) ///
		(cfcho = ccsho + ccmho) ///
		(priho = prgho - cfcho) ///
		(nsmho = nmxho + nsrho) ///
		(gsmho = gmxho + gsrho) ///
		(segho = prgho - taxho + ssbho) ///
		(taxho = tiwho + sscho) ///
		(segho = secho + cfcho) ///
		(sagho = segho - conho) ///
		(sagho = savho + cfcho) ///
		/// NPISH
        (prgnp = comnp + cagnp) ///
		(cagnp = gsrnp + prpnp) ///
		(capnp = nsrnp + prpnp) ///
		(nsrnp = gsrnp - cfcnp) ///
		(prinp = prgnp - cfcnp) ///
		(segnp = prgnp - taxnp + ssbnp) ///
		(taxnp = tiwnp + sscnp) ///
		(segnp = secnp + cfcnp) ///
		(sagnp = segnp - connp) ///
		(sagnp = savnp + cfcnp) ///
		/// Combination of sectors
		(prihn = priho + prinp) ///
		(comhn = comho + comnp) ///
		(prphn = prpho + prpnp) ///
		(caphn = capho + capnp) ///
		(caghn = cagho + cagnp) ///
		(nsmhn = nsmho + nsrnp) ///
		(gsmhn = gsmho + gsrnp) ///
		(gsrhn = gsrho + gsrnp) ///
		(gmxhn = gmxho) ///
		(cfchn = cfcho + cfcnp) ///
		(ccshn = ccsho + cfcnp) ///
		(ccmhn = ccmho) ///
		(sechn = secho + secnp) ///
		(taxhn = taxho + taxnp) ///
		(tiwhn = tiwho + tiwnp) ///
		(sschn = sscho + sscnp) ///
		(ssbhn = ssbho + ssbnp) ///
		(seghn = segho + segnp) ///
		(savhn = savho + savnp) ///
		(saghn = sagho + sagnp) ///
		/// Corporate sector
		/// Combined sectors, primary income
		(prgco = prpco + gsrco) ///
		(prgco = prico + cfcco) ///
		(nsrco = gsrco - cfcco) ///
		/// Financial, primary income
		(prgfc = prpfc + gsrfc) ///
		(prgfc = prifc + cfcfc) ///
		(nsrfc = gsrfc - cfcfc) ///
		/// Non-financial, primary income
		(prgnf = prpnf + gsrnf) ///
		(prgnf = prinf + cfcnf) ///
		(nsrnf = gsrnf - cfcnf) ///
		/// Combined sectors, secondary income
		(segco = prgco - taxco + sscco - ssbco) ///
		(segco = secco + cfcco) ///
		/// Financial, secondary income
		(segfc = prgfc - taxfc + sscfc - ssbfc) ///
		(segfc = secfc + cfcfc) ///
		/// Non-financial, secondary income
		(segnf = prgnf - taxnf + sscnf - ssbnf) ///
		(segnf = secnf + cfcnf) ///
		/// Combination of sectors
		(prico = prifc + prinf) ///
		(prpco = prpfc + prpnf) ///
		(nsrco = nsrfc + nsrnf) ///
		(gsrco = gsrfc + gsrnf) ///
		(cfcco = cfcfc + cfcnf) ///
		(secco = secfc + secnf) ///
		(taxco = taxfc + taxnf) ///
		(sscco = sscfc + sscnf) ///
		(segco = segfc + segnf) ///
		/// Government
		/// Primary income
		(prggo = ptxgo + prpgo + gsrgo) ///
		(nsrgo = gsrgo - cfcgo) ///
		(prigo = prggo - cfcgo) ///
		/// Taxes less subsidies of production
		(ptxgo = tpigo - spigo) ///
		(tpigo = tprgo + otpgo) ///
		(spigo = sprgo + ospgo) ///
		/// Secondary incomes
		(seggo = prggo + taxgo - ssbgo) ///
		(taxgo = tiwgo + sscgo) ///
		(secgo = seggo - cfcgo) ///
		/// Consumption and savings
		(saggo = seggo - congo) ///
		(congo = indgo + colgo) ///
		(savgo = saggo - cfcgo) ///
		/// Structure of gov spending
		(congo = gpsgo + defgo + polgo + ecogo + envgo + hougo + heago + recgo + edugo + sopgo + othgo) ///
		/// Labor + capital income decomposition
		(fkpin = prphn + prico + nsrhn + prpgo), fixed(gdpro fsubx ftaxx comrx compx fdirx fdipx ptfrx ptfpx confc cfcgo fkpin comhn nmxhn) prefix(new) replace force

drop newgdpro newfsubx newftaxx newcomrx newcompx newfdirx newfdipx newptfrx newptfpx newconfc newcfcgo newfkpin newcomhn newnmxhn
foreach v of varlist new* {
    local base = subinstr("`v'", "new", "", .)
	
	replace s_`base' = "enforce" if missing(`base') & !missing(`v')
    replace q_`base' = 3         if missing(`base') & !missing(`v')
    replace   `base' = `v'
}
drop new* 
		
		
keep iso year toreplace confc cfc* ccs* ccm* q_confc q_cfc* q_ccs* q_ccm* s_confc s_cfc* s_ccs* s_ccm*

renvars confc cfc* ccs* ccm* q_confc q_cfc* q_ccs* q_ccm* s_confc s_cfc* s_ccs* s_ccm*, prefix(imputed_)

label data "Generated by impute-confc.do"
save "$work_data/cfc-full-imputation.dta", replace
