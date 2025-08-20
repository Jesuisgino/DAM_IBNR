/*
 Copyright (C) 2022-2025 SAS Institute Inc. Cary, NC, USA
*/

/**
   \file
   \anchor  pcpr_convert_dates_to_num
   \brief   Utility macro to convert a list of date columns to numeric.
         Once called, a cas data step will convert the provided list of date variables to numeric.

   \param [in] caslib_nm                   Cas library name
   \param [in] table_nm                    Cas table name
   \param [in] date_col_list               List of date columns separated by a whitespace



   \details Convert dates to numeric

   \ingroup Macros
   \author  SAS Institute Inc.
   \date    2023
*/

%macro pcpr_convert_dates_to_num(caslib_nm=, table_nm=, date_col_list=);
   %local SUCCESS_FLG MISSING_VAR;
   %rsk_verify_ds_col(REQUIRED_COL_LIST=&date_col_list., IN_DS_LIB=&caslib_nm.,
      IN_DS_NM=&table_nm., OUT_SUCCESS_FLG=SUCCESS_FLG,
      OUT_MISSING_VAR=MISSING_VAR);
   %if &SUCCESS_FLG.=N %then
      %do;
         %PUT ERROR: VARIABLE &MISSING_VAR. is not present in &INCASLIB..&INCASTABLE. !;
         %abort;
      %end;

   %let n=%sysfunc(countw(&date_col_list));

   %do i=1 %to &n;
      %let var = %scan(&date_col_list., &i.);

      proc cas;
         datastep.runCode / code="data  &caslib_nm..&table_nm. (drop = &var rename=(&var._new=&var.));
      set &caslib_nm..&table_nm.;
      if VTYPE(&var.) = 'N' then &var._NEW=INPUT(&var.,BEST.);
      else if VTYPE(&var.) in ('C','V') then &var._NEW=INPUT(&var.,ANYDTDTE12.);
      else &var._NEW=&var.;
      run; ";
      run;
   %end;
%mend pcpr_convert_dates_to_num;
