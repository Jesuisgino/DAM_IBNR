/*
Copyright (C) 2022-2025 SAS Institute Inc. Cary, NC, USA
*/

/**
\file
\anchor  pcpr_prepare_input_ratebook
\brief   Macro to prepare input ratebook table, used by both Generate-Ratebook-FreqSev and Generate-Ratebook-Rules script
         - Copy input table to a table with valid sas names
         - Check if interactionFlag exist in the input ratebook table (since we shall still support existing ratebook without the new added interaction related columns)
         - Based on the interactionFlag exist result, check required columns in the ratebook
         - Find out the maximum value of the upper bound for interval variable if upper_bound_max macro variable name is specified
         - Sort ratebook

\param [in] required_column         Required columns in the ratebook if interaction flag does not exist
\param [in] required_column_new     Additional required columns in the ratebook if interaction flag does not exist
\param [in] in_caslib               Input cas library for the ratebook table
\param [in] in_ds                   Input ratebook table name
\param [in] out_caslib              Output cas library for the ratebook table
\param [in] out_ds                  Output ratebook table name
\param [in] use_tb_name             Optional intermediate ratebook table name, default to _tmp_ratebook
\param [in] interaction_exist_flg   macro variable name that hold result of checking interaction flag existence
\param [in] upper_bound_max         macro variable name that hold the maximum value of the upper bound for interval variable if specified
\param [in] cas_session_name        Cas session name

\details This macro is called by both enrich-pricing-data script for annuity pricing and enrich-inquiry-data script for universal life cash value projection. For annuity pricing,
the enrichment is for pricing analysis and the input data type is "ABT". While for universal life, the enrichment is for cash value projection and the input data type is "SCR".
Note that user needs to drop or promote cas tables if needed outside this macro if needed.

\ingroup Macros
\author  SAS Institute Inc.
\date    2023
*/
%macro pcpr_prepare_input_ratebook(required_column=, required_column_new=,in_caslib=, in_ds=, out_caslib=, out_ds=, use_tb_name=_tmp_ratebook, interaction_exist_flg=, upper_bound_max=,cas_session_name=&casSessionName.);

    /*drop the tables if they already exist*/
    %pcpr_drop_promoted_table(caslib_nm=&out_caslib.,table_nm=&out_ds.,cas_session_name=&casSessionName.);

    /*rename the input table name to a valid sas name*/
    proc casutil;
        copy casdata="&in_ds."
           casout="&use_tb_name."
           incaslib= "&in_caslib."
           outcaslib="&in_caslib."
           replace;
     quit;

    /*Verify required columns exist*/
   /*First check input frequency and severity ratebook validity*/
   %global &interaction_exist_flg interaction_missing_var;
    %global SUCCESS_FLG MISSING_VAR;


   %rsk_verify_ds_col(REQUIRED_COL_LIST=interactionFlag, IN_DS_LIB =&cas_data_lib., IN_DS_NM =&use_tb_name., OUT_SUCCESS_FLG =&interaction_exist_flg.,OUT_MISSING_VAR =interaction_missing_var);

   %if &&&interaction_exist_flg. eq Y %then %do;
      /*frequency rate book*/
       %rsk_verify_ds_col(REQUIRED_COL_LIST=&required_column. &required_column_new., IN_DS_LIB =&in_caslib., IN_DS_NM =&use_tb_name., OUT_SUCCESS_FLG =SUCCESS_FLG, OUT_MISSING_VAR =MISSING_VAR);
   %end;
   %else %do;
       %rsk_verify_ds_col(REQUIRED_COL_LIST=&required_column., IN_DS_LIB =&in_caslib., IN_DS_NM =&use_tb_name., OUT_SUCCESS_FLG =SUCCESS_FLG, OUT_MISSING_VAR =MISSING_VAR);
   %end;

    %if &SUCCESS_FLG.=N %then %do;
     %put %pcpr_get_message(key=pcpricingutilmsg_generate_ratebook_freqsev_1, s1=&MISSING_VAR., s2=&in_caslib..&in_ds.);
    %abort;
    %end;

   %if &upper_bound_max ne %str() %then %do;
      %global &upper_bound_max;
       data ign_model_interval;
           set &in_caslib..&use_tb_name.;
            if kupcase(_level_)="INTERVAL" and binFlag=1 then do;
               upper_bound=input(_split_value_,8.);
            end;
         %if &&&interaction_exist_flg. eq Y %then %do;
            if kupcase(_level2_)="INTERVAL" and binFlag2=1 then do;
               upper_bound2=input(_split_value2_,8.);
            end;
         %end;
      run;
      /*Find out the upper_bound_max*/
      proc sql noprint;
         select
         %if &&&interaction_exist_flg. eq Y %then %do;
            max(max(upper_bound),max(upper_bound2))
         %end;
      %else %do;
         max(upper_bound)
      %end;
          into :&upper_bound_max.
         from ign_model_interval
         ;
      quit;
      %put &upper_bound_max.==&&&upper_bound_max.;
   %end;

    data ign_model_info;
        set &in_caslib..&use_tb_name.;
   run;

    proc sort data=ign_model_info out=&out_caslib..&out_ds.;
        by  &required_column.;
    run;

    %pcpr_promote_table_to_cas(input_caslib_nm =&out_caslib.,input_table_nm =&out_ds.,output_caslib_nm =&out_caslib.,output_table_nm =&out_ds.,cas_session_name=&casSessionName.);

%mend;
