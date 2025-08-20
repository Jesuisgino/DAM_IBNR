/*
Copyright (C) 2022-2025 SAS Institute Inc. Cary, NC, USA
*/

/**
\file
\anchor  lf_prepare_map_config
\brief   Macro to prepare input abt/scr table, map_product_code, and pricing_config table
         - Filter map_product_code and pricing_config table with relevant (specified in the input abt/scr table) PRODUCT_CD (ABT) or PRODUCT_ID (SCR)
         - Transpose map_product_code and pricing_config table
         - Join tranposed map_product_code and pricing_config table
         - Filter input abt/scr table

\param [in] casDataLib              Input Cas library name
\param [in] in_abt_data             Input base table, abt table for annuity pricing and scr table for ul
\param [in] in_data_type            Input base table type, "ABT" or "SCR", default is set to ABT
\param [in] in_map_data             Input map table
\param [in] in_config_data          Input configuration table
\param [in] out_abt_data            Output base table
\param [in] out_map_data            Output enriched map table
\param [in] out_config_data         Output enriched configuration table
\param [in] config_key_list         Input list of primary key variables for the in_config_data, for example PRODUCT_CD, SCENARIO_ID, and RATE_ID
\param [in] map_config_var_list     Output list of variables to define the PRODUCT_CD, for example PRODUCT_ID and CHANNEL_ID
\param [in] check_config_var_list   Input list of variables that need to verified existence in the enriched output configuration table

\details This macro is called by both enrich-pricing-data script for annuity pricing and enrich-inquiry-data script for universal life cash value projection. For annuity pricing,
the enrichment is for pricing analysis and the input data type is "ABT". While for universal life, the enrichment is for cash value projection and the input data type is "SCR".
Note that user needs to drop or promote cas tables if needed outside this macro if needed.

\ingroup Macros
\author  SAS Institute Inc.
\date    2023
*/
%macro lf_prepare_map_config(casDataLib=,in_abt_data=,in_data_type=ABT,in_map_data=,in_config_data=,out_abt_data=,out_map_data=,out_config_data=,config_key_list=,map_config_var_list=,check_config_var_list=);

   %global &map_config_var_list.;
   /*In ABT table, PRODUCT_CD is required and will be used for filtering the map and config table*/
   %if %upcase(&in_data_type.) = ABT %then %do;
       proc sql noprint;
          create table _tmp_config_product_cd_list as
          select A.*
          from &casDataLib..&in_config_data. A
          where A.PRODUCT_CD in
          (select distinct(B.PRODUCT_CD) from &casDataLib..&in_abt_data. B)
          ;
          create table _tmp_map_product_code as
          select *
          from &casDataLib..&in_map_data.
          where upcase(PRODUCT_CD) in
          (select distinct(upcase(PRODUCT_CD)) from _tmp_config_product_cd_list)
          ;
       quit;
    %end;
    /*In SCR table, PRODUCT_CD will not be used. And PRODUCT_ID is required and will be used for filtering the map and config table*/
    %else %do;
       proc sql noprint;
          create table _tmp_map_product_cd_list as
          select distinct(upcase(PRODUCT_CD))
          from &casDataLib..&in_map_data.
            where upcase(MAP_VAR_NM) eq "PRODUCT_ID" and upcase(MAP_VAR_VALUE) in
          (select distinct(upcase(PRODUCT_ID)) from &casDataLib..&in_abt_data.)
          ;

          create table _tmp_map_product_code as
          select *
          from &casDataLib..&in_map_data. A
          where upcase(A.PRODUCT_CD) in (
            select *
            from _tmp_map_product_cd_list B)
          ;
       quit;
    %end;
   %if %rsk_attrn(_tmp_map_product_code,nlobs) = 0 %then %do;
      %put %pcpr_get_message(key=pcpricingutilmsg_enrich_inquiry_data_2, s1=&casDataLib..&in_map_data.);
      %rsk_terminate;
   %end;

   /*Transpose the map_product_code to get ready to merge with pricing_config*/
   proc sort data=_tmp_map_product_code;
   by PRODUCT_CD;
   run;

   proc transpose data=_tmp_map_product_code out=map_product_code(drop=_NAME_ _LABEL_);
   by PRODUCT_CD;
   id MAP_VAR_NM;
   var MAP_VAR_VALUE;
   run;

   /*Retrieve the config var list from the map_product_code table and check if config key list exist in the pricing_config table*/
   proc contents data=map_product_code out=meta_map_product_code(keep=NAME) ;
   run ;

   proc sql noprint;
      select distinct(NAME) into :config_var_list separated by " "
      from meta_map_product_code
      where upcase(NAME) ne "PRODUCT_CD"
      ;
   quit;
   %put &config_var_list;
   %let &map_config_var_list.=&config_var_list.;
   %put &&&map_config_var_list.;

   /*1.2 transpose pricing config table for merge with map product code table*/
      /*Filter config table and only keep relavent configuration based on filtered mapping table*/
   proc sql noprint;
      create table _tmp_pricing_config as
      select *
      from &casDataLib..&in_config_data.
      where upcase(PRODUCT_CD) in
      (select distinct(upcase(PRODUCT_CD)) from map_product_code)
      ;
   quit;

   data _tmp_cvar_config(drop=CONFIG_NVAR_VALUE) _tmp_nvar_config(drop=CONFIG_CVAR_VALUE) _tmp_invalid_config;
      set _tmp_pricing_config;
      if upcase(scan(CONFIG_VAR_NM,-1,"_")) in ("AMT","RT","PCT") then output _tmp_nvar_config;
      else if upcase(scan(CONFIG_VAR_NM,-1,"_")) in ("ID","CD","NM") then output _tmp_cvar_config;
      else if missing(CONFIG_CVAR_VALUE) and not missing(CONFIG_NVAR_VALUE) then output _tmp_nvar_config;
      else if not missing(CONFIG_CVAR_VALUE) and missing(CONFIG_NVAR_VALUE) then output _tmp_cvar_config;
      else output _tmp_invalid_config;
   run;

   %if %rsk_attrn(_tmp_invalid_config,nlobs) gt 0 %then %do;
      %put %pcpr_get_message(key=pcpricingutilmsg_enrich_pricing_data_1,s1=CONFIG_VAR_NM,s2=&casDataLib..&in_config_data.);
   %end;

   %let nvar_exist=0;
   %let cvar_exist=0;
   %if %rsk_attrn(_tmp_cvar_config,nlobs) gt 0 %then %do;
      %let cvar_exist=1;
      proc sort data=_tmp_cvar_config;
      by &config_key_list.;
      run;

      proc transpose data=_tmp_cvar_config out=pricing_cvar_config(drop=_NAME_ _LABEL_);
      by &config_key_list.;
      id CONFIG_VAR_NM;
      var CONFIG_CVAR_VALUE;
      run;

   %end;

   %if %rsk_attrn(_tmp_nvar_config,nlobs) gt 0 %then %do;
      %let nvar_exist=1;
      proc sort data=_tmp_nvar_config;
      by &config_key_list.;
      run;

      proc transpose data=_tmp_nvar_config out=pricing_nvar_config(drop=_NAME_ _LABEL_);
      by &config_key_list.;
      id CONFIG_VAR_NM;
      var CONFIG_NVAR_VALUE;
      run;

   %end;
   /*Join cvar and nvar if both exist*/
   %if &nvar_exist=1 and &cvar_exist=1 %then %do;
      data &casDataLib..&out_config_data.;
         merge pricing_nvar_config(in=a) pricing_cvar_config(in=b);
         by &config_key_list.;
         if a or b;
      run;

   %end;
   %else %if &nvar_exist=1 and &cvar_exist=0 %then %do;
      data &casDataLib..&out_config_data.;
         set pricing_nvar_config;
      run;
   %end;
   %else %if &nvar_exist=0 and &cvar_exist=1 %then %do;
      data &casDataLib..&out_config_data.;
         set pricing_cvar_config;
      run;
   %end;
   %else %do;
        %put  %pcpr_get_message(key=pcpricingutilmsg_enrich_pricing_data_2, s1=&casDataLib..&in_config_data.);
        %rsk_terminate;
   %end;

   %pcpr_check_ds_status(caslib=&casDataLib.,castable=&out_config_data.,required_col_list=&config_key_list. &check_config_var_list.);

   /*1.3: Check the data and only keep the policies with config defined in the pricing_config table*/

   %if %upcase(&in_data_type.)=ABT %then %do;
        %let abt_config_join_var=PRODUCT_CD;
   %end;
   %else %do;
        %let abt_config_join_var=&config_var_list.;
   %end;
   proc sort data=&casDataLib..&in_abt_data. out=_tmp_abt_orig;
   by &abt_config_join_var.;
   run;

   proc sort data=map_product_code out=_tmp_config(keep=&abt_config_join_var) nodupkey;
   by &abt_config_join_var.;
   run;

   data _tmp_abt_w_config;
      merge _tmp_abt_orig(in=a) _tmp_config(in=b);
      by &abt_config_join_var.;
      if a and b;
   run;


   /*Create cas table*/
   data &casDataLib..&out_map_data.;
      set map_product_code;
   run;

      data &casDataLib..&out_abt_data.;
      set _tmp_abt_w_config;
   run;
%mend;
