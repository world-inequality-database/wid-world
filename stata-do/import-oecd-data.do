// -------------------------------------------------------------------------- //
// Import OECD national accounts data
// -------------------------------------------------------------------------- //

import delimited "$input_data_dir/oecd-data/national-accounts/SNA_TABLE14A_ARCHIVE_19042021180740312.csv", clear encoding(utf8)
generate series = 10000
tempfile oecd
save "`oecd'"

import delimited "$input_data_dir/oecd-data/national-accounts/SNA_TABLE14A_19042021180438124.csv", clear encoding(utf8)
generate series = 20000
append using "`oecd'"

// Keep GDP (expenditure approach) separately to express everything as a % of GDP
keep if (transact == "B1_GE" | transact == "NFB1GP") & sector == "S1"

keep location year series transact value
greshape wide value, i(location year series) j(transact) string
generate gdp = cond(missing(valueNFB1GP), valueB1_GE, valueNFB1GP)
drop value*

*label data "generate by import-oecd-data.do"
*save "$work_data/current-gdp-oecd.dta", replace
tempfile current_gdp_oecd
save `current_gdp_oecd'

// -------------------------------------------------------------------------- //
// Import data from the different sectors
// -------------------------------------------------------------------------- //

import delimited "$input_data_dir/oecd-data/national-accounts/SNA_TABLE14A_19042021180438124.csv", clear encoding(utf8)
generate series = 20000
append using "`oecd'"

drop if (transact == "B1_GE" | transact == "NFB1GP") & sector == "S1"

merge n:1 location year series using "`current_gdp_oecd'", keep(match) nogenerate
replace value = value/gdp
drop gdp

generate widcode = ""

*save "$work_data/raw-data-oecd.dta", replace
tempfile raw_data_oecd
save `raw_data_oecd'

// -------------------------------------------------------------------------- //
// Total economy and rest of the world
// -------------------------------------------------------------------------- //

use "`raw_data_oecd'", clear

// Consumption of fixed capital for the entire economy
replace widcode = "confc" if sector == "S1" & transact == "NFK1MP"

// Som countries omit taxes on production from S2, so we get it (net) from S1
replace widcode = "taxnx_p1" if sector == "S1" & transact == "NFD2P"
replace widcode = "taxnx_p2" if sector == "S1" & transact == "NFD3P"
replace widcode = "taxnx_r1" if sector == "S1" & transact == "NFD2R"
replace widcode = "taxnx_r2" if sector == "S1" & transact == "NFD3R"

// Foreign income
replace widcode = "comrx" if sector == "S2" & transact == "NFD1P"
replace widcode = "compx" if sector == "S2" & transact == "NFD1R"

replace widcode = "pinrx" if sector == "S2" & transact == "NFD4P"
replace widcode = "pinpx" if sector == "S2" & transact == "NFD4R"

replace widcode = "fsubx" if sector == "S2" & transact == "NFD3P"
replace widcode = "fpsub" if sector == "S2" & transact == "NFD31P"
replace widcode = "fosub" if sector == "S2" & transact == "NFD39P"

replace widcode = "ftaxx" if sector == "S2" & transact == "NFD2R"
replace widcode = "fptax" if sector == "S2" & transact == "NFD21R"
replace widcode = "fotax" if sector == "S2" & transact == "NFD29R"

drop if missing(widcode)
keep location year series widcode value
collapse (mean) value, by(location year series widcode)
greshape wide value, i(location year series) j(widcode)

renvars value*, predrop(5)

// Fix
swapval pinrx pinpx if location == "NZL"

replace taxnx_p1 = -taxnx_p1
replace taxnx_p2 = -taxnx_p2
egen taxnx = rowtotal(taxnx_r1 taxnx_r2 taxnx_p1 taxnx_p2) if inlist(location, "ZAF")
drop taxnx_*

// whenever gross flows are negative, adding them to their counterpart gross flow to ensure everything is positive
foreach v in compx comrx pinpx pinrx fsubx ftaxx {
	gen neg`v' = 1 if `v' < 0
	replace neg`v' = 0 if mi(neg`v')	
}

// Generate metadata
ds  location year series neg*, not
foreach v in `r(varlist)'{
	*Genrate data quality
	gen q_`v' = 5       if `v'!=.
	*Genrate s_
	gen s_`v' = "OECD" if `v'!=.
}

