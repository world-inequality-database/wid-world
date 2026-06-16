// -------------------------------------------------------------------------- //
//                 Current account .do-file
// -------------------------------------------------------------------------- //

global EURO `" "AD" "AL" "AT" "BA" "BE" "BG" "CH" "CY" "CZ" "DE" "DK" "EE" "ES" "FI" "FR" "GB" "GG" "GI" "GR" "HR" "HU" "IE" "IM" "IS" "IT" "JE" "KS" "LI" "LT" "LU" "LV" "MC" "MD" "ME" "MK" "MT" "NL" "NO" "PL" "PT" "RO" "RS" "SE" "SI" "SK" "SM" "'
global NAOC `" "AU" "BM" "CA" "FJ" "FM" "GL" "KI" "MH" "NC" "NR" "NZ" "PF" "PG" "PW" "SB" "TO" "TV" "US" "VU" "WS" "'
global LATA `" "AG" "AI" "AR" "AW" "BB" "BO" "BQ" "BR" "BS" "BZ" "CL" "CO" "CR" "CU" "CW" "DM" "DO" "EC" "GD" "GT" "GY" "HN" "HT" "JM" "KN" "KY" "LC" "MS" "MX" "NI" "PA" "PE" "PR" "PY" "SR" "SV" "SX" "TC" "TT" "UY" "VC" "VE" "VG" "'
global MENA `" "AE" "BH" "DZ" "EG" "IL" "IQ" "IR" "JO" "KW" "LB" "LY" "MA" "OM" "PS" "QA" "SA" "SY" "TN" "TR" "YE" "'
global SSAF `" "AO" "BF" "BI" "BJ" "BW" "CD" "CF" "CG" "CI" "CM" "CV" "DJ" "ER" "ET" "GA" "GH" "GM" "GN" "GQ" "GW" "KE" "KM" "LR" "LS" "MG" "ML" "MR" "MU" "MW" "MZ" "NA" "NE" "NG" "RW" "SC" "SD" "SL" "SN" "SO" "SS" "ST" "SZ" "TD" "TG" "TZ" "UG" "ZA" "ZM" "ZW" "'
global RUCA `" "AM" "AZ" "BY" "GE" "KG" "KZ" "RU" "TJ" "TM" "UA" "UZ" "'
global EASA `" "CN" "HK" "JP" "KP" "KR" "MN" "MO" "TW" "'
global SSEA `" "AF" "BD" "BN" "BT" "ID" "IN" "KH" "LA" "LK" "MM" "MV" "MY" "NP"  "PH" "PK" "SG" "TH" "TL" "VN" "'


// ------------ 1. Import Current account ----------------------------------- //
*import delimited "$current_account/BOP_05-13-2024 14-41-48-35.csv", clear
use "$wid_dir/Country-Updates/National_Accounts/imf-data/BOP-treated-$pastyear.dta", clear

//Keep Current accounts variables 

keep if inlist(code3, "GS", "D1", "D4O", "IN2", "D9", "EO_AFR","NNADISP") | ///
		inlist(code3,"IN2_S13", "D752_S1W", "IN22_S1W") 
keep if inlist(code2,"CD_T","DB_T") | (code2=="NETCD_T" & code3=="EO_AFR")
		
*Current Account, Primary Income, Compensation of Employees, Credit, US Dollars             CD_T.D1,       before:BXIPCE_BP6_USD 
*Current Account, Primary Income, Compensation of Employees, Debit,  US Dollars             DB_T.D1,       before:BMIPCE_BP6_USD
*Current Account, Total, Debit,  US Dollars	                                                                      BMCA_BP6_USD
*Current Account, Total, Credit, US Dollars													                      BXCA_BP6_USD
*Current Account, Primary Income, Other Primary Income, Credit, US Dollars					CD_T.D4O,      before:BXIPO_BP6_USD
*Current Account, Primary Income, Other Primary Income, Debit,  US Dollars  				DB_T.D4O,      before:BMIPO_BP6_USD
*Current Account, Secondary Income, Credit, US Dollars										CD_T.IN2,      before:BXIS_BP6_USD
*Current Account, Secondary Income, Debit, US Dollars										DB_T.IN2,      before:BMIS_BP6_USD
*Current Account, Secondary Income, Financial Corporations, Nonfinancial Corporations,
*                 Households, and NPISHs, Credit, US Dollars                                CD_T.D752_S1W, before:BXISOPT_BP6_USD  
*Current Account, Secondary Income, Financial Corporations, Nonfinancial Corporations, 
*                 Households, and NPISHs, Other Current Transfers, Credit, US Dollars       CD_T.IN22_S1W, before:BXISOOT_BP6_USD
*Current Account, Secondary Income, General Government, Credit, US Dollars                  CD_T.IN2_S13,  before:BXISG_BP6_USD
*Net Errors and Omissions, US Dollars	                                                                          BOP_BP6_USD
*Supplementary Items, Errors and Omissions (with Fund Record), US Dollars	                NETCD_T.EO_AFR,before:BOPFR_BP6_USD
*Current Account, Goods and Services, Debit, US Dollars                                     CD_T.GS,       before:BMGS_BP6_USD
*Current Account, Goods and Services, Credit, US Dollars   									DB_T.GS,       before:BXGS_BP6_USD
*Current Account, Goods and Services, Net, US Dollars 															  BGS_BP6_USD


//Rename the variables
replace indicator = "trade_credit"       if code2=="CD_T"    & code3=="GS"       // "BXGS_BP6_USD"
replace indicator = "trade_debit"        if code2=="DB_T"    & code3=="GS"       // "BMGS_BP6_USD"
replace indicator = "compemp_debit"      if code2=="DB_T"    & code3=="D1"       // "BMIPCE_BP6_USD"
replace indicator = "compemp_credit"     if code2=="CD_T"    & code3=="D1"       // "BXIPCE_BP6_USD"
*replace indicator = "total_debit"        if indicatorcode == "BMCA_BP6_USD"
*replace indicator = "total_credit"       if indicatorcode == "BXCA_BP6_USD"
replace indicator = "otherpinc_credit"   if code2=="CD_T"    & code3=="D4O"      //"BXIPO_BP6_USD"
replace indicator = "otherpinc_debit"    if code2=="DB_T"    & code3=="D4O"      // "BMIPO_BP6_USD"
replace indicator = "secinc_credit"      if code2=="CD_T"    & code3=="IN2"      // "BXIS_BP6_USD"
replace indicator = "foreignaid_credit"  if code2=="CD_T"    & code3=="IN2_S13"  // "BXISG_BP6_USD"
replace indicator = "remittances_credit" if code2=="CD_T"    & code3=="D752_S1W" // "BXISOPT_BP6_USD"
replace indicator = "othtrans_credit"    if code2=="CD_T"    & code3=="IN22_S1W" // "BXISOOT_BP6_USD"
replace indicator = "secinc_debit"       if code2=="DB_T"    & code3=="IN2"      // "BMIS_BP6_USD"
replace indicator = "foreignaid_debit"   if code2=="DB_T"    & code3=="IN2_S13"  // "BMISG_BP6_USD"
replace indicator = "remittances_debit"  if code2=="DB_T"    & code3=="D752_S1W" // "BMISOPT_BP6_USD"
replace indicator = "othtrans_debit"     if code2=="DB_T"    & code3=="IN22_S1W" // "BMISOOT_BP6_USD"
replace indicator = "errors_net"         if code2=="NETCD_T" & code3=="EO_AFR"   // "BOP_BP6_USD"
replace indicator = "capital_credit"     if code2=="CD_T"    & inlist(code3,"D9","NNADISP")  // "BKA_CD_BP6_USD" | "BKT_CD_BP6_USD"
replace indicator = "capital_debit"      if code2=="DB_T"    & inlist(code3,"D9","NNADISP")  // "BKA_DB_BP6_USD" | "BKT_DB_BP6_USD"
collapse (sum) value, by(country indicator year)

