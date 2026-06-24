// -------------------------------------------------------------------------- //
// Import foreign income data from the IMF, including an estimate
// for missing income from tax havens
// -------------------------------------------------------------------------- //

// ----------------- Index. ------------------------------------------------- //
//  1. Import GDP
//        1.1 Get estimate of GPD in current USD (SNA) 
//        1.2 Get estimate of GPD in current USD (WID) for missing countries 
//  2. Import IMF BOP
//        2.1 Process nevative values 
//        2.2 Complete Portafolio variables
//  3. Save USD data
//  4. Enforce values 
//  5. Expot
//--------------------------------------------------------------------------- //

// -------------------------------------------------------------------------- //
// 1. Import GDP 
// -------------------------------------------------------------------------- //

// -------------------------------------------------------------------------- //
// 1.1 Get estimate of GPD in current USD (SNA) 
// -------------------------------------------------------------------------- //

import excel "$input_data_dir/un-data/sna-main/gni-gdp-bop/GDPcurrent-USD-countries.xlsx", cellrange(A3) firstrow clear case(lower)

keep if indicatorname == "Gross Domestic Product (GDP)"
drop indicatorname

ds countryid country, not
local varlist = r(varlist)
local year = 1970
foreach v of local varlist {
	rename `v' gdp`year'
	local year = `year' + 1
}

greshape long gdp, i(countryid) j(year)

kountry countryid, from(iso3n) to(iso2c)
rename _ISO2C_ iso
replace iso = "CW" if country == "Curaçao"
replace iso = "CS" if country == "Czechoslovakia (Former)"
replace iso = "ET" if country == "Ethiopia (Former)"
replace iso = "KS" if country == "Kosovo"
replace iso = "RU" if country == "Russian Federation"
replace iso = "RS" if country == "Serbia"
replace iso = "SX" if country == "Sint Maarten (Dutch part)"
replace iso = "SD" if country == "Sudan"
replace iso = "TZ" if country == "U.R. of Tanzania: Mainland"
replace iso = "YA" if country == "Yemen Arab Republic (Former)"
replace iso = "YD" if country == "Yemen Democratic (Former)"
replace iso = "ZZ" if country == "Zanzibar"
replace iso = "YU" if country == "Yugoslavia (Former)"
replace iso = "SU" if country == "USSR (Former)"
assert iso != ""
drop if country == "Ethiopia" & year <= 1993
drop if country == "Sudan (Former)" & year >= 2008

keep iso year gdp
drop if missing(gdp)

tempfile gdp
save "`gdp'"

// -------------------------------------------------------------------------- //
// 1.2 Get estimate of GPD in current USD (WID) for missing countries 
// -------------------------------------------------------------------------- //
u "$work_data/retropolate-gdp.dta", clear
merge 1:1 iso year using "$work_data/exchange-rates.dta", nogen keepusing(exrate_usd) keep(master matched)
merge 1:1 iso year using "$work_data/price-index.dta",    nogen keepusing(index)      keep(master matched)
gen gdp_idx = gdp*index
gen gdp_wid = gdp_idx/exrate_usd
tempfile gdpwid
save "`gdpwid'"

// -------------------------------------------------------------------------- //
// 2. Import IMF BOP
// -------------------------------------------------------------------------- //
*import delimited "$input_data_dir/imf-data/balance-of-payments/BOP_01-31-2024 15-49-55-97.csv", clear encoding(utf8)
use "$wid_dir/Country-Updates/National_Accounts/imf-data/BOP-treated-$pastyear.dta", clear


// Trasnlate series codes into WID-fivelets
generate widcode = ""
* net foreign income (Primary incope - EARNED INCOME)
replace widcode = "nnfin"     if code2=="NETCD_T" & code3=="IN1"   //  Before 2025 "BIP_BP6_USD"
* Foreign income 
replace widcode = "finrx"     if code2=="CD_T" & code3=="IN1"      // Before 2025 "BXIP_BP6_USD"
replace widcode = "finpx"     if code2=="DB_T" & code3=="IN1"      // Before 2025 "BMIP_BP6_USD"
* Compensations to employees (REMUNERATION OF EMPLOYEES)
replace widcode = "comrx"     if code2=="CD_T" & code3=="D1"       // Before 2025 "BXIPCE_BP6_USD"*
replace widcode = "compx"     if code2=="DB_T" & code3=="D1"       // Before 2025 "BMIPCE_BP6_USD"

* Property income
replace widcode = "pinrx"     if code2=="CD_T" & code3=="_T_F_D4P" // Before 2025 "BXIPI_BP6_USD"
replace widcode = "pinpx"     if code2=="DB_T" & code3=="_T_F_D4P" // Before 2025 "BMIPI_BP6_USD"
* Foreign direct investment income
replace widcode = "fdirx"     if code2=="CD_T" & code3=="D_F_D4P"  // Before 2025 "BXIPID_BP6_USD"
replace widcode = "fdipx"     if code2=="DB_T" & code3=="D_F_D4P"  // Before 2025 "BMIPID_BP6_USD"
* Portafolio Investment
replace widcode = "ptfrx"     if code2=="CD_T" & code3=="P_F_D4P"  // Before 2025 "BXIPIP_BP6_USD"
replace widcode = "ptfpx"     if code2=="DB_T" & code3=="P_F_D4P"  // Before 2025 "BMIPIP_BP6_USD"
replace widcode = "ptfrx_eq"  if code2=="CD_T" & code3=="P_F5_D4S" // Before 2025 "BXIPIPE_BP6_USD"
replace widcode = "ptfpx_eq"  if code2=="DB_T" & code3=="P_F5_D4S" // Before 2025 "BMIPIPE_BP6_USD"
replace widcode = "ptfrx_deb" if code2=="CD_T" & code3=="P_F3_D41" // Before 2025 "BXIPIPI_BP6_USD"
replace widcode = "ptfpx_deb" if code2=="DB_T" & code3=="P_F3_D41" // Before 2025 "BMIPIPI_BP6_USD"
replace widcode = "ptfrx_oth" if code2=="CD_T" & code3=="O_F_D4P"  // "O_D41" // Before 2025 "BXIPIO_BP6_USD"
replace widcode = "ptfpx_oth" if code2=="DB_T" & code3=="O_F_D4P"  // "O_D41" // Before 2025 "BMIPIO_BP6_USD"
replace widcode = "ptfrx_res" if code2=="CD_T" & code3=="R_F_D4P"  // "R_F_D41" // Before 2025 "BXIPIR_BP6_USD"
* Taxes and subidies (Other incomes)
replace widcode = "fsubx"     if  code2=="CD_T" & code3=="D4O"     // "D3" // Before 2025 "BXIPO_BP6_USD"
replace widcode = "ftaxx"     if  code2=="DB_T" & code3=="D4O"     // "D2" // Before 2025 "BMIPO_BP6_USD"

drop if widcode == ""

* Trasnform countrynames in WID iso codes
countrycode country, generate(iso) from("imf data")
drop if iso == "CWX" 

keep iso year widcode value
drop if mi(value)
collapse (sum) value, by(iso year widcode)
greshape wide value, i(iso year) j(widcode) string
renvars value*, predrop(5)

// Generate metadata
ds  iso year , not
foreach v in `r(varlist)'{
	*Genrate q_
	gen q_`v' = 5   if `v'!=.
	*Genrate s_
	gen s_`v' = "IMFBOP" if `v'!=.
}


// -------------------------------------------------------------------------- //
//        2.1 Process nevative values 
// -------------------------------------------------------------------------- //

// whenever gross flows are negative, adding them to their counterpart gross flow to ensure everything is positive
foreach v in ptfrx_res ptfrx_oth ptfpx_oth ptfrx_eq ptfpx_eq ptfrx_deb ptfpx_deb fdirx fdipx fsubx ftaxx comrx compx {
	gen neg`v' = 1 if `v' < 0
	replace neg`v' = 0 if mi(neg`v')	
}


replace q_finrx = .  if finrx < 0
replace s_finrx = "" if finrx < 0
replace   finrx = .  if finrx < 0
replace q_finpx = .  if finpx < 0 
replace s_finpx = "" if finpx < 0 
replace   finpx = .  if finpx < 0 
 
replace q_pinrx     = min(3, cond(pinrx >= ptfrx_res, q_pinrx, q_ptfrx_res)) if ptfrx_res < 0
replace q_ptfrx     = min(3, cond(ptfrx >= ptfrx_res, q_ptfrx, q_ptfrx_res)) if ptfrx_res < 0
replace q_finrx     = min(3, cond(finrx <= ptfrx_res, q_finrx, q_ptfrx_res)) if ptfrx_res < 0
replace q_ptfrx_res = 0                                                      if ptfrx_res < 0 
replace s_pinrx     = "pinrx,ptfrx-res" if ptfrx_res < 0
replace s_ptfrx     = "ptfrx,ptfrx-res" if ptfrx_res < 0
replace s_finrx     = "finrx,ptfrx-res" if ptfrx_res < 0
replace s_ptfrx_res = "assumed"         if ptfrx_res < 0 
replace pinrx       = pinrx - ptfrx_res if ptfrx_res < 0
replace ptfrx       = ptfrx - ptfrx_res if ptfrx_res < 0
replace finrx       = finrx - ptfrx_res if ptfrx_res < 0
replace   ptfrx_res = 0 if ptfrx_res < 0 

*adding the negative values to the other gross aggregated component
replace q_pinrx = min(3, cond(pinrx >= ptfpx_oth, q_pinrx, q_ptfpx_oth)) if negptfpx_oth == 1
replace q_pinpx = min(3, cond(pinpx >= ptfpx_oth, q_pinpx, q_ptfpx_oth)) if negptfpx_oth == 1
replace q_pinpx = min(3, cond(pinpx >= ptfrx_oth, q_pinpx, q_ptfrx_oth)) if negptfrx_oth == 1
replace s_pinrx = "pinrx,ptfrx-oth" if negptfrx_oth == 1
replace s_pinrx = "pinrx,ptfpx-oth" if negptfpx_oth == 1
replace s_pinpx = "pinpx,ptfpx-oth" if negptfpx_oth == 1
replace s_pinpx = "pinpx,ptfrx-oth" if negptfrx_oth == 1
replace   pinrx = pinrx - ptfrx_oth if negptfrx_oth == 1
replace   pinrx = pinrx - ptfpx_oth if negptfpx_oth == 1
replace   pinpx = pinpx - ptfpx_oth if negptfpx_oth == 1
replace   pinpx = pinpx - ptfrx_oth if negptfrx_oth == 1