* Net foreign property income
gen aux = 1 if negpinrx == 1 & negpinpx == 1
replace negpinrx = 0 if aux == 1 
replace negpinpx = 0 if aux == 1 
cap swapval pinrx pinpx if aux == 1 
replace pinrx = abs(pinrx) if aux == 1
replace pinpx = abs(pinpx) if aux == 1
replace q_pinrx = min(3, cond(pinrx>=pinpx,q_pinrx, q_pinpx))  if negpinpx == 1
replace s_pinrx = "pinrx,pinpx" if negpinpx == 1
replace   pinrx = pinrx - pinpx if negpinpx == 1
replace q_pinpx = 0 if negpinpx == 1 
replace s_pinpx = "assumed" if negpinpx == 1 
replace   pinpx = 0 if negpinpx == 1 
replace q_pinpx = min(3,cond(pinpx>=pinrx,q_pinpx, q_pinrx)) if negpinrx == 1 
replace s_pinpx = "pinpx,pinrx" if negpinrx == 1 
replace   pinpx = pinpx - pinrx if negpinrx == 1 
replace q_pinrx = 0 if negpinrx == 1
replace s_pinrx = "assumed" if negpinrx == 1
replace   pinrx = 0 if negpinrx == 1
drop aux 

* Net foreign labor income
gen aux = 1 if negcomrx == 1 & negcompx == 1
replace negcomrx = 0 if aux == 1 
replace negcompx = 0 if aux == 1 
cap swapval comrx compx if aux == 1 
replace comrx = abs(comrx) if aux == 1
replace compx = abs(compx) if aux == 1
replace q_comrx = min(3,cond(comrx >=compx,q_comrx, q_compx)) if negcompx == 1
replace s_comrx ="comrx,compx" if negcompx == 1
replace   comrx = comrx - compx if negcompx == 1
replace q_compx = 0 if negcompx == 1 
replace s_compx = "assumed" if negcompx == 1 
replace   compx = 0 if negcompx == 1 
replace q_compx = min(3,cond(compx >= comrx,q_compx, q_comrx)) if negcomrx == 1 
replace s_compx = "compx,comrx" if negcomrx == 1 
replace   compx = compx - comrx if negcomrx == 1 
replace q_comrx = 0 if negcomrx == 1
replace s_comrx = "assumed" if negcomrx == 1
replace   comrx = 0 if negcomrx == 1
drop aux 

* Subsidies & taxes on production and imports
gen aux = 1 if negfsubx == 1 & negftaxx == 1
replace negfsubx = 0 if aux == 1 
replace negftaxx = 0 if aux == 1 
cap swapval fsubx ftaxx if aux == 1 
replace fsubx = abs(fsubx) if aux == 1
replace ftaxx = abs(ftaxx) if aux == 1
replace q_fsubx = min(3,cond(fsubx>= ftaxx,q_fsubx, q_ftaxx)) if negftaxx == 1
replace s_fsubx = "fsubx,ftaxx" if negftaxx == 1
replace   fsubx = fsubx - ftaxx if negftaxx == 1
replace q_ftaxx = 0 if negftaxx == 1 
replace s_ftaxx = "assumed" if negftaxx == 1 
replace   ftaxx = 0 if negftaxx == 1 
replace q_ftaxx = min(3,cond(ftaxx >=fsubx,q_ftaxx, q_fsubx)) if negfsubx == 1 
replace s_ftaxx = "ftaxx,fsubx" if negfsubx == 1 
replace   ftaxx = ftaxx - fsubx if negfsubx == 1 
replace q_fsubx = 0 if negfsubx == 1
replace s_fsubx ="assumed" if negfsubx == 1
replace   fsubx = 0 if negfsubx == 1
drop aux 

replace q_taxnx = min(3,cond(fsubx>=ftaxx, q_fsubx, q_ftaxx)) if missing(taxnx)
replace s_taxnx = "fsubx,ftaxx" if missing(taxnx)
replace   taxnx = fsubx - ftaxx if missing(taxnx)

generate   comnx = comrx - compx
generate   pinnx = pinrx - pinpx
generate   flcir = comrx + pinrx
generate   flcip = compx + pinpx
generate   flcin = flcir - flcip
generate   finrx = flcir + fsubx
generate   finpx = flcip + ftaxx
generate   prtxn = fpsub - fptax
generate   optxn = fosub - fotax
generate   nnfin = flcin + taxnx