drop if country == "Australia" & missing(v) & (indicator == "capital_credit" | indicator == "capital_debit")


tempfile ca 
save `ca'

// ------------ 2. Import Trade services ------------------------------------ //
*import delimited "$current_account/BOP_01-10-2025 14-28-14-86.csv", clear
use "$wid_dir/Country-Updates/National_Accounts/imf-data/BOP-treated-$pastyear.dta", clear
/*
Export of services
      Export of transport services
             Passenger
             Freight and other (including postal and courier) 
      Export of travel services
             Personal travel
             Business travel
      Other export of services (this will include all the rest: Manufacturing services on physical inputs owned by others + Maintenance and repair services + Other services -Construction; Insurance and pension; Financial; Intellectual property, Telecommunication, Government goods and services, Personal cultural)
	  
	  
indicatorname	indicatorcode
Current Account, Goods and Services, Services, Construction, Debit, US Dollars															BMSOCN_BP6_USD
Current Account, Goods and Services, Services, Construction, Credit, US Dollars															BXSOCN_BP6_USD
Current Account, Goods and Services, Services, Credit, US Dollars																		BXS_BP6_USD
Current Account, Goods and Services, Services, Debit, US Dollars																		BMS_BP6_USD
Current Account, Goods and Services, Services, Financial Services, Credit, US Dollars													BXSOFI_BP6_USD
Current Account, Goods and Services, Services, Financial Services, Debit, US Dollars													BMSOFI_BP6_USD
Current Account, Goods and Services, Services, Other Business Services, Debit, US Dollars												BMSOOB_BP6_USD
Current Account, Goods and Services, Services, Government Goods and Services nie, Credit, US Dollars									BXSOGGS_BP6_USD
Current Account, Goods and Services, Services, Government Goods and Services nie, Debit, US Dollars										BMSOGGS_BP6_USD
Current Account, Goods and Services, Services, Travel, Debit, US Dollars																BMSTV_BP6_USD
Current Account, Goods and Services, Services, Maintenance and Repair Services nie, Debit, US Dollars									BMSR_BP6_USD
Current Account, Goods and Services, Services, Manufacturing Services on Physical Inputs Owned by Others, Credit, US Dollars			BXSM_BP6_USD
Current Account, Goods and Services, Services, Manufacturing Services on Physical Inputs Owned by Others, Debit, US Dollars				BMSM_BP6_USD
Current Account, Goods and Services, Services, Net, US Dollars																			BS_BP6_USD
Current Account, Goods and Services, Services, Personal, Cultural, and Recreational Services, Credit, US Dollars						BXSOPCR_BP6_USD
Current Account, Goods and Services, Services, Personal, Cultural, and Recreational Services, Debit, US Dollars							BMSOPCR_BP6_USD
Current Account, Goods and Services, Services, Other Services, Credit, US Dollars											  CD_T.SPX 	BXSO_BP6_USD
Current Account, Goods and Services, Services, Transport, Freight, Credit, US Dollars													BXSTRFR_BP6_USD
Current Account, Goods and Services, Services, Travel, Business, Credit, US Dollars														BXSTVB_BP6_USD
Current Account, Goods and Services, Services, Telecommunications, Computer, and Information Services, Credit, US Dollars				BXSOTCM_BP6_USD
Current Account, Goods and Services, Services, Telecommunications, Computer, and Information Services, Debit, US Dollars				BMSOTCM_BP6_USD
Current Account, Goods and Services, Services, Charges for the Use of Intellectual Property nie, Credit, US Dollars						BXSORL_BP6_USD
Current Account, Goods and Services, Services, Insurance and Pension Services, Credit, US Dollars										BXSOIN_BP6_USD
Current Account, Goods and Services, Services, Insurance and Pension Services, Debit, US Dollars										BMSOIN_BP6_USD
Current Account, Goods and Services, Services, Transport, Credit, US Dollars															BXSTR_BP6_USD
Current Account, Goods and Services, Services, Travel, Personal, Debit, US Dollars														BMSTVP_BP6_USD
Current Account, Goods and Services, Services, Other Business Services, Credit, US Dollars												BXSOOB_BP6_USD
Current Account, Goods and Services, Services, Maintenance and Repair Services nie, Credit, US Dollars									BXSR_BP6_USD
Current Account, Goods and Services, Services, Transport, Passenger, Debit, US Dollars													BMSTRPA_BP6_USD
Current Account, Goods and Services, Services, Other Services, Debit, US Dollars											  DB_T.SPX  BMSO_BP6_USD
Current Account, Goods and Services, Services, Transport, Debit, US Dollars													  DB_T.SC   BMSTR_BP6_USD
Current Account, Goods and Services, Services, Travel, Credit, US Dollars													  CD_T.SD 	BXSTV_BP6_USD
Current Account, Goods and Services, Services, Transport, Passenger, Credit, US Dollars													BXSTRPA_BP6_USD
Current Account, Goods and Services, Services, Travel, Business, Debit, US Dollars														BMSTVB_BP6_USD
Current Account, Goods and Services, Services, Travel, Personal, Credit, US Dollars														BXSTVP_BP6_USD
Current Account, Goods and Services, Services: Transport Other (Including postal and courier), Credit, US Dollars						BXSTROPC_BP6_USD
Current Account, Goods and Services, Services, Transport, Freight, Debit, US Dollars													BMSTRFR_BP6_USD
Current Account, Goods and Services, Services, Charges for the Use of Intellectual Property nie, Debit, US Dollars						BMSORL_BP6_USD
Current Account, Goods and Services, Services: Transport Other (Including postal and courier), Debit, US Dollars						BMSTROPC_BP6_USD
	  
*/
*drop if inlist(indicatorcode, "BXS_BP6_USD", "BMS_BP6_USD", "BS_BP6_USD")

replace indicator = "travel_credit"        if code2=="CD_T" & code3=="SD"   // "BXSTV_BP6_USD"
replace indicator = "travel_debit"         if code2=="DB_T" & code3=="SD"   //  "BMSTV_BP6_USD"
replace indicator = "travel_pers_debit"    if code2=="DB_T" & code3=="SDB" // "BMSTVP_BP6_USD"
replace indicator = "travel_pers_credit"   if code2=="CD_T" & code3=="SDB" // "BXSTVP_BP6_USD"
replace indicator = "travel_bus_debit"     if code2=="DB_T" & code3=="SJ"   // "BMSTVB_BP6_USD"
replace indicator = "travel_bus_credit"    if code2=="CD_T" & code3=="SJ"   // "BXSTVB_BP6_USD"

replace indicator = "trans_credit"         if code2=="CD_T" & code3=="SC"   // "BXSTR_BP6_USD"
replace indicator = "trans_debit"          if code2=="DB_T" & code3=="SC"   // "BMSTR_BP6_USD" 
replace indicator = "trans_fr_credit"      if code2=="CD_T" & inlist(code3,"SCC2","SCB") // "BXSTRFR_BP6_USD", "BXSTROPC_BP6_USD" 
replace indicator = "trans_fr_debit"       if code2=="DB_T" & inlist(code3,"SCC2","SCB") // "BMSTRFR_BP6_USD", "BMSTROPC_BP6_USD"
replace indicator = "trans_pass_credit"    if code2=="CD_T" & code3=="SCA"  // "BXSTRPA_BP6_USD"
replace indicator = "trans_pass_debit"     if code2=="DB_T" & code3=="SCA"  // "BMSTRPA_BP6_USD"

replace indicator = "otherservices_credit" if code2=="CD_T" & inlist(code3,"SPX","SB","SA") // "BXSO_BP6_USD", "BXSM_BP6_USD", "BXSR_BP6_USD"
replace indicator = "otherservices_debit"  if code2=="DB_T" & inlist(code3,"SPX","SB","SA") // "BMSO_BP6_USD", "BMSM_BP6_USD", "BMSR_BP6_USD") 

drop if !inlist(indicator, "services_credit", "services_debit", "travel_credit", "travel_debit", "travel_pers_debit", "travel_pers_credit", "travel_bus_debit", "travel_bus_credit") & !inlist(indicator, "trans_credit", "trans_debit", "trans_fr_credit", "trans_fr_debit", "trans_pass_credit", "trans_pass_debit", "otherservices_credit", "otherservices_debit") 

collapse (sum) value, by(country indicator year)

tempfile trserv
sa `trserv'

