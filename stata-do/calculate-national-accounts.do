// -------------------------------------------------------------------------- //
// Generate final national accounts series (totals + decomposition)
// -------------------------------------------------------------------------- //

//-------------- 1. Aux tables -------------------------------------------------

//--------------------- 1.1 GDP ------------------------------------------------
use "$work_data/retropolate-gdp.dta", clear


keep iso year gdp currency data_quality s_
rename (gdp data_quality) (value q_)
generate widcode = "gdpro"

tempfile gdp
save "`gdp'"

//--------------------- 1.2 Public Finance ------------------------------------------------
use "$wid_dir/Country-Updates/publicfinance/wid-gethinpublicfinance-2024-11-15.dta", clear
//-----------------Temporal ------------
drop data_quality source
gen  q_=4 if !missing(value)
gen s_=author
//--------------------------------------
drop extrapolation data_points /*q_ s_*/ method author p

// Note: widcodes= "m" + widcode + "999i"; so we can remove the sufix and prefix and later, 
//       re-insert them
* Remove prefix "m" and sufix "999i"
replace widcode = substr(widcode, 2, .) if substr(widcode, 1, 1) == "m"
replace widcode = subinstr(widcode, "999i", "", .)

* Reshape to wide
reshape wide value q_ s_, i(iso year) j(widcode) string
rename value* *

tempfile public_finance
save "`public_finance'"

//-------------- 2. Main table -------------------------------------------------
use "$work_data/sna-series-adjusted.dta", clear

drop *gdpro series_* gdp_idx *_gdp

drop TH

//	current account
merge 1:1 iso year using "$work_data/bop_currentacc.dta", nogenerate

quality                tbnnx scinx pinnx comnx taxnx,  gen(temp)
gen         s_ncanx = "tbnnx,scinx,pinnx,comnx,taxnx"
egen double   ncanx = rowtotal(tbnnx scinx pinnx comnx taxnx)
gen         q_ncanx = temp if !mi(ncanx)
drop temp 

quality           tbnnx scinx nnfin, gen(temp)
replace q_ncanx = temp                   if year <1970  
replace s_ncanx = "tbnnx,scinx,nnfin"    if year <1970
replace   ncanx = tbnnx + scinx + nnfin  if year <1970
drop temp

// Decompositon of merchandise trade
merge 1:1 iso year using "$work_data/commodities-decomposition.dta", nogenerate
// GDP final data
merge 1:1 iso year using "$work_data/retropolate-gdp.dta", nogenerate keep(match) keepusing(gdp data_qualitygdp currency)
rename data_qualitygdp q_gdp
// Merging Public Finance data
merge 1:1 iso year using "`public_finance'", nogenerate


// GDP Ratios and Convertion to monetary values
ds iso year gdp currency q_* s_* coef_*, not
local varlist = r(varlist)
foreach v of varlist `varlist' {
	by iso : carryforward `v', replace
	replace q_`v' = 2              if !missing(`v') & missing(q_`v') // &  year == $pastyear
    replace s_`v' = "carryforward" if !missing(`v') & missing(s_`v') // &  year == $pastyear
	
	gen         q_y`v' = q_`v'  if !missing(`v')
	gen         s_y`v' = s_`v'  if !mi(`v')
	gen double    y`v' =   `v' // Keep values as onlet "Y" for Percentage of GDP
	
	*This will be the aggregates m
	replace  q_`v' = q_gdp   if !missing(`v')
	*replace s_`v' = s_`v' // s_ stay as it is
	replace    `v' = `v'*gdp // Generate monetary values
}
drop *gdp 


renvars  `varlist', prefix(value)
foreach v of local varlist {
	rename y`v' valuey`v' 
}
drop coef_* //valuey_merge*

greshape long value q_ s_, i(iso year currency) j(widcode) string
drop if missing(value)

append using "`gdp'"

sort iso widcode year

replace widcode = "m" + widcode + "999i" if substr(widcode,1,1)!="y"
replace widcode =       widcode + "999i" if substr(widcode,1,1)=="y"

// Kosovo: use KV rather than KS


tempfile m_y
save `m_y'

// national income ratios
drop currency 
greshape wide value q_ s_, i(iso year) j(widcode) string


foreach v of local varlist {
	gen            q_w`v'999i = q_mnninc999i
	gen            s_w`v'999i = s_m`v'999i
	gen double  valuew`v'999i = valuem`v'999i/valuemnninc999i
}

foreach v in gdpro {
	gen            q_w`v'999i = q_mnninc999i
	gen            s_w`v'999i = s_m`v'999i
	gen double  valuew`v'999i = valuem`v'999i/valuemnninc999i
}

// dropping original foreign portfolio 
drop valuemptfon999i valuemptfop999i valuemptfor999i 
drop s_mptfon999i s_mptfop999i s_mptfor999i 
drop q_mptfon999i q_mptfop999i q_mptfor999i

// extrapolating based on nninc 

