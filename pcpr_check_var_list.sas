/*
Copyright (C) 2022-2025 SAS Institute Inc. Cary, NC, USA
*/

/**
\file
\anchor  pcpr_check_var_list
\brief   Macro to check a list of variables existence in the input table. Remove the variables from the list if not exist in the table and assign the new list to a macro variable.

\param [in] var_list              Original space seperated list of variables
\param [in] new_var_list          Modified space seperated list of variables which exist in the table
\param [in] incaslib              Input Cas library name
\param [in] incastable            Input Cas table name


\details

\ingroup Macros
\author  SAS Institute Inc.
\date    2024
*/

%macro pcpr_check_var_list(incaslib=, incastable=, var_list=, new_var_list=);

   %global &new_var_list.;
   %let &new_var_list=;
   %let n_var_list=%rsk_wordcount(&var_list.);
   %do i=1 %to &n_var_list;
      %let temp_var=%scan(&var_list., &i, " ");
     %let var_exist_flg=;
     %let missing_var_list=;
      %rsk_verify_ds_col(REQUIRED_COL_LIST    = &temp_var.,
                         IN_DS_LIB            =&incaslib.,
                         IN_DS_NM             =&incastable.,
                         OUT_SUCCESS_FLG      =var_exist_flg,
                         OUT_MISSING_VAR      =missing_var_list);
      %if &var_exist_flg. = Y %then %do;
         %let &new_var_list=&&&new_var_list. &temp_var.;
     %end;
     %else %do;
         %let &new_var_list=&&&new_var_list.;
    %end;
   %end;
   %put %pcpr_get_message(key=pcpricingutilmsg_profile_data_1, s1= &&&new_var_list.);
%mend;
