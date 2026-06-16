//---------------------------------------------------------------------------//
// Comand to generate metadata for calcuated 
//---------------------------------------------------------------------------//



















program define quality
    version 18.0
    syntax varlist(min=1 numeric) , Generate(name) ///
        [ Weights(numlist) ]
    tempvar vmax missflag
    *--------------------------------------------*
    * Check q_ variables exist
    *--------------------------------------------*
    foreach v of local varlist {
        capture confirm variable q_`v'
        if _rc {
            di as error "Variable q_`v' does not exist"
            exit 111
        }
    }
    *--------------------------------------------*
    * Default weights = 1
    *--------------------------------------------*
    local nvars : word count `varlist'
    if "`weights'" == "" {
        forvalues i = 1/`nvars' {
            local weights `weights' 1
        }
    }
    local nweights : word count `weights'
    if `nweights' != `nvars' {
        di as error "weights() must contain one weight per variable"
        exit 198
    }
    *--------------------------------------------*
    * Missing values — count non-missing instead
    *--------------------------------------------*
    egen `missflag' = rownonmiss(`varlist')
    *--------------------------------------------*
    * Build weighted copies (treat missing as 0)
    *--------------------------------------------*
    local wvars
    local i = 1
    foreach v of local varlist {
        tempvar w`i'
        local wt : word `i' of `weights'
        gen double `w`i'' = abs(`wt' * `v')
        replace `w`i'' = 0 if missing(`v')
        local wvars `wvars' `w`i''
        local ++i
    }
    *--------------------------------------------*
    * Largest weighted contribution
    *--------------------------------------------*
    egen `vmax' = rowmax(`wvars')
    *--------------------------------------------*
    * Output
    *--------------------------------------------*
    gen `generate' = .
    local i = 1
    foreach v of local varlist {
        local wt : word `i' of `weights'
        replace `generate' = q_`v' ///
            if `missflag' > 0 ///
            & (`wt' * `v') == `vmax' ///
            & missing(`generate') ///
            & !missing(`v')
        local ++i
    }
    *--------------------------------------------*
    * Cap at 3
    *--------------------------------------------*
    replace `generate' = min(3, `generate') ///
        if `missflag' > 0
end

/*
program define quality
    version 18.0

    syntax varlist(min=1 numeric) , Generate(name) ///
        [ Weights(numlist) ]

    tempvar vmax missflag

    *--------------------------------------------*
    * Check q_ variables exist
    *--------------------------------------------*
    foreach v of local varlist {
        capture confirm variable q_`v'
        if _rc {
            di as error "Variable q_`v' does not exist"
            exit 111
        }
    }

    *--------------------------------------------*
    * Default weights = 1
    *--------------------------------------------*
    local nvars : word count `varlist'

    if "`weights'" == "" {
        forvalues i = 1/`nvars' {
            local weights `weights' 1
        }
    }

    local nweights : word count `weights'

    if `nweights' != `nvars' {
        di as error "weights() must contain one weight per variable"
        exit 198
    }

    *--------------------------------------------*
    * Missing values
    *--------------------------------------------*
    egen `missflag' = rowmiss(`varlist')

    *--------------------------------------------*
    * Build weighted copies
    *--------------------------------------------*
    local wvars

    local i = 1
    foreach v of local varlist {

        tempvar w`i'

        local wt : word `i' of `weights'

        gen double `w`i'' = abs(`wt' * `v')

        local wvars `wvars' `w`i''

        local ++i
    }

    *--------------------------------------------*
    * Largest weighted contribution
    *--------------------------------------------*
    egen `vmax' = rowmax(`wvars')

    *--------------------------------------------*
    * Output
    *--------------------------------------------*
    gen `generate' = .

    local i = 1
    foreach v of local varlist {

        local wt : word `i' of `weights'

        replace `generate' = q_`v' ///
            if `missflag' == 0 ///
            & (`wt' * `v') == `vmax' ///
            & missing(`generate')

        local ++i
    }

    *--------------------------------------------*
    * Cap at 3
    *--------------------------------------------*
    replace `generate' = min(3, `generate') ///
        if `missflag' == 0

end
*/


/*
program define quality
    version 18.0

    syntax varlist(min=1 numeric) , Generate(name)

    tempvar vmax missflag

    *------------------------------------------------------------*
    * Check that q_ variables exist
    *------------------------------------------------------------*
    foreach v of local varlist {
        capture confirm variable q_`v'
        if _rc {
            di as error "Variable q_`v' does not exist"
            exit 111
        }
    }

    *------------------------------------------------------------*
    * detect missing inputs
    *------------------------------------------------------------*
    egen `missflag' = rowmiss(`varlist')

    *------------------------------------------------------------*
    * Create max variable
    *------------------------------------------------------------*
    egen `vmax' = rowmax(`varlist')

    *------------------------------------------------------------*
    * Initialize output
    *------------------------------------------------------------*
    gen `generate' = .

    *------------------------------------------------------------*
    * Assign corresponding q_ only if complete case
    *------------------------------------------------------------*
    foreach v of local varlist {

        replace `generate' = q_`v' ///
            if `missflag' == 0 ///
            & `v' == `vmax' ///
            & missing(`generate')
    }

    *------------------------------------------------------------*
    * Apply cap at 3 (only where defined)
    *------------------------------------------------------------*
    replace `generate' = min(3, `generate') if `missflag' == 0

end
*/
