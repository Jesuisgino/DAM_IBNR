/*
 Copyright (C) 2022-2025 SAS Institute Inc. Cary, NC, USA
*/

/**
   \file
   \anchor  pcpr_check_table_scope
   \brief   Utility macro to check if a table is promoted.
         Once called, a global macro variable (cas_promoted_flg) is created to indicate if the cas table is promoted (=1) or not (=0).

   \param [in] cas_session_name             Cas session reference name
   \param [in] caslib_nm                   Cas library name
   \param [in] table_nm                     Cas table name
   \param [in] promoted_flg                 name of the global macro variable for the promoted status. By default use cas_promoted_flg.



   \details Check cas promotion status

   \ingroup Macros
   \author  SAS Institute Inc.
   \date    2022
*/

%macro pcpr_check_table_scope(caslib_nm =,table_nm =, promoted_flg=cas_promoted_flg, cas_session_name= );

    *=======================================================================================;
    * To check if table is already promoted to that caslib or not.
    *=======================================================================================;
    /* promoted_flg cannot be missing. Set a default value */
    %if(%sysevalf(%superq(promoted_flg) =, boolean)) %then
       %let promoted_flg = cas_promoted_flg;

    /* Declare the output variable as global if it does not exist */
    %if(not %symexist(&promoted_flg.)) %then
       %global &promoted_flg.;

    %let &promoted_flg.=;

    proc cas;
        %if(%sysevalf(%superq(cas_session_name) ne, boolean)) %then %do;
            session &cas_session_name.;
        %end;

        table.tableInfo result = table_info/ caslib="&caslib_nm." name="&table_nm." ;
        exist_Tables = findtable(table_info);
        if exist_Tables then saveresult table_info dataout= work.table_info;
    quit;

    proc sql ;
        select
        case
            when global eq 1 then "True" /* i18nOK:Line */
            else "False" /* i18nOK:Line */
        end as tbl_sess_scope_flg
        into
            :&promoted_flg.
        from work.table_info;

    quit;

%mend pcpr_check_table_scope;
