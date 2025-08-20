/*
 Copyright (C) 2022-2025 SAS Institute Inc. Cary, NC, USA
*/

/**
   \file
   \anchor  pcpr_save_table_to_cas
   \brief   Utility macro to save table to the caslib in which table is already promoted;

   \param [in] cas_session_name             Cas session name
   \param [in] in_caslib_nm               Input Cas library name
   \param [in] In_table_nm                  Input Cas table name
   \param [in] out_caslib_nm              Output Cas library name
   \param [in] out_table_nm                 Output Cas table name
   \param [in] promoted_flg                 name of the global macro variable for the promoted status. By default use cas_promoted_flg.



   \details Save the table to caslib

   \ingroup Macros
   \author  SAS Institute Inc.
   \date    2022
*/

%macro pcpr_save_table_to_cas(in_caslib_nm=, in_table_nm=, out_caslib_nm=, out_table_nm=, cas_session_name=, replace_flg=true);
    proc cas;
       %if(%sysevalf(%superq(cas_session_name) ne, boolean)) %then %do;
            session &cas_session_name.;
        %end;

       table.save/caslib="&out_caslib_nm." name="&out_table_nm." table={caslib="&in_caslib_nm.", name="&in_table_nm."} replace=&replace_flg;
    quit;

%mend pcpr_save_table_to_cas;