sort iso year
foreach v in expgo999i gpsge999i defge999i polge999i ecoge999i envge999i houge999i heage999i recge999i eduge999i edpge999i edsge999i edtge999i sopge999i spige999i sacge999i sakge999i revgo999i pitgr999i citgr999i scogr999i pwtgr999i intgr999i ottgr999i {

    by iso : carryforward valuew`v', replace // &  year == $pastyear

    replace q_w`v' = 2              if !mi(valuew`v') & mi(q_w`v') // &  year == $pastyear
    replace s_w`v' = "carryforward" if !mi(valuew`v') & mi(s_w`v') // &  year == $pastyear

    replace    q_m`v' = q_mnninc999i              if mi(valuem`v') // & year == $pastyear 
    replace    s_m`v' = s_w`v'                    if mi(valuem`v') // & year == $pastyear 
    replace valuem`v' = valuew`v'*valuemnninc999i if mi(valuem`v') // & year == $pastyear 
	
	replace    q_y`v' = q_mgdpro999i              if mi(valuey`v') // & year == $pastyear 
    replace    s_y`v' = s_w`v'                    if mi(valuey`v') // & year == $pastyear 
    replace valuey`v' = valuem`v'/valuemgdpro999i if mi(valuey`v') // & year == $pastyear 
}

// Note: the dataset now is too big for being reshaped at once
preserve
	keep iso year valuew* s_w* q_w*
	greshape long value q_ s_, i(iso year ) j(widcode) string
	drop if missing(value)
	
	tempfile w
	save `w'
restore


preserve
	keep iso year valuem* s_m* q_m*
	greshape long value q_ s_, i(iso year ) j(widcode) string
	drop if missing(value)
	
	tempfile m_plus
	save `m_plus'
restore


// Call everything
use "`m_y'", clear
gen tempt="m_y"
append using "`m_plus'"
replace tempt="m_plus" if mi(tempt)
append using "`w'"
replace tempt="w" if mi(tempt)

duplicates tag iso year widcode, gen(dup)
drop if dup==1 & tempt=="m_plus"

duplicates tag iso year widcode, gen(dup2)
assert dup2 ==0
drop dup* tempt

sort iso year widcode
gen p = "pall"

merge m:1 iso year using "$work_data/retropolate-gdp.dta", nogen keepusing(currency)
replace currency="" if substr(widcode,1,1)!="m"

*preserve 
	rename q_ data_quality
	*drop s_

	// Export
	label data "Generated by calculate-national-accounts.do"
	save "$work_data/national-accounts.dta", replace
*restore 
// -------------------------------------------------------------------------- //
// Generate metadata for components
// -------------------------------------------------------------------------- //
/*
keep iso year widcode s_ 
rename s_ metadata

gen sixlet=substr(widcode,1,6)
drop widcode


*Identify frontier years
gen      aux=0 
replace  aux=1 if year>=1970
sort iso sixlet year metadata



sort iso sixlet aux year
bysort iso sixlet aux (year): ///
gen spell = sum(metadata != metadata[_n-1])
bysort iso sixlet aux spell: egen firstyear = min(year)
bysort iso sixlet aux spell: egen lastyear = max(year)

drop aux
collapse (first) metadata , by(iso sixlet firstyear lastyear)

bysort iso sixlet (firstyear lastyear): gen categ = sum(firstyear != firstyear[_n-1] | lastyear  != lastyear[_n-1])

* Notes on the metadata generation
/*
The information source and the method are collected in the column metadata. An underscode (_)
is supposed to separate the source or the variable used from the adjusmente mehod in case the variabmes was adjusted
*/


*Split source and method
split metadata, parse(_) generate(treat)

//------- Generate s_ ------------------------------------------------------
*Papers
gen source=`"[URL][URL_LINK]https://wid.world/document/globalization-and-factor-income-taxation-world-inequality-lab-working-paper-2022-05/[/URL_LINK]"' ///
		+ `"[URL_TEXT] Bachas, P., Fishet-Post, M. Jensen, A., Zucman, G.(2002). Globalization and Factor Income Taxation[/URL_TEXT][/URL]"' if strpos(treat1, "Bachas2022")
replace source = `"[URL][URL_LINK]https://www.diva-portal.org/smash/record.jsf?pid=diva2%3A193148&dswid=1666[/URL_LINK]"' ///
		+ `"[URL_TEXT] Edvinsson, R.(2005). Growth, Accumulation, Crisis With New Macroeconomic Data for Sweden 1800-2000[/URL_TEXT][/URL]"' if strpos(treat1,"Edvinsson2005")		
		
replace source=`"[URL][URL_LINK]https://wid.world/document/updated-and-extended-series-on-factor-shares-and-domestic-capital-stock-in-peru-1942-2024-world-inequality-lab-technical-note-2026-02/[/URL_LINK]"' ///
		+ `"[URL_TEXT]Castillo-Garcia, C.(2026). Updated and Extended Series on Factor Shares and Domestic Capital Stock in Peru, 1942-2024[/URL_TEXT][/URL]"' if strpos(treat1, "castillogarcia2026")		
		
replace source=`"[URL][URL_LINK]https://wid.world/document/global-wealth-accumulation-and-ownership-patterns-1800-2025-world-inequality-lab-working-paper-2025-22/[/URL_LINK]"' ///
		+ `"[URL_TEXT]Bauluz, L., Brassac, P., Dietrich J., Martinez-Toledano, C., Nievas, G., Odersky, M., Piketty, T., Sodano, A., Somanchi, A.(2025). Global Wealth Accumulation and Ownership Patterns, 1800-2025[/URL_TEXT][/URL]"' if strpos(metadata,"Bauluz2025")
		
replace source=`"[URL][URL_LINK]https://jenmana.info/projects/ [/URL_LINK]"' ///
		+ `"[URL_TEXT]Jenmana, T., Document forthcoming[/URL_TEXT][/URL]"' if strpos(treat1,"Jenmana")

