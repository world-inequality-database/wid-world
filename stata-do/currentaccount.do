global EURO `" "AD" "AL" "AT" "BA" "BE" "BG" "CH" "CY" "CZ" "DE" "DK" "EE" "ES" "FI" "FR" "GB" "GG" "GI" "GR" "HR" "HU" "IE" "IM" "IS" "IT" "JE" "KS" "LI" "LT" "LU" "LV" "MC" "MD" "ME" "MK" "MT" "NL" "NO" "PL" "PT" "RO" "RS" "SE" "SI" "SK" "SM" "'
global NAOC `" "AU" "BM" "CA" "FJ" "FM" "GL" "KI" "MH" "NC" "NR" "NZ" "PF" "PG" "PW" "SB" "TO" "TV" "US" "VU" "WS" "'
global LATA `" "AG" "AI" "AR" "AW" "BB" "BO" "BQ" "BR" "BS" "BZ" "CL" "CO" "CR" "CU" "CW" "DM" "DO" "EC" "GD" "GT" "GY" "HN" "HT" "JM" "KN" "KY" "LC" "MS" "MX" "NI" "PA" "PE" "PR" "PY" "SR" "SV" "SX" "TC" "TT" "UY" "VC" "VE" "VG" "'
global MENA `" "AE" "BH" "DZ" "EG" "IL" "IQ" "IR" "JO" "KW" "LB" "LY" "MA" "OM" "PS" "QA" "SA" "SY" "TN" "TR" "YE" "'
global SSAF `" "AO" "BF" "BI" "BJ" "BW" "CD" "CF" "CG" "CI" "CM" "CV" "DJ" "ER" "ET" "GA" "GH" "GM" "GN" "GQ" "GW" "KE" "KM" "LR" "LS" "MG" "ML" "MR" "MU" "MW" "MZ" "NA" "NE" "NG" "RW" "SC" "SD" "SL" "SN" "SO" "SS" "ST" "SZ" "TD" "TG" "TZ" "UG" "ZA" "ZM" "ZW" "'
global RUCA `" "AM" "AZ" "BY" "GE" "KG" "KZ" "RU" "TJ" "TM" "UA" "UZ" "'
global EASA `" "CN" "HK" "JP" "KP" "KR" "MN" "MO" "TW" "'
global SSEA `" "AF" "BD" "BN" "BT" "ID" "IN" "KH" "LA" "LK" "MM" "MV" "MY" "NP"  "PH" "PK" "SG" "TH" "TL" "VN" "'



import delimited "$current_account/BOP_05-13-2024 14-41-48-35.csv", clear

//Keep Current accounts variables 

keep if inlist(indicatorcode, "BXIPCE_BP6_USD", "BMIPCE_BP6_USD", "BMCA_BP6_USD", "BXCA_BP6_USD") | ///
inlist(indicatorcode, "BXIPO_BP6_USD", "BMIPO_BP6_USD", "BXIS_BP6_USD", "BMIS_BP6_USD") | ///     
		inlist(indicatorcode, "BOP_BP6_USD","BMGS_BP6_USD", "BXGS_BP6_USD", "BKA_CD_BP6_USD", "BKA_DB_BP6_USD", "BKT_CD_BP6_USD", "BKT_DB_BP6_USD") | /// 
		inlist(indicatorcode, "BXISG_BP6_USD", "BXISOPT_BP6_USD", "BXISOOT_BP6_USD", "BMISG_BP6_USD", "BMISOPT_BP6_USD", "BMISOOT_BP6_USD" )
		
*Current Account, Primary Income, Compensation of Employees, Credit, US Dollars BXIPCE_BP6_USD 
*Current Account, Primary Income, Compensation of Employees, Debit, US Dollars BMIPCE_BP6_USD


*Current Account, Total, Debit, US Dollars	BMCA_BP6_USD
*Current Account, Total, Credit, US Dollars	BXCA_BP6_USD


*Current Account, Primary Income, Other Primary Income, Credit, US Dollars	BXIPO_BP6_USD
*Current Account, Primary Income, Other Primary Income, Debit, US Dollars	BMIPO_BP6_USD

*Current Account, Secondary Income, Credit, US Dollars	BXIS_BP6_USD
*Current Account, Secondary Income, Debit, US Dollars	BMIS_BP6_USD

*Current Account, Secondary Income, Financial Corporations, Nonfinancial Corporations, Households, and NPISHs, Credit, US Dollars BXISOPT_BP6_USD
*Current Account, Secondary Income, Financial Corporations, Nonfinancial Corporations, Households, and NPISHs, Other Current Transfers, Credit, US Dollars BXISOOT_BP6_USD
*Current Account, Secondary Income, General Government, Credit, US Dollars BXISG_BP6_USD