// ------------ 3. Import Trade goods --------------------------------------- //
*import delimited "$current_account/BOP_01-13-2025 16-52-44-31.csv", clear 
use "$wid_dir/Country-Updates/National_Accounts/imf-data/BOP-treated-$pastyear.dta", clear
// Current Account, Goods and Services, Goods, Debit, US Dollars	BMG_BP6_USD
// Current Account, Goods and Services, Goods, Credit, US Dollars	BXG_BP6_USD

keep if code3=="G"
keep if inlist(code2,"CD_T","DB_T")

replace indicator = "goods_credit" if code2=="CD_T" & code3=="G" // "BXG_BP6_USD"
replace indicator = "goods_debit"  if code2=="DB_T" & code3=="G" //"BMG_BP6_USD"

collapse (sum) value, by(country indicator year)


// ------------ 4. Process negative values ---------------------------------- //
// appending
append using `ca' `trserv'

greshape wide value, i(country year) j(indicator) 

renpfix value

foreach v in capital_credit capital_debit compemp_credit compemp_debit foreignaid_credit foreignaid_debit goods_credit goods_debit otherpinc_credit otherpinc_debit otherservices_credit otherservices_debit othtrans_credit othtrans_debit remittances_credit remittances_debit secinc_credit secinc_debit trade_credit trade_debit trans_credit trans_debit trans_fr_credit trans_fr_debit trans_pass_credit trans_pass_debit travel_bus_credit travel_bus_debit travel_credit travel_debit travel_pers_credit travel_pers_debit {
	gen neg`v' = 1 if `v' < 0
	replace neg`v' = 0 if mi(neg`v')	
}

// Generate metadata
ds  country year neg*, not
foreach v in `r(varlist)'{
	gen q_`v' = 5         if `v'!=.
	gen s_`v' = "IMFBOP" if `v'!=.
}

*adding the negative values to the other gross aggregated component
foreach v in capital goods trans travel otherservices remittances foreignaid othtrans secinc {
    gen aux = 1 if neg`v'_credit == 1 & neg`v'_debit == 1
    replace neg`v'_credit = 0 if aux == 1
    replace neg`v'_debit  = 0 if aux == 1
    cap swapval `v'_credit `v'_debit if aux == 1
    replace   `v'_credit = abs(`v'_credit) if aux == 1
    replace   `v'_debit  = abs(`v'_debit)  if aux == 1
	replace q_`v'_credit = min(3, cond(`v'_credit >= `v'_debit, q_`v'_credit, q_`v'_debit)) if neg`v'_debit  == 1
	replace s_`v'_credit = "`v'-credit,`v'-debit" if neg`v'_debit  == 1
    replace   `v'_credit = `v'_credit - `v'_debit if neg`v'_debit  == 1
    replace q_`v'_debit  = 0                      if neg`v'_debit  == 1
	replace s_`v'_debit  = "assumed"              if neg`v'_debit  == 1
	replace   `v'_debit  = 0                      if neg`v'_debit  == 1
    replace q_`v'_debit  = min(3, cond(`v'_debit >= `v'_credit,`v'_debit, `v'_credit)) if neg`v'_credit == 1
    replace s_`v'_debit  = "`v'-debit,`v'-credit" if neg`v'_credit == 1
    replace   `v'_debit  = `v'_debit - `v'_credit if neg`v'_credit == 1
    replace q_`v'_credit = 0                      if neg`v'_credit == 1
	replace s_`v'_credit = "assumed"              if neg`v'_credit == 1
	replace   `v'_credit = 0                      if neg`v'_credit == 1
    drop aux
}


// ------------ 5. Format --------------------------------------------------- //
*kountry countrycode, from(imfn) to(iso2c)
*ren _ISO2C_ iso 
countrycode country, generate(iso) from("imf data")
drop if iso == "CWX" 
drop if mi(iso)
drop country

fillin iso year
//Netherlands Antilles split
merge m:1 iso using "$work_data/ratioCWSX_AN.dta", nogen 

foreach v in compemp_credit compemp_debit otherpinc_credit goods_credit goods_debit /// total_debit total_credit errors_net
 otherpinc_debit secinc_credit secinc_debit  trade_credit trade_debit capital_credit capital_debit foreignaid_credit remittances_credit othtrans_credit foreignaid_debit remittances_debit othtrans_debit /// 
 travel_credit travel_debit travel_pers_debit travel_pers_credit travel_bus_debit travel_bus_credit trans_credit trans_debit trans_fr_credit trans_fr_debit trans_pass_credit trans_pass_debit otherservices_credit otherservices_debit {
bys year : gen aux`v' = `v' if iso == "AN" & year<2011
bys year : egen `v'AN = mode(aux`v')
}