replace source=`"[URL][URL_LINK]https://www.brookings.edu/articles/the-external-wealth-of-nations-database/[/URL_LINK]"' ///
		+ `"[URL_TEXT]Milesi-Ferretti G-M. The external wealth of nations database. Brookings(04/$year)[/URL_TEXT][/URL]"' if strpos(treat1,"MilesiFerretti")

replace source=`"[URL][URL_LINK]https://wid.world/document/soviets-oligarchs-inequality-property-russia-1905-2016/[/URL_LINK]"' ///
		+ `"[URL_TEXT]Novokmet, F., Piketty, T., Zucman, G.(2018) From Soviets to Oligarchs: Inequality and Property in Russia 1905-2016[/URL_TEXT][/URL]"' if strpos(treat1, "NovokmetPikettyZucman2017")
		
replace source=`"[URL][URL_LINK]https://wid.world/document/t-piketty-l-yang-and-g-zucman-capital-accumulation-private-property-and-inequality-in-china-1978-2015-2016/[/URL_LINK]"' ///
		+ `"[URL_TEXT]Piketty, T., Yang, L., Zucman, G.(2017).Capital Accumulation, Private Property and Rising Inequality in China, 1978-2015[/URL_TEXT][/URL]"' if strpos(treat1,"PikettyYangZucman2017")

replace source=`"[URL][URL_LINK]https://wid.world/www-site/uploads/2019/09/WID_WORKING_PAPER_2017_23_Updates_Bauluz.pdf[/URL_LINK]"' ///
		+ `"[URL_TEXT]Bauluz, L.(2017). Luis Bauluz[/URL_TEXT][/URL]"' if strpos(treat1,"Bauluz2019")		
		
replace source=`"[URL][URL_LINK]http://piketty.pse.ens.fr/fichiers/PikettyZucman2014QJE.pdf[/URL_LINK]"' ///
		+ `"[URL_TEXT]Piketty, T., Zucman, G.(2014). Revised national income and wealth series: Australia, Canada, France, Germany, Italy, Japan, UK and USA[/URL_TEXT][/URL]"' if strpos(treat1,"PikettyZucman2013")
		
replace source=`"[URL][URL_LINK]https://www.stats.gov.sa/en/statistics?index=119021&subindex=120034[/URL_LINK]"' ///
		+ `"[URL_TEXT]General Authority for Statistics. Goverment of the Kingdom of Saudi Arabia (retreived on 11/2025) [/URL_TEXT][/URL]"' if strpos(treat1,"SAGAStat")

replace source=`"[URL][URL_LINK] https://www.tandfonline.com/doi/abs/10.1080/03585522.2015.1132759[/URL_LINK]"' ///
		+ `"[URL_TEXT] Waldenström, D.(2016).The national wealth of Sweden, 1810–2014[/URL_TEXT][/URL]"' if strpos(treat1,"Waldenstrom")
		
replace source=`"[URL][URL_LINK]https://wid.world/document/a-new-database-of-general-government-revenue-and-expenditure-by-function-1980-2022-world-inequality-lab-technical-note-2024-01/[/URL_LINK]"' ///
		+ `"[URL_TEXT]Gethin, A. (2024), A New Database of General Government Revenue and Expenditure by Function, 1980-2022[/URL_TEXT][/URL]"' if strpos(treat1,"gethinpublicfinance")
		
replace source=`"[URL][URL_LINK]https://wid.world/document/wid-national-accounts-series-updated-and-extended-coverage-1800-2023-world-inequality-lab-technical-note-2025-02/[/URL_LINK]"' ///
		+ `"[URL_TEXT]Nievas, G., Piketty, T. (2025). WID National Accounts Series: Updated and Extended Coverage 1800-2023[/URL_TEXT][/URL]"' if strpos(treat1,"np2025")
		
replace source=`"[URL][URL_LINK][/URL_LINK]"' ///
		+ `"[URL_TEXT]WTID[/URL_TEXT][/URL]"' if strpos(treat1,"WID")		
		
		
* Multilaterals
replace source=`"[URL][URL_LINK]https://betadata.imf.org/en/datasets/IMF.STA:BOP_BP[/URL_LINK]"' ///
		+ `"[URL_TEXT]IMF($year). Balance of Payments and International Investment Position Statistics (BOP/IIP)(retrieved 04/$year)[/URL_TEXT][/URL]"' if strpos(treat1,"IMFBOP")


replace source=`"[URL][URL_LINK]https://data.imf.org/en/datasets/IMF.STA:PIP[/URL_LINK]"' ///
		+ `"[URL_TEXT]IMF($year). Portfolio Investment Positions by Counterpart Economy(retrieved 04/$year) [/URL_TEXT][/URL]"' if strpos(treat1,"IMFPIP")
		

replace source=`"[URL][URL_LINK]http://data.un.org[/URL_LINK]"' ///
		+ `"[URL_TEXT]UN($year). National Accounts Statistics: Main Aggregates and Detailed Tables(retrieved 04/$year) [/URL_TEXT][/URL]"' if strpos(treat1,"unsnacurr") 

replace source=`"[URL][URL_LINK]http://data.un.org [/URL_LINK]"' ///
		+ `"[URL_TEXT]UN($year). National Accounts Statistics: Main Aggregates and Detailed Tables (1968 Mehtodology) [/URL_TEXT][/URL]"' if strpos(treat1,"unsna68")
		
