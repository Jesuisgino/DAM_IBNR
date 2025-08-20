/*
Copyright (C) 2022-2025 SAS Institute Inc. Cary, NC, USA
*/

/**
\file
\anchor  lf_create_dg_disc
\brief   Macro to create a data grid for discount curve

\param [in] casDataLib              Input Cas library name
\param [in] in_pricing_curve        Input pricing curve table name
\param [in] out_pricing_curve       The pricing curve table after removing the DISC_CURVE_ID curves
\param [in] OutputTables_disc       Output table with discount curve data grid


\details This macro is only used when DISC_CURVE_ID is required for the configuration. And the DISC_CURVE_ID will be removed from the input pricing curve table.

\ingroup Macros
\author  SAS Institute Inc.
\date    2024
*/

%macro lf_create_dg_disc(casDataLib=,in_pricing_curve=,out_pricing_curve=,OutputTables_disc=,casSession=&casSessionName.);

   /*Drop data grid tables if they already exist*/
   %pcpr_drop_promoted_table(caslib_nm=&casDataLib., table_nm=&OutputTables_disc., CAS_SESSION_NAME=&casSession.);
   proc cas;
       datastep.runcode /
       code = "data &casDataLib..&out_pricing_curve. &casDataLib.._tmp_disc_curve(drop=CONFIG_VAR_NM rename=(CURVE_ID=DISC_CURVE_ID POLICY_YEAR=MATURITY));
               set &casDataLib..&in_pricing_curve.;
            if upcase(CONFIG_VAR_NM)='DISC_CURVE_ID' then output &casDataLib.._tmp_disc_curve ;
            else output &casDataLib..&out_pricing_curve.;
       run;";
   run;
   quit;

   /*DISC_CURVE_ID is required and terminate if not specified*/
   %if %rsk_attrn(&casDataLib.._tmp_disc_curve,nlobs) = 0 %then %do;
      %put %pcpr_get_message(key=pcpricingutilmsg_common_ds_empty, s1=&casDataLib.._tmp_disc_curve);
      %rsk_terminate;
   %end;


   /*Create json strings of data grid based on disc curve table*/
   %dcm_serializeGrid(
         gridSourceTable=&casDataLib.._tmp_disc_curve,
         gridColName=DG_DISC_CURVE,
         outputTable=&casdatalib..&OutputTables_disc.,
         classvars=DISC_CURVE_ID);
%mend;