foreach v in compemp_credit compemp_debit otherpinc_credit goods_credit goods_debit /// total_debit total_credit errors_net
 otherpinc_debit secinc_credit secinc_debit  trade_credit trade_debit capital_credit capital_debit foreignaid_credit remittances_credit othtrans_credit foreignaid_debit remittances_debit othtrans_debit /// 
 travel_credit travel_debit travel_pers_debit travel_pers_credit travel_bus_debit travel_bus_credit trans_credit trans_debit trans_fr_credit trans_fr_debit trans_pass_credit trans_pass_debit otherservices_credit otherservices_debit {
 
	foreach c in CW SX {
		local v_dash = subinstr("`v'", "_", "-", .)
		
		replace s_`v' = "`v_dash'(AN)_ratio`c'/AN" if iso == "`c'" & missing(`v')
		replace q_`v' = 1                   if iso == "`c'" & missing(`v')
		replace `v' = `v'AN*ratio`c'_ANusd  if iso == "`c'" & missing(`v')
	}
}	
drop aux* *AN *ANlcu

drop if mi(iso)

//Keep core countries only
merge 1:1 iso year using "$work_data/import-core-country-codes-year-output.dta", nogen keepusing(corecountry TH)
keep if corecountry == 1

// merge with tradebalances 
// merge 1:1 iso year using "$current_account/tradebalances.dta", nogen keepusing(tradebalance exports imports)
// ------------ 6. Convert values in GDP USD -------------------------------- //
//	bring GDP in usd
merge 1:1 iso year using "$work_data/retropolate-gdp.dta", nogen keep(master matched) keepusing(gdp) 
merge 1:1 iso year using "$work_data/exchange-rates.dta" , nogen keep(master matched) keepusing(exrate_usd) 
merge 1:1 iso year using "$work_data/price-index.dta"    , nogen keep(master matched) keepusing(index) 

gen double gdp_idx = gdp*index
//gen double gdp_xrate = gdp/exrate_usd
gen double gdp_usd = gdp_idx/exrate_usd

drop gdp 	
sort iso year 
keep if inrange(year, 1970, $pastyear )


//Express all variables as share of GDP
foreach v in compemp_credit compemp_debit otherpinc_credit goods_credit goods_debit /// total_debit total_credit errors_net exports imports tradebalance 
 otherpinc_debit secinc_credit secinc_debit trade_credit trade_debit capital_credit capital_debit foreignaid_credit remittances_credit othtrans_credit foreignaid_debit remittances_debit othtrans_debit /// 
 travel_credit travel_debit travel_pers_debit travel_pers_credit travel_bus_debit travel_bus_credit trans_credit trans_debit trans_fr_credit trans_fr_debit trans_pass_credit trans_pass_debit otherservices_credit otherservices_debit {
replace `v' = `v'/gdp_usd
}

// replacing trade balance when it's too big of a GDP share
/*
gen net_trade = trade_credit - trade_debit
replace tradebalance = . if tradebalance < - 1 & net_trade >= -1
replace tradebalance = . if tradebalance > 1 & !mi(tradebalance) & net_trade <= 1 
drop net_trade 
*/

// ------------ 7. Complete variables --------------------------------------- //
// ----------------- 7.1 Interpolate missing values within the series 
foreach v in compemp_credit compemp_debit otherpinc_credit goods_credit goods_debit /// total_debit total_credit errors_net
 otherpinc_debit secinc_credit secinc_debit  trade_credit trade_debit capital_credit capital_debit foreignaid_credit remittances_credit remittances_debit othtrans_credit foreignaid_debit othtrans_debit /// 
 travel_credit travel_debit travel_pers_debit travel_pers_credit travel_bus_debit travel_bus_credit trans_credit trans_debit trans_fr_credit trans_fr_debit trans_pass_credit trans_pass_debit otherservices_credit otherservices_debit {
	replace `v'            =.  if `v' == 0 & neg`v' != 1
	bys iso : egen tot`v'  = total(abs(`v')), missing
	gen flagcountry`v'     = 1 if tot`v' == .
	replace flagcountry`v' = 0 if missing(flagcountry`v')
	drop tot`v'
	gen flag`v'            = 1 if mi(`v')
	replace flag`v'        = 0 if missing(flag`v')

}
drop neg* 

so iso year
foreach v in compemp_credit compemp_debit otherpinc_credit goods_credit goods_debit /// total_debit total_credit errors_net
 otherpinc_debit secinc_credit secinc_debit  trade_credit trade_debit capital_credit capital_debit foreignaid_credit remittances_credit remittances_debit othtrans_credit foreignaid_debit othtrans_debit /// 
 travel_credit travel_debit travel_pers_debit travel_pers_credit travel_bus_debit travel_bus_credit trans_credit trans_debit trans_fr_credit trans_fr_debit trans_pass_credit trans_pass_debit otherservices_credit otherservices_debit {
	by iso : ipolate `v' year      if corecountry == 1 & flagcountry`v' == 0, gen(x`v') 
	replace q_`v' = 3              if missing(`v')  & x`v'!=.
	replace s_`v' = "ipol" if missing(`v')  & x`v'!=.
	replace   `v' = x`v'           if missing(`v') 
	drop x`v'
}

* Generate reigons
foreach level in undet un {
	kountry iso, from(iso2c) geo(`level')

replace GEO = "Western Asia" 	if iso == "AE" & "`level'" == "undet"
replace GEO = "Caribbean" 		if iso == "CW" & "`level'" == "undet"
replace GEO = "Caribbean"		if iso == "SX" & "`level'" == "undet"
replace GEO = "Caribbean" 		if iso == "BQ" & "`level'" == "undet"
replace GEO = "Southern Europe" if iso == "KS" & "`level'" == "undet"
replace GEO = "Southern Europe" if iso == "ME" & "`level'" == "undet"
replace GEO = "Eastern Asia" 	if iso == "TW" & "`level'" == "undet"
replace GEO = "Northern Europe" if iso == "GG" & "`level'" == "undet"
replace GEO = "Northern Europe" if iso == "JE" & "`level'" == "undet"
replace GEO = "Northern Europe" if iso == "IM" & "`level'" == "undet"

replace GEO = "Asia"            if inlist(iso, "AE", "TW") & "`level'" == "un"
replace GEO = "Americas"        if inlist(iso, "CW", "SX", "BQ") & "`level'" == "un"
replace GEO = "Europe"          if inlist(iso, "KS", "ME", "GG", "JE", "IM") & "`level'" == "un"
ren GEO geo`level'
drop NAMES_STD 
}

gen soviet = 1 if inlist(iso, "AZ", "AM", "BY", "KG", "KZ", "GE") ///
				| inlist(iso, "TJ", "MD", "TM", "UA", "UZ") ///
				| inlist(iso, "EE", "LT", "LV", "RU", "SU")

gen yugosl = 1 if inlist(iso, "BA", "HR", "MK", "RS") ///
				| inlist(iso, "KS", "ME", "SI", "YU")

gen other = 1 if inlist(iso, "ER", "EH", "CS", "CZ", "SK", "SD", "SS", "TL") ///
			   | inlist(iso, "ID", "SX", "CW", "AN", "YE", "ZW", "IQ", "TW")
			   
// ----------------- 7.2 Carryforward 
foreach v in compemp_credit compemp_debit otherpinc_credit goods_credit goods_debit /// total_debit total_credit errors_net
 otherpinc_debit secinc_credit secinc_debit  trade_credit trade_debit capital_credit capital_debit foreignaid_credit remittances_credit remittances_debit othtrans_credit foreignaid_debit othtrans_debit /// 
 travel_credit travel_debit travel_pers_debit travel_pers_credit travel_bus_debit travel_bus_credit trans_credit trans_debit trans_fr_credit trans_fr_debit trans_pass_credit trans_pass_debit otherservices_credit otherservices_debit {

	so iso year
	by iso: carryforward `v' if corecountry == 1, replace 

	gsort iso -year 
	by iso: carryforward `v' if corecountry == 1, replace
	
	replace s_`v' = "carryfor" if !missing(`v') & missing(s_`v')
	replace q_`v' = 1              if !missing(`v') & missing(q_`v')
}

*IQ has an absurd large amount because it's 2005, just after the war 
// we adjust it
gen aux = capital_credit      if iso == "IQ" & year == 2007 
bys iso : egen aux2 = mode(aux)
replace capital_credit = aux2 if iso == "IQ" & year < 2005
drop aux*
replace s_capital_credit = "carryfor" if  iso == "IQ" & year < 2005
replace q_capital_credit = 1              if  iso == "IQ" & year < 2005

*KW presents issues with too low value for secinc_credit due to the gulf war in 1991. we use the value in 1993 rather than 1992 to carrybackwards
gen aux = secinc_credit      if iso == "KW" & year == 1993 
bys iso : egen aux2 = mode(aux)
replace secinc_credit = aux2 if iso == "KW" & year < 1992
drop aux*
replace s_secinc_credit = "carryfor" if  iso == "KW" & year < 1992 
replace q_secinc_credit = 1              if  iso == "KW" & year < 1992 

// ----------------- 7.3 Fill missing with regional means 
foreach v in compemp_credit compemp_debit otherpinc_credit goods_credit goods_debit ///  total_debit total_credit errors_net
 otherpinc_debit secinc_credit secinc_debit  trade_credit trade_debit capital_credit capital_debit foreignaid_credit remittances_credit remittances_debit othtrans_credit foreignaid_debit othtrans_debit /// 
 travel_credit travel_debit travel_pers_debit travel_pers_credit travel_bus_debit travel_bus_credit trans_credit trans_debit trans_fr_credit trans_fr_debit trans_pass_credit trans_pass_debit otherservices_credit otherservices_debit {
		
	foreach level in undet un {
			 bys geo`level' year : egen av`level'`v' = mean(`v') if corecountry == 1 // & TH == 0 
	}
	replace `v' = avundet`v'         if missing(`v')  & flagcountry`v' == 1 
	replace s_`v' = "reg" + geoundet if !missing(`v') & missing(s_`v')
	
	replace `v' = avun`v'            if missing(`v')  & flagcountry`v' == 1
	replace s_`v' = "reg" + geoun    if !missing(`v') & missing(s_`v')
	
	replace q_`v' = 0                if !missing(`v') & missing(q_`v')
}
drop av*