replace source=`"[URL][URL_LINK]https://stats.oecd.org/Index.aspx?DataSetCode=SNA_TABLE14A[/URL_LINK]"' ///
		+ `"[URL_TEXT]OECD($year).Annual non-financial accounts by institutional sector[/URL_TEXT][/URL]"' if strpos(metadata,"OECD")
		
replace source=`"[URL][URL_LINK]https://comtradeplus.un.org[/URL_LINK]"' ///
		+ `"[URL_TEXT]UN Comtrade Database(retrieved on 04/$year)[/URL_TEXT][/URL]"' if strpos(metadata,"UNcomtrade")
		
replace source=`"[URL][URL_LINK]https://www.wto.org/english/res_e/statis_e/trade_datasets_e.htm[/URL_LINK]"' ///
		+ `"[URL_TEXT]WTO-OECD Balanced Trade in Services Dataset (BaTiS) — BPM6[/URL_TEXT][/URL]"' if strpos(metadata,"WTOtrade")

*replace source=`"[URL][URL_LINK] [/URL_LINK]"' ///
*		+ `"[URL_TEXT] [/URL_TEXT][/URL]"' if strpos(metadata,)

		

//------- Generate Method ------------------------------------------------------
gen method=""

//------ Core data ( treat 1) -----------//
* Basic imputations
replace method = "Data were calculated by solving macroeconomic identities using the enforce command"           if strpos(treat1,"enforce") & missing(source)
replace method = "Data inputed trough a lineal interpolation"   if strpos(treat1,"ipol")     & missing(source)
replace method = "Obsevation carried from last year available"  if strpos(treat1,"carryfor") & missing(source)

* Assumed values
replace method = "This value was assumed" if treat1=="assumed" & missing(source)
replace method = " This values was calculate assuming y" + substr(treat1,8,5) + " to be " + substr(treat1,13,.) if treat1!="assumed" & strpos(treat1,"assumed") & missing(source)


* Regional imputations
replace method = "This value is inputed using the variable's share to gdp observed for the region " + substr(treat1,6,.) if substr(treat1,1,5)=="regsh" & missing(source)
replace method = "This value is inputed using median of the region " + substr(treat1,16,2) + " for the variable " + substr(treat1,1,5) if substr(treat1,7,9)=="medianreg" & missing(source)

replace method = "This value is an average of the region " + substr(treat1,4,.) if substr(treat1,1,3)=="reg" & missing(method)  & !strpos(treat1,"TH") & missing(source)
replace method = "This value is an average of the Tax Haven countries"          if substr(treat1,1,3)=="reg" & missing(method) & strpos(treat1,"TH") & missing(source) 

* Inhouse calculations
replace method = "This variable was calculated using the variables " + subinstr(treat1, ",", ", ", .)  if missing(method) & strpos(treat1,",")  & missing(source) // Several variables
replace method = "This variable was approached inputing the value of the variable " + treat1           if missing(method) & !strpos(treat1,",") & !strpos(treat1,"/") & missing(source) & !strpos(treat1,"(") // One variable


*Inputation from other countries
*** Only one variable
replace method = "This variable was calculated by using the value of the variable " + treat1                       if missing(method) & !strpos(treat1,",") & missing(source) & !strpos(treat1,"/") & !strpos(treat1,")") 
replace method = "This variable was calculated by using the value of the variable " + regexr(treat1, "\(.*\)", "") + " of the country " + regexs(1) if missing(method) & !strpos(treat1,",") & missing(source) & !strpos(treat1,"/") & strpos(treat1,")") & regexm(treat1, "\((.*)\)") 
replace method = subinstr(method, "medianreg", "median of the region ", .) 
*** Corrected by AN
replace source = source + ", for AN" if strpos(treat1,"(AN)") & !missing(source)

*** Only variable inputed
replace method = "This variable was calculated as " + subinstr(treat1, "(medianreg", " (median of the region ", .) if missing(method) & !strpos(treat1,",") & missing(source) &  !strpos(treat1,"/") & !strpos(treat1,")") 
*** Formula
replace method = "This variable was calculated as "                                 + treat1                       if missing(method) & !strpos(treat1,",") & missing(source) &  strpos(treat1,"/") & !strpos(treat1,"ratio")

//------ First round of adjustments (treat2) -----------//
*Ratios
gen     adjustment=""
replace adjustment = ", adjusted by the ratio " + substr(treat2,13,.) + " carried forward"             if strpos(treat2,"carriedratio")
replace adjustment = ", adjusted by the share of " + substr(treat2,6,2) + "'s mgdpro to the one of AN" if strpos(treat2,"ratio") & strpos(treat2,"/AN")
replace adjustment = ", adjusted by the ratio " + substr(treat2,9,.) + " lagged one year"              if strpos(treat2,"ratiolag")
replace adjustment = ", adjusted by the mean of the ratio " + regexs(1) + " for the region " + substr(treat2, strpos(treat2, "reg") + 3, .)    if strpos(treat2,"ratiomean") & strpos(treat2,"[") & regexm(treat2, "\[(.*)\]") & strpos(treat2,"reg")
replace adjustment = ", adjusted by the median of the ratio " + regexs(1) + " for the region " + substr(treat2, strpos(treat2, "reg") + 3, .)  if strpos(treat2,"ratiomedian") & strpos(treat2,"[") & regexm(treat2, "\[(.*)\]") & strpos(treat2,"reg")
replace adjustment = ", adjusted by the median of the ratio " + regexs(1) + " for the country " + substr(treat2, strpos(treat2, "iso") + 3, .) if strpos(treat2,"ratiomedian") & strpos(treat2,"[") & regexm(treat2, "\[(.*)\]") & strpos(treat2,"iso")

