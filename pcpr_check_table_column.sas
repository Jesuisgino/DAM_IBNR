/*
Copyright (C) 2022-2025 SAS Institute Inc. Cary, NC, USA
*/

/**
\file
\anchor  pcpr_check_table_column
\brief   Macro to check if input table columns have violations. If so, throw errors.

\param [in] CAS_SESSION            Cas session name
\param [in] IN_CASLIB              Input Cas library name
\param [in] IN_CASTABLE            Input Cas table name


\details

\ingroup Macros
\author  SAS Institute Inc.
\date    2023
*/
%macro pcpr_check_table_column(IN_CASLIB=,IN_CASTABLE=,CAS_SESSION=);

proc cas;
   table.columnInfo result = ci status=rc/
   table={caslib="&IN_CASLIB.",name="&IN_CASTABLE."};
   tableci=findtable(ci);
   saveresult tableci replace caslib="&IN_CASLIB." casout="column_info";
   run;
quit;

data &IN_CASLIB..column_result;
   set &IN_CASLIB..column_info;
   v7=nvalid(Column, 'v7');
   if v7=0  then output;
run;

/* In case of any column violations, throw errors*/
%if %rsk_attrn(&IN_CASLIB..column_result, NLOBS) ^= 0 %then %do;
   proc sql;
      select
     Column into :Invalid_column_list separated by ','
      from &IN_CASLIB..column_result;
   quit;

   %put ERROR: Table &IN_CASLIB..&IN_CASTABLE contain invalid columns: &Invalid_column_list.. Please correct the column names;
   %abort;

%end;

%mend;
