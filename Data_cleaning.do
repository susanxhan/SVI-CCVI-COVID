//National data - cleaning
*Source of deaths, cases, population by county data: John Hopkins University 
*Available at: https://github.com/CSSEGISandData/COVID-19/blob/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_US.csv

*Source of SVI: CDC, 2018 SVI release (Geography: US, Geography Type: Counties, File Type: CSV file)
*Available at: https://www.atsdr.cdc.gov/placeandhealth/svi/data_documentation_download.html

*Source of CCVI: Surgo foundation
*Available at: https://covid-static-assets.s3.amazonaws.com/US-CCVI/ccvi-US.xlsx


//Clean CCVI file
*Use ccvi-US.xlsx file from Surgo foundation --> save ccvi-US-county sheet as ccvi-US.csv
import delimited "ccvi-US.csv", varnames(1)
rename ïfips countyfips
 
*Drop unnecessary vars
drop countyname statename theme1 theme2 theme3 theme4 theme5 theme6 theme7
 
*Save
save "ccvi_county.dta"
clear

//Clean SVI file
import delimited "SVI2018_US_COUNTY.csv", varnames(1) 

rename fips countyfips

*Keep only relevant variables
keep countyfips rpl_themes

rename rpl_themes svi

*Save
save "svi_county.dta"
clear
 
//Clean death data
import delimited "time_series_covid19_deaths_US.csv", varnames(1)  

rename fips countyfips
drop if missing(countyfips)
drop if lat==0
drop if province_state=="Puerto Rico" 
drop if province_state=="American Samoa" 
drop if province_state=="Guam" 
drop if province_state=="Northern Mariana Islands" 
drop if province_state=="Virgin Islands"
drop v13-v366 v368-v374
rename v367 county_deaths

save "covid_deaths_cumulative_final.dta"
clear

//Create merged file
use "covid_deaths_cumulative_final.dta"
 
*Merge in population file
merge 1:1 countyfips using "county_population.dta"
drop _merge
 
*Merge in CCVI file
merge 1:1 countyfips using "ccvi_county.dta"

*Note: 2 FIPS w/o CCVI data: 2270 (Wade Hampton Census Area), 6000 (Grand Princess Cruise Ship)
drop _merge
 
*Merge in SVI file
merge 1:1 countyfips using "svi_county.dta"
*Note: Same 2 FIPS as CCVI lack SVI data
 
*Drop 2 FIPS with missing CCVI, SVI data
drop if missing(svi)
 
*Replace SVI -999 with missing (Rio Arriba County, NM - per CDC documentation, unable to calculate score due to missing Census data)
replace svi=. if svi==-999
 
*Generate deaths/1000 variable
gen deaths_per_thous=(county_deaths/population)*1000
 
summarize deaths_per_thous, detail
/*
                      deaths_per_thous
-------------------------------------------------------------
      Percentiles      Smallest
 1%            0              0
 5%     .1661789              0
10%     .3265306              0       Obs               3,142
25%     .6289076              0       Sum of Wgt.       3,142

50%     1.102222                      Mean           1.279599
                        Largest       Std. Dev.      .9308405
75%     1.679769       6.212664
90%     2.463353       6.568144       Variance       .8664641
95%     2.971768       7.948336       Skewness       1.647358
99%     4.568296       8.345979       Kurtosis       7.946658
*/

//Top decile of SVI
gen svi_top_dec=1 if svi>=0.9

//Top decile of CCVI
gen ccvi_top_dec=1 if ccvi>=0.9

//Top decile of deaths
gen deaths_top_dec=1 if deaths_per_thous>=2.463353

//Top quartile of SVI
gen svi_top_quart=1 if svi>=0.75

//Top quartile of CCVI
gen ccvi_top_quart=1 if ccvi>=0.75

//Top quartile of deaths
gen deaths_top_quart=1 if deaths_per_thous>=1.679769

*Save final analytic dataset
save "national_county_data_final.dta"
 