quality comrx compx, gen(q_comnx)
quality pinrx pinpx, gen(q_pinnx)
quality comrx pinrx, gen(q_flcir)
quality compx pinpx, gen(q_flcip)
quality flcir flcip, gen(q_flcin)
quality flcir fsubx, gen(q_finrx)
quality flcip ftaxx, gen(q_finpx)
quality fpsub fptax, gen(q_prtxn)
quality fosub fotax, gen(q_optxn)
quality flcin taxnx, gen(q_nnfin)

generate s_comnx = "comrx,compx"
generate s_pinnx = "pinrx,pinpx"
generate s_flcir = "comrx,pinrx"
generate s_flcip = "compx,pinpx"
generate s_flcin = "flcir,flcip"
generate s_finrx = "flcir,fsubx"
generate s_finpx = "flcip,ftaxx"
generate s_prtxn = "fpsub,fptax"
generate s_optxn = "fosub,fotax"
generate s_nnfin = "flcin,taxnx"


foreach v in  compx comrx comnx pinrx pinpx pinnx flcir flcip flcin fpsub fosub flcin finrx finpx prtxn optxn nnfin ftaxx fsubx taxnx{
	replace s_`v'= "" if mi(`v')
	replace q_`v'= .  if mi(`v')
}


*save "$work_data/oecd-foreign-income.dta", replace
tempfile oecd_foreign_income
save `oecd_foreign_income'

// -------------------------------------------------------------------------- //
// Corporations
// -------------------------------------------------------------------------- //

use "`raw_data_oecd'", clear

generate sector_wid = ""
replace sector_wid = "nf" if sector == "S11"
replace sector_wid = "fc" if sector == "S12"

drop if sector_wid == ""

replace widcode = "prp-recv" if transact == "NFD4R"
replace widcode = "prp-paid" if transact == "NFD4P"

replace widcode = "gsr" if transact == "NFB2G_B3GR"
replace widcode = "prg" if transact == "NFB5GR"
replace widcode = "cfc" if transact == "NFK1MP"

replace widcode = "tax" if transact == "NFD5P"
replace widcode = "ssc" if transact == "NFD61R"
replace widcode = "ssb" if transact == "NFD62P"

replace widcode = "ceu" if transact == "NFD1P" 

drop if missing(widcode)
keep location year series widcode value sector_wid
collapse (mean) value, by(location year series widcode sector_wid)
greshape wide value, i(location year series sector_wid) j(widcode)

renvars value*, predrop(5)

// Generate metadata
ds  location year series sector_wid, not
foreach v in `r(varlist)'{
	*Genrate data quality
	gen q_`v' = 5       if `v'!=.
	*Genrate s_
	gen s_`v' = "OECD" if `v'!=.
}

generate   prp = prp_recv - prp_paid
generate s_prp = "prp-recv,prp-paid" if !mi(prp)
quality prp_recv prp_paid, gen(temp)
generate q_prp = temp                if !mi(prp)
drop *prp_recv *prp_paid temp

// Fix data
replace q_gsr = .  if gsr == 0
replace s_gsr = "" if gsr == 0
replace   gsr = .  if gsr == 0
replace q_cfc = .  if cfc == 0
replace s_cfc = "" if cfc == 0
replace   cfc = .  if cfc == 0

replace q_ssb = 0 if missing(ssb) & !missing(tax)
replace s_ssb = "assumed" if missing(ssb) & !missing(tax)
replace   ssb = 0 if missing(ssb) & !missing(tax)
replace q_ssc = 0 if missing(ssc) & !missing(tax)
replace s_ssc = "assumed" if missing(ssc) & !missing(tax)
replace ssc = 0 if missing(ssc) & !missing(tax)

generate seg = prg - tax + ssc - ssb
generate sec = seg - cfc
generate pri = prg - cfc
generate nsr = gsr - cfc

quality prg tax ssc ssb,  gen(q_seg)
quality seg cfc,          gen(q_sec)
quality prg cfc,          gen(q_pri)
quality gsr cfc,          gen(q_nsr)

