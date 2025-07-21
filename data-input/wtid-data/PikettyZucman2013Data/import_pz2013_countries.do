//------------------------------------------------------------------------------
//      Import Piketty Zucman (2013) countries
//------------------------------------------------------------------------------

* Objective: Import long-run macro-economic variables from Piketty & Zucman (2013)
*            and prepare datasets to be called in import-pikettyzucman2013.do
         

//-------------------------- France ---------------------------------------

import excel "$wtid_data/PikettyZucman2013Data/France.xls", sheet("DataFR1") firstrow clear

gen iso = "FR"
rename DataFR1Rawnationalaccountss year
rename B nninc 
rename E gdpro
rename F confc3
rename G ptxgo3 // production taxes
// HH: Housing
rename W gsrhn3 // Housing GVA
rename X ccshn3 // CFC Housing
// HH Self employed
rename AB gvmhn3 
rename AE ceuhn3
rename AF ccmhn3
rename AD gmxhn3

// Governement
rename AW gvago3
rename AX ceugo3
rename AY cfcgo3
// Corporation
rename AI gvaco3 
rename AJ gsrco3
rename AK ceuco3
rename AL cfcco3

drop in 1/9
drop if year == ""
order iso year
ds *3*
local keep_vars `r(varlist)'
keep `keep_vars' iso year nninc gdpro confc3

save "$wtid_data/PikettyZucman2013Data/FR.dta", replace

//-------------------------- UK ---------------------------------------

import excel "$wtid_data/PikettyZucman2013Data/UK.xls", sheet("DataUK1") firstrow clear

gen iso = "GB"
rename DataUK1Raw18552010national year
rename B nninc 
rename E gdpro
rename F confc3
rename K ptxgo3 // production taxes (D21 +D29 + D31 + D39)
// HH: Housing
rename T gsrhn3 // Housing GVA
rename X ccshn3 // CFC Housing
// HH Self employed
rename AL gvmhn3 
rename BM ceuhn3
rename BT ccmhn3
rename AO gmxhn3

// Governement
rename DI gvago3
rename DJ ceugo3
rename DK cfcgo3
// Corporation
rename CM gvaco3 
rename CN gsrco3
rename CP ceuco3
rename CQ cfcco3

drop in 1/11
drop if year == ""
order iso year
ds *3*
local keep_vars `r(varlist)'
keep `keep_vars' iso year nninc gdpro confc3

save "$wtid_data/PikettyZucman2013Data/UK.dta", replace

//-------------------------- USA ---------------------------------------
import excel "$wtid_data/PikettyZucman2013Data/USA.xlsx", sheet("DataUS1") firstrow clear

gen iso = "US"
rename TableDataUS1Rawnationalacco year
rename B nninc 
rename H gdpro
rename D confc3
rename O ptxgo3 // production taxes
// HH: Housing
rename AH gsrhn3 // Housing GVA
rename AI ccshn3 // CFC Housing
// HH Self employed
rename AL gvmhn3 
rename AN ceuhn3
rename AO ccmhn3
rename AM gmxhn3

// Corporation
rename AR gvaco3 
rename AS gsrco3
rename AT ceuco3
rename AU cfcco3

// Governement
rename BH gvago3
rename BI ceugo3
rename BJ cfcgo3


drop in 1/11
drop if year == ""
order iso year
ds *3*
local keep_vars `r(varlist)'
keep `keep_vars' iso year nninc gdpro confc3

save "$wtid_data/PikettyZucman2013Data/US.dta", replace

//-------------------------- Italy ---------------------------------------
import excel "$wtid_data/PikettyZucman2013Data/Italy.xls", sheet("DataItaly") firstrow clear

gen iso = "IT"
rename DataItalyRawnationalaccounts year
rename B nninc 
rename E gdpro
rename F confc3
rename G ptxgo3 // production taxes
// HH: Housing
rename AK gsrhn3 // Housing GVA
rename AL ccshn3 // CFC Housing
// HH Self employed
rename AO gvmhn3 
rename AR ceuhn3
rename AS ccmhn3
rename AQ gmxhn3

// Corporation
rename BA gvaco3 
rename BB gsrco3
rename BD ceuco3
rename BE cfcco3

// Governement
rename AV gvago3
rename AW ceugo3
rename AX cfcgo3


drop in 1/11
drop if year == ""
order iso year
ds *3*
local keep_vars `r(varlist)'
keep `keep_vars' iso year nninc gdpro confc3

