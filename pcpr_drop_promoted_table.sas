/*
Copyright (C) 2022-2025 SAS Institute Inc. Cary, NC, USA
*/

/**
\file
\anchor  pcpr_drop_promoted_table
\brief   Utility macro to avoid errors when promoting a table using the same name and in the same caslib of the table you want to promote;

\param [in] cas_session_name         Cas session name
\param [in] caslib_nm                Cas library name
\param [in] table_nm                 Cas table name


\details I check table existence, if it exists and is already promoted I remove it to avoid errors;
\details Use logic: 1)%pcpr_drop_promoted_table; 2)create table; 3)Promote the table in the same caslib as the table you want to promote;
\ingroup Macros
\author  SAS Institute Inc.
\date    2023
*/

%macro pcpr_drop_promoted_table(caslib_nm=,table_nm=,CAS_SESSION_NAME=&casSessionName.);

%rsk_dsexist_cas(cas_lib=&caslib_nm., cas_table=&table_nm.);
/*need to check promotion status before creating this table*/
%if &cas_table_exists. %then %do;
%let promoted_status_flg=;
%pcpr_check_table_scope(caslib_nm =&caslib_nm.,table_nm =&table_nm., promoted_flg=promoted_status_flg );
%if &promoted_status_flg = True %then %do;
%core_cas_drop_table(cas_session_name =&CAS_SESSION_NAME., cas_libref =&caslib_nm., cas_table =&table_nm.);
%end;
%end;
%mend pcpr_drop_promoted_table;
