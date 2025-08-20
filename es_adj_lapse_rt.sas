/*
Copyright (C) 2024-2025 SAS Institute Inc. Cary, NC, USA
*/

/**
\file
\anchor  es_adj_lapse_rt
\brief  Apply adjustment on lapse rate in experience study.

\param [in] cc_var_list       Cross-classification variable list, delimited by space. For example: Product EXP_TYPE GENDER SMOKER X.
\param [in] ADJ_CC_VAL_LIST   Cross-classification value list, delimited by #, character values shall include double quotations and numeric values shall not.
                              The number of values in ADJ_CC_VAL_LIST shall be consistent with the nubmer of variables in cc_var_list,
                              for example "Term Life"#"Actuarial"#"M"#"NS"#62.
\param [in] Audit_trail       Message for Audit trail.

\ingroup Macros
\author  SAS Institute Inc.
\date    2025
*/

%MACRO es_adj_lapse_rt(CC_VAR_LIST = , ADJ_CC_VAL_LIST = &product, ADJ_TO = &_to, AUDIT_TRAIL = &auditral);

    %let CROSS_VAR_N = %sysfunc(countw(&CC_VAR_LIST., %str( )));
    %let CROSS_VAL_N = %sysfunc(countw(&ADJ_CC_VAL_LIST., %str(#)));
    %IF %EVAL(&CROSS_VAR_N - &CROSS_VAL_N) ne 0 %then %do;
       %put "ERROR: the number of cross classification variable is not consistent with the number of given cross classifiction values. Please make sure they are consistent.";
       %abort;
    %end;

    %let lapse_col_nm = ;
    %let msg_nm = ;

    %if &ADJ_TYPE. = BY_CNT %then %do;
       %let lapse_col_nm=LAPSE_RATE_BY_CNT;
       %let msg_nm=Count;
    %end;
    %else %do;
       %let lapse_col_nm=LAPSE_RATE_BY_AMT;
       %let msg_nm=Amount;
    %end;

   %let if_condition=;
        %do i = 1 %to %sysfunc(countw(&CC_VAR_LIST., %str( )));
            %let var= %scan(&CC_VAR_LIST., &i., %str( ));
            %let value = %scan(&ADJ_CC_VAL_LIST., &i., %str(#));
            %if %eval(&i) eq 1 %then %do;
                %let if_condition = &if_condition &var = &value;
            %end;
            %else %do;
               %let if_condition = &if_condition  and &var = &value;
            %end;
       %end;

       %let Msg=&sysdate9. &systime &SYS_COMPUTE_SESSION_OWNER, adjust lapse rate by &msg_nm;
          %if &audit_trail=  %then %do;
              %let Msg="&Msg.";
          %end;
          %else %do;
              %let Msg="&Msg. comment: &audit_trail.";
          %end;

    DATA casuser._&es_res;
      length ADJ_DESC $132;
       SET &caslib..&es_res. ;
         if  &if_condition.
         then do;
            &lapse_col_nm = &adj_to;
            ACTUAL_LAPSE_RATE=&adj_to;
            ADJ=1;
            ADJ_DESC=&Msg.;
         end;
    RUN;

   proc casutil;
      droptable casdata="&es_res." incaslib="&caslib." QUIET;
        save casdata="_&es_res." incaslib="CASUSER" casout="&es_res." outcaslib="&caslib." replace;
      promote casdata="_&es_res." incaslib="CASUSER" casout="&es_res." outcaslib="&caslib.";
   run;
%MEND;