replace q_ptfrx = min(3, cond(ptfrx >= ptfrx_oth, q_ptfrx, q_ptfrx_oth)) if negptfrx_oth == 1
replace q_ptfrx = min(3, cond(ptfrx >= ptfpx_oth, q_ptfrx, q_ptfpx_oth)) if negptfpx_oth == 1
replace q_ptfpx = min(3, cond(ptfpx >= ptfpx_oth, q_ptfpx, q_ptfpx_oth)) if negptfpx_oth == 1
replace q_ptfpx = min(3, cond(ptfpx >= ptfrx_oth, q_ptfpx, q_ptfrx_oth)) if negptfrx_oth == 1
replace s_ptfrx = "ptfrx,ptfrx-oth" if negptfrx_oth == 1
replace s_ptfrx = "ptfrx,ptfpx-oth" if negptfpx_oth == 1
replace s_ptfpx = "ptfpx,ptfpx-oth" if negptfpx_oth == 1
replace s_ptfpx = "ptfpx,ptfrx-oth" if negptfrx_oth == 1
replace   ptfrx = ptfrx - ptfrx_oth if negptfrx_oth == 1
replace   ptfrx = ptfrx - ptfpx_oth if negptfpx_oth == 1
replace   ptfpx = ptfpx - ptfpx_oth if negptfpx_oth == 1
replace   ptfpx = ptfpx - ptfrx_oth if negptfrx_oth == 1


replace q_finrx = min(3, cond(finrx >= ptfrx_oth, q_finrx, q_ptfrx_oth)) if negptfrx_oth == 1
replace q_finrx = min(3, cond(finrx >= ptfpx_oth, q_finrx, q_ptfpx_oth)) if negptfpx_oth == 1
replace q_finpx = min(3, cond(finpx >= ptfpx_oth, q_finpx, q_ptfpx_oth)) if negptfpx_oth == 1
replace q_finpx = min(3, cond(finpx >= ptfrx_oth, q_finpx, q_ptfrx_oth)) if negptfrx_oth == 1
replace s_finrx = "finrx,ptfrx-oth" if negptfrx_oth == 1
replace s_finrx = "finrx,ptfpx-oth" if negptfpx_oth == 1
replace s_finpx = "finpx,ptfpx-oth" if negptfpx_oth == 1
replace s_finpx = "finpx,ptfrx-oth" if negptfrx_oth == 1
replace   finrx = finrx - ptfrx_oth if negptfrx_oth == 1
replace   finrx = finrx - ptfpx_oth if negptfpx_oth == 1
replace   finpx = finpx - ptfpx_oth if negptfpx_oth == 1
replace   finpx = finpx - ptfrx_oth if negptfrx_oth == 1

gen aux = 1 if negptfrx_oth == 1 & negptfpx_oth == 1
replace negptfrx_oth = 0 if aux == 1 
replace negptfpx_oth = 0 if aux == 1 
cap swapval ptfrx_oth ptfpx_oth if aux == 1 
replace ptfrx_oth = abs(ptfrx_oth) if aux == 1
replace ptfpx_oth = abs(ptfpx_oth) if aux == 1
replace q_ptfrx_oth = min(3, cond(ptfrx_oth >= ptfpx_oth, q_ptfrx_oth, q_ptfpx_oth)) if negptfpx_oth == 1
replace s_ptfrx_oth = "ptfrx-oth,ptfpx-oth" if negptfpx_oth == 1
replace   ptfrx_oth = ptfrx_oth - ptfpx_oth if negptfpx_oth == 1
replace q_ptfpx_oth = 0         if negptfpx_oth == 1 
replace s_ptfpx_oth = "assumed" if negptfpx_oth == 1 
replace   ptfpx_oth = 0         if negptfpx_oth == 1 
replace q_ptfpx_oth = min(3, cond(ptfpx_oth >= ptfrx_oth, q_ptfpx_oth, q_ptfrx_oth)) if negptfrx_oth == 1 
replace s_ptfpx_oth = "ptfpx-oth,ptfrx-oth" if negptfrx_oth == 1 
replace   ptfpx_oth = ptfpx_oth - ptfrx_oth if negptfrx_oth == 1 
replace q_ptfrx_oth = 0         if negptfrx_oth == 1
replace s_ptfrx_oth = "assumed" if negptfrx_oth == 1
replace   ptfrx_oth = 0         if negptfrx_oth == 1
drop aux 

replace q_pinrx = min(3, cond(pinrx >= ptfrx_deb, q_pinrx, q_ptfrx_deb)) if negptfrx_deb == 1
replace q_pinrx = min(3, cond(pinrx >= ptfpx_deb, q_pinrx, q_ptfpx_deb)) if negptfpx_deb == 1
replace q_pinpx = min(3, cond(pinpx >= ptfpx_deb, q_pinpx, q_ptfpx_deb)) if negptfpx_deb == 1
replace q_pinpx = min(3, cond(pinpx >= ptfrx_deb, q_pinpx, q_ptfrx_deb)) if negptfrx_deb == 1
replace s_pinrx = "pinrx,ptfrx-deb" if negptfrx_deb == 1
replace s_pinrx = "pinrx,ptfpx-deb" if negptfpx_deb == 1
replace s_pinpx = "pinpx,ptfpx-deb" if negptfpx_deb == 1
replace s_pinpx = "pinpx,ptfrx-deb" if negptfrx_deb == 1
replace   pinrx = pinrx - ptfrx_deb if negptfrx_deb == 1
replace   pinrx = pinrx - ptfpx_deb if negptfpx_deb == 1
replace   pinpx = pinpx - ptfpx_deb if negptfpx_deb == 1
replace   pinpx = pinpx - ptfrx_deb if negptfrx_deb == 1

replace q_ptfrx = min(3, cond(ptfrx >= ptfrx_deb, q_ptfrx, q_ptfrx_deb)) if negptfrx_deb == 1
replace q_ptfrx = min(3, cond(ptfrx >= ptfpx_deb, q_ptfrx, q_ptfpx_deb)) if negptfpx_deb == 1
replace q_ptfpx = min(3, cond(ptfpx >= ptfpx_deb, q_ptfpx, q_ptfpx_deb)) if negptfpx_deb == 1
replace q_ptfpx = min(3, cond(ptfpx >= ptfrx_deb, q_ptfpx, q_ptfrx_deb)) if negptfrx_deb == 1
replace s_ptfrx = "ptfrx,ptfrx-deb" if negptfrx_deb == 1
replace s_ptfrx = "ptfrx,ptfpx-deb" if negptfpx_deb == 1
replace s_ptfpx = "ptfpx,ptfpx-deb" if negptfpx_deb == 1
replace s_ptfpx = "ptfpx,ptfrx-deb" if negptfrx_deb == 1
replace   ptfrx = ptfrx - ptfrx_deb if negptfrx_deb == 1
replace   ptfrx = ptfrx - ptfpx_deb if negptfpx_deb == 1
replace   ptfpx = ptfpx - ptfpx_deb if negptfpx_deb == 1
replace   ptfpx = ptfpx - ptfrx_deb if negptfrx_deb == 1

replace q_finrx = min(3, cond(finrx >= ptfrx_deb, q_finrx, q_ptfrx_deb)) if negptfrx_deb == 1
replace q_finrx = min(3, cond(finrx >= ptfpx_deb, q_finrx, q_ptfpx_deb)) if negptfpx_deb == 1
replace q_finpx = min(3, cond(finpx >= ptfpx_deb, q_finpx, q_ptfpx_deb)) if negptfpx_deb == 1
replace q_finpx = min(3, cond(finpx >= ptfrx_deb, q_finpx, q_ptfrx_deb)) if negptfrx_deb == 1
replace s_finrx = "finrx,ptfrx-deb" if negptfrx_deb == 1
replace s_finrx = "finrx,ptfpx-deb" if negptfpx_deb == 1
replace s_finpx = "finpx,ptfpx-deb" if negptfpx_deb == 1
replace s_finpx = "finpx,ptfrx-deb" if negptfrx_deb == 1
replace   finrx = finrx - ptfrx_deb if negptfrx_deb == 1
replace   finrx = finrx - ptfpx_deb if negptfpx_deb == 1
replace   finpx = finpx - ptfpx_deb if negptfpx_deb == 1
replace   finpx = finpx - ptfrx_deb if negptfrx_deb == 1

gen aux = 1 if negptfrx_deb == 1 & negptfpx_deb == 1
replace negptfrx_deb = 0 if aux == 1 
replace negptfpx_deb = 0 if aux == 1 
cap swapval ptfrx_deb ptfpx_deb if aux == 1 
replace ptfrx_deb = abs(ptfrx_deb) if aux == 1
replace ptfpx_deb = abs(ptfpx_deb) if aux == 1
replace q_ptfrx_deb = min(3,cond(ptfrx_deb >= ptfpx_deb, q_ptfrx_deb, q_ptfpx_deb)) if negptfpx_deb == 1
replace s_ptfrx_deb = "ptfrx-deb,ptfpx-deb" if negptfpx_deb == 1
replace   ptfrx_deb = ptfrx_deb - ptfpx_deb if negptfpx_deb == 1
replace q_ptfpx_deb = 0  if negptfpx_deb == 1 
replace s_ptfpx_deb = "" if negptfpx_deb == 1 
replace   ptfpx_deb = 0  if negptfpx_deb == 1 
replace q_ptfpx_deb = min(3,cond(ptfpx_deb >= ptfrx_deb, q_ptfpx_deb, q_ptfrx_deb)) if negptfrx_deb == 1
replace s_ptfpx_deb = "ptfpx-deb,ptfrx-deb" if negptfrx_deb == 1
replace   ptfpx_deb = ptfpx_deb - ptfrx_deb if negptfrx_deb == 1
replace q_ptfrx_deb = 0 if negptfrx_deb == 1
replace s_ptfrx_deb = "assumed" if negptfrx_deb == 1
replace   ptfrx_deb = 0 if negptfrx_deb == 1
drop aux 