*Net Errors and Omissions, US Dollars	BOP_BP6_USD
*Supplementary Items, Errors and Omissions (with Fund Record), US Dollars	BOPFR_BP6_USD

*BMGS_BP6_USD Current Account, Goods and Services, Debit, US Dollars
*BXGS_BP6_USD Current Account, Goods and Services, Credit, US Dollars
*BGS_BP6_USD Current Account, Goods and Services, Net, US Dollars


//Rename the variables
replace indicatorname = "trade_credit" if indicatorcode == "BXGS_BP6_USD"
replace indicatorname = "trade_debit" if indicatorcode == "BMGS_BP6_USD"
replace indicatorname = "compemp_debit" if indicatorcode == "BMIPCE_BP6_USD"
replace indicatorname = "compemp_credit" if indicatorcode == "BXIPCE_BP6_USD"
*replace indicatorname = "total_debit" if indicatorcode == "BMCA_BP6_USD"
*replace indicatorname = "total_credit" if indicatorcode == "BXCA_BP6_USD"
replace indicatorname = "otherpinc_credit" if indicatorcode == "BXIPO_BP6_USD"
replace indicatorname = "otherpinc_debit" if indicatorcode == "BMIPO_BP6_USD"
replace indicatorname = "secinc_credit" if indicatorcode == "BXIS_BP6_USD"
replace indicatorname = "foreignaid_credit" if indicatorcode == "BXISG_BP6_USD"
replace indicatorname = "remittances_credit" if indicatorcode == "BXISOPT_BP6_USD"
replace indicatorname = "othtrans_credit" if indicatorcode == "BXISOOT_BP6_USD"
replace indicatorname = "secinc_debit" if indicatorcode == "BMIS_BP6_USD"
replace indicatorname = "foreignaid_debit" if indicatorcode == "BMISG_BP6_USD"
replace indicatorname = "remittances_debit" if indicatorcode == "BMISOPT_BP6_USD"
replace indicatorname = "othtrans_debit" if indicatorcode == "BMISOOT_BP6_USD"
replace indicatorname = "errors_net" if indicatorcode == "BOP_BP6_USD"
replace indicatorname = "capital_credit" if indicatorcode == "BKA_CD_BP6_USD" | indicatorcode == "BKT_CD_BP6_USD"
replace indicatorname = "capital_debit" if indicatorcode == "BKA_DB_BP6_USD" | indicatorcode == "BKT_DB_BP6_USD"
collapse (sum) value, by(countryname countrycode indicatorname timeperiod)

ren timeperiod year
drop if countryname == "Australia" & missing(v) & (indicatorname == "capital_credit" | indicatorname == "capital_debit")

tempfile ca 
sa `ca'

// trade in services 
import delimited "$current_account/BOP_01-10-2025 14-28-14-86.csv", clear

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
Current Account, Goods and Services, Services, Other Services, Credit, US Dollars														BXSO_BP6_USD
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
Current Account, Goods and Services, Services, Other Services, Debit, US Dollars														BMSO_BP6_USD
Current Account, Goods and Services, Services, Transport, Debit, US Dollars																BMSTR_BP6_USD
Current Account, Goods and Services, Services, Travel, Credit, US Dollars																BXSTV_BP6_USD
Current Account, Goods and Services, Services, Transport, Passenger, Credit, US Dollars													BXSTRPA_BP6_USD
Current Account, Goods and Services, Services, Travel, Business, Debit, US Dollars														BMSTVB_BP6_USD
Current Account, Goods and Services, Services, Travel, Personal, Credit, US Dollars														BXSTVP_BP6_USD
Current Account, Goods and Services, Services: Transport Other (Including postal and courier), Credit, US Dollars						BXSTROPC_BP6_USD
Current Account, Goods and Services, Services, Transport, Freight, Debit, US Dollars													BMSTRFR_BP6_USD
Current Account, Goods and Services, Services, Charges for the Use of Intellectual Property nie, Debit, US Dollars						BMSORL_BP6_USD
Current Account, Goods and Services, Services: Transport Other (Including postal and courier), Debit, US Dollars						BMSTROPC_BP6_USD
	  
*/
drop if inlist(indicatorcode, "BXS_BP6_USD", "BMS_BP6_USD", "BS_BP6_USD")

replace indicatorname = "travel_credit" if indicatorcode == "BXSTV_BP6_USD"
replace indicatorname = "travel_debit" if indicatorcode == "BMSTV_BP6_USD"
	replace indicatorname = "travel_pers_debit" if indicatorcode == "BMSTVP_BP6_USD"
	replace indicatorname = "travel_pers_credit" if indicatorcode == "BXSTVP_BP6_USD"
	replace indicatorname = "travel_bus_debit" if indicatorcode == "BMSTVB_BP6_USD"
	replace indicatorname = "travel_bus_credit" if indicatorcode == "BXSTVB_BP6_USD"

replace indicatorname = "trans_credit" if indicatorcode == "BXSTR_BP6_USD"
replace indicatorname = "trans_debit" if indicatorcode == "BMSTR_BP6_USD" 
	replace indicatorname = "trans_fr_credit" if indicatorcode == "BXSTRFR_BP6_USD" | indicatorcode == "BXSTROPC_BP6_USD"
	replace indicatorname = "trans_fr_debit" if indicatorcode == "BMSTRFR_BP6_USD" | indicatorcode == "BMSTROPC_BP6_USD"
	replace indicatorname = "trans_pass_credit" if indicatorcode == "BXSTRPA_BP6_USD"
	replace indicatorname = "trans_pass_debit" if indicatorcode == "BMSTRPA_BP6_USD"

replace indicatorname = "otherservices_credit" if inlist(indicatorcode, "BXSO_BP6_USD", "BXSM_BP6_USD", "BXSR_BP6_USD")
replace indicatorname = "otherservices_debit" if inlist(indicatorcode, "BMSO_BP6_USD", "BMSM_BP6_USD", "BMSR_BP6_USD") 

drop if !inlist(indicatorname, "services_credit", "services_debit", "travel_credit", "travel_debit", "travel_pers_debit", "travel_pers_credit", "travel_bus_debit", "travel_bus_credit") & !inlist(indicatorname, "trans_credit", "trans_debit", "trans_fr_credit", "trans_fr_debit", "trans_pass_credit", "trans_pass_debit", "otherservices_credit", "otherservices_debit") 

collapse (sum) value, by(countryname countrycode indicatorname timeperiod)
ren timeperiod year

tempfile trserv
sa `trserv'

