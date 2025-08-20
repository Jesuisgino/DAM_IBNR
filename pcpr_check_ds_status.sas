/*
Copyright (C) 2022-2025 SAS Institute Inc. Cary, NC, USA
*/

/**
\file
\anchor  pcpr_check_ds_status
\brief   Macro to check input tables existence and required columns if any

\param [in] required_col_list   Space seperated list of column names
\param [in] caslib              Input Cas library name
\param [in] castable            Input Cas table name


\details

\ingroup Macros
\author  SAS Institute Inc.
\date    2024
*/


%macro pcpr_check_ds_status(caslib=,castable=,required_col_list=);

    %rsk_dsexist_cas(cas_lib = %superq(caslib)
                        ,cas_table = %superq(castable)
                        );

    %if not &cas_table_exists. %then %do;
            %put %pcpr_get_message(key=pcpricingutilmsg_common_ds_not_exist, s1=&caslib..&castable.);
            %rsk_terminate;
    %end;
    %else %if %rsk_attrn(&caslib..&castable.,nlobs) = 0 %then %do;
           %put %pcpr_get_message(key=pcpricingutilmsg_common_ds_empty, s1=&caslib..&castable.);
         %rsk_terminate;
    %end;
   %else %if &required_col_list ne %str() %then %do;;
         %let i = 1;
         %do %while(%scan(&required_col_list,&i) ne );
            %let required_col_list_item=%scan(&required_col_list,&i);
            %if %rsk_varexist(&caslib..&castable.,&required_col_list_item.) eq 0 %then %do;
              %put  %pcpr_get_message(key=pcpricingutilmsg_common_col_not_exist, s1=&caslib..&castable.,s2=&required_col_list_item.);
              %rsk_terminate;
            %end;
            %let i=%eval(&i+1);
         %end;
    %end;
%mend;