replace q_pinrx = min(3,cond(pinrx >= ptfrx_eq, q_pinrx, q_ptfrx_eq)) if negptfrx_eq == 1
replace q_pinrx = min(3,cond(pinrx >= ptfpx_eq, q_pinrx, q_ptfpx_eq)) if negptfpx_eq == 1
replace q_pinpx = min(3,cond(pinpx >= ptfpx_eq, q_pinpx, q_ptfpx_eq)) if negptfpx_eq == 1
replace q_pinpx = min(3,cond(pinpx >= ptfrx_eq, q_pinpx, q_ptfrx_eq)) if negptfrx_eq == 1
replace s_pinrx = "pinrx,ptfrx-eq" if negptfrx_eq == 1
replace s_pinrx = "pinrx,ptfpx-eq" if negptfpx_eq == 1
replace s_pinpx = "pinpx,ptfpx-eq" if negptfpx_eq == 1
replace s_pinpx = "pinpx,ptfrx-eq" if negptfrx_eq == 1
replace   pinrx = pinrx - ptfrx_eq if negptfrx_eq == 1
replace   pinrx = pinrx - ptfpx_eq if negptfpx_eq == 1
replace   pinpx = pinpx - ptfpx_eq if negptfpx_eq == 1
replace   pinpx = pinpx - ptfrx_eq if negptfrx_eq == 1

replace q_ptfrx = min(3,cond(ptfrx >= ptfrx_eq, q_ptfrx, q_ptfrx_eq)) if negptfrx_eq == 1
replace q_ptfrx = min(3,cond(ptfrx >= ptfpx_eq, q_ptfrx, q_ptfpx_eq)) if negptfpx_eq == 1
replace q_ptfpx = min(3,cond(ptfpx >= ptfpx_eq, q_ptfpx, q_ptfpx_eq)) if negptfpx_eq == 1
replace q_ptfpx = min(3,cond(ptfpx >= ptfrx_eq, q_ptfpx, q_ptfrx_eq)) if negptfrx_eq == 1
replace s_ptfrx = "ptfrx,ptfrx-eq" if negptfrx_eq == 1
replace s_ptfrx = "ptfrx,ptfpx-eq" if negptfpx_eq == 1
replace s_ptfpx = "ptfpx,ptfpx-eq" if negptfpx_eq == 1
replace s_ptfpx = "ptfpx,ptfrx-eq" if negptfrx_eq == 1
replace   ptfrx = ptfrx - ptfrx_eq if negptfrx_eq == 1
replace   ptfrx = ptfrx - ptfpx_eq if negptfpx_eq == 1
replace   ptfpx = ptfpx - ptfpx_eq if negptfpx_eq == 1
replace   ptfpx = ptfpx - ptfrx_eq if negptfrx_eq == 1


replace q_finrx = min(3,cond(finrx >= ptfrx_eq, q_finrx, q_ptfrx_eq)) if negptfrx_eq == 1
replace q_finrx = min(3,cond(finrx >= ptfpx_eq, q_finrx, q_ptfpx_eq)) if negptfpx_eq == 1
replace q_finpx = min(3,cond(finpx >= ptfpx_eq, q_finpx, q_ptfpx_eq)) if negptfpx_eq == 1
replace q_finpx = min(3,cond(finpx >= ptfrx_eq, q_finpx, q_ptfrx_eq)) if negptfrx_eq == 1
replace s_finrx = "finrx,ptfrx-eq" if negptfrx_eq == 1
replace s_finrx = "finrx,ptfpx-eq" if negptfpx_eq == 1
replace s_finpx = "finpx,ptfpx-eq" if negptfpx_eq == 1
replace s_finpx = "finpx,ptfrx-eq" if negptfrx_eq == 1
replace   finrx = finrx - ptfrx_eq if negptfrx_eq == 1
replace   finrx = finrx - ptfpx_eq if negptfpx_eq == 1
replace   finpx = finpx - ptfpx_eq if negptfpx_eq == 1
replace   finpx = finpx - ptfrx_eq if negptfrx_eq == 1

gen aux = 1 if negptfrx_eq == 1 & negptfpx_eq == 1
replace negptfrx_eq = 0 if aux == 1 
replace negptfpx_eq = 0 if aux == 1 
cap swapval ptfrx_eq ptfpx_eq if aux == 1 
replace ptfrx_eq = abs(ptfrx_eq) if aux == 1
replace ptfpx_eq = abs(ptfpx_eq) if aux == 1
replace q_ptfrx_eq = min(3,cond(ptfrx_eq >= ptfpx_eq, q_ptfrx_eq, q_ptfpx_eq)) if negptfpx_eq == 1
replace s_ptfrx_eq = "ptfrx-eq,ptfpx-eq" if negptfpx_eq == 1
replace   ptfrx_eq = ptfrx_eq - ptfpx_eq if negptfpx_eq == 1
replace q_ptfpx_eq = 0 if negptfpx_eq == 1 
replace s_ptfpx_eq = "assumed" if negptfpx_eq == 1 
replace   ptfpx_eq = 0 if negptfpx_eq == 1 
replace q_ptfpx_eq = min(3,cond(ptfpx_eq >= ptfrx_eq, q_ptfpx_eq, q_ptfrx_eq)) if negptfrx_eq == 1
replace s_ptfpx_eq = "ptfpx-eq,ptfrx-eq" if negptfrx_eq == 1
replace   ptfpx_eq = ptfpx_eq - ptfrx_eq if negptfrx_eq == 1
replace q_ptfrx_eq = 0 if negptfrx_eq == 1
replace s_ptfrx_eq = "assumed" if negptfrx_eq == 1
replace   ptfrx_eq = 0 if negptfrx_eq == 1
drop aux 

replace q_pinrx = min(3,cond(pinrx >= fdirx, q_pinrx, q_fdirx)) if negfdirx == 1
replace q_pinrx = min(3,cond(pinrx >= fdipx, q_pinrx, q_fdipx)) if negfdipx == 1
replace q_pinpx = min(3,cond(pinpx >= fdipx, q_pinpx, q_fdipx)) if negfdipx == 1
replace q_pinpx = min(3,cond(pinpx >= fdirx, q_pinpx, q_fdirx)) if negfdirx == 1
replace s_pinrx = "pinrx,fdirx" if negfdirx == 1
replace s_pinrx = "pinrx,fdipx" if negfdipx == 1
replace s_pinpx = "pinpx,fdipx" if negfdipx == 1
replace s_pinpx = "pinpx,fdirx" if negfdirx == 1
replace   pinrx = pinrx - fdirx if negfdirx == 1
replace   pinrx = pinrx - fdipx if negfdipx == 1
replace   pinpx = pinpx - fdipx if negfdipx == 1
replace   pinpx = pinpx - fdirx if negfdirx == 1

replace q_finrx = min(3,cond(finrx >= fdirx, q_finrx, q_fdirx)) if negfdirx == 1
replace q_finrx = min(3,cond(finrx >= fdipx, q_finrx, q_fdipx)) if negfdipx == 1
replace q_finpx = min(3,cond(finpx >= fdipx, q_finpx, q_fdipx)) if negfdipx == 1
replace q_finpx = min(3,cond(finpx >= fdirx, q_finpx, q_fdirx)) if negfdirx == 1
replace s_finrx = "finrx,fdirx" if negfdirx == 1
replace s_finrx = "finrx,fdipx" if negfdipx == 1
replace s_finpx = "finpx,fdipx" if negfdipx == 1
replace s_finpx = "finpx,fdirx" if negfdirx == 1
replace   finrx = finrx - fdirx if negfdirx == 1
replace   finrx = finrx - fdipx if negfdipx == 1
replace   finpx = finpx - fdipx if negfdipx == 1
replace   finpx = finpx - fdirx if negfdirx == 1

gen aux = 1 if negfdirx == 1 & negfdipx == 1
replace negfdirx = 0 if aux == 1 
replace negfdipx = 0 if aux == 1 
cap swapval fdirx fdipx if aux == 1 
replace fdirx = abs(fdirx) if aux == 1
replace fdipx = abs(fdipx) if aux == 1
replace q_fdirx = min(3,cond(fdirx >= fdipx, q_fdirx, q_fdipx)) if negfdipx == 1
replace s_fdirx = "fdirx,fdipx" if negfdipx == 1
replace   fdirx = fdirx - fdipx if negfdipx == 1
replace q_fdipx = 0         if negfdipx == 1 
replace s_fdipx = "assumed" if negfdipx == 1 
replace   fdipx = 0         if negfdipx == 1 
replace q_fdipx = min(3,cond(fdipx >= fdirx, q_fdipx, q_fdirx)) if negfdirx == 1
replace s_fdipx = "fdipx,fdirx" if negfdirx == 1
replace   fdipx = fdipx - fdirx if negfdirx == 1
replace q_fdirx = 0         if negfdirx == 1
replace s_fdirx = "assumed" if negfdirx == 1
replace   fdirx = 0         if negfdirx == 1
drop aux 

replace q_finrx = min(3,cond(finrx >= fsubx, q_finrx, q_fsubx)) if negfsubx == 1
replace q_finrx = min(3,cond(finrx >= ftaxx, q_finrx, q_ftaxx)) if negftaxx == 1
replace q_finpx = min(3,cond(finpx >= ftaxx, q_finpx, q_ftaxx)) if negftaxx == 1
replace q_finpx = min(3,cond(finpx >= fsubx, q_finpx, q_fsubx)) if negfsubx == 1
replace s_finrx = "finrx,fsubx" if negfsubx == 1
replace s_finrx = "finrx,ftaxx" if negftaxx == 1
replace s_finpx = "finpx,ftaxx" if negftaxx == 1
replace s_finpx = "finpx,fsubx" if negfsubx == 1
replace   finrx = finrx - fsubx if negfsubx == 1
replace   finrx = finrx - ftaxx if negftaxx == 1
replace   finpx = finpx - ftaxx if negftaxx == 1
replace   finpx = finpx - fsubx if negfsubx == 1
gen aux = 1 if negfsubx == 1 & negftaxx == 1
replace negfsubx = 0 if aux == 1 
replace negftaxx = 0 if aux == 1 
cap swapval fsubx ftaxx if aux == 1 
replace fsubx = abs(fsubx) if aux == 1
replace ftaxx = abs(ftaxx) if aux == 1
replace q_fsubx = min(3,cond(fsubx >= ftaxx,q_fsubx, q_ftaxx))  if negftaxx == 1
replace s_fsubx = "fsubx,ftaxx" if negftaxx == 1
replace   fsubx = fsubx - ftaxx if negftaxx == 1
replace q_ftaxx = 0 if negftaxx == 1 
replace s_ftaxx = "assumed" if negftaxx == 1 
replace   ftaxx = 0 if negftaxx == 1 
replace q_ftaxx = min(3,cond(ftaxx >= fsubx, q_ftaxx, q_fsubx)) if negfsubx == 1
replace s_ftaxx = "ftaxx,fsubx" if negfsubx == 1
replace   ftaxx = ftaxx - fsubx if negfsubx == 1
replace q_fsubx = 0 if negfsubx == 1
replace s_fsubx = "assumed" if negfsubx == 1
replace   fsubx = 0 if negfsubx == 1
drop aux 

