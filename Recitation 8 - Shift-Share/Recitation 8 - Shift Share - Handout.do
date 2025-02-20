**************************************
*                                    *
*                                    *
*           Recitation 8            *
*                                    *
*                                    *
**************************************

// Date: 2/29/2024
// By: Bruno Kömel

// We'll be using data from 

// The China Syndrome: Local Labor Market Effects of Import Competition in the United States
// By Autor, Dorn, Hanson (2013)
// https://www.aeaweb.org/articles?id=10.1257/aer.103.6.2121

global ADH_derived https://github.com/zhangxiang0822/ShiftShareSEStata/raw/master/data/ADH_derived.dta

use $ADH_derived, clear

global controls t2 l_shind_manuf_cbp reg_encen reg_escen reg_midatl reg_mount reg_pacif reg_satl reg_wncen reg_wscen l_sh_popedu_c l_sh_popfborn l_sh_empl_f l_sh_routine33 l_task_outsource

global controls2 t2 l_sh* reg_* 


// ssc install ivreg_ss
// ssc install reg_ss

// Just replicating column 1 and 6 of table 3 on the ADH 2013 paper
ivreg2 d_sh_empl_mfg (d_tradeusch_pw=d_tradeotch_pw_lag) t2 [aw=weight], cluster(state) first
* recall, you should read this as: ivreg2 'outcome' ('endogenous variable' = 'instrument') controls [weight], cluster  

ivreg2 d_sh_empl_mfg (d_tradeusch_pw=d_tradeotch_pw_lag) $controls [aw=weight], cluster(state) first

// Example 1 

ivreg_ss d_sh_empl_mfg, endogenous_var(d_tradeusch_pw) shiftshare_iv(d_tradeotch_pw_lag) control_varlist($controls) share_varlist(emp_share1-emp_share770) weight_var(weight) alpha(0.05) akmtype(1) firststage(1)

// Example 2 (using the AKM0 model)
use $ADH_derived, clear

ivreg_ss d_sh_empl_mfg, endogenous_var(d_tradeusch_pw) shiftshare_iv(d_tradeotch_pw_lag) control_varlist($controls) share_varlist(emp_share1-emp_share770) weight_var(weight) akmtype(0) firststage(1)

// Example 3 (now clustering at the sector level)
use $ADH_derived, clear

global cpath "https://github.com/zhangxiang0822/ShiftShareSEStata/raw/master/data/sector_derived.dta"

ivreg_ss d_sh_empl_mfg, endogenous_var(d_tradeusch_pw) shiftshare_iv(d_tradeotch_pw_lag) control_varlist($controls2) share_varlist(emp_share1-emp_share770) weight_var(weight) akmtype(1) path_cluster(`cpath') cluster_var(sec_3d) firststage(1)

use $cpath, clear

// Example 4 (Using the AKM0 Model)
use $ADH_derived, clear

ivreg_ss d_sh_empl, endogenous_var(d_tradeusch_pw) shiftshare_iv(d_tradeotch_pw_lag) control_varlist($controls) share_varlist(emp_share1-emp_share770) weight_var(weight) akmtype(0) path_cluster(`cpath') cluster_var(sec_3d) firststage(1)

// Example 5 (clustering at the state level)
use $ADH_derived, clear

ivreg_ss d_sh_empl_mfg, endogenous_var(d_tradeusch_pw) shiftshare_iv(d_tradeotch_pw_lag) control_varlist($controls2) share_varlist(emp_share1-emp_share770) weight_var(weight) akmtype(1)  cluster_var(state) firststage(1)


**************************************
*                                    *
*                                    *
*              Exercise              *
*                                    *
*                                    *
**************************************

use "https://github.com/brunokomel/econ-3080-recitations/raw/main/Recitation%208%20-%20Shift-Share/workfile_china_id.dta", clear

keep lnchg_popworkage czone statefip yr t2

// Let's create a unique id for each czone, in each state, for each year, for each t2 so we can merge the two datasets
egen id = concat(czone statefip yr t2)
unique id 


// Change this in your computers:
cd "/Users/brunokomel/Documents/Pitt/Year 3/TA - Econ 3080/econ-3080-recitations/Recitation 8 - Shift-Share/"

save "workfile_china_id.dta", replace

use $ADH_derived, clear

egen id = concat(czone state year t2)
unique id

merge 1:1 id using "/Users/brunokomel/Documents/Pitt/Year 3/TA - Econ 3080/econ-3080-recitations/Recitation 8 - Shift-Share/workfile_china_id.dta"

drop _merge id

* Exercise: Replicate the first coefficient in table 4 using both the ivreg2 and the ivreg_ss command
* Note, the outcome of interest now is lnchg_popworkage