save "$wtid_data/PikettyZucman2013Data/IT.dta", replace

//-------------------------- Germany ---------------------------------------
import excel "$wtid_data/PikettyZucman2013Data/Germany.xls", sheet("DataDE1") firstrow clear

gen iso = "DE"
rename DataDE1Rawnationalincomeacc year
rename B nninc 
rename G gdpro
rename H confc3
rename I ptxgo3 // production taxes
// HH: Housing
rename AK gsrhn3 // Housing GVA
rename AL ccshn3 // CFC Housing
// HH Self employed
rename AP gvmhn3 
rename AS ceuhn3
rename AT ccmhn3
rename AR gmxhn3

// Corporation
rename AW gvaco3 
rename AY gsrco3
rename AZ ceuco3
rename BA cfcco3

// Governement
rename BN gvago3
rename BO ceugo3
rename BP cfcgo3

// Private sector (Sum of corporations and households, including housing)
rename X gvapr3
rename Y ceupr3
rename AA cfcpr3 


drop in 1/8
drop if year == ""
order iso year
ds *3*
local keep_vars `r(varlist)'
keep `keep_vars' iso year nninc gdpro confc3

save "$wtid_data/PikettyZucman2013Data/DE.dta", replace

//-------------------------- Australia ---------------------------------------
import excel "$wtid_data/PikettyZucman2013Data/Australia.xls", sheet("DataAU") firstrow clear

gen iso = "AU"
rename DataAURawnationalaccountsse year
rename B nninc 
rename E gdpro
rename F confc3
rename G ptxgo3 // production taxes
// HH: Housing
rename W gsrhn3 // Housing GVA
rename X ccshn3 // CFC Housing
// HH Self employed
rename AD gvmhn3 
rename AG ceuhn3
rename AH ccmhn3
rename AF gmxhn3

// Corporation
rename AK gvaco3 
rename AL gsrco3
rename AM ceuco3
rename AN cfcco3

// Governement
rename AQ gvago3
rename AR ceugo3
rename AS cfcgo3

drop in 1/9
drop if year == ""
order iso year
ds *3*
local keep_vars `r(varlist)'
keep `keep_vars' iso year nninc gdpro confc3

save "$wtid_data/PikettyZucman2013Data/AU.dta", replace

//-------------------------- Canada ---------------------------------------
import excel "$wtid_data/PikettyZucman2013Data/Canada.xls", sheet("DataCanada") firstrow clear

gen iso = "CA"
rename DataCanadaRawofficialnationa year
rename B nninc 
rename E gdpro
rename F confc3
rename G ptxgo3 // production taxes
// HH: Housing
rename AG gsrhn3 // Housing GVA
rename AI ccshn3 // CFC Housing
// HH Self employed
rename BB gvmhn3 
rename BE ceuhn3
rename BF ccmhn3
rename BD gmxhn3

// Corporation
rename BI gvaco3 
rename BJ gsrco3
rename BK ceuco3
rename BL cfcco3

// Governement
rename AM gvago3
rename AN ceugo3
rename AP cfcgo3

drop in 1/9
drop if year == ""
order iso year
ds *3*
local keep_vars `r(varlist)'
keep `keep_vars' iso year nninc gdpro confc3

save "$wtid_data/PikettyZucman2013Data/CA.dta", replace

//-------------------------- Japan ---------------------------------------
import excel "$wtid_data/PikettyZucman2013Data/Japan.xls", sheet("DataJapan") firstrow clear
drop in 1/10

gen iso = "JP"
rename DataJPRawofficialnationalac year
rename B nninc 
rename E gdpro
rename F confc3
rename G ptxgo3 // production taxes
// HH: Housing
rename T gsrhn3 // Housing GVA
rename U ccshn3 // CFC Housing
// HH Self employed
rename AL gvmhn3 // not seperate for HH and corporations
rename AO ceuhn3
rename AP ccmhn3 
rename AN gmxhn3

// Corporation
rename AV gvaco3 
rename AX ceuco3
rename AY cfcco3
rename AW nsrco3

// Buisines Sector (self-employed and corporations, exl corporations)
rename AE gvhco3 
rename AH cehco3
rename AI cfhco3

// Governement
rename Z gvago3
rename AA ceugo3
rename AB cfcgo3

drop if year == ""
order iso year
ds *3*
local keep_vars `r(varlist)'
keep `keep_vars' iso year nninc gdpro confc3

save "$wtid_data/PikettyZucman2013Data/JP.dta", replace