replace q_finrx = min(3,cond(finrx >= comrx, q_finrx, q_comrx)) if negcomrx == 1
replace q_finrx = min(3,cond(finrx >= compx, q_finrx, q_compx)) if negcompx == 1
replace q_finpx = min(3,cond(finpx >= compx, q_finpx, q_compx)) if negcompx == 1
replace q_finpx = min(3,cond(finpx >= comrx, q_finpx, q_comrx)) if negcomrx == 1
replace s_finrx = "finrx,comrx" if negcomrx == 1
replace s_finrx = "finrx,compx" if negcompx == 1
replace s_finpx = "finpx,compx" if negcompx == 1
replace s_finpx = "finpx,comrx" if negcomrx == 1
replace   finrx = finrx - comrx if negcomrx == 1
replace   finrx = finrx - compx if negcompx == 1
replace   finpx = finpx - compx if negcompx == 1
replace   finpx = finpx - comrx if negcomrx == 1


gen aux = 1 if negcomrx == 1 & negcompx == 1
replace negcomrx = 0 if aux == 1 
replace negcompx = 0 if aux == 1 
cap swapval comrx compx if aux == 1 
replace comrx = abs(comrx) if aux == 1
replace compx = abs(compx) if aux == 1
replace q_comrx = min(3,cond(comrx >= compx, q_comrx, q_compx)) if negcompx == 1
replace s_comrx = "comrx,compx" if negcompx == 1
replace   comrx = comrx - compx if negcompx == 1
replace q_compx = 0         if negcompx == 1 
replace s_compx = "assumed" if negcompx == 1 
replace   compx = 0         if negcompx == 1 
replace q_compx = min(3,cond(compx >= comrx, q_compx, q_comrx)) if negcomrx == 1
replace s_compx = "compx,comrx" if negcomrx == 1
replace   compx = compx - comrx if negcomrx == 1
replace q_comrx = 0         if negcomrx == 1
replace s_comrx = "assumed" if negcomrx == 1
replace   comrx = 0         if negcomrx == 1
drop aux 

// -------------------------------------------------------------------------- //
//        2.2 Complete Portafolio variables 
// -------------------------------------------------------------------------- //
replace ptfrx = ptfrx + cond(missing(ptfrx_oth), 0, ptfrx_oth) + cond(missing(ptfrx_res), 0, ptfrx_res)
replace ptfpx = ptfpx + cond(missing(ptfpx_oth), 0, ptfpx_oth)
replace ptfrx_deb = ptfrx_deb + cond(missing(ptfrx_oth), 0, ptfrx_oth)
replace ptfpx_deb = ptfpx_deb + cond(missing(ptfpx_oth), 0, ptfpx_oth)
drop ptfrx_oth ptfpx_oth

// completing
replace q_ptfrx = min(3,cond(pinrx >= fdirx, q_pinrx, q_fdirx)) if (missing(ptfrx) | ptfrx == 0) & (!missing(pinrx) & pinrx !=0) & (!missing(fdirx) & fdirx !=0) & (fdirx < pinrx)
replace q_ptfpx = min(3,cond(pinpx >= fdipx, q_pinpx, q_fdipx)) if (missing(ptfpx) | ptfpx == 0) & (!missing(pinpx) & pinpx !=0) & (!missing(fdipx) & fdipx !=0) & (fdipx < pinpx)
replace q_fdirx = min(3,cond(pinrx >= ptfrx, q_pinrx, q_ptfrx)) if (missing(fdirx) | fdirx == 0) & (!missing(pinrx) & pinrx !=0) & (!missing(ptfrx) & ptfrx !=0) & (ptfrx < pinrx) 
replace q_fdipx = min(3,cond(pinpx >= ptfpx, q_pinpx, q_ptfpx)) if (missing(fdipx) | fdipx == 0) & (!missing(pinpx) & pinpx !=0) & (!missing(ptfpx) & ptfpx !=0) & (ptfpx < pinpx) 
replace s_ptfrx = "pinrx,fdirx" if (missing(ptfrx) | ptfrx == 0) & (!missing(pinrx) & pinrx !=0) & (!missing(fdirx) & fdirx !=0) & (fdirx < pinrx)
replace s_ptfpx = "pinpx,fdipx" if (missing(ptfpx) | ptfpx == 0) & (!missing(pinpx) & pinpx !=0) & (!missing(fdipx) & fdipx !=0) & (fdipx < pinpx)
replace s_fdirx = "pinrx,ptfrx" if (missing(fdirx) | fdirx == 0) & (!missing(pinrx) & pinrx !=0) & (!missing(ptfrx) & ptfrx !=0) & (ptfrx < pinrx) 
replace s_fdipx = "pinpx,ptfpx" if (missing(fdipx) | fdipx == 0) & (!missing(pinpx) & pinpx !=0) & (!missing(ptfpx) & ptfpx !=0) & (ptfpx < pinpx) 
replace   ptfrx = pinrx - fdirx if (missing(ptfrx) | ptfrx == 0) & (!missing(pinrx) & pinrx !=0) & (!missing(fdirx) & fdirx !=0) & (fdirx < pinrx)
replace   ptfpx = pinpx - fdipx if (missing(ptfpx) | ptfpx == 0) & (!missing(pinpx) & pinpx !=0) & (!missing(fdipx) & fdipx !=0) & (fdipx < pinpx)
replace   fdirx = pinrx - ptfrx if (missing(fdirx) | fdirx == 0) & (!missing(pinrx) & pinrx !=0) & (!missing(ptfrx) & ptfrx !=0) & (ptfrx < pinrx) 
replace   fdipx = pinpx - ptfpx if (missing(fdipx) | fdipx == 0) & (!missing(pinpx) & pinpx !=0) & (!missing(ptfpx) & ptfpx !=0) & (ptfpx < pinpx) 

// for portfolio components
// received
quality ptfrx ptfrx_deb ptfrx_res, gen(q_ptfrx_eq2)
replace q_ptfrx_eq = q_ptfrx_eq2 if (missing(ptfrx_eq) | ptfrx_eq == 0) & (!missing(ptfrx) & ptfrx !=0) & (!missing(ptfrx_deb) & ptfrx_deb !=0) & (!missing(ptfrx_res) & ptfrx_res !=0) & ((ptfrx_deb + ptfrx_res) < ptfrx) 
replace s_ptfrx_eq = "ptfrx,ptfrx-deb,ptfrx-res" if (missing(ptfrx_eq) | ptfrx_eq == 0) & (!missing(ptfrx) & ptfrx !=0) & (!missing(ptfrx_deb) & ptfrx_deb !=0) & (!missing(ptfrx_res) & ptfrx_res !=0) & ((ptfrx_deb + ptfrx_res) < ptfrx) 
replace   ptfrx_eq = ptfrx - ptfrx_deb - ptfrx_res if (missing(ptfrx_eq) | ptfrx_eq == 0) & (!missing(ptfrx) & ptfrx !=0) & (!missing(ptfrx_deb) & ptfrx_deb !=0) & (!missing(ptfrx_res) & ptfrx_res !=0) & ((ptfrx_deb + ptfrx_res) < ptfrx) 

quality ptfrx  ptfrx_eq  ptfrx_res, gen(q_ptfrx_deb2)
replace q_ptfrx_deb = q_ptfrx_deb2 if (missing(ptfrx_deb) | ptfrx_deb == 0) & (!missing(ptfrx) & ptfrx !=0) & (!missing(ptfrx_eq) & ptfrx_eq !=0) & (!missing(ptfrx_res) & ptfrx_res !=0) & ((ptfrx_eq + ptfrx_res) < ptfrx) 
replace s_ptfrx_deb = "ptfrx,ptfrx-eq,ptfrx-res" if (missing(ptfrx_deb) | ptfrx_deb == 0) & (!missing(ptfrx) & ptfrx !=0) & (!missing(ptfrx_eq) & ptfrx_eq !=0) & (!missing(ptfrx_res) & ptfrx_res !=0) & ((ptfrx_eq + ptfrx_res) < ptfrx) 
replace   ptfrx_deb = ptfrx - ptfrx_eq - ptfrx_res if (missing(ptfrx_deb) | ptfrx_deb == 0) & (!missing(ptfrx) & ptfrx !=0) & (!missing(ptfrx_eq) & ptfrx_eq !=0) & (!missing(ptfrx_res) & ptfrx_res !=0) & ((ptfrx_eq + ptfrx_res) < ptfrx) 

quality ptfrx ptfrx_deb ptfrx_eq, gen(q_ptfrx_res2)
replace q_ptfrx_res = q_ptfrx_res2 if (missing(ptfrx_res) | ptfrx_res == 0) & (!missing(ptfrx) & ptfrx !=0) & (!missing(ptfrx_deb) & ptfrx_deb !=0) & (!missing(ptfrx_eq) & ptfrx_eq !=0) & ((ptfrx_deb + ptfrx_eq) < ptfrx) 
replace s_ptfrx_res = "ptfrx,ptfrx-deb,ptfrx-eq" if (missing(ptfrx_res) | ptfrx_res == 0) & (!missing(ptfrx) & ptfrx !=0) & (!missing(ptfrx_deb) & ptfrx_deb !=0) & (!missing(ptfrx_eq) & ptfrx_eq !=0) & ((ptfrx_deb + ptfrx_eq) < ptfrx) 
replace   ptfrx_res = ptfrx - ptfrx_deb - ptfrx_eq if (missing(ptfrx_res) | ptfrx_res == 0) & (!missing(ptfrx) & ptfrx !=0) & (!missing(ptfrx_deb) & ptfrx_deb !=0) & (!missing(ptfrx_eq) & ptfrx_eq !=0) & ((ptfrx_deb + ptfrx_eq) < ptfrx) 

drop q_ptfrx_eq2 q_ptfrx_deb2 q_ptfrx_res2