// trade in goods 
import delimited "$current_account/BOP_01-13-2025 16-52-44-31.csv", clear 

// Current Account, Goods and Services, Goods, Debit, US Dollars	BMG_BP6_USD
// Current Account, Goods and Services, Goods, Credit, US Dollars	BXG_BP6_USD

keep if inlist(indicatorcode, "BMG_BP6_USD", "BXG_BP6_USD")

replace indicatorname = "goods_credit" if indicatorcode == "BXG_BP6_USD"
replace indicatorname = "goods_debit" if indicatorcode == "BMG_BP6_USD"

collapse (sum) value, by(countryname countrycode indicatorname timeperiod)
ren timeperiod year

// appending
append using `ca' `trserv'

greshape wide v, i(countryname countrycode year) j(indicatorname) 

renpfix value

foreach v in capital_credit capital_debit compemp_credit compemp_debit foreignaid_credit foreignaid_debit goods_credit goods_debit otherpinc_credit otherpinc_debit otherservices_credit otherservices_debit othtrans_credit othtrans_debit remittances_credit remittances_debit secinc_credit secinc_debit trade_credit trade_debit trans_credit trans_debit trans_fr_credit trans_fr_debit trans_pass_credit trans_pass_debit travel_bus_credit travel_bus_debit travel_credit travel_debit travel_pers_credit travel_pers_debit {
	gen neg`v' = 1 if `v' < 0
	replace neg`v' = 0 if mi(neg`v')	
}

*adding the negative values to the other gross aggregated component
gen aux = 1 if negcapital_credit == 1 & negcapital_debit == 1
replace negcapital_credit = 0 if aux == 1 
replace negcapital_debit = 0 if aux == 1 
cap swapval capital_credit capital_debit if aux == 1 
replace capital_credit = abs(capital_credit) if aux == 1
replace capital_debit = abs(capital_debit) if aux == 1
replace capital_credit = capital_credit - capital_debit if negcapital_debit == 1
replace capital_debit = 0 if negcapital_debit == 1 
replace capital_debit = capital_debit - capital_credit if negcapital_credit == 1 
replace capital_credit = 0 if negcapital_credit == 1
drop aux 

gen aux = 1 if neggoods_credit == 1 & neggoods_debit == 1
replace neggoods_credit = 0 if aux == 1 
replace neggoods_debit = 0 if aux == 1 
cap swapval goods_credit goods_debit if aux == 1 
replace goods_credit = abs(goods_credit) if aux == 1
replace goods_debit = abs(goods_debit) if aux == 1
replace goods_credit = goods_credit - goods_debit if neggoods_debit == 1
replace goods_debit = 0 if neggoods_debit == 1 
replace goods_debit = goods_debit - goods_credit if neggoods_credit == 1 
replace goods_credit = 0 if neggoods_credit == 1
drop aux 