*issues with TL in other_pinc 
bys geoundet year : egen avundetotherpinc_credit = mean(otherpinc_credit) if corecountry == 1 & TH == 0 & iso != "TL" & flagcountryotherpinc_credit == 0
bys year : egen aux = mode(avundetotherpinc_credit)
replace otherpinc_credit = aux if flagcountryotherpinc_credit == 1 & geoundet == "South-Eastern Asia"
drop aux* 
replace s_otherpinc_credit = "reg" + geoundet if flagcountryotherpinc_credit == 1 & geoundet == "South-Eastern Asia"
replace q_otherpinc_credit = 0                  if flagcountryotherpinc_credit == 1 & geoundet == "South-Eastern Asia"

/* debit is raw data so I'm leaving unchanged for now
*issues with KW in secinc 1991
bys geoundet year : egen avundetsecinc_credit = mean(secinc_credit) if corecountry == 1 & TH == 0 & iso != "KW" & flagcountrysecinc_credit == 0 & year == 1991
bys year : egen aux = mode(avundetsecinc_credit)
replace secinc_credit = aux if flagcountrysecinc_credit == 1 & geoundet == "Western Asia" & year == 1991
drop aux* 

bys geoundet year : egen avundetsecinc_debit = mean(secinc_debit) if corecountry == 1 & TH == 0 & iso != "KW" & flagcountrysecinc_debit == 0 & year == 1991
bys year : egen aux = mode(avundetsecinc_debit)
replace secinc_debit = aux if flagcountrysecinc_debit == 1 & geoundet == "Western Asia" & year == 1991
drop aux* 
*/
drop av*

*issues with NA in otherpinc 2009 onward 
bys geoundet year : egen avundetotherpinc_credit = mean(otherpinc_credit) if corecountry == 1 & TH == 0 & iso != "NA" & flagcountryotherpinc_credit == 0
bys year : egen aux = mode(avundetotherpinc_credit)
replace otherpinc_credit = aux                  if flagcountryotherpinc_credit == 1 & geoundet == "Southern Africa"
drop aux* 
replace s_otherpinc_credit = "reg" + geoundet if flagcountryotherpinc_credit == 1 & geoundet == "Southern Africa"
replace q_otherpinc_credit = 0                  if flagcountryotherpinc_credit == 1 & geoundet == "Southern Africa"

bys geoundet year : egen avundetotherpinc_debit = mean(otherpinc_debit) if corecountry == 1 & TH == 0 & iso != "NA" & flagcountryotherpinc_debit == 0
bys year : egen aux = mode(avundetotherpinc_debit)
replace otherpinc_debit= aux                   if flagcountryotherpinc_debit == 1 & geoundet == "Southern Africa"
drop aux* av*
replace s_otherpinc_debit = "reg" + geoundet if flagcountryotherpinc_debit == 1 & geoundet == "Southern Africa"
replace q_otherpinc_debit = 0                  if flagcountryotherpinc_debit == 1 & geoundet == "Southern Africa"

/*
//Fill missing with TH average for TH
foreach v in compemp_credit compemp_debit otherpinc_credit /// total_debit total_credit errors_net
 otherpinc_debit secinc_credit secinc_debit trade_credit trade_debit capital_credit capital_debit foreignaid_credit remittances_credit othtrans_credit foreignaid_debit remittances_debit othtrans_debit { 
	
bys year : egen med`v' = median(`v') if corecountry == 1 & TH == 1 

replace `v' = med`v' if missing(`v') & flagcountry`v' == 1

}
drop med*
*/

foreach x in credit debit {
	replace   otherpinc_`x' =.    if year < 1991
	replace s_otherpinc_`x' ="" if year < 1991
	replace q_otherpinc_`x' =.  if year < 1991        
}

preserve 
	gen net_trade    = trade_credit - trade_debit 
	*gen s_net_trade = s_trade_credit
	*gen q_net_trade = q_trade_credit
	
	keep iso year trade_credit trade_debit net_trade gdp_us
	
	label data "generated by currentaccount.do"
	save "$work_data/bop_tradeusd.dta", replace
restore 

// Separating trade in services and trade in goods
// if trade in goods is bigger than total trade we replace with the ratio
/*
ren (exports imports tradebalance) (tgxrx tgmpx tgnnx)

gen ratio_tgxrx = tgxrx/trade_credit
replace ratio_tgxrx =. if ratio_tgxrx >= 1
gen ratio_tgmpx = tgmpx/trade_debit
replace ratio_tgmpx =. if ratio_tgmpx >= 1

sort iso year 
carryforward ratio_tgxrx ratio_tgmpx, replace
gsort iso -year 
carryforward ratio_tgxrx ratio_tgmpx, replace

replace tgxrx = trade_credit*(ratio_tgxrx) 
replace tgmpx = trade_debit*(ratio_tgmpx) 

gen tsxrx = trade_credit - tgxrx if flagtrade_credit == 0
gen tsmpx = trade_debit - tgmpx if flagtrade_debit == 0

replace tsxrx = travel_pers_credit + travel_bus_credit + trans_fr_credit + trans_pass_credit + otherservices_credit if flagtrade_credit == 1
replace tsmpx = travel_pers_debit + travel_bus_debit + trans_fr_debit + trans_pass_debit + otherservices_debit if flagtrade_debit == 1

drop ratio* 
ren (tgxrx tgmpx) (goods_credit goods_debit)
ren (tsxrx tsmpx) (service_credit service_debit)
drop tgnnx


// rescaling subcomponents of trade in services 
gen ratio_serv_credit = (travel_pers_credit + travel_bus_credit + trans_fr_credit + trans_pass_credit + otherservices_credit)/service_credit
gen ratio_serv_debit = (travel_pers_debit + travel_bus_debit + trans_fr_debit + trans_pass_debit + otherservices_debit)/service_debit
foreach var in travel_pers_credit travel_bus_credit trans_fr_credit trans_pass_credit otherservices_credit {
	replace `var' = `var'/ratio_serv_credit
}
foreach var in travel_pers_debit travel_bus_debit trans_fr_debit trans_pass_debit otherservices_debit {
	replace `var' = `var'/ratio_serv_debit
}
drop ratio*
*/
// ------------ 8. Ensure consistency --------------------------------------- //
*allocating the difference proportionally
foreach v in compemp otherpinc secinc foreignaid remittances othtrans trade capital goods travel trans otherservices { // service
	replace `v'_credit = `v'_credit*gdp_usd
	replace `v'_debit  = `v'_debit*gdp_usd
	gen net_`v' = `v'_credit - `v'_debit

	bys year : egen tot`v'_credit = total(`v'_credit)
	bys year : egen tot`v'_debit  = total(`v'_debit)

	gen aux`v'_credit = abs(`v'_credit)
	gen aux`v'_debit  = abs(`v'_debit)
	bys year : egen totaux`v'_credit = total(aux`v'_credit)
	bys year : egen totaux`v'_debit  = total(aux`v'_debit)
}
drop aux*