generate s_seg = "prg,tax,ssc,ssb"
generate s_sec = "seg,cfc"
generate s_pri = "prg,cfc"
generate s_nsr = "gsr,cfc"

foreach v in gsr cfc ssb ssc seg pri sec nsr {
	replace s_`v'= "" if mi(`v')
	replace q_`v'= .  if mi(`v')
}


ds location year series sector_wid, not
local varlist = r(varlist) 
reshape wide `varlist', i(location year series) j(sector_wid) string

// Combine financial and non-financial sectors ourselves if necessary
foreach v of varlist *nf {
	if inlist(substr("`v'",1,2), "s_", "q_") continue
	
	local stub = substr("`v'", 1, 3)
	generate `stub'co = `stub'nf + `stub'fc
	quality  `stub'nf   `stub'fc, gen(temp)
	generate q_`stub'co = temp                if !missing(`stub'co)
	generate s_`stub'co = "`stub'nf,`stub'fc" if !missing(`stub'co)
	drop temp
}


*save "$work_data/oecd-corporations.dta", replace
tempfile oecd_corporations
save `oecd_corporations'

// -------------------------------------------------------------------------- //
// Households and NPISH
// -------------------------------------------------------------------------- //

use "`raw_data_oecd'", clear

generate sector_wid = ""
replace sector_wid = "ho" if sector == "S14"
replace sector_wid = "np" if sector == "S15"
replace sector_wid = "hn" if sector == "S14_S15"
drop if sector_wid == ""

replace widcode = "com" if transact == "NFD1R"
replace widcode = "prg" if transact == "NFB5GR"
replace widcode = "gsm" if transact == "NFB2G_B3GR"
replace widcode = "gsr" if transact == "NFB2GR"
replace widcode = "gmx" if transact == "NFB3GR"
replace widcode = "cfc" if transact == "NFK1MP"

replace widcode = "prp_recv" if transact == "NFD4R"
replace widcode = "prp_paid" if transact == "NFD4P"

replace widcode = "tiw" if transact == "NFD5P"
replace widcode = "ssc_recv" if transact == "NFD61R"
replace widcode = "ssc_paid" if transact == "NFD61P"
replace widcode = "ssb_recv" if transact == "NFD62R"
replace widcode = "ssb_paid" if transact == "NFD62P"

replace widcode = "con" if transact == "NFP3P"
replace widcode = "ceu" if transact == "NFD1P"

drop if missing(widcode)
keep location year series widcode value sector_wid
collapse (mean) value, by(location year series widcode sector_wid)
greshape wide value, i(location year series sector_wid) j(widcode)

renvars value*, predrop(5)

// Generate metadata
ds  location year series sector_wid , not
foreach v in `r(varlist)'{
	*Genrate data quality
	gen q_`v' = 5       if `v'!=.
	*Genrate s_
	gen s_`v' = "OECD"  if `v'!=.
}


// Fix
replace q_cfc = .  if cfc == 0
replace q_gsr = .  if gsr == 0
replace q_gsm = .  if gsm == 0
replace s_cfc = "" if cfc == 0
replace s_gsr = "" if gsr == 0
replace s_gsm = "" if gsm == 0
replace   cfc = .  if cfc == 0
replace   gsr = .  if gsr == 0
replace   gsm = .  if gsm == 0

generate   prp = prp_recv - prp_paid
quality prp_recv prp_pai, gen(temp1) 
generate q_prp = temp1               if !mi(prp)
generate s_prp = "prp-recv,prp-paid" if !mi(prp)

egen    ssc = rowtotal(ssc_paid ssb_paid), missing
quality ssc_paid ssb_paid, gen(temp2)
generate q_ssc = temp2           if !missing(ssc) 
gen  s_ssc = "ssc-paid,ssb-paid" if !missing(ssc) 

egen   ssb = rowtotal(ssc_recv ssb_recv), missing
quality ssc_recv ssb_recv, gen(temp3)
generate q_ssb = temp3          if !missing(ssb) 
gen s_ssb = "ssc-recv,ssb-recv" if !missing(ssb) 
drop *_paid *_recv temp*

replace q_ssb = .  if location == "AUS"
replace s_ssb = "" if location == "AUS"
replace   ssb = .  if location == "AUS"