gen aux = 1 if negtrans_credit == 1 & negtrans_debit == 1
replace negtrans_credit = 0 if aux == 1 
replace negtrans_debit = 0 if aux == 1 
cap swapval trans_credit trans_debit if aux == 1 
replace trans_credit = abs(trans_credit) if aux == 1
replace trans_debit = abs(trans_debit) if aux == 1
replace trans_credit = trans_credit - trans_debit if negtrans_debit == 1
replace trans_debit = 0 if negtrans_debit == 1 
replace trans_debit = trans_debit - trans_credit if negtrans_credit == 1 
replace trans_credit = 0 if negtrans_credit == 1
drop aux 

gen aux = 1 if negtravel_credit == 1 & negtravel_debit == 1
replace negtravel_credit = 0 if aux == 1 
replace negtravel_debit = 0 if aux == 1 
cap swapval travel_credit trans_debit if aux == 1 
replace travel_credit = abs(travel_credit) if aux == 1
replace travel_debit = abs(travel_debit) if aux == 1
replace travel_credit = travel_credit - travel_debit if negtravel_debit == 1
replace travel_debit = 0 if negtravel_debit == 1 
replace travel_debit = travel_debit - travel_credit if negtravel_credit == 1 
replace travel_credit = 0 if negtravel_credit == 1
drop aux 

gen aux = 1 if negotherservices_credit == 1 & negotherservices_debit == 1
replace negotherservices_credit = 0 if aux == 1 
replace negotherservices_debit = 0 if aux == 1 
cap swapval otherservices_credit otherservices_debit if aux == 1 
replace otherservices_credit = abs(otherservices_credit) if aux == 1
replace otherservices_debit = abs(otherservices_debit) if aux == 1
replace otherservices_credit = otherservices_credit - otherservices_debit if negotherservices_debit == 1
replace otherservices_debit = 0 if negotherservices_debit == 1 
replace otherservices_debit = otherservices_debit - otherservices_credit if negotherservices_credit == 1 
replace otherservices_credit = 0 if negotherservices_credit == 1
drop aux 

gen aux = 1 if negremittances_credit == 1 & negremittances_debit == 1
replace negremittances_credit = 0 if aux == 1 
replace negremittances_debit = 0 if aux == 1 
cap swapval remittances_credit remittances_debit if aux == 1 
replace remittances_credit = abs(remittances_credit) if aux == 1
replace remittances_debit = abs(remittances_debit) if aux == 1
replace remittances_credit = remittances_credit - remittances_debit if negremittances_debit == 1
replace remittances_debit = 0 if negremittances_debit == 1 
replace remittances_debit = remittances_debit - remittances_credit if negremittances_credit == 1 
replace remittances_credit = 0 if negremittances_credit == 1
drop aux 

gen aux = 1 if negforeignaid_credit == 1 & negforeignaid_debit == 1
replace negforeignaid_credit = 0 if aux == 1 
replace negforeignaid_debit = 0 if aux == 1 
cap swapval foreignaid_credit foreignaid_debit if aux == 1 
replace foreignaid_credit = abs(foreignaid_credit) if aux == 1
replace foreignaid_debit = abs(foreignaid_debit) if aux == 1
replace foreignaid_credit = foreignaid_credit - foreignaid_debit if negforeignaid_debit == 1
replace foreignaid_debit = 0 if negforeignaid_debit == 1 
replace foreignaid_debit = foreignaid_debit - foreignaid_credit if negforeignaid_credit == 1 
replace foreignaid_credit = 0 if negforeignaid_credit == 1
drop aux 

gen aux = 1 if negothtrans_credit == 1 & negothtrans_debit == 1
replace negothtrans_credit = 0 if aux == 1 
replace negothtrans_debit = 0 if aux == 1 
cap swapval othtrans_credit othtrans_debit if aux == 1 
replace othtrans_credit = abs(othtrans_credit) if aux == 1
replace othtrans_debit = abs(othtrans_debit) if aux == 1
replace othtrans_credit = othtrans_credit - othtrans_debit if negothtrans_debit == 1
replace othtrans_debit = 0 if negothtrans_debit == 1 
replace othtrans_debit = othtrans_debit - othtrans_credit if negothtrans_credit == 1 
replace othtrans_credit = 0 if negothtrans_credit == 1
drop aux 

gen aux = 1 if negsecinc_credit == 1 & negsecinc_debit == 1
replace negsecinc_credit = 0 if aux == 1 
replace negsecinc_debit = 0 if aux == 1 
cap swapval secinc_credit secinc_debit if aux == 1 
replace secinc_credit = abs(secinc_credit) if aux == 1
replace secinc_debit = abs(secinc_debit) if aux == 1
replace secinc_credit = secinc_credit - secinc_debit if negsecinc_debit == 1
replace secinc_debit = 0 if negsecinc_debit == 1 
replace secinc_debit = secinc_debit - secinc_credit if negsecinc_credit == 1 
replace secinc_credit = 0 if negsecinc_credit == 1
drop aux 

