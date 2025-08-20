/*
 Copyright (C) 2022-2025 SAS Institute Inc. Cary, NC, USA
*/

/*
   \file
   \anchor pcpr_segment_data
   \brief   Segment data by COVERAGE_CD

   \param [in] INCASLIB                 Input cas library name
   \param [in] INCASTABLE               Input cas table name
   \param [in] OUTCASLIB                Output cas library name
   \param [in] OUTCASTABLE              Ouput cas table name
   \param [in] OPERATORTYPE             Operator type
   \param [in] VARLIST                  Target filter value list when operator type is in or not in
   \param [in] FILTERVALUE              Target filter value when operator type is eq or ne
   \param [in] CAS_SESSION_NAME         Cas session name


   \details Segment an input table by COVERAGE_CD and promote it to the caslib.

   \ingroup Macros
   \author  SAS Institute Inc.
   \date    2023
*/

%macro pcpr_segment_data(INCASLIB=
                        ,INCASTABLE=
                        ,OUTCASLIB=
                        ,OUTCASTABLE=
                        ,OPERATORTYPE=
                        ,VARLIST=
                        ,FILTERVALUE=
                        ,CAS_SESSION_NAME=);


%let filter_expression=;
%if "&OPERATORTYPE." eq "NULL" %then %do;
   %let filter_expression= missing(COVERAGE_CD);
%end;
%else %if "&OPERATORTYPE." eq "NOT_NULL" %then %do;
   %let  filter_expression=^missing(COVERAGE_CD);
%end;
%else %if "&OPERATORTYPE." eq "IN" or "&OPERATORTYPE." eq "NOT_IN" %then %do;
    %let filter_expression= COVERAGE_CD %sysfunc(tranwrd(&OPERATORTYPE., %str(_), %str( )))  &VARLIST.;
%end;
%else %if "&OPERATORTYPE." eq "EQ" or "&OPERATORTYPE." eq "NE" %then %do;
    %let filter_expression= COVERAGE_CD &OPERATORTYPE.  %rsk_quote_list(list=%str(&FILTERVALUE.));
%end;

%pcpr_filter_cas_table(INCASLIB=&INCASLIB.
                      ,INCASTABLE=&INCASTABLE.
                      ,OUTCASLIB=&OUTCASLIB.
                      ,OUTCASTABLE=&OUTCASTABLE.
                      ,FILTER_EXPRESSION=&filter_expression.
                      ,CAS_SESSION_NAME=&CAS_SESSION_NAME.);

%mend;
