/*
Copyright (C) 2022-2025 SAS Institute Inc. Cary, NC, USA
*/

/**
\file
\anchor  lf_create_dg_mortality
\brief   Macro to create a data grid for mortality table

\param [in] casDataLib              Input Cas library name
\param [in] in_mortality_data       Input mortality table name
\param [in] OutputTables_mort       Output table with mortality data grid
\param [in] where_clause            Where clause to filter the mortality table
\param [in] use_duration            Y/N Whether duration column will be used in the data grid. If N, then DURATION column will be dropped before creating data grid


\details

\ingroup Macros
\author  SAS Institute Inc.
\date    2024
*/

%macro lf_create_dg_mortality(casDataLib=,in_mortality_data=,OutputTables_mort=,where_clause=, use_duration=N,casSession=&casSessionName.);

   %pcpr_drop_promoted_table(caslib_nm=&casDataLib., table_nm=&OutputTables_mort., CAS_SESSION_NAME=&casSession.);

   data casuser._tmp_mortality
   %if &use_duration ne Y %then %do;
       (drop=DURATION)
   %end;
   ;
       set &casDataLib..&in_mortality_data.;
      %if &where_clause ne %str() %then %do;
           where &where_clause.;
      %end;
   run;

   /*Mortality table is required, terminate if not provided*/
   %if %rsk_attrn(casuser._tmp_mortality,nlobs) = 0 %then %do;
      %put %pcpr_get_message(key=pcpricingutilmsg_common_ds_empty, s1=casuser._tmp_mortality);
      %rsk_terminate;
   %end;
   /*transpose mortality table wide to long and prepare for data grid creation*/
   %if &use_duration ne Y %then %do;
      proc cas;
         dataShaping.wideToLong result=res /
            table={caslib='casuser',name="_tmp_mortality"},
            id={"MORTALITY_TBL_ID", "ISSUE_AGE"},
         variableName="GENDER_UW_CLASS",
         valueName="RATE",
            casout={caslib="casuser", name="_tmp_mortality_trans", replace=true};
      run;
      quit;
	%end;
	%else %do;
   	  proc cas;
         dataShaping.wideToLong result=res /
            table={caslib='casuser',name="_tmp_mortality"},
            id={"MORTALITY_TBL_ID", "ISSUE_AGE","DURATION"},
         variableName="GENDER_UW_CLASS",
         valueName="RATE",
            casout={caslib="casuser", name="_tmp_mortality_trans", replace=true};
      run;
      quit;

%end;
   /*Drop redundant colum _C0_*/
   proc casutil;
      ALTERTABLE CASDATA="_tmp_mortality_trans" INCASLIB="casuser" drop={"_C0_"}
      ;
   run;
   quit;

   /*Create json strings of data grid based on mortality table*/
   %dcm_serializeGrid(
         gridSourceTable=casuser._tmp_mortality_trans,
         gridColName=DG_MORTALITY,
         outputTable=&casDataLib..&OutputTables_mort.,
         classvars=MORTALITY_TBL_ID GENDER_UW_CLASS);

%mend;
