/*
Copyright (C) 2022-2025 SAS Institute Inc. Cary, NC, USA
*/

/**
\file
\anchor  pcpr_drop_columns
\brief  Removing columns inserted into a list

\param [in] cas_session_name       Cas session name
\param [in] INCASLIB               Input Cas library name
\param [in] INCASTABLE             Input Cas table name
\param [in] OUTCASLIB              Output Cas library name
\param [in] OUTCASTABLE            Output Cas table name
\param [in] DROP_LIST              List of columns to remove

\details the list should be composed as follows: string containing the variables to be removed separated by a space
\ingroup Macros
\author  SAS Institute Inc.
\date    2023
*/

%macro pcpr_drop_columns(INCASLIB=,INCASTABLE=,OUTCASLIB=,OUTCASTABLE=,DROP_LIST=,CAS_SESSION_NAME=&casSessionName.);

    %local DROP_LIST_NEW i required_col_list_item;

    %let i = 1;
    %do %while(%scan(&DROP_LIST,&i) ne );
       %let required_col_list_item=%scan(&DROP_LIST,&i);
       %if %rsk_varexist(&INCASLIB..&INCASTABLE.,&required_col_list_item.) NE 0 %then %let DROP_LIST_NEW = &DROP_LIST_NEW &required_col_list_item.;
       %else %PUT WARNING: VARIABLE &required_col_list_item. is not present in &INCASLIB..&INCASTABLE..;
       %let i=%eval(&i+1);
    %end;

    %if &DROP_LIST_NEW ne %then %do;
        proc cas;
            datastep.runCode /
            code =      "DATA &OUTCASLIB..&OUTCASTABLE. (DROP = &DROP_LIST_NEW);
            SET &INCASLIB..&INCASTABLE.;
            RUN;";
            run;
        quit;
    %end;
    %else %if &INCASLIB ne &OUTCASLIB or &INCASTABLE ne &OUTCASTABLE %then %do;
        proc cas;
            datastep.runCode /
            code =      "DATA &OUTCASLIB..&OUTCASTABLE.;
            SET &INCASLIB..&INCASTABLE.;
            RUN;";
            run;
        quit;


    %end;

%mend pcpr_drop_columns;