*replace adjustment = ", adjusted by the ratio " + substr(treat2,6,.) if strpos(treat2,"ratio") & missing(adjustment) & strpos(treat2,"(WO)")
replace adjustment = ", adjusted by the ratio " +  regexs(1) if strpos(treat2,"ratio") & missing(adjustment) & strpos(treat2,"(WO)") & regexm(treat2, "\[(.*)\]")

replace adjustment = subinstr(adjustment, "(WO)", " for the WO", .)  if strpos(treat2,"ratio") & !missing(adjustment) & strpos(treat2,"(WO)")
replace adjustment = ", adjusted by the ratio " + substr(treat2,6,.) if strpos(treat2,"ratio") & missing(adjustment) 

*Regional growth
replace adjustment = ", projected with the variable growth observed for the region " + substr(treat2,8,.) if strpos(treat2,"reggrow")

*Rates of return
replace adjustment = ", adjusted by the mean of the rate of return " + regexs(1) + " for the region " + substr(treat2, strpos(treat2, "reg") + 3, .)  if strpos(treat2,"returnmean") & regexm(treat2, "\[(.*)\]") & strpos(treat2,"reg")
replace adjustment = ", adjusted by the rate of return " + regexs(1) + " estimated for tax haven countries" if strpos(treat2,"returnregressionTH") & regexm(treat2, "\[(.*)\]") 
replace adjustment = ", adjusted by the rate of return " + regexs(1) + " estimated for tax haven countries with FE on the region "  + substr(treat2, strpos(treat2, "FE") + 2, .)  if strpos(treat2,"returnregressionTH") & regexm(treat2, "\[(.*)\]") & strpos(treat2,"FE")
replace adjustment = ", adjusted by the rate of return " + regexs(1) + " estimated with FE on the region "  + substr(treat2, strpos(treat2, "FE") + 2, .)  if strpos(treat2,"returnregression") & regexm(treat2, "\[(.*)\]") & missing(adjustment)
replace adjustment = ", adjusted by the rate of return " + substr(treat2,7,.)  if strpos(treat2,"return") & missing(adjustment)

replace adjustment=" (data corrected to fit into the aggregates of  "+`"[URL][URL_LINK]https://wid.world/document/unequal-exchange-and-north-south-relations-evidence-from-global-trade-flows-and-the-world-balance-of-payments-1800-2025-world-inequality-lab-working-paper-2025-11/[/URL_LINK]"' ///
		+ `"[URL_TEXT]Nievas, G., Piketty, T. (2025) [/URL_TEXT][/URL]"' + ")" if strpos(treat2,"adjnp2025")


//------ Second round of adjustments (treat3) -----------//
gen adjustment2=""
replace adjustment2 = ", and a second correction by the ratio " + substr(treat3, 6,.) if strpos(treat3,"ratio")
replace adjustment2 = subinstr(treat3, "(WO)", " estimated for the world", .)   if strpos(treat3,"ratio") 


replace adjustment2 = "(data corrected to fit into the aggregates of " + `"[URL][URL_LINK]https://wid.world/document/unequal-exchange-and-north-south-relations-evidence-from-global-trade-flows-and-the-world-balance-of-payments-1800-2025-world-inequality-lab-working-paper-2025-11/[/URL_LINK][URL_TEXT]"' + `"Nievas, G., Piketty, T. (2025) [/URL_TEXT][/URL]"' + ")" if strpos(treat3,"adjnp2025")

// Generate metadata
replace method = method + adjustment + adjustment2						  
replace source="In-house calculation" if missing(source)
replace method="Observed data" if missing(method)
drop metadata treat1 treat2 treat3 adjustment adjustment2



//----------- Collapse ---------------------------------//
foreach v in source method {
	preserve
		generate `v'_new = string(firstyear) + ": " + `v' + ";" ///
			if (firstyear == lastyear) & (`v'!="")
		replace `v'_new = string(firstyear) + "-" + string(lastyear) + ///
			": " + `v' + ";" if  (firstyear != lastyear)  & (`v'!="")
		drop firstyear lastyear 

		keep iso sixlet categ `v'_new 
		drop if `v'_new == ""
		duplicates drop

		greshape wide `v'_new, i(iso sixlet) j(categ)
		egen `v' = concat(`v'_new*), punct(" ")
		keep iso sixlet `v' 
		
		tempfile metadata_`v'
		save    `metadata_`v''
	restore
}

u "`metadata_method'", clear
merge 1:1 iso sixlet using "`metadata_source'", nogen 
order iso sixlet method source


// Add one-let note
replace method= method + " (variable is calculated as a share of GDP (y), and extended to the gdpro estimate;" if substr(sixlet,1,1)=="m"
replace method= method + " (variable is calculated as a share of GDP (y), and extended to the nninc estimate;" if substr(sixlet,1,1)=="w"
// Add technical Note
gen technote=""
replace technote = "; See [URL][URL_LINK]https://wid.world/document/extending-wid-national-accounts-series-institutional-sectors-and-factor-shares-world-inequality-lab-technical-note-2025-03/[/URL_LINK][URL_TEXT] Dietrich, J., Nievas, G., Odersky, M., Piketty, T., Somanchi, A. (2025) `Extending WID National Accounts Series: Institutional Sectors and Factor Shares'[/URL_TEXT][/URL]" if /// 
																											inlist(substr(sixlet,2,.),"pxtgo","gvato","gvago","ceugo","gsrgo","nsrgo","cfcgo","gvaco") | /// 
																											inlist(substr(sixlet,2,.),"ceuco","gsrco","nsrco","cfcco","gvahn","ceuhn","gmxhn","nmxhn") | /// 
																											inlist(substr(sixlet,2,.),"ccmhn","gsrhn","nsrhn","ccshn")