foreach v in fdipx fdirx ptfpx ptfrx ptfrx_eq ptfrx_deb ptfrx_res ptfpx_eq ptfpx_deb { 
	replace q_`v' = 0         if (`v' == 0 | abs(`v') < 1)
	replace s_`v' = "assumed" if (`v' == 0 | abs(`v') < 1)
	replace    `v' = 0        if (`v' == 0 | abs(`v') < 1)
}

egen ptfrx_comp = rowtotal(ptfrx_eq ptfrx_deb ptfrx_res)
quality ptfrx_eq ptfrx_deb ptfrx_res, gen(q_ptfrx_comp)


replace   ptfrx_comp = ptfrx - ptfrx_comp
gen     s_ptfrx_comp = "ptfrx,ptfrx-comp"

// allocating to deb and eq and reserves will be done below
replace q_ptfrx_deb = min(3,q_ptfrx_comp) if mi(ptfrx_deb) & ptfrx_comp > 0 & !mi(ptfrx_eq)
replace s_ptfrx_deb = "ptfrx-comp" if mi(ptfrx_deb) & ptfrx_comp > 0 & !mi(ptfrx_eq)
replace   ptfrx_deb = ptfrx_comp   if mi(ptfrx_deb) & ptfrx_comp > 0 & !mi(ptfrx_eq)
replace q_ptfrx_eq = min(3,q_ptfrx_comp)  if mi(ptfrx_eq) & ptfrx_comp > 0 & !mi(ptfrx_deb)
replace s_ptfrx_eq = "ptfrx-comp" if mi(ptfrx_eq) & ptfrx_comp > 0 & !mi(ptfrx_deb)
replace   ptfrx_eq = ptfrx_comp   if mi(ptfrx_eq) & ptfrx_comp > 0 & !mi(ptfrx_deb)
drop ptfrx_comp

// paid
replace q_ptfpx_eq  = min(3, cond(ptfpx >= ptfpx_deb, q_ptfpx, q_ptfpx_deb)) if (missing(ptfpx_eq) | ptfpx_eq == 0) & (!missing(ptfpx) & ptfpx !=0) ///
																				& (!missing(ptfpx_deb) & ptfpx_deb !=0) & (ptfrx_deb < ptfpx) 
replace s_ptfpx_eq  = "ptfpx,ptfpx-deb" if (missing(ptfpx_eq) | ptfpx_eq == 0) & (!missing(ptfpx) & ptfpx !=0) & (!missing(ptfpx_deb) & ptfpx_deb !=0) & (ptfrx_deb < ptfpx)
replace   ptfpx_eq  = ptfpx - ptfpx_deb if (missing(ptfpx_eq) | ptfpx_eq == 0) & (!missing(ptfpx) & ptfpx !=0) & (!missing(ptfpx_deb) & ptfpx_deb !=0) & (ptfrx_deb < ptfpx) 
replace q_ptfpx_deb = min(3, cond(ptfpx >= ptfpx_eq, q_ptfpx, q_ptfpx_eq)) if (missing(ptfpx_deb) | ptfpx_deb == 0) & (!missing(ptfpx) & ptfpx !=0) ///
																				& (!missing(ptfpx_eq) & ptfpx_eq !=0) & (ptfpx_eq < ptfpx)  
replace s_ptfpx_deb = "ptfpx,ptfpx-eq" if (missing(ptfpx_deb) | ptfpx_deb == 0) & (!missing(ptfpx) & ptfpx !=0) & (!missing(ptfpx_eq) & ptfpx_eq !=0) & (ptfpx_eq < ptfpx) 
replace   ptfpx_deb = ptfpx - ptfpx_eq if (missing(ptfpx_deb) | ptfpx_deb == 0) & (!missing(ptfpx) & ptfpx !=0) & (!missing(ptfpx_eq) & ptfpx_eq !=0) & (ptfpx_eq < ptfpx) 



foreach v in fdipx fdirx ptfpx ptfrx ptfrx_eq ptfrx_deb ptfrx_res ptfpx_eq ptfpx_deb { 
	replace q_`v' = 0 if (`v' == 0 | abs(`v') < 4e-6)
	replace s_`v' = "assumed" if (`v' == 0 | abs(`v') < 4e-6)
	replace   `v' = 0 if (`v' == 0 | abs(`v') < 4e-6)
}

// whenever total income paid/received for one type of asset equals total foreign capital income paid/received and that country reports assets/liabilities of that type 
// we assume that there is misreporting in the IMF and we separate total capital income based on the share of the asset class in total assets 
gen checkptfrx = 1 if round(ptfrx) == round(pinrx) & !missing(ptfrx) & !missing(pinrx)
gen checkfdirx = 1 if round(fdirx) == round(pinrx) & !missing(fdirx) & !missing(pinrx)
gen checkptfpx = 1 if round(ptfpx) == round(pinpx) & !missing(ptfpx) & !missing(pinpx)
gen checkfdipx = 1 if round(fdipx) == round(pinpx) & !missing(fdipx) & !missing(pinpx)

gen checkptfrx_eq  = 1 if round(ptfrx_eq)  == round(ptfrx) & !missing(ptfrx_eq) & !missing(ptfrx)
gen checkptfrx_deb = 1 if round(ptfrx_deb) == round(ptfrx) & !missing(ptfrx_deb) & !missing(ptfrx)
gen checkptfrx_res = 1 if round(ptfrx_res) == round(ptfrx) & !missing(ptfrx_res) & !missing(ptfrx)

gen checkptfpx_eq  = 1 if round(ptfpx_eq)  == round(ptfpx) & !missing(ptfpx_eq) & !missing(ptfpx)
gen checkptfpx_deb = 1 if round(ptfpx_deb) == round(ptfpx) & !missing(ptfpx_deb) & !missing(ptfpx)

merge 1:1 iso year using "$work_data/foreign-wealth-total-EWN_new.dta", nogen
encode iso, gen(i)
xtset i year 

foreach x in a d {
	gen share_fdix`x' = fdix`x'/nwgx`x'
	gen share_ptfx`x' = ptfx`x'/nwgx`x'
	gen s_share_fdix`x' = "fdix`x'/nwgx`x'"
	gen s_share_ptfx`x' = "ptfx`x'/nwgx`x'"
}
gen negptfrx = 1 if negptfrx_deb == 1 & negptfrx_eq == 1 
gen negptfpx = 1 if negptfpx_deb == 1 & negptfpx_eq == 1 

replace q_fdirx = min(3, q_pinrx)  if  missing(fdirx) | fdirx == 0  & negfdirx != 1
replace q_ptfrx = min(3, q_pinrx)  if  missing(ptfrx) | ptfrx == 0  & negptfrx != 1 
replace q_fdipx = min(3, q_pinrx)  if  missing(fdipx) | fdipx == 0  & negfdipx != 1
replace q_ptfpx = min(3, q_pinrx)  if  missing(ptfpx) | ptfpx == 0  & negptfpx != 1 
replace s_fdirx = "pinrx_ratiolag" + s_share_fdixa 	if  missing(fdirx) | fdirx == 0  & negfdirx != 1
replace s_ptfrx = "pinrx_ratiolag" + s_share_ptfxa 	if  missing(ptfrx) | ptfrx == 0  & negptfrx != 1 
replace s_fdipx = "pinrx_ratiolag" + s_share_fdixd 	if  missing(fdipx) | fdipx == 0  & negfdipx != 1
replace s_ptfpx = "pinrx_ratiolag" + s_share_ptfxd 	if  missing(ptfpx) | ptfpx == 0  & negptfpx != 1 
replace   fdirx = pinrx*l.share_fdixa 				if  missing(fdirx) | fdirx == 0  & negfdirx != 1
replace   ptfrx = pinrx*l.share_ptfxa 				if  missing(ptfrx) | ptfrx == 0  & negptfrx != 1 
replace   fdipx = pinpx*l.share_fdixd 				if  missing(fdipx) | fdipx == 0  & negfdipx != 1
replace   ptfpx = pinpx*l.share_ptfxd 				if  missing(ptfpx) | ptfpx == 0  & negptfpx != 1 // Should we have parenthesis here as below? 


replace q_fdirx = min(q_pinrx,3)   if (missing(fdirx) | fdirx == 0) & year == 1970 & negfdirx != 1
replace q_ptfrx = min(q_pinrx,3)   if (missing(ptfrx) | ptfrx == 0) & year == 1970 & negptfrx != 1
replace q_fdipx = min(q_pinrx,3)   if (missing(fdipx) | fdipx == 0) & year == 1970 & negfdipx != 1
replace q_ptfpx = min(q_pinrx,3)   if (missing(ptfpx) | ptfpx == 0) & year == 1970 & negptfpx != 1
replace s_fdirx = "pinrx_ratio" + s_share_fdixa if (missing(fdirx) | fdirx == 0) & year == 1970 & negfdirx != 1
replace s_ptfrx = "pinrx_ratio" + s_share_ptfxa if (missing(ptfrx) | ptfrx == 0) & year == 1970 & negptfrx != 1
replace s_fdipx = "pinrx_ratio" + s_share_fdixd if (missing(fdipx) | fdipx == 0) & year == 1970 & negfdipx != 1
replace s_ptfpx = "pinrx_ratio" + s_share_ptfxd if (missing(ptfpx) | ptfpx == 0) & year == 1970 & negptfpx != 1
replace   fdirx = pinrx*share_fdixa if (missing(fdirx) | fdirx == 0) & year == 1970 & negfdirx != 1
replace   ptfrx = pinrx*share_ptfxa if (missing(ptfrx) | ptfrx == 0) & year == 1970 & negptfrx != 1
replace   fdipx = pinpx*share_fdixd if (missing(fdipx) | fdipx == 0) & year == 1970 & negfdipx != 1
replace   ptfpx = pinpx*share_ptfxd if (missing(ptfpx) | ptfpx == 0) & year == 1970 & negptfpx != 1

