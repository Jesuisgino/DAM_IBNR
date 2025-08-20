/*
 Copyright (C) 2022-2025 SAS Institute Inc. Cary, NC, USA
*/

/**
   \file
   \anchor  pcpr_filter_cas_table
   \brief   This utility macro is used to filter an input table with a FILTER_EXPRESSION condition.
         It includes the following steps: check if the output table already exist;
                                  if yes, check if the output table is already promoted;
                                  if yes, drop the existing table;
                                  create the new filtered output table;
                                  promote the output table;
                                  save the output table;
         For example: create tables for modeling, backtesting, and business backtesting by
            filtering the table with partition index, which is an output of pcpr_random_sampling;

   \param [in] cas_session_name         Cas session name
   \param [in] INCASLIB                Input cas library name
   \param [in] INCASTABLE               Input cas table name
   \param [in] OUTCASLIB                Output cas library name
   \param [in] OUTCASTABLE              Ouput cas table name
   \param [in] FILTER_EXPRESSION        Expression used to filter table. For example: _PINDEX_=1
   \param [in] DROP_COL_LIST            A list of columns that will be dropped after table is filtered
   \param [in] PROMOTE_RESULT_TABLE_FLG Whether result table needs to be promoted



   \details Filter an input table and promote it to the caslib
   \Note   This macro do not support the following condition: INCASLIB=OUTCASLIB and INCASTABLE=OUTCASTABLE.

   \ingroup Macros
   \author  SAS Institute Inc.
   \date    2022
*/

%macro pcpr_filter_cas_table(INCASLIB=,INCASTABLE=,OUTCASLIB=,OUTCASTABLE=,FILTER_EXPRESSION=, DROP_COL_LIST=, PROMOTE_RESULT_TABLE_FLG=Y, CAS_SESSION_NAME=&casSessionName.);
    *=======================================================================================;
    * Issue an error when trying to use the same caslib and table name for the input and output
    *=======================================================================================;
 %if (&INCASLIB. eq &OUTCASLIB.) and (&INCASTABLE. eq &OUTCASTABLE.) %then %do;

    %put ERROR: Please use a different cas library or table name for the input and output tables;

 %end;

    %if &PROMOTE_RESULT_TABLE_FLG =Y %then %do;
       %pcpr_drop_promoted_table(caslib_nm=&OUTCASLIB.,table_nm=&OUTCASTABLE.,CAS_SESSION_NAME=&CAS_SESSION_NAME.)
    %end;
    data  &OUTCASLIB..&OUTCASTABLE.;
        set &INCASLIB..&INCASTABLE.;
        %if (%sysevalf(%superq(FILTER_EXPRESSION) ne, boolean)) %then %do;
           if &FILTER_EXPRESSION. then OUTPUT;
       %end;
       %if (%sysevalf(%superq(DROP_COL_LIST) ne, boolean)) %then %do;
           drop &DROP_COL_LIST;
     %end;

run;

    %if &PROMOTE_RESULT_TABLE_FLG =Y %then %do;
      %pcpr_promote_table_to_cas(input_caslib_nm =&OUTCASLIB.,input_table_nm =&OUTCASTABLE.,output_caslib_nm =&OUTCASLIB.,output_table_nm =&OUTCASTABLE. ,drop_sess_scope_tbl_flg=Y);
      %pcpr_save_table_to_cas(in_caslib_nm=&OUTCASLIB., in_table_nm=&OUTCASTABLE., out_caslib_nm=&OUTCASLIB., out_table_nm=&OUTCASTABLE., replace_flg=true)
    %end;
%mend pcpr_filter_cas_table;