gen totnet_compemp       = (totcompemp_credit + totcompemp_debit)/2 
gen totnet_otherpinc     = (tototherpinc_credit + tototherpinc_debit)/2 
gen totnet_secinc        = (totsecinc_credit + totsecinc_debit)/2
gen totnet_foreignaid    = (totforeignaid_credit + totforeignaid_debit)/2
gen totnet_remittances   = (totremittances_credit + totremittances_debit)/2
gen totnet_othtrans      = (totothtrans_credit + totothtrans_debit)/2
gen totnet_capital       = (totcapital_credit + totcapital_debit)/2
gen totnet_goods         = (totgoods_credit + totgoods_debit)/2
*gen totnet_services     = (totservices_credit + totservices_debit)/2
gen totnet_travel        = (tottravel_credit + tottravel_debit)/2
gen totnet_trans         = (tottrans_credit + tottrans_debit)/2
gen totnet_otherservices = (tototherservices_credit + tototherservices_debit)/2


// unadjusted world
preserve 
	bys year : egen totgdpusd = total(gdp_usd)
	ren (totnet_travel tottravel_credit tottravel_debit) (tsvnx tsvrx tsvpx)
	ren (totnet_trans tottrans_credit tottrans_debit) (tstnx tstrx tstpx)
	ren (totnet_otherservices tototherservices_credit tototherservices_debit) (tsonx tsorx tsopx)
	collapse (mean) tsvnx tsvrx tsvpx tstnx tstrx tstpx tsonx tsorx tsopx totgdpusd, by(year)
	ren totgdpusd gdp_usd
	gen iso = "UnadjustedWorld"
	sa "$work_data/services_trade_unadj_world.dta", replace
restore

foreach v in secinc foreignaid remittances othtrans capital goods travel trans otherservices {
	replace tot`v'_credit = totnet_`v' - tot`v'_credit
	replace tot`v'_debit  = totnet_`v' - tot`v'_debit
}

foreach v in secinc foreignaid remittances othtrans capital goods travel trans otherservices {
	gen ratio_`v'_credit = `v'_credit/totaux`v'_credit
	gen ratio_`v'_debit  = `v'_debit/totaux`v'_debit
	
	replace `v'_credit = `v'_credit + tot`v'_credit*ratio_`v'_credit 
	replace `v'_debit  = `v'_debit + tot`v'_debit*ratio_`v'_debit 
}
drop ratio* net* tot* 

// ----------------- 8.1 calcuate estimates after adjustments

foreach x in credit debit {
	gen     service_`x'  = travel_`x' + trans_`x' + otherservices_`x'
	quality  travel_`x' trans_`x' otherservices_`x', gen(q_service_`x')
	gen   s_service_`x' = "travel-`x',trans-`x',otherservices-`x'"

	replace   trade_`x' = goods_`x' + service_`x'
	replace q_trade_`x' = min(3, cond(goods_`x' >= service_`x', q_goods_`x', q_service_`x'))
	replace s_trade_`x' = "goods-`x',service-`x'"  
} 

//	adjusting secinc
* Replacing the remittance accounts by the ones galculated in IMFBoP remittances do-file
drop remittances_credit remittances_debit
merge 1:1 iso year using "$work_data/imfbop-remittances.dta", nogenerate
drop *net_remittances

