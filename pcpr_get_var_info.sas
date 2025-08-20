/*
Copyright (C) 2022-2025 SAS Institute Inc. Cary, NC, USA
*/

/**
\file
\anchor  pcpr_get_var_info
\brief   Macro for extracting information from input table columns (metadata)

\param [in] cas_session_name      Cas session name
\param [in] INCASLIB              Input Cas library name
\param [in] INCASTABLE            Input Cas table name
\param [in] OUTCASLIB             Output Cas library name
\param [in] OUTCASTABLE           Output Cas table name


\details Metadata saved in the output table: Column,Label,ID,Type,RawLength,FormattedLength,Format,NFL,NFD

\ingroup Macros
\author  SAS Institute Inc.
\date    2023
*/

%macro pcpr_get_var_info(INCASLIB=,INCASTABLE=,OUTCASLIB=,OUTCASTABLE=,CAS_SESSION_NAME=&casSessionName.);

%pcpr_drop_promoted_table(caslib_nm=&OUTCASLIB.,table_nm=&OUTCASTABLE.,CAS_SESSION_NAME=&casSessionName.);

proc cas;
table.columnInfo result = ci status=rc/
table={caslib="&INCASLIB.",name="&INCASTABLE."};
tableci=findtable(ci);
saveresult tableci replace caslib="&OUTCASLIB." casout="&OUTCASTABLE.";
run;
quit;
%pcpr_promote_table_to_cas(input_caslib_nm =&OUTCASLIB.,input_table_nm =&OUTCASTABLE.,output_caslib_nm =&OUTCASLIB.,output_table_nm =&OUTCASTABLE. ,drop_sess_scope_tbl_flg=N);
%pcpr_save_table_to_cas(in_caslib_nm=&OUTCASLIB., in_table_nm=&OUTCASTABLE., out_caslib_nm=&OUTCASLIB., out_table_nm=&OUTCASTABLE., cas_session_name=&casSessionName., replace_flg=true);

%mend pcpr_get_var_info;
