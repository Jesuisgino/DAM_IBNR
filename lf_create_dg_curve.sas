/*
Copyright (C) 2022-2025 SAS Institute Inc. Cary, NC, USA
*/

/**
\file
\anchor  lf_create_dg_curve
\brief   Macro to create a data grid for pricing curves other than disc_curve without enriching configuration table
         Examples of pricing curves includes: LAPSE_CURVE_ID COMMISSION_CURVE_ID SURRENDER_CHARGE_CURVE_ID

\param [in] casDataLib              Input Cas library name
\param [in] in_pricing_curve        Input pricing curve table name
\param [in] OutputTables_curve      Output table with pricing curve data grid


\details

\ingroup Macros
\author  SAS Institute Inc.
\date    2024
*/

%macro lf_create_dg_curve(casDataLib=,in_pricing_curve=,OutputTables_curve=,casSessionName=);

/*First check existence of the data*/
%rsk_dsexist_cas(cas_lib = &casDataLib.,cas_table =&in_pricing_curve.,cas_session_name =&casSessionName.,out_var=cas_table_exists);
%if &cas_table_exists %then %do;

   %if %rsk_attrn(&casDataLib..&in_pricing_curve.,nlobs) gt 0 %then %do;
   %pcpr_drop_promoted_table(caslib_nm=&casDataLib., table_nm=_tmp_curve_data_grid, CAS_SESSION_NAME=&casSessionName.);
   %pcpr_drop_promoted_table(caslib_nm=&casDataLib., table_nm=&OutputTables_curve., CAS_SESSION_NAME=&casSessionName.);

      /*Get the list of config column names and check if they exist in pricing config*/
      proc sql noprint;
         select distinct(CONFIG_VAR_NM) into :pricing_curve_var_list separated by ' '
         from &casDataLib..&in_pricing_curve.
         ;
      quit;
      %put &pricing_curve_var_list;

      %if &pricing_curve_var_list. ne %str() %then %do;
      /*Create json strings of data grid for other curve table*/
         %dcm_serializeGrid(
               gridSourceTable=&casDataLib..&in_pricing_curve.,
               gridColName=datagrid,
               outputTable=&casdatalib.._tmp_curve_data_grid,
               classvars=CURVE_ID CONFIG_VAR_NM);

       data curve_dg_1(drop=CONFIG_VAR_NM);
              set &casDataLib.._tmp_curve_data_grid;
              format DATA_GRID_NM $36.;
              DATA_GRID_NM=TRANWRD(CONFIG_VAR_NM, '_CURVE_ID', '');
         run;

      proc sort data=curve_dg_1;
      by CURVE_ID DATA_GRID_NM;
      run;

      proc transpose data=curve_dg_1 out=curve_dg_trans(drop=_NAME_) prefix=DG_;
      by CURVE_ID;
      var datagrid;
      id DATA_GRID_NM;
      run;

      data &casDatalib.._&OutputTables_curve.(replace=YES);
         set work.curve_dg_trans;
      run;

      %pcpr_promote_table_to_cas(input_caslib_nm =&casDataLib.,input_table_nm =_&OutputTables_curve.,output_caslib_nm =&casDataLib.,output_table_nm =&OutputTables_curve. ,cas_session_name=&casSessionName.,drop_sess_scope_tbl_flg=N);
      %pcpr_save_table_to_cas(in_caslib_nm=&casDataLib., in_table_nm=_&OutputTables_curve., out_caslib_nm=&casDataLib., out_table_nm=&OutputTables_curve., cas_session_name=&casSessionName., replace_flg=true);


     %end;

   %end;
%end;

%mend;
