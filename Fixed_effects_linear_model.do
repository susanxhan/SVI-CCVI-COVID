use "national_county_data_final.dta", clear

drop if state == "DC"

encode state, gen(ST)

egen state_flag = tag(state)

* COVID-19 mortality explained by state 
regress  deaths_per_thous i.ST
local SSRes_reduced = e(rss)


* COVID-19 mortality explained by within-state SVI + state 
regress  deaths_per_thous i.ST ST##c.svi
local SSRes_full_svi = e(rss)


* Proportion of within-state variance in COVID-19 mortality explained by SVI
di (`SSRes_reduced' - `SSRes_full_svi')/`SSRes_reduced'


gen svi_state_association = .
forvalues i = 1/50{
	qui lincom svi + `i'.ST#svi
	local cur_est = r(estimate)
	qui replace svi_state_association = `cur_est'/10 if ST == `i'
}

gen state_r_squared_svi = .
forvalues i = 1/50{	
	qui regress deaths_per_thous svi if ST == `i'
	local r_sq = e(r2)
	qui replace state_r_squared_svi = `r_sq' if ST == `i'
}

summarize svi_state_association if state_flag ==1, detail

sort state_r_squared_svi
format state_r_squared_svi %12.4f
list state state_r_squared_svi if state_flag ==1

* COVID-19 mortality explained by within-state CCVI + state 
regress  deaths_per_thous i.ST ST##c.ccvi
local SSRes_full_ccvi = e(rss)


* Proportion of within-state variance in COVID-19 mortality explained by CCVI
di (`SSRes_reduced' - `SSRes_full_ccvi')/`SSRes_reduced'


gen ccvi_state_association = .
forvalues i = 1/50{
	qui lincom ccvi + `i'.ST#ccvi
	local cur_est = r(estimate)
	qui replace ccvi_state_association = `cur_est'/10 if ST == `i'
}

gen state_r_squared_ccvi = .
forvalues i = 1/50{	
	qui regress deaths_per_thous ccvi if ST == `i'
	local r_sq = e(r2)
	qui replace state_r_squared_ccvi = `r_sq' if ST == `i'
}

summarize ccvi_state_association if state_flag ==1, detail

sort state_r_squared_ccvi
format state_r_squared_ccvi %12.4f
list state state_r_squared_ccvi if state_flag ==1


