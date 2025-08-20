/*
Copyright (C) 2024-2025 SAS Institute Inc. Cary, NC, USA
*/

/**
\file
\anchor  es_remove_adj
\brief  Remove adjustment of actual mortality rate in experience study.

\param [in] cc_var_list       Cross-classification variable list, delimited by space. For example: Product EXP_TYPE GENDER SMOKER X.
\param [in] ADJ_CC_VAL_LIST   Cross-classification value list, delimited by #, character values shall include double quotations and numeric values shall not.
                              The number of values in ADJ_CC_VAL_LIST shall be consistent with the nubmer of variables in cc_var_list,
                              for example "Term Life"#"Actuarial"#"M"#"NS"#62.
\param [in] Audit_trail       Message for Audit trail.

\ingroup Macros
\author  SAS Institute Inc.
\date    2024
*/

%macro es_remove_adj(cc_var_list = PRODUCT EXP_TYPE GENDER SMOKER X, ADJ_CC_VAL_LIST = &cc_val, AGE_VAR = x );

    %let CROSS_VAR_N = %sysfunc(countw(&cc_var_list., %str( )));
    %let CROSS_VAL_N = %sysfunc(countw(&ADJ_CC_VAL_LIST., %str(#)));
    %IF %EVAL(&CROSS_VAR_N - &CROSS_VAL_N) ne 0 %then %do;
       %put "ERROR: the number of cross classification variable is not consistent with the number of given cross classifiction values. Please make sure they are consistent.";
       %abort;
    %end;

    %let ccvar_exclude_age = ;
    %let ccval_exclude_age = ;

    %do i = 1 %to &CROSS_VAR_N.;
        %let var= %scan(&CC_VAR_LIST., &i., %str( ));
        %let val= %scan(&ADJ_CC_VAL_LIST., &i., %str(#));
        %if %upcase(&var) ne %upcase(&AGE_VAR) %then %do;
            %let ccvar_exclude_age = &ccvar_exclude_age &var;
            %let ccval_exclude_age = &ccval_exclude_age.#&val.;
        %end;
        %else %do;
            %let age_val = &val;
        %end;
    %end;

    %let if_condition_without_age = ;
    %do i = 1 %to %sysfunc(countw(&ccvar_exclude_age., %str( )));
        %let var= %scan(&ccvar_exclude_age., &i., %str( ));
        %let value = %scan(&ccval_exclude_age., &i., %str(#));
        %if %eval(&i) eq 1 %then %do;

            %let if_condition_without_age = &if_condition_without_age &var = &value;
        %end;
        %else %do;
           %let if_condition_without_age = &if_condition_without_age  and &var = &value;
        %end;
    %end;
    DATA temp_val (drop = A_E_predicted A_E_P_W ) CASUSER._&es_val. (REPLACE = YES);
		SET &caslib..&es_val. end = eof;
         if  &if_condition_without_age
         then do;
            IF &AGE_VAR EQ &age_val THEN DO;
                qx = qx_orig;
                dx = dx_orig;
                dx_amt=dx_amt_orig;
                qx_amt = dx_amt_orig;
                A_E = A_E_orig;
                A_E_AMT = A_E_AMT_orig;
                Adj_desc = "";
                Adj = 0;
            END;
            OUTPUT temp_val;
         end;
         ELSE OUTPUT CASUSER._&es_val.;
    RUN;

    data temp_val(drop = sum_dx sum_e_dx sum_dx_amt sum_e_dx_amt A_E_T A_E_A_T);
        set temp_val end = eof;
        retain sum_dx sum_e_dx sum_dx_amt sum_e_dx_amt;
        if _N_ = 1 then do;
            sum_dx = 0;
            sum_e_dx = 0;
            sum_dx_amt=0;
            sum_e_dx_amt=0;
        end;
        sum_dx + dx;
        sum_e_dx + e_dx;
        sum_dx_amt + dx_amt;
        sum_e_dx_amt+e_dx_amt;
        if eof then do;
            A_E_T = sum_dx/sum_e_dx;
            Call Symput("A_E_T",A_E_T);
            A_E_A_T = sum_dx_amt/sum_e_dx_amt;
            Call Symput("A_E_A_T",A_E_A_T);
        end;
    run;

    PROC SORT data=temp_val ;
        BY &cc_var_list ;
    RUN;

    ods exclude all;
    ods output ParameterEstimates = parm1;
    proc reg data=temp_val;
        A_E: model qx = E_qx / NOINT;
        output out = es_val1
        p = A_E_predicted;
        BY &ccvar_exclude_age;
    run;
    ods output ParameterEstimates = parm2;
    proc reg data=es_val1;
        A_E_W: model qx = E_qx / NOINT;
        output out = es_val
        p = A_E_P_W;
        BY &ccvar_exclude_age;
        WEIGHT Ex;
    run;

    proc sql noprint;
        select Estimate into: A_E_parm from parm1;
        select Estimate into: A_E_parm_w from parm2;
    quit;
    DATA CASUSER._&es_val. (append = force);
		SET WORK.es_val;
	RUN;
    DATA CASUSER._&es_parm.;
		SET &caslib..&es_parm.;
        if &if_condition_without_age and MODEL = "Least Squared A/E" then a =&A_E_parm;
        if &if_condition_without_age and MODEL = "Least Squared A/E weighted by exposure" then a =&A_E_parm_w;
        if &if_condition_without_age and MODEL = "Total A/E" then a =&A_E_T;
        if &if_condition_without_age and MODEL = "Total A/E by Amount" then a =&A_E_A_T;
	RUN;

	proc casutil;
		droptable casdata="&es_val." incaslib="&caslib." QUIET;
        save casdata="_&es_val." incaslib="CASUSER" casout="&es_val." outcaslib="&caslib." replace;
    	promote casdata="_&es_val." incaslib="CASUSER" casout="&es_val." outcaslib="&caslib.";

		droptable casdata="&es_parm." incaslib="&caslib." QUIET;
        save casdata="_&es_parm." incaslib="CASUSER" casout="&es_parm." outcaslib="&caslib." replace;
    	promote casdata="_&es_parm." incaslib="CASUSER" casout="&es_parm." outcaslib="&caslib.";
	run;

%MEND;