replace q_ptfrx = min(3, cond(pinrx >= fdirx, q_pinrx, q_fdirx)) if checkptfrx == 1 & pinrx > fdirx
replace q_fdirx = min(3, cond(pinrx >= ptfrx, q_pinrx, q_ptfrx)) if checkfdirx == 1 & pinrx > ptfrx
replace q_ptfpx = min(3, cond(pinpx >= fdipx, q_pinpx, q_fdipx)) if checkptfpx == 1 & pinpx > fdipx
replace q_fdipx = min(3, cond(pinpx >= ptfpx, q_pinpx, q_ptfpx)) if checkfdipx == 1 & pinpx > ptfpx
replace s_ptfrx = "pinrx,fdirx" if checkptfrx == 1 & pinrx > fdirx
replace s_fdirx = "pinrx,ptfrx" if checkfdirx == 1 & pinrx > ptfrx
replace s_ptfpx = "pinpx,fdipx" if checkptfpx == 1 & pinpx > fdipx
replace s_fdipx = "pinpx,ptfpx" if checkfdipx == 1 & pinpx > ptfpx
replace   ptfrx = pinrx - fdirx if checkptfrx == 1 & pinrx > fdirx
replace   fdirx = pinrx - ptfrx if checkfdirx == 1 & pinrx > ptfrx
replace   ptfpx = pinpx - fdipx if checkptfpx == 1 & pinpx > fdipx
replace   fdipx = pinpx - ptfpx if checkfdipx == 1 & pinpx > ptfpx

