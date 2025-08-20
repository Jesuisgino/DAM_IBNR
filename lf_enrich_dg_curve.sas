/*
Copyright (C) 2022-2025 SAS Institute Inc. Cary, NC, USA
*/

/**
\file
\anchor  lf_enrich_dg_curve
\brief   Macro to create a data grid for pricing curves and enrich the config table by merging with the created curves data grid
         Examples of pricing curves includes: DISC_CURVE_ID LAPSE_CURVE_ID COMMISSION_CURVE_ID SURRENDER_CHARGE_CURVE_ID

\param [in] casDataLib              Input Cas library name
\param [in] in_pricing_curve        Input pricing curve table name
\param [in] in_pricing_config       Input pricing config table name
\param [in] OutputTables_curve      Output table with pricing curve data grid
\param [in] output_config           Output configuration table with merged pricing curves data grid


\details

\ingroup Macros
\author  SAS Institute Inc.
\date    2024
*/

%macro lf_enrich_dg_curve(casDataLib=,in_pricing_curve=,in_pricing_config=,OutputTables_curve=,output_config=);

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

      %pcpr_check_var_list(incaslib=&casDataLib., incastable=&in_pricing_config., var_list=&pricing_curve_var_list., new_var_list=new_curve_var_list)
      %let quote_new_curve_var_list=%rsk_quote_list(list=&new_curve_var_list.);

      %if &new_curve_var_list. ne %str() %then %do;
      /*Create json strings of data grid for other curve table*/
         %dcm_serializeGrid(
               gridSourceTable=&casDataLib..&in_pricing_curve.,
               gridColName=DG_,
               outputTable=&casdatalib..&OutputTables_curve.,
               classvars=CURVE_ID CONFIG_VAR_NM);

         proc cas;
             datastep.runcode /
             code = "data &casDataLib.._tmp_pricing_config_curve;
                     set &casDataLib..&in_pricing_config.;
                     keep &config_key_list. &new_curve_var_list.;
             run;";
         run;
         quit;
         /*transpose curve table wide to long*/
         %let quote_config_key_list=%rsk_quote_list(list=&config_key_list.);
         proc cas;
            dataShaping.wideToLong result=res /
               table={caslib="&casDataLib.",name="_tmp_pricing_config_curve"},
               id={&quote_config_key_list.},
              variableName="CONFIG_VAR_NM",
              valueName="CURVE_ID",
               casout={caslib="&casDataLib.", name="_tmp_config_curve_trans", replace=true};
         run;
         quit;
         /*get curve data grid*/
         /*For missing values, the data grid won't be merged*/
         %pcpr_join_tbl_cas( caslib=&casDataLib.
                       ,base_tbl=_tmp_config_curve_trans
                       ,join_direction=inner
                       ,tbl_to_join=&OutputTables_curve.
                       ,join_key=%bquote(CONFIG_VAR_NM,CURVE_ID)
                       ,output_tbl=config_curve_dg
                       );

         %if %rsk_attrn(&casDataLib..config_curve_dg,nlobs) gt 0 %then %do;
            /*clean up the config table with curve data grid*/
            proc cas;
                datastep.runcode /
                code = "data &casDataLib..config_curve_dg_1(drop=_C0_ CURVE_ID CONFIG_VAR_NM);
                        set &casDataLib..config_curve_dg;
                       format DATA_GRID_NM $36.;
                         DATA_GRID_NM=TRANWRD(CONFIG_VAR_NM, '_CURVE_ID', '');
                run;";
            run;
            quit;

            /*Transpose back to get ready to merge back*/

            proc cas;
                 simple.groupByInfo result=res /
                  noVars=true,
                  generatedColumns={"F"},
                  inputs={"DATA_GRID_NM"},
                  casOut={caslib="&casDataLib.",name="orderByTBL",replace=true},
                  table="config_curve_dg_1";
            run;

               dataShaping.longToWide result=res /
                  table={caslib="&casDataLib.",
                      name="config_curve_dg_1",
                         groupBy={&quote_config_key_list.},
                         groupByMode="REDISTRIBUTE",
                         orderBy={"DATA_GRID_NM"}},
                  inputs={"DG_"},
                 orderByTable="orderbyTBL",
                  maxPosition=4,
                  casout={caslib="&casDataLib",name="curve_data_grid", replace=True};
            run;
            quit;
            proc casutil;
               ALTERTABLE CASDATA="curve_data_grid" INCASLIB="&casDataLib." drop={"_FREQUENCY_"}
               ;
            run;
            quit;

            /*Join data grid with pricing_config table*/
            %pcpr_join_tbl_cas( caslib=&casDataLib.
                          ,base_tbl=&in_pricing_config.
                          ,join_direction=left
                          ,tbl_to_join=curve_data_grid
                          ,join_key=%bquote(&comma_config_key_list.)
                          ,output_tbl=&output_config.
                          );
            proc casutil;
               ALTERTABLE CASDATA="&output_config." INCASLIB="&casDataLib." drop={&quote_new_curve_var_list.}
               ;
            run;
            quit;
         %end;
         %else %do;
            proc cas;
                datastep.runcode /
                code = "data &casDataLib..&output_config.(drop=&new_curve_var_list.);
                        set &casDataLib..&in_pricing_config.;
                      run;";
            run;
            quit;
         %end;
      %end;
      %else %do;
            proc cas;
                datastep.runcode /
                code = "data &casDataLib..&output_config.(drop=&new_curve_var_list.);
                        set &casDataLib..&in_pricing_config.;
                      run;";
            run;
            quit;
      %end;
   %end;
   %else %do;
      proc cas;
          datastep.runcode /
          code = "data &casDataLib..&output_config.;
                  set &casDataLib..&in_pricing_config.;
                run;";
      run;
      quit;
   %end;
%end;
%else %do;
      proc cas;
          datastep.runcode /
          code = "data &casDataLib..&output_config.;
                  set &casDataLib..&in_pricing_config.;
                run;";
      run;
      quit;
%end;
%mend;