kountry countrycode, from(imfn) to(iso2c)
ren _ISO2C_ iso 

replace iso="AD" if countryname=="Andorra, Principality of"
replace iso="SS" if countryname=="South Sudan, Rep. of"
replace iso="TC" if countryname=="Turks and Caicos Islands"
replace iso="TV" if countryname=="Tuvalu"
replace iso="RS" if countryname=="Serbia, Rep. of"
replace iso="KV" if countryname=="Kosovo, Rep. of"
replace iso="CW" if countryname=="Curaçao, Kingdom of the Netherlands"
replace iso="SX" if countryname=="Sint Maarten, Kingdom of the Netherlands"
replace iso="PS" if countryname=="West Bank and Gaza"

drop if mi(iso)
drop countrycode

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
		replace `v' = `v'AN*ratio`c'_ANusd if iso == "`c'" & missing(`v')
	}
}	
drop aux* *AN *ANlcu

drop if mi(iso)

//Keep core countries only
merge 1:1 iso year using "$work_data/import-core-country-codes-year-output.dta", nogen keepusing(corecountry TH)
keep if corecountry == 1

// merge with tradebalances 
// merge 1:1 iso year using "$current_account/tradebalances.dta", nogen keepusing(tradebalance exports imports)

//	bring GDP in usd
merge 1:1 iso year using "$work_data/retropolate-gdp.dta", nogenerate keepusing(gdp) keep(master matched)
merge 1:1 iso year using "$work_data/USS-exchange-rates.dta", nogen keepusing(exrate_usd) keep(master matched)
merge 1:1 iso year using "$work_data/price-index.dta", nogen keep(master matched)

gen gdp_idx = gdp*index
	gen gdp_usd = gdp_idx/exrate_usd
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

//Interpolate missing values within the series 
foreach v in compemp_credit compemp_debit otherpinc_credit goods_credit goods_debit /// total_debit total_credit errors_net
 otherpinc_debit secinc_credit secinc_debit  trade_credit trade_debit capital_credit capital_debit foreignaid_credit remittances_credit remittances_debit othtrans_credit foreignaid_debit othtrans_debit /// 
 travel_credit travel_debit travel_pers_debit travel_pers_credit travel_bus_debit travel_bus_credit trans_credit trans_debit trans_fr_credit trans_fr_debit trans_pass_credit trans_pass_debit otherservices_credit otherservices_debit {
	replace `v' =. if `v' == 0 & neg`v' != 1
	bys iso : egen tot`v' = total(abs(`v')), missing
	gen flagcountry`v' = 1 if tot`v' == .
	replace flagcountry`v' = 0 if missing(flagcountry`v')
	drop tot`v'
	gen flag`v' = 1 if mi(`v')
	replace flag`v' = 0 if missing(flag`v')

}
drop neg* 

so iso year
foreach v in compemp_credit compemp_debit otherpinc_credit goods_credit goods_debit /// total_debit total_credit errors_net
 otherpinc_debit secinc_credit secinc_debit  trade_credit trade_debit capital_credit capital_debit foreignaid_credit remittances_credit remittances_debit othtrans_credit foreignaid_debit othtrans_debit /// 
 travel_credit travel_debit travel_pers_debit travel_pers_credit travel_bus_debit travel_bus_credit trans_credit trans_debit trans_fr_credit trans_fr_debit trans_pass_credit trans_pass_debit otherservices_credit otherservices_debit {
	by iso : ipolate `v' year if corecountry == 1 & flagcountry`v' == 0, gen(x`v') 
	replace `v' = x`v' if missing(`v') 
	drop x`v'
}

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

replace GEO = "Asia" if inlist(iso, "AE", "TW") & "`level'" == "un"
replace GEO = "Americas" if inlist(iso, "CW", "SX", "BQ") & "`level'" == "un"
replace GEO = "Europe" if inlist(iso, "KS", "ME", "GG", "JE", "IM") & "`level'" == "un"
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
			   
//Carryforward 
foreach v in compemp_credit compemp_debit otherpinc_credit goods_credit goods_debit /// total_debit total_credit errors_net
 otherpinc_debit secinc_credit secinc_debit  trade_credit trade_debit capital_credit capital_debit foreignaid_credit remittances_credit remittances_debit othtrans_credit foreignaid_debit othtrans_debit /// 
 travel_credit travel_debit travel_pers_debit travel_pers_credit travel_bus_debit travel_bus_credit trans_credit trans_debit trans_fr_credit trans_fr_debit trans_pass_credit trans_pass_debit otherservices_credit otherservices_debit {

so iso year
by iso: carryforward `v' if corecountry == 1, replace 

gsort iso -year 
by iso: carryforward `v' if corecountry == 1, replace
}