// for portfolio components
foreach x in a d {
	gen   share_ptfx`x'_deb = ptfx`x'_deb/(ptfx`x' - ptfx`x'_fin) // financial derivatives do not accrue income as per IMF BOP manual 6
	gen   share_ptfx`x'_eq  = ptfx`x'_eq/ (ptfx`x' - ptfx`x'_fin)
	gen s_share_ptfx`x'_deb = "ptfx`x'-deb/(ptfx`x' - ptfx`x'-fin)" // financial derivatives do not accrue income as per IMF BOP manual 6
	gen s_share_ptfx`x'_eq  = "ptfx`x'-eq/(ptfx`x' - ptfx`x'-fin)"
}
gen   share_ptfxa_res = ptfxa_res/(ptfxa - ptfxa_fin)
gen s_share_ptfxa_res = "ptfxa-res/(ptfxa - ptfxa-fin)"

replace q_ptfrx_eq  = 0 if share_ptfxa_eq  == 0 | mi(share_ptfxa_eq)
replace q_ptfrx_deb = 0 if share_ptfxa_deb == 0 | mi(share_ptfxa_deb)
replace q_ptfrx_res = 0 if share_ptfxa_res == 0 | mi(ptfrx_res)
replace q_ptfpx_eq  = 0 if share_ptfxd_eq  == 0 | mi(share_ptfxd_eq)
replace q_ptfpx_deb = 0 if share_ptfxd_deb == 0 | mi(share_ptfxd_deb)

replace s_ptfrx_eq  = "assumed" if share_ptfxa_eq  == 0 | mi(share_ptfxa_eq)
replace s_ptfrx_deb = "assumed" if share_ptfxa_deb == 0 | mi(share_ptfxa_deb)
replace s_ptfrx_res = "assumed" if share_ptfxa_res == 0 | mi(ptfrx_res)
replace s_ptfpx_eq  = "assumed" if share_ptfxd_eq  == 0 | mi(share_ptfxd_eq)
replace s_ptfpx_deb = "assumed" if share_ptfxd_deb == 0 | mi(share_ptfxd_deb)

replace ptfrx_eq  = 0 if share_ptfxa_eq  == 0 | mi(share_ptfxa_eq)
replace ptfrx_deb = 0 if share_ptfxa_deb == 0 | mi(share_ptfxa_deb)
replace ptfrx_res = 0 if share_ptfxa_res == 0 | mi(ptfrx_res)
replace ptfpx_eq  = 0 if share_ptfxd_eq  == 0 | mi(share_ptfxd_eq)
replace ptfpx_deb = 0 if share_ptfxd_deb == 0 | mi(share_ptfxd_deb)

foreach x in ptfrx_eq ptfrx_deb ptfrx_res ptfpx_eq ptfpx_deb {
	gen     miss`x' = 1 if mi(`x')
	replace miss`x' = 1 if `x' == 0 
	replace miss`x' = 0 if mi(miss`x')
}

// received
replace q_ptfrx_eq  = min(q_ptfrx, 3) if (missing(ptfrx_eq)  | ptfrx_eq  == 0) & !missing(ptfrx)
replace s_ptfrx_eq  = "ptfrx_ratio"+s_share_ptfxa_eq       if (missing(ptfrx_eq)  | ptfrx_eq  == 0) & !missing(ptfrx)
replace   ptfrx_eq  = ptfrx*l.share_ptfxa_eq            if (missing(ptfrx_eq)  | ptfrx_eq  == 0) 

replace q_ptfrx_deb = min(q_ptfrx, 3) if (missing(ptfrx_deb) | ptfrx_deb == 0) & !missing(ptfrx)
replace s_ptfrx_deb = "ptfrx_ratio"+s_share_ptfxa_deb      if (missing(ptfrx_deb) | ptfrx_deb == 0) & !missing(ptfrx)
replace   ptfrx_deb = ptfrx*l.share_ptfxa_deb           if (missing(ptfrx_deb) | ptfrx_deb == 0) 

// since many years reserves are not reported, we substract them from debt
replace q_ptfrx_res = min(q_ptfrx, 3) if (missing(ptfrx_res) | ptfrx_res     == 0) & !missing(ptfrx)
replace q_ptfrx_deb = min(3, cond(ptfrx_deb >= ptfrx_res, q_ptfrx_deb, q_ptfrx_res)) if  missptfrx_res == 1 & missptfrx_deb == 0  & !mi(ptfrx_deb) & !mi(ptfrx_res) & ptfrx_deb > ptfrx_res 
replace q_ptfrx_eq  = min(3, cond(ptfrx_eq  >= ptfrx_res, q_ptfrx_eq, q_ptfrx_res))  if  missptfrx_res == 1 & missptfrx_eq  == 0  & !mi(ptfrx_eq)  & !mi(ptfrx_res) & ptfrx_deb < ptfrx_res & ptfrx_eq > ptfrx_res
replace s_ptfrx_res = "ptfrx_ratio"+ s_share_ptfxa_res if (missing(ptfrx_res) | ptfrx_res    == 0) & !missing(ptfrx)
replace s_ptfrx_deb = "ptfrx-deb,ptfrx-res"          if missptfrx_res == 1 & missptfrx_deb == 0 & !mi(ptfrx_deb) & !mi(ptfrx_res) & ptfrx_deb > ptfrx_res 
replace s_ptfrx_eq  = "ptfrx-eq,ptfrx-res"           if missptfrx_res == 1 & missptfrx_eq  == 0 & !mi(ptfrx_eq)  & !mi(ptfrx_res) & ptfrx_deb < ptfrx_res & ptfrx_eq > ptfrx_res
replace   ptfrx_res = ptfrx*l.share_ptfxa_res if missing(ptfrx_res) | ptfrx_res     == 0
replace   ptfrx_deb = ptfrx_deb - ptfrx_res   if missptfrx_res == 1 & missptfrx_deb == 0 & !mi(ptfrx_deb) & !mi(ptfrx_res) & ptfrx_deb > ptfrx_res 
replace   ptfrx_eq  = ptfrx_eq - ptfrx_res    if missptfrx_res == 1 & missptfrx_eq  == 0 & !mi(ptfrx_eq)  & !mi(ptfrx_res) & ptfrx_deb < ptfrx_res & ptfrx_eq > ptfrx_res


replace q_ptfrx_eq  = min(q_ptfrx, 3)   if (missing(ptfrx_eq)  | ptfrx_eq  == 0 & year == 1970) & !missing(ptfrx)
replace q_ptfrx_deb = min(q_ptfrx, 3)  if (missing(ptfrx_deb) | ptfrx_deb == 0 & year == 1970) & !missing(ptfrx)
replace q_ptfrx_res = min(q_ptfrx, 3)  if (missing(ptfrx_res) | ptfrx_res == 0 & year == 1970) & !missing(ptfrx)
replace s_ptfrx_eq  = "ptfrx_ratiolag"+ s_share_ptfxa_eq   if (missing(ptfrx_eq)  | ptfrx_eq  == 0 & year == 1970) & !missing(ptfrx)
replace s_ptfrx_deb = "ptfrx_ratiolag"+ s_share_ptfxa_deb  if (missing(ptfrx_deb) | ptfrx_deb == 0 & year == 1970) & !missing(ptfrx)
replace s_ptfrx_res = "ptfrx_ratiolag"+ s_share_ptfxa_res  if (missing(ptfrx_res) | ptfrx_res == 0 & year == 1970) & !missing(ptfrx)
replace   ptfrx_eq  = ptfrx*l.share_ptfxa_eq  if  missing(ptfrx_eq)  | ptfrx_eq  == 0 & year == 1970
replace   ptfrx_deb = ptfrx*l.share_ptfxa_deb if  missing(ptfrx_deb) | ptfrx_deb == 0 & year == 1970
replace   ptfrx_res = ptfrx*l.share_ptfxa_res if  missing(ptfrx_res) | ptfrx_res == 0 & year == 1970

gen    check  = ptfrx_deb + ptfrx_eq + ptfrx_res 
order check, after(ptfrx)
gen   ratio   = check/ptfrx 
order ratio, after(check)
replace ratio = 0 if mi(ratio)

foreach var in ptfrx_deb ptfrx_eq ptfrx_res {
	local v_dash = subinstr("`var'", "_", "-", .)
	replace q_`var' = min(3, q_`var')
	replace s_`var' = "`v_dash'_ratio(ptfrx-deb + ptfrx_eq + ptfrx-res)/ptfrx"
	replace `var' = `var'/ratio 
}

// replacing proportionally
replace q_ptfrx_eq  = min(3, cond(ptfrx_eq >= ptfrx_deb, q_ptfrx_eq, q_ptfrx_deb))   if missptfrx_eq == 0 & missptfrx_res == 0 & missptfrx_deb == 1 & ratio > 1
replace s_ptfrx_eq  = "ptfrx-eq,ptfrx-deb_ratioptfrx-eq/ptfrx"   if missptfrx_eq == 0 & missptfrx_res == 0 & missptfrx_deb == 1 & ratio > 1
replace   ptfrx_eq  = ptfrx_eq - ptfrx_deb*(ptfrx_eq/ptfrx)   if missptfrx_eq == 0 & missptfrx_res == 0 & missptfrx_deb == 1 & ratio > 1
replace q_ptfrx_res = min(3, cond(ptfrx_res >= ptfrx_deb, q_ptfrx_res, q_ptfrx_deb)) if missptfrx_eq == 0 & missptfrx_res == 0 & missptfrx_deb == 1 & ratio > 1
replace s_ptfrx_res = "ptfrx-res,ptfrx-deb_ratioptfrx-res/ptfrx" if missptfrx_eq == 0 & missptfrx_res == 0 & missptfrx_deb == 1 & ratio > 1
replace   ptfrx_res = ptfrx_res - ptfrx_deb*(ptfrx_res/ptfrx) if missptfrx_eq == 0 & missptfrx_res == 0 & missptfrx_deb == 1 & ratio > 1

replace q_ptfrx_deb = min(3, cond(ptfrx_deb >= ptfrx_eq, q_ptfrx_deb, q_ptfrx_eq))  if missptfrx_eq == 1 & missptfrx_res == 0 & missptfrx_deb == 0 & ratio > 1
replace s_ptfrx_deb = "ptfrx-deb,ptfrx-eq_ratioptfrx-deb/ptfrx"  if missptfrx_eq == 1 & missptfrx_res == 0 & missptfrx_deb == 0 & ratio > 1
replace   ptfrx_deb = ptfrx_deb - ptfrx_eq*(ptfrx_deb/ptfrx)  if missptfrx_eq == 1 & missptfrx_res == 0 & missptfrx_deb == 0 & ratio > 1
replace q_ptfrx_res = min(3, cond(ptfrx_res >= ptfrx_eq, q_ptfrx_res, q_ptfrx_eq)) if missptfrx_eq == 1 & missptfrx_res == 0 & missptfrx_deb == 0 & ratio > 1
replace s_ptfrx_res = "ptfrx-res,ptfrx-eq_ratioptfrx-res/ptfrx"  if missptfrx_eq == 1 & missptfrx_res == 0 & missptfrx_deb == 0 & ratio > 1
replace   ptfrx_res = ptfrx_res - ptfrx_eq*(ptfrx_res/ptfrx)  if missptfrx_eq == 1 & missptfrx_res == 0 & missptfrx_deb == 0 & ratio > 1

replace q_ptfrx_deb = min(3, cond(ptfrx_deb >= ptfrx_res, q_ptfrx_deb, q_ptfrx_res)) if missptfrx_eq == 0 & missptfrx_res == 1 & missptfrx_deb == 0 & ratio > 1
replace s_ptfrx_deb = "ptfrx-deb,ptfrx-res_ratioptfrx-deb/ptfrx" if missptfrx_eq == 0 & missptfrx_res == 1 & missptfrx_deb == 0 & ratio > 1
replace   ptfrx_deb = ptfrx_deb - ptfrx_res*(ptfrx_deb/ptfrx) if missptfrx_eq == 0 & missptfrx_res == 1 & missptfrx_deb == 0 & ratio > 1
replace q_ptfrx_eq  = min(3, cond(ptfrx_eq >= ptfrx_res, q_ptfrx_eq, q_ptfrx_res))   if missptfrx_eq == 0 & missptfrx_res == 1 & missptfrx_deb == 0 & ratio > 1 
replace s_ptfrx_eq  = "ptfrx-eq,ptfrx-res_ratioptfrx-eq/ptfrx"   if missptfrx_eq == 0 & missptfrx_res == 1 & missptfrx_deb == 0 & ratio > 1 
replace   ptfrx_eq  = ptfrx_eq - ptfrx_res*(ptfrx_eq/ptfrx)   if missptfrx_eq == 0 & missptfrx_res == 1 & missptfrx_deb == 0 & ratio > 1 

drop check ratio 
gen check = ptfrx_deb + ptfrx_eq + ptfrx_res 
order check, after(ptfrx)
gen ratio = check/ptfrx 
order ratio, after(check)
replace ratio = 0 if mi(ratio)

quality ptfrx ptfrx_deb ptfrx_res,gen(q_ptfrx_eq2)
quality ptfrx ptfrx_eq  ptfrx_res,gen(q_ptfrx_deb2)
quality ptfrx ptfrx_eq  ptfrx_deb,gen(q_ptfrx_res2)

replace q_ptfrx_eq  = q_ptfrx_eq2  if (checkptfrx_eq  == 1 & ratio > 1) & (!mi(ptfrx) &  !mi(ptfrx_deb) & !mi(ptfrx_res))
replace q_ptfrx_deb = q_ptfrx_deb2 if (checkptfrx_deb == 1 & ratio > 1) & (!mi(ptfrx) &  !mi(ptfrx_eq)  & !mi(ptfrx_res))
replace q_ptfrx_res = q_ptfrx_res2 if (checkptfrx_res == 1 & ratio > 1) & (!mi(ptfrx) &  !mi(ptfrx_eq)  & !mi(ptfrx_deb))
replace s_ptfrx_eq  = "ptfrx,ptfrx-deb,ptfrx-res"  if checkptfrx_eq  == 1 & ratio > 1
replace s_ptfrx_deb = "ptfrx,ptfrx-deb,ptfrx-res"  if checkptfrx_deb == 1 & ratio > 1
replace s_ptfrx_res = "ptfrx,ptfrx-eq,ptfrx-deb"   if checkptfrx_res == 1 & ratio > 1
replace   ptfrx_eq  = ptfrx - (ptfrx_deb + ptfrx_res) if checkptfrx_eq  == 1 & ratio > 1
replace   ptfrx_deb = ptfrx - (ptfrx_eq + ptfrx_res)  if checkptfrx_deb == 1 & ratio > 1
replace   ptfrx_res = ptfrx - (ptfrx_eq + ptfrx_deb)  if checkptfrx_res == 1 & ratio > 1

drop check ratio q_*2
// now adjust 
gen check = ptfrx_deb + ptfrx_eq + ptfrx_res 
order check, after(ptfrx)
gen ratio = check/ptfrx 
order ratio, after(check)
replace ratio = 0 if mi(ratio)

foreach var in ptfrx_deb ptfrx_eq ptfrx_res {
	local v_dash = subinstr("`var'", "_", "-", .)
	replace q_`var' = min(3, q_`var')
	replace s_`var' = "`v_dash'_ratio(ptfrx-deb + ptfrx-eq + ptfrx-res)/ptfrx"
	replace `var' = `var'/ratio 
}
drop check ratio 

// paid
replace q_ptfpx_eq  = min(3,q_ptfpx)  if missing(ptfpx_eq) | ptfpx_eq == 0 
replace s_ptfpx_eq  = "ptfpx_ratiolag" + s_share_ptfxd_eq  if missing(ptfpx_eq) | ptfpx_eq == 0 
replace   ptfpx_eq  = ptfpx*l.share_ptfxd_eq  if missing(ptfpx_eq) | ptfpx_eq == 0 
replace q_ptfpx_deb = min(3,q_ptfpx)  if missing(ptfpx_deb) | ptfpx_deb == 0 
replace s_ptfpx_deb = "ptfpx_ratiolag" + s_share_ptfxd_deb if missing(ptfpx_deb) | ptfpx_deb == 0 
replace   ptfpx_deb = ptfpx*l.share_ptfxd_deb if missing(ptfpx_deb) | ptfpx_deb == 0 

replace q_ptfpx_eq  = min(3, cond(ptfpx >= ptfpx_deb, q_ptfpx, q_ptfpx_deb)) if checkptfpx_eq == 1
replace s_ptfpx_eq  = "ptfpx,ptfpx-deb" if checkptfpx_eq == 1
replace   ptfpx_eq  = ptfpx - ptfpx_deb if checkptfpx_eq == 1
replace q_ptfpx_deb = min(3, cond(ptfpx >= ptfpx_eq, q_ptfpx, q_ptfpx_eq))  if checkptfpx_deb == 1
replace s_ptfpx_deb = "ptfpx,ptfpx-eq"  if checkptfpx_deb == 1
replace   ptfpx_deb = ptfpx - ptfpx_eq  if checkptfpx_deb == 1

replace q_ptfpx_eq  = min(3,q_ptfpx)          if missing(ptfpx_eq) | ptfpx_eq == 0 & year == 1970
replace s_ptfpx_eq  = "ptfpx_ratiolag" + s_share_ptfxd_eq if missing(ptfpx_eq) | ptfpx_eq == 0 & year == 1970
replace   ptfpx_eq  = ptfpx*l.share_ptfxd_eq  if missing(ptfpx_eq) | ptfpx_eq == 0 & year == 1970
replace s_ptfpx_deb = "ptfpx_ratiolag" + s_share_ptfxd_deb if missing(ptfpx_deb) | ptfpx_deb == 0 & year == 1970
replace q_ptfpx_deb = min(3,q_ptfpx)          if missing(ptfpx_deb) | ptfpx_deb == 0 & year == 1970
replace   ptfpx_deb = ptfpx*l.share_ptfxd_deb if missing(ptfpx_deb) | ptfpx_deb == 0 & year == 1970

// now adjust 
gen check = ptfpx_deb + ptfpx_eq 
order check, after(ptfpx)
gen ratio = check/ptfpx 
order ratio, after(check)
replace ratio = 0 if mi(ratio)

foreach var in ptfpx_deb ptfpx_eq {
	replace `var' = `var'/ratio // Keep metadata as it is
}
drop check ratio 

drop checkptfrx checkfdirx checkptfpx checkfdipx ptfxa ptfxd fdixa fdixd nwgxa nwgxd flagnwgxa flagnwgxd i share_fdixa share_ptfxa share_fdixd share_ptfxd share* check* ptfxd* ptfxa*

foreach v in fdipx fdirx ptfpx ptfrx pinpx pinrx ptfrx_eq ptfrx_deb ptfrx_res ptfpx_eq ptfpx_deb {
	gen     flagimf`v' = 1 if missing(`v')
	replace flagimf`v' = 0 if missing(flagimf`v')
}

merge 1:1 iso year using "`gdp'", nogenerate
merge 1:1 iso year using "$work_data/imf-weo-gdpusd.dta", ///
       nogenerate update assert(using master match) keepusing(gdp*)
merge 1:1 iso year using "`gdpwid'", ///
       nogenerate keep(1 3) keepusing(gdp_wid)
	   
replace gdp = gdp_usd_weo if missing(gdp) 
replace gdp = gdp_wid if missing(gdp)

*issues with gdp
replace gdp = gdp_usd_weo if inlist(iso, "GY", "EG", "HN", "SV", "SB", "LR") & !missing(gdp_usd_weo)

ds iso year gdp* flag* neg* q_* s_* miss*, not //
local varlist = r(varlist)
foreach v of local varlist {
	replace   `v' = `v'/gdp
	replace q_`v' = .  if missing(`v')
	replace s_`v' = "" if missing(`v')
}

// adding corecountry dummy and Tax Haven dummy
merge 1:1 iso year using "$work_data/import-core-country-codes-year-output.dta", nogen keepusing(corecountry TH) 

// computing for Curaçao and Sint Maarten based on Netherland Antilles GDP
merge m:1 iso using "$work_data/ratioCWSX_AN.dta", nogen 
foreach v in compx comrx fsubx ftaxx fdipx fdirx ptfpx ptfrx pinpx pinrx ptfrx_eq ptfrx_deb ptfrx_res ptfpx_eq ptfpx_deb { 
bys year : gen aux`v' = `v' if iso == "AN"
bys year : egen `v'AN = mode(aux`v')

bys year : gen aux2`v' = s_`v' if iso == "AN"
bys year : egen src_`v'AN = mode(aux2`v')

}
foreach v in compx comrx fsubx ftaxx fdipx fdirx ptfpx ptfrx pinpx pinrx ptfrx_eq ptfrx_deb ptfrx_res ptfpx_eq ptfpx_deb { 
	foreach c in CW SX {
		replace q_`v' = 1                    if iso == "`c'" & missing(`v') & !missing(`v'AN)
		replace s_`v' = src_`v'AN + "(AN)"    if iso == "`c'" & missing(`v') & !missing(`v'AN)
		replace   `v' = `v'AN*ratio`c'_ANlcu if iso == "`c'" & missing(`v')
	}
}	
drop aux* ratio* *AN src_*

// variables in USD
foreach v in compx comrx fdipx fdirx finpx finrx fsubx ftaxx nnfin pinpx pinrx ptfpx ptfrx ptfrx_eq ptfrx_deb ptfrx_res ptfpx_eq ptfpx_deb {
	replace `v' = `v'*gdp_wid
}

foreach v in compx comrx ptfrx_eq ptfrx_deb ptfrx_res ptfpx_eq ptfpx_deb fdirx fdipx fsubx ftaxx {
	replace `v' = 0 if neg`v' == 1
}

// ensuring consistency
egen auxptfrx = rowtotal(ptfrx_eq ptfrx_deb ptfrx_res), missing
quality ptfrx_eq ptfrx_deb ptfrx_res, gen(q_ptfrx2)
gen ratio = auxptfrx/ptfrx 
replace ratio = 0 if mi(ratio)
drop ratio 
replace q_ptfrx = q_ptfrx if !missing(auxptfrx)
replace s_ptfrx = "ptfrx-eq,ptfrx-deb,ptfrx-res" if !missing(auxptfrx)
replace   ptfrx = auxptfrx if !missing(auxptfrx)

egen auxptfpx = rowtotal(ptfpx_eq ptfpx_deb), missing
quality ptfpx_eq ptfpx_deb, gen(q_ptfpx2)
gen ratio = auxptfpx/ptfpx 
replace ratio = 0 if mi(ratio)
drop ratio 
replace q_ptfpx = q_ptfpx2 if !missing(auxptfpx)
replace s_ptfpx = "ptfpx-eq,ptfpx-deb" if !missing(auxptfpx)
replace   ptfpx = auxptfpx if !missing(auxptfpx)

egen auxpinrx = rowtotal(fdirx ptfrx), missing
quality fdirx ptfrx, gen(q_pinrx2)
gen ratio2 = auxpinrx/pinrx 
replace ratio2 = 0 if mi(ratio2)
drop ratio2 
replace q_pinrx = q_pinrx2 if !missing(auxpinrx)
replace s_pinrx = "fdirx,ptfrx" if !missing(auxpinrx)
replace   pinrx = auxpinrx if !missing(auxpinrx)

egen auxpinpx = rowtotal(fdipx ptfpx), missing
quality fdipx ptfpx, gen(q_pinpx2)
gen ratio = auxpinpx/pinpx 
replace ratio = 0 if mi(ratio)
drop ratio 
replace q_pinpx = q_pinpx2 if !missing(auxpinpx)
replace s_pinpx = "fdipx,ptfpx" if !missing(auxpinpx)
replace   pinpx = auxpinpx if !missing(auxpinpx)
drop q_*2

gen s_flcir = "pinrx,comrx" if !mi(pinrx) & !mi(comrx)
gen q_flcir = min(3, cond(pinrx >= comrx, q_pinrx,  q_comrx)) if !mi(pinrx) & !mi(comrx)
gen   flcir = pinrx + comrx
gen  auxfinrx = flcir + fsubx
replace q_finrx = min(3, cond(flcir >=  fsubx, q_flcir,  q_fsubx)) if !missing(auxfinrx)
replace s_finrx = "flcir,fsubx" if !missing(auxfinrx)
replace   finrx = auxfinrx    if !missing(auxfinrx)

//egen flcir = rowtotal(pinrx comrx), missing
//egen auxfinrx = rowtotal(flcir fsubx), missing 
//replace finrx = auxfinrx if !missing(auxfinrx)

gen s_flcip = "pinpx,compx"    if !mi(pinpx) & !mi(compx)
gen q_flcip = min(3, cond(pinpx >= compx, q_pinpx,  q_compx)) if !mi(pinpx) & !mi(compx)
gen flcip = pinpx + compx
gen auxfinpx = flcip + ftaxx 
replace q_finpx = min(3, cond(flcip >= ftaxx, q_flcip,  q_ftaxx)) if !missing(auxfinrx)
replace s_finpx = "flcip,ftaxx" if !missing(auxfinpx)
replace   finpx = auxfinpx    if !missing(auxfinpx)

//egen flcip = rowtotal(pinpx compx), missing
//egen auxfinpx = rowtotal(flcip ftaxx), missing 
//replace finpx = auxfinpx if !missing(auxfinpx)

quality flcir flcip, gen(q_flcin)
quality pinrx pinpx, gen(q_pinnx)
quality comrx compx, gen(q_comnx)
quality fdirx fdipx, gen(q_fdinx)
quality ptfrx ptfpx, gen(q_ptfnx)
quality fsubx ftaxx, gen(q_taxnx)
gen s_flcin = "flcir,flcip"
gen s_pinnx = "pinrx,pinpx"
gen s_comnx = "comrx,compx"
gen s_fdinx = "fdirx,fdipx"
gen s_ptfnx = "ptfrx,ptfpx"
gen s_taxnx = "fsubx,ftaxx"
gen   flcin = flcir - flcip
gen   pinnx = pinrx - pinpx
gen   comnx = comrx - compx
gen   fdinx = fdirx - fdipx
gen   ptfnx = ptfrx - ptfpx
gen   taxnx = fsubx - ftaxx

gen    auxnnfin = finrx - finpx 
replace q_nnfin = min( 3, cond(finrx >= finpx, q_finrx,  q_finpx)) if !missing(auxnnfin)
replace s_nnfin = "finrx,finpx" if !missing(auxnnfin)
replace   nnfin = auxnnfin    if !missing(auxnnfin)
drop aux* // non*  min* share* 
drop if missing(year)

// -------------------------------------------------------------------------- //
// 3. Save USD data
// -------------------------------------------------------------------------- //
// Save USD version (for redistributing missing incomes later)
*save "$work_data/imf-usd.dta", replace

ds iso year gdp* flag* neg* s_* q_*, not
local varlist = r(varlist)
foreach v of local varlist {
	replace `v' = `v'/gdp_wid
}
drop gdp

// -------------------------------------------------------------------------- //
// 4. Enforce values 
// -------------------------------------------------------------------------- //
generate series = 6000


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
		(ptfrx = ptfrx_eq + ptfrx_deb + ptfrx_res) ///
		(ptfpx = ptfpx_eq + ptfpx_deb) ///
		(pinpx = fdipx + ptfpx) ///
		(pinrx = fdirx + ptfrx) ///
		(fdinx = fdirx - fdipx) ///
		(ptfnx = ptfrx - ptfpx), fixed(nnfin) prefix(new) force

foreach v in compx comrx fdipx fdirx finpx finrx fsubx ftaxx pinpx pinrx ptfpx ptfrx flcir flcip ptfrx_eq ptfrx_deb ptfrx_res ptfpx_eq ptfpx_deb {
	replace q_`v' = 3   if new`v' >= 0 & new`v' != . & missing(`v')
	replace s_`v' = "enforce" if new`v' >= 0 & new`v' != . & missing(`v')
	replace `v' = new`v'          if new`v' >= 0 		
	
	replace q_`v' = 3   if new`v' < 0 & new`v' != . & `v' < 0 & !missing(`v')
	replace s_`v' = "enforce" if new`v' < 0 & new`v' != . & `v' < 0 & !missing(`v')
	replace `v' = new`v'                  if new`v' < 0  & new`v' != .& `v' < 0 & !missing(`v')	

	
	replace q_`v' = 0    if missing(`v') & !missing(new`v')
	replace s_`v' = "assumed0" if missing(`v') & !missing(new`v')
	replace `v' = 0                if missing(`v') & !missing(new`v')
	
}
drop new*


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
		(ptfrx = ptfrx_eq + ptfrx_deb + ptfrx_res) ///
		(ptfpx = ptfpx_eq + ptfpx_deb) ///
		(pinpx = fdipx + ptfpx) ///
		(pinrx = fdirx + ptfrx) ///
		(fdinx = fdirx - fdipx) ///
		(ptfnx = ptfrx - ptfpx), fixed(fdirx fdipx ptfrx ptfpx ptfrx_eq ptfrx_deb ptfrx_res ptfpx_eq ptfpx_deb) prefix(new) replace force

foreach v of varlist new* {
    local base = subinstr("`v'", "new", "", .)

    replace q_`base' = 3          if missing(`base') & !missing(`v')
	replace s_`base' = "enforce" if missing(`base') & !missing(`v')
    replace `base' = `v'
}
drop new* 

foreach v in fdipx fdirx ptfpx ptfrx pinpx pinrx ptfrx_eq ptfrx_deb ptfrx_res ptfpx_eq ptfpx_deb {
	replace `v'   =.  if flagimf`v' == 1
	replace s_`v' ="" if flagimf`v' == 1
	replace q_`v' =.  if flagimf`v' == 1
}

// -------------------------------------------------------------------------- //
// 5. Expot
// -------------------------------------------------------------------------- //
		
drop gdp_usd_weo gdp_wid corecountry TH		
label data "Generated by import-imf-bop.do"
save "$work_data/imf-foreign-income.dta", replace
