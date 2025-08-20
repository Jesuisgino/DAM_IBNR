/*
Copyright (C) 2022-2025 SAS Institute Inc. Cary, NC, USA
*/

/**
\file
\anchor  pcpr_map_variables
\brief  Macro that map columns to standardized names

\param [in] cas_session_nm     Cas Session name
\param [in] caslib_nm          Cas library name
\param [in] input_table_nm     Input table name
\param [in] map_policy_id      Column to map to POLICY_ID
\param [in] map_Policy_uw_year_no   Column to map to POLICY_UW_YEAR_NO
\param [in] map_policy_exposure   Column to map to POLICY_EXPOSURE_AMT
\param [in] map_claims_cnt     Column to map to CLAIMS_CNT
\param [in] map_claims_amt     Column to map to CLAIMS_AMT
\param [in] map_coverage_cd    Column to map to COVERAGE_CD
\param [in] map_cust_age_amt   Column to map to CUST_AGE_AMT
\param [in] out_table_nm       Output table name

\details  Map columns to standardized names: POLICY_ID POLICY_UW_YEAR_NO POLICY_EXPOSURE_AMT CLAIMS_CNT CLAIMS_AMT COVERAGE_CD CUST_AGE_AMT
\ingroup Macros
\author  SAS Institute Inc.
\date    2023
*/

%macro pcpr_map_variables(cas_session_nm =
                        ,caslib_nm =
                        ,input_table_nm =
                        ,map_policy_id =
                        ,map_Policy_uw_year_no =
                        ,map_policy_exposure =
                        ,map_claims_cnt =
                        ,map_claims_amt =
                        ,map_coverage_cd =
                        ,map_cust_age_amt=
                        ,out_table_nm =);

/*Checks*/
/*1.1 check if the out_table_nm is not the same as the input_table_nm, otherwise output error message*/
%if &input_table_nm. eq &out_table_nm. %then %do;
   %put ERROR: Input table and output table have the same name. Please use a different cas table name for the input and output tables;
    %abort;
%end;
/*1.2 check if the output table already exist and is promoted, if so, delete it. Otherwise it may cause error in promotion*/
%pcpr_drop_promoted_table(caslib_nm=&caslib_nm.,table_nm=&out_table_nm.,CAS_SESSION_NAME=&cas_session_nm.);

%local rename_statement length_statement;
%let rename_statement=;
%let length_statement=;
%if "&map_policy_id" ne "" %then %do;
   %let rename_statement= rename=(%nrbquote('&map_policy_id.'n )= 'POLICY_ID'n) ;
%end;
%if "&map_Policy_uw_year_no" ne ""  %then %do;
   %let rename_statement=&rename_statement. rename=(%nrbquote('&map_Policy_uw_year_no.'n )= 'POLICY_UW_YEAR_NO'n) ;
%end;
%if "&map_policy_exposure" ne ""  %then %do;
   %let rename_statement=&rename_statement. rename=(%nrbquote('&map_policy_exposure.'n )= 'POLICY_EXPOSURE_AMT'n);
%end;
%if "&map_claims_cnt" ne ""  %then %do;
   %let rename_statement=&rename_statement. rename=(%nrbquote('&map_claims_cnt.'n )= 'CLAIMS_CNT'n);
%end;
%if "&map_claims_amt" ne ""  %then %do;
   %let rename_statement=&rename_statement. rename=(%nrbquote('&map_claims_amt.'n )= 'CLAIMS_AMT'n);
%end;
%if "&map_coverage_cd" ne ""  %then %do;
   %let rename_statement=&rename_statement. rename=(%nrbquote('&map_coverage_cd.'n )= 'COVERAGE_CD'n);
%end;
%if "&map_cust_age_amt" ne ""  %then %do;
   %let rename_statement=&rename_statement. rename=(%nrbquote('&map_cust_age_amt.'n )= 'CUST_AGE_AMT'n);
%end;

%if "&rename_statement" eq "" %then %do;
   /* No need to rename the column names*/
   proc cas;
      dataStep.runCode /
      code=" data &out_table_nm. (caslib=&caslib_nm.);
                set &input_table_nm. (caslib=&caslib_nm.);

      run;" ;
   run;
%end;
%else %do;
   /* replace the column names*/
   proc cas;
      dataStep.runCode /
      code=" data &out_table_nm. (caslib=&caslib_nm. promote=no);
      set &input_table_nm. (caslib=&caslib_nm. &rename_statement.);
      run;" ;
   run;
   quit;
%end;

%pcpr_promote_table_to_cas(input_caslib_nm =&caslib_nm,input_table_nm =&out_table_nm,output_caslib_nm =&caslib_nm,output_table_nm =&out_table_nm);
%pcpr_save_table_to_cas(in_caslib_nm=&caslib_nm., in_table_nm=&out_table_nm.,out_caslib_nm=&caslib_nm., out_table_nm=&out_table_nm., cas_session_name=&cas_session_nm.);

%mend pcpr_map_variables;
