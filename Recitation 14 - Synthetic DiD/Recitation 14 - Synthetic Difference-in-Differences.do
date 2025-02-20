**************************************
*                                    *
*                                    *
*           Recitation 14            *
*                                    *
*                                    *
**************************************

// Date: 4/11/24
// By: Bruno Kömel

**********************************
*                                *
*                                *
*            Example 1           *
*                                *
*                                *
**********************************


// Synthetic Difference-in-Differences
// By Dmitry Arkhangelsky, Susan Athey, David A. Hirshberg, Guido W. Imbens, and Stefan Wager
// https://www.aeaweb.org/articles?id=10.1257/aer.20190159

cd "/Users/brunokomel/Documents/Pitt/Year 3/TA - Econ 3080/econ-3080-recitations/Recitation 14 - Synthetic DiD"

global seed_num = 824 

set scheme gg_tableau

webuse set www.damianclarke.net/stata/
webuse prop99_example.dta, clear

bro

// ssc install sdid, replace
// or 
// net install sdid, from("https://raw.githubusercontent.com/daniel-pailanir/sdid/master") replace

#delimit ;

local scheme = "gg_tableau" ;

sdid packspercapita state year treated, vce(placebo) reps(100) seed($seed_num) g1on
     graph g1_opt(xtitle("") ylabel(-35(5)10) scheme(`scheme')) 
     g2_opt(ylabel(0(50)150) xlabel(1970(5)2000) ytitle("Packs per capita") 
            xtitle("") text(125 1995 "ATT = `e(ATT)'" " SE = (`e(se)')") scheme(`scheme'));
    //graph_export(sdid_, .png);
#delimit cr


// Let's break down the command. 
// Again, #delimit; just changes the character that marks the end of a command
// Then sdid requires you to specify a y variable (here packspercapita) and then it requires a group variable, that distinguishes the units and a time variable to distinguish the periods. 
// Finally you need a treated variable that is equal to 1 for all periods in which the treated unit was treated, and 0 otherwise (always 0 for control units)
// vce allows you to specify how you want to calculate the standard erros. Placebo is the only method that does not require more than one treated unit per treated period, so we go with that
// Reps specifies how many times to run the procedure (for standard error estimation)
// seed sets the seed
// g1on turns "on" the option to output the plot with the weights assigned to each unit
// g1_opt and g2_opt allow you to personalize the plot
// graph_export specifies how you want the graph to be saved in your working directory. In this case it'll be saved as "sdid_trends1989 and sdid_weights1989" , where 1989 is the treatment year

// We can also use this command to output a regular old synthetic control plot

#delimit ;

local scheme = "gg_tableau" ;

sdid packspercapita state year treated, vce(placebo) reps(100) seed($seed_num) method(sc) g1on
     graph g1_opt(xtitle("") ylabel(-35(5)10) scheme(`scheme')) 
     g2_opt(ylabel(0(50)150) xlabel(1970(5)2000) ytitle("Packs per capita") 
            xtitle("") text(125 1995 "ATT = `e(ATT)'" " SE = (`e(se)')") scheme(`scheme'));
    //graph_export(sdid_, .png);
#delimit cr

// Notice that the only difference is that we specified "method(sc)"

// As well as a DiD
#delimit ;

local scheme = "gg_tableau" ;

sdid packspercapita state year treated, vce(placebo) reps(100) seed($seed_num) method(did) g1on
     graph g1_opt(xtitle("") ylabel(-35(5)10) scheme(`scheme')) 
     g2_opt(ylabel(0(50)150) xlabel(1970(5)2000) ytitle("Packs per capita") 
            xtitle("") text(125 1995 "ATT = `e(ATT)'" " SE = (`e(se)')") scheme(`scheme'));
    //graph_export(sdid_, .png);
#delimit cr
// Notice that the only difference is that we specified "method(did)"

// Just to show how to add covariates to the specification
*create a uniform variable to use as a control
gen r=runiform()

*run sdid
eststo sdid_1: sdid packspercapita state year treated, vce(placebo) seed($seed_num)
eststo sdid_2: sdid packspercapita state year treated, vce(placebo) seed($seed_num) covariates(r, projected)

// for details on the "projected", let's check the helpfile

*create a table
esttab sdid_1 sdid_2, starlevel ("*" 0.10 "**" 0.05 "***" 0.01) b(%-9.3f) se(%-9.3f)

**********************************
*                                *
*                                *
*            Example 2           *
*                                *
*                                *
**********************************

// Example from help file

webuse set damianclarke.net/stata/

webuse quota_example.dta, clear
// we can look at this other example where we have women in parliament as the outcome variable 
// and quota as the treatment variable. So quota is 1 in country-years when the observation had a quota for women in parliament


sdid womparl country year quota, vce(bootstrap) seed($seed_num)

sdid womparl country year quota, vce(bootstrap) seed($seed_num) covariates(lngdp, projected)

drop if lngdp == .

sdid womparl country year quota, vce(bootstrap) seed($seed_num) covariates(lngdp, projected)
sdid womparl country year quota, vce(bootstrap) seed($seed_num) covariates(lngdp) // this might take forever

**********************************
*                                *
*                                *
*            Example 3           *
*                                *
*                                *
**********************************

///Another example - Just to show that the period weights may be different, depending on the data
// First, let's just generate some data

clear

local units = 30
local start = 1
local end 	= 60

local time = `end' - `start' + 1
local obsv = `units' * `time'
set obs `obsv'

egen id	   = seq(), b(`time')  
egen t 	   = seq(), f(`start') t(`end') 	

sort  id t
xtset id t


set seed $seed_num

gen Y 	   		= 0		// outcome variable	
gen D 	   		= 0		// intervention variable
gen cohort      = .  	// treatment cohort
gen effect      = .		// treatment effect size
gen first_treat = .		// when the treatment happens for each cohort
gen rel_time	= .     // time - first_treat

levelsof id, local(lvls)
foreach x of local lvls {
	local chrt = runiformint(0,5)	
	replace cohort = `chrt' if id==`x'
}


levelsof cohort , local(lvls)  

foreach x of local lvls {
	
	local eff = runiformint(2,10)
		replace effect = `eff' if cohort==`x'
			
	local timing = runiformint(`start',`end' + 20)	// 
	replace first_treat = `timing' if cohort==`x'
	replace first_treat = . if first_treat > `end'
		replace D = 1 if cohort==`x' & t>= `timing' 
}

replace rel_time = t - first_treat
replace Y = id + t + cond(D==1, effect * rel_time, 0) + rnormal()

// Here cond(s,a,b,[,c]) executes a if x is true and nonmissing, b if x is false, and c if x is missing; a if c is not specified and x evaluates to missing


rename t year

xtline Y, overlay legend(off)

sdid Y id year D, vce(bootstrap) seed($seed_num) 

sdid Y id year D, vce(bootstrap) seed($seed_num) graph g1on

// Notice that here we have staggered treatment, and the command automatically recognizes that


**********************************
*                                *
*                                *
*            Exercise            *
*                                *
*                                *
**********************************

// Let's use sdid to perform the same analysis we did in Recitation 5
use https://github.com/scunning1975/mixtape/raw/master/texas.dta, clear

gen treated = 0
replace treated = 1 if year >= 1993 & statefip == 48

// 1. Recreate the plot from Recitation 6 using sdid instead of synth. Make sure to use the synthetic control method.

#delimit ;

local scheme = "gg_tableau" ;

sdid bmprison state year treated , vce(placebo) reps(100) seed($seed_num) method(sc) g1on
     graph g1_opt(xtitle("") scheme(`scheme')) 
     g2_opt( ytitle("Packs per capita") 
            xtitle("") text(15000 1995 "ATT = `e(ATT)'" " SE = (`e(se)')") scheme(`scheme'));
    //graph_export(sdid_, .png);
	
#delimit cr

// 2. Use sdid instead and compare the ATT, the weights, and the trends plot.

#delimit ;

local scheme = "gg_tableau" ;

sdid bmprison state year treated , vce(placebo) reps(100) seed($seed_num) method(sdid) g1on
     graph g1_opt(xtitle("") scheme(`scheme')) 
     g2_opt( ytitle("Packs per capita") 
            xtitle("") text(15000 1995 "ATT = `e(ATT)'" " SE = (`e(se)')") scheme(`scheme'));
    //graph_export(sdid_, .png);
	
#delimit cr
        
// 3. Marvel at how much easier and cleaner this was. (And notice the omission of an ATT in the Recitation 5 file)
