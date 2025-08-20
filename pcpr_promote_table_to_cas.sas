/*
 Copyright (C) 2022-2025 SAS Institute Inc. Cary, NC, USA
*/

/**
   \file
   \anchor  pcpr_promote_table_to_cas
   \brief   This utility macro promotes(to make it available to other sessions) table which is already present in caslib.
            Promote action deletes the session scope table from input cas lib.
            If user want to keep the session scope table then set drop_sess_scope_tbl_flg=False

   \param [in] cas_session_name             Cas session name
   \param [in] input_caslib_nm              Name of input cas library from where table has to promote
   \param [in] input_table_nm               Name of table which has to promote from
   \param [in] output_caslib_nm             Name of output cas library where table has to promote to
   \param [in] output_table_nm              Name of table which has to promote to
   \param [in] drop_sess_scope_tbl_flg      Flag to indicate if session scope table is to be delete or not after table is promoted.(Y/N)



   \details Promote table to cas
   \note    If promote same table names in the same cas library, please make sure to drop the promoted table before creating the &input_caslib_nm..&input_table_nm
         Otherwise with different caslib or table names, the promoted table will be automatically dropped before a new version gets promoted.

   \ingroup Macros
   \author  SAS Institute Inc.
   \date    2022
*/

%macro pcpr_promote_table_to_cas(input_caslib_nm =,input_table_nm =,output_caslib_nm =,output_table_nm = ,cas_session_name=, drop_sess_scope_tbl_flg=Y);

    %let m_input_caslib_nm = &input_caslib_nm.;
    %let m_input_tbl_nm = &input_table_nm.;
    %let m_output_caslib_nm = &output_caslib_nm.;
    %let m_output_tbl_nm = &output_table_nm.;
    %let m_drop_sess_scope_tbl_flg = &drop_sess_scope_tbl_flg.;

    *=============================================================================;
    * If output caslib is blank then input caslib will be treated as output caslib;
    *=============================================================================;

    %if &m_output_caslib_nm. eq %then %do;
        %let m_output_caslib_nm = &m_input_caslib_nm.;
    %end;

    *====================================================================;
    * If output table is blank then table will be promoted with same name;
    *====================================================================;

    %if &m_output_tbl_nm. eq %then %do;
        %let m_output_tbl_nm = &m_input_tbl_nm.;
    %end;

    *====================================================================;
    *Converting User Input flag Y/N to True/False;
    *====================================================================;

    %if &drop_sess_scope_tbl_flg eq Y %then %do;
        %let m_drop_sess_scope_tbl_flg = TRUE;
    %end;
    %else %do;
        %let m_drop_sess_scope_tbl_flg = FALSE;
    %end;

    *======================================================;
    * If table is promoted to same library with same name,
    * then call %pcpr_check_table_scope and %core_cas_drop_table before data creation and second time promotion
    *=====================================================;

    %if (&m_input_caslib_nm. eq &m_output_caslib_nm.) and (&m_input_tbl_nm. eq &m_output_tbl_nm.) %then %do;

        *=======================================================================================;
        * Issue an warning when trying to promote the same caslib and table name
        *=======================================================================================;
        %put NOTE: Please check and drop the promoted table &m_output_caslib_nm..&m_output_tbl_nm. before creating and promoting a new version;

    %end;

    %else %do;
        *=======================================================================================;
        * To drop output table from caslib in which table is to be promoted if it already exists;
        *=======================================================================================;
        %core_cas_drop_table(cas_session_name =&cas_session_name., cas_libref =&m_output_caslib_nm., cas_table =&m_output_tbl_nm.);
     %end;
    *=============================;
    * CAS Action- to promote table;
    *=============================;

    proc cas;
       %if(%sysevalf(%superq(cas_session_name) ne, boolean)) %then %do;
            session &cas_session_name.;
        %end;

        table.promote  /
        caslib = "&m_input_caslib_nm.",
        name="&m_input_tbl_nm",
        target="&m_output_tbl_nm",
        targetLib = "&m_output_caslib_nm.",
        drop=&m_drop_sess_scope_tbl_flg.
    ;
    quit;

%mend pcpr_promote_table_to_cas;
