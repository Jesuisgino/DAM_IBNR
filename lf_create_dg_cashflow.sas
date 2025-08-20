/*
Copyright (C) 2022-2025 SAS Institute Inc. Cary, NC, USA
*/

/**
\file
\anchor  lf_create_dg_cashflow
\brief   Macro to create a data grid for insurance_cashflow table

\param [in] casDataLib              Input Cas library name
\param [in] in_cashflow_data        Input insurance_cashflow table name
\param [in] OutputTables_cf         Output table with cashflow data grid
\param [in] cashflow_type           Cashflow type BES or RSV
\param [in] cashflow_key_list       space separated variable list that will be used to join with portfolio table


\details

\ingroup Macros
\author  SAS Institute Inc.
\date    2025
*/

%macro lf_create_dg_cashflow(casDataLib=,in_cashflow_data=,OutputTables_cf=,cashflow_type=,cashflow_key_list=,casSession=&casSessionName.);

   %pcpr_drop_promoted_table(caslib_nm=&casDataLib., table_nm=cashflow_dg_&cashflow_type., CAS_SESSION_NAME=&casSession.);
   %pcpr_drop_promoted_table(caslib_nm=&casDataLib., table_nm=&OutputTables_cf., CAS_SESSION_NAME=&casSession.);

   %if &cashflow_key_list ne %str() %then %do;
      %let quote_cf_key_list=%rsk_quote_list(list=&cashflow_key_list.);
   %end;

   data casuser._tmp_cashflow ;
       set &casDataLib..&in_cashflow_data.;
        /*NET_PREMIUM is singular and will not be included in cashflow data grid*/
           where upcase(CASHFLOW_LEG_NM) ne "NET_PREMIUM"
      /*cashflow_type should match CASHFLOW_TYPE_CD: BES or RSV*/
         %if &cashflow_type ne %str() %then %do;
            and upcase(CASHFLOW_TYPE_CD) eq "%upcase(&cashflow_type.)"
         %end;
      ;
         %if &cashflow_type ne %str() %then %do;
            drop CASHFLOW_TYPE_CD;
         %end;
   run;

   /*cashflow table is required when macro is called, terminate if not provided*/
   %if %rsk_attrn(casuser._tmp_cashflow,nlobs) = 0 %then %do;
      %put %pcpr_get_message(key=pcpricingutilmsg_common_ds_empty, s1=casuser._tmp_cashflow);
      %rsk_terminate;
   %end;

   /*Create json strings of data grid based on cashflow table*/
   %dcm_serializeGrid(
         gridSourceTable=casuser._tmp_cashflow,
         gridColName=%upcase(&cashflow_type.)_,
         outputTable=&casDataLib..cashflow_dg_&cashflow_type.,
         classvars=&cashflow_key_list. CASHFLOW_LEG_NM);

   /*Transpose data grid for each cashflow id (type and leg name) as columns*/
    proc cas;
         simple.groupByInfo result=res /
         noVars=true,
         generatedColumns={"F"},
         inputs={"CASHFLOW_LEG_NM"},
         casOut={caslib="&casDataLib.",name="orderByTBL",replace=true},
         table="cashflow_dg_&cashflow_type.";
      run;

        dataShaping.longToWide result=res /
        table={caslib="&casDataLib.",
               name="cashflow_dg_&cashflow_type.",
               groupBy={&quote_cf_key_list.},
               groupByMode="REDISTRIBUTE",
               orderBy={"CASHFLOW_LEG_NM"}},
               inputs={"%upcase(&cashflow_type.)_"},
               orderByTable="orderbyTBL",
               maxPosition=4,
               casout={caslib="&casDataLib",name="cashflow_datagrid", replace=True};
    run;
    quit;

     /*clean up the config table with curve data grid*/
     proc cas;
        datastep.runcode /
           code = "data &casDataLib..&outputtables_cf(drop=_FREQUENCY_);
                        set &casDataLib..cashflow_datagrid;
                run;";
     run;
     quit;

%mend;