foreach x in credit debit {
	replace secinc_`x'  =  foreignaid_`x' + remittances_`x' + othtrans_`x'
	quality foreignaid_`x' remittances_`x' othtrans_`x', gen(temp)
	replace q_secinc_`x' = temp 
	
	replace s_secinc_`x' = "foreignaid-`x',remittances-`x',othtrans-`x'" if !missing(temp)
	drop temp
}

//Generate nets
foreach x in compemp otherpinc secinc foreignaid remittances othtrans capital trade service goods travel trans travel_pers travel_bus trans_fr trans_pass otherservices {  
	gen   net_`x' = `x'_credit - `x'_debit
	quality  `x'_credit `x'_debit,gen(q_net_`x') 
	gen s_net_`x' = "`x'-credit,`x'-debit"
}

// Calcualate exports and imports
gen   exports = goods_credit + service_credit
quality goods_credit service_credit, gen(q_exports)
gen s_exports = "tgxrx,service-credit"  if !missing(q_exports)


gen   imports = goods_debit + service_debit 
quality goods_debit service_debit,gen(q_imports)
gen s_imports = "tgmpx,service-debit" if !missing(q_imports)


gen    tradebalance = exports - imports 
quality exports imports, gen(q_tradebalance)
gen  s_tradebalance = s_exports if !missing(q_tradebalance)


// ren (trade_credit trade_debit net_trade) (exports imports tradebalance)
ren (*goods_credit *goods_debit *net_goods) (*tgxrx *tgmpx *tgnnx)
ren (*service_credit *service_debit *net_service) (*tsxrx *tsmpx *tsnnx)

keep iso year *exports *imports *tradebalance *otherpinc_credit *otherpinc_debit *net_otherpinc *secinc_credit *secinc_debit *net_secinc *capital_credit *capital_debit *net_capital *tgxrx *tgmpx *tgnnx *tsxrx *tsmpx *tsnnx *foreignaid_credit *remittances_credit *othtrans_credit *foreignaid_debit *remittances_debit *othtrans_debit *net_foreignaid *net_remittances *net_othtrans gdp_us *travel_credit *travel_debit *trans_credit *trans_debit *travel_pers_credit *travel_bus_credit *travel_pers_debit *travel_bus_debit *trans_fr_credit *trans_pass_credit *trans_fr_debit *trans_pass_debit *net_travel_pers *net_travel_bus *net_trans_fr *net_trans_pass *net_otherservices *net_travel *net_trans *otherservices_credit *otherservices_debit gdp_idx //gdp_xrate
drop flag*

foreach v in exports imports tradebalance otherpinc_credit otherpinc_debit net_otherpinc secinc_credit secinc_debit net_secinc capital_credit capital_debit net_capital tgxrx tgmpx tgnnx tsxrx tsmpx tsnnx foreignaid_credit remittances_credit othtrans_credit foreignaid_debit remittances_debit othtrans_debi net_foreignaid net_remittances net_othtrans travel_credit travel_debit trans_credit trans_debit travel_pers_credit travel_bus_credit travel_pers_debit travel_bus_debit trans_fr_credit trans_pass_credit trans_fr_debit trans_pass_debit net_travel_pers net_travel_bus net_trans_fr net_trans_pass net_otherservices net_travel net_trans otherservices_credit otherservices_debit {
	replace `v' = `v'/gdp_us
}

ren *exports 			*tbxrx
ren *imports 			*tbmpx
ren *tradebalance 		*tbnnx
*ren *otherpinc_credit 	*opirx
*ren *otherpinc_debit 	*opipx
*ren *net_otherpinc 	*opinx
ren *secinc_credit 		*scirx
ren *secinc_debit 		*scipx
ren *net_secinc 		*scinx
ren *foreignaid_debit	*scgpx
ren *foreignaid_credit	*scgrx
ren *net_foreignaid		*scgnx
ren *remittances_debit	*scrpx
ren *remittances_credit	*scrrx
ren *net_remittances	*scrnx
ren *othtrans_debit		*scopx
ren *othtrans_credit	*scorx
ren *net_othtrans		*sconx
ren *capital_credit 	*fkarx
ren *capital_debit 		*fkapx
ren *net_capital 		*fkanx

ren *travel_credit		*tsvrx 
ren *travel_debit		*tsvpx 
ren *net_travel			*tsvnx 
ren *travel_pers_credit	*tvprx 
ren *travel_pers_debit	*tvppx 
ren *net_travel_pers	*tvpnx 
ren *travel_bus_credit	*tvbrx 
ren *travel_bus_debit	*tvbpx 
ren *net_travel_bus		*tvbnx 

ren *trans_credit		*tstrx 
ren *trans_debit		*tstpx 
ren *net_trans			*tstnx 
ren *trans_fr_credit	*ttfrx 
ren *trans_fr_debit		*ttfpx 
ren *net_trans_fr		*ttfnx 
ren *trans_pass_credit	*ttprx 
ren *trans_pass_debit	*ttppx 
ren *net_trans_pass		*ttpnx 

ren *otherservices_credit *tsorx 
ren *otherservices_debit  *tsopx 
ren *net_otherservices	  *tsonx 
                  
drop *otherpinc_credit *otherpinc_debit *net_otherpinc
/*
enforce (tbxrx = tgxrx + tsxrx) ///
		(tbmpx = tgmpx + tsmpx) ///
		(tbnnx = tgnnx + tsnnx) ///
		(tbnnx = tbxrx - tbmpx) ///
		(tgnnx = tgxrx - tgmpx) ///
		(tsvnx = tsvrx - tsvpx) ///
		(tstnx = tstrx - tstpx) ///		
		(tsonx = tsorx - tsopx) ///		
		(tsxrx = tsvrx + tstrx + tsorx) ///
		(tsmpx = tsvpx + tstpx + tsopx) ///
		(scgnx = scgrx - scgpx) ///
		(scrnx = scrrx - scrpx) ///
		(sconx = scorx - scopx) /// 
		(scinx = scgnx + scrnx + sconx) /// 
		(scinx = scirx - scipx) /// 
		(tsnnx = tsvnx + tstnx + tsonx) /// 
		(tsnnx = tsxrx - tsmpx), fixed(tgxrx tgmpx tsxrx tsmpx) replace force
*/


* Replacing the good accounts by the ones galculated in IMFBoP gravity do-file
drop *tgxrx *tgmpx *tgnnx
merge 1:1 iso year using "$work_data/imfbop-tradegoods-gravity.dta", nogenerate

gen    net_goods = goods_credit - goods_debit
quality goods_credit  goods_debit, gen(q_net_goods)
gen  s_net_goods = "tgxrx,tgmpx" if !missing(q_net_goods)
rename (*goods_credit *goods_debit *net_goods) (*tgxrx *tgmpx *tgnnx)

recast double gdp_usd

* Calibration	
enforce (tbxrx = tgxrx + tsxrx) ///
		(tbmpx = tgmpx + tsmpx) ///
		(tbnnx = tgnnx + tsnnx) ///
		(tbnnx = tbxrx - tbmpx) ///
		(tgnnx = tgxrx - tgmpx) ///
		(tsvnx = tsvrx - tsvpx) ///
		(tstnx = tstrx - tstpx) ///		
		(tsonx = tsorx - tsopx) ///		
		(tsxrx = tsvrx + tstrx + tsorx) ///
		(tsmpx = tsvpx + tstpx + tsopx) ///
		(scgnx = scgrx - scgpx) ///
		(scrnx = scrrx - scrpx) ///
		(sconx = scorx - scopx) /// 
		(scinx = scgnx + scrnx + sconx) /// 
		(scinx = scirx - scipx) /// 
		(tsnnx = tsvnx + tstnx + tsonx) /// 
		(tsnnx = tsxrx - tsmpx), fixed(tgxrx tgmpx tsxrx tsmpx tbxrx tbmpx scirx scipx) prefix(new) replace force

foreach v of varlist new* {
    local base = subinstr("`v'", "new", "", .)

    replace q_`base' = 3 if missing(`base') & !missing(`v')
	replace s_`base' = "enforce" if missing(`base') & !missing(`v')
    replace   `base' = `v'
}
drop new* 

//--------  Import data from Nievas Piketty 2025 ---------------------------- //
preserve
	* Import Data
	use "$work_data/nievaspiketty2025_70.dta", clear
	keep if year<=2022
	gen fivelet=substr(widcode,2,5)
	drop widcode p
	keep if inlist(fivelet,"tgxrx", "tgmpx", "tsxrx", "tsmpx", "tbxrx", "tbmpx", "scirx", "scipx")
	
	*Format for importing
	reshape wide value q_ s_, i(iso year) j(fivelet) string
	rename value* *
	
	
	
	tempfile np2025
	save `np2025'
	
	* Copy the subregional agregates
	keep if inlist(substr(iso, 1, 1), "X", "O") | inlist(iso, "QL","QM","WO","QE")
	renvars scipx-tsxrx, prefix(paper_)
	rename iso region2
	tempfile np2025_reg
	save `np2025_reg'
restore

*merge NP2025
merge 1:1 iso year using "`np2025'", update replace nogenerate

order iso year gdp_idx gdp_usd


// Adjust countries in residual regions to fitin in the residual regions of NP2025
* Step 1: Call region defintions
merge 1:1 iso year using "$work_data/import-core-country-codes-year-output.dta", nogen keepusing(region2 corecountry)
drop if corecountry!=1  & year>= 1970
sort iso year 

 *calculate gdp of regions
bys year region2: egen reg_gdp_usd = total(gdp_usd) 
replace 			   reg_gdp_usd = round(reg_gdp_usd,1) 
replace 			   reg_gdp_usd = .                    if missing(region2)

* Bring regions from Paper
merge m:1 region2 year using "`np2025_reg'", nogenerate keep(master match)

* Step 2: Calculate monetary values of the variables
foreach v in tgxrx tgmpx tsxrx tsmpx tbxrx tbmpx scirx scipx {
	replace `v'=`v'* gdp_usd
	replace paper_`v'=paper_`v'* reg_gdp_usd
}

* Step 3: Calculate total values by region-year
foreach v in tgxrx tgmpx tsxrx tsmpx tbxrx tbmpx scirx scipx {
    gen double abs_`v' = abs(`v')
    bys region2 year: egen total_`v' = total(`v')         // Raw regional sum
    bys region2 year: egen total_abs_`v' = total(abs_`v') // For proportional adjustment
}

* Step 4: Compute the net total (e.g. tgxrx - tgmpx) vs paper values
foreach v in tgxrx tgmpx tsxrx tsmpx tbxrx tbmpx scirx scipx {
    gen double totnet_`v' = (paper_`v'- total_abs_`v')
}

* Step 5: Allocate adjustments proportionally for tgxrx and tgmpx
foreach v in tgxrx tgmpx tsxrx tsmpx tbxrx tbmpx scirx scipx{
    gen double prop_`v'   = abs_`v' / total_abs_`v'  // Share in regional total
    gen double adjust_`v' = prop_`v' * totnet_`v'    // Adjustment share
    
	replace s_`v'       = s_`v' + "_adjnp2025" if !missing(region2) & year>=1970 & year<=2022 
	// The q_ should remain the same as we asume with the enforce
	replace    `v'          = `v' + adjust_`v'         if !missing(region2) & year>=1970 & year<=2022 
}
drop corecountry paper_* abs_* adjust_* prop_*  total_* totnet_* reg_gdp_usd