*IQ has an absurd large amount because it's 2005, just after the war 
// we adjust it
gen aux = capital_credit if iso == "IQ" & year == 2007 
bys iso : egen aux2 = mode(aux)
replace capital_credit = aux2 if iso == "IQ" & year < 2005
drop aux*

*KW presents issues with too low value for secinc_credit due to the gulf war in 1991. we use the value in 1993 rather than 1992 to carrybackwards
gen aux = secinc_credit if iso == "KW" & year == 1993 
bys iso : egen aux2 = mode(aux)
replace secinc_credit = aux2 if iso == "KW" & year < 1992
drop aux*

//Fill missing with regional means 
foreach v in compemp_credit compemp_debit otherpinc_credit goods_credit goods_debit ///  total_debit total_credit errors_net
 otherpinc_debit secinc_credit secinc_debit  trade_credit trade_debit capital_credit capital_debit foreignaid_credit remittances_credit remittances_debit othtrans_credit foreignaid_debit othtrans_debit /// 
 travel_credit travel_debit travel_pers_debit travel_pers_credit travel_bus_debit travel_bus_credit trans_credit trans_debit trans_fr_credit trans_fr_debit trans_pass_credit trans_pass_debit otherservices_credit otherservices_debit {
	
 foreach level in undet un {
		
  bys geo`level' year : egen av`level'`v' = mean(`v') if corecountry == 1 // & TH == 0 

  }
replace `v' = avundet`v' if missing(`v') & flagcountry`v' == 1 
replace `v' = avun`v' if missing(`v') & flagcountry`v' == 1
}
drop av*
*issues with TL in other_pinc 
bys geoundet year : egen avundetotherpinc_credit = mean(otherpinc_credit) if corecountry == 1 & TH == 0 & iso != "TL" & flagcountryotherpinc_credit == 0
bys year : egen aux = mode(avundetotherpinc_credit)
replace otherpinc_credit = aux if flagcountryotherpinc_credit == 1 & geoundet == "South-Eastern Asia"
drop aux* 

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
replace otherpinc_credit = aux if flagcountryotherpinc_credit == 1 & geoundet == "Southern Africa"
drop aux* 

bys geoundet year : egen avundetotherpinc_debit = mean(otherpinc_debit) if corecountry == 1 & TH == 0 & iso != "NA" & flagcountryotherpinc_debit == 0
bys year : egen aux = mode(avundetotherpinc_debit)
replace otherpinc_debit= aux if flagcountryotherpinc_debit == 1 & geoundet == "Southern Africa"
drop aux* 
drop av*

/*
//Fill missing with TH average for TH
foreach v in compemp_credit compemp_debit otherpinc_credit /// total_debit total_credit errors_net
 otherpinc_debit secinc_credit secinc_debit trade_credit trade_debit capital_credit capital_debit foreignaid_credit remittances_credit othtrans_credit foreignaid_debit remittances_debit othtrans_debit { 
	
bys year : egen med`v' = median(`v') if corecountry == 1 & TH == 1 

replace `v' = med`v' if missing(`v') & flagcountry`v' == 1

}
drop med*
*/

replace otherpinc_credit =. if year < 1991
replace otherpinc_debit =. if year < 1991

preserve 
	gen net_trade = trade_credit - trade_debit 
	keep iso year trade_credit trade_debit net_trade gdp_us
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

*allocating the difference proportionally
foreach v in compemp otherpinc secinc foreignaid remittances othtrans trade capital goods travel trans otherservices { // service
	replace `v'_credit = `v'_credit*gdp_usd
	replace `v'_debit = `v'_debit*gdp_usd
	gen net_`v' = `v'_credit - `v'_debit

	bys year : egen tot`v'_credit = total(`v'_credit)
	bys year : egen tot`v'_debit = total(`v'_debit)

	gen aux`v'_credit = abs(`v'_credit)
	gen aux`v'_debit = abs(`v'_debit)
	bys year : egen totaux`v'_credit = total(aux`v'_credit)
	bys year : egen totaux`v'_debit = total(aux`v'_debit)
}
drop aux*

gen totnet_compemp = (totcompemp_credit + totcompemp_debit)/2 
gen totnet_otherpinc = (tototherpinc_credit + tototherpinc_debit)/2 
gen totnet_secinc = (totsecinc_credit + totsecinc_debit)/2
gen totnet_foreignaid = (totforeignaid_credit + totforeignaid_debit)/2
gen totnet_remittances = (totremittances_credit + totremittances_debit)/2
gen totnet_othtrans = (totothtrans_credit + totothtrans_debit)/2
gen totnet_capital = (totcapital_credit + totcapital_debit)/2
gen totnet_goods = (totgoods_credit + totgoods_debit)/2
*gen totnet_services = (totservices_credit + totservices_debit)/2
gen totnet_travel = (tottravel_credit + tottravel_debit)/2
gen totnet_trans = (tottrans_credit + tottrans_debit)/2
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
	replace tot`v'_debit = totnet_`v' - tot`v'_debit
}

