//------------------------------------------------------------------------------
// Import  Institutional Factro shares from Dietrich et al. (2025) historical series databse
// -----------------------------------------------------------------------------

clear all

*Define globals
global sheets C1 C2 E1 E2 E3 E4 E5 E6 E7 F1 F2 F3 F4 G1 G2 G3 G4 G5 H2 H3 H4 H5 H6 H7 H8 H9 I1 I2 I3 I4

tempfile combined
save `combined', emptyok


// ------ 1. Import sheets -----------------------------------------------------
foreach s in $sheets {
	di "Now reading: sheet `s'"
	quietly {
		* Call the definition of the variables
		import excel "$wid_dir/Country-Updates/Inst_sectors_DNOPS2025/Dietrichetal2025sectors.xlsx", sheet("`s'")  cellrange(A1:A1) clear
		local def`s' = A[1]
		
		* Call the data
		import excel "$wid_dir/Country-Updates/Inst_sectors_DNOPS2025/Dietrichetal2025sectors.xlsx", ///
				sheet("`s'") firstrow cellrange(A4:BO230) clear

		
		* Tranforms the regions name into WID iso codes
		rename *, upper
		rename (WORLD EUROPE NORTHAMERICAOCEANIA LATINAMERICA MIDDLEEASTNORTHAFRICA) (WO QE XB XL XN)
		rename (SUBSAHARANAFRICA RUSSIACENTRALASIA EASTASIA SOUTHSOUTHEASTASIA) (XF XR QL XS)


		* Format to long
		rename * value*
		capture confirm variable valueA
		if !_rc {
			rename valueA year
		}

		capture confirm variable valueYEAR
		if !_rc {
			rename valueYEAR year
		}
		reshape long value, i(year) j(iso) string
		
		*Label the data with the variable definition
		gen origin="`s'"
		gen concept="`def`s''"
		
		
		tempfile sheet`s'
		save "`sheet`s''"
		
		*Append to the other rest of the data
		use "`combined'", clear
		append using "`sheet`s''"
		save `combined', replace
	}
}

* cleaning
drop if missing(value)
recast float value 
format value %10.5f
replace concept = subinstr(concept, "Data series on ", "", .)
keep if year<=2022

gen changed =0
gen value_org=value

// ------ 2. Generate GDP at factor-prices and NDP adt factor-prices -----------
* Generate pecentage of GDP at factor-prices
expand 2 if origin=="C2", gen (xpnd)
replace origin="C3" if xpnd==1
replace  concept ="factor-price % of GDP" if xpnd==1
replace value=1-value if xpnd==1
drop xpnd

* Generate percentages of GDP for % factor-price GDP
gen aux= value if origin=="C3"
egen factorpricegdp_shr=mode(aux), by(iso year)
drop aux

* Generate percentages of GDP for % factor-price NDP 
expand 2 if origin=="C1", gen (xpnd)
replace origin="C4" if xpnd==1
replace  concept ="factor-price % of NDP" if xpnd==1
replace value=factorpricegdp_shr-value if xpnd==1
drop xpnd

* Generate Percentages of GDP for % factor-price NDP
gen aux= value if origin=="C4"
egen factorpricendp_shr=mode(aux), by(iso year)
drop aux

* Generate percentages NDP 
expand 2 if origin=="C1", gen (xpnd)
replace origin  = "C5"    if xpnd==1
replace concept = "NDP"   if xpnd==1
replace value   = 1-value if xpnd==1
drop xpnd

* Generate gross operating surplus in government sector
* Note: We assume that nsrgo = 0, and therefore gsrgo = cfcgo.
expand 2 if origin=="F1", gen (xpnd)
replace origin="F5" if xpnd==1
replace  concept ="share of gross operating surplus in government sector (% factor-price GDP)" if xpnd==1
drop xpnd
// ------ 3. Generate GDP and NDP, (...) at factor-prices to % of GDP ----------
*-------------- 3.1  Factor-price GDP to GDP
replace value = value*factorpricegdp_shr if strpos(concept,"% factor-price GDP")
replace changed = 1 if strpos(concept,"% factor-price GDP")

*-------------- 3.2 Factor-price NDP to GDP
replace value = value*factorpricendp_shr if strpos(concept,"% factor-price NDP")
replace changed = 1 if strpos(concept,"% factor-price NDP")

*-------------- 3.3 Factor-price gross VA Corp to GDP
* Generate Percentages of GDP for % of factor-price gross VA in corporation sector
gen aux = value if origin=="E2"
egen factorpricevacor_shr=mode(aux), by(iso year)
drop aux

* Recalculate share
replace value = value*factorpricevacor_shr if strpos(concept,"% of factor-price gross VA in corporation sector")
replace changed = 1 					   if strpos(concept,"% of factor-price gross VA in corporation sector")

*-------------- 3.3 Factor-price gross net VA Corp to GDP
* Generate Percentages of GDP for % of factor-price net VA in corporation sector
gen aux = value if origin=="G2"
egen factorpricenetvacor_shr=mode(aux), by(iso year)
drop aux

* Recalculate share
replace value = value*factorpricenetvacor_shr if strpos(concept,"% of net factor-price VA in corporation sector") ///
											   | strpos(concept,"% of factor-price net VA in corporation sector")
replace changed = 1 						  if strpos(concept,"% of net factor-price VA in corporation sector") ///
											   | strpos(concept,"% of factor-price net VA in corporation sector")			 

*tab concept changed
drop factorpricegdp_shr factorpricendp_shr factorpricenetvacor_shr factorpricevacor_shr changed 
sort iso year origin

// ------ 4. Assign Widcodes ---------------------------------------------------
drop if missing(value)

* Macro
*        widcode = "ygdpro999i" --> value=1       // (=)
gen      widcode = "yconfc999i" if origin == "C1" // 
replace  widcode = "yptxgo999i" if origin == "C2" // (+)
replace  widcode = "ygvato999i" if origin == "C3" // (+) // (=)
replace  widcode = "yndpro999i" if origin == "C5" 

* Government
replace  widcode = "ygvago999i" if origin == "E1" //     // (+) // (=)
*replace  widcode = "yceugo999i" if origin == ""  //     //     // (+)
replace  widcode = "ygsrgo999i" if origin == "F5" //     //	    // (+) // (=)
*replace  widcode = "ynsrgo999i" if origin == ""  //     //	    //	   // (+)
replace  widcode = "ycfcgo999i" if origin == "F1" //     //	    //	   // (+)


* Corporate
replace  widcode = "ygvaco999i" if origin == "E2" //     // (+) // (=)
replace  widcode = "yceuco999i" if origin == "H7" //     //	    // (+)
replace  widcode = "ygsrco999i" if origin == "H8" //     //	    // (+) // (=)
replace  widcode = "ynsrco999i" if origin == "H9" //     //     //	   // (+)
replace  widcode = "ycfcco999i" if origin == "F2" //     //	    //	   // (+)

* Hosehold
replace  widcode = "ygvahn999i" if origin == "E3" //     // (+) // (=)
replace  widcode = "yceuhn999i" if origin == "E5" //     //	    // (+)
replace  widcode = "ygmxhn999i" if origin == "E4" //     //	    // (+) // (=)
*replace  widcode = "ynmxhn999i" if origin == ""  //     //	    //	   // (+)
replace  widcode = "yccmhn999i" if origin == "F3" //     //	    //	   // (+)
replace  widcode = "ygsrhn999i" if origin == "E7" //     //	    // (+) // (=) 
*replace  widcode = "ynsrhn999i" if origin == ""  //     //	    //	   // (+)
replace  widcode = "yccshn999i" if origin == "F4" //     //	    //	   // (+)

* Shares
replace  widcode = "ylsgdp999i" if origin == "I1"
replace  widcode = "ycsgdp999i" if origin == "I2"

drop if missing(widcode)
keep iso year widcode value

// ------ 5. Complete missing Widcodes -----------------------------------------
reshape wide value,i(iso year) j(widcode) string
* complete missing aggregates
gen valueynsrgo999i = valueygsrgo999i - valueycfcgo999i
gen valueyceugo999i = valueygvago999i - valueygsrgo999i

gen valueynmxhn999i = valueygmxhn999i - valueyccmhn999i
gen valueynsrhn999i = valueygsrhn999i - valueyccshn999i

// ------ 6. Checks ------------------------------------------------------------
/*
gen valueygvato999i2 = valueygvago999i + valueygvaco999i + valueygvahn999i

gen valueygvago999i2= valueyceugo999i + valueygsrgo999i

foreach x in  gvago gvato {
	di "check of `x':"
	gen dif = abs(valuey`x'999i2-valuey`x'999i)                 
	assert dif<1e-07 & dif!=.
	drop dif
}

drop *2
*/

reshape long value,i(iso year) j(widcode) string

// ------ 7. Export  -----------------------------------------------------------
drop if missing(value)
gen p="pall"
sort iso year
order iso year widcode p value 
label data "Generated by import-dietrichetal2025.do"

preserve
	keep if year>=1970
	save "$work_data/dietrichetal2025sectors_70.dta", replace
restore

preserve
	keep if year<=1980
	save "$work_data/dietrichetal2025sectors_hist.dta", replace
restore