/*

// Make sure that they add-up 0

* Step 1: Calculate total values by region-year
foreach v in tgxrx tgmpx tsxrx tsmpx tbxrx tbmpx scirx scipx {
    gen double abs_`v' = abs(`v')
    bys year: egen total_`v' = total(`v')         // Raw regional sum
    bys year: egen total_abs_`v' = total(abs_`v') // For proportional adjustment
}

* Step 2: Compute the net total which half is the ideal point to be reach in each variable
gen double totnet_tgnnx = (total_abs_tgxrx + total_abs_tgmpx)/2 
gen double totnet_tsnnx = (total_abs_tsxrx + total_abs_tsmpx)/2 
gen double totnet_tbnnx = (total_abs_tbxrx + total_abs_tbmpx)/2 
gen double totnet_scinx = (total_abs_scirx + total_abs_scipx)/2 


* Step 3: Allocate adjustments proportionally for variables
foreach v in tgxrx tgmpx tsxrx tsmpx tbxrx tbmpx scirx scipx{
    gen double prop_`v'   = abs_`v' / total_abs_`v'  
	replace total_abs_`v' = total_abs_`v' - totnet_tgnnx if inlist("`v'", "tgxrx", "tgmpx")
	replace total_abs_`v' = total_abs_`v' - totnet_tsnnx if inlist("`v'", "tsxrx", "tsmpx")
	replace total_abs_`v' = total_abs_`v' - totnet_tbnnx if inlist("`v'", "tbxrx", "tbmpx") 
	replace total_abs_`v' = total_abs_`v' - totnet_scinx if inlist("`v'", "scirx", "scipx")
	gen double adjust_`v' =.
    replace    adjust_`v' = prop_`v' * total_abs_`v' // Adjustment share
    replace    `v'        = `v' - adjust_`v' if year>=1970 & year<=2023
}
drop  abs_* adjust_* prop_*  total_* totnet_*
*/
* Recalculate net values
replace tgnnx = tgxrx - tgmpx
replace tsnnx = tsxrx - tsmpx
replace tbnnx = tbxrx - tbmpx
replace scinx = scirx - scipx

replace s_tgnnx = s_tgnnx + "_adjnp2025" if strpos(s_tgxrx,"_adjnp2025") > 0 | strpos(s_tgmpx,"_adjnp2025") > 0
replace s_tsnnx = s_tsnnx + "_adjnp2025" if strpos(s_tsxrx,"_adjnp2025") > 0 | strpos(s_tsmpx,"_adjnp2025") > 0
replace s_tbnnx = s_tbnnx + "_adjnp2025" if strpos(s_tbxrx,"_adjnp2025") > 0 | strpos(s_tbmpx,"_adjnp2025") > 0
replace s_scinx = s_scinx + "_adjnp2025" if strpos(s_scirx,"_adjnp2025") > 0 | strpos(s_scipx,"_adjnp2025") > 0


* Recalcualte the shares of the GDP
foreach v in tgxrx tgmpx tsxrx tsmpx tbxrx tbmpx scirx scipx tbnnx tgnnx tsnnx scinx {
	replace `v'=`v'/ gdp_usd	
} 
drop region2 // gdp_xrate

//--------------------------------------------------------------------------- //

* Calibration	
enforce (tbxrx = tgxrx + tsxrx) ///
		(tbmpx = tgmpx + tsmpx) ///
		(tbnnx = tgnnx + tsnnx) ///
		(tbnnx = tbxrx - tbmpx) ///
		(tgnnx = tgxrx - tgmpx) ///
		(tsvnx = tsvrx - tsvpx) ///
		(tstnx = tstrx - tstpx) ///		
		(tsonx = tsorx - tsopx) ///		
		(tsxrx = tsvrx + tstrx + tsorx) ///
		(tsmpx = tsvpx + tstpx + tsopx) ///
		(scgnx = scgrx - scgpx) ///
		(scrnx = scrrx - scrpx) ///
		(sconx = scorx - scopx) /// 
		(scinx = scgnx + scrnx + sconx) /// 
		(scinx = scirx - scipx) /// 
		(tsnnx = tsvnx + tstnx + tsonx) /// 
		(tsnnx = tsxrx - tsmpx), fixed(tgxrx tgmpx tsxrx tsmpx tbxrx tbmpx scirx scipx) prefix(new) replace force

foreach v of varlist new* {
    local base = subinstr("`v'", "new", "", .)

    replace q_`base' = 3 if missing(`base') & !missing(`v')
	replace s_`base' = "enforce" if missing(`base') & !missing(`v')
    replace `base' = `v'
}
drop new* 


/*
* checking adding to zero: Option 1
*replace gdp_usd= round(gdp_usd,  0.0000000000000000001) 
foreach var in tbxrx tgxrx tsxrx tbmpx tgmpx tsmpx scirx scipx {
	*replace `var' = round(`var', 0.0000000000000000001)
	replace `var' = `var'*gdp_usd
}

collapse (sum) tbxrx tgxrx tsxrx tbmpx tgmpx tsmpx scirx scipx gdp_usd, by( year)
gen double tbnnx2 = tbxrx - tbmpx
gen double tgnnx2 = tgxrx - tgmpx
gen double tsnnx2 = tsxrx - tsmpx
gen double scinx2 = scirx - scipx

foreach var in tbnnx tgnnx tsnnx scinx{
	replace `var' = `var'/gdp_usd
	replace `var' = round(`var',5)
}



* checking adding to zero: Option 2
foreach var in tbxrx tgxrx tsxrx tbmpx tgmpx tsmpx scirx scipx {
	replace `var' = `var'*gdp_usd
}
replace region2=iso if missing(region2)
collapse (sum) tbxrx tgxrx tsxrx tbmpx tgmpx tsmpx scirx scipx gdp_usd, by( year region2)
gen double tbnnx = tbxrx - tbmpx
gen double tgnnx = tgxrx - tgmpx
gen double tsnnx = tsxrx - tsmpx
gen double scinx = scirx - scipx

foreach var in  tbxrx tgxrx tsxrx tbmpx tgmpx tsmpx scirx scipx  tbnnx tgnnx tsnnx scinx{
	replace `var' = `var'/gdp_usd
	*replace `var' = round(`var',5)
}


* checking adding to zero : Option 3
merge 1:1 iso year using "$work_data/retropolate-gdp.dta", nogenerate keepusing(gdp) keep(master matched)
merge 1:1 iso year using "$work_data/exchange-rates.dta", nogen keepusing(value) keep(master matched)
rename value exrate_usd
*merge 1:1 iso year using "$work_data/price-index.dta", nogen keep(master matched)

gen double gdp_xrate = gdp/exrate_usd

foreach var in tbxrx tgxrx tsxrx tbmpx tgmpx tsmpx scirx scipx gdp_xrate {
	replace `var' = `var'*gdp_xrate
}
collapse (sum) tbxrx tgxrx tsxrx tbmpx tgmpx tsmpx scirx scipx gdp_usd, by( year)
gen double tbnnx = tbxrx - tbmpx
gen double tgnnx = tgxrx - tgmpx
gen double tsnnx = tsxrx - tsmpx
gen double scinx = scirx - scipx
*/

*drop gdp_us

label data "Generated by currentaccount.do"
save "$work_data/bop_currentacc_complete.dta", replace

drop gdp* *tvprx *tvppx *tvpnx *tvbrx *tvbpx *tvbnx *ttfrx *ttfpx *ttfnx *ttppx *ttprx *ttpnx 

save "$work_data/bop_currentacc.dta", replace