generate seg = prg - tiw - ssc + ssb
generate pri = prg - cfc
generate sec = seg - cfc
generate nsm = gsm - cfc
generate sav = sec - con
generate sag = seg - con
generate cap = nsm + prp
generate cag = gsm + prp
generate tax = tiw + ssc

quality prg tiw ssc ssb, gen(q_seg)
quality prg cfc,         gen(q_pri)
quality seg cfc,         gen(q_sec)
quality gsm cfc,         gen(q_nsm)
quality sec con,         gen(q_sav)
quality seg con,         gen(q_sag)
quality nsm prp,         gen(q_cap)
quality gsm prp,         gen(q_cag)
quality tiw ssc,         gen(q_tax)

generate s_seg = "prg,tiw,ssc,ssb" 
generate s_pri = "prg,cfc"
generate s_sec = "seg,cfc"
generate s_nsm = "gsm,cfc"
generate s_sav = "sec,con"
generate s_sag = "seg,con"
generate s_cap = "nsm,prp"
generate s_cag = "gsm,prp"
generate s_tax = "tiw,ssc"

foreach v in ssb ssc prp seg pri sec nsm sav sag cap cag tax {
	replace s_`v'= "" if mi(`v')
	replace q_`v'= .  if mi(`v')
}

ds location year series sector_wid, not
local varlist = r(varlist) 
reshape wide `varlist', i(location year series) j(sector_wid) string

// Combine sectors ourselves if necessary
foreach v of varlist *hn {
	if inlist(substr("`v'",1,2), "s_", "q_") continue
	
	local stub = substr("`v'", 1, 3)
	replace   `v' = `stub'ho + `stub'np if missing(`v')
	quality `stub'ho `stub'np , gen(q_`v'2)
	replace q_`v' = q_`v'2              if !missing(`v') & missing(q_`v')
	replace s_`v' = "`stub'ho,`stub'np" if !missing(`v') & missing(q_`v')
	drop q_`v'2
}

// No mixed income in the NPISH sector
replace   gsrnp = gsmnp
replace q_gsrnp = min(3, q_gsmnp) if !mi(gsrnp)
replace s_gsrnp = "gsmnp"         if !mi(gsrnp)

drop *gmxnp *gsmnp

generate   nsrnp = gsrnp - cfcnp
quality gsrnp cfcnp, gen(temp0)
gen q_nsrnp= temp0               if !missing(nsrnp)
generate s_nsrnp = "gsrnp,cfcnp" if !missing(nsrnp)


// Assume CFC falls on gross operating surplus and gross mixed income
// of household sector proportionally to gross operating surplus + 30% of
// gross mixed income
generate ccsho = cfcho*gsrho/(gsrho + 0.3*gmxho)
quality cfcho gsrho gmxho, gen(temp1) 
generate q_ccsho = temp1                   if !missing(ccsho)
generate s_ccsho = "cfcho,gsrho,0.3*gmxho" if !missing(ccsho) 

generate   ccmho = cfcho*0.3*gmxho/(gsrho + 0.3*gmxho) 
quality cfcho gmxho gmxho, gen(temp2)
generate q_ccmho = temp2 if !missing(ccmho)
generate s_ccmho = "cfcho,0.3*gmxho,gsrho" if !missing(ccmho)
drop temp*


generate   ccshn = ccsho + cfcnp
quality ccsho cfcnp, gen(temp)
generate q_ccshn = temp          if !missing(ccshn)
generate s_ccshn = "ccsho,cfcnp" if !missing(ccshn)

generate q_ccmhn = min(3,q_ccmho) if !missing(ccmho)
generate s_ccmhn = "ccmho"        if !missing(ccmho)
generate   ccmhn = ccmho

replace   ccshn = cfchn*gsrhn/(gsrhn + 0.3*gmxhn) if missing(ccshn) 
quality cfchn gsrhn gmxhn, gen(temp2)     
replace q_ccshn= temp2                            if missing(q_ccshn) & !missing(ccshn) 
replace s_ccshn = "cfchn,gsrhn,0.3*gmxhn"         if !missing(ccshn)  & missing(s_ccshn)

replace   ccmhn = cfchn*0.3*gmxhn/(gsrhn + 0.3*gmxhn) if missing(ccmhn)
quality cfchn gmxhn gsrhn, gen(temp3)  
replace q_ccmhn = temp3                               if !missing(ccmhn) & missing(q_ccmhn)
replace s_ccmhn = "cfchn,0.3*gmxhn,gsrhn"             if !missing(ccmhn) & missing(s_ccmhn)

generate   nsrho = gsrho - ccsho
quality gsrho ccsho, gen(temp4) 
generate q_nsrho = temp4          if !missing(nsrho)
generate s_nsrho = "gsrho,ccsho"  if !missing(ccsho)

generate   nmxho = gmxho - ccmho
quality gmxho ccmho, gen(temp5)
generate q_nmxho = temp5          if !missing(nmxho)
generate s_nmxho = "gmxho,ccmho"  if !missing(nmxho)


generate   nmxhn = nmxho
generate q_nmxhn = min(3,q_nmxho)  if !missing(nmxhn)
generate s_nmxhn = "nmxho"         if !missing(nmxhn)


generate   nsrhn = nsrho + nsrnp
quality nsrho nsrnp, gen(temp6)   
generate q_nsrhn = temp6         if !missing(nsrhn)       
generate s_nsrhn = "nsrho,nsrnp" if !missing(nsrhn) 

replace    nmxhn = gmxhn - ccmhn if missing(nmxhn)
quality gmxhn ccmhn, gen(temp7)  
replace  q_nmxhn = temp7         if !missing(nmxhn) & missing(q_nmxhn)
replace  s_nmxhn = "gmxhn,ccmhn" if !missing(nmxhn) & missing(s_nmxhn)
drop temp*

*save "$work_data/oecd-households-npish.dta", replace
tempfile oecd_households_npish
save    `oecd_households_npish'

// -------------------------------------------------------------------------- //
// General government
// -------------------------------------------------------------------------- //

use "`raw_data_oecd'", clear

keep if sector == "S13"

tab transact

replace widcode = "prggo" if transact == "NFB5GR"
replace widcode = "cfcgo" if transact == "NFK1MP"

replace widcode = "tpigo" if transact == "NFD2R"
replace widcode = "tprgo" if transact == "NFD21R"
replace widcode = "otpgo" if transact == "NFD29R"

replace widcode = "spigo" if transact == "NFD3P"
replace widcode = "sprgo" if transact == "NFD31P"
replace widcode = "ospgo" if transact == "NFD39P"

replace widcode = "prpgo_recv" if transact == "NFD4R"
replace widcode = "prpgo_paid" if transact == "NFD4P"

replace widcode = "gsrgo" if transact == "NFB2G_B3GR"

replace widcode = "tiwgo" if transact == "NFD5R"
replace widcode = "sscgo" if transact == "NFD61R"
replace widcode = "ssbgo" if transact == "NFD62P"

replace widcode = "congo" if transact == "NFP3P"
replace widcode = "indgo" if transact == "NFP31P"
replace widcode = "colgo" if transact == "NFP32P"

replace widcode = "ceugo" if transact == "NFD1P"

drop if missing(widcode)
keep location year series widcode value
collapse (mean) value, by(location year series widcode)
greshape wide value, i(location year series) j(widcode)

renvars value*, predrop(5)

generate prpgo = cond(missing(prpgo_recv), 0, prpgo_recv) - prpgo_paid
drop *_recv *_paid

// Generate metadata
ds  location year series , not
foreach v in `r(varlist)'{
	*Genrate data quality
	gen q_`v' = 5 if `v'!=.
	*Genrate s_
	gen s_`v' = "OECD"  if `v'!=.
}


// Fix
replace q_tpigo = min(3,cond(tpigo > spigo, q_tpigo, q_spigo)) if location == "CHN"
replace s_tpigo = "tpigo,spigo" if location == "CHN"
replace   tpigo = tpigo + spigo if location == "CHN"

generate ptxgo = tpigo - spigo
generate taxgo = tiwgo + sscgo
generate seggo = prggo + taxgo - ssbgo
generate saggo = seggo - congo

quality tpigo spigo,       gen(q_ptxgo)
quality tiwgo sscgo,       gen(q_taxgo)
quality prggo taxgo ssbgo, gen(q_seggo)
quality seggo congo,       gen(q_saggo)

generate s_ptxgo = "tpigo,spigo"
generate s_taxgo = "tiwgo,sscgo"
generate s_seggo = "prggo,taxgo,ssbgo"
generate s_saggo = "seggo,congo"

foreach v in tpigo ptxgo taxgo seggo saggo {
	replace s_`v'= "" if mi(`v')
	replace q_`v'= .  if mi(`v')
}

generate nsrgo = gsrgo - cfcgo
generate prigo = prggo - cfcgo
generate secgo = seggo - cfcgo
generate savgo = saggo - cfcgo

quality gsrgo cfcgo, gen(q_nsrgo)
quality prggo cfcgo, gen(q_prigo)
quality seggo cfcgo, gen(q_secgo)
quality saggo cfcgo, gen(q_savgo)

generate s_nsrgo = "gsrgo,cfcgo"
generate s_prigo = "prggo,cfcgo"
generate s_secgo = "seggo,cfcgo"
generate s_savgo = "saggo,cfcgo"


replace q_nsrgo = 0 if missing(gsrgo)
replace s_nsrgo = "assumed" if missing(gsrgo)
replace   nsrgo = 0 if missing(gsrgo)



foreach v in  nsrgo prigo secgo savgo{
	replace s_`v'= "" if mi(`v')
	replace q_`v'= .  if mi(`v')
}


*save "$work_data/oecd-general-government.dta", replace
tempfile oecd_general_government
save `oecd_general_government'

// -------------------------------------------------------------------------- //
// Government final expenditure by function
// -------------------------------------------------------------------------- //

import delimited "$input_data_dir/oecd-data/national-accounts/SNA_TABLE11_ARCHIVE_19042021181111687.csv", clear encoding(utf8)
generate series = 10000
tempfile oecd
save "`oecd'"

import delimited "$input_data_dir/oecd-data/national-accounts/SNA_TABLE11_19042021181239922.csv", clear encoding(utf8)
generate series = 20000
append using "`oecd'"

merge n:1 location year series using "`current_gdp_oecd'", keep(match) nogenerate
replace value = value/gdp
drop gdp

drop if function == "Total function"

generate widcode = ""
replace widcode = "gpsgo" if function == "General public services"
replace widcode = "defgo" if function == "Defence"
replace widcode = "polgo" if function == "Public order and safety"
replace widcode = "ecogo" if function == "Economic affairs"
replace widcode = "envgo" if function == "Environment protection"
replace widcode = "hougo" if function == "Housing and community amenities"
replace widcode = "heago" if function == "Health"
replace widcode = "recgo" if function == "Recreation, culture and religion"
replace widcode = "edugo" if function == "Education"
replace widcode = "sopgo" if function == "Social protection"

assert widcode != ""

keep location year series widcode value
collapse (mean) value, by(location year series widcode)
greshape wide value, i(location year series) j(widcode)

renvars value*, predrop(5)

generate othgo = .

// Generate metadata
ds  location year series , not
foreach v in `r(varlist)'{
	*Genrate data quality
	gen q_`v' = 5 if `v'!=.
	*Genrate s_
	gen s_`v' = "OECD"  if `v'!=.
}

*save "$work_data/oecd-government-function.dta", replace
tempfile oecd_government_function
save 	`oecd_government_function'
// -------------------------------------------------------------------------- //
// Combine and clear the data
// -------------------------------------------------------------------------- //

use "`oecd_foreign_income'", clear
merge 1:1 location year series using "`oecd_corporations'",        nogenerate
merge 1:1 location year series using "`oecd_households_npish'",    nogenerate
merge 1:1 location year series using "`oecd_general_government'",  nogenerate
merge 1:1 location year series using "`oecd_government_function'", nogenerate

// Identify countries
kountry location, from(iso3c) to(iso2c)
rename _ISO2C_ iso
drop location
drop if iso == ""

// -------------------------------------------------------------------------- //
// Calibrate the data
// -------------------------------------------------------------------------- //

generate gdpro = 1
gen q_gdpro=5
gen s_gdpro="OECD"

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
		(fsubx = fpsub + fosub) ///
		(ftaxx = fptax + fotax) ///
		(taxnx = prtxn + optxn), fixed(nnfin) prefix(new) replace

foreach v of varlist new* {
    local base = subinstr("`v'", "new", "", .)

    replace q_`base' = 3 if missing(`base') & !missing(`v')
	replace s_`base' = "enforce" if missing(`base') & !missing(`v')
    replace `base' = `v'
}
drop new* 
	