foreach v in secinc foreignaid remittances othtrans capital goods travel trans otherservices {
	gen ratio_`v'_credit = `v'_credit/totaux`v'_credit
	gen ratio_`v'_debit = `v'_debit/totaux`v'_debit
	
replace `v'_credit = `v'_credit + tot`v'_credit*ratio_`v'_credit 
replace `v'_debit = `v'_debit + tot`v'_debit*ratio_`v'_debit 
}
drop ratio* net* tot* 

gen service_credit = travel_credit + trans_credit + otherservices_credit
gen service_debit = travel_debit + trans_debit + otherservices_debit

replace trade_credit = goods_credit + service_credit 
replace trade_debit = goods_debit + service_debit 

//	adjusting secinc
* Replacing the remittance accounts by the ones galculated in IMFBoP remittances do-file
drop remittances_credit remittances_debit
merge 1:1 iso year using "$work_data/imfbop-remittances.dta", nogenerate
drop net_remittances 

replace secinc_debit = foreignaid_debit + remittances_debit + othtrans_debit
replace secinc_credit = foreignaid_credit + remittances_credit + othtrans_credit

foreach x in compemp otherpinc secinc foreignaid remittances othtrans capital trade service goods travel trans travel_pers travel_bus trans_fr trans_pass otherservices {  
	gen net_`x' = `x'_credit - `x'_debit
}

gen exports = goods_credit + service_credit 
gen imports = goods_debit + service_debit 
gen tradebalance = exports - imports 

// ren (trade_credit trade_debit net_trade) (exports imports tradebalance)
ren (goods_credit goods_debit net_goods) (tgxrx tgmpx tgnnx)
ren (service_credit service_debit net_service) (tsxrx tsmpx tsnnx)

keep iso year exports imports tradebalance otherpinc_credit otherpinc_debit net_otherpinc secinc_credit secinc_debit net_secinc capital_credit capital_debit net_capital tgxrx tgmpx tgnnx tsxrx tsmpx tsnnx foreignaid_credit remittances_credit othtrans_credit foreignaid_debit remittances_debit othtrans_debi net_foreignaid net_remittances net_othtrans gdp_us travel_credit travel_debit trans_credit trans_debit travel_pers_credit travel_bus_credit travel_pers_debit travel_bus_debit trans_fr_credit trans_pass_credit trans_fr_debit trans_pass_debit net_travel_pers net_travel_bus net_trans_fr net_trans_pass net_otherservices net_travel net_trans otherservices_credit otherservices_debit gdp_idx

foreach v in exports imports tradebalance otherpinc_credit otherpinc_debit net_otherpinc secinc_credit secinc_debit net_secinc capital_credit capital_debit net_capital tgxrx tgmpx tgnnx tsxrx tsmpx tsnnx foreignaid_credit remittances_credit othtrans_credit foreignaid_debit remittances_debit othtrans_debi net_foreignaid net_remittances net_othtrans travel_credit travel_debit trans_credit trans_debit travel_pers_credit travel_bus_credit travel_pers_debit travel_bus_debit trans_fr_credit trans_pass_credit trans_fr_debit trans_pass_debit net_travel_pers net_travel_bus net_trans_fr net_trans_pass net_otherservices net_travel net_trans otherservices_credit otherservices_debit {
	replace `v' = `v'/gdp_us
}

ren exports 			tbxrx
ren imports 			tbmpx
ren tradebalance 		tbnnx
*ren otherpinc_credit 	opirx
*ren otherpinc_debit 	opipx
*ren net_otherpinc 		opinx
ren secinc_credit 		scirx
ren secinc_debit 		scipx
ren net_secinc 			scinx
ren foreignaid_debit	scgpx
ren foreignaid_credit	scgrx
ren net_foreignaid		scgnx
ren remittances_debit	scrpx
ren remittances_credit	scrrx
ren net_remittances		scrnx
ren othtrans_debit		scopx
ren othtrans_credit		scorx
ren net_othtrans		sconx
ren capital_credit 		fkarx
ren capital_debit 		fkapx
ren net_capital 		fkanx

ren travel_credit		tsvrx 
ren travel_debit		tsvpx 
ren net_travel			tsvnx 
	ren travel_pers_credit	tvprx 
	ren travel_pers_debit	tvppx 
	ren net_travel_pers		tvpnx 
	ren travel_bus_credit	tvbrx 
	ren travel_bus_debit	tvbpx 
	ren net_travel_bus		tvbnx 