replace technote = "; See [URL][URL_LINK]https://wid.world/document/wid-national-accounts-series-updated-and-extended-coverage-1800-2023-world-inequality-lab-technical-note-2025-02/[/URL_LINK][URL_TEXT] Nievas, G., Piketty, T.(2025) `WID National Accounts Series: Updated and Extended Coverage 1800-2023'[/URL_TEXT][/URL]" if /// 
																											inlist(substr(sixlet,2,.),"tgnnx","tgxrx","tgmpx","tgncx","tgxcx","tgmcx","tgnmx","tgxmx") | /// 
																											inlist(substr(sixlet,2,.),"tgmmx","tsnnx","tsxrx","tsmpx","tbnnx","tbxrx","tbmpx","nnfin") | /// 
																											inlist(substr(sixlet,2,.),"finrx","finpx","scinx","scirx","scipx","ncanx","nwnxa","nwgxa") | /// 
																											inlist(substr(sixlet,2,.),"nwgxd","nyixx")																										
																											
replace technote=  "; See [URL][URL_LINK]https://wid.world/document/extending-wid-national-accounts-series-institutional-sectors-and-factor-shares-world-inequality-lab-technical-note-2025-03/[/URL_LINK][URL_TEXT] Gomez-Carrera R., Moshirf, R, Nievas, G. , Pikkety, T. (2024) `Global Inequality Update 2024:New Insights from Extended WID Macro Series'[/URL_TEXT][/URL]" if missing(technote)

replace method= method + technote + ", See   [URL][URL_LINK]https://wid.world/document/distributional-national-accounts-dina-guidelines-2025-methods-and-concepts-used-in-the-world-inequality-database/[/URL_LINK][URL_TEXT] Chancel L., FLores, I., Moshirf, R, Nievas, G. , Pikkety, T. (2025) `Distributional National Accounts Guidelines'[/URL_TEXT][/URL]. "
drop technote


label data "Generated by calculate-national-accounts.do"
save "$work_data/na-metadata.dta", replace





