// Gross national income of the different sectors of the economy
// (+ specific income components)
enforce (gdpro + nnfin = prghn + prgco + prggo) ///
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
		(ssbhn = ssbho + ssbnp), fixed(gdpro nnfin pinnx) prefix(new) replace
		
foreach v of varlist new* {
    local base = subinstr("`v'", "new", "", .)

    replace q_`base' = 3 if missing(`base') & !missing(`v')
	replace s_`base' = "enforce" if missing(`base') & !missing(`v')
    replace `base' = `v'
}
drop new* 

// Consumption of fixed capital
enforce (confc = cfchn + cfcco + cfcgo), fixed(confc) prefix(new) replace

foreach v of varlist new* {
    local base = subinstr("`v'", "new", "", .)

    replace q_`base' = 3 if missing(`base') & !missing(`v')
	replace s_`base' = "enforce" if missing(`base') & !missing(`v')
    replace `base' = `v'
}
drop new* 

// Household + NPISH sector
enforce (prghn = comhn + caghn) ///
		(caghn = gsmhn + prphn) ///
		(caphn = nsmhn + prphn) ///
		(nsmhn = gsmhn - cfchn) ///
		(nsrhn = gsrhn - ccshn) ///
		(nmxhn = gmxhn - ccmhn) ///
		(cfchn = ccshn + ccmhn) ///
		(prihn = prghn - cfchn) ///
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
		(saghn = sagho + sagnp), fixed(prghn cfchn) prefix(new) replace

