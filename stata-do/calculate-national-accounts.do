// -------------------------------------------------------------------------- //
// Generate final national accounts series (totals + decomposition)
// -------------------------------------------------------------------------- //

//-------------- 1. Aux tables -------------------------------------------------

//--------------------- 1.1 GDP ------------------------------------------------
use "$work_data/retropolate-gdp.dta", clear

keep iso year gdp currency
rename gdp value
generate widcode = "gdpro"

tempfile gdp
save "`gdp'"

//--------------------- 1.2 Public Finance ------------------------------------------------
use "$wid_dir/Country-Updates/publicfinance/wid-gethinpublicfinance-2024-11-15.dta", clear
drop extrapolation data_points data_quality source method author p

// Note: widcodes= "m" + widcode + "999i"; so we can remove the sufix and prefix and later, 
//       re-insert them
* Remove prefix "m" and sufix "999i"
replace widcode = substr(widcode, 2, .) if substr(widcode, 1, 1) == "m"
replace widcode = subinstr(widcode, "999i", "", .)

* Reshape to wide
reshape wide value, i(iso year) j(widcode) string
rename value* *

tempfile public_finance
save "`public_finance'"

//-------------- 2. Main table -------------------------------------------------
use "$work_data/sna-series-adjusted.dta", clear

drop gdpro series_* gdp_idx *_gdp

drop TH

//	current account
merge 1:1 iso year using "$work_data/bop_currentacc.dta", nogenerate

egen double ncanx = rowtotal(tbnnx   scinx          pinnx comnx taxnx)
replace     ncanx =          tbnnx + scinx + nnfin                    if year <1970

merge 1:1 iso year using "$work_data/retropolate-gdp.dta", nogenerate keep(match) keepusing(gdp currency)

// Merging Public Finance data
merge 1:1 iso year using "`public_finance'", nogenerate

ds iso year gdp currency, not
local varlist = r(varlist)
foreach v of varlist `varlist' {
	gen double y`v' = `v' // Keep values as onlet "Y" for Percentage of GDP
	replace `v' = `v'*gdp // Generate monetary values
}

drop gdp 

renvars  `varlist', prefix(value)
foreach v of local varlist {
	rename y`v' valuey`v' 
}
drop valueycoef_* valuey_merge*

greshape long value, i(iso year currency) j(widcode) string
drop if missing(value)

append using "`gdp'"

sort iso widcode year

replace widcode = "m" + widcode + "999i" if substr(widcode,1,1)!="y"
replace widcode =       widcode + "999i" if substr(widcode,1,1)=="y"

// Kosovo: use KV rather than KS


gen p = "pall"

// national income ratios
drop currency 
greshape wide value, i(iso year p) j(widcode) string

foreach v in ndpro999i gdpro999i nnfin999i finrx999i finpx999i comnx999i pinnx999i nwnxa999i nwgxa999i nwgxd999i comhn999i fkpin999i confc999i comrx999i compx999i pinrx999i pinpx999i fdinx999i fdirx999i fdipx999i ptfnx999i ptfrx999i ptfpx999i flcin999i flcir999i flcip999i ncanx999i tbnnx999i scinx999i tgxcx999i tgmcx999i tgncx999i tgxmx999i tgmmx999i tgnmx999i tbxrx999i tbmpx999i tgxrx999i tgmpx999i tgnnx999i tsxrx999i tsmpx999i tsnnx999i scirx999i scipx999i fkarx999i fkapx999i fkanx999i taxnx999i fsubx999i ftaxx999i expgo999i gpsge999i defge999i polge999i ecoge999i envge999i houge999i heage999i recge999i eduge999i edpge999i edsge999i edtge999i sopge999i spige999i sacge999i sakge999i revgo999i pitgr999i citgr999i scogr999i pwtgr999i intgr999i ottgr999i {
	gen double valuew`v' = valuem`v'/valuemnninc999i
}


/*
// Percentage to the GDP
foreach v in ndpro999i nninc999i nnfin999i finrx999i finpx999i comnx999i pinnx999i nwnxa999i nwgxa999i nwgxd999i comhn999i fkpin999i confc999i comrx999i compx999i pinrx999i pinpx999i fdinx999i fdirx999i fdipx999i ptfnx999i ptfrx999i ptfpx999i flcin999i flcir999i flcip999i ncanx999i tbnnx999i scinx999i tgxcx999i tgmcx999i tgncx999i tgxmx999i tgmmx999i tgnmx999i tbxrx999i tbmpx999i tgxrx999i tgmpx999i tgnnx999i tsxrx999i tsmpx999i tsnnx999i scirx999i scipx999i fkarx999i fkapx999i fkanx999i taxnx999i fsubx999i ftaxx999i expgo999i gpsge999i defge999i polge999i ecoge999i envge999i houge999i heage999i recge999i eduge999i edpge999i edsge999i edtge999i sopge999i spige999i sacge999i sakge999i revgo999i pitgr999i citgr999i scogr999i pwtgr999i intgr999i ottgr999i {
	gen double valuey`v' = valuem`v'/valuemgdpro999i
}
*/
// dropping original foreign portfolio 
drop valuemptfon999i valuemptfop999i valuemptfor999i