/*

use "$work_data/sna-series-adjusted.dta", clear

// Only keep data with GDP too
merge 1:n iso year using "$work_data/retropolate-gdp.dta", nogenerate keep(match) keepusing(gdp)
drop gdp  
drop gdpro
//---------------- Modif:
*drop gdpro series_* gdp_idx *_gdp
drop TH gdp_idx *_gdp
//-----------------------

ds iso year series_*, not
local varlist = r(varlist)

renvars `varlist', prefix(value_)

greshape long value_ series_, i(iso year) j(widcode) string
rename value_ value
rename series_ series

drop if missing(value)

merge n:1 iso using "$work_data/sna-wid-metadata.dta", nogenerate keep(master match) keepusing(s_)

generate method = "extrapolated from last available year; " if (series == -2)
replace method = "estimated value (see DINA guidelines); " if (series == -3)
replace method = "estimated value (see DINA guidelines, foreign inflows of retained earnings were divided by 10 as in several other tax havens to account for the heterogeneity between domestic and foreign-owned firms); " if (series == -3) & inlist(iso, "KY", "AN", "MU", "BM", "LU", "SX", "CW") & inlist(widcode, "ptfrr", "ptfrn")
replace method = "imputed value; " if (series == -1)
replace method = "[URL][URL_LINK]http://data.un.org/Explorer.aspx[/URL_LINK][URL_TEXT]UN SNA (1968)[/URL_TEXT][/URL]; " if inrange(series, 1, 99)
replace method = "[URL][URL_LINK]http://data.un.org/Explorer.aspx[/URL_LINK][URL_TEXT]UN SNA (1993)[/URL_TEXT][/URL]; " if inrange(series, 100, 999)
replace method = "[URL][URL_LINK]http://data.un.org/Explorer.aspx[/URL_LINK][URL_TEXT]UN SNA (2008)[/URL_TEXT][/URL]; " if inrange(series, 1000, 5000)
replace method = "[URL][URL_LINK]http://data.imf.org/BOP[/URL_LINK][URL_TEXT]IMF Balance of Payments Statistics[/URL_TEXT][/URL]; " if (series == 6000)
replace method = "[URL][URL_LINK]https://stats.oecd.org/Index.aspx?DataSetCode=SNA_TABLE14A[/URL_LINK][URL_TEXT]OECD[/URL_TEXT][/URL]; " if inrange(series, 10000, 20000)
replace method = s_ if (series == 200000)
replace method = "[URL][URL_LINK]http://wid.world/document/revised-extended-national-wealth-series-australia-canada-france-germany-italy-japan-uk-usa-wid-world-technical-note-2017-23/[/URL_LINK][URL_TEXT]Piketty, Thomas; Zucman, Gabriel (2014). Capital is back: Wealth-Income ratios in Rich Countries 1700-2010. Series updated by Luis Bauluz.[/URL_TEXT][/URL]; " if series == 300000


replace method = "[URL][URL_LINK]https://wid.world/document/extending-wid-national-accounts-series-institutional-sectors-and-factor-shares-world-inequality-lab-technical-note-2025-03/[/URL_LINK][URL_TEXT] Dietrich, J., Nievas G., Odersky, M., Piketty, T. & Somanchi A (2025). Extending WID National Accounts Series: Institutional Sectors and Factor Shares [/URL_TEXT][/URL]; " if series==0

replace method = "estimated from other components; " if missing(series)
// s_s
preserve
	drop if missing(series) | series < 0

	gsort iso -year
	keep iso widcode method
	gduplicates drop
	sort iso widcode
	by iso widcode: generate spell = _n

	greshape wide method, i(iso widcode) j(spell)

	egen s = concat(method*)
	drop method*
	replace s = "See [URL][URL_TEXT]DINA guidelines[/URL_TEXT][URL_LINK]https://wid.world/document/distributional-national-accounts-guidelines-2020-concepts-and-methods-used-in-the-world-inequality-database/[/URL_LINK][/URL] for methodological explanations. The s_s used are: " + substr(s, 1, length(s) - 1) + "."
	rename s s_
	
	tempfile s_
	save "`s_'"
restore

// Method
assert method != ""

gsort iso widcode -year

by iso widcode: generate spell = sum(method[_n - 1] != method)
order iso widcode year series spell

collapse (first) method (min) min_year = year (max) max_year = year, by(iso widcode spell)

replace method = string(min_year) + "–" + string(max_year) + ": " + method if (min_year < max_year)
replace method = string(min_year) + ": " + method if (min_year == max_year)
drop min_year max_year

greshape wide method, i(iso widcode) j(spell)

egen m = concat(method*)
drop method*
replace m = "WID.world estimations as a proportion of GDP based on the following; " + substr(m, 1, length(m) - 1) + ". These estimates are then anchored to GDP (see GDP variable for details)."
replace m = m + " "
replace m = m + ///
"The estimates of national accounts subcomponents in the WID are based on official country data and use the methodology presented in the " + ///
 `"[URL][URL_LINK]https://wid.world/document/distributional-national-accounts-guidelines-2020-concepts-and-methods-used-in-the-world-inequality-database/[/URL_LINK]"' + ///
 `"[URL_TEXT]DINA guidelines[/URL_TEXT][/URL]."' + ///
 " We stress that these subcomponents estimates are more fragile than those of main aggregates such as national income. Countries may use classifications used are not always fully consistent with other countries or over time. Series breaks with no real economic significance can appear as a result. The WID include these estimates to provide a centralized source for this official data, so that it can be exploited more directly. We encourage users of this data to be careful and to pay attention to the source of the data, which we systematically indicate."
rename m method

merge 1:1 iso widcode using "`s_'", nogenerate
replace s_ = "See " + ///
 `"[URL][URL_LINK]https://wid.world/document/distributional-national-accounts-guidelines-2020-concepts-and-methods-used-in-the-world-inequality-database/[/URL_LINK]"' + ///
 `"[URL_TEXT]DINA guidelines[/URL_TEXT][/URL]."' if s_ == ""

rename widcode sixlet
order iso sixlet s_ method

tempfile compo
save "`compo'"

// -------------------------------------------------------------------------- //
// Generate metadata for Public Finance
// -------------------------------------------------------------------------- //

u "$wid_dir/Country-Updates/publicfinance/wid-gethinpublicfinance.dta", clear
keep iso widcode method
gduplicates drop iso widcode, force 
replace widcode = substr(widcode, 1, 6)
ren widcode sixlet
replace method = "See [URL][URL_LINK]https://wid.world/document/revisiting-global-poverty-reduction-public-goods-and-the-world-distribution-of-income-1980-2022-wid-world-working-paper-2023-24/[/URL_LINK][URL_TEXT]Gethin A. (2023), Revisiting Global Poverty Reduction: Public Goods and the World Distribution of Income, 1980-2022 " + /// 
"and Gethin A. (2024), A New Database of General Government Revenue and Expenditure by Function, 1980-2022[/URL_TEXT][/URL]; " 
ren method s_ 

tempfile pfgethin_metadata
sa `pfgethin_metadata'

// -------------------------------------------------------------------------- //
// Generate metadata for GDP
// -------------------------------------------------------------------------- //

use "$work_data/retropolate-gdp.dta", clear

egen tmp = mode(level_src), by(iso)
replace level_src = tmp
drop tmp

egen tmp = mode(level_year), by(iso)
replace level_year = tmp
drop tmp

foreach v of varlist growth_src level_src {
	replace `v' = ustrregexrf(`v', "the ", "")
	replace `v' = ustrregexrf(`v', " \(series \d+\)", "")
	replace `v' = "previous year's growth; " if `v' == "value for the previous year"
	replace `v' = "[URL][URL_LINK]https://wid.world/document/piketty-t-and-zucman-g-2014-capital-is-back-wealth-income-ratios-in-rich-countries-1700-2010quarterly-journal-of-economics-1293-1255-1310/[/URL_LINK][URL_TEXT]Piketty T. and Zucman G. (2014), Capital is Back: " + ///
		"Wealth-Income Ratios in Rich Countries 1700-2010, Quarterly Journal " + ///
		"of Economics, 129(3): 1255-1310 (series updated by the same authors)[/URL_TEXT][/URL]; " ///
		if (`v' == "Piketty and Zucman (2014)")
	replace `v' = `"[URL][URL_LINK]http://www.ggdc.net/maddison/other_books/Contours_World_Economy.pdf[/URL_LINK][URL_TEXT]"' + ///
		`"Maddison, Angus (2007). Contours of the World Economy 1-2030 AD.[/URL_TEXT][/URL]; "' ///
		if (`v' == "Maddison (2007)")
	replace `v' = `"[URL][URL_LINK]http://www.ggdc.net/maddison/Monitoring.shtml[/URL_LINK][URL_TEXT]"' + ///
		`"Maddison, Angus (1995). Monitoring the world economy, 1820-1992.[/URL_TEXT][/URL]; "' ///
		if (`v' == "Maddison (1995)")
	replace `v' = `"[URL][URL_LINK]http://www.ggdc.net/maddison/articles/China_Maddison_Wu_22_Feb_07.pdf[/URL_LINK][URL_TEXT]"' + ///
		"Maddison, Angus and Wu, Harry. China’s Economic Performance: " + ///
		"How Fast Has GDP Grown; How Big is it Compared to the USA? (2007). Series " + ///
		"updated by Prof. Harry Wu.[/URL_TEXT][/URL]; " if (`v' == "Maddison and Wu (2007)")
	replace `v' = `"[URL][URL_LINK]http://www.imf.org/external/pubs/ft/weo/$year/01/weodata/index.aspx/[/URL_LINK][URL_TEXT]IMF "' ///
		+ `"World Economic Outlook (04/$year)[/URL_TEXT][/URL]; "' ///
		if inlist(`v', "IMF World Economic Outlook")
	replace `v' = `"[URL][URL_LINK]http://www.imf.org/external/pubs/ft/weo/$year/01/weodata/index.aspx/[/URL_LINK][URL_TEXT]IMF "' ///
		+ `"World Economic Outlook (04/$year, forecast)[/URL_TEXT][/URL]; "' ///
		if inlist(`v', "IMF World Economic Outlook (forecast)")
	replace `v' = `"[URL][URL_LINK]http://unstats.un.org/unsd/snaama/Introduction.asp[/URL_LINK][URL_TEXT]United "' + ///
		`"Nations National Accounts Main Aggregates Database[/URL_TEXT][/URL]; "' if (`v' == "UN SNA main tables")
	replace `v' = `"[URL][URL_LINK]http://unstats.un.org/unsd/nationalaccount/madt.asp[/URL_LINK][URL_TEXT]UN SNA detailed tables[/URL_TEXT][/URL]; "' ///
		if (`v' == "UN SNA detailed tables")
	replace `v' = `"[URL][URL_LINK]http://www.uueconomics.se/danielw/Research_files/National%20Wealth%20of%20Sweden%201810-2014.pdf[/URL_LINK][URL_TEXT]"' + ///
		`"Waldenström, Daniel (2016), The national wealth of Sweden, 1810–2014, "' + ///
		`"Scandinavian Economic History Review 64, n°1 (2016): 36–54.[/URL_TEXT][/URL]; "' if (`v' == "Waldenstrom")
	replace `v' = `"[URL][URL_LINK]http://data.worldbank.org/[/URL_LINK][URL_TEXT]World Bank[/URL_TEXT][/URL]; "' ///
		if (`v' == "World Bank")
	replace `v' = `"[URL][URL_LINK]https://datacatalog.worldbank.org/dataset/global-economic-monitor[/URL_LINK][URL_TEXT]World Bank[/URL_TEXT][/URL]; "' ///
		if (`v' == "World Bank Global Economic Monitor")
	replace `v' = `"[URL][URL_LINK]https://stats.oecd.org/Index.aspx?DataSetCode=SNA_TABLE1[/URL_LINK][URL_TEXT]OECD[/URL_TEXT][/URL]; "' ///
		if (`v' == "OECD")
	
}

// s_s
preserve
	drop if growth_src == "previous year's growth; "
	replace growth_src = level_src if level_src != ""
	drop if growth_src == ""

	keep iso growth_src
	gduplicates drop
	sort iso
	by iso: generate spell = _n

	greshape wide growth_src, i(iso) j(spell)

	egen s = concat(growth_src*)
	drop growth_src*
	replace s = "See DINA guidelines for methodological explanations. The s_s used are: " + substr(s, 1, length(s) - 1) + "."
	rename s s_
	
	tempfile s_
	save "`s_'"
restore
	
// Method
drop if growth_src == ""

gsort iso -year
by iso: generate spell = sum(growth_src[_n - 1] != growth_src)
order iso year spell

collapse (first) growth_src (min) min_year = year (max) max_year = year, by(iso spell level_src level_year)

replace growth_src = string(min_year) + "–" + string(max_year) + ": " + growth_src if (min_year < max_year)
replace growth_src = string(min_year) + ": " + growth_src if (min_year == max_year)
drop min_year max_year

greshape wide growth_src, i(iso) j(spell)

egen m = concat(growth_src*)
drop growth_src*

generate method = "We use the GDP level in " + string(level_year) + " from: " + substr(level_src, 1, length(level_src) - 2) + ". Then we cumulate growth rates from the following s_s; " + substr(m, 1, length(m) - 1) + "."
keep iso method

merge 1:1 iso using "`s_'", nogenerate

generate widcode = "gdpro"

rename widcode sixlet
order iso sixlet s_ method

append using "`compo'"

replace sixlet = "m" + sixlet

append using "`pfgethin_metadata'"

sort iso sixlet

save "$work_data/na-metadata.dta", replace