foreach v of varlist new* {
    local base = subinstr("`v'", "new", "", .)

    replace q_`base' = 3 if missing(`base') & !missing(`v')
	replace s_`base' = "enforce" if missing(`base') & !missing(`v')
    replace `base' = `v'
}
drop new* 

// Corporate sector
enforce /// Combined sectors, primary income
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
		(segco = segfc + segnf), fixed(prgco cfcco)  prefix(new)replace

foreach v of varlist new* {
    local base = subinstr("`v'", "new", "", .)

    replace q_`base' = 3 if missing(`base') & !missing(`v')
	replace s_`base' = "enforce" if missing(`base') & !missing(`v')
    replace `base' = `v'
}
drop new* 

// Governement expenditure by function is a satellite account: calibrate it
// separately
enforce (congo = gpsgo + defgo + polgo + ecogo + envgo + hougo + heago + recgo + edugo + sopgo + othgo), fixed(congo) prefix(new) replace

foreach v of varlist new* {
    local base = subinstr("`v'", "new", "", .)

    replace q_`base' = 3 if missing(`base') & !missing(`v')
	replace s_`base' = "enforce" if missing(`base') & !missing(`v')
    replace `base' = `v'
}
drop new* 

// Government
enforce ///
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
	(congo = gpsgo + defgo + polgo + ecogo + envgo + hougo + heago + recgo + edugo + sopgo + othgo), fixed(prggo) prefix(new) replace
	
foreach v of varlist new* {
    local base = subinstr("`v'", "new", "", .)

    replace q_`base' = 3 if missing(`base') & !missing(`v')
	replace s_`base' = "enforce" if missing(`base') & !missing(`v')
    replace `base' = `v'
}
drop new* 
	
// -------------------------------------------------------------------------- //
// Perform additional decompositions
// -------------------------------------------------------------------------- //

// Net labor/capital income decomposition
generate fkpin = prphn + prico + nsrhn + prpgo
// National savings
generate savin = savhn + savgo + secco
generate savig = savin + confc

// Complete metadata
quality  prphn prico nsrhn prpgo, gen(temp1)
generate q_fkpin = temp1 if !missing(fkpin)
quality savhn savgo secco, gen(temp2)
generate q_savin = temp2 if !missing(savin)
quality savin confc, gen(temp3)
generate q_savig = temp3 if !missing(savig)
drop temp*

gen s_fkpin= "prphn,prico,nsrhn,prpgo" if !missing(fkpin)
gen s_savin= "savhn,savgo,secco"       if !missing(savin)
gen s_savig= "savin,confc"             if !missing(savig)

order iso year series 
label data "generate by import-oecd-data.do"
save "$work_data/oecd-full.dta", replace
