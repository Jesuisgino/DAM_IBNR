/*
Copyright (C) 2024-2025 SAS Institute Inc. Cary, NC, USA
*/

/**
\file
\anchor  es_adj_mortality_rt
\brief  Apply adjustment on actual mortality rate in experience study.

\param [in] cc_var_list       Cross-classification variable list, delimited by space. For example: Product EXP_TYPE GENDER SMOKER X.
\param [in] ADJ_CC_VAL_LIST   Cross-classification value list, delimited by #, character values shall include double quotations and numeric values shall not.
                              The number of values in ADJ_CC_VAL_LIST shall be consistent with the nubmer of variables in cc_var_list,
                              for example "Term Life"#"Actuarial"#"M"#"NS"#62.
\param [in] age_var           Variable name representing age
\param [in] Audit_trail       Message for Audit trail.

\ingroup Macros
\author  SAS Institute Inc.
\date    2024
*/

%MACRO es_adj_mortality_rt(CC_VAR_LIST = , ADJ_CC_VAL_LIST = &product, AGE_VAR =x, ADJ_TO = &_to, AUDIT_TRAIL = &auditral);

    %let CROSS_VAR_N = %sysfunc(countw(&CC_VAR_LIST., %str( )));
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

       %let Msg=&sysdate9. &systime &SYS_COMPUTE_SESSION_OWNER, adjust actual mortality rate;
			%if &audit_trail=
						%then %do;
							%let Msg="&Msg.";
						%end;
						%else %do;
							%let Msg="&Msg.  comment:&audit_trail.";
						%end;
    DATA temp_val (drop = max_adj factor) casuser._&es_val( drop = max_adj factor replace = yes);
		SET &caslib..&es_val. end = eof;
        retain max_adj;
	     if _N_ eq 1 then max_adj = 0;

         if  &if_condition_without_age
         then do;
            max_adj = MAX(MAX_adj, adj);
            if &age_var eq &age_val then do;
                qx = &adj_to;
                dx = qx*ex;
                if qx_orig ne 0 then do;
                   factor = &adj_to/qx_orig;
                   dx_amt=dx_amt*factor;
                end;
                /*It is an estimation of the dx_amt, not acurrate*/
                else do;
                   dx_amt = dx * E_dx_amt/E_dx;
                end;
                qx_amt = dx_amt/ex_amt;
                A_E = dx/e_dx;
                A_E_AMT = dx_amt/e_dx_amt;
                Adj_desc = &Msg.;
             end;
             output temp_val;
         end;
         else output casuser._&es_val;
         if eof then Call Symput("CURR_ADJ_CNT",max_adj);
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
        if &age_var eq &age_val then do;
             adj = %eval(&CURR_ADJ_CNT. + 1);
        end;
        if eof then do;
            A_E_T = sum_dx/sum_e_dx;
            Call Symput("A_E_T",A_E_T);
            A_E_A_T = sum_dx_amt/sum_e_dx_amt;
            Call Symput("A_E_A_T",A_E_A_T);
        end;
    run;

    PROC SORT data=temp_val(DROP = A_E_predicted A_E_P_W) ;
        BY &CC_VAR_LIST ;
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