// extrapolating based on nninc 
sort iso year 
foreach v in expgo999i gpsge999i defge999i polge999i ecoge999i envge999i houge999i heage999i recge999i eduge999i edpge999i edsge999i edtge999i sopge999i spige999i sacge999i sakge999i revgo999i pitgr999i citgr999i scogr999i pwtgr999i intgr999i ottgr999i {
	by iso : carryforward valuew`v' if year == $pastyear , replace
	replace valuem`v' = valuew`v'*valuemnninc999i if year == $pastyear & mi(valuem`v')
}


greshape long value, i(iso year p) j(widcode) string
merge m:1 iso year using "$work_data/retropolate-gdp.dta", nogen keepusing(currency)


save "$work_data/national-accounts.dta", replace

// -------------------------------------------------------------------------- //
// Generate metadata for components
// -------------------------------------------------------------------------- //

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

merge n:1 iso using "$work_data/sna-wid-metadata.dta", nogenerate keep(master match) keepusing(source)

generate method = "extrapolated from last available year; " if (series == -2)
replace method = "estimated value (see DINA guidelines); " if (series == -3)
replace method = "estimated value (see DINA guidelines, foreign inflows of retained earnings were divided by 10 as in several other tax havens to account for the heterogeneity between domestic and foreign-owned firms); " if (series == -3) & inlist(iso, "KY", "AN", "MU", "BM", "LU", "SX", "CW") & inlist(widcode, "ptfrr", "ptfrn")
replace method = "imputed value; " if (series == -1)
replace method = "[URL][URL_LINK]http://data.un.org/Explorer.aspx[/URL_LINK][URL_TEXT]UN SNA (1968)[/URL_TEXT][/URL]; " if inrange(series, 1, 99)
replace method = "[URL][URL_LINK]http://data.un.org/Explorer.aspx[/URL_LINK][URL_TEXT]UN SNA (1993)[/URL_TEXT][/URL]; " if inrange(series, 100, 999)
replace method = "[URL][URL_LINK]http://data.un.org/Explorer.aspx[/URL_LINK][URL_TEXT]UN SNA (2008)[/URL_TEXT][/URL]; " if inrange(series, 1000, 5000)
replace method = "[URL][URL_LINK]http://data.imf.org/BOP[/URL_LINK][URL_TEXT]IMF Balance of Payments Statistics[/URL_TEXT][/URL]; " if (series == 6000)
replace method = "[URL][URL_LINK]https://stats.oecd.org/Index.aspx?DataSetCode=SNA_TABLE14A[/URL_LINK][URL_TEXT]OECD[/URL_TEXT][/URL]; " if inrange(series, 10000, 20000)
replace method = source if (series == 200000)
replace method = "[URL][URL_LINK]http://wid.world/document/revised-extended-national-wealth-series-australia-canada-france-germany-italy-japan-uk-usa-wid-world-technical-note-2017-23/[/URL_LINK][URL_TEXT]Piketty, Thomas; Zucman, Gabriel (2014). Capital is back: Wealth-Income ratios in Rich Countries 1700-2010. Series updated by Luis Bauluz.[/URL_TEXT][/URL]; " if series == 300000
replace method = "estimated from other components; " if missing(series)

// Sources
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
	replace s = "See [URL][URL_TEXT]DINA guidelines[/URL_TEXT][URL_LINK]https://wid.world/document/distributional-national-accounts-guidelines-2020-concepts-and-methods-used-in-the-world-inequality-database/[/URL_LINK][/URL] for methodological explanations. The sources used are: " + substr(s, 1, length(s) - 1) + "."
	rename s source
	
	tempfile source
	save "`source'"
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

merge 1:1 iso widcode using "`source'", nogenerate
replace source = "See " + ///
 `"[URL][URL_LINK]https://wid.world/document/distributional-national-accounts-guidelines-2020-concepts-and-methods-used-in-the-world-inequality-database/[/URL_LINK]"' + ///
 `"[URL_TEXT]DINA guidelines[/URL_TEXT][/URL]."' if source == ""

rename widcode sixlet
order iso sixlet source method

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
ren method source 

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

// Sources
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
	replace s = "See DINA guidelines for methodological explanations. The sources used are: " + substr(s, 1, length(s) - 1) + "."
	rename s source
	
	tempfile source
	save "`source'"
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

generate method = "We use the GDP level in " + string(level_year) + " from: " + substr(level_src, 1, length(level_src) - 2) + ". Then we cumulate growth rates from the following sources; " + substr(m, 1, length(m) - 1) + "."
keep iso method

merge 1:1 iso using "`source'", nogenerate

generate widcode = "gdpro"

rename widcode sixlet
order iso sixlet source method

append using "`compo'"

replace sixlet = "m" + sixlet

append using "`pfgethin_metadata'"

sort iso sixlet


save "$work_data/na-metadata.dta", replace