ren trans_credit		tstrx 
ren trans_debit			tstpx 
ren net_trans			tstnx 
	ren trans_fr_credit		ttfrx 
	ren trans_fr_debit		ttfpx 
	ren net_trans_fr		ttfnx 
	ren trans_pass_credit	ttprx 
	ren trans_pass_debit	ttppx 
	ren net_trans_pass		ttpnx 

ren otherservices_credit tsorx 
ren otherservices_debit  tsopx 
ren net_otherservices	 tsonx 
                  
drop otherpinc_credit otherpinc_debit net_otherpinc

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

/* checking adding to zero
foreach var in tbxrx tgxrx tsxrx tbmpx tgmpx tsmpx {
	replace `var' = `var'*gdp_usd
}
collapse (sum) tbxrx tgxrx tsxrx tbmpx tgmpx tsmpx gdp_usd, by(year)
gen tbnnx = tbxrx - tbmpx
gen tgnnx = tgxrx - tgmpx
gen tsnnx = tsxrx - tsmpx

foreach var in tbnnx tgnnx tsnnx {
	replace `var' = `var'/gdp_usd
}
*/

* Replacing the good accounts by the ones galculated in IMFBoP gravity do-file
drop tgxrx tgmpx tgnnx
merge 1:1 iso year using "$work_data/imfbop-tradegoods-gravity.dta", nogenerate
gen net_goods = goods_credit - goods_debit
rename (goods_credit goods_debit net_goods) (tgxrx tgmpx tgnnx)

//--------  Import data from Nievas Piketty 2025 ---------------------------- //
preserve
	* Import Data
	use "$work_data/NievasPiketty2025WBOP.dta", clear
	drop if inlist(substr(iso, 1, 1), "X", "O") | inlist(iso, "QL","QM","WO","QE")
	
	* Generate Fivelets as defined in the Wid-Dictionary
	gen      fivelet= "tgxrx"  if origin =="B1b"
	replace  fivelet= "tgmpx"  if origin =="B1c"
	replace  fivelet= "tgxcx"  if origin =="B2b"
	replace  fivelet= "tgmcx"  if origin =="B2c"
	replace  fivelet= "tgxmx"  if origin =="B3b" 
	replace  fivelet= "tgmmx"  if origin =="B3c"
	replace  fivelet= "tsxrx"  if origin =="C1b"
	replace  fivelet= "tsmpx"  if origin =="C1c"
	replace  fivelet= "tbxrx"  if origin =="C1e"
	replace  fivelet= "tbmpx"  if origin =="C1f"
	replace  fivelet= "scirx"  if origin =="E1b"
	replace  fivelet= "scipx"  if origin =="E1c"
	
	*Format for importing
	drop if mi(fivelet)
	drop origin concept
	reshape wide value, i(iso year) j(fivelet) string
	rename value* *
	
	* Calculate net values
	gen double tgnnx = tgxrx - tgmpx
	gen double tgncx = tgxcx - tgmcx
	gen double tgnmx = tgxmx - tgmmx
	gen double tsnnx = tsxrx - tsmpx
	gen double tbnnx = tbxrx - tbmpx
	gen double scinx = scirx - scipx
	
	ds year iso, not
	tempfile np2025
	save `np2025'
restore

*merge NP2025
merge 1:1 iso year using "`np2025'", update replace nogenerate


// Second calibration
enforce (tbxrx = tgxrx + tsxrx) ///
		(tbmpx = tgmpx + tsmpx) ///	
		(tbnnx = tgnnx + tsnnx) ///
		(tgxrx = tgxcx + tgxmx) /// New from NievasPiketty2025
		(tgmpx = tgmcx + tgmmx) /// New from NievasPiketty2025
		(tgnnx = tgncx + tgnmx) /// New from NievasPiketty2025
		(tbnnx = tbxrx - tbmpx) ///
		(tgnnx = tgxrx - tgmpx) ///
		(tgncx = tgxcx - tgmcx) /// New from NievasPiketty2025
	    (tgnmx = tgxmx - tgmmx) /// New from NievasPiketty2025
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
		(tsnnx = tsxrx - tsmpx), fixed( scipx  tbmpx  tgmcx  tgmpx  tgxmx  tsmpx  tgnnx  tgnmx  tbnnx scirx  tbxrx  tgmmx  tgxcx  tgxrx  tsxrx  tgncx  tsnnx  scinx) replace force

//---------------------------------------------------------------------------- //

*drop gdp_us
save "$work_data/bop_currentacc_complete.dta", replace

drop gdp* tvprx tvppx tvpnx tvbrx tvbpx tvbnx ttfrx ttfpx ttfnx ttppx ttprx ttpnx 

save "$work_data/bop_currentacc.dta", replace
